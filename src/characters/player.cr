# Enhanced player character with 8-directional animations and adventure game features

require "yaml"
require "./animation"

module PointClickEngine
  module Characters
    # Enhanced player character with advanced animation system
    # for Simon the Sorcerer style adventure games.
    #
    # ## Features
    # - 8-directional walking animations
    # - Context-specific action animations
    # - Idle variations and personality animations
    # - Smooth direction transitions
    #
    # ## Usage
    # ```
    # player = Player.new("Simon", position, size)
    # player.load_enhanced_spritesheet("simon_8dir.png", 32, 64, 8, 4)
    # player.walk_to(target) # Automatically selects appropriate direction
    # player.perform_action(AnimationState::PickingUp, item_position)
    # ```
    class Player < EnhancedCharacter
      include Talkable

      property inventory_access : Bool = true
      property movement_enabled : Bool = true

      @[YAML::Field(ignore: true)]
      property interaction_callback : Tuple(Scenes::Hotspot | Character, Symbol)?

      def initialize
        super()
        @name = "Player"
        @description = "That's me, #{@name}."
        @size = RL::Vector2.new(x: 32f32, y: 64f32)
        setup_player_animations
      end

      def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
        @name = name
        @description = "That's me, #{@name}."
        setup_player_animations
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        setup_player_animations
      end

      # Handle interactions with other characters
      def on_interact(interactor : Character)
        perform_action(AnimationState::Talking)
        say("Someone's trying to interact with me, #{@name}.") { }
      end

      # Handle look action
      def on_look
        perform_action(AnimationState::Talking)
        say("That's me, #{@name}.") { }
      end

      # Handle talk action
      def on_talk
        perform_action(AnimationState::Talking)
        say("I can't talk to myself!") { }
      end

      # Enhanced click handling with proper animations
      def handle_click(mouse_pos : RL::Vector2, scene : Scenes::Scene)
        return unless @movement_enabled

        # Check if the target is walkable
        return unless scene.is_walkable?(mouse_pos)

        # Start walking with enhanced animations
        walk_to(mouse_pos)
      end

      # Perform specific action with appropriate animation
      def use_item_on_target(target_position : RL::Vector2)
        perform_action(AnimationState::Using, target_position)
      end

      def pick_up_item(item_position : RL::Vector2)
        perform_action(AnimationState::PickingUp, item_position)
      end

      def examine_object(object_position : RL::Vector2)
        # Look in direction of object
        direction_vec = RL::Vector2.new(
          x: object_position.x - @position.x,
          y: object_position.y - @position.y
        )
        direction = Direction8.from_velocity(direction_vec)
        play_enhanced_animation(AnimationState::Idle, direction)
      end

      def push_object(object_position : RL::Vector2)
        perform_action(AnimationState::Pushing, object_position)
      end

      def pull_object(object_position : RL::Vector2)
        perform_action(AnimationState::Pulling, object_position)
      end

      # Enhanced walking with pathfinding
      def walk_to_with_path(path : Array(RL::Vector2))
        return if path.empty?

        @path = path
        @current_path_index = 0

        if path.size > 1
          # Calculate initial direction from first two waypoints
          velocity = RL::Vector2.new(
            x: path[1].x - path[0].x,
            y: path[1].y - path[0].y
          )
          @enhanced_direction = Direction8.from_velocity(velocity)
        end

        walk_to(path.first)
      end

      # Override stop_walking to return to idle properly
      def stop_walking
        super
        @movement_state = AnimationState::Idle
        @animation_controller.play_animation("idle")
      end

      private def update_movement(dt : Float32)
        previous_state = @state
        super(dt)

        if previous_state == CharacterState::Walking && @state == CharacterState::Idle
          if callback_data = @interaction_callback
            target_object, action_method = callback_data
            case target_object
            when Scenes::Hotspot
              target_object.on_click.try &.call
            when Character
              if action_method == :on_interact
                target_object.on_interact(self)
              elsif action_method == :on_talk
                target_object.on_talk
              end
            end
            @interaction_callback = nil
          end
        end
      end

      # Setup player-specific animations
      private def setup_player_animations
        # Add player-specific idle variations
        @animation_controller.add_idle_variation("check_inventory", 100, 8, 0.15)
        @animation_controller.add_idle_variation("look_around", 108, 6, 0.2)
        @animation_controller.add_idle_variation("tap_foot", 114, 4, 0.25)

        # Add action animations (assuming they start after walking animations)
        # Walking: frames 0-31 (8 directions × 4 frames)
        # Talking: frames 32-47 (8 directions × 2 frames)
        @animation_controller.add_directional_animation("talk", 32, 2, 0.3)

        # Action animations (single direction, will be mirrored/rotated as needed)
        @animation_controller.add_animation("pickup", 48, 6, 0.15, false, 5, true, true)
        @animation_controller.add_animation("use", 54, 4, 0.2, false, 5, true, true)
        @animation_controller.add_animation("push", 58, 6, 0.12, false, 5, true, true)
        @animation_controller.add_animation("pull", 64, 6, 0.12, false, 5, true, true)
        @animation_controller.add_animation("climb", 70, 8, 0.15, false, 10, false, true)
        @animation_controller.add_animation("sit", 78, 1, 1.0, true, 3, true, false)
        @animation_controller.add_animation("stand", 79, 3, 0.2, false, 3, true, true)
        @animation_controller.add_animation("die", 82, 8, 0.3, false, 100, false, false)
      end
    end
  end
end
