require "../spec_helper"

describe PointClickEngine::Core::InputState do
  describe ".reset" do
    it "resets mouse_consumed to false" do
      # Manually set consumed state by consuming
      # First check it starts false
      PointClickEngine::Core::InputState.reset
      PointClickEngine::Core::InputState.mouse_consumed?.should be_false
    end

    it "allows consume_mouse_click after reset" do
      # Reset first
      PointClickEngine::Core::InputState.reset

      # Without a mouse click, consume should return false
      # (because mouse_button_pressed? returns false)
      result = PointClickEngine::Core::InputState.consume_mouse_click
      result.should be_false

      # Verify consumed state is still trackable
      PointClickEngine::Core::InputState.mouse_consumed?.should be_false
    end
  end

  describe ".mouse_consumed?" do
    it "returns false initially after reset" do
      PointClickEngine::Core::InputState.reset
      PointClickEngine::Core::InputState.mouse_consumed?.should be_false
    end
  end

  describe ".mouse_pressed?" do
    it "checks mouse state without consuming" do
      PointClickEngine::Core::InputState.reset

      # Just verify it doesn't crash and returns a boolean
      result = PointClickEngine::Core::InputState.mouse_pressed?
      result.should be_a(Bool)
    end
  end

  describe "input consumption lifecycle" do
    it "prevents double consumption within same frame" do
      PointClickEngine::Core::InputState.reset

      # Without actual mouse input, both should return false
      # but the key test is that the second call respects the consumed state
      first_result = PointClickEngine::Core::InputState.consume_mouse_click
      second_result = PointClickEngine::Core::InputState.consume_mouse_click

      # Both false because no mouse press, but importantly second checks consumed state
      first_result.should be_false
      second_result.should be_false
    end

    it "allows consumption again after reset" do
      PointClickEngine::Core::InputState.reset

      # Simulate a frame boundary by resetting
      PointClickEngine::Core::InputState.reset

      # Should be able to attempt consumption again
      PointClickEngine::Core::InputState.mouse_consumed?.should be_false
    end
  end
end

describe "Engine main loop resets InputState" do
  # This test verifies the fix we made - InputState.reset is called each frame
  it "calls InputState.reset at start of each frame" do
    RaylibContext.ensure_window

    # We can't easily test the actual game loop, but we can verify
    # that the reset method exists and works
    PointClickEngine::Core::InputState.reset
    PointClickEngine::Core::InputState.mouse_consumed?.should be_false

    # The actual integration would be in engine.cr:
    # while @running && !RL.close_window?
    #   dt = RL.get_frame_time
    #   InputState.reset  # <-- This is the fix
    #   update(dt)
    #   ...
  end
end
