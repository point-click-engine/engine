require "../spec_helper"

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
    
    it "detects northeast direction" do
      velocity = RL::Vector2.new(x: 1, y: -1)
      PointClickEngine::Characters::Direction8.from_velocity(velocity).should eq PointClickEngine::Characters::Direction8::NorthEast
    end
    
    it "detects southeast direction" do
      velocity = RL::Vector2.new(x: 1, y: 1)
      PointClickEngine::Characters::Direction8.from_velocity(velocity).should eq PointClickEngine::Characters::Direction8::SouthEast
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
  
  describe "#angle_difference" do
    it "calculates angle differences correctly" do
      north = PointClickEngine::Characters::Direction8::North
      east = PointClickEngine::Characters::Direction8::East
      
      north.angle_difference(east).should eq 90.0f32
      east.angle_difference(north).should eq 90.0f32
    end
    
    it "handles wraparound correctly" do
      north = PointClickEngine::Characters::Direction8::North
      north_west = PointClickEngine::Characters::Direction8::NorthWest
      
      # Should be 45 degrees, not 315
      north.angle_difference(north_west).should eq 45.0f32
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
  
  it "initializes with custom values" do
    anim = PointClickEngine::Characters::EnhancedAnimationData.new(
      start_frame: 10,
      frame_count: 5,
      frame_speed: 0.2f32,
      loop: false,
      priority: 5,
      interruptible: false,
      auto_return_to_idle: false,
      sound_effect: "footstep"
    )
    
    anim.start_frame.should eq 10
    anim.frame_count.should eq 5
    anim.frame_speed.should eq 0.2f32
    anim.loop.should be_false
    anim.priority.should eq 5
    anim.interruptible.should be_false
    anim.auto_return_to_idle.should be_false
    anim.sound_effect.should eq "footstep"
  end
end

describe PointClickEngine::Characters::AnimationController do
  let(controller) { PointClickEngine::Characters::AnimationController.new }
  
  it "initializes with default animations" do
    controller.animations.should contain("idle")
    controller.current_animation.should eq "idle"
  end
  
  describe "#add_animation" do
    it "adds a new animation" do
      controller.add_animation("test", 0, 4, 0.15f32)
      controller.animations.should contain("test")
      
      anim_data = controller.animations["test"]
      anim_data.start_frame.should eq 0
      anim_data.frame_count.should eq 4
      anim_data.frame_speed.should eq 0.15f32
    end
  end
  
  describe "#add_directional_animation" do
    it "creates 8 directional animations" do
      controller.add_directional_animation("walk", 0, 4)
      
      PointClickEngine::Characters::Direction8.each do |direction|
        animation_name = "walk_#{direction.to_s.downcase}"
        controller.animations.should contain(animation_name)
      end
    end
    
    it "calculates frame offsets correctly" do
      controller.add_directional_animation("walk", 10, 3)
      
      # North should start at frame 10, Northeast at 13, etc.
      controller.animations["walk_north"].start_frame.should eq 10
      controller.animations["walk_northeast"].start_frame.should eq 13
      controller.animations["walk_east"].start_frame.should eq 16
    end
  end
  
  describe "#add_idle_variation" do
    it "adds idle variation to the list" do
      controller.add_idle_variation("yawn", 50, 6)
      
      controller.animations.should contain("idle_yawn")
      controller.idle_variations.should contain("idle_yawn")
    end
  end
  
  describe "#play_animation" do
    it "plays animation when it exists" do
      controller.add_animation("test", 0, 4)
      result = controller.play_animation("test")
      
      result.should be_true
      controller.current_animation.should eq "test"
    end
    
    it "fails when animation doesn't exist" do
      result = controller.play_animation("nonexistent")
      result.should be_false
    end
    
    it "respects priority system" do
      # Add high priority animation
      controller.add_animation("important", 0, 4, priority: 10, interruptible: false)
      # Add low priority animation
      controller.add_animation("minor", 0, 2, priority: 1)
      
      # Play important animation first
      controller.play_animation("important")
      controller.current_animation.should eq "important"
      
      # Try to interrupt with minor - should fail
      result = controller.play_animation("minor")
      result.should be_false
      controller.current_animation.should eq "important"
      
      # Force should work
      result = controller.play_animation("minor", force: true)
      result.should be_true
      controller.current_animation.should eq "minor"
    end
  end
  
  describe "#update_directional_animation" do
    it "updates animation based on state and direction" do
      controller.add_directional_animation("walk", 0, 4)
      
      controller.update_directional_animation(
        PointClickEngine::Characters::AnimationState::Walking,
        PointClickEngine::Characters::Direction8::North
      )
      
      controller.current_animation.should eq "walk_north"
      controller.current_direction.should eq PointClickEngine::Characters::Direction8::North
    end
  end
  
  describe "#update_idle" do
    it "doesn't trigger idle variation before timer" do
      controller.add_idle_variation("yawn", 50, 6)
      controller.idle_timer = 1.0f32
      
      controller.update_idle(1.0f32)
      controller.current_animation.should eq "idle"
    end
    
    it "triggers idle variation after timer expires" do
      controller.add_idle_variation("yawn", 50, 6)
      controller.idle_timer = PointClickEngine::Characters::AnimationController::IDLE_TRIGGER_TIME + 1.0f32
      
      # Mock random to always return first variation
      controller.idle_variations.clear
      controller.idle_variations << "idle_yawn"
      
      controller.update_idle(0.1f32)
      controller.current_animation.should eq "idle_yawn"
      controller.idle_timer.should eq 0.0f32
    end
    
    it "doesn't trigger when not in idle state" do
      controller.add_idle_variation("yawn", 50, 6)
      controller.current_animation = "walk_north"
      controller.idle_timer = 100.0f32
      
      controller.update_idle(0.1f32)
      controller.current_animation.should eq "walk_north"
    end
  end
  
  describe "#current_animation_data" do
    it "returns data for current animation" do
      controller.add_animation("test", 5, 3, 0.2f32)
      controller.play_animation("test")
      
      data = controller.current_animation_data
      data.should_not be_nil
      data.not_nil!.start_frame.should eq 5
      data.not_nil!.frame_count.should eq 3
    end
    
    it "returns nil for invalid animation" do
      controller.current_animation = "nonexistent"
      controller.current_animation_data.should be_nil
    end
  end
end