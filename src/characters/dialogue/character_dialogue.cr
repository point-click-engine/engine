# Character dialogue system for managing character conversations

require "raylib-cr"
require "yaml"
require "../../utils/yaml_converters"

module PointClickEngine
  module Characters
    module Dialogue
      # Character dialogue manager
      class CharacterDialogue
        include YAML::Serializable

        @[YAML::Field(ignore: true)]
        property character : Character
        property current_dialog_data : UI::Dialog?
        @[YAML::Field(ignore: true)]
        delegate current_dialog, to: @current_dialog_data

        @[YAML::Field(ignore: true)]
        property dialog_offset : RL::Vector2 = RL::Vector2.new(x: 0, y: -100)

        def initialize(@character : Character)
        end

        def initialize
          @character = Characters::Player.new # Dummy, will be replaced
        end

        def after_yaml_deserialize(ctx : YAML::ParseContext)
          @current_dialog_data.try &.after_yaml_deserialize(ctx)
        end

        def say(text : String, &on_complete : -> Nil)
          dialog_pos, dialog_size = calculate_dialog_rect(text)

          @current_dialog_data = UI::Dialog.new(text, dialog_pos, dialog_size)
          @current_dialog_data.not_nil!.character_name = @character.name
          @current_dialog_data.not_nil!.on_complete = on_complete
          Core::Engine.instance.show_dialog(@current_dialog_data.not_nil!)
        end

        def ask(question : String, choices : Array(Tuple(String, Proc(Nil))), &on_overall_complete : -> Nil)
          dialog_pos, dialog_size = calculate_dialog_rect(question, choices.size)

          @current_dialog_data = UI::Dialog.new(question, dialog_pos, dialog_size)
          @current_dialog_data.not_nil!.character_name = @character.name

          choices.each do |choice_text, action|
            @current_dialog_data.not_nil!.add_choice(choice_text) do
              action.call
            end
          end
          @current_dialog_data.not_nil!.on_complete = on_overall_complete

          Core::Engine.instance.show_dialog(@current_dialog_data.not_nil!)
        end

        def update(dt : Float32)
          if cd = @current_dialog_data
            unless cd.visible
              @current_dialog_data = nil
            end
          end
        end

        def draw
          # Dialogs are drawn by the Engine's main draw loop
        end

        private def calculate_dialog_rect(text : String, num_choices : Int = 0) : Tuple(RL::Vector2, RL::Vector2)
          engine = Core::Engine.instance
          screen_w = engine.window_width
          screen_h = engine.window_height

          dialog_w = (text.size * 8).clamp(200, screen_w - 20).to_f
          dialog_h = 80.0 + (num_choices * 30)

          pos_x = @character.position.x + @dialog_offset.x - (dialog_w / 2)
          pos_y = @character.position.y + @dialog_offset.y - dialog_h

          pos_x = pos_x.clamp(10.0, screen_w - dialog_w - 10.0)
          pos_y = pos_y.clamp(10.0, screen_h - dialog_h - 10.0)

          return RL::Vector2.new(x: pos_x, y: pos_y), RL::Vector2.new(x: dialog_w, y: dialog_h)
        end
      end
    end
  end
end
