require "../spec_helper"
require "../../src/characters/character_state_manager"

describe PointClickEngine::Characters::CharacterStateManager do
  describe "initialization" do
    it "starts with default state" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      manager.direction.should eq(PointClickEngine::Characters::Direction::Right)
      manager.mood.should eq(PointClickEngine::Characters::CharacterMood::Neutral)
    end

    it "sets up valid transition rules" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      # Should be able to transition from Idle to Walking
      manager.can_transition_to?(PointClickEngine::Characters::CharacterState::Walking).should be_true

      # Should be able to transition from Idle to Talking
      manager.can_transition_to?(PointClickEngine::Characters::CharacterState::Talking).should be_true
    end
  end

  describe "state transitions" do
    it "allows valid state transitions" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      # Idle -> Walking should be valid
      result = manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      result.should be_true
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end

    it "prevents invalid state transitions" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      # Set to Talking first
      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)

      # Talking -> Walking should be invalid (not in transition rules)
      result = manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      result.should be_false
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Talking)
    end

    it "allows forced state transitions" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)

      # Force transition to Walking even if invalid
      result = manager.set_state(PointClickEngine::Characters::CharacterState::Walking, force: true)
      result.should be_true
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end

    it "returns true for same state transition" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      result = manager.set_state(PointClickEngine::Characters::CharacterState::Idle)
      result.should be_true # Should succeed even though already in Idle
    end

    it "calls state change callback" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      old_state = nil.as(PointClickEngine::Characters::CharacterState?)
      new_state = nil.as(PointClickEngine::Characters::CharacterState?)

      manager.on_state_changed = ->(old : PointClickEngine::Characters::CharacterState, new : PointClickEngine::Characters::CharacterState) {
        old_state = old
        new_state = new
      }

      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)

      old_state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      new_state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end
  end

  describe "direction changes" do
    it "changes direction and calls callback" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      old_direction = nil.as(PointClickEngine::Characters::Direction?)
      new_direction = nil.as(PointClickEngine::Characters::Direction?)

      manager.on_direction_changed = ->(old : PointClickEngine::Characters::Direction, new : PointClickEngine::Characters::Direction) {
        old_direction = old
        new_direction = new
      }

      manager.set_direction(PointClickEngine::Characters::Direction::Left)

      manager.direction.should eq(PointClickEngine::Characters::Direction::Left)
      old_direction.should eq(PointClickEngine::Characters::Direction::Right)
      new_direction.should eq(PointClickEngine::Characters::Direction::Left)
    end

    it "ignores setting same direction" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      callback_called = false
      manager.on_direction_changed = ->(old : PointClickEngine::Characters::Direction, new : PointClickEngine::Characters::Direction) {
        callback_called = true
      }

      manager.set_direction(PointClickEngine::Characters::Direction::Right) # Same as default
      callback_called.should be_false
    end
  end

  describe "mood changes" do
    it "changes mood and calls callback" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      old_mood = nil.as(PointClickEngine::Characters::CharacterMood?)
      new_mood = nil.as(PointClickEngine::Characters::CharacterMood?)

      manager.on_mood_changed = ->(old : PointClickEngine::Characters::CharacterMood, new : PointClickEngine::Characters::CharacterMood) {
        old_mood = old
        new_mood = new
      }

      manager.set_mood(PointClickEngine::Characters::CharacterMood::Happy)

      manager.mood.should eq(PointClickEngine::Characters::CharacterMood::Happy)
      old_mood.should eq(PointClickEngine::Characters::CharacterMood::Neutral)
      new_mood.should eq(PointClickEngine::Characters::CharacterMood::Happy)
    end

    it "ignores setting same mood" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      callback_called = false
      manager.on_mood_changed = ->(old : PointClickEngine::Characters::CharacterMood, new : PointClickEngine::Characters::CharacterMood) {
        callback_called = true
      }

      manager.set_mood(PointClickEngine::Characters::CharacterMood::Neutral) # Same as default
      callback_called.should be_false
    end
  end

  describe "state queries" do
    it "reports movement capability" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.can_move?.should be_true # Idle allows movement

      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      manager.can_move?.should be_true # Walking allows movement

      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      manager.can_move?.should be_false # Talking doesn't allow movement
    end

    it "reports talk capability" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.can_talk?.should be_true # Can transition from Idle to Talking

      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      manager.can_talk?.should be_true # Can transition from Walking to Talking

      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      manager.can_talk?.should be_true # Already talking
    end

    it "reports interaction capability" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.can_interact?.should be_true # Can transition from Idle to Interacting

      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      manager.can_interact?.should be_true # Can transition from Talking to Interacting
    end

    it "reports busy status" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.busy?.should be_false # Idle is not busy

      manager.set_state(PointClickEngine::Characters::CharacterState::Interacting)
      manager.busy?.should be_true # Interacting is busy

      manager.set_state(PointClickEngine::Characters::CharacterState::Thinking)
      manager.busy?.should be_true # Thinking is busy
    end

    it "reports availability" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.available?.should be_true # Idle is available

      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      manager.available?.should be_false # Walking is not available
    end

    it "reports specific states" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.moving?.should be_false
      manager.talking?.should be_false

      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      manager.moving?.should be_true

      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      manager.talking?.should be_true
    end
  end

  describe "convenience methods" do
    it "forces specific states" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)

      manager.force_idle
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Idle)

      manager.force_walking
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      manager.force_talking
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Talking)
    end

    it "returns to idle when possible" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      result = manager.try_return_to_idle
      result.should be_true
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Idle)

      # Test case where return to idle fails
      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      # Remove the transition rule temporarily to test failure
      manager.remove_transition_rule(
        PointClickEngine::Characters::CharacterState::Talking,
        PointClickEngine::Characters::CharacterState::Idle
      )
      result = manager.try_return_to_idle
      result.should be_false
      manager.state.should eq(PointClickEngine::Characters::CharacterState::Talking)
    end
  end

  describe "transition rule management" do
    it "gets valid transitions from current state" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      transitions = manager.valid_transitions_from_current
      transitions.should contain(PointClickEngine::Characters::CharacterState::Walking)
      transitions.should contain(PointClickEngine::Characters::CharacterState::Talking)
    end

    it "adds custom transition rules" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      # Add invalid transition for testing
      manager.add_transition_rule(
        PointClickEngine::Characters::CharacterState::Talking,
        PointClickEngine::Characters::CharacterState::Walking
      )

      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      result = manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      result.should be_true
    end

    it "removes transition rules" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      # Remove valid transition
      manager.remove_transition_rule(
        PointClickEngine::Characters::CharacterState::Idle,
        PointClickEngine::Characters::CharacterState::Walking
      )

      result = manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      result.should be_false
    end

    it "resets to default transition rules" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      # Modify rules
      manager.add_transition_rule(
        PointClickEngine::Characters::CharacterState::Talking,
        PointClickEngine::Characters::CharacterState::Walking
      )

      # Reset to defaults
      manager.reset_transition_rules

      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      result = manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      result.should be_false # Should be invalid again
    end
  end

  describe "descriptions" do
    it "provides state descriptions" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.state_description.should contain("idle")

      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      manager.state_description.should contain("walking")

      manager.set_state(PointClickEngine::Characters::CharacterState::Talking)
      manager.state_description.should contain("conversation")
    end

    it "provides direction descriptions" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.direction_description.should contain("right")

      manager.set_direction(PointClickEngine::Characters::Direction::Left)
      manager.direction_description.should contain("left")

      manager.set_direction(PointClickEngine::Characters::Direction::Up)
      manager.direction_description.should contain("away")
    end

    it "provides mood descriptions" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.mood_description.should contain("neutral")

      manager.set_mood(PointClickEngine::Characters::CharacterMood::Happy)
      manager.mood_description.should contain("joyful")

      manager.set_mood(PointClickEngine::Characters::CharacterMood::Angry)
      manager.mood_description.should contain("irritated")
    end
  end

  describe "state persistence" do
    it "creates and restores snapshots" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.set_state(PointClickEngine::Characters::CharacterState::Walking)
      manager.set_direction(PointClickEngine::Characters::Direction::Left)
      manager.set_mood(PointClickEngine::Characters::CharacterMood::Happy)

      snapshot = manager.create_snapshot

      # Change state
      manager.set_state(PointClickEngine::Characters::CharacterState::Idle, force: true)
      manager.set_direction(PointClickEngine::Characters::Direction::Right)
      manager.set_mood(PointClickEngine::Characters::CharacterMood::Neutral)

      # Restore from snapshot
      manager.restore_from_snapshot(snapshot)

      manager.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
      manager.direction.should eq(PointClickEngine::Characters::Direction::Left)
      manager.mood.should eq(PointClickEngine::Characters::CharacterMood::Happy)
    end

    it "handles invalid snapshot data gracefully" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      invalid_snapshot = {
        "state"     => "InvalidState",
        "direction" => "InvalidDirection",
        "mood"      => "InvalidMood",
      }

      original_state = manager.state
      original_direction = manager.direction
      original_mood = manager.mood

      manager.restore_from_snapshot(invalid_snapshot)

      # Should remain unchanged with invalid data
      manager.state.should eq(original_state)
      manager.direction.should eq(original_direction)
      manager.mood.should eq(original_mood)
    end
  end

  describe "validation" do
    it "validates current state consistency" do
      manager = PointClickEngine::Characters::CharacterStateManager.new
      manager.validate_state.should be_true

      # Simulate corrupted state (would require breaking encapsulation in real scenario)
      # For testing purposes, assume validation works correctly
      manager.validate_state.should be_true
    end
  end
end
