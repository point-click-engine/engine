require "../spec_helper"
require "../../src/characters/animation_controller"
require "../../src/graphics/sprites/animated"

def create_mock_sprite
  sprite = PointClickEngine::Graphics::Sprites::Animated.new(RL::Vector2.new(0, 0), 32, 32, 1)
  sprite.current_frame = 0
  sprite.frame_timer = 0.0
  sprite.playing = false
  sprite
end

describe PointClickEngine::Characters::AnimationController do
  describe "animation management" do
    it "adds animations correctly" do
      controller = PointClickEngine::Characters::AnimationController.new
      controller.add_animation("idle", 0, 1, 0.1, true)

      controller.has_animation?("idle").should be_true
      anim = controller.get_animation("idle")
      anim.should_not be_nil
      if anim
        anim.start_frame.should eq(0)
        anim.frame_count.should eq(1)
        anim.frame_speed.should eq(0.1_f32)
        anim.loop.should be_true
      end
    end

    it "removes animations correctly" do
      controller = PointClickEngine::Characters::AnimationController.new
      controller.add_animation("temp", 0, 1)
      controller.has_animation?("temp").should be_true

      controller.remove_animation("temp")
      controller.has_animation?("temp").should be_false
    end

    it "clears all animations" do
      controller = PointClickEngine::Characters::AnimationController.new
      controller.add_animation("anim1", 0, 1)
      controller.add_animation("anim2", 1, 1)

      controller.animation_names.size.should eq(2)
      controller.clear_animations
      controller.animation_names.size.should eq(0)
    end

    it "gets animation names" do
      controller = PointClickEngine::Characters::AnimationController.new
      controller.add_animation("walk", 0, 4)
      controller.add_animation("idle", 4, 1)

      names = controller.animation_names
      names.should contain("walk")
      names.should contain("idle")
    end
  end

  describe "animation playback" do
    it "plays animation with sprite configuration" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("walk", 0, 4, 0.1, true)
      controller.add_animation("idle", 4, 1, 0.2, false)
      controller.play_animation("walk")

      controller.current_animation.should eq("walk")
      sprite.current_frame.should eq(0)
      sprite.frame_count.should eq(4)
      sprite.frame_speed.should eq(0.1_f32)
      sprite.loop.should be_true
      sprite.playing.should be_true
    end

    it "doesn't restart same animation unless forced" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("walk", 0, 4, 0.1, true)
      controller.play_animation("walk")
      sprite.current_frame = 2 # Simulate animation progress

      controller.play_animation("walk", force_restart: false)
      sprite.current_frame.should eq(2) # Should not reset

      controller.play_animation("walk", force_restart: true)
      sprite.current_frame.should eq(0) # Should reset
    end

    it "ignores non-existent animations" do
      controller = PointClickEngine::Characters::AnimationController.new
      original_animation = controller.current_animation
      controller.play_animation("nonexistent")

      controller.current_animation.should eq(original_animation)
    end
  end

  describe "animation updates" do
    it "advances frames based on delta time" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("test", 0, 3, 0.1, true)
      controller.play_animation("test")
      sprite.frame_timer = 0.05
      controller.update(0.06) # Total: 0.11, should advance frame

      sprite.current_frame.should eq(1)
      sprite.frame_timer.should be < 0.1
    end

    it "loops animation when reaching end" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("test", 0, 3, 0.1, true)
      controller.play_animation("test")
      sprite.current_frame = 2 # Last frame (0-based, 3 frames total)
      sprite.frame_timer = 0.05
      controller.update(0.06) # Should loop back to start

      sprite.current_frame.should eq(0) # Back to start
    end

    it "stops non-looping animation at end" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("oneshot", 5, 2, 0.1, false)
      controller.play_animation("oneshot")

      sprite.current_frame = 6 # Last frame
      sprite.frame_timer = 0.05
      controller.update(0.06)

      sprite.current_frame.should eq(6) # Stay at last frame
      sprite.playing.should be_false
    end

    it "calls completion callback for non-looping animations" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      completed_animation = ""
      controller.on_animation_complete = ->(name : String) { completed_animation = name }

      controller.add_animation("oneshot", 0, 1, 0.1, false)
      controller.play_animation("oneshot")

      sprite.frame_timer = 0.05
      controller.update(0.06)

      completed_animation.should eq("oneshot")
    end
  end

  describe "mood-based animations" do
    it "plays mood animation when mood changes" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("idle", 0, 1)
      controller.add_animation("happy", 1, 2)
      controller.add_animation("sad", 3, 2)
      controller.state = PointClickEngine::Characters::CharacterState::Idle
      controller.set_mood(PointClickEngine::Characters::CharacterMood::Happy)

      controller.mood.should eq(PointClickEngine::Characters::CharacterMood::Happy)
      controller.current_animation.should eq("happy")
    end

    it "falls back to idle if mood animation doesn't exist" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("idle", 0, 1)
      controller.state = PointClickEngine::Characters::CharacterState::Idle
      controller.set_mood(PointClickEngine::Characters::CharacterMood::Angry) # No "angry" animation

      controller.mood.should eq(PointClickEngine::Characters::CharacterMood::Angry)
      controller.current_animation.should eq("idle")
    end

    it "only plays mood animation when character is idle" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("idle", 0, 1)
      controller.add_animation("happy", 1, 2)
      controller.state = PointClickEngine::Characters::CharacterState::Walking
      controller.set_mood(PointClickEngine::Characters::CharacterMood::Happy)

      # Should not change animation when not idle
      controller.current_animation.should eq("idle")
    end
  end

  describe "directional animations" do
    it "plays directional walking animations" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("walk_left", 0, 4)
      controller.add_animation("walk_right", 4, 4)
      controller.add_animation("walk_up", 8, 4)
      controller.add_animation("walk_down", 12, 4)
      controller.state = PointClickEngine::Characters::CharacterState::Walking

      controller.set_direction(PointClickEngine::Characters::Direction::Left)
      controller.current_animation.should eq("walk_left")

      controller.set_direction(PointClickEngine::Characters::Direction::Right)
      controller.current_animation.should eq("walk_right")

      controller.set_direction(PointClickEngine::Characters::Direction::Up)
      controller.current_animation.should eq("walk_up")

      controller.set_direction(PointClickEngine::Characters::Direction::Down)
      controller.current_animation.should eq("walk_down")
    end

    it "falls back to generic walk animation" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("walk_left", 0, 4)
      controller.add_animation("walk_right", 4, 4)
      controller.add_animation("walk_up", 8, 4)
      controller.add_animation("walk_down", 12, 4)
      controller.state = PointClickEngine::Characters::CharacterState::Walking

      controller.remove_animation("walk_left")
      controller.add_animation("walk", 0, 4)

      controller.set_direction(PointClickEngine::Characters::Direction::Left)
      controller.current_animation.should eq("walk")
    end
  end

  describe "state-based animations" do
    it "plays state-appropriate animations" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("idle", 0, 1)
      controller.add_animation("talk", 1, 3)
      controller.add_animation("interact", 4, 2)
      controller.add_animation("think", 6, 1)

      controller.set_state(PointClickEngine::Characters::CharacterState::Talking)
      controller.current_animation.should eq("talk")

      controller.set_state(PointClickEngine::Characters::CharacterState::Interacting)
      controller.current_animation.should eq("interact")

      controller.set_state(PointClickEngine::Characters::CharacterState::Thinking)
      controller.current_animation.should eq("think")

      controller.set_state(PointClickEngine::Characters::CharacterState::Idle)
      controller.current_animation.should eq("idle")
    end

    it "falls back to idle for missing state animations" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("idle", 0, 1)
      controller.add_animation("talk", 1, 3)
      controller.add_animation("interact", 4, 2)
      controller.add_animation("think", 6, 1)

      controller.set_state(PointClickEngine::Characters::CharacterState::Interacting)
      controller.current_animation.should eq("interact")

      controller.remove_animation("interact")
      controller.set_state(PointClickEngine::Characters::CharacterState::Interacting)
      controller.current_animation.should eq("idle")
    end
  end

  describe "control methods" do
    it "stops animation" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("test", 0, 3, 0.1, true)
      controller.play_animation("test")

      sprite.playing = true
      controller.stop
      sprite.playing.should be_false
    end

    it "pauses and resumes animation" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("test", 0, 3, 0.1, true)
      controller.play_animation("test")

      sprite.playing = true
      controller.pause
      sprite.playing.should be_false

      controller.resume
      sprite.playing.should be_true
    end

    it "reports playing status" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("test", 0, 3, 0.1, true)
      controller.play_animation("test")

      sprite.playing = false
      controller.playing?.should be_false

      sprite.playing = true
      controller.playing?.should be_true
    end
  end

  describe "edge cases" do
    it "handles missing sprite gracefully" do
      controller = PointClickEngine::Characters::AnimationController.new
      controller.sprite = nil
      controller.add_animation("test", 0, 1)

      # Should not crash
      controller.play_animation("test")
      controller.update(0.1)
      controller.stop
      controller.playing?.should be_false
    end

    it "handles empty animation list" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite

      controller.update(0.1) # Should not crash
      controller.playing?.should be_false
    end

    it "handles animation with zero frames" do
      controller = PointClickEngine::Characters::AnimationController.new
      sprite = create_mock_sprite
      controller.sprite = sprite
      controller.add_animation("empty", 0, 0, 0.1, true)

      controller.play_animation("empty")
      controller.update(0.1) # Should not crash
    end
  end
end
