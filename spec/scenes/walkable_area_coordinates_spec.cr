require "../spec_helper"

describe "Walkable Area Coordinate System" do
  describe "coordinate space independence" do
    it "uses logical coordinates independent of texture size" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Simulate a small texture (doesn't affect coordinates)
      # In real usage, background might be 320x180 but coordinates are still 1024x768

      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Define regions in logical space
      region = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      region.vertices = [
        RL::Vector2.new(x: 0, y: 400),
        RL::Vector2.new(x: 1024, y: 400),
        RL::Vector2.new(x: 1024, y: 768),
        RL::Vector2.new(x: 0, y: 768),
      ]

      walkable_area.regions << region
      walkable_area.update_bounds

      # Points should be evaluated in logical space
      walkable_area.is_point_walkable?(RL::Vector2.new(x: 512, y: 600)).should be_true
      walkable_area.is_point_walkable?(RL::Vector2.new(x: 512, y: 300)).should be_false
    end
  end

  describe "validation" do
    it "detects coordinates outside logical bounds" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.logical_width = 800
      scene.logical_height = 600

      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Region extends beyond logical bounds
      region = PointClickEngine::Scenes::PolygonRegion.new("overflow", true)
      region.vertices = [
        RL::Vector2.new(x: 700, y: 500),
        RL::Vector2.new(x: 900, y: 500), # X > logical_width
        RL::Vector2.new(x: 900, y: 700), # Y > logical_height
        RL::Vector2.new(x: 700, y: 700),
      ]

      walkable_area.regions << region
      walkable_area.update_bounds

      # Bounds should reflect actual vertices (even if invalid)
      walkable_area.bounds.x.should eq(700)
      walkable_area.bounds.y.should eq(500)
      walkable_area.bounds.width.should eq(200)
      walkable_area.bounds.height.should eq(200)
    end
  end

  describe "scaling behavior" do
    it "maintains coordinate space when display is scaled" do
      # This tests that coordinates remain consistent regardless of display scaling
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      region = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      region.vertices = [
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 300, y: 100),
        RL::Vector2.new(x: 300, y: 200),
        RL::Vector2.new(x: 100, y: 200),
      ]

      walkable_area.regions << region
      walkable_area.update_bounds

      # Test point should work the same regardless of any display scaling
      test_point = RL::Vector2.new(x: 200, y: 150)
      walkable_area.is_point_walkable?(test_point).should be_true

      # Points are in logical space, not screen space
      outside_point = RL::Vector2.new(x: 350, y: 150)
      walkable_area.is_point_walkable?(outside_point).should be_false
    end
  end

  describe "bounds calculation" do
    it "correctly calculates bounds from vertices" do
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Irregular polygon
      region = PointClickEngine::Scenes::PolygonRegion.new("irregular", true)
      region.vertices = [
        RL::Vector2.new(x: 150, y: 100),
        RL::Vector2.new(x: 400, y: 150),
        RL::Vector2.new(x: 350, y: 400),
        RL::Vector2.new(x: 100, y: 350),
        RL::Vector2.new(x: 50, y: 200),
      ]

      walkable_area.regions << region
      walkable_area.update_bounds

      # Bounds should encompass all vertices
      walkable_area.bounds.x.should eq(50)       # Min X
      walkable_area.bounds.y.should eq(100)      # Min Y
      walkable_area.bounds.width.should eq(350)  # Max X (400) - Min X (50)
      walkable_area.bounds.height.should eq(300) # Max Y (400) - Min Y (100)
    end

    it "handles multiple regions correctly" do
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # First region
      region1 = PointClickEngine::Scenes::PolygonRegion.new("area1", true)
      region1.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 200, y: 0),
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 0, y: 200),
      ]

      # Second region (separate)
      region2 = PointClickEngine::Scenes::PolygonRegion.new("area2", true)
      region2.vertices = [
        RL::Vector2.new(x: 300, y: 300),
        RL::Vector2.new(x: 500, y: 300),
        RL::Vector2.new(x: 500, y: 500),
        RL::Vector2.new(x: 300, y: 500),
      ]

      walkable_area.regions << region1
      walkable_area.regions << region2
      walkable_area.update_bounds

      # Bounds should encompass both regions
      walkable_area.bounds.x.should eq(0)
      walkable_area.bounds.y.should eq(0)
      walkable_area.bounds.width.should eq(500)
      walkable_area.bounds.height.should eq(500)
    end
  end

  describe "overlapping regions" do
    it "handles walkable and non-walkable overlaps correctly" do
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Large walkable floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 500, y: 0),
        RL::Vector2.new(x: 500, y: 500),
        RL::Vector2.new(x: 0, y: 500),
      ]

      # Non-walkable obstacle in the middle
      obstacle = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle.vertices = [
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 300, y: 200),
        RL::Vector2.new(x: 300, y: 300),
        RL::Vector2.new(x: 200, y: 300),
      ]

      walkable_area.regions << floor
      walkable_area.regions << obstacle
      walkable_area.update_bounds

      # Points on floor but not in obstacle should be walkable
      walkable_area.is_point_walkable?(RL::Vector2.new(x: 100, y: 100)).should be_true
      walkable_area.is_point_walkable?(RL::Vector2.new(x: 400, y: 400)).should be_true

      # Points in obstacle should not be walkable (non-walkable takes precedence)
      walkable_area.is_point_walkable?(RL::Vector2.new(x: 250, y: 250)).should be_false
    end
  end
end
