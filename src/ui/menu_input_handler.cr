require "raylib-cr"

module PointClickEngine
  module UI
    # Handles input processing for menu systems
    #
    # The MenuInputHandler centralizes all input logic for menus including:
    # - Keyboard navigation (arrow keys, Enter, Escape)
    # - Mouse interaction (hover, click)
    # - Input validation and filtering
    # - Navigation state management
    class MenuInputHandler
      # Input actions that can be performed on menus
      enum InputAction
        None
        NavigateUp
        NavigateDown
        NavigateLeft
        NavigateRight
        Select
        Cancel
        MouseHover
        MouseClick
      end

      # Current input state
      property mouse_position : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      property last_input_time : Float64 = 0.0
      property input_repeat_delay : Float64 = 0.15

      # Callback for input events
      property on_navigate : Proc(InputAction, Nil)?
      property on_select : Proc(Int32, Nil)?
      property on_cancel : Proc(Nil)?
      property on_mouse_hover : Proc(Int32, Nil)?

      # Input configuration
      property keyboard_navigation_enabled : Bool = true
      property mouse_navigation_enabled : Bool = true
      property input_repeat_enabled : Bool = true

      def initialize
      end

      # Processes input for the current frame
      #
      # - *dt* : Delta time since last frame
      #
      # Returns: The input action that occurred this frame
      def process_input(dt : Float64) : InputAction
        current_time = Time.monotonic.total_seconds

        # Update mouse position
        @mouse_position = RL.get_mouse_position

        # Process keyboard input
        if @keyboard_navigation_enabled
          keyboard_action = process_keyboard_input(current_time)
          return keyboard_action if keyboard_action != InputAction::None
        end

        # Process mouse input
        if @mouse_navigation_enabled
          mouse_action = process_mouse_input
          return mouse_action if mouse_action != InputAction::None
        end

        InputAction::None
      end

      # Processes keyboard input and navigation
      private def process_keyboard_input(current_time : Float64) : InputAction
        # Check for input repeat delay
        if @input_repeat_enabled && (current_time - @last_input_time) < @input_repeat_delay
          return InputAction::None
        end

        # Navigation keys
        if RL.key_pressed?(RL::KeyboardKey::Up) || RL.key_pressed?(RL::KeyboardKey::W)
          @last_input_time = current_time
          @on_navigate.try(&.call(InputAction::NavigateUp))
          return InputAction::NavigateUp
        elsif RL.key_pressed?(RL::KeyboardKey::Down) || RL.key_pressed?(RL::KeyboardKey::S)
          @last_input_time = current_time
          @on_navigate.try(&.call(InputAction::NavigateDown))
          return InputAction::NavigateDown
        elsif RL.key_pressed?(RL::KeyboardKey::Left) || RL.key_pressed?(RL::KeyboardKey::A)
          @last_input_time = current_time
          @on_navigate.try(&.call(InputAction::NavigateLeft))
          return InputAction::NavigateLeft
        elsif RL.key_pressed?(RL::KeyboardKey::Right) || RL.key_pressed?(RL::KeyboardKey::D)
          @last_input_time = current_time
          @on_navigate.try(&.call(InputAction::NavigateRight))
          return InputAction::NavigateRight
        end

        # Action keys
        if RL.key_pressed?(RL::KeyboardKey::Enter) || RL.key_pressed?(RL::KeyboardKey::Space)
          @last_input_time = current_time
          return InputAction::Select
        elsif RL.key_pressed?(RL::KeyboardKey::Escape)
          @last_input_time = current_time
          @on_cancel.try(&.call)
          return InputAction::Cancel
        end

        InputAction::None
      end

      # Processes mouse input and interaction
      private def process_mouse_input : InputAction
        # Check for mouse click
        if RL::MouseButton::Left.pressed?
          return InputAction::MouseClick
        end

        # Mouse movement triggers hover
        InputAction::MouseHover
      end

      # Checks if a point is within a rectangular area
      def point_in_rect?(point : RL::Vector2, rect : RL::Rectangle) : Bool
        point.x >= rect.x && point.x <= rect.x + rect.width &&
          point.y >= rect.y && point.y <= rect.y + rect.height
      end

      # Checks if mouse is hovering over a menu item
      #
      # - *item_bounds* : Rectangle defining the menu item area
      #
      # Returns: true if mouse is over the item
      def mouse_over_item?(item_bounds : RL::Rectangle) : Bool
        point_in_rect?(@mouse_position, item_bounds)
      end

      # Processes menu item interaction
      #
      # - *item_index* : Index of the menu item
      # - *item_bounds* : Rectangle defining the menu item area
      # - *item_enabled* : Whether the item can be interacted with
      #
      # Returns: true if the item was clicked
      def process_item_interaction(item_index : Int32, item_bounds : RL::Rectangle, item_enabled : Bool = true) : Bool
        return false unless item_enabled

        is_hovering = mouse_over_item?(item_bounds)

        if is_hovering
          @on_mouse_hover.try(&.call(item_index))

          if RL::MouseButton::Left.pressed?
            @on_select.try(&.call(item_index))
            return true
          end
        end

        false
      end

      # Sets up navigation callbacks
      def on_navigation(&block : InputAction -> Nil)
        @on_navigate = block
      end

      # Sets up selection callback
      def on_selection(&block : Int32 -> Nil)
        @on_select = block
      end

      # Sets up cancel callback
      def on_cancellation(&block : -> Nil)
        @on_cancel = block
      end

      # Sets up hover callback
      def on_hover(&block : Int32 -> Nil)
        @on_mouse_hover = block
      end

      # Enables or disables keyboard navigation
      def set_keyboard_navigation(enabled : Bool)
        @keyboard_navigation_enabled = enabled
      end

      # Enables or disables mouse navigation
      def set_mouse_navigation(enabled : Bool)
        @mouse_navigation_enabled = enabled
      end

      # Sets input repeat delay for keyboard navigation
      def set_input_repeat_delay(delay : Float64)
        @input_repeat_delay = delay
      end

      # Enables or disables input repeat
      def set_input_repeat(enabled : Bool)
        @input_repeat_enabled = enabled
      end

      # Gets current mouse position
      def get_mouse_position : RL::Vector2
        @mouse_position
      end

      # Checks if any navigation key is currently held
      def navigation_key_held? : Bool
        RL.key_down?(RL::KeyboardKey::Up) || RL.key_down?(RL::KeyboardKey::Down) ||
          RL.key_down?(RL::KeyboardKey::Left) || RL.key_down?(RL::KeyboardKey::Right) ||
          RL.key_down?(RL::KeyboardKey::W) || RL.key_down?(RL::KeyboardKey::S) ||
          RL.key_down?(RL::KeyboardKey::A) || RL.key_down?(RL::KeyboardKey::D)
      end

      # Checks if any action key is currently held
      def action_key_held? : Bool
        RL.key_down?(RL::KeyboardKey::Enter) || RL.key_down?(RL::KeyboardKey::Space) ||
          RL.key_down?(RL::KeyboardKey::Escape)
      end

      # Resets input state (useful for menu transitions)
      def reset_input_state
        @last_input_time = 0.0
        @mouse_position = RL::Vector2.new(x: 0, y: 0)
      end

      # Updates input configuration from settings
      def update_from_settings(settings : Hash(String, String))
        if delay = settings["input_repeat_delay"]?
          @input_repeat_delay = delay.to_f64
        end

        if enabled = settings["keyboard_navigation"]?
          @keyboard_navigation_enabled = enabled.downcase == "true"
        end

        if enabled = settings["mouse_navigation"]?
          @mouse_navigation_enabled = enabled.downcase == "true"
        end
      end

      # Gets input statistics for debugging
      def get_input_stats : Hash(String, Bool | Float32 | Float64)
        {
          "keyboard_enabled" => @keyboard_navigation_enabled,
          "mouse_enabled"    => @mouse_navigation_enabled,
          "repeat_enabled"   => @input_repeat_enabled,
          "repeat_delay"     => @input_repeat_delay,
          "last_input_time"  => @last_input_time,
          "mouse_x"          => @mouse_position.x,
          "mouse_y"          => @mouse_position.y,
        }
      end

      # Validates input configuration
      def validate_configuration : Array(String)
        issues = [] of String

        if @input_repeat_delay < 0.0
          issues << "Input repeat delay cannot be negative"
        end

        if @input_repeat_delay > 1.0
          issues << "Input repeat delay is unusually high (#{@input_repeat_delay}s)"
        end

        if !@keyboard_navigation_enabled && !@mouse_navigation_enabled
          issues << "All input methods are disabled"
        end

        issues
      end
    end
  end
end
