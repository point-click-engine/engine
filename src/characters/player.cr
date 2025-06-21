# Player character class

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Characters
    # Player character implementation
    class Player < Character
      property inventory_access : Bool = true
      property movement_enabled : Bool = true

      @[YAML::Field(ignore: true)]
      property interaction_callback : Tuple(Scenes::Hotspot | Character, Symbol)?

      def initialize
        super()
        @name = "Player"
        @size = RL::Vector2.new(x: 32f32, y: 64f32)
      end

      def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
        setup_default_animations
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        setup_default_animations
      end

      def on_interact(interactor : Character)
        say("Someone's trying to interact with me, #{@name}.") { }
      end

      def on_look
        say("That's me, #{@name}.") { }
      end

      def on_talk
        say("I'd rather talk to someone else if I'm initiating.") { }
      end

      def handle_click(target_pos : RL::Vector2, scene : Scenes::Scene)
        return unless @movement_enabled
        return if @state == CharacterState::Talking

        @interaction_callback = nil

        clicked_on = scene.get_hotspot_at(target_pos) || scene.get_character_at(target_pos)

        if clicked_on
          interaction_target = clicked_on
          walk_to(interaction_target.position)

          case interaction_target
          when Scenes::Hotspot
            @interaction_callback = {interaction_target, :on_click}
          when Character
            @interaction_callback = {interaction_target, :on_interact}
          end
        else
          walk_to(target_pos)
        end
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

      private def setup_default_animations
        unless @animations.has_key?("idle")
          add_animation("idle", 0, 1, 1.0, true)
        end
        unless @animations.has_key?("idle_right")
          add_animation("idle_right", 0, 1, 1.0, true)
        end
        unless @animations.has_key?("idle_left")
          add_animation("idle_left", 1, 1, 1.0, true)
        end
        unless @animations.has_key?("walk_right")
          add_animation("walk_right", 2, 4, 0.15, true)
        end
        unless @animations.has_key?("walk_left")
          add_animation("walk_left", 6, 4, 0.15, true)
        end
        unless @animations.has_key?("talk")
          add_animation("talk", 10, 2, 0.3, true)
        end
        play_animation("idle_right")
      end
    end
  end
end
