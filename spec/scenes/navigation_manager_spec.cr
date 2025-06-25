require "../spec_helper"
require "../../src/scenes/navigation_manager"

describe PointClickEngine::Scenes::NavigationManager do
  let(manager) { PointClickEngine::Scenes::NavigationManager.new(800, 600) }

  describe "initialization" do
    it "initializes with scene dimensions" do
      manager.scene_width.should eq(800)
      manager.scene_height.should eq(600)
      manager.grid_cell_size.should eq(10) # default
      manager.initialized?.should be_false
    end

    it "allows custom grid cell size" do
      custom_manager = PointClickEngine::Scenes::NavigationManager.new(800, 600)
      custom_manager.grid_cell_size = 20
      custom_manager.grid_cell_size.should eq(20)
    end
  end

  describe "navigation setup" do
    it "sets up navigation grid without walkable area" do
      manager.setup_navigation

      manager.initialized?.should be_true
      manager.navigation_grid.should_not be_nil
      manager.pathfinder.should_not be_nil
    end

    it "creates grid with correct dimensions" do
      manager.setup_navigation

      if nav_grid = manager.navigation_grid
        expected_width = (800 / 10).ceil.to_i  # 80 cells
        expected_height = (600 / 10).ceil.to_i # 60 cells

        nav_grid.width.should eq(expected_width)
        nav_grid.height.should eq(expected_height)
      end
    end

    it "marks all cells as walkable when no walkable area provided" do
      manager.setup_navigation

      # All positions should be navigable
      manager.is_navigable?(100, 100).should be_true
      manager.is_navigable?(400, 300).should be_true
      manager.is_navigable?(700, 500).should be_true
    end

    it "respects walkable area constraints" do
      # Create a mock walkable area that only allows center region
      walkable_area = double("WalkableArea")
      walkable_area.stub(:contains_point?) do |point|
        point.x >= 200 && point.x <= 600 && point.y >= 150 && point.y <= 450
      end

      manager.setup_navigation(walkable_area)

      # Center should be navigable
      manager.is_navigable?(400, 300).should be_true

      # Edges should not be navigable
      manager.is_navigable?(50, 50).should be_false
      manager.is_navigable?(750, 550).should be_false
    end
  end

  describe "pathfinding" do
    before_each do
      manager.setup_navigation
    end

    it "finds path between valid points" do
      path = manager.find_path(100, 100, 700, 500)

      path.should_not be_nil
      if path
        path.should_not be_empty
        path.first.x.should be_close(100, 20) # Within grid cell tolerance
        path.first.y.should be_close(100, 20)
        path.last.x.should be_close(700, 20)
        path.last.y.should be_close(500, 20)
      end
    end

    it "returns nil when no path exists" do
      # Create walkable area with blocked middle section
      walkable_area = double("WalkableArea")
      walkable_area.stub(:contains_point?) do |point|
        # Block middle vertical strip
        !(point.x >= 350 && point.x <= 450)
      end

      manager.setup_navigation(walkable_area)

      # Try to path from left side to right side (should be blocked)
      path = manager.find_path(100, 300, 700, 300)
      path.should be_nil
    end

    it "handles out-of-bounds coordinates" do
      # Should clamp coordinates to grid bounds
      path = manager.find_path(-100, -100, 1000, 1000)
      path.should_not be_nil # Should find path between clamped points
    end

    it "converts grid coordinates to world coordinates correctly" do
      path = manager.find_path(0, 0, 100, 100)

      if path
        # Path waypoints should be in world coordinates
        path.each do |waypoint|
          waypoint.x.should be >= 0
          waypoint.y.should be >= 0
          waypoint.x.should be <= 800
          waypoint.y.should be <= 600
        end
      end
    end
  end

  describe "navigation queries" do
    before_each do
      manager.setup_navigation
    end

    it "checks if positions are navigable" do
      # Most positions should be navigable with default setup
      manager.is_navigable?(100, 100).should be_true
      manager.is_navigable?(400, 300).should be_true
      manager.is_navigable?(700, 500).should be_true
    end

    it "handles out-of-bounds position queries" do
      manager.is_navigable?(-50, 100).should be_false
      manager.is_navigable?(1000, 100).should be_false
      manager.is_navigable?(400, -50).should be_false
      manager.is_navigable?(400, 1000).should be_false
    end

    it "provides navigation statistics" do
      stats = manager.get_navigation_stats

      stats["total_cells"].should be > 0
      stats["walkable_cells"].should be > 0
      stats["blocked_cells"].should be >= 0
      stats["grid_width"].should eq(80)  # 800/10
      stats["grid_height"].should eq(60) # 600/10
      stats["cell_size"].should eq(10)
    end
  end

  describe "navigation updates" do
    before_each do
      manager.setup_navigation
    end

    it "updates navigation with new walkable area" do
      # Initially all walkable
      manager.is_navigable?(100, 100).should be_true

      # Create restrictive walkable area
      restricted_area = double("WalkableArea")
      restricted_area.stub(:contains_point?) { |point| point.x >= 400 && point.y >= 300 }

      manager.update_navigation(restricted_area)

      # Previously walkable area should now be blocked
      manager.is_navigable?(100, 100).should be_false
      # New restricted area should be walkable
      manager.is_navigable?(500, 400).should be_true
    end

    it "clears navigation data" do
      manager.initialized?.should be_true

      manager.clear_navigation

      manager.initialized?.should be_false
      manager.navigation_grid.should be_nil
      manager.pathfinder.should be_nil
    end
  end

  describe "debug visualization" do
    before_each do
      manager.setup_navigation
    end

    it "draws navigation debug when debug mode enabled" do
      # Enable debug mode
      PointClickEngine::Core::Engine.debug_mode = true

      camera_offset = RL::Vector2.new(0, 0)

      # Should not crash when drawing debug info
      manager.draw_navigation_debug(camera_offset)
    end

    it "skips debug drawing when debug mode disabled" do
      # Disable debug mode
      PointClickEngine::Core::Engine.debug_mode = false

      camera_offset = RL::Vector2.new(0, 0)

      # Should not crash and should be no-op
      manager.draw_navigation_debug(camera_offset)
    end

    it "handles camera offset in debug rendering" do
      PointClickEngine::Core::Engine.debug_mode = true

      camera_offset = RL::Vector2.new(100, 50)

      # Should not crash with camera offset
      manager.draw_navigation_debug(camera_offset)
    end
  end

  describe "data export/import" do
    before_each do
      manager.setup_navigation
    end

    it "exports navigation data" do
      data = manager.export_navigation_data

      data.should_not be_empty
      # Should be valid JSON
      parsed = JSON.parse(data)
      parsed["width"].should be > 0
      parsed["height"].should be > 0
      parsed["cell_size"].should eq(10)
    end

    it "handles export with no navigation data" do
      manager.clear_navigation

      data = manager.export_navigation_data
      data.should eq("")
    end
  end

  describe "performance optimization" do
    it "handles large grid sizes efficiently" do
      large_manager = PointClickEngine::Scenes::NavigationManager.new(2000, 1500)
      large_manager.grid_cell_size = 5 # Smaller cells = more grid cells

      start_time = Time.monotonic
      large_manager.setup_navigation
      setup_time = Time.monotonic - start_time

      # Setup should complete reasonably quickly even for large grids
      setup_time.should be < 1.second

      large_manager.initialized?.should be_true
    end

    it "optimizes navigation efficiently" do
      manager.setup_navigation

      start_time = Time.monotonic
      manager.optimize_navigation
      optimize_time = Time.monotonic - start_time

      # Optimization should be fast
      optimize_time.should be < 100.milliseconds
    end
  end

  describe "edge cases" do
    it "handles zero-sized scenes gracefully" do
      zero_manager = PointClickEngine::Scenes::NavigationManager.new(0, 0)

      # Should not crash
      zero_manager.setup_navigation
      zero_manager.initialized?.should be_true
    end

    it "handles very small grid cell sizes" do
      manager.grid_cell_size = 1

      # Should not crash but may be slow
      manager.setup_navigation
      manager.initialized?.should be_true
    end

    it "handles pathfinding with same start and end points" do
      manager.setup_navigation

      path = manager.find_path(400, 300, 400, 300)

      # Should return trivial path or handle gracefully
      path.should_not be_nil
      if path
        path.size.should be >= 1
      end
    end
  end
end
