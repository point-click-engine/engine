require "../spec_helper"
require "../../src/scenes/scene"
require "../../src/scenes/walkable_area"

describe PointClickEngine::Scenes::Scene do
  describe "#is_area_walkable?" do
    it "checks if a character-sized area is walkable" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("main_area", true)
      region.vertices = [
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 500, y: 100),
        RL::Vector2.new(x: 500, y: 500),
        RL::Vector2.new(x: 100, y: 500),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Test center of walkable area with character size
      center = RL::Vector2.new(x: 300, y: 300)
      size = RL::Vector2.new(x: 56, y: 56)
      scale = 1.0_f32

      scene.is_area_walkable?(center, size, scale).should be_true
    end

    it "returns false when character bounds exceed walkable area" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create small walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("small_area", true)
      region.vertices = [
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 300, y: 200),
        RL::Vector2.new(x: 300, y: 300),
        RL::Vector2.new(x: 200, y: 300),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Create navigation grid directly since we don't have a background texture in tests
      scene.navigation_grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene,
        scene.logical_width,
        scene.logical_height,
        32,      # cell size
        50.0_f32 # character radius
      )

      # Test with large character that won't fit
      center = RL::Vector2.new(x: 250, y: 250)
      size = RL::Vector2.new(x: 100, y: 100) # Too big for the area
      scale = 1.0_f32

      scene.is_area_walkable?(center, size, scale).should be_false
    end

    it "considers character scale in area checks" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("area", true)
      region.vertices = [
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 400, y: 200),
        RL::Vector2.new(x: 400, y: 400),
        RL::Vector2.new(x: 200, y: 400),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      center = RL::Vector2.new(x: 300, y: 300)
      size = RL::Vector2.new(x: 50, y: 50)

      # Should fit with scale 1.0 (50x50 effective size)
      scene.is_area_walkable?(center, size, 1.0_f32).should be_true

      # Should fit with scale 3.0 (150x150 effective size in 200x200 area)
      scene.is_area_walkable?(center, size, 3.0_f32).should be_true

      # Should NOT fit with scale 5.0 (250x250 effective size exceeds 200x200 area)
      scene.is_area_walkable?(center, size, 5.0_f32).should be_false
    end

    it "checks multiple points around character bounds" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create L-shaped walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("l_shape", true)
      region.vertices = [
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 300, y: 100),
        RL::Vector2.new(x: 300, y: 200),
        RL::Vector2.new(x: 200, y: 200),
        RL::Vector2.new(x: 200, y: 300),
        RL::Vector2.new(x: 100, y: 300),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Test position where center is walkable but corners aren't
      center = RL::Vector2.new(x: 250, y: 200) # At the inner corner of L
      size = RL::Vector2.new(x: 120, y: 120)   # Large enough to extend outside
      scale = 1.0_f32

      # Should be false because not all corners are walkable
      # With center at (250,200) and size 120x120:
      # - Top-left (190,140) - not in L shape
      # - Top-right (310,140) - outside bounds
      # - Bottom-left (190,260) - in vertical part
      # - Bottom-right (310,260) - outside bounds
      scene.is_area_walkable?(center, size, scale).should be_false
    end

    it "returns true when no walkable area is defined" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # No walkable area set
      center = RL::Vector2.new(x: 500, y: 500)
      size = RL::Vector2.new(x: 100, y: 100)
      scale = 2.0_f32

      scene.is_area_walkable?(center, size, scale).should be_true
    end

    it "handles edge positions correctly" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("area", true)
      region.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 1024, y: 0),
        RL::Vector2.new(x: 1024, y: 768),
        RL::Vector2.new(x: 0, y: 768),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Test character at edge
      center = RL::Vector2.new(x: 50, y: 50) # Near top-left corner
      size = RL::Vector2.new(x: 60, y: 60)
      scale = 1.0_f32

      # Half the character would be outside at (20, 20)
      scene.is_area_walkable?(center, size, scale).should be_true

      # But not if too close to edge
      center = RL::Vector2.new(x: 25, y: 25)                       # Would put corner at negative coords
      scene.is_area_walkable?(center, size, scale).should be_false # Corner at (-5,-5) is outside
    end

    it "handles non-walkable regions correctly" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      main_region = PointClickEngine::Scenes::PolygonRegion.new("main_area", true)
      main_region.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 1024, y: 0),
        RL::Vector2.new(x: 1024, y: 768),
        RL::Vector2.new(x: 0, y: 768),
      ]

      obstacle_region = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle_region.vertices = [
        RL::Vector2.new(x: 400, y: 300),
        RL::Vector2.new(x: 600, y: 300),
        RL::Vector2.new(x: 600, y: 500),
        RL::Vector2.new(x: 400, y: 500),
      ]

      walkable_area.regions = [main_region, obstacle_region]
      scene.walkable_area = walkable_area

      # Create navigation grid for proper area checking
      scene.navigation_grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene,
        scene.logical_width,
        scene.logical_height,
        32,      # cell size
        25.0_f32 # character radius (half of size 50)
      )

      # Test position in walkable area
      center = RL::Vector2.new(x: 200, y: 200)
      size = RL::Vector2.new(x: 50, y: 50)
      scale = 1.0_f32
      scene.is_area_walkable?(center, size, scale).should be_true

      # Test position in obstacle
      center = RL::Vector2.new(x: 500, y: 400)
      scene.is_area_walkable?(center, size, scale).should be_false

      # Test position where character would overlap obstacle
      center = RL::Vector2.new(x: 375, y: 400) # Close to obstacle edge
      scene.is_area_walkable?(center, size, scale).should be_false
    end
  end

  describe "navigation setup with character size" do
    it "requires background texture for navigation setup" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Without background, navigation won't be set up
      character_radius = 42.0_f32
      scene.setup_navigation(character_radius)

      # Should not create grid without background
      scene.navigation_grid.should be_nil

      # Navigation requires background texture in the actual implementation
      # This test documents that requirement
    end
  end
end
