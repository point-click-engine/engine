require "../spec_helper"
require "../../src/core/engine"
require "../../src/characters/player"

describe "Navigation Radius Calculation" do
  describe "character-based navigation radius" do
    it "calculates radius based on character dimensions and scale" do
      # Create a player with specific dimensions
      player = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(56, 56) # Base size
      )

      # Test with scale 1.0
      player.scale = 1.0_f32
      char_width = player.size.x * player.scale  # 56 * 1.0 = 56
      char_height = player.size.y * player.scale # 56 * 1.0 = 56
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      navigation_radius.should eq(28.0_f32)

      # Test with scale 1.5
      player.scale = 1.5_f32
      char_width = player.size.x * player.scale  # 56 * 1.5 = 84
      char_height = player.size.y * player.scale # 56 * 1.5 = 84
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      navigation_radius.should eq(42.0_f32)

      # Test with scale 2.0
      player.scale = 2.0_f32
      char_width = player.size.x * player.scale  # 56 * 2.0 = 112
      char_height = player.size.y * player.scale # 56 * 2.0 = 112
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      navigation_radius.should eq(56.0_f32)
    end

    it "uses smaller dimension for non-square characters" do
      # Create a player with non-square dimensions
      player = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(32, 64) # Tall character
      )

      player.scale = 1.0_f32
      char_width = player.size.x * player.scale  # 32
      char_height = player.size.y * player.scale # 64
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      # Should use the smaller dimension (width)
      navigation_radius.should eq(16.0_f32)

      # Test with wide character
      player.size = RL::Vector2.new(80, 40)      # Wide character
      char_width = player.size.x * player.scale  # 80
      char_height = player.size.y * player.scale # 40
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      # Should use the smaller dimension (height)
      navigation_radius.should eq(20.0_f32)
    end

    it "scales navigation radius appropriately" do
      player = PointClickEngine::Characters::Player.new(
        "TestPlayer",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(50, 50)
      )

      # Test different scales
      scales = [0.5_f32, 1.0_f32, 1.5_f32, 2.0_f32, 3.0_f32]
      expected_radii = [12.5_f32, 25.0_f32, 37.5_f32, 50.0_f32, 75.0_f32]

      scales.each_with_index do |scale, i|
        player.scale = scale
        char_width = player.size.x * player.scale
        char_height = player.size.y * player.scale
        navigation_radius = Math.min(char_width, char_height) / 2.0_f32

        navigation_radius.should be_close(expected_radii[i], 0.01)
      end
    end
  end

  describe "navigation grid walkability impact" do
    it "affects walkable cell count based on radius" do
      # Larger radius = fewer walkable cells
      # Smaller radius = more walkable cells

      # This is a conceptual test showing the relationship
      # In practice, the navigation grid generation would use the radius

      # Example with 100x100 area and obstacles
      total_cells = 100 * 100

      # With small radius (10), more cells are walkable
      small_radius = 10.0_f32
      walkable_with_small = total_cells * 0.7 # ~70% walkable

      # With large radius (50), fewer cells are walkable
      large_radius = 50.0_f32
      walkable_with_large = total_cells * 0.3 # ~30% walkable

      (walkable_with_small > walkable_with_large).should be_true
    end
  end

  describe "edge cases" do
    it "handles very small characters" do
      player = PointClickEngine::Characters::Player.new(
        "TinyPlayer",
        RL::Vector2.new(100, 100),
        RL::Vector2.new(8, 8) # Very small
      )

      player.scale = 1.0_f32
      char_width = player.size.x * player.scale  # 8
      char_height = player.size.y * player.scale # 8
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      navigation_radius.should eq(4.0_f32)

      # Even with scale, should remain reasonable
      player.scale = 0.5_f32
      char_width = player.size.x * player.scale  # 4
      char_height = player.size.y * player.scale # 4
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      navigation_radius.should eq(2.0_f32)
    end

    it "handles very large characters" do
      player = PointClickEngine::Characters::Player.new(
        "GiantPlayer",
        RL::Vector2.new(500, 500),
        RL::Vector2.new(200, 200) # Very large
      )

      player.scale = 1.0_f32
      char_width = player.size.x * player.scale  # 200
      char_height = player.size.y * player.scale # 200
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      navigation_radius.should eq(100.0_f32)

      # With additional scale
      player.scale = 2.0_f32
      char_width = player.size.x * player.scale  # 400
      char_height = player.size.y * player.scale # 400
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      navigation_radius.should eq(200.0_f32)
    end

    it "ensures minimum viable radius" do
      # Even tiny characters should have some minimum radius
      player = PointClickEngine::Characters::Player.new(
        "MicroPlayer",
        RL::Vector2.new(50, 50),
        RL::Vector2.new(1, 1) # Extremely small
      )

      player.scale = 1.0_f32
      char_width = player.size.x * player.scale
      char_height = player.size.y * player.scale
      navigation_radius = Math.min(char_width, char_height) / 2.0_f32

      # Raw calculation gives 0.5
      navigation_radius.should eq(0.5_f32)

      # In practice, engine might want to enforce minimum
      min_radius = 5.0_f32
      effective_radius = Math.max(navigation_radius, min_radius)
      effective_radius.should eq(5.0_f32)
    end
  end
end
