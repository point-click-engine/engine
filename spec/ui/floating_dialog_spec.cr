require "../spec_helper"
require "../../src/ui/floating_dialog"

describe PointClickEngine::UI::DialogStyle do
  it "has all expected styles" do
    styles = [
      PointClickEngine::UI::DialogStyle::Bubble,
      PointClickEngine::UI::DialogStyle::Rectangle,
      PointClickEngine::UI::DialogStyle::Thought,
      PointClickEngine::UI::DialogStyle::Shout,
      PointClickEngine::UI::DialogStyle::Whisper,
      PointClickEngine::UI::DialogStyle::Narrator,
    ]

    styles.each do |style|
      style.should be_a(PointClickEngine::UI::DialogStyle)
    end
  end
end

describe PointClickEngine::UI::WrappedText do
  it "initializes with text data" do
    lines = ["Hello", "World"]
    wrapped = PointClickEngine::UI::WrappedText.new(lines, 100, 32)

    wrapped.lines.should eq lines
    wrapped.total_width.should eq 100
    wrapped.total_height.should eq 32
  end
end

describe PointClickEngine::UI::FloatingDialog do
  it "initializes with character and text data" do
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    dialog = PointClickEngine::UI::FloatingDialog.new(
      "Hello there!",
      "Player",
      character_pos,
      3.0f32
    )

    dialog.text.should eq "Hello there!"
    dialog.character_name.should eq "Player"
    dialog.character_position.should eq character_pos
    dialog.duration.should eq 3.0f32
    dialog.visible.should be_true
    dialog.style.should eq PointClickEngine::UI::DialogStyle::Bubble
  end

  it "enables typewriter effect for long text" do
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    short_dialog = PointClickEngine::UI::FloatingDialog.new(
      "Hi!",
      "Player",
      character_pos,
      2.0f32
    )

    long_dialog = PointClickEngine::UI::FloatingDialog.new(
      "This is a very long message that should trigger typewriter effect",
      "Player",
      character_pos,
      4.0f32
    )

    short_dialog.typewriter_enabled.should be_false
    short_dialog.visible_characters.should eq 3

    long_dialog.typewriter_enabled.should be_true
    long_dialog.visible_characters.should eq 0
  end

  it "updates animation state over time" do
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    dialog = PointClickEngine::UI::FloatingDialog.new(
      "Test message",
      "Player",
      character_pos,
      3.0f32
    )

    initial_offset = dialog.float_offset
    initial_alpha = dialog.fade_alpha

    # Update for 0.1 seconds
    dialog.update(0.1f32)

    # Should have animated
    dialog.elapsed.should eq 0.1f32
    dialog.float_offset.should_not eq initial_offset
    dialog.fade_alpha.should eq initial_alpha # No fade yet
  end

  it "returns true when dialog expires" do
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    dialog = PointClickEngine::UI::FloatingDialog.new(
      "Short",
      "Player",
      character_pos,
      1.0f32
    )

    # Should not expire initially
    result = dialog.update(0.5f32)
    result.should be_false

    # Should expire after duration
    result = dialog.update(0.6f32)
    result.should be_true
  end

  it "applies character-specific colors" do
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    player_dialog = PointClickEngine::UI::FloatingDialog.new("Hi", "Player", character_pos, 2.0f32)
    wizard_dialog = PointClickEngine::UI::FloatingDialog.new("Magic!", "Wizard", character_pos, 2.0f32)
    unknown_dialog = PointClickEngine::UI::FloatingDialog.new("Hello", "Unknown", character_pos, 2.0f32)

    # Player should be white
    player_dialog.color.r.should eq 255
    player_dialog.color.g.should eq 255
    player_dialog.color.b.should eq 255

    # Wizard should be purple
    wizard_dialog.color.r.should eq 138
    wizard_dialog.color.g.should eq 43
    wizard_dialog.color.b.should eq 226

    # Unknown should be light gray
    unknown_dialog.color.r.should eq 200
    unknown_dialog.color.g.should eq 200
    unknown_dialog.color.b.should eq 200
  end

  it "updates typewriter effect over time" do
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    long_text = "This is a very long message for typewriter test"
    dialog = PointClickEngine::UI::FloatingDialog.new(long_text, "Player", character_pos, 5.0f32)

    dialog.typewriter_enabled.should be_true
    dialog.visible_characters.should eq 0

    # Update for 1 second at 30 chars/sec speed
    dialog.update(1.0f32)
    dialog.visible_characters.should eq 30

    # Update more - should not exceed text length
    dialog.update(10.0f32)
    dialog.visible_characters.should eq long_text.size
  end

  it "handles different dialog styles" do
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    dialog = PointClickEngine::UI::FloatingDialog.new("Test", "Player", character_pos, 2.0f32)

    # Test different styles
    PointClickEngine::UI::DialogStyle.each do |style|
      dialog.style = style
      dialog.style.should eq style
    end
  end
end

describe PointClickEngine::UI::FloatingDialogManager do
  it "initializes empty" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    manager.active_dialogs.size.should eq 0
    manager.max_concurrent.should eq 3
    manager.default_duration.should eq 4.0f32
    manager.enable_floating.should be_true
  end

  it "can show floating dialogs" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.show_dialog("Player", "Hello!", character_pos)
    manager.active_dialogs.size.should eq 1

    dialog = manager.active_dialogs.first
    dialog.text.should eq "Hello!"
    dialog.character_name.should eq "Player"
  end

  it "respects max concurrent limit" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    manager.max_concurrent = 2
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.show_dialog("Player", "First", character_pos)
    manager.show_dialog("Player", "Second", character_pos)
    manager.show_dialog("Player", "Third", character_pos)

    # Should only have 2 dialogs (oldest removed)
    manager.active_dialogs.size.should eq 2
    manager.active_dialogs.first.text.should eq "Second"
    manager.active_dialogs.last.text.should eq "Third"
  end

  it "removes expired dialogs during update" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    # Add dialog with short duration
    manager.show_dialog("Player", "Quick message", character_pos, 0.5f32)
    manager.active_dialogs.size.should eq 1

    # Update past expiration - need to call multiple times until dialog expires
    6.times { manager.update(0.1f32) } # 0.6 seconds total > 0.5 duration
    manager.active_dialogs.size.should eq 0
  end

  it "calculates duration based on text length" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    # Show dialog without explicit duration
    manager.show_dialog("Player", "This is a longer message that should have calculated duration", character_pos)

    dialog = manager.active_dialogs.first
    # Should be more than base duration (2.0s) but less than max (8.0s)
    dialog.duration.should be > 2.0f32
    dialog.duration.should be <= 8.0f32
  end

  it "can be disabled" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    manager.enable_floating = false
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.show_dialog("Player", "This won't show", character_pos)
    manager.active_dialogs.size.should eq 0
  end

  it "can clear all dialogs" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.show_dialog("Player", "First", character_pos)
    manager.show_dialog("NPC", "Second", character_pos)
    manager.active_dialogs.size.should eq 2

    manager.clear_all
    manager.active_dialogs.size.should eq 0
  end

  it "reports active dialog status" do
    manager = PointClickEngine::UI::FloatingDialogManager.new
    character_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.has_active_dialogs?.should be_false

    manager.show_dialog("Player", "Hello", character_pos)
    manager.has_active_dialogs?.should be_true

    manager.clear_all
    manager.has_active_dialogs?.should be_false
  end
end
