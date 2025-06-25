require "../spec_helper"

# Comprehensive movement controller tests covering edge cases and critical fixes
describe "MovementController Comprehensive Tests" do
  describe "cached distance calculation fixes" do
    it "uses fresh distance calculations for waypoint threshold checking" do
      character = TestCharacter.new("cache_test", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Create a path with waypoints very close to starting position
      threshold = PointClickEngine::Core::GameConstants::PATHFINDING_WAYPOINT_THRESHOLD
      path = [
        RL::Vector2.new(100.0_f32, 100.0_f32),                       # Start
        RL::Vector2.new(100.0_f32 + threshold - 1.0_f32, 100.0_f32), # Very close waypoint
        RL::Vector2.new(200.0_f32, 100.0_f32),                       # End
      ]

      controller.move_along_path(path)
      controller.following_path?.should be_true
      controller.current_path_index.should eq(0)

      # Since we're already very close to the first waypoint, update should advance immediately
      controller.update(0.016_f32)

      # Should have advanced past the first waypoint due to proximity
      controller.current_path_index.should eq(1)
    end

    it "invalidates direction cache after movement" do
      character = TestCharacter.new("cache_invalidation", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      target = RL::Vector2.new(100.0_f32, 0.0_f32)
      controller.move_to(target, use_pathfinding: false)

      # Cache should be invalidated after each movement update
      initial_position = character.position
      controller.update(0.016_f32)

      # Position should have changed (character should be moving)
      # The exact position depends on walking speed and dt
      character.position.should_not eq(initial_position)
    end

    it "handles waypoint threshold correctly with small distances" do
      character = TestCharacter.new("threshold_test", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Create path with very close waypoints (within threshold)
      threshold = PointClickEngine::Core::GameConstants::PATHFINDING_WAYPOINT_THRESHOLD
      close_waypoint = RL::Vector2.new(100.0_f32 + threshold - 1.0_f32, 100.0_f32)

      path = [
        RL::Vector2.new(100.0_f32, 100.0_f32),
        close_waypoint,
        RL::Vector2.new(200.0_f32, 100.0_f32),
      ]

      controller.move_along_path(path)

      # Should immediately advance past first waypoint since we're already close
      controller.update(0.016_f32)
      controller.current_path_index.should eq(1)
    end
  end

  describe "pathfinding movement edge cases" do
    it "handles empty path gracefully" do
      character = TestCharacter.new("empty_path", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Empty path should not cause errors
      controller.move_along_path([] of RL::Vector2)
      controller.following_path?.should be_false
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end

    it "handles single waypoint path" do
      character = TestCharacter.new("single_waypoint", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      path = [RL::Vector2.new(100.0_f32, 100.0_f32)]
      controller.move_along_path(path)

      controller.following_path?.should be_true
      controller.target_position.should eq(path[0])
    end

    it "completes path when reaching final waypoint" do
      character = TestCharacter.new("path_completion", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Create a single waypoint path (just the target)
      path = [RL::Vector2.new(100.0_f32, 100.0_f32)]

      controller.move_along_path(path)

      # Update should complete the path immediately since we're already at the target
      controller.update(0.016_f32)

      # Should complete movement
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      controller.following_path?.should be_false
    end

    it "handles path index overflow gracefully" do
      character = TestCharacter.new("index_overflow", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      path = [RL::Vector2.new(100.0_f32, 100.0_f32)]
      controller.move_along_path(path)

      # Manually set index beyond path size (shouldn't happen in normal use)
      controller.current_path_index = 10

      # Should handle gracefully by stopping movement
      controller.update(0.016_f32)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end
  end

  describe "direct movement edge cases" do
    it "handles zero distance movement" do
      character = TestCharacter.new("zero_distance", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Move to same position
      same_position = RL::Vector2.new(100.0_f32, 100.0_f32)
      controller.move_to(same_position, use_pathfinding: false)

      # Should complete immediately
      controller.update(0.016_f32)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end

    it "handles very small movement distances" do
      character = TestCharacter.new("small_distance", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Move very small distance (less than arrival threshold)
      threshold = PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD
      close_target = RL::Vector2.new(100.0_f32 + threshold / 2.0_f32, 100.0_f32)

      controller.move_to(close_target, use_pathfinding: false)
      controller.update(0.016_f32)

      # Should arrive immediately
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      character.position.should eq(close_target)
    end

    it "handles movement with zero walking speed" do
      character = TestCharacter.new("zero_speed", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      character.walking_speed = 0.0_f32
      controller = PointClickEngine::Characters::MovementController.new(character)

      target = RL::Vector2.new(100.0_f32, 100.0_f32)
      controller.move_to(target, use_pathfinding: false)

      initial_position = character.position
      controller.update(0.016_f32)

      # Character should not move with zero speed
      character.position.should eq(initial_position)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking) # Still trying to walk
    end

    it "handles very high walking speeds" do
      character = TestCharacter.new("high_speed", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      character.walking_speed = 10000.0_f32 # Very high speed
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Use a very close target that will be reached in one frame
      arrival_threshold = PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD
      target = RL::Vector2.new(arrival_threshold - 1.0_f32, 0.0_f32)
      controller.move_to(target, use_pathfinding: false)

      controller.update(0.016_f32)

      # Should arrive in one frame due to close distance
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      character.position.should eq(target)
    end
  end

  describe "movement completion callbacks" do
    it "executes callback when movement completes" do
      character = TestCharacter.new("callback_test", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      callback_executed = false
      controller.on_movement_complete = -> { callback_executed = true }

      # Very close target for immediate completion
      target = RL::Vector2.new(1.0_f32, 0.0_f32)
      controller.move_to(target, use_pathfinding: false)
      controller.update(0.016_f32)

      callback_executed.should be_true
    end

    it "clears callback after execution" do
      character = TestCharacter.new("callback_clear", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      controller.on_movement_complete = -> { }
      controller.on_movement_complete.should_not be_nil

      # Complete movement
      target = RL::Vector2.new(1.0_f32, 0.0_f32)
      controller.move_to(target, use_pathfinding: false)
      controller.update(0.016_f32)

      # Callback should be cleared
      controller.on_movement_complete.should be_nil
    end

    it "executes callback when pathfinding movement completes" do
      character = TestCharacter.new("path_callback", RL::Vector2.new(100.0_f32, 100.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      callback_executed = false
      controller.on_movement_complete = -> { callback_executed = true }

      # Single waypoint for quick completion
      path = [RL::Vector2.new(101.0_f32, 100.0_f32)]
      controller.move_along_path(path)
      controller.update(0.016_f32)

      callback_executed.should be_true
    end
  end

  describe "movement state management" do
    it "tracks movement state correctly" do
      character = TestCharacter.new("state_tracking", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Initially not moving
      controller.moving?.should be_false
      controller.distance_to_target.should eq(0.0_f32)

      # Start movement
      target = RL::Vector2.new(100.0_f32, 100.0_f32)
      controller.move_to(target, use_pathfinding: false)

      controller.moving?.should be_true
      controller.distance_to_target.should be > 0.0_f32

      # Complete movement
      character.position = target
      controller.update(0.016_f32)

      controller.moving?.should be_false
      controller.distance_to_target.should eq(0.0_f32)
    end

    it "handles manual movement stopping" do
      character = TestCharacter.new("manual_stop", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      target = RL::Vector2.new(100.0_f32, 100.0_f32)
      controller.move_to(target, use_pathfinding: false)
      controller.moving?.should be_true

      # Stop manually
      controller.stop_movement

      controller.moving?.should be_false
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      controller.target_position.should be_nil
    end

    it "handles speed changes during movement" do
      character = TestCharacter.new("speed_change", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      initial_speed = 100.0_f32
      character.walking_speed = initial_speed
      controller.current_speed.should eq(initial_speed)

      # Change speed
      new_speed = 200.0_f32
      controller.set_speed(new_speed)
      controller.current_speed.should eq(new_speed)
      character.walking_speed.should eq(new_speed)
    end
  end
end

# Test character class for testing purposes
class TestCharacter < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character)
    # Test implementation
  end

  def on_look
    # Test implementation
  end

  def on_talk
    # Test implementation
  end
end
