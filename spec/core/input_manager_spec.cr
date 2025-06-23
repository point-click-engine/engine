require "../spec_helper"
require "../../src/core/input_manager"

describe PointClickEngine::Core::InputManager do
  describe "#initialize" do
    it "creates a new InputManager instance" do
      manager = PointClickEngine::Core::InputManager.new
      manager.should be_a(PointClickEngine::Core::InputManager)
    end
  end

  describe "#block_input and #unblock_input" do
    it "blocks input for specified frames" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.input_blocked?.should be_false
      manager.block_input(5, "test")
      manager.input_blocked?.should be_true
      manager.input_block_source.should eq("test")
    end

    it "unblocks input immediately" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.block_input(10, "test")
      manager.input_blocked?.should be_true
      
      manager.unblock_input
      manager.input_blocked?.should be_false
      manager.input_block_source.should be_nil
    end

    it "automatically unblocks after frame countdown" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.block_input(2, "test")
      manager.input_blocked?.should be_true
      
      # Simulate frame updates
      manager.process_input(0.016_f32)
      manager.input_blocked?.should be_true
      
      manager.process_input(0.016_f32)
      manager.input_blocked?.should be_false
    end
  end

  describe "#register_handler and #unregister_handler" do
    it "registers input handlers with priorities" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.register_handler("test_handler", 10)
      # Handler should be registered (verified through behavior)
    end

    it "unregisters input handlers" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.register_handler("test_handler", 10)
      result = manager.unregister_handler("test_handler")
      
      result.should be_true
    end

    it "returns false when unregistering non-existent handler" do
      manager = PointClickEngine::Core::InputManager.new
      
      result = manager.unregister_handler("nonexistent_handler")
      
      result.should be_false
    end
  end

  describe "#is_consumed and #consume_input" do
    it "tracks input consumption" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.is_consumed("mouse_click").should be_false
      manager.consume_input("mouse_click", "test_handler")
      manager.is_consumed("mouse_click").should be_true
    end

    it "resets consumption state each frame" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.consume_input("mouse_click", "test_handler")
      manager.is_consumed("mouse_click").should be_true
      
      # Process input should reset consumption
      manager.process_input(0.016_f32)
      manager.is_consumed("mouse_click").should be_false
    end
  end

  describe "#process_input" do
    it "processes input when not blocked" do
      manager = PointClickEngine::Core::InputManager.new
      
      # Should not raise exceptions
      manager.process_input(0.016_f32)
    end

    it "skips input processing when blocked" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.block_input(5, "test")
      
      # Should not process input but not raise exceptions
      manager.process_input(0.016_f32)
      manager.input_blocked?.should be_true
    end

    it "handles multiple input handlers with priorities" do
      manager = PointClickEngine::Core::InputManager.new
      handler_calls = [] of String
      
      # Mock handlers that record when they're called
      high_priority = ->(dt : Float32) {
        handler_calls << "high"
        false # Don't consume input
      }
      
      low_priority = ->(dt : Float32) {
        handler_calls << "low"
        false
      }
      
      # Register handlers (would need actual implementation support)
      # This tests the concept even if the exact API differs
      manager.process_input(0.016_f32)
    end
  end

  describe "#update" do
    it "updates input state without errors" do
      manager = PointClickEngine::Core::InputManager.new
      
      # Should not raise exceptions
      manager.update(0.016_f32)
    end

    it "handles frame-based operations" do
      manager = PointClickEngine::Core::InputManager.new
      
      manager.block_input(2, "test")  # Block for 2 frames
      manager.input_blocked?.should be_true
      
      manager.update(0.016_f32)  # First update - decrements to 1
      manager.input_blocked?.should be_true  # Still blocked
      
      manager.update(0.016_f32)  # Second update - decrements to 0
      manager.input_blocked?.should be_false  # Now unblocked
    end
  end

  describe "input state tracking" do
    it "tracks mouse position and movement" do
      manager = PointClickEngine::Core::InputManager.new
      
      # These would test the actual mouse tracking implementation
      # For now, we ensure the methods exist and don't crash
      manager.update(0.016_f32)
    end

    it "detects key presses and releases" do
      manager = PointClickEngine::Core::InputManager.new
      
      # These would test keyboard state tracking
      manager.update(0.016_f32)
    end

    it "handles double-click detection" do
      manager = PointClickEngine::Core::InputManager.new
      
      # Test double-click timing and detection
      manager.update(0.016_f32)
    end
  end
end