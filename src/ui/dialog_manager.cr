require "./dialog"

module PointClickEngine
  module UI
    class DialogManager
      property current_dialog : Dialog?
      property dialog_queue : Array(Dialog) = [] of Dialog
      property message_display_time : Float32 = 3.0f32

      def initialize
        @current_dialog = nil
        @message_timer = 0.0f32
        @showing_message = false
      end

      def show_dialog(character_name : String, text : String, choices : Array(DialogChoice)? = nil)
        pos = Raylib::Vector2.new(x: 100f32, y: 400f32)
        size = Raylib::Vector2.new(x: 824f32, y: 200f32)

        dialog = Dialog.new(text, pos, size)
        dialog.character_name = character_name
        dialog.choices = choices if choices
        dialog.visible = true

        @current_dialog = dialog
      end

      def show_message(text : String, duration : Float32 = 3.0f32)
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
      end

      def draw
        @current_dialog.try &.draw
      end

      def close_current_dialog
        @current_dialog = nil
      end

      def is_dialog_active? : Bool
        !@current_dialog.nil?
      end
    end
  end
end
