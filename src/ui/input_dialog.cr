# Text input dialog for user text entry
#
# Provides a modal dialog with a text input field for entering
# text like safe combinations, names, passwords, etc.

module PointClickEngine
  module UI
    # A dialog with text input capability
    class InputDialog
      property prompt : String
      property input_text : String = ""
      property max_length : Int32 = 32
      property visible : Bool = false
      property position : RL::Vector2
      property size : RL::Vector2
      property callback : Proc(String, Nil)?

      # Visual properties
      property background_color : RL::Color = RL::Color.new(r: 20, g: 20, b: 30, a: 240)
      property text_color : RL::Color = RL::WHITE
      property input_bg_color : RL::Color = RL::Color.new(r: 40, g: 40, b: 50, a: 255)
      property cursor_color : RL::Color = RL::Color.new(r: 255, g: 255, b: 100, a: 255)
      property border_color : RL::Color = RL::Color.new(r: 100, g: 100, b: 120, a: 255)

      # Animation
      property cursor_blink_timer : Float32 = 0.0f32
      property cursor_visible : Bool = true

      # Input state
      property ready_to_process_input : Bool = false
      @frame_delay : Int32 = 0

      def initialize(@prompt : String, position : RL::Vector2? = nil, size : RL::Vector2? = nil)
        # Default centered position
        @position = position || RL::Vector2.new(x: 262f32, y: 284f32)
        @size = size || RL::Vector2.new(x: 500f32, y: 200f32)
      end

      def show(&callback : String ->)
        @callback = callback
        @input_text = ""
        @visible = true
        @ready_to_process_input = false
        @frame_delay = 2
      end

      def show_with_default(default_text : String, &callback : String ->)
        @callback = callback
        @input_text = default_text
        @visible = true
        @ready_to_process_input = false
        @frame_delay = 2
      end

      def hide
        @visible = false
      end

      def update(dt : Float32)
        return unless @visible

        # Frame delay before accepting input
        if @frame_delay > 0
          @frame_delay -= 1
          return
        end
        @ready_to_process_input = true

        # Cursor blink animation
        @cursor_blink_timer += dt
        if @cursor_blink_timer >= 0.5f32
          @cursor_blink_timer = 0.0f32
          @cursor_visible = !@cursor_visible
        end

        # Handle keyboard input
        handle_keyboard_input
      end

      def draw
        return unless @visible

        pos = @position
        sz = @size

        # Draw background
        RL.draw_rectangle_rounded(
          RL::Rectangle.new(x: pos.x, y: pos.y, width: sz.x, height: sz.y),
          0.1f32, 8, @background_color
        )

        # Draw border
        RL.draw_rectangle_rounded_lines(
          RL::Rectangle.new(x: pos.x, y: pos.y, width: sz.x, height: sz.y),
          0.1f32, 8, 2.0f32, @border_color
        )

        # Draw prompt text
        prompt_x = pos.x + 20
        prompt_y = pos.y + 20
        RL.draw_text(@prompt, prompt_x.to_i, prompt_y.to_i, 20, @text_color)

        # Draw input field background
        input_x = pos.x + 20
        input_y = pos.y + 60
        input_width = sz.x - 40
        input_height = 40f32

        RL.draw_rectangle_rounded(
          RL::Rectangle.new(x: input_x, y: input_y, width: input_width, height: input_height),
          0.2f32, 4, @input_bg_color
        )

        # Draw input text
        text_x = input_x + 10
        text_y = input_y + 10
        RL.draw_text(@input_text, text_x.to_i, text_y.to_i, 20, @text_color)

        # Draw cursor
        if @cursor_visible && @ready_to_process_input
          cursor_x = text_x + RL.measure_text(@input_text, 20)
          RL.draw_rectangle(cursor_x.to_i, text_y.to_i, 2, 20, @cursor_color)
        end

        # Draw instructions
        instructions = "Enter: Confirm | Escape: Cancel"
        instr_width = RL.measure_text(instructions, 16)
        instr_x = pos.x + (sz.x - instr_width) / 2
        instr_y = pos.y + sz.y - 40
        RL.draw_text(instructions, instr_x.to_i, instr_y.to_i, 16, RL::Color.new(r: 150, g: 150, b: 150, a: 255))
      end

      private def handle_keyboard_input
        return unless @ready_to_process_input

        # Handle Enter key - confirm input
        if RL.key_pressed?(RL::KeyboardKey::Enter) || RL.key_pressed?(RL::KeyboardKey::KpEnter)
          confirm_input
          return
        end

        # Handle Escape key - cancel
        if RL.key_pressed?(RL::KeyboardKey::Escape)
          cancel_input
          return
        end

        # Handle Backspace
        if RL.key_pressed?(RL::KeyboardKey::Backspace)
          if @input_text.size > 0
            @input_text = @input_text[0...-1]
          end
          return
        end

        # Handle character input
        char = RL.get_char_pressed
        while char > 0
          # Only accept printable ASCII characters
          if char >= 32 && char <= 126 && @input_text.size < @max_length
            @input_text += char.chr
          end
          char = RL.get_char_pressed
        end
      end

      private def confirm_input
        @visible = false
        @callback.try(&.call(@input_text))
      end

      private def cancel_input
        @visible = false
        @callback.try(&.call(""))
      end
    end
  end
end
