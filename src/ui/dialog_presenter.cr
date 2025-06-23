# Dialog Presenter - Handles the presentation layer for dialogs
module PointClickEngine
  module UI
    # Manages how dialogs are presented to the player
    class DialogPresenter
      # Character speech colors
      CHARACTER_COLORS = {
        "butler"    => RL::Color.new(r: 200, g: 200, b: 255, a: 255), # Light blue
        "scientist" => RL::Color.new(r: 255, g: 200, b: 200, a: 255), # Light red
        "player"    => RL::Color.new(r: 200, g: 255, b: 200, a: 255), # Light green
      }

      DEFAULT_COLOR   = RL::WHITE
      SPEECH_OFFSET_Y = 20f32

      def initialize(@dialog_manager : DialogManager)
      end

      # Show character speech as floating text
      def show_character_speech(text : String, character_name : String)
        return if text.empty?

        position = get_character_position(character_name)
        color = get_character_color(character_name)

        @dialog_manager.show_floating_text(
          text,
          position,
          color: color,
          duration: 0.0 # Stay until next dialog
        )
      end

      # Show dialog choices at the bottom of the screen
      def show_choices(choices : Array(String), &callback : Int32 ->)
        @dialog_manager.show_dialog_choices("", choices, &callback)
      end

      private def get_character_position(character_name : String) : RL::Vector2
        if scene = Core::Engine.instance.current_scene
          if character = scene.get_character(character_name)
            # Position above character's head
            return RL::Vector2.new(
              x: character.position.x + character.size.x / 2,
              y: character.position.y - SPEECH_OFFSET_Y
            )
          end
        end

        # Fallback: center of screen
        RL::Vector2.new(x: 512, y: 100)
      end

      private def get_character_color(character_name : String) : RL::Color
        CHARACTER_COLORS[character_name.downcase]? || DEFAULT_COLOR
      end
    end
  end
end
