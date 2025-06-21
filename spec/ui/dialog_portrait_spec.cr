require "../spec_helper"
require "../../src/ui/dialog_portrait"

describe PointClickEngine::UI::PortraitExpression do
  it "has all expected expressions" do
    expressions = [
      PointClickEngine::UI::PortraitExpression::Neutral,
      PointClickEngine::UI::PortraitExpression::Happy,
      PointClickEngine::UI::PortraitExpression::Sad,
      PointClickEngine::UI::PortraitExpression::Angry,
      PointClickEngine::UI::PortraitExpression::Surprised,
      PointClickEngine::UI::PortraitExpression::Thinking,
      PointClickEngine::UI::PortraitExpression::Worried,
      PointClickEngine::UI::PortraitExpression::Excited,
      PointClickEngine::UI::PortraitExpression::Disgusted,
      PointClickEngine::UI::PortraitExpression::Fear,
    ]

    expressions.each do |expression|
      expression.should be_a(PointClickEngine::UI::PortraitExpression)
    end
  end
end

describe PointClickEngine::UI::PortraitPosition do
  it "has positioning options" do
    positions = [
      PointClickEngine::UI::PortraitPosition::BottomLeft,
      PointClickEngine::UI::PortraitPosition::BottomRight,
      PointClickEngine::UI::PortraitPosition::TopLeft,
      PointClickEngine::UI::PortraitPosition::TopRight,
      PointClickEngine::UI::PortraitPosition::Center,
      PointClickEngine::UI::PortraitPosition::Dynamic,
    ]

    positions.each do |position|
      position.should be_a(PointClickEngine::UI::PortraitPosition)
    end
  end
end

describe PointClickEngine::UI::PortraitFrame do
  it "initializes with expression and frame data" do
    frame_rect = RL::Rectangle.new(x: 0, y: 0, width: 64, height: 64)
    frame = PointClickEngine::UI::PortraitFrame.new(
      PointClickEngine::UI::PortraitExpression::Happy,
      frame_rect,
      0.5f32
    )

    frame.expression.should eq PointClickEngine::UI::PortraitExpression::Happy
    frame.frame_rect.should eq frame_rect
    frame.duration.should eq 0.5f32
  end
end

describe PointClickEngine::UI::DialogPortrait do
  it "initializes with character name" do
    portrait = PointClickEngine::UI::DialogPortrait.new("Wizard")
    portrait.character_name.should eq "Wizard"
    portrait.current_expression.should eq PointClickEngine::UI::PortraitExpression::Neutral
    portrait.visible.should be_false
  end

  it "can set and change expressions" do
    portrait = PointClickEngine::UI::DialogPortrait.new("Hero")

    portrait.set_expression(PointClickEngine::UI::PortraitExpression::Happy)
    portrait.current_expression.should eq PointClickEngine::UI::PortraitExpression::Happy

    portrait.set_expression(PointClickEngine::UI::PortraitExpression::Angry)
    portrait.current_expression.should eq PointClickEngine::UI::PortraitExpression::Angry
  end

  it "can start and stop talking" do
    portrait = PointClickEngine::UI::DialogPortrait.new("NPC")

    portrait.talking.should be_false
    portrait.start_talking
    portrait.talking.should be_true
    portrait.stop_talking
    portrait.talking.should be_false
  end

  it "can show and hide with visibility state" do
    portrait = PointClickEngine::UI::DialogPortrait.new("Character")

    portrait.visible.should be_false
    portrait.show(fade_in: false)
    portrait.visible.should be_true
    portrait.hide(fade_out: false)
    portrait.visible.should be_false
  end

  it "calculates screen positions correctly" do
    portrait = PointClickEngine::UI::DialogPortrait.new("Test")
    portrait.size = RL::Vector2.new(x: 128, y: 128)

    # Test bottom left position
    portrait.position = PointClickEngine::UI::PortraitPosition::BottomLeft
    pos = portrait.get_screen_position(800, 600)
    pos.x.should eq 20.0f32  # margin
    pos.y.should eq 452.0f32 # 600 - 128 - 20

    # Test bottom right position
    portrait.position = PointClickEngine::UI::PortraitPosition::BottomRight
    pos = portrait.get_screen_position(800, 600)
    pos.x.should eq 652.0f32 # 800 - 128 - 20
    pos.y.should eq 452.0f32 # 600 - 128 - 20

    # Test center position
    portrait.position = PointClickEngine::UI::PortraitPosition::Center
    pos = portrait.get_screen_position(800, 600)
    pos.x.should eq 336.0f32 # (800 - 128) / 2
    pos.y.should eq 236.0f32 # (600 - 128) / 2
  end

  it "updates fade animation" do
    portrait = PointClickEngine::UI::DialogPortrait.new("FadeTest")

    # Start with fade in
    portrait.show(fade_in: true)
    portrait.fade_alpha.should eq 0.0f32

    # Update should increase alpha
    portrait.update(0.1f32)
    portrait.fade_alpha.should be > 0.0f32

    # Keep updating until fully visible
    10.times { portrait.update(0.1f32) }
    portrait.fade_alpha.should eq 255.0f32
  end
end

describe PointClickEngine::UI::PortraitManager do
  it "initializes empty" do
    manager = PointClickEngine::UI::PortraitManager.new
    manager.portraits.size.should eq 0
    manager.active_portrait.should be_nil
  end

  it "can add portraits" do
    manager = PointClickEngine::UI::PortraitManager.new

    # Note: This test would require an actual image file to load
    # For testing, we'll just verify the portrait is created and added
    portrait = PointClickEngine::UI::DialogPortrait.new("TestChar")
    manager.portraits["TestChar"] = portrait

    manager.portraits.size.should eq 1
    manager.portraits["TestChar"].should eq portrait
  end

  it "can show and hide portraits" do
    manager = PointClickEngine::UI::PortraitManager.new
    portrait = PointClickEngine::UI::DialogPortrait.new("Speaker")
    manager.portraits["Speaker"] = portrait

    manager.show_portrait("Speaker", PointClickEngine::UI::PortraitExpression::Happy)
    manager.active_portrait.should eq "Speaker"
    portrait.visible.should be_true
    portrait.current_expression.should eq PointClickEngine::UI::PortraitExpression::Happy

    manager.hide_portrait
    manager.active_portrait.should be_nil
  end

  it "can control talking state" do
    manager = PointClickEngine::UI::PortraitManager.new
    portrait = PointClickEngine::UI::DialogPortrait.new("Talker")
    manager.portraits["Talker"] = portrait
    manager.show_portrait("Talker")

    manager.start_talking
    portrait.talking.should be_true

    manager.stop_talking
    portrait.talking.should be_false
  end
end
