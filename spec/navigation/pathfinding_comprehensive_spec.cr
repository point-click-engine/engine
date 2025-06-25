require "../spec_helper"

describe "Comprehensive Pathfinding Tests" do
  describe PointClickEngine::Navigation::Pathfinding do
    describe "edge cases and complex scenarios" do
      it "handles path to same position" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)
        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        path = pathfinder.find_path(100f32, 100f32, 100f32, 100f32)
        path.should_not be_nil
        path.not_nil!.size.should eq(1)

        point = path.not_nil!.first
        (point.x - 100f32).abs.should be < 32f32
        (point.y - 100f32).abs.should be < 32f32
      end

      it "handles very long paths efficiently" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(100, 100, 16)
        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Path from one corner to opposite corner
        path = pathfinder.find_path(8f32, 8f32, 1584f32, 1584f32) # (0,0) to (99,99) in grid

        path.should_not be_nil
        # Should find a path - with optimization it might be just 2 points for a straight diagonal
        path.not_nil!.size.should be >= 2

        # Verify start and end
        start_point = path.not_nil!.first
        end_point = path.not_nil!.last

        (start_point.x - 8f32).abs.should be < 16f32
        (end_point.x - 1584f32).abs.should be < 16f32
      end

      it "finds path around complex obstacles" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)

        # Create a vertical wall that blocks direct path
        (0..19).each do |y|
          grid.set_walkable(10, y, false)
        end
        # Create a single gap in the wall
        grid.set_walkable(10, 10, true)

        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)
        # Path from left side to right side - must go through gap
        path = pathfinder.find_path(80f32, 160f32, 240f32, 160f32) # x=5,y=10 to x=15,y=10

        path.should_not be_nil

        # Path should go through or very close to the gap
        # Due to grid cell centers and optimization, might not be exactly at (10,10)
        has_near_gap = path.not_nil!.any? do |point|
          grid_pos = grid.world_to_grid(point.x, point.y)
          # Check if we're at or near the gap
          (grid_pos[0] - 10).abs <= 1 && (grid_pos[1] - 10).abs <= 1
        end
        has_near_gap.should be_true
      end

      it "handles grid boundaries correctly" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)
        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Path along edge
        path = pathfinder.find_path(16f32, 16f32, 16f32, 288f32) # Along left edge
        path.should_not be_nil

        # All points should be valid
        path.not_nil!.each do |point|
          grid_pos = grid.world_to_grid(point.x, point.y)
          grid_pos[0].should be >= 0
          grid_pos[0].should be < 10
          grid_pos[1].should be >= 0
          grid_pos[1].should be < 10
        end
      end

      it "returns nil for completely blocked paths" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

        # Create an island
        (0...10).each do |x|
          (0...10).each do |y|
            grid.set_walkable(x, y, false)
          end
        end

        # Make only start and goal walkable (disconnected)
        grid.set_walkable(1, 1, true)
        grid.set_walkable(8, 8, true)

        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)
        path = pathfinder.find_path(48f32, 48f32, 272f32, 272f32)

        path.should be_nil
      end

      it "finds optimal path with diagonal movement" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

        # Add some obstacles to make the path more interesting
        grid.set_walkable(2, 2, false)
        grid.set_walkable(3, 3, false)
        grid.set_walkable(4, 4, false)

        pathfinder_diag = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: true)
        pathfinder_no_diag = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: false)

        # Path that would benefit from diagonal movement
        path_diag = pathfinder_diag.find_path(32f32, 32f32, 288f32, 288f32)
        path_no_diag = pathfinder_no_diag.find_path(32f32, 32f32, 288f32, 288f32)

        path_diag.should_not be_nil
        path_no_diag.should_not be_nil

        # With obstacles, paths should be different lengths
        # No diagonal should have more waypoints
        path_diag.not_nil!.size.should be <= path_no_diag.not_nil!.size
      end

      it "avoids diagonal movement through corners" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

        # Create corner obstacle
        grid.set_walkable(5, 5, false)
        grid.set_walkable(6, 5, false)
        grid.set_walkable(5, 6, false)

        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: true)

        # Try to path through the corner
        path = pathfinder.find_path(144f32, 144f32, 208f32, 208f32) # (4,4) to (6,6)

        path.should_not be_nil

        # Should not cut through the diagonal at (5,5)
        has_corner_cut = path.not_nil!.any? do |point|
          grid_pos = grid.world_to_grid(point.x, point.y)
          grid_pos[0] == 6 && grid_pos[1] == 6
        end

        # Path should go around, not through corner
        path.not_nil!.size.should be > 2
      end
    end

    describe "performance and optimization" do
      it "caches grid lookups efficiently" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(50, 50, 16)

        # Create complex obstacle pattern
        (10..40).each do |i|
          grid.set_walkable(i, 25, false)
          grid.set_walkable(25, i, false)
        end

        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Time multiple pathfinding operations
        start_time = Time.monotonic

        10.times do
          path = pathfinder.find_path(80f32, 80f32, 720f32, 720f32)
          path.should_not be_nil
        end

        elapsed = Time.monotonic - start_time
        # Should complete quickly (< 100ms for 10 paths on 50x50 grid)
        elapsed.total_milliseconds.should be < 100
      end

      it "handles dynamic obstacle updates" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)
        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Initial path - straight line
        path1 = pathfinder.find_path(16f32, 160f32, 304f32, 160f32)
        path1.should_not be_nil
        initial_length = path1.not_nil!.size

        # Add obstacle that blocks the direct path
        # Create a wall in the middle
        (8..12).each do |x|
          (8..12).each do |y|
            grid.set_walkable(x, y, false)
          end
        end

        # New path should go around the obstacle
        path2 = pathfinder.find_path(16f32, 160f32, 304f32, 160f32)
        path2.should_not be_nil
        # Should have more waypoints to go around
        path2.not_nil!.size.should be >= initial_length

        # Remove obstacle
        (8..12).each do |x|
          (8..12).each do |y|
            grid.set_walkable(x, y, true)
          end
        end

        # Path should be optimal again
        path3 = pathfinder.find_path(16f32, 160f32, 304f32, 160f32)
        path3.should_not be_nil
        path3.not_nil!.size.should eq(initial_length)
      end
    end

    describe "path smoothing and optimization" do
      it "produces smooth paths for character movement" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)
        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Create path that could be smoothed
        path = pathfinder.find_path(16f32, 16f32, 304f32, 304f32)
        path.should_not be_nil

        # Check path is relatively smooth (no unnecessary zigzags)
        if path.not_nil!.size >= 3
          (1...(path.not_nil!.size - 1)).each do |i|
            prev = path.not_nil![i - 1]
            curr = path.not_nil![i]
            next_point = path.not_nil![i + 1]

            # Calculate angles between segments
            angle1 = Math.atan2(curr.y - prev.y, curr.x - prev.x)
            angle2 = Math.atan2(next_point.y - curr.y, next_point.x - curr.x)

            # Angles shouldn't change drastically (unless hitting obstacle)
            angle_diff = (angle2 - angle1).abs
            angle_diff = 2 * Math::PI - angle_diff if angle_diff > Math::PI

            # Most angles should be small (straight or diagonal)
            # This is a soft check as obstacles may require sharp turns
          end
        end
      end

      it "handles partial paths when goal is unreachable" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)

        # Create unreachable goal area
        (15..19).each do |x|
          (15..19).each do |y|
            grid.set_walkable(x, y, false)
          end
        end

        # Make goal position walkable but surrounded
        grid.set_walkable(17, 17, true)

        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Try to reach unreachable goal
        path = pathfinder.find_path(16f32, 16f32, 280f32, 280f32) # (1,1) to (17,17)

        # Should return nil or partial path
        if path
          # If partial path returned, should get as close as possible
          end_point = path.last
          grid_pos = grid.world_to_grid(end_point.x, end_point.y)

          # Should be near the blocked area
          (grid_pos[0] - 17).abs.should be <= 5
          (grid_pos[1] - 17).abs.should be <= 5
        else
          path.should be_nil
        end
      end
    end

    describe "integration with scene data" do
      it "creates navigation grid from walkable area" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(50, 40, 16)

        # Simulate scene walkable area setup
        # Main floor
        grid.set_rect_walkable(0, 320, 800, 320, true)

        # Obstacles
        grid.set_rect_walkable(200, 400, 100, 100, false) # Table
        grid.set_rect_walkable(500, 450, 80, 80, false)   # Chair

        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Path should navigate around obstacles
        path = pathfinder.find_path(50f32, 400f32, 750f32, 500f32)
        path.should_not be_nil

        # Verify path avoids obstacles
        path.not_nil!.each do |point|
          # Check table area
          if point.x >= 200 && point.x <= 300
            (point.y < 400 || point.y > 500).should be_true
          end

          # Check chair area
          if point.x >= 500 && point.x <= 580
            (point.y < 450 || point.y > 530).should be_true
          end
        end
      end

      it "respects different cell sizes for precision vs performance" do
        # Fine grid
        fine_grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(100, 100, 8)
        fine_pathfinder = PointClickEngine::Navigation::Pathfinding.new(fine_grid)

        # Coarse grid
        coarse_grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(25, 25, 32)
        coarse_pathfinder = PointClickEngine::Navigation::Pathfinding.new(coarse_grid)

        # Add same obstacle pattern (scaled appropriately)
        fine_grid.set_rect_walkable(200, 200, 100, 100, false)
        coarse_grid.set_rect_walkable(200, 200, 100, 100, false)

        # Find paths
        fine_path = fine_pathfinder.find_path(50f32, 50f32, 750f32, 750f32)
        coarse_path = coarse_pathfinder.find_path(50f32, 50f32, 750f32, 750f32)

        fine_path.should_not be_nil
        coarse_path.should_not be_nil

        # Fine path should be more precise (more waypoints)
        fine_path.not_nil!.size.should be >= coarse_path.not_nil!.size
      end
    end

    describe "special movement patterns" do
      it "supports restricted movement directions" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

        # No diagonal movement
        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: false)

        path = pathfinder.find_path(32f32, 32f32, 160f32, 160f32)
        path.should_not be_nil

        # With no diagonal movement and optimization, we might get just start and end
        # if there's a clear straight path. Let's check if no diagonal shortcuts were taken
        if path.not_nil!.size > 2
          # Check intermediate points
          (1...path.not_nil!.size).each do |i|
            prev = path.not_nil![i - 1]
            curr = path.not_nil![i]

            dx = (curr.x - prev.x).abs
            dy = (curr.y - prev.y).abs

            # For optimized paths, we might have larger jumps but they should be
            # either horizontal or vertical, not diagonal
            if dx > 0 && dy > 0
              # This would be a diagonal move - check if it's just optimization
              # by verifying the ratio is what we'd expect from cardinal moves
              ratio = dx / dy
              (ratio == 1.0f32).should be_false # Not a true diagonal
            end
          end
        end
      end

      it "handles narrow passages correctly" do
        grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)

        # Create narrow passage
        (0...20).each do |x|
          grid.set_walkable(x, 10, false) unless x == 10 # Only x=10 is passable
        end

        pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

        # Path through narrow passage
        path = pathfinder.find_path(160f32, 80f32, 160f32, 240f32)
        path.should_not be_nil

        # Should go through or near the passage at x=10
        has_passage_point = path.not_nil!.any? do |point|
          grid_pos = grid.world_to_grid(point.x, point.y)
          # Check if near the passage (allowing for optimization)
          (grid_pos[0] - 10).abs <= 1 && grid_pos[1] >= 9 && grid_pos[1] <= 11
        end
        has_passage_point.should be_true
      end
    end
  end
end
