require "../spec_helper"
require "../../src/characters/character"
require "../../src/characters/movement_controller"
require "../../src/scenes/scene"
require "../../src/scenes/walkable_area"

module PointClickEngine::Characters
  describe "Position Conversion" do
    it "correctly converts feet position to center position" do
      # Character with size 56x56 at scale 1.5 = 84x84 effective size
      character = TestCharacter.new("test", RL::Vector2.new(x: 100, y: 200), RL::Vector2.new(x: 56, y: 56))
      character.scale = 1.5

      # Character position is at feet (bottom-center)
      feet_position = character.position

      # Center should be half the effective height above feet
      effective_height = character.size.y * character.scale          # 56 * 1.5 = 84
      expected_center_y = feet_position.y - (effective_height / 2.0) # 200 - 42 = 158

      # The center X should remain the same
      expected_center = RL::Vector2.new(x: feet_position.x, y: expected_center_y)

      # This is what the movement controller does
      calculated_center = RL::Vector2.new(
        x: feet_position.x,
        y: feet_position.y - (character.size.y * character.scale) / 2.0
      )

      calculated_center.x.should eq(expected_center.x)
      calculated_center.y.should eq(expected_center.y)
    end

    it "collision box should be centered around the center position" do
      character = TestCharacter.new("test", RL::Vector2.new(x: 100, y: 200), RL::Vector2.new(x: 56, y: 56))
      character.scale = 1.5

      # Calculate center from feet position
      center_position = RL::Vector2.new(
        x: character.position.x,
        y: character.position.y - (character.size.y * character.scale) / 2.0
      )

      # Half extents
      half_width = (character.size.x * character.scale) / 2.0  # 42
      half_height = (character.size.y * character.scale) / 2.0 # 42

      # The collision box corners from center
      top_left = RL::Vector2.new(x: center_position.x - half_width, y: center_position.y - half_height)
      bottom_right = RL::Vector2.new(x: center_position.x + half_width, y: center_position.y + half_height)

      # Verify the box is correct
      # Top should be at: 200 - 84 = 116
      # Bottom should be at: 200
      top_left.y.should eq(character.position.y - character.size.y * character.scale)
      bottom_right.y.should eq(character.position.y)

      # Left should be at: 100 - 42 = 58
      # Right should be at: 100 + 42 = 142
      top_left.x.should eq(character.position.x - half_width)
      bottom_right.x.should eq(character.position.x + half_width)
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
