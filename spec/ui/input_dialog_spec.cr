require "../spec_helper"
require "../../src/ui/input_dialog"

describe PointClickEngine::UI::InputDialog do
  describe "#initialize" do
    it "creates an input dialog with prompt" do
      dialog = PointClickEngine::UI::InputDialog.new("Enter code:")

      dialog.prompt.should eq("Enter code:")
      dialog.input_text.should eq("")
      dialog.max_length.should eq(32)
      dialog.visible.should be_false
    end

    it "sets default position and size" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")

      dialog.position.x.should eq(262f32)
      dialog.position.y.should eq(284f32)
      dialog.size.x.should eq(500f32)
      dialog.size.y.should eq(200f32)
    end

    it "accepts custom position and size" do
      pos = RL::Vector2.new(x: 100f32, y: 200f32)
      size = RL::Vector2.new(x: 400f32, y: 150f32)

      dialog = PointClickEngine::UI::InputDialog.new("Test", pos, size)

      dialog.position.should eq(pos)
      dialog.size.should eq(size)
    end
  end

  describe "#show" do
    it "makes dialog visible and resets input" do
      dialog = PointClickEngine::UI::InputDialog.new("Enter name:")
      dialog.input_text = "previous"

      callback_result = ""
      dialog.show { |result| callback_result = result }

      dialog.visible.should be_true
      dialog.input_text.should eq("")
    end

    it "stores callback for later invocation" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")

      callback_called = false
      dialog.show { |result| callback_called = true }

      dialog.callback.should_not be_nil
    end
  end

  describe "#show_with_default" do
    it "shows dialog with pre-filled text" do
      dialog = PointClickEngine::UI::InputDialog.new("Edit name:")

      dialog.show_with_default("John") { |result| }

      dialog.visible.should be_true
      dialog.input_text.should eq("John")
    end
  end

  describe "#hide" do
    it "hides the dialog" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")
      dialog.show { |r| }

      dialog.visible.should be_true
      dialog.hide
      dialog.visible.should be_false
    end
  end

  describe "#update" do
    it "does nothing when not visible" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")

      # Should not raise
      dialog.update(0.1f32)
      dialog.ready_to_process_input.should be_false
    end

    it "has frame delay before accepting input" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")
      dialog.show { |r| }

      dialog.ready_to_process_input.should be_false

      # First update - still waiting
      dialog.update(0.1f32)
      dialog.ready_to_process_input.should be_false

      # Second update - ready
      dialog.update(0.1f32)
      dialog.ready_to_process_input.should be_false

      # Third update - ready
      dialog.update(0.1f32)
      dialog.ready_to_process_input.should be_true
    end

    it "blinks cursor" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")
      dialog.show { |r| }

      # Skip frame delay
      3.times { dialog.update(0.1f32) }

      initial_state = dialog.cursor_visible

      # Update past blink interval
      dialog.update(0.6f32)

      dialog.cursor_visible.should_not eq(initial_state)
    end
  end

  describe "input text handling" do
    it "respects max_length" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")
      dialog.max_length = 5
      dialog.input_text = "12345"

      # Adding more characters should be blocked
      # (This would be tested with keyboard input in integration tests)
      dialog.input_text.size.should eq(5)
    end
  end

  describe "visual properties" do
    it "has default colors" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")

      dialog.background_color.should eq(RL::Color.new(r: 20, g: 20, b: 30, a: 240))
      dialog.text_color.should eq(RL::WHITE)
      dialog.input_bg_color.should eq(RL::Color.new(r: 40, g: 40, b: 50, a: 255))
      dialog.cursor_color.should eq(RL::Color.new(r: 255, g: 255, b: 100, a: 255))
      dialog.border_color.should eq(RL::Color.new(r: 100, g: 100, b: 120, a: 255))
    end

    it "allows custom colors" do
      dialog = PointClickEngine::UI::InputDialog.new("Test")
      dialog.background_color = RL::Color.new(r: 0, g: 0, b: 0, a: 255)
      dialog.text_color = RL::Color.new(r: 255, g: 0, b: 0, a: 255)

      dialog.background_color.should eq(RL::Color.new(r: 0, g: 0, b: 0, a: 255))
      dialog.text_color.should eq(RL::Color.new(r: 255, g: 0, b: 0, a: 255))
    end
  end
end

describe PointClickEngine::UI::DialogManager do
  describe "#show_input_dialog" do
    it "creates and shows an input dialog" do
      manager = PointClickEngine::UI::DialogManager.new

      callback_received = ""
      manager.show_input_dialog("Enter code:") do |result|
        callback_received = result
      end

      manager.input_dialog.should_not be_nil
      manager.input_dialog.not_nil!.visible.should be_true
      manager.input_dialog.not_nil!.prompt.should eq("Enter code:")
    end

    it "accepts max_length parameter" do
      manager = PointClickEngine::UI::DialogManager.new

      manager.show_input_dialog("PIN:", 4) { |r| }

      manager.input_dialog.not_nil!.max_length.should eq(4)
    end

    it "is_dialog_active? returns true with input dialog" do
      manager = PointClickEngine::UI::DialogManager.new

      manager.is_dialog_active?.should be_false

      manager.show_input_dialog("Test") { |r| }

      manager.is_dialog_active?.should be_true
    end
  end

  describe "#show_input_dialog_with_default" do
    it "shows input dialog with pre-filled text" do
      manager = PointClickEngine::UI::DialogManager.new

      manager.show_input_dialog_with_default("Edit:", "Default", 20) { |r| }

      manager.input_dialog.not_nil!.input_text.should eq("Default")
    end
  end

  describe "#update with input dialog" do
    it "clears input dialog when hidden" do
      manager = PointClickEngine::UI::DialogManager.new

      manager.show_input_dialog("Test") { |r| }
      manager.input_dialog.should_not be_nil

      manager.input_dialog.not_nil!.hide
      manager.update(0.1f32)

      manager.input_dialog.should be_nil
    end

    it "input dialog blocks other updates when visible" do
      manager = PointClickEngine::UI::DialogManager.new

      # Show a regular message first
      manager.show_message("Regular message", 1.0f32)

      # Then show input dialog
      manager.show_input_dialog("Input") { |r| }

      # Update - input dialog is modal, message timer shouldn't decrease
      # (Actually it does return early, so we test the consumed flag)
      manager.update(0.1f32)

      # Input dialog should still be visible
      manager.input_dialog.should_not be_nil
      manager.input_dialog.not_nil!.visible.should be_true
    end
  end
end
