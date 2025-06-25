require "../spec_helper"

describe PointClickEngine::Scenes::Scene do
  describe "#is_area_walkable?" do
    it "checks if a character-sized area can fit at a position" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Create a simple floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 800, y: 0),
        RL::Vector2.new(x: 800, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Test with a character in the middle (should fit)
      center_pos = RL::Vector2.new(x: 400, y: 300)
      char_size = RL::Vector2.new(x: 64, y: 64)

      scene.is_area_walkable?(center_pos, char_size, 1.0).should be_true
    end

    it "prevents large characters from fitting in small spaces" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Create floor with a narrow corridor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 200),
        RL::Vector2.new(x: 800, y: 200),
        RL::Vector2.new(x: 800, y: 400),
        RL::Vector2.new(x: 0, y: 400),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      center_pos = RL::Vector2.new(x: 400, y: 300)

      # Small character should fit
      small_size = RL::Vector2.new(x: 50, y: 50)
      scene.is_area_walkable?(center_pos, small_size, 1.0).should be_true

      # Large character should not fit (would extend beyond corridor)
      large_size = RL::Vector2.new(x: 250, y: 250)
      scene.is_area_walkable?(center_pos, large_size, 1.0).should be_false
    end

    it "accounts for character scale when checking fit" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Narrow walkable strip
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 250),
        RL::Vector2.new(x: 800, y: 250),
        RL::Vector2.new(x: 800, y: 350),
        RL::Vector2.new(x: 0, y: 350),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      center_pos = RL::Vector2.new(x: 400, y: 300)
      char_size = RL::Vector2.new(x: 40, y: 40)

      # Scale 1.0 should fit
      scene.is_area_walkable?(center_pos, char_size, 1.0).should be_true

      # Scale 3.0 makes character too large
      scene.is_area_walkable?(center_pos, char_size, 3.0).should be_false
    end

    it "correctly handles character bounds near obstacles" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor with obstacle
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 800, y: 0),
        RL::Vector2.new(x: 800, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      obstacle = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle.vertices = [
        RL::Vector2.new(x: 350, y: 250),
        RL::Vector2.new(x: 450, y: 250),
        RL::Vector2.new(x: 450, y: 350),
        RL::Vector2.new(x: 350, y: 350),
      ]

      walkable_area.regions << floor
      walkable_area.regions << obstacle
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      char_size = RL::Vector2.new(x: 60, y: 60)

      # Position where center is walkable but character would overlap obstacle
      near_obstacle = RL::Vector2.new(x: 340, y: 300)
      scene.is_walkable?(near_obstacle).should be_true                       # Point check
      scene.is_area_walkable?(near_obstacle, char_size, 1.0).should be_false # Area check

      # Position far enough from obstacle
      safe_pos = RL::Vector2.new(x: 250, y: 300)
      scene.is_area_walkable?(safe_pos, char_size, 1.0).should be_true
    end

    it "checks all corners and edge midpoints of character bounds" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Create an L-shaped walkable area
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 400, y: 0),
        RL::Vector2.new(x: 400, y: 200),
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 200, y: 400),
        RL::Vector2.new(x: 0, y: 400),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Position at the inner corner of the L
      corner_pos = RL::Vector2.new(x: 200, y: 200)
      char_size = RL::Vector2.new(x: 100, y: 100)

      # Character would extend into non-walkable area
      scene.is_area_walkable?(corner_pos, char_size, 1.0).should be_false
    end
  end
end
