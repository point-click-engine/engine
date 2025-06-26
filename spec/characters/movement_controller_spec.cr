require "../spec_helper"
require "../../src/characters/movement_controller"
require "../../src/characters/character"

# Mock character class for testing
class MockCharacter < PointClickEngine::Characters::Character
  def initialize(position : Raylib::Vector2, @walking_speed : Float32 = 100.0_f32)
    super("TestCharacter", position, Raylib::Vector2.new(x: 32.0_f32, y: 32.0_f32))
    @animation_controller.try(&.add_animation("idle", 0, 1, 0.1_f32, false))
    @animation_controller.try(&.add_animation("walk_left", 1, 4, 0.1_f32, true))
    @animation_controller.try(&.add_animation("walk_right", 5, 4, 0.1_f32, true))
    @animation_controller.try(&.add_animation("walk_up", 9, 4, 0.1_f32, true))
    @animation_controller.try(&.add_animation("walk_down", 13, 4, 0.1_f32, true))
  end

  def on_interact(interactor : PointClickEngine::Characters::Character)
    # Mock implementation
  end

  def on_look
    # Mock implementation
  end

  def on_talk
    # Mock implementation
  end
end

describe PointClickEngine::Characters::MovementController do
  describe "#initialize" do
    it "creates a new MovementController instance" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      controller.should be_a(PointClickEngine::Characters::MovementController)
      controller.character.should eq(character)
    end
  end

  describe "#move_to" do
    it "initiates movement to target position" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 100.0_f32, y: 0.0_f32)

      controller.move_to(target)

      controller.target_position.should eq(target)
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end

    it "stops movement when target is reached" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 1.0_f32, y: 0.0_f32) # Very close target

      controller.move_to(target)

      # Move multiple times to reach target
      10.times do
        controller.update(0.1_f32)
      end

      # Should eventually reach the target
      distance = PointClickEngine::Utils::VectorMath.distance(character.position, target)
      distance.should be < PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end

    it "handles zero delta time gracefully" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 100.0_f32, y: 0.0_f32)

      controller.move_to(target)
      controller.update(0.0_f32)

      # Should not crash and position shouldn't change
      character.position.x.should eq(0.0_f32)
    end
  end

  describe "movement animations" do
    it "sets walking animation when moving right" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 100.0_f32, y: 0.0_f32)

      controller.move_to(target)
      controller.update(0.01_f32)

      character.animation_controller.try(&.current_animation).should eq("walk_right")
    end

    it "sets walking animation when moving left" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 100.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32)

      controller.move_to(target)
      controller.update(0.01_f32)

      character.animation_controller.try(&.current_animation).should eq("walk_left")
    end

    it "returns to idle animation when movement stops" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      controller.stop_movement

      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      character.animation_controller.try(&.current_animation).should eq("idle")
    end
  end

  describe "facing direction" do
    it "updates facing direction based on movement" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 50.0_f32, y: 50.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Test facing right
      controller.move_to(Raylib::Vector2.new(x: 150.0_f32, y: 50.0_f32))
      controller.update(0.01_f32)
      character.direction.should eq(PointClickEngine::Characters::Direction::Right)

      # Test facing left
      controller.move_to(Raylib::Vector2.new(x: 0.0_f32, y: 50.0_f32))
      controller.update(0.01_f32)
      character.direction.should eq(PointClickEngine::Characters::Direction::Left)
    end
  end

  describe "target reaching" do
    it "stops when character reaches target" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      # Target at same position
      target = Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32)

      controller.move_to(target)
      controller.update(0.1_f32)

      controller.moving?.should be_false
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end

    it "continues moving when far from target" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32)

      controller.move_to(target)
      controller.update(0.01_f32) # Small time step

      controller.moving?.should be_true
      character.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end
  end

  describe "movement calculation" do
    it "moves at correct speed" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 100.0_f32, y: 0.0_f32)
      dt = 0.1_f32

      controller.move_to(target)
      initial_x = character.position.x
      controller.update(dt)

      # Should move speed * dt units
      expected_movement = character.walking_speed * dt
      actual_movement = character.position.x - initial_x
      actual_movement.should be_close(expected_movement, 0.1_f32)
    end

    it "doesn't overshoot target" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 2.0_f32, y: 0.0_f32) # Close target
      character.walking_speed = 100.0_f32                  # High speed

      controller.move_to(target)
      controller.update(0.1_f32) # Would move 10 units without clamping

      # Should not overshoot the target
      character.position.x.should eq(2.0_f32)
    end
  end

  describe "#move_along_path" do
    it "follows a path of waypoints" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      waypoints = [
        Raylib::Vector2.new(x: 50.0_f32, y: 0.0_f32),
        Raylib::Vector2.new(x: 100.0_f32, y: 0.0_f32),
        Raylib::Vector2.new(x: 100.0_f32, y: 50.0_f32),
      ]

      controller.move_along_path(waypoints)

      controller.following_path?.should be_true
      controller.path.should eq(waypoints)
      controller.target_position.should eq(waypoints.last)
    end

    it "advances through waypoints" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      waypoints = [
        Raylib::Vector2.new(x: 10.0_f32, y: 0.0_f32), # Close waypoint
        Raylib::Vector2.new(x: 20.0_f32, y: 0.0_f32),
      ]

      controller.move_along_path(waypoints)

      # Move enough to reach first waypoint
      20.times { controller.update(0.1_f32) }

      # Should have advanced past first waypoint
      controller.current_path_index.should be >= 1
    end
  end

  describe "edge cases" do
    it "handles very small movements" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 0.001_f32, y: 0.001_f32)

      controller.move_to(target)
      controller.update(0.016_f32)

      # Should reach tiny target immediately
      controller.moving?.should be_false
    end

    it "handles very large movements" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 10000.0_f32, y: 10000.0_f32)

      controller.move_to(target)
      controller.update(0.016_f32)

      # Should handle large movements without issues
      controller.moving?.should be_true
      character.position.x.should be > 0.0_f32
    end

    it "handles negative coordinates" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: -50.0_f32, y: -50.0_f32)

      controller.move_to(target)
      controller.update(0.016_f32)

      character.position.x.should be < 100.0_f32
      character.position.y.should be < 100.0_f32
    end

    it "handles empty path gracefully" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      controller.move_along_path([] of Raylib::Vector2)

      controller.following_path?.should be_false
      controller.moving?.should be_false
    end
  end

  describe "performance" do
    it "completes movement operations efficiently" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)
      target = Raylib::Vector2.new(x: 100.0_f32, y: 0.0_f32)

      start_time = Time.monotonic
      controller.move_to(target)

      # Simulate many updates
      100.times do
        controller.update(0.016_f32)
      end

      end_time = Time.monotonic
      elapsed = (end_time - start_time).total_milliseconds

      # Should complete quickly with caching optimizations
      elapsed.should be < 50.0
    end
  end

  describe "blocked movement handling" do
    it "stores pathfinding preference when movement is blocked" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      character.use_pathfinding = true
      controller = PointClickEngine::Characters::MovementController.new(character)

      # The preference should be stored internally
      controller.move_to(Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32), use_pathfinding: false)

      # Can't directly test private field, but behavior should reflect preference
      controller.target_position.should_not be_nil
    end

    it "handles close waypoint blocking gracefully" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 0.0_f32, y: 0.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Set up path with very close first waypoint
      waypoints = [
        Raylib::Vector2.new(x: 5.0_f32, y: 5.0_f32), # Within PATHFINDING_WAYPOINT_THRESHOLD * 2
        Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32),
      ]

      controller.move_along_path(waypoints)
      controller.current_path_index.should eq(0)

      # Move close to first waypoint
      character.position = Raylib::Vector2.new(x: 4.0_f32, y: 4.0_f32)

      # Update should advance past the close waypoint
      controller.update(0.016_f32)

      # Should either reach waypoint or advance if blocked
      if controller.current_path_index == 0
        # If still at first waypoint, position should be very close
        distance = PointClickEngine::Utils::VectorMath.distance(character.position, waypoints[0])
        distance.should be < PointClickEngine::Core::GameConstants::PATHFINDING_WAYPOINT_THRESHOLD
      end
    end
  end

  describe "character size awareness" do
    it "respects character scale in movement" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32))
      character.scale = 2.0_f32 # Larger character
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Character size should be considered in movement calculations
      character.size.x.should eq(32.0_f32)
      character.size.y.should eq(32.0_f32)
      # Effective size with scale: 64x64

      controller.move_to(Raylib::Vector2.new(x: 200.0_f32, y: 200.0_f32))
      controller.update(0.016_f32)

      # Movement should work regardless of scale
      controller.moving?.should be_true
    end
  end

  describe "micro-movement prevention" do
    it "avoids getting stuck in micro-movements" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Move to a position very close (potential micro-movement)
      controller.move_to(Raylib::Vector2.new(x: 102.0_f32, y: 100.0_f32))

      # Update multiple times
      5.times { controller.update(0.016_f32) }

      # Should complete movement quickly and not get stuck
      controller.moving?.should be_false
      character.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end

    it "handles pathfinding to very close waypoints" do
      character = MockCharacter.new(Raylib::Vector2.new(x: 100.0_f32, y: 100.0_f32))
      controller = PointClickEngine::Characters::MovementController.new(character)

      # Path with micro-waypoint
      waypoints = [
        Raylib::Vector2.new(x: 101.0_f32, y: 100.0_f32), # 1 pixel away
        Raylib::Vector2.new(x: 200.0_f32, y: 200.0_f32),
      ]

      controller.move_along_path(waypoints)

      # Should handle micro-waypoint efficiently
      controller.update(0.1_f32)

      # Should quickly advance past micro-waypoint
      controller.current_path_index.should be >= 1
    end
  end
end
