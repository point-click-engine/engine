require "../spec_helper"

# Input handling comprehensive edge case tests
# Tests input manager, event processing, priority handling, and edge cases
describe "Input Handling Comprehensive Edge Case Tests" do
  describe "input manager initialization and setup" do
    it "initializes with correct default state" do
      manager = PointClickEngine::Core::InputManager.new

      # Should start unblocked
      manager.input_blocked?.should be_false
      manager.input_block_source.should be_nil

      # Should have no consumed input initially
      manager.mouse_consumed?.should be_false
      manager.keyboard_consumed?.should be_false

      # Should handle input state queries without crashing
      manager.any_key_pressed?.should be_false
      manager.any_mouse_button_pressed?.should be_false
      manager.double_click_detected?.should be_false
      manager.click_count.should eq(0)
    end

    it "handles handler registration correctly" do
      manager = PointClickEngine::Core::InputManager.new

      # Test basic handler registration
      handler_called = false
      handler = ->(dt : Float32) {
        handler_called = true
        false # Don't consume input
      }

      manager.add_input_handler(handler, priority: 10)

      # Process input to trigger handler
      manager.process_input(0.016_f32)
      handler_called.should be_true

      # Test handler removal
      removed = manager.remove_input_handler(handler)
      removed.should be_true

      # Try to remove again (should fail)
      removed_again = manager.remove_input_handler(handler)
      removed_again.should be_false
    end

    it "handles named handler registration" do
      manager = PointClickEngine::Core::InputManager.new

      # Test named handler registration with block
      ui_handler_called = false
      manager.register_handler("ui_handler", priority: 10) do |dt|
        ui_handler_called = true
        false
      end

      # Test named handler registration without block
      manager.register_handler("placeholder_handler", priority: 5)

      # Process input
      manager.process_input(0.016_f32)
      ui_handler_called.should be_true

      # Test handler unregistration
      removed = manager.unregister_handler("ui_handler")
      removed.should be_true

      # Try to unregister non-existent handler
      removed_missing = manager.unregister_handler("nonexistent_handler")
      removed_missing.should be_false
    end
  end

  describe "input priority and consumption handling" do
    it "processes handlers in priority order" do
      manager = PointClickEngine::Core::InputManager.new

      execution_order = [] of String

      # Add handlers with different priorities
      manager.register_handler("low_priority", priority: 1) do |dt|
        execution_order << "low"
        false
      end

      manager.register_handler("high_priority", priority: 10) do |dt|
        execution_order << "high"
        false
      end

      manager.register_handler("medium_priority", priority: 5) do |dt|
        execution_order << "medium"
        false
      end

      # Process input
      manager.process_input(0.016_f32)

      # Should execute in priority order (high to low)
      execution_order.should eq(["high", "medium", "low"])
    end

    it "stops processing when input is consumed" do
      manager = PointClickEngine::Core::InputManager.new

      execution_order = [] of String

      # High priority handler that consumes input
      manager.register_handler("consuming_handler", priority: 10) do |dt|
        execution_order << "consuming"
        true # Consume input
      end

      # Lower priority handler that should not execute
      manager.register_handler("blocked_handler", priority: 5) do |dt|
        execution_order << "blocked"
        false
      end

      # Process input
      manager.process_input(0.016_f32)

      # Only the consuming handler should execute
      execution_order.should eq(["consuming"])
    end

    it "handles input consumption tracking" do
      manager = PointClickEngine::Core::InputManager.new

      # Test initial state
      manager.is_consumed("mouse_click").should be_false
      manager.is_consumed("key_space").should be_false

      # Mark inputs as consumed
      manager.consume_input("mouse_click", "ui_handler")
      manager.consume_input("key_space", "game_handler")

      # Check consumption state
      manager.is_consumed("mouse_click").should be_true
      manager.is_consumed("key_space").should be_true
      manager.is_consumed("key_enter").should be_false

      # Process input (should clear consumption tracking)
      manager.process_input(0.016_f32)

      # Consumption should be cleared after processing
      manager.is_consumed("mouse_click").should be_false
      manager.is_consumed("key_space").should be_false
    end

    it "handles mouse and keyboard consumption separately" do
      manager = PointClickEngine::Core::InputManager.new

      # Test mouse consumption
      manager.mouse_consumed?.should be_false
      manager.consume_mouse_input
      manager.mouse_consumed?.should be_true

      # Keyboard should still be available
      manager.keyboard_consumed?.should be_false

      # Test keyboard consumption
      manager.consume_keyboard_input
      manager.keyboard_consumed?.should be_true

      # Both should now be consumed
      manager.mouse_consumed?.should be_true
      manager.keyboard_consumed?.should be_true

      # Process input should reset both
      manager.process_input(0.016_f32)
      manager.mouse_consumed?.should be_false
      manager.keyboard_consumed?.should be_false
    end
  end

  describe "input blocking mechanisms" do
    it "handles frame-based input blocking" do
      manager = PointClickEngine::Core::InputManager.new

      handler_calls = 0
      manager.register_handler("test_handler", priority: 10) do |dt|
        handler_calls += 1
        false
      end

      # Normal processing
      manager.process_input(0.016_f32)
      handler_calls.should eq(1)

      # Block input for 3 frames
      manager.block_input(3, "test_blocking")
      manager.input_blocked?.should be_true
      manager.input_block_source.should eq("test_blocking")

      # Process 3 frames while blocked
      3.times do
        manager.process_input(0.016_f32)
      end

      # Handler should not have been called while blocked
      handler_calls.should eq(1)

      # Should automatically unblock after frame count
      manager.input_blocked?.should be_false
      manager.input_block_source.should be_nil

      # Should process normally again
      manager.process_input(0.016_f32)
      handler_calls.should eq(2)
    end

    it "handles manual input blocking and unblocking" do
      manager = PointClickEngine::Core::InputManager.new

      handler_calls = 0
      manager.register_handler("test_handler", priority: 10) do |dt|
        handler_calls += 1
        false
      end

      # Block input indefinitely
      manager.block_input(999, "manual_test")
      manager.input_blocked?.should be_true

      # Process several frames
      5.times do
        manager.process_input(0.016_f32)
      end

      # Should still be blocked
      handler_calls.should eq(0)
      manager.input_blocked?.should be_true

      # Manually unblock
      manager.unblock_input
      manager.input_blocked?.should be_false
      manager.input_block_source.should be_nil

      # Should process normally
      manager.process_input(0.016_f32)
      handler_calls.should eq(1)
    end

    it "handles multiple blocking sources" do
      manager = PointClickEngine::Core::InputManager.new

      # Test different blocking sources
      manager.block_input(2, "cutscene")
      manager.input_block_source.should eq("cutscene")

      # Blocking again should override previous
      manager.block_input(1, "dialog")
      manager.input_block_source.should eq("dialog")

      # Process one frame
      manager.process_input(0.016_f32)

      # Should unblock after dialog frame count (1 frame)
      manager.process_input(0.016_f32)
      manager.input_blocked?.should be_false
    end
  end

  describe "input state tracking edge cases" do
    it "handles rapid input state changes" do
      manager = PointClickEngine::Core::InputManager.new

      # Simulate rapid state changes
      100.times do |i|
        # Alternate between consuming and not consuming
        if i % 2 == 0
          manager.consume_mouse_input
          manager.consume_keyboard_input
        end

        # Process input
        manager.process_input(0.001_f32) # Very fast updates

        # Check state consistency
        unless i % 2 == 0
          manager.mouse_consumed?.should be_false
          manager.keyboard_consumed?.should be_false
        end
      end
    end

    it "handles boundary conditions for click detection" do
      manager = PointClickEngine::Core::InputManager.new

      # Test initial click count
      manager.click_count.should eq(0)
      manager.double_click_detected?.should be_false

      # Simulate time-based click count reset
      manager.process_input(5.0_f32)   # Very long frame time
      manager.click_count.should eq(0) # Should reset due to timeout
    end

    it "handles invalid input parameters" do
      manager = PointClickEngine::Core::InputManager.new

      # Test with empty strings for input consumption (should work)
      manager.consume_input("", "handler") # Should not raise exception

      # Test zero frame blocking
      manager.block_input(0, "instant")
      manager.input_blocked?.should be_true
      manager.process_input(0.016_f32)
      # Note: Zero frame blocking behavior may vary by implementation

      # Test negative frame blocking (should be handled gracefully)
      manager.block_input(-5, "negative")
      manager.input_blocked?.should be_true
      manager.process_input(0.016_f32)
      # Note: Negative frame blocking behavior handled by implementation
    end

    it "handles concurrent input consumption" do
      manager = PointClickEngine::Core::InputManager.new

      concurrent_handlers = [] of String

      # Multiple handlers trying to consume the same input
      5.times do |i|
        manager.register_handler("handler_#{i}", priority: 10 - i) do |dt|
          if !manager.mouse_consumed?
            manager.consume_mouse_input
            concurrent_handlers << "handler_#{i}"
            true # Consume
          else
            false # Already consumed
          end
        end
      end

      # Process input
      manager.process_input(0.016_f32)

      # Only the first (highest priority) handler should consume
      concurrent_handlers.size.should eq(1)
      concurrent_handlers[0].should eq("handler_0")
    end
  end

  describe "input validation and bounds checking" do
    it "handles mouse bounds checking" do
      manager = PointClickEngine::Core::InputManager.new

      # Test various rectangle bounds
      test_bounds = RL::Rectangle.new(x: 100.0_f32, y: 100.0_f32, width: 200.0_f32, height: 150.0_f32)

      # Note: Since we can't easily simulate actual mouse position without graphics,
      # we test that the bounds checking method exists and doesn't crash
      result = manager.mouse_in_bounds?(test_bounds)
      result.should be_a(Bool)

      # Test with edge case bounds
      zero_bounds = RL::Rectangle.new(x: 0.0_f32, y: 0.0_f32, width: 0.0_f32, height: 0.0_f32)
      result = manager.mouse_in_bounds?(zero_bounds)
      result.should be_a(Bool)

      # Test with negative bounds
      negative_bounds = RL::Rectangle.new(x: -100.0_f32, y: -100.0_f32, width: 50.0_f32, height: 50.0_f32)
      result = manager.mouse_in_bounds?(negative_bounds)
      result.should be_a(Bool)
    end

    it "handles movement detection" do
      manager = PointClickEngine::Core::InputManager.new

      # Test initial state
      manager.mouse_moved?.should be_a(Bool)

      # Test mouse position and delta queries
      position = manager.mouse_position
      position.should be_a(RL::Vector2)

      delta = manager.mouse_delta
      delta.should be_a(RL::Vector2)
    end

    it "handles input state queries without graphics" do
      manager = PointClickEngine::Core::InputManager.new

      # All these should work without requiring actual input hardware
      manager.any_key_pressed?.should be_a(Bool)
      manager.any_mouse_button_pressed?.should be_a(Bool)

      # Test specific key/button queries
      manager.key_pressed?(RL::KeyboardKey::Escape).should be_a(Bool)
      manager.key_held?(RL::KeyboardKey::Space).should be_a(Bool)
      manager.key_released?(RL::KeyboardKey::Enter).should be_a(Bool)

      manager.mouse_button_pressed?(RL::MouseButton::Left).should be_a(Bool)
      manager.mouse_button_held?(RL::MouseButton::Right).should be_a(Bool)
      manager.mouse_button_released?(RL::MouseButton::Middle).should be_a(Bool)
    end
  end

  describe "input mapping and configuration" do
    it "handles key action mapping" do
      manager = PointClickEngine::Core::InputManager.new

      # Test key mapping (placeholder implementation)
      manager.map_key_to_action(RL::KeyboardKey::Space, "jump")
      manager.map_key_to_action(RL::KeyboardKey::Enter, "confirm")
      manager.map_key_to_action(RL::KeyboardKey::Escape, "cancel")

      # Test action lookup (placeholder implementation)
      action = manager.get_action_for_key(RL::KeyboardKey::Space)
      action.should be_a(String?) # Should return String? type
    end

    it "handles handler enabling and disabling" do
      manager = PointClickEngine::Core::InputManager.new

      handler_calls = 0
      handler = ->(dt : Float32) {
        handler_calls += 1
        false
      }

      # Add disabled handler
      manager.add_input_handler(handler, priority: 10, enabled: false)

      # Process input - handler should not be called
      manager.process_input(0.016_f32)
      handler_calls.should eq(0)

      # Enable handler
      manager.set_handler_enabled(handler, true)

      # Process input - handler should now be called
      manager.process_input(0.016_f32)
      handler_calls.should eq(1)

      # Disable handler again
      manager.set_handler_enabled(handler, false)

      # Process input - handler should not be called
      manager.process_input(0.016_f32)
      handler_calls.should eq(1) # Same count as before
    end
  end

  describe "performance and stress testing" do
    it "handles many input handlers efficiently" do
      manager = PointClickEngine::Core::InputManager.new

      handler_count = 100
      execution_count = 0

      # Add many handlers
      handler_count.times do |i|
        manager.register_handler("handler_#{i}", priority: i) do |dt|
          execution_count += 1
          false # Don't consume input
        end
      end

      # Test processing performance
      start_time = Time.monotonic
      10.times do
        manager.process_input(0.016_f32)
      end
      process_time = Time.monotonic - start_time

      puts "Input handler performance:"
      puts "  Handlers: #{handler_count}"
      puts "  Processes: 10"
      puts "  Total executions: #{execution_count}"
      puts "  Total time: #{process_time.total_milliseconds.round(2)}ms"
      puts "  Time per process: #{(process_time.total_milliseconds / 10).round(4)}ms"

      # Should execute all handlers for each process
      execution_count.should eq(handler_count * 10)

      # Should be reasonably fast
      (process_time.total_milliseconds / 10).should be < 10.0 # 10ms per process cycle
    end

    it "handles rapid input processing" do
      manager = PointClickEngine::Core::InputManager.new

      process_count = 1000

      # Add a simple handler
      manager.register_handler("rapid_handler", priority: 10) do |dt|
        false
      end

      # Test rapid processing
      start_time = Time.monotonic
      process_count.times do |i|
        manager.process_input(0.001_f32) # 1ms frames (1000 FPS)

        # Occasionally block and unblock input
        if i % 100 == 0
          manager.block_input(1, "rapid_test")
        end
      end
      rapid_time = Time.monotonic - start_time

      puts "Rapid input processing performance:"
      puts "  Processes: #{process_count}"
      puts "  Total time: #{rapid_time.total_milliseconds.round(2)}ms"
      puts "  Time per process: #{(rapid_time.total_milliseconds / process_count).round(6)}ms"

      # Should be very fast
      (rapid_time.total_milliseconds / process_count).should be < 0.1 # 0.1ms per process
    end

    it "manages memory efficiently with many handlers" do
      initial_memory = GC.stats.heap_size

      # Create and destroy many input managers
      50.times do |cycle|
        manager = PointClickEngine::Core::InputManager.new

        # Add many handlers
        20.times do |i|
          manager.register_handler("handler_#{cycle}_#{i}", priority: i) do |dt|
            # Simulate some work
            dummy_calculation = i * cycle + dt
            false
          end
        end

        # Use the manager
        10.times do
          manager.process_input(0.016_f32)
          manager.block_input(1, "memory_test")
          manager.consume_mouse_input
          manager.consume_keyboard_input
        end

        # Manager goes out of scope here
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Input manager memory test: growth = #{memory_growth} bytes"

      # Should not leak significant memory
      memory_growth.should be < 5_000_000 # 5MB limit
    end
  end

  describe "input state global management" do
    it "handles global input state correctly" do
      # Test initial state
      PointClickEngine::Core::InputState.reset
      PointClickEngine::Core::InputState.mouse_consumed?.should be_false

      # Test mouse consumption (without actual mouse input)
      # Note: This will return false since no actual mouse button is pressed
      consumed = PointClickEngine::Core::InputState.consume_mouse_click
      consumed.should be_false

      # Test mouse press checking
      pressed = PointClickEngine::Core::InputState.mouse_pressed?
      pressed.should be_a(Bool)
    end

    it "handles repeated state resets" do
      # Test multiple resets don't cause issues
      100.times do
        PointClickEngine::Core::InputState.reset
        PointClickEngine::Core::InputState.mouse_consumed?.should be_false
      end
    end

    it "handles state consistency" do
      PointClickEngine::Core::InputState.reset

      # Test state consistency over multiple queries
      10.times do
        consumed = PointClickEngine::Core::InputState.mouse_consumed?
        consumed.should be_false

        pressed = PointClickEngine::Core::InputState.mouse_pressed?
        pressed.should be_a(Bool)
      end
    end
  end

  describe "edge cases and error conditions" do
    it "handles null and invalid handlers gracefully" do
      manager = PointClickEngine::Core::InputManager.new

      # Test adding and removing the same handler multiple times
      handler = ->(dt : Float32) { false }

      manager.add_input_handler(handler, priority: 10)
      manager.add_input_handler(handler, priority: 5) # Same handler, different priority

      # Should handle duplicate handlers gracefully
      manager.process_input(0.016_f32) # Should not crash

      # Remove handler multiple times
      removed1 = manager.remove_input_handler(handler)
      removed2 = manager.remove_input_handler(handler)

      removed1.should be_true
      removed2.should be_false # Second removal should fail (no duplicate)
    end

    it "handles extreme priority values" do
      manager = PointClickEngine::Core::InputManager.new

      execution_order = [] of String

      # Add handlers with high and low priorities (avoid overflow)
      manager.register_handler("high_priority", priority: 1000000) do |dt|
        execution_order << "high"
        false
      end

      manager.register_handler("low_priority", priority: -1000000) do |dt|
        execution_order << "low"
        false
      end

      manager.register_handler("zero_priority", priority: 0) do |dt|
        execution_order << "zero"
        false
      end

      # Process input
      manager.process_input(0.016_f32)

      # Should handle extreme values and maintain correct order
      execution_order[0].should eq("high")
      execution_order[2].should eq("low")
    end

    it "handles very long and short frame times" do
      manager = PointClickEngine::Core::InputManager.new

      # Test very short frame time
      manager.process_input(0.000001_f32) # 1 microsecond
      # Should not crash

      # Test very long frame time
      manager.process_input(100.0_f32) # 100 seconds
      # Should not crash

      # Test zero frame time
      manager.process_input(0.0_f32)
      # Should not crash

      # Test negative frame time (edge case)
      manager.process_input(-1.0_f32)
      # Should not crash
    end
  end
end
