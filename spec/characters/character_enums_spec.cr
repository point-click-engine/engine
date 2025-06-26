require "../spec_helper"

module PointClickEngine::Characters
  describe CharacterState do
    describe "#to_s" do
      it "converts idle state to string" do
        io = IO::Memory.new
        CharacterState::Idle.to_s(io)
        io.to_s.should eq("idle")
      end

      it "converts walking state to string" do
        CharacterState::Walking.to_s.should eq("walking")
      end

      it "converts talking state to string" do
        CharacterState::Talking.to_s.should eq("talking")
      end

      it "converts picking_up state to string" do
        CharacterState::PickingUp.to_s.should eq("picking_up")
      end

      it "converts using state to string" do
        CharacterState::Using.to_s.should eq("using")
      end

      it "converts pushing state to string" do
        CharacterState::Pushing.to_s.should eq("pushing")
      end

      it "converts pulling state to string" do
        CharacterState::Pulling.to_s.should eq("pulling")
      end

      it "converts climbing state to string" do
        CharacterState::Climbing.to_s.should eq("climbing")
      end

      it "converts sitting state to string" do
        CharacterState::Sitting.to_s.should eq("sitting")
      end

      it "converts standing state to string" do
        CharacterState::Standing.to_s.should eq("standing")
      end

      it "converts dying state to string" do
        CharacterState::Dying.to_s.should eq("dying")
      end

      it "converts interacting state to string" do
        CharacterState::Interacting.to_s.should eq("interacting")
      end

      it "converts looking state to string" do
        CharacterState::Looking.to_s.should eq("looking")
      end

      it "converts thinking state to string" do
        CharacterState::Thinking.to_s.should eq("thinking")
      end
    end
  end

  describe Direction do
    describe "#to_s" do
      it "converts left direction to string" do
        Direction::Left.to_s.should eq("left")
      end

      it "converts right direction to string" do
        Direction::Right.to_s.should eq("right")
      end

      it "converts up direction to string" do
        Direction::Up.to_s.should eq("up")
      end

      it "converts down direction to string" do
        Direction::Down.to_s.should eq("down")
      end
    end

    describe "#opposite" do
      it "returns right for left" do
        Direction::Left.opposite.should eq(Direction::Right)
      end

      it "returns left for right" do
        Direction::Right.opposite.should eq(Direction::Left)
      end

      it "returns down for up" do
        Direction::Up.opposite.should eq(Direction::Down)
      end

      it "returns up for down" do
        Direction::Down.opposite.should eq(Direction::Up)
      end
    end

    describe ".from_velocity" do
      it "returns right for positive x velocity" do
        velocity = RL::Vector2.new(10.0f32, 5.0f32)
        Direction.from_velocity(velocity).should eq(Direction::Right)
      end

      it "returns left for negative x velocity" do
        velocity = RL::Vector2.new(-10.0f32, 5.0f32)
        Direction.from_velocity(velocity).should eq(Direction::Left)
      end

      it "returns down for positive y velocity when y dominates" do
        velocity = RL::Vector2.new(5.0f32, 10.0f32)
        Direction.from_velocity(velocity).should eq(Direction::Down)
      end

      it "returns up for negative y velocity when y dominates" do
        velocity = RL::Vector2.new(5.0f32, -10.0f32)
        Direction.from_velocity(velocity).should eq(Direction::Up)
      end

      it "favors horizontal direction when velocities are equal" do
        velocity = RL::Vector2.new(10.0f32, 10.0f32)
        Direction.from_velocity(velocity).should eq(Direction::Right)
      end
    end
  end

  describe CharacterMood do
    describe "#to_s" do
      it "converts neutral mood to string" do
        CharacterMood::Neutral.to_s.should eq("neutral")
      end

      it "converts happy mood to string" do
        CharacterMood::Happy.to_s.should eq("happy")
      end

      it "converts sad mood to string" do
        CharacterMood::Sad.to_s.should eq("sad")
      end

      it "converts angry mood to string" do
        CharacterMood::Angry.to_s.should eq("angry")
      end

      it "converts friendly mood to string" do
        CharacterMood::Friendly.to_s.should eq("friendly")
      end

      it "converts hostile mood to string" do
        CharacterMood::Hostile.to_s.should eq("hostile")
      end

      it "converts wise mood to string" do
        CharacterMood::Wise.to_s.should eq("wise")
      end

      it "converts curious mood to string" do
        CharacterMood::Curious.to_s.should eq("curious")
      end

      it "converts confused mood to string" do
        CharacterMood::Confused.to_s.should eq("confused")
      end

      it "converts grateful mood to string" do
        CharacterMood::Grateful.to_s.should eq("grateful")
      end

      it "converts suspicious mood to string" do
        CharacterMood::Suspicious.to_s.should eq("suspicious")
      end
    end

    describe "#intensity" do
      it "returns 0.0 for neutral mood" do
        CharacterMood::Neutral.intensity.should eq(0.0f32)
      end

      it "returns 0.8 for happy mood" do
        CharacterMood::Happy.intensity.should eq(0.8f32)
      end

      it "returns 0.6 for sad mood" do
        CharacterMood::Sad.intensity.should eq(0.6f32)
      end

      it "returns 1.0 for angry mood" do
        CharacterMood::Angry.intensity.should eq(1.0f32)
      end

      it "returns 0.7 for friendly mood" do
        CharacterMood::Friendly.intensity.should eq(0.7f32)
      end

      it "returns 0.9 for hostile mood" do
        CharacterMood::Hostile.intensity.should eq(0.9f32)
      end

      it "returns 0.4 for wise mood" do
        CharacterMood::Wise.intensity.should eq(0.4f32)
      end

      it "returns 0.6 for curious mood" do
        CharacterMood::Curious.intensity.should eq(0.6f32)
      end

      it "returns 0.5 for confused mood" do
        CharacterMood::Confused.intensity.should eq(0.5f32)
      end

      it "returns 0.7 for grateful mood" do
        CharacterMood::Grateful.intensity.should eq(0.7f32)
      end

      it "returns 0.8 for suspicious mood" do
        CharacterMood::Suspicious.intensity.should eq(0.8f32)
      end
    end

    describe "#positive?" do
      it "returns true for positive moods" do
        CharacterMood::Happy.positive?.should be_true
        CharacterMood::Friendly.positive?.should be_true
        CharacterMood::Wise.positive?.should be_true
        CharacterMood::Curious.positive?.should be_true
        CharacterMood::Grateful.positive?.should be_true
      end

      it "returns false for non-positive moods" do
        CharacterMood::Neutral.positive?.should be_false
        CharacterMood::Sad.positive?.should be_false
        CharacterMood::Angry.positive?.should be_false
        CharacterMood::Hostile.positive?.should be_false
        CharacterMood::Confused.positive?.should be_false
        CharacterMood::Suspicious.positive?.should be_false
      end
    end

    describe "#negative?" do
      it "returns true for negative moods" do
        CharacterMood::Sad.negative?.should be_true
        CharacterMood::Angry.negative?.should be_true
        CharacterMood::Hostile.negative?.should be_true
        CharacterMood::Suspicious.negative?.should be_true
      end

      it "returns false for non-negative moods" do
        CharacterMood::Neutral.negative?.should be_false
        CharacterMood::Happy.negative?.should be_false
        CharacterMood::Friendly.negative?.should be_false
        CharacterMood::Wise.negative?.should be_false
        CharacterMood::Curious.negative?.should be_false
        CharacterMood::Confused.negative?.should be_false
        CharacterMood::Grateful.negative?.should be_false
      end
    end
  end
end
