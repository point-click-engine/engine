require "../spec_helper"
require "../../src/ui/status_bar"

describe PointClickEngine::UI::StatusBar do
  it "initializes with screen dimensions" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.visible.should be_true
    status_bar.size.x.should eq 800.0f32
    status_bar.size.y.should eq 30.0f32
    status_bar.position.y.should eq 570.0f32  # 600 - 30
    status_bar.current_verb.should eq PointClickEngine::UI::VerbType::Walk
    status_bar.inventory_count.should eq 0
  end
  
  it "updates position and size correctly" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.set_position(10.0f32, 50.0f32)
    status_bar.position.x.should eq 10.0f32
    status_bar.position.y.should eq 50.0f32
    
    status_bar.set_size(900.0f32, 40.0f32)
    status_bar.size.x.should eq 900.0f32
    status_bar.size.y.should eq 40.0f32
  end
  
  it "updates with cursor manager state" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    cursor_manager = PointClickEngine::UI::CursorManager.new
    
    # Mock the cursor manager state
    cursor_manager.current_verb = PointClickEngine::UI::VerbType::Look
    
    status_bar.update(cursor_manager)
    
    status_bar.current_verb.should eq PointClickEngine::UI::VerbType::Look
  end
  
  it "updates manually with provided values" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.update_manual(
      PointClickEngine::UI::VerbType::Use,
      "Crystal",
      5,
      100
    )
    
    status_bar.current_verb.should eq PointClickEngine::UI::VerbType::Use
    status_bar.current_object.should eq "Crystal"
    status_bar.inventory_count.should eq 5
    status_bar.score.should eq 100
  end
  
  it "toggles visibility" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.visible.should be_true
    status_bar.toggle_visibility
    status_bar.visible.should be_false
    status_bar.toggle_visibility
    status_bar.visible.should be_true
  end
  
  it "shows and hides correctly" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.hide
    status_bar.visible.should be_false
    
    status_bar.show
    status_bar.visible.should be_true
  end
  
  it "enables and disables score display" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.show_score.should be_false
    status_bar.enable_score(true)
    status_bar.show_score.should be_true
    status_bar.enable_score(false)
    status_bar.show_score.should be_false
  end
  
  it "sets score correctly" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.set_score(250)
    status_bar.score.should eq 250
  end
  
  it "returns correct height" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.get_height.should eq 30.0f32
    
    status_bar.set_size(800.0f32, 50.0f32)
    status_bar.get_height.should eq 50.0f32
  end
  
  it "detects point containment" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    status_bar.set_position(0.0f32, 570.0f32)
    
    # Point inside status bar
    inside_point = RL::Vector2.new(x: 400f32, y: 580f32)
    status_bar.contains_point(inside_point).should be_true
    
    # Point outside status bar
    outside_point = RL::Vector2.new(x: 400f32, y: 300f32)
    status_bar.contains_point(outside_point).should be_false
    
    # Point on border
    border_point = RL::Vector2.new(x: 0f32, y: 570f32)
    status_bar.contains_point(border_point).should be_true
  end
  
  it "handles long object names correctly" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    # Test with very long object name
    long_name = "This is a very long object name that should be truncated"
    status_bar.update_manual(PointClickEngine::UI::VerbType::Look, long_name)
    
    status_bar.current_object.should eq long_name
    # The truncation happens during drawing, so object name remains full
  end
  
  it "handles empty object name" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    status_bar.update_manual(PointClickEngine::UI::VerbType::Walk, "")
    status_bar.current_object.should eq ""
  end
  
  it "converts verb types to display text correctly" do
    status_bar = PointClickEngine::UI::StatusBar.new(800, 600)
    
    # Test each verb type gets proper display text
    test_verbs = [
      {PointClickEngine::UI::VerbType::Walk, "Walk"},
      {PointClickEngine::UI::VerbType::Look, "Look"},
      {PointClickEngine::UI::VerbType::Talk, "Talk"},
      {PointClickEngine::UI::VerbType::Use, "Use"},
      {PointClickEngine::UI::VerbType::Take, "Take"},
      {PointClickEngine::UI::VerbType::Open, "Open"},
      {PointClickEngine::UI::VerbType::Close, "Close"},
      {PointClickEngine::UI::VerbType::Push, "Push"},
      {PointClickEngine::UI::VerbType::Pull, "Pull"},
      {PointClickEngine::UI::VerbType::Give, "Give"}
    ]
    
    test_verbs.each do |verb, expected_text|
      status_bar.update_manual(verb, "Object")
      # We can't test the private method directly, but we verify the verb is stored
      status_bar.current_verb.should eq verb
    end
  end
end