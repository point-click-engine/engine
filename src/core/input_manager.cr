# Input management system for the Point & Click Engine
#
# Centralizes input handling, event processing, and input state management.
# Extracted from the Engine class to provide better separation of concerns
# and more sophisticated input handling capabilities.

require "raylib-cr"
require "./error_handling"
require "./game_constants"

# Using full Raylib module name to avoid alias conflicts

module PointClickEngine
  module Core
    # Manages all input-related operations including event processing, input state, and coordination
    #
    # The InputManager centralizes input handling logic that was previously
    # scattered throughout the Engine class. It provides priority-based input
    # processing, input blocking for UI elements, and coordinated event handling.
    #
    # ## Features
    # - Priority-based input processing
    # - Input blocking for dialogs and UI
    # - Event coordination between systems
    # - Input state tracking and validation
    # - Keyboard and mouse event handling
    # - Customizable input mappings
    #
    # ## Usage
    # ```
    # manager = InputManager.new
    # manager.add_input_handler(ui_handler, priority: 10)
    # manager.add_input_handler(game_handler, priority: 5)
    # manager.process_input(dt)
    # ```
    class InputManager
      include ErrorHelpers
      include GameConstants
      include IInputManager

      # Input handler with priority
      private record InputHandler, handler : Proc(Float32, Bool), priority : Int32, enabled : Bool = true

      # Named input handler with priority
      private record NamedInputHandler, name : String, handler : Proc(Float32, Bool), priority : Int32, enabled : Bool = true

      # Current input blocking state
      @input_blocked : Bool = false
      @input_block_source : String?
      @input_block_frames : Int32 = 0

      # Input handlers ordered by priority (higher priority first)
      @input_handlers : Array(InputHandler) = [] of InputHandler
      
      # Named input handlers for easier management
      @named_handlers : Hash(String, NamedInputHandler) = {} of String => NamedInputHandler
      
      # Track input consumption by handler
      @consumed_inputs : Hash(String, String) = {} of String => String

      # Current input state tracking
      @mouse_position : Raylib::Vector2 = Raylib::Vector2.new
      @previous_mouse_position : Raylib::Vector2 = Raylib::Vector2.new
      @mouse_delta : Raylib::Vector2 = Raylib::Vector2.new

      # Key state tracking
      @pressed_keys : Set(Raylib::KeyboardKey) = Set(Raylib::KeyboardKey).new
      @held_keys : Set(Raylib::KeyboardKey) = Set(Raylib::KeyboardKey).new
      @released_keys : Set(Raylib::KeyboardKey) = Set(Raylib::KeyboardKey).new

      # Mouse state tracking
      @pressed_buttons : Set(Raylib::MouseButton) = Set(Raylib::MouseButton).new
      @held_buttons : Set(Raylib::MouseButton) = Set(Raylib::MouseButton).new
      @released_buttons : Set(Raylib::MouseButton) = Set(Raylib::MouseButton).new

      # Input timing for double-clicks and long presses
      @last_click_time : Float32 = 0.0_f32
      @last_click_position : Raylib::Vector2 = Raylib::Vector2.new
      @click_count : Int32 = 0

      # Frame-based input consumption tracking
      @mouse_consumed_this_frame : Bool = false
      @keyboard_consumed_this_frame : Bool = false

      def initialize
        ErrorLogger.info("InputManager initialized")
      end

      # Add an input handler with priority
      #
      # Higher priority handlers are processed first. UI handlers should
      # typically have higher priority than game handlers.
      #
      # - *handler* : The input processing function
      # - *priority* : Processing priority (higher = first)
      # - *enabled* : Whether the handler is initially enabled
      def add_input_handler(handler : Proc(Float32, Bool), priority : Int32, enabled : Bool = true)
        input_handler = InputHandler.new(handler, priority, enabled)
        @input_handlers << input_handler
        @input_handlers.sort_by! { |h| -h.priority } # Sort descending by priority
        ErrorLogger.debug("Input handler added with priority #{priority}")
      end

      # Remove an input handler
      def remove_input_handler(handler : Proc(Float32, Bool)) : Bool
        initial_size = @input_handlers.size
        @input_handlers.reject! { |h| h.handler == handler }
        removed = @input_handlers.size < initial_size
        ErrorLogger.debug("Input handler removed: #{removed}") if removed
        removed
      end

      # Register a named input handler with a block
      #
      # Named handlers are easier to manage and remove later.
      # The handler should return true if it consumed the input.
      #
      # - *name* : Unique name for the handler
      # - *priority* : Processing priority (higher = first)
      # - *enabled* : Whether the handler is initially enabled
      def register_handler(name : String, priority : Int32, enabled : Bool = true, &handler : Float32 -> Bool)
        handler_proc = handler
        named_handler = NamedInputHandler.new(name, handler_proc, priority, enabled)
        @named_handlers[name] = named_handler
        
        # Also add to the main handlers array for processing
        input_handler = InputHandler.new(handler_proc, priority, enabled)
        @input_handlers << input_handler
        @input_handlers.sort_by! { |h| -h.priority }
        
        ErrorLogger.debug("Named input handler '#{name}' registered with priority #{priority}")
      end

      # Register a named input handler (non-block version)
      #
      # For simpler cases where you just need a placeholder handler.
      # Creates a no-op handler that doesn't consume input.
      #
      # - *name* : Unique name for the handler
      # - *priority* : Processing priority (higher = first)
      # - *enabled* : Whether the handler is initially enabled
      def register_handler(name : String, priority : Int32, enabled : Bool = true)
        handler_proc = ->(dt : Float32) { false }
        named_handler = NamedInputHandler.new(name, handler_proc, priority, enabled)
        @named_handlers[name] = named_handler
        
        # Also add to the main handlers array for processing
        input_handler = InputHandler.new(handler_proc, priority, enabled)
        @input_handlers << input_handler
        @input_handlers.sort_by! { |h| -h.priority }
        
        ErrorLogger.debug("Named input handler '#{name}' registered with priority #{priority}")
      end

      # Unregister a named input handler
      #
      # - *name* : Name of the handler to remove
      #
      # Returns true if the handler was found and removed
      def unregister_handler(name : String) : Bool
        if handler = @named_handlers.delete(name)
          # Remove from main handlers array
          @input_handlers.reject! { |h| h.handler == handler.handler }
          ErrorLogger.debug("Named input handler '#{name}' unregistered")
          true
        else
          false
        end
      end

      # Check if a specific input has been consumed
      #
      # - *input_type* : Type of input to check (e.g., "mouse_click", "key_space")
      #
      # Returns true if the input has been consumed this frame
      def is_consumed(input_type : String) : Bool
        @consumed_inputs.has_key?(input_type)
      end

      # Mark an input as consumed
      #
      # - *input_type* : Type of input to mark as consumed
      # - *handler_name* : Name of the handler consuming the input
      def consume_input(input_type : String, handler_name : String)
        @consumed_inputs[input_type] = handler_name
        ErrorLogger.debug("Input '#{input_type}' consumed by '#{handler_name}'")
      end

      # Enable or disable an input handler
      def set_handler_enabled(handler : Proc(Float32, Bool), enabled : Bool)
        @input_handlers.each_with_index do |h, i|
          if h.handler == handler
            @input_handlers[i] = InputHandler.new(h.handler, h.priority, enabled)
            ErrorLogger.debug("Input handler enabled: #{enabled}")
            return
          end
        end
      end

      # Block all input for a specified number of frames
      #
      # Useful for preventing input during scene transitions or cutscenes.
      #
      # - *frames* : Number of frames to block input
      # - *source* : Description of what is blocking input
      def block_input(frames : Int32, source : String = "unknown")
        @input_blocked = true
        @input_block_frames = frames
        @input_block_source = source
        ErrorLogger.debug("Input blocked for #{frames} frames by #{source}")
      end

      # Unblock input immediately
      def unblock_input
        @input_blocked = false
        @input_block_frames = 0
        @input_block_source = nil
        ErrorLogger.debug("Input unblocked")
      end

      # Check if input is currently blocked
      def input_blocked? : Bool
        @input_blocked
      end

      # Get the source of input blocking
      def input_block_source : String?
        @input_block_source
      end

      # Update the input manager state
      #
      # This is an alias for process_input for API compatibility.
      #
      # - *dt* : Delta time since last frame
      def update(dt : Float32)
        process_input(dt)
      end

      # Main input processing method
      #
      # Processes all input events and distributes them to registered handlers
      # based on priority. Updates input state and handles frame-based cleanup.
      #
      # - *dt* : Delta time since last frame
      def process_input(dt : Float32)
        update_input_state(dt)

        # Handle input blocking countdown
        if @input_blocked && @input_block_frames > 0
          @input_block_frames -= 1
          if @input_block_frames <= 0
            unblock_input
          end
          return # Skip input processing while blocked
        end

        # Process handlers in priority order
        @input_handlers.each do |handler|
          next unless handler.enabled

          # Call handler and check if it consumed input
          consumed = handler.handler.call(dt)

          # If input was consumed by a high-priority handler, stop processing
          break if consumed
        end

        # Reset frame-based consumption flags
        @mouse_consumed_this_frame = false
        @keyboard_consumed_this_frame = false
        
        # Reset consumed inputs for next frame
        @consumed_inputs.clear
      end

      # Mouse input methods

      def mouse_position : Raylib::Vector2
        @mouse_position.dup
      end

      def mouse_delta : Raylib::Vector2
        @mouse_delta.dup
      end

      def mouse_button_pressed?(button : Raylib::MouseButton) : Bool
        return false if @mouse_consumed_this_frame
        @pressed_buttons.includes?(button)
      end

      def mouse_button_held?(button : Raylib::MouseButton) : Bool
        @held_buttons.includes?(button)
      end

      def mouse_button_released?(button : Raylib::MouseButton) : Bool
        return false if @mouse_consumed_this_frame
        @released_buttons.includes?(button)
      end

      def consume_mouse_input
        @mouse_consumed_this_frame = true
      end

      def mouse_consumed? : Bool
        @mouse_consumed_this_frame
      end

      # Keyboard input methods

      def key_pressed?(key : Raylib::KeyboardKey) : Bool
        return false if @keyboard_consumed_this_frame
        @pressed_keys.includes?(key)
      end

      def key_held?(key : Raylib::KeyboardKey) : Bool
        @held_keys.includes?(key)
      end

      def key_released?(key : Raylib::KeyboardKey) : Bool
        return false if @keyboard_consumed_this_frame
        @released_keys.includes?(key)
      end

      def consume_keyboard_input
        @keyboard_consumed_this_frame = true
      end

      def keyboard_consumed? : Bool
        @keyboard_consumed_this_frame
      end

      # Advanced input detection

      def double_click_detected? : Bool
        @click_count >= 2
      end

      def click_count : Int32
        @click_count
      end

      def last_click_position : Raylib::Vector2
        @last_click_position.dup
      end

      # Input validation helpers

      def mouse_in_bounds?(bounds : Raylib::Rectangle) : Bool
        RL.check_collision_point_rec?(@mouse_position, bounds)
      end

      def mouse_moved? : Bool
        @mouse_delta.x.abs > 0.1 || @mouse_delta.y.abs > 0.1
      end

      def any_key_pressed? : Bool
        return false if @keyboard_consumed_this_frame
        !@pressed_keys.empty?
      end

      def any_mouse_button_pressed? : Bool
        return false if @mouse_consumed_this_frame
        !@pressed_buttons.empty?
      end

      # Input mapping support (for future extension)

      def map_key_to_action(key : Raylib::KeyboardKey, action : String)
        # Future implementation for customizable key bindings
        ErrorLogger.debug("Key mapping added: #{key} -> #{action}")
      end

      def get_action_for_key(key : Raylib::KeyboardKey) : String?
        # Future implementation for action lookup
        nil
      end

      private def update_input_state(dt : Float32)
        # Update mouse state
        @previous_mouse_position = @mouse_position
        @mouse_position = RL.get_mouse_position
        @mouse_delta = Raylib::Vector2.new(
          x: @mouse_position.x - @previous_mouse_position.x,
          y: @mouse_position.y - @previous_mouse_position.y
        )

        # Update mouse button states
        @pressed_buttons.clear
        @released_buttons.clear

        check_mouse_button_state(Raylib::MouseButton::Left)
        check_mouse_button_state(Raylib::MouseButton::Right)
        check_mouse_button_state(Raylib::MouseButton::Middle)

        # Update keyboard states
        @pressed_keys.clear
        @released_keys.clear

        # Check common keys (this could be expanded)
        check_key_state(Raylib::KeyboardKey::Escape)
        check_key_state(Raylib::KeyboardKey::Space)
        check_key_state(Raylib::KeyboardKey::Enter)
        check_key_state(Raylib::KeyboardKey::Tab)
        check_key_state(Raylib::KeyboardKey::F1)
        check_key_state(Raylib::KeyboardKey::One)
        check_key_state(Raylib::KeyboardKey::Two)
        check_key_state(Raylib::KeyboardKey::Three)
        check_key_state(Raylib::KeyboardKey::Four)
        check_key_state(Raylib::KeyboardKey::Five)
        check_key_state(Raylib::KeyboardKey::Six)

        # Handle double-click detection
        if @pressed_buttons.includes?(Raylib::MouseButton::Left)
          current_time = Time.monotonic.total_seconds.to_f32
          time_since_last = current_time - @last_click_time
          distance_moved = Utils::VectorMath.distance(@mouse_position, @last_click_position)

          if time_since_last < DOUBLE_CLICK_TIME && distance_moved < DRAG_THRESHOLD
            @click_count += 1
          else
            @click_count = 1
          end

          @last_click_time = current_time
          @last_click_position = @mouse_position
        end

        # Reset click count after timeout
        if Time.monotonic.total_seconds.to_f32 - @last_click_time > DOUBLE_CLICK_TIME
          @click_count = 0
        end
      end

      private def check_mouse_button_state(button : Raylib::MouseButton)
        currently_pressed = RL.mouse_button_down?(button)
        was_held = @held_buttons.includes?(button)

        if currently_pressed && !was_held
          @pressed_buttons.add(button)
          @held_buttons.add(button)
        elsif !currently_pressed && was_held
          @released_buttons.add(button)
          @held_buttons.delete(button)
        end
      end

      private def check_key_state(key : Raylib::KeyboardKey)
        currently_pressed = RL.key_down?(key)
        was_held = @held_keys.includes?(key)

        if currently_pressed && !was_held
          @pressed_keys.add(key)
          @held_keys.add(key)
        elsif !currently_pressed && was_held
          @released_keys.add(key)
          @held_keys.delete(key)
        end
      end
    end
  end
end
