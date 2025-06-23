# Global input state management
module PointClickEngine
  module Core
    # Manages input state to prevent multiple systems from processing the same input
    class InputState
      @@mouse_consumed = false
      @@keyboard_consumed = false

      # Reset input state at the start of each frame
      def self.reset
        @@mouse_consumed = false
        @@keyboard_consumed = false
      end

      # Check if mouse input is available and consume it
      def self.consume_mouse_click : Bool
        return false if @@mouse_consumed
        return false unless RL.mouse_button_pressed?(Raylib::MouseButton::Left)

        @@mouse_consumed = true
        true
      end

      # Check if mouse was already consumed this frame
      def self.mouse_consumed? : Bool
        @@mouse_consumed
      end

      # Just check if mouse is pressed without consuming
      def self.mouse_pressed? : Bool
        RL.mouse_button_pressed?(Raylib::MouseButton::Left)
      end
    end
  end
end
