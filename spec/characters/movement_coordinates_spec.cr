require "../spec_helper"
require "../../src/characters/movement_controller"
require "../../src/characters/character"

# Test character implementation
class TestCharacterForMovement < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character)
  end

  def on_look
  end

  def on_talk
  end
end

describe PointClickEngine::Characters::MovementController do
  describe "coordinate changes during movement" do
    it "actually changes character position when moving" do
      # Create test character at specific position
      initial_position = RL::Vector2.new(100.0_f32, 100.0_f32)
      character = TestCharacterForMovement.new("TestChar", initial_position, RL::Vector2.new(32, 32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Store initial position
      initial_x = character.position.x
      initial_y = character.position.y

      # Move to a different position
      target = RL::Vector2.new(200.0_f32, 200.0_f32)
      controller.move_to(target)

      # Character should be in walking state
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)

      # Update multiple times to ensure movement occurs
      10.times do
        controller.update(0.016_f32) # 16ms per frame
      end

      # Character position should have changed
      character.position.x.should_not eq(initial_x)
      character.position.y.should_not eq(initial_y)

      # Character should be moving towards target
      x_diff = target.x - initial_x
      y_diff = target.y - initial_y

      # Check movement direction is correct
      if x_diff > 0
        character.position.x.should be > initial_x
      else
        character.position.x.should be < initial_x
      end

      if y_diff > 0
        character.position.y.should be > initial_y
      else
        character.position.y.should be < initial_y
      end
    end

    it "reaches the target position within threshold" do
      # Create test character
      character = TestCharacterForMovement.new("TestChar", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))
      character.walking_speed = 100.0_f32 # Explicit speed
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Move to a target beyond the arrival threshold
      target = RL::Vector2.new(50.0_f32, 50.0_f32)
      controller.move_to(target)

      # Track if we ever stop
      frames_updated = 0
      max_frames = 200 # Increase max frames

      # Update until movement completes
      while controller.moving? && frames_updated < max_frames
        controller.update(0.016_f32)
        frames_updated += 1
      end

      # Debug output if still moving
      if controller.moving?
        distance = Math.sqrt((character.position.x - target.x)**2 + (character.position.y - target.y)**2)
        puts "Still moving after #{frames_updated} frames. Distance to target: #{distance}"
        puts "Character position: #{character.position}, Target: #{target}"
      end

      # Character should have stopped moving
      controller.moving?.should be_false
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)

      # Character should be within arrival threshold of target
      distance = Math.sqrt((character.position.x - target.x)**2 + (character.position.y - target.y)**2)
      distance.should be <= PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD
    end

    it "moves at the correct speed" do
      # Create test character with known speed
      character = TestCharacterForMovement.new("TestChar", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))
      character.walking_speed = 100.0_f32 # 100 pixels per second
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Move horizontally
      target = RL::Vector2.new(100.0_f32, 0.0_f32)
      controller.move_to(target)

      # Update for exactly 0.5 seconds
      controller.update(0.5_f32)

      # Character should have moved approximately 50 pixels (100 * 0.5)
      expected_distance = 50.0_f32
      actual_distance = character.position.x

      # Allow small margin for floating point precision
      actual_distance.should be_close(expected_distance, 1.0_f32)
    end

    it "updates position incrementally during movement" do
      # Create test character
      character = TestCharacterForMovement.new("TestChar", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Track positions
      positions = [] of {Float32, Float32}
      positions << {character.position.x, character.position.y}

      # Move to target
      target = RL::Vector2.new(100.0_f32, 100.0_f32)
      controller.move_to(target)

      # Update and track positions
      5.times do
        controller.update(0.016_f32)
        positions << {character.position.x, character.position.y}
      end

      # All positions should be different (character is moving)
      positions.uniq.size.should eq(positions.size)

      # Positions should be getting progressively closer to target
      prev_distance = Float32::INFINITY
      positions.each do |x, y|
        distance = Math.sqrt((target.x - x)**2 + (target.y - y)**2)
        distance.should be <= prev_distance
        prev_distance = distance
      end
    end

    it "stops at target without overshooting" do
      # Create test character with high speed
      character = TestCharacterForMovement.new("TestChar", RL::Vector2.new(0, 0), RL::Vector2.new(32, 32))
      character.walking_speed = 1000.0_f32 # Very fast
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Move to relatively close target
      target = RL::Vector2.new(50.0_f32, 0.0_f32)
      controller.move_to(target)

      # Update with large time step that would overshoot
      controller.update(0.1_f32) # Would move 100 pixels without clamping

      # Should stop exactly at target, not overshoot
      character.position.x.should eq(target.x)
      character.position.y.should eq(target.y)
    end
  end
end
