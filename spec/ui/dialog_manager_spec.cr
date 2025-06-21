require "../spec_helper"
require "../../src/ui/dialog_manager"

describe PointClickEngine::UI::DialogManager do
  describe "#initialize" do
    it "creates an empty dialog manager" do
      manager = PointClickEngine::UI::DialogManager.new
      manager.current_dialog.should be_nil
      manager.dialog_queue.should be_empty
      manager.message_display_time.should eq(3.0f32)
    end
  end

  describe "#show_dialog" do
    it "creates and displays a dialog" do
      manager = PointClickEngine::UI::DialogManager.new
      manager.show_dialog("TestChar", "Hello World")

      dialog = manager.current_dialog
      dialog.should_not be_nil
      dialog.not_nil!.character_name.should eq("TestChar")
      dialog.not_nil!.text.should eq("Hello World")
      dialog.not_nil!.visible.should be_true
    end

    it "creates dialog with choices" do
      manager = PointClickEngine::UI::DialogManager.new

      choice1 = PointClickEngine::UI::DialogChoice.new("Yes", -> { })
      choice2 = PointClickEngine::UI::DialogChoice.new("No", -> { })
      choices = [choice1, choice2]

      manager.show_dialog("Player", "Continue?", choices)

      dialog = manager.current_dialog
      dialog.should_not be_nil
      dialog.not_nil!.choices.not_nil!.size.should eq(2)
      dialog.not_nil!.choices.not_nil![0].text.should eq("Yes")
      dialog.not_nil!.choices.not_nil![1].text.should eq("No")
    end
  end

  describe "#show_message" do
    it "shows a temporary message" do
      manager = PointClickEngine::UI::DialogManager.new
      manager.show_message("Test message", 2.0f32)

      manager.current_dialog.should_not be_nil
      manager.current_dialog.not_nil!.text.should eq("Test message")
      manager.current_dialog.not_nil!.character_name.should eq("")
    end
  end

  describe "#show_choice" do
    it "creates a choice dialog with callback" do
      manager = PointClickEngine::UI::DialogManager.new
      selected_choice = 0

      callback = ->(choice : Int32) { selected_choice = choice }
      manager.show_choice("Pick one:", ["Option A", "Option B"], callback)

      dialog = manager.current_dialog
      dialog.should_not be_nil
      dialog.not_nil!.text.should eq("Pick one:")
      dialog.not_nil!.choices.not_nil!.size.should eq(2)

      # Simulate clicking first choice
      dialog.not_nil!.choices.not_nil![0].action.call
      selected_choice.should eq(1)
      manager.current_dialog.should be_nil # Dialog should close
    end
  end

  describe "#update" do
    it "auto-closes messages after timeout" do
      manager = PointClickEngine::UI::DialogManager.new
      manager.show_message("Temp", 1.0f32)

      manager.current_dialog.should_not be_nil

      # Update past the timeout
      manager.update(1.5f32)

      manager.current_dialog.should be_nil
    end

    it "doesn't close dialogs without timeout" do
      manager = PointClickEngine::UI::DialogManager.new
      manager.show_dialog("NPC", "Hello")

      manager.update(5.0f32)

      manager.current_dialog.should_not be_nil
    end
  end

  describe "#close_current_dialog" do
    it "closes the active dialog" do
      manager = PointClickEngine::UI::DialogManager.new
      manager.show_dialog("Test", "Message")

      manager.current_dialog.should_not be_nil
      manager.close_current_dialog
      manager.current_dialog.should be_nil
    end
  end

  describe "#is_dialog_active?" do
    it "returns true when dialog is active" do
      manager = PointClickEngine::UI::DialogManager.new
      manager.is_dialog_active?.should be_false

      manager.show_dialog("Test", "Message")
      manager.is_dialog_active?.should be_true

      manager.close_current_dialog
      manager.is_dialog_active?.should be_false
    end
  end
end
