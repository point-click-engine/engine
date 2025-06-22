require "./dialog"
require "./dialog_portrait"
require "./floating_dialog"
require "./floating_text"

module PointClickEngine
  module UI
    class DialogManager
      property current_dialog : Dialog?
      property dialog_queue : Array(Dialog) = [] of Dialog
      property message_display_time : Float32 = 3.0f32
      property portrait_manager : PortraitManager
      property floating_manager : FloatingDialogManager
      property enable_portraits : Bool = false
      property enable_floating : Bool = true

      def initialize
        @current_dialog = nil
        @message_timer = 0.0f32
        @showing_message = false
        @portrait_manager = PortraitManager.new
        @floating_manager = FloatingDialogManager.new
      end

      def show_dialog(character_name : String, text : String, choices : Array(DialogChoice)? = nil, expression : PortraitExpression = PortraitExpression::Neutral)
        pos = Raylib::Vector2.new(x: 100f32, y: 400f32)
        size = Raylib::Vector2.new(x: 824f32, y: 200f32)

        dialog = Dialog.new(text, pos, size)
        dialog.character_name = character_name
        dialog.choices = choices if choices
        dialog.visible = true

        @current_dialog = dialog

        # Show portrait if enabled and character name is provided
        if @enable_portraits && !character_name.empty?
          @portrait_manager.show_portrait(character_name, expression)
          @portrait_manager.start_talking
        end
      end

      # Show floating dialog above character position
      def show_floating_dialog(character_name : String, text : String, character_pos : RL::Vector2,
                               duration : Float32? = nil, style : DialogStyle = DialogStyle::Bubble)
        return unless @enable_floating
        @floating_manager.show_dialog(character_name, text, character_pos, duration, style)
      end

      # Show floating dialog for character (convenience method)
      def show_character_dialog(character_name : String, text : String, character_pos : RL::Vector2,
                                style : DialogStyle = DialogStyle::Bubble)
        if @enable_floating
          @floating_manager.show_dialog(character_name, text, character_pos, nil, style)
        elsif @enable_portraits
          show_dialog(character_name, text)
        end
      end

      def show_message(text : String, duration : Float32 = 3.0f32)
        if @enable_floating
          # Try to show message as floating text near player
          if engine = Core::Engine.instance
            if player = engine.player
              @floating_manager.show_dialog("", text, player.position, duration, DialogStyle::Rectangle)
              return
            end
          end
        end

        # Fallback to regular dialog
        show_dialog("", text)
        @showing_message = true
        @message_timer = duration
      end

      def show_choice(prompt : String, options : Array(String), callback : Proc(Int32, Nil))
        choices = options.map_with_index do |option, index|
          DialogChoice.new(option, -> {
            callback.call(index + 1)
            close_current_dialog
          })
        end

        show_dialog("", prompt, choices)
      end

      def update(dt : Float32)
        if @showing_message && @message_timer > 0
          @message_timer -= dt
          if @message_timer <= 0
            close_current_dialog
            @showing_message = false
          end
        end

        @current_dialog.try &.update(dt)
        @portrait_manager.update(dt)
        @floating_manager.update(dt)
      end

      def draw
        @current_dialog.try &.draw
        @portrait_manager.draw if @enable_portraits
        @floating_manager.draw if @enable_floating
      end

      def close_current_dialog
        @current_dialog = nil
        @portrait_manager.stop_talking
        @portrait_manager.hide_portrait
      end

      # Add a character portrait
      def add_character_portrait(character_name : String, texture_path : String) : DialogPortrait
        @portrait_manager.add_portrait(character_name, texture_path)
      end

      # Set expression for current speaker
      def set_speaker_expression(expression : PortraitExpression)
        @portrait_manager.set_expression(expression)
      end

      # Configure portrait positioning
      def set_portrait_position(position : PortraitPosition)
        @portrait_manager.default_position = position
      end

      # Toggle portrait system
      def toggle_portraits(enabled : Bool)
        @enable_portraits = enabled
        if !enabled
          @portrait_manager.hide_portrait
        end
      end

      # Cleanup resources
      def cleanup
        @portrait_manager.cleanup
      end

      def is_dialog_active? : Bool
        !@current_dialog.nil?
      end
    end
  end
end
