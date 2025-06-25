# Refactored Character class using extracted components

require "yaml"
require "../utils/yaml_converters"
require "../core/game_object"
require "../core/game_constants"
require "../utils/vector_math"
require "./movement_controller"
require "./dialogue/character_dialogue"
require "./animation_controller"
require "./sprite_controller"
require "./character_state_manager"

module PointClickEngine
  module Characters
    # Marker module for objects that support dialogue interactions
    module Talkable
    end

    # Refactored Character class using extracted component architecture
    #
    # This version delegates responsibilities to specialized components:
    # - AnimationController: Handles all animation logic
    # - SpriteController: Manages sprite loading and rendering
    # - CharacterStateManager: Coordinates state transitions
    # - MovementController: Handles movement and pathfinding
    # - CharacterDialogue: Manages dialogue interactions
    abstract class Character < Core::GameObject
      include Talkable

      # The character's unique name identifier
      property name : String

      # Descriptive text shown when examining the character
      property description : String

      # Movement speed in pixels per second
      property walking_speed : Float32 = Core::GameConstants::DEFAULT_WALKING_SPEED

      # Target position for movement (nil if not moving)
      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::Vector2Converter, nilable: true)]
      property target_position : RL::Vector2?

      # Pathfinding waypoints for navigation (runtime only)
      @[YAML::Field(ignore: true)]
      property path : Array(RL::Vector2)?

      # Current waypoint index when following a path (runtime only)
      @[YAML::Field(ignore: true)]
      property current_path_index : Int32 = 0

      # Whether to use pathfinding for movement (true = smart navigation)
      property use_pathfinding : Bool = true

      # Callback executed when character finishes walking (runtime only)
      @[YAML::Field(ignore: true)]
      property on_walk_complete : Proc(Nil)?

      # Dialogue system data for this character
      property dialogue_system_data : Dialogue::CharacterDialogue?

      # Delegate dialogue methods to the dialogue system
      @[YAML::Field(ignore: true)]
      delegate dialogue_system, to: @dialogue_system_data

      # Name of character currently in conversation with (for serialization)
      property conversation_partner_name : String?

      # Reference to character currently in conversation with (runtime only)
      @[YAML::Field(ignore: true)]
      property conversation_partner : Character?

      # Manual scale override from configuration (overrides dynamic scaling)
      property manual_scale : Float32?

      # Component Controllers
      @[YAML::Field(ignore: true)]
      property animation_controller : AnimationController

      @[YAML::Field(ignore: true)]
      property sprite_controller : SpriteController

      @[YAML::Field(ignore: true)]
      property state_manager : CharacterStateManager

      @[YAML::Field(ignore: true)]
      property movement_controller : MovementController?

      # Creates a character with empty properties
      def initialize
        super(RL::Vector2.new, RL::Vector2.new)
        @name = ""
        @description = ""
        @dialogue_system_data = Dialogue::CharacterDialogue.new(self)
        
        # Initialize component controllers
        @animation_controller = AnimationController.new
        @sprite_controller = SpriteController.new(@position, @size)
        @state_manager = CharacterStateManager.new
        @movement_controller = MovementController.new(self)
        
        setup_component_integration
      end

      # Creates a character with specified properties
      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(position, size)
        @description = "A character named #{@name}"
        @dialogue_system_data = Dialogue::CharacterDialogue.new(self)
        
        # Initialize component controllers
        @animation_controller = AnimationController.new
        @sprite_controller = SpriteController.new(@position, @size)
        @state_manager = CharacterStateManager.new
        @movement_controller = MovementController.new(self)
        
        setup_component_integration
      end

      # Sets up integration between components
      private def setup_component_integration
        # Connect state manager callbacks to other components
        @state_manager.on_state_changed = ->(old_state : CharacterState, new_state : CharacterState) {
          @animation_controller.state = new_state
          @animation_controller.update_state_animation
        }

        @state_manager.on_direction_changed = ->(old_dir : Direction, new_dir : Direction) {
          @animation_controller.direction = new_dir
          @animation_controller.update_directional_animation
        }

        @state_manager.on_mood_changed = ->(old_mood : CharacterMood, new_mood : CharacterMood) {
          @animation_controller.mood = new_mood
          @animation_controller.update_mood_animation
        }

        # Connect animation controller to sprite controller
        @animation_controller.sprite = @sprite_controller.sprite
      end

      # Called after YAML deserialization to restore runtime state
      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        @sprite_controller.after_yaml_deserialize(ctx)
        @dialogue_system_data.try(&.character = self)
        @movement_controller = MovementController.new(self)
        
        # Restore component integration
        setup_component_integration
        
        # Restore current animation
        @animation_controller.play_animation(@animation_controller.current_animation, force_restart: false)
      end

      # Loads a spritesheet for character animation
      def load_spritesheet(path : String, frame_width : Int32, frame_height : Int32)
        @sprite_controller.load_spritesheet(path, frame_width, frame_height)
        @animation_controller.sprite = @sprite_controller.sprite
        @size = @sprite_controller.size
      end

      # Defines a named animation for the character
      def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                        frame_speed : Float32 = Core::GameConstants::DEFAULT_ANIMATION_SPEED, 
                        loop : Bool = true)
        @animation_controller.add_animation(name, start_frame, frame_count, frame_speed, loop)
      end

      # Plays a named animation
      def play_animation(name : String, force_restart : Bool = true)
        @animation_controller.play_animation(name, force_restart)
      end

      # Initiates movement to a target position
      def walk_to(target : RL::Vector2, use_pathfinding : Bool? = nil)
        @target_position = target
        @state_manager.set_state(CharacterState::Walking)
        @movement_controller.try(&.move_to(target, use_pathfinding))
      end

      # Initiates movement along a predefined path
      def walk_to_with_path(path : Array(RL::Vector2))
        @movement_controller.try(&.move_along_path(path))
      end

      # Stops the character's movement immediately
      def stop_walking
        @target_position = nil
        @state_manager.try_return_to_idle
        @movement_controller.try(&.stop_movement)
      end

      # Check if character is currently moving
      def moving? : Bool
        @movement_controller.try(&.moving?) || false
      end

      # Check if character is following a pathfinding route
      def following_path? : Bool
        @movement_controller.try(&.following_path?) || false
      end

      # Get remaining distance to movement target
      def distance_to_target : Float32
        @movement_controller.try(&.distance_to_target) || 0.0_f32
      end

      # Set movement completion callback
      def on_movement_complete(&block : -> Nil)
        @movement_controller.try(&.on_movement_complete = block)
      end

      # Makes the character speak dialogue text
      def say(text : String, &block : -> Nil)
        @state_manager.set_state(CharacterState::Talking)
        @animation_controller.play_animation("talk") if @animation_controller.has_animation?("talk")

        if dialogue = @dialogue_system_data
          dialogue.say(text) do
            @state_manager.try_return_to_idle
            stop_walking
            block.call
          end
        else
          block.call
        end
      end

      # Presents a dialogue question with multiple choice responses
      def ask(question : String, choices : Array(Tuple(String, Proc(Nil))))
        @state_manager.set_state(CharacterState::Talking)
        @animation_controller.play_animation("talk") if @animation_controller.has_animation?("talk")

        if dialogue = @dialogue_system_data
          dialogue.ask(question, choices) do
            @state_manager.try_return_to_idle
            stop_walking
          end
        end
      end

      # Updates the character's state, movement, and animation
      def update(dt : Float32)
        return unless @active
        
        @movement_controller.try(&.update(dt))
        @animation_controller.update(dt)
        @dialogue_system_data.try(&.update(dt))
        
        # Update sprite position to match character position
        @sprite_controller.update_position(@position)
        @sprite_controller.update_scale(@scale)
      end

      # Renders the character sprite and dialogue
      def draw
        return unless @visible
        
        @sprite_controller.draw
        @dialogue_system_data.try(&.draw)

        if Core::Engine.debug_mode
          RL.draw_text(@name, @position.x.to_i, (@position.y - 25).to_i, 16, RL::WHITE)
          if @target_position
            RL.draw_line_v(@position, @target_position.not_nil!, RL::GREEN)
            RL.draw_circle_v(@target_position.not_nil!, 5.0, RL::GREEN)
          end

          # Draw path if using pathfinding
          if path = @path
            (0...path.size - 1).each do |i|
              RL.draw_line_v(path[i], path[i + 1], RL::YELLOW)
            end
            path.each do |waypoint|
              RL.draw_circle_v(waypoint, 3.0, RL::YELLOW)
            end
          end
        end
      end

      # Sets the character's mood and updates mood-based animations
      def set_mood(new_mood : CharacterMood)
        @state_manager.set_mood(new_mood)
      end

      # Check if a point is within the character's bounds
      def contains_point?(point : RL::Vector2) : Bool
        @sprite_controller.contains_point?(point)
      end

      # Delegate state properties to state manager
      delegate state, to: @state_manager
      delegate direction, to: @state_manager
      delegate mood, to: @state_manager
      delegate state=, to: @state_manager
      delegate direction=, to: @state_manager
      delegate mood=, to: @state_manager

      # Delegate sprite properties to sprite controller
      delegate sprite, to: @sprite_controller
      delegate sprite_path, to: @sprite_controller

      # Delegate animation properties to animation controller
      delegate current_animation, to: @animation_controller
      delegate animations, to: @animation_controller

      # Abstract methods that must be implemented by subclasses
      abstract def on_interact(interactor : Character)
      abstract def on_look
      abstract def on_talk

      # Get the current scene from the engine
      private def get_current_scene : Scenes::Scene?
        Core::Engine.instance.current_scene
      rescue
        nil
      end

      # Component access methods for external systems
      def get_animation_controller : AnimationController
        @animation_controller
      end

      def get_sprite_controller : SpriteController
        @sprite_controller
      end

      def get_state_manager : CharacterStateManager
        @state_manager
      end

      # Convenience methods for state queries
      delegate can_move?, to: @state_manager
      delegate can_talk?, to: @state_manager
      delegate can_interact?, to: @state_manager
      delegate busy?, to: @state_manager
      delegate available?, to: @state_manager
      delegate talking?, to: @state_manager

      # Convenience methods for animation control
      def has_animation?(name : String) : Bool
        @animation_controller.has_animation?(name)
      end

      def stop_animation
        @animation_controller.stop
      end

      def pause_animation
        @animation_controller.pause
      end

      def resume_animation
        @animation_controller.resume
      end

      # Sprite management convenience methods
      def set_manual_scale(scale : Float32?)
        @sprite_controller.set_manual_scale(scale)
        @manual_scale = scale
      end

      def reload_sprite_texture
        @sprite_controller.reload_texture
      end

      def sprite_loaded? : Bool
        @sprite_controller.loaded?
      end
    end
  end
end