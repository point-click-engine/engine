require "../spec_helper"
require "../../src/navigation/pathfinding"
require "../../src/scenes/scene"

describe PointClickEngine::Navigation::Pathfinding::NavigationGrid do
  describe "grid generation with character radius" do
    it "creates appropriate walkable cells with character radius" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create walkable area similar to laboratory
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("main_floor", true)
      region.vertices = [
        RL::Vector2.new(50, 300),
        RL::Vector2.new(950, 300),
        RL::Vector2.new(950, 700),
        RL::Vector2.new(50, 700),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Create navigation grid with character radius
      character_radius = 42.0_f32 # Typical for 1.5 scale character
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
        scene,
        scene.logical_width,
        scene.logical_height,
        16, # cell size
        character_radius
      )

      # Check that cells near the spawn position are walkable
      # Player spawn is at (320, 520)
      spawn_grid_x, spawn_grid_y = grid.world_to_grid(320.0_f32, 520.0_f32)
      grid.is_walkable?(spawn_grid_x, spawn_grid_y).should be_true

      # Check nearby cells are also walkable
      grid.is_walkable?(spawn_grid_x - 1, spawn_grid_y).should be_true
      grid.is_walkable?(spawn_grid_x + 1, spawn_grid_y).should be_true
      grid.is_walkable?(spawn_grid_x, spawn_grid_y - 1).should be_true
      grid.is_walkable?(spawn_grid_x, spawn_grid_y + 1).should be_true

      # Check that we have a reasonable number of walkable cells
      walkable_count = 0
      (0...grid.height).each do |y|
        (0...grid.width).each do |x|
          walkable_count += 1 if grid.is_walkable?(x, y)
        end
      end

      # Should have many walkable cells in the main floor area
      total_cells = grid.width * grid.height
      walkable_percentage = (walkable_count * 100.0 / total_cells)
      walkable_percentage.should be > 20.0 # At least 20% should be walkable
    end

    it "handles edge cases near walkable area boundaries" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 1024
      scene.logical_height = 768

      # Create a smaller walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("small_area", true)
      region.vertices = [
        RL::Vector2.new(200, 200),
        RL::Vector2.new(400, 200),
        RL::Vector2.new(400, 400),
        RL::Vector2.new(200, 400),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Create grid with typical character radius
      character_radius = 42.0_f32
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
        scene,
        scene.logical_width,
        scene.logical_height,
        16,
        character_radius
      )

      # Center of area should definitely be walkable
      center_x, center_y = grid.world_to_grid(300.0_f32, 300.0_f32)
      grid.is_walkable?(center_x, center_y).should be_true

      # Just outside should not be walkable
      outside_x, outside_y = grid.world_to_grid(150.0_f32, 150.0_f32)
      grid.is_walkable?(outside_x, outside_y).should be_false
    end

    it "uses lenient approach near boundaries" do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 500
      scene.logical_height = 500

      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new("corridor", true)
      # Narrow corridor
      region.vertices = [
        RL::Vector2.new(200, 100),
        RL::Vector2.new(300, 100),
        RL::Vector2.new(300, 400),
        RL::Vector2.new(200, 400),
      ]
      walkable_area.regions = [region]
      scene.walkable_area = walkable_area

      # Create grid with character radius that would be too strict
      character_radius = 30.0_f32
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
        scene,
        scene.logical_width,
        scene.logical_height,
        16,
        character_radius
      )

      # Center of corridor should be walkable even with large radius
      center_x, center_y = grid.world_to_grid(250.0_f32, 250.0_f32)
      grid.is_walkable?(center_x, center_y).should be_true

      # Count walkable cells in corridor
      corridor_walkable = 0
      (6..25).each do |y|    # Y range for corridor
        (12..18).each do |x| # X range for corridor
          corridor_walkable += 1 if grid.is_walkable?(x, y)
        end
      end

      # Should have some walkable cells despite narrow corridor
      corridor_walkable.should be > 0
    end
  end
end

describe PointClickEngine::Navigation::Pathfinding do
  describe "pathfinding from non-walkable start position" do
    it "allows pathfinding when start position is not walkable" do
      # Create a simple navigation grid
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 10)

      # Mark most cells as walkable
      (0...10).each do |y|
        (0...10).each do |x|
          grid.set_walkable(x, y, true)
        end
      end

      # Mark start position as non-walkable (character is already there)
      grid.set_walkable(1, 1, false)

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Should still find path from non-walkable start to walkable end
      path = pathfinder.find_path(15.0_f32, 15.0_f32, 85.0_f32, 85.0_f32) # Grid coords (1,1) to (8,8)

      path.should_not be_nil
      path.not_nil!.size.should be > 0
    end

    it "returns nil when end position is not walkable" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 10)

      # Mark most cells as walkable
      (0...10).each do |y|
        (0...10).each do |x|
          grid.set_walkable(x, y, true)
        end
      end

      # Mark end position as non-walkable
      grid.set_walkable(8, 8, false)

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Should return nil when end is not walkable
      path = pathfinder.find_path(15.0_f32, 15.0_f32, 85.0_f32, 85.0_f32)

      path.should be_nil
    end

    it "handles character already in non-walkable position gracefully" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)

      # Create a walkable area with an obstacle
      (0...20).each do |y|
        (0...20).each do |x|
          # Create obstacle in middle
          if x >= 8 && x <= 12 && y >= 8 && y <= 12
            grid.set_walkable(x, y, false)
          else
            grid.set_walkable(x, y, true)
          end
        end
      end

      # Character somehow ended up inside obstacle at (10, 10)
      grid.set_walkable(10, 10, false)

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Should attempt to find path out of obstacle
      # From (10*16 + 8, 10*16 + 8) = (168, 168) to outside area
      path = pathfinder.find_path(168.0_f32, 168.0_f32, 50.0_f32, 50.0_f32)

      # Path might be nil if completely blocked, but shouldn't crash
      # This tests the graceful handling
    end
  end

  describe "micro-path prevention" do
    it "handles very short paths efficiently" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 10)

      # All walkable
      (0...10).each do |y|
        (0...10).each do |x|
          grid.set_walkable(x, y, true)
        end
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Very close start and end positions
      path = pathfinder.find_path(50.0_f32, 50.0_f32, 52.0_f32, 50.0_f32) # 2 pixels apart

      if path
        # Should generate minimal path
        path.size.should be <= 2
      end
    end

    it "avoids unnecessary waypoints for straight paths" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 10)

      # All walkable
      (0...20).each do |y|
        (0...20).each do |x|
          grid.set_walkable(x, y, true)
        end
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Straight horizontal path
      path = pathfinder.find_path(50.0_f32, 100.0_f32, 150.0_f32, 100.0_f32)

      if path
        # Should have minimal waypoints for straight line
        # Start, maybe one middle, and end
        path.size.should be <= 3
      end
    end
  end

  describe "navigation grid with character radius" do
    it "marks cells as non-walkable based on character radius" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.logical_width = 200
      scene.logical_height = 200

      # Create walkable area with obstacle
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      main_region = PointClickEngine::Scenes::PolygonRegion.new("main", true)
      main_region.vertices = [
        RL::Vector2.new(0, 0),
        RL::Vector2.new(200, 0),
        RL::Vector2.new(200, 200),
        RL::Vector2.new(0, 200),
      ]

      obstacle_region = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle_region.vertices = [
        RL::Vector2.new(90, 90),
        RL::Vector2.new(110, 90),
        RL::Vector2.new(110, 110),
        RL::Vector2.new(90, 110),
      ]

      walkable_area.regions = [main_region, obstacle_region]
      scene.walkable_area = walkable_area

      # Create grid with character radius
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
        scene,
        200, # width
        200, # height
        10,  # cell size
        20.0 # character radius
      )

      # Cells near obstacle should be non-walkable due to radius
      # Cell at (10, 10) is at world (105, 105) - center of obstacle
      grid.is_walkable?(10, 10).should be_false

      # Cells far from obstacle should be walkable
      grid.is_walkable?(2, 2).should be_true   # Far corner
      grid.is_walkable?(17, 17).should be_true # Other far corner
    end

    it "creates appropriate buffer around non-walkable areas" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.logical_width = 300
      scene.logical_height = 300

      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      main_region = PointClickEngine::Scenes::PolygonRegion.new("main", true)
      main_region.vertices = [
        RL::Vector2.new(0, 0),
        RL::Vector2.new(300, 0),
        RL::Vector2.new(300, 300),
        RL::Vector2.new(0, 300),
      ]

      wall_region = PointClickEngine::Scenes::PolygonRegion.new("wall", false)
      wall_region.vertices = [
        RL::Vector2.new(140, 0),
        RL::Vector2.new(160, 0),
        RL::Vector2.new(160, 300),
        RL::Vector2.new(140, 300),
      ]

      walkable_area.regions = [main_region, wall_region]
      scene.walkable_area = walkable_area

      # Test with different character radii
      small_radius = 10.0_f32
      large_radius = 30.0_f32

      small_grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
        scene, 300, 300, 10, small_radius
      )

      large_grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
        scene, 300, 300, 10, large_radius
      )

      # Count walkable cells
      small_walkable = 0
      large_walkable = 0

      (0...30).each do |y|
        (0...30).each do |x|
          small_walkable += 1 if small_grid.is_walkable?(x, y)
          large_walkable += 1 if large_grid.is_walkable?(x, y)
        end
      end

      # Larger radius should result in fewer walkable cells
      (large_walkable < small_walkable).should be_true
    end
  end

  describe "path recalculation" do
    it "supports dynamic path recalculation" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 10)

      # Initially all walkable
      (0...20).each do |y|
        (0...20).each do |x|
          grid.set_walkable(x, y, true)
        end
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Find initial path
      path1 = pathfinder.find_path(50.0_f32, 50.0_f32, 150.0_f32, 150.0_f32)
      path1.should_not be_nil

      # Block part of the path
      (8..12).each do |x|
        grid.set_walkable(x, 10, false)
      end

      # Recalculate path
      path2 = pathfinder.find_path(50.0_f32, 50.0_f32, 150.0_f32, 150.0_f32)
      path2.should_not be_nil

      # New path should be different (likely longer)
      if path1 && path2
        (path2.size >= path1.size).should be_true
      end
    end
  end
end
