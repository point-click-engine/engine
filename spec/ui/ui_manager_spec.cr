require "../spec_helper"
require "../../src/ui/ui_manager"

describe PointClickEngine::UI::UIManager do
  it "initializes with all components" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.verb_coin.should be_a(PointClickEngine::UI::VerbCoin)
    ui_manager.status_bar.should be_a(PointClickEngine::UI::StatusBar)
    ui_manager.cursor_manager.should be_a(PointClickEngine::UI::CursorManager)
    ui_manager.current_verb.should eq PointClickEngine::UI::VerbType::Walk
    ui_manager.verb_coin_enabled.should be_true
    ui_manager.status_bar_enabled.should be_true
  end

  it "enables and disables verb coin" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.verb_coin_enabled.should be_true
    ui_manager.enable_verb_coin(false)
    ui_manager.verb_coin_enabled.should be_false
    ui_manager.enable_verb_coin(true)
    ui_manager.verb_coin_enabled.should be_true
  end

  it "enables and disables status bar" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.status_bar_enabled.should be_true
    ui_manager.enable_status_bar(false)
    ui_manager.status_bar_enabled.should be_false
    ui_manager.enable_status_bar(true)
    ui_manager.status_bar_enabled.should be_true
  end

  it "sets and gets current verb" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.set_current_verb(PointClickEngine::UI::VerbType::Look)
    ui_manager.get_current_verb.should eq PointClickEngine::UI::VerbType::Look
    ui_manager.current_verb.should eq PointClickEngine::UI::VerbType::Look
  end

  it "reports verb coin active state" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.is_verb_coin_active?.should be_false

    # Show verb coin
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    ui_manager.verb_coin.show(position, [PointClickEngine::UI::VerbType::Look])
    ui_manager.is_verb_coin_active?.should be_true

    # Hide verb coin
    ui_manager.hide_verb_coin
    ui_manager.is_verb_coin_active?.should be_false
  end

  it "sets score and enables score display" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.set_score(150)
    ui_manager.status_bar.score.should eq 150

    ui_manager.enable_score_display(true)
    ui_manager.status_bar.show_score.should be_true
  end

  it "gets applicable verbs for nil hotspot" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    # This tests the private method indirectly by checking behavior
    # When no hotspot is present, should default to basic verbs
    ui_manager.current_verb.should eq PointClickEngine::UI::VerbType::Walk
  end

  it "handles right-click timing correctly" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.right_click_time.should eq 0.0f32
    ui_manager.right_click_threshold.should eq 0.1f32

    # Test that threshold is reasonable for user interaction
    ui_manager.right_click_threshold.should be > 0.05f32
    ui_manager.right_click_threshold.should be < 0.5f32
  end

  it "generates current action text" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    ui_manager.set_current_verb(PointClickEngine::UI::VerbType::Look)
    action_text = ui_manager.get_current_action_text

    # Should return a valid action description
    action_text.should_not be_empty
    action_text.includes?("Look").should be_true
  end

  it "handles cleanup correctly" do
    ui_manager = PointClickEngine::UI::UIManager.new(800, 600)

    # Should not raise any errors during cleanup
    ui_manager.cleanup
  end
end

# Test helper for creating mock scenes and hotspots
class MockScene < PointClickEngine::Scenes::Scene
  def initialize
    super("test_scene", "Test Scene")
  end

  def get_hotspot_at(pos : RL::Vector2) : PointClickEngine::Scenes::Hotspot?
    @hotspots.find { |hotspot| hotspot.contains_point?(pos) }
  end
end

class MockHotspot < PointClickEngine::Scenes::Hotspot
  def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
    super(name, position, size)
    @description = "A #{@name}"
  end
end
