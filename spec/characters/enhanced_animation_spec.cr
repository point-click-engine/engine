require "../spec_helper"
require "../../src/characters/enhanced_animation"

describe PointClickEngine::Characters::Direction8 do
  describe ".from_velocity" do
    it "detects north direction" do
      velocity = RL::Vector2.new(x: 0, y: -1)
      PointClickEngine::Characters::Direction8.from_velocity(velocity).should eq PointClickEngine::Characters::Direction8::North
    end
    
    it "detects south direction" do
      velocity = RL::Vector2.new(x: 0, y: 1)
      PointClickEngine::Characters::Direction8.from_velocity(velocity).should eq PointClickEngine::Characters::Direction8::South
    end
    
    it "detects east direction" do
      velocity = RL::Vector2.new(x: 1, y: 0)
      PointClickEngine::Characters::Direction8.from_velocity(velocity).should eq PointClickEngine::Characters::Direction8::East
    end
    
    it "detects west direction" do
      velocity = RL::Vector2.new(x: -1, y: 0)
      PointClickEngine::Characters::Direction8.from_velocity(velocity).should eq PointClickEngine::Characters::Direction8::West
    end
    
    it "handles zero velocity" do
      velocity = RL::Vector2.new(x: 0, y: 0)
      PointClickEngine::Characters::Direction8.from_velocity(velocity).should eq PointClickEngine::Characters::Direction8::South
    end
  end
  
  describe "#opposite" do
    it "returns correct opposite directions" do
      PointClickEngine::Characters::Direction8::North.opposite.should eq PointClickEngine::Characters::Direction8::South
      PointClickEngine::Characters::Direction8::East.opposite.should eq PointClickEngine::Characters::Direction8::West
      PointClickEngine::Characters::Direction8::NorthEast.opposite.should eq PointClickEngine::Characters::Direction8::SouthWest
      PointClickEngine::Characters::Direction8::SouthEast.opposite.should eq PointClickEngine::Characters::Direction8::NorthWest
    end
  end
end

describe PointClickEngine::Characters::AnimationState do
  describe "#with_direction" do
    it "creates directional animation names" do
      walking = PointClickEngine::Characters::AnimationState::Walking
      north = PointClickEngine::Characters::Direction8::North
      
      walking.with_direction(north).should eq "walk_north"
    end
    
    it "handles talking animations" do
      talking = PointClickEngine::Characters::AnimationState::Talking
      east = PointClickEngine::Characters::Direction8::East
      
      talking.with_direction(east).should eq "talk_east"
    end
    
    it "handles non-directional animations" do
      idle = PointClickEngine::Characters::AnimationState::Idle
      south = PointClickEngine::Characters::Direction8::South
      
      idle.with_direction(south).should eq "idle"
    end
  end
end

describe PointClickEngine::Characters::EnhancedAnimationData do
  it "initializes with default values" do
    anim = PointClickEngine::Characters::EnhancedAnimationData.new
    anim.start_frame.should eq 0
    anim.frame_count.should eq 1
    anim.frame_speed.should eq 0.1f32
    anim.loop.should be_true
    anim.priority.should eq 0
    anim.interruptible.should be_true
    anim.auto_return_to_idle.should be_true
    anim.sound_effect.should be_nil
  end
end

describe PointClickEngine::Characters::AnimationController do
  it "initializes with default animations" do
    controller = PointClickEngine::Characters::AnimationController.new
    controller.animations.should contain("idle")
    controller.current_animation.should eq "idle"
  end
  
  it "adds a new animation" do
    controller = PointClickEngine::Characters::AnimationController.new
    controller.add_animation("test", 0, 4, 0.15f32)
    controller.animations.should contain("test")
    
    anim_data = controller.animations["test"]
    anim_data.start_frame.should eq 0
    anim_data.frame_count.should eq 4
    anim_data.frame_speed.should eq 0.15f32
  end
  
  it "creates 8 directional animations" do
    controller = PointClickEngine::Characters::AnimationController.new
    controller.add_directional_animation("walk", 0, 4)
    
    PointClickEngine::Characters::Direction8.each do |direction|
      animation_name = "walk_#{direction.to_s.downcase}"
      controller.animations.should contain(animation_name)
    end
  end
  
  it "plays animation when it exists" do
    controller = PointClickEngine::Characters::AnimationController.new
    controller.add_animation("test", 0, 4)
    result = controller.play_animation("test")
    
    result.should be_true
    controller.current_animation.should eq "test"
  end
  
  it "fails when animation doesn't exist" do
    controller = PointClickEngine::Characters::AnimationController.new
    result = controller.play_animation("nonexistent")
    result.should be_false
  end
end