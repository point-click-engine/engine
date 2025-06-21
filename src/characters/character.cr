# Base Character class and related types

require "yaml"
require "../utils/yaml_converters"
require "../core/game_object"

module PointClickEngine
  module Characters
    # Defines the various states a character can be in
    #
    # Used to control character behavior, animations, and interaction availability.
    enum CharacterState
      Idle        # Character is stationary and available for interaction
      Walking     # Character is moving to a target position
      Talking     # Character is engaged in dialogue
      Interacting # Character is performing an interaction with an object
      Thinking    # Character is in a contemplative state (often for delays)
    end

    # Defines the facing direction of a character
    #
    # Used for sprite selection and animation control. Affects which
    # animation variants are played (e.g., "walk_left" vs "walk_right").
    enum Direction
      Left  # Character is facing left
      Right # Character is facing right
      Up    # Character is facing up/away
      Down  # Character is facing down/toward camera
    end

    # Marker module for objects that support dialogue interactions
    #
    # Mix this module into characters or objects that can be talked to.
    # Used by the interaction system to determine available actions.
    module Talkable
    end

    # Contains animation configuration data for character sprites
    #
    # Defines which frames to use, playback speed, and looping behavior
    # for a specific character animation sequence.
    struct AnimationData
      include YAML::Serializable

      # First frame index in the animation sequence
      property start_frame : Int32

      # Number of frames in the animation
      property frame_count : Int32

      # Time between frames in seconds (lower = faster)
      property frame_speed : Float32

      # Whether the animation should loop continuously
      property loop : Bool

      # Creates animation data with specified parameters
      #
      # - *start_frame* : First frame index (default: 0)
      # - *frame_count* : Number of frames (default: 1)
      # - *frame_speed* : Seconds per frame (default: 0.1)
      # - *loop* : Whether to loop (default: true)
      def initialize(@start_frame : Int32 = 0, @frame_count : Int32 = 1,
                     @frame_speed : Float32 = 0.1, @loop : Bool = true)
      end
    end

    # Abstract base class for all character types in the game
    #
    # Provides core functionality for character movement, animation, dialogue,
    # and interaction. Characters can navigate using pathfinding, play animated
    # sprites, engage in conversations, and respond to player actions.
    #
    # ## Key Features
    # - Sprite-based animation system with directional support
    # - Pathfinding and direct movement capabilities
    # - Dialogue system integration
    # - State management for behavior control
    # - Automatic scaling based on scene depth
    #
    # ## Animation System
    # Characters support named animations (e.g., "idle", "walk_left", "talk").
    # The system automatically selects appropriate animations based on
    # character state and facing direction.
    #
    # ## Usage Example
    # ```
    # class MyCharacter < Character
    #   def initialize(name, position)
    #     super(name, position, Vector2.new(64, 64))
    #     load_spritesheet("character.png", 32, 48)
    #     add_animation("idle", 0, 1)
    #     add_animation("walk_right", 1, 4, 0.15)
    #   end
    #
    #   def on_interact(interactor)
    #     say("Hello there!")
    #   end
    # end
    # ```
    #
    # NOTE: This is an abstract class - implement `on_interact`, `on_look`, and `on_talk`
    abstract class Character < Core::GameObject
      # The character's unique name identifier
      property name : String

      # Descriptive text shown when examining the character
      property description : String

      # Current behavioral state (idle, walking, talking, etc.)
      property state : CharacterState = CharacterState::Idle

      # Current facing direction for sprite selection
      property direction : Direction = Direction::Right

      # Movement speed in pixels per second
      property walking_speed : Float32 = 100.0

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

      # Animated sprite data for rendering
      property sprite_data : Graphics::AnimatedSprite?

      # Gets the character's sprite
      #
      # Returns: The animated sprite, or `nil` if not set
      def sprite
        @sprite_data
      end

      # Sets the character's sprite
      #
      # - *value* : The animated sprite to use
      def sprite=(value : Graphics::AnimatedSprite)
        @sprite_data = value
      end

      # Name of the currently playing animation
      property current_animation : String = "idle"

      # Collection of defined animations by name
      property animations : Hash(String, AnimationData) = {} of String => AnimationData

      # Name of character currently in conversation with (for serialization)
      property conversation_partner_name : String?

      # Reference to character currently in conversation with (runtime only)
      @[YAML::Field(ignore: true)]
      property conversation_partner : Character?

      # Creates a character with empty properties
      #
      # Initializes all collections and sets up dialogue system.
      # Name and description must be set separately.
      def initialize
        super(RL::Vector2.new, RL::Vector2.new)
        @name = ""
        @description = ""
        @animations = {} of String => AnimationData
        @dialogue_system_data = Dialogue::CharacterDialogue.new(self)
      end

      # Creates a character with specified properties
      #
      # - *name* : Unique identifier for the character
      # - *position* : Starting world position
      # - *size* : Collision bounds size
      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(position, size)
        @description = "A character named #{@name}"
        @dialogue_system_data = Dialogue::CharacterDialogue.new(self)
        @animations = {} of String => AnimationData
      end

      # Called after YAML deserialization to restore runtime state
      #
      # Restores sprite data, reconnects dialogue system, and resumes
      # the current animation.
      #
      # - *ctx* : YAML parsing context
      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        @sprite_data.try &.after_yaml_deserialize(ctx)
        @dialogue_system_data.try &.character = self
        play_animation(@current_animation, force_restart: false)
      end

      # Loads a spritesheet for character animation
      #
      # Creates an animated sprite from the specified image file with the given
      # frame dimensions. Automatically calculates appropriate scaling.
      #
      # - *path* : File path to the spritesheet image
      # - *frame_width* : Width of each frame in pixels
      # - *frame_height* : Height of each frame in pixels
      #
      # ```
      # character.load_spritesheet("hero.png", 32, 48)
      # ```
      def load_spritesheet(path : String, frame_width : Int32, frame_height : Int32)
        @sprite_data = Graphics::AnimatedSprite.new(@position, frame_width, frame_height, 1)
        @sprite_data.not_nil!.load_texture(path)
        @sprite_data.not_nil!.scale = calculate_scale(frame_width, frame_height)
        @size = RL::Vector2.new(x: frame_width * @sprite_data.not_nil!.scale, y: frame_height * @sprite_data.not_nil!.scale)
        @sprite_data.not_nil!.size = @size
      end

      # Defines a named animation for the character
      #
      # Animations are referenced by name and define which frames to play
      # from the loaded spritesheet.
      #
      # - *name* : Unique name for the animation (e.g., "walk_left")
      # - *start_frame* : First frame index in the spritesheet
      # - *frame_count* : Number of frames in the sequence
      # - *frame_speed* : Time between frames in seconds (default: 0.1)
      # - *loop* : Whether animation should loop (default: true)
      #
      # ```
      # character.add_animation("walk_right", 8, 4, 0.15)
      # character.add_animation("idle", 0, 1, 0.1, false)
      # ```
      def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                        frame_speed : Float32 = 0.1, loop : Bool = true)
        @animations[name] = AnimationData.new(start_frame, frame_count, frame_speed, loop)
      end

      # Plays a named animation
      #
      # Switches to the specified animation if it exists. Can optionally
      # avoid restarting if the same animation is already playing.
      #
      # - *name* : Name of the animation to play
      # - *force_restart* : Whether to restart if already playing (default: true)
      #
      # ```
      # character.play_animation("walk_left")
      # character.play_animation("idle", force_restart: false)
      # ```
      def play_animation(name : String, force_restart : Bool = true)
        return unless @animations.has_key?(name)
        return if !force_restart && @current_animation == name && @sprite_data.try(&.playing)

        @current_animation = name
        anim_data = @animations[name]

        if sprite = @sprite_data
          sprite.current_frame = anim_data.start_frame
          sprite.frame_count = anim_data.frame_count
          sprite.frame_speed = anim_data.frame_speed
          sprite.loop = anim_data.loop
          sprite.play
        end
      end

      # Initiates movement to a target position
      #
      # Sets the character to walk directly toward the target position.
      # Automatically selects appropriate walking animation based on direction.
      # Clears any existing pathfinding data.
      #
      # - *target* : World position to walk to
      #
      # ```
      # character.walk_to(Vector2.new(200, 300))
      # ```
      def walk_to(target : RL::Vector2)
        @target_position = target
        @state = CharacterState::Walking

        # Reset path when new target is set
        @path = nil
        @current_path_index = 0

        if target.x < @position.x
          @direction = Direction::Left
          play_animation("walk_left") if @animations.has_key?("walk_left")
        else
          @direction = Direction::Right
          play_animation("walk_right") if @animations.has_key?("walk_right")
        end
      end

      # Initiates movement along a predefined path
      #
      # Sets the character to follow a series of waypoints, typically
      # generated by the pathfinding system. The character will navigate
      # through each waypoint in sequence.
      #
      # - *path* : Array of waypoints to follow
      #
      # ```
      # waypoints = scene.find_path(start_x, start_y, end_x, end_y)
      # character.walk_to_with_path(waypoints) if waypoints
      # ```
      def walk_to_with_path(path : Array(RL::Vector2))
        return if path.empty?

        @path = path
        @current_path_index = 0
        @target_position = path.last
        @state = CharacterState::Walking

        # Set initial direction based on first waypoint
        if path[0].x < @position.x
          @direction = Direction::Left
          play_animation("walk_left") if @animations.has_key?("walk_left")
        else
          @direction = Direction::Right
          play_animation("walk_right") if @animations.has_key?("walk_right")
        end
      end

      # Stops the character's movement immediately
      #
      # Clears movement target and path, returns to idle state, and
      # plays appropriate idle animation. Executes walk completion callback
      # if one was set.
      def stop_walking
        @target_position = nil
        @path = nil
        @current_path_index = 0
        @state = CharacterState::Idle
        base_idle_anim = @direction == Direction::Left ? "idle_left" : "idle_right"
        play_animation(base_idle_anim) if @animations.has_key?(base_idle_anim)
        play_animation("idle") if !@animations.has_key?(base_idle_anim) && @animations.has_key?("idle")

        # Call completion callback if set
        if callback = @on_walk_complete
          @on_walk_complete = nil # Clear callback to prevent double calls
          callback.call
        end
      end

      # Makes the character speak dialogue text
      #
      # Displays the text using the dialogue system and transitions to
      # talking state. Plays talk animation if available. Executes the
      # provided block when dialogue completes.
      #
      # - *text* : The dialogue text to display
      # - *block* : Callback to execute when dialogue finishes
      #
      # ```
      # character.say("Hello, adventurer!") do
      #   puts "Dialogue completed"
      # end
      # ```
      def say(text : String, &block : -> Nil)
        @state = CharacterState::Talking
        play_animation("talk") if @animations.has_key?("talk")

        if dialogue = @dialogue_system_data
          dialogue.say(text) do
            @state = CharacterState::Idle
            stop_walking
            block.call
          end
        else
          block.call
        end
      end

      # Presents a dialogue question with multiple choice responses
      #
      # Displays the question and provides clickable response options.
      # Each choice is paired with a callback that executes when selected.
      #
      # - *question* : The question text to display
      # - *choices* : Array of (response_text, callback) tuples
      #
      # ```
      # character.ask("What do you want?", [
      #   {"Trade", -> { start_trading }},
      #   {"Nothing", -> { end_conversation }},
      # ])
      # ```
      def ask(question : String, choices : Array(Tuple(String, Proc(Nil))))
        @state = CharacterState::Talking
        play_animation("talk") if @animations.has_key?("talk")

        if dialogue = @dialogue_system_data
          dialogue.ask(question, choices) do
            @state = CharacterState::Idle
            stop_walking
          end
        end
      end

      # Updates the character's state, movement, and animation
      #
      # Called every frame to process movement, animation playback,
      # and dialogue system updates.
      #
      # - *dt* : Delta time in seconds since last update
      def update(dt : Float32)
        return unless @active
        update_movement(dt)
        update_animation(dt)
        @dialogue_system_data.try &.update(dt)
      end

      # Renders the character sprite and dialogue
      #
      # Draws the character's animated sprite with proper scaling,
      # dialogue bubbles, and debug information when enabled.
      def draw
        return unless @visible

        # Apply character scale to sprite
        if sprite = @sprite_data
          old_scale = sprite.scale
          sprite.scale = @scale
          sprite.draw
          sprite.scale = old_scale
        end

        @dialogue_system_data.try &.draw

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

      # Called when another character interacts with this one
      #
      # Implement this method to define interaction behavior such as
      # dialogue, item exchange, or quest progression.
      #
      # - *interactor* : The character performing the interaction
      abstract def on_interact(interactor : Character)

      # Called when this character is examined/looked at
      #
      # Implement this method to provide descriptive text or trigger
      # examination-specific behavior.
      abstract def on_look

      # Called when this character is talked to
      #
      # Implement this method to initiate conversation or provide
      # talk-specific responses.
      abstract def on_talk

      # Get the current scene from the engine
      private def get_current_scene : Scenes::Scene?
        Core::Engine.instance.current_scene
      rescue
        nil
      end

      private def update_movement(dt : Float32)
        return unless @state == CharacterState::Walking

        # Use pathfinding if available
        if path = @path
          update_path_following(dt)
        elsif target = @target_position
          # Direct movement without pathfinding
          direction_vec = RL::Vector2.new(x: target.x - @position.x, y: target.y - @position.y)
          distance = Math.sqrt(direction_vec.x ** 2 + direction_vec.y ** 2).to_f

          if distance < 5.0
            @position = target
            stop_walking
            return
          end

          normalized_dir_x = direction_vec.x / distance
          normalized_dir_y = direction_vec.y / distance

          new_position = RL::Vector2.new(
            x: @position.x + normalized_dir_x * @walking_speed * dt,
            y: @position.y + normalized_dir_y * @walking_speed * dt
          )

          # Check if new position is walkable
          if scene = get_current_scene
            if scene.is_walkable?(new_position)
              @position = new_position
              # Update character scale based on Y position
              @scale = scene.get_character_scale(@position.y)
            else
              # Try to slide along the boundary
              constrained_pos = scene.walkable_area.try(&.constrain_to_walkable(@position, new_position))
              if constrained_pos
                @position = constrained_pos
                @scale = scene.get_character_scale(@position.y)
              end
            end
          else
            @position = new_position
          end

          @sprite_data.try &.position = @position

          # Update direction
          if (target.x - @position.x).abs > 5.0
            new_direction = target.x < @position.x ? Direction::Left : Direction::Right
            if new_direction != @direction
              @direction = new_direction
              if @direction == Direction::Left
                play_animation("walk_left") if @animations.has_key?("walk_left")
              else
                play_animation("walk_right") if @animations.has_key?("walk_right")
              end
            end
          end
        end
      end

      private def update_path_following(dt : Float32)
        return unless path = @path
        return if path.empty?

        # Get current waypoint
        if @current_path_index >= path.size
          stop_walking
          return
        end

        current_waypoint = path[@current_path_index]
        direction_vec = RL::Vector2.new(x: current_waypoint.x - @position.x, y: current_waypoint.y - @position.y)
        distance = Math.sqrt(direction_vec.x ** 2 + direction_vec.y ** 2).to_f

        # Check if we reached the current waypoint
        if distance < 10.0
          @current_path_index += 1

          # Check if we reached the end
          if @current_path_index >= path.size
            if final_target = @target_position
              @position = final_target
            end
            stop_walking
            return
          end

          # Update direction for next waypoint
          if @current_path_index < path.size
            next_waypoint = path[@current_path_index]
            if (next_waypoint.x - @position.x).abs > 5.0
              new_direction = next_waypoint.x < @position.x ? Direction::Left : Direction::Right
              if new_direction != @direction
                @direction = new_direction
                if @direction == Direction::Left
                  play_animation("walk_left") if @animations.has_key?("walk_left")
                else
                  play_animation("walk_right") if @animations.has_key?("walk_right")
                end
              end
            end
          end
          return
        end

        # Move towards current waypoint
        normalized_dir_x = direction_vec.x / distance
        normalized_dir_y = direction_vec.y / distance

        new_position = RL::Vector2.new(
          x: @position.x + normalized_dir_x * @walking_speed * dt,
          y: @position.y + normalized_dir_y * @walking_speed * dt
        )

        # Check walkable area for pathfinding movement too
        if scene = get_current_scene
          if scene.is_walkable?(new_position)
            @position = new_position
          else
            # Constrain to walkable area
            constrained_pos = scene.walkable_area.try(&.constrain_to_walkable(@position, new_position))
            @position = constrained_pos || @position
          end
        else
          @position = new_position
        end

        @sprite_data.try &.position = @position
      end

      private def update_animation(dt : Float32)
        if @sprite_data && @animations.has_key?(@current_animation)
          anim_data = @animations[@current_animation]
          current_sprite = @sprite_data.not_nil!

          if current_sprite.playing
            current_sprite.frame_timer += dt
            if current_sprite.frame_timer >= current_sprite.frame_speed
              current_sprite.frame_timer = 0.0

              current_sprite.current_frame += 1

              if current_sprite.current_frame >= anim_data.start_frame + anim_data.frame_count
                if anim_data.loop
                  current_sprite.current_frame = anim_data.start_frame
                else
                  current_sprite.current_frame = anim_data.start_frame + anim_data.frame_count - 1
                  current_sprite.stop
                  if @state != CharacterState::Talking
                    stop_walking
                  end
                end
              end
            end
          end
        end
      end

      private def calculate_scale(frame_width : Int32, frame_height : Int32) : Float32
        return 1.0_f32 if frame_width == 0 || frame_height == 0
        scale_x = @size.x / frame_width
        scale_y = @size.y / frame_height
        Math.min(scale_x, scale_y).to_f32
      end
    end
  end
end
