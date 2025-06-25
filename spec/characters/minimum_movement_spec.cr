require "../spec_helper"
require "../../src/characters/character"
require "../../src/characters/movement_controller"
require "../../src/utils/vector_math"

module PointClickEngine::Characters
  describe "Minimum Movement" do
    it "ensures minimum movement step to prevent getting stuck" do
      character = TestCharacter.new("test", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 56, y: 56))
      controller = MovementController.new(character)

      # Set a very slow walking speed that would normally result in tiny movements
      character.walking_speed = 10.0_f32 # 10 pixels per second

      # With a small dt, movement would be tiny
      small_dt = 0.001_f32 # 1 millisecond
      # Normal movement would be: 10 * 0.001 = 0.01 pixels (way too small!)

      # Move to a nearby target
      target = RL::Vector2.new(x: 105, y: 100)
      controller.move_to(target, use_pathfinding: false)

      # Store initial position
      initial_pos = character.position.dup

      # Update with small dt
      controller.update(small_dt)

      # Calculate actual movement
      actual_movement = Utils::VectorMath.distance(initial_pos, character.position)

      # Movement should be at least 2.0 pixels (minimum step)
      actual_movement.should be >= 2.0_f32

      # But not more than the distance to target
      actual_movement.should be <= 5.0_f32
    end

    it "respects target distance when close" do
      character = TestCharacter.new("test", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 56, y: 56))
      controller = MovementController.new(character)

      # Set slow speed
      character.walking_speed = 10.0_f32

      # Move to a very close target (less than minimum step)
      target = RL::Vector2.new(x: 101, y: 100) # Only 1 pixel away
      controller.move_to(target, use_pathfinding: false)

      # Update
      controller.update(0.001_f32)

      # Should have reached the target exactly (not overshot)
      character.position.x.should eq(101.0_f32)
      character.position.y.should eq(100.0_f32)

      # Should have stopped
      controller.moving?.should be_false
    end
  end

  # Test helper class
  class TestCharacter < Character
    def on_interact(interactor : Character)
    end

    def on_look
    end

    def on_talk
    end
  end
end
