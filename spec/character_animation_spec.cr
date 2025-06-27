require "./spec_helper"

class TestCharacter < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character)
  end

  def on_look
  end

  def on_talk
  end
end

describe PointClickEngine::Characters::Character do
  describe "#add_animation" do
    it "adds animation data to character" do
      character = TestCharacter.new("Hero", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 32, y: 32))

      character.add_animation("walk_right", 0, 4, 0.1_f32, true)
      character.animation_controller.should_not be_nil
      character.animation_controller.try(&.has_animation?("walk_right")).should be_true

      anim = character.animation_controller.try(&.get_animation("walk_right"))
      anim.should_not be_nil
      anim.try(&.start_frame).should eq(0)
      anim.try(&.frame_count).should eq(4)
      anim.try(&.frame_speed).should eq(0.1_f32)
      anim.try(&.loop).should be_true
    end
  end

  describe "#walk_to" do
    it "sets walking state and target position" do
      character = TestCharacter.new("Hero", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 32, y: 32))
      target = RL::Vector2.new(x: 200, y: 150)

      character.walk_to(target)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
      character.target_position.should eq(target)
      character.direction.should eq(PointClickEngine::Characters::Direction::Right)
    end

    it "sets correct direction based on target" do
      character = TestCharacter.new("Hero", RL::Vector2.new(x: 200, y: 100), RL::Vector2.new(x: 32, y: 32))
      target = RL::Vector2.new(x: 100, y: 150)

      character.walk_to(target)
      character.direction.should eq(PointClickEngine::Characters::Direction::Left)
    end
  end

  describe "#stop_walking" do
    it "stops walking and resets state" do
      character = TestCharacter.new("Hero", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 32, y: 32))

      character.walk_to(RL::Vector2.new(x: 200, y: 150))
      character.stop_walking

      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      character.target_position.should be_nil
    end
  end
end

describe PointClickEngine::Graphics::Sprites::Animated do
  describe "#new" do
    it "creates animated sprite with correct properties" do
      sprite = PointClickEngine::Graphics::Sprites::Animated.new(
        RL::Vector2.new(x: 100, y: 100), 32, 32, 8
      )

      sprite.frame_width.should eq(32)
      sprite.frame_height.should eq(32)
      sprite.frame_count.should eq(8)
      sprite.current_frame.should eq(0)
      sprite.playing.should be_true
    end
  end

  describe "#play and #stop" do
    it "controls animation playback" do
      sprite = PointClickEngine::Graphics::Sprites::Animated.new(
        RL::Vector2.new(x: 100, y: 100), 32, 32, 4
      )

      sprite.stop
      sprite.playing.should be_false

      sprite.play
      sprite.playing.should be_true
      sprite.frame_timer.should eq(0.0)
    end
  end
end
