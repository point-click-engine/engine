require "../spec_helper"
require "../../src/ui/verb_coin"

describe PointClickEngine::UI::VerbCoin do
  it "initializes with default settings" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    
    verb_coin.active.should be_false
    verb_coin.verbs.should be_empty
    verb_coin.selected_verb.should be_nil
    verb_coin.radius.should eq 60.0f32
    verb_coin.icon_radius.should eq 40.0f32
  end
  
  it "shows with provided verbs and position" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    verbs = [PointClickEngine::UI::VerbType::Look, PointClickEngine::UI::VerbType::Use]
    
    verb_coin.show(position, verbs)
    
    verb_coin.active.should be_true
    verb_coin.position.should eq position
    verb_coin.verbs.should eq verbs
    verb_coin.selected_verb.should eq PointClickEngine::UI::VerbType::Look
  end
  
  it "shows all verbs when empty array provided" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    
    verb_coin.show(position, [] of PointClickEngine::UI::VerbType)
    
    verb_coin.active.should be_true
    verb_coin.verbs.size.should be > 0
    verb_coin.verbs.should contain(PointClickEngine::UI::VerbType::Walk)
    verb_coin.verbs.should contain(PointClickEngine::UI::VerbType::Look)
  end
  
  it "hides when hide is called" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    verbs = [PointClickEngine::UI::VerbType::Look]
    
    verb_coin.show(position, verbs)
    verb_coin.active.should be_true
    
    verb_coin.hide
    verb_coin.active.should be_false
    verb_coin.selected_verb.should be_nil
  end
  
  it "has verb icons for all verb types" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    
    # Test that we have descriptions for all verb types
    PointClickEngine::UI::VerbType.each do |verb|
      description = verb_coin.get_verb_description(verb)
      description.should_not be_empty
      description.should_not eq "Unknown"
    end
  end
  
  it "reports active state correctly" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    
    verb_coin.is_active?.should be_false
    
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    verb_coin.show(position, [PointClickEngine::UI::VerbType::Look])
    verb_coin.is_active?.should be_true
    
    verb_coin.hide
    verb_coin.is_active?.should be_false
  end
  
  it "returns selected verb" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    verbs = [PointClickEngine::UI::VerbType::Talk, PointClickEngine::UI::VerbType::Use]
    
    verb_coin.show(position, verbs)
    
    selected = verb_coin.get_selected_verb
    selected.should_not be_nil
    verbs.should contain(selected.not_nil!)
  end
  
  it "applies alpha to colors correctly" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    
    # Test color with alpha application (this is a private method, so we test the concept)
    original_color = RL::Color.new(r: 255, g: 100, b: 50, a: 200)
    # We can't test the private method directly, but we can verify the coin handles colors
    
    verb_coin.background_color = original_color
    verb_coin.background_color.should eq original_color
  end
  
  it "updates fade animation over time" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    
    verb_coin.show(position, [PointClickEngine::UI::VerbType::Look])
    initial_alpha = verb_coin.fade_alpha
    
    # Simulate several update frames
    5.times { verb_coin.update(0.1f32) }
    
    # Alpha should have increased (fading in)
    verb_coin.fade_alpha.should be > initial_alpha
  end
  
  it "handles verb descriptions for all types" do
    verb_coin = PointClickEngine::UI::VerbCoin.new
    
    # Test specific verb descriptions
    verb_coin.get_verb_description(PointClickEngine::UI::VerbType::Walk).should eq "Walk to"
    verb_coin.get_verb_description(PointClickEngine::UI::VerbType::Look).should eq "Look at"
    verb_coin.get_verb_description(PointClickEngine::UI::VerbType::Talk).should eq "Talk to"
    verb_coin.get_verb_description(PointClickEngine::UI::VerbType::Use).should eq "Use"
    verb_coin.get_verb_description(PointClickEngine::UI::VerbType::Take).should eq "Take"
  end
end