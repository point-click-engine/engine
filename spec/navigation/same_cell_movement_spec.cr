require "../spec_helper"
require "../../src/navigation/pathfinding"

describe PointClickEngine::Navigation::Pathfinding do
  describe "same grid cell movement" do
    it "returns proper path when moving within same grid cell" do
      # Create a small navigation grid
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 16)

      # Make all cells walkable
      10.times do |y|
        10.times do |x|
          grid.set_walkable(x, y, true)
        end
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Test movement within same cell (both positions map to same grid cell)
      start_x = 20.0_f32 # Grid cell (1, 1)
      start_y = 20.0_f32
      end_x = 25.0_f32 # Still grid cell (1, 1) since cell size is 16
      end_y = 25.0_f32

      path = pathfinder.find_path(start_x, start_y, end_x, end_y)

      path.should_not be_nil
      path.not_nil!.size.should eq(2) # Should have start and end points

      # Verify path points
      path.not_nil![0].x.should eq(start_x)
      path.not_nil![0].y.should eq(start_y)
      path.not_nil![1].x.should eq(end_x)
      path.not_nil![1].y.should eq(end_y)
    end

    it "returns single point when distance is negligible" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 16)

      # Make all cells walkable
      10.times do |y|
        10.times do |x|
          grid.set_walkable(x, y, true)
        end
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Test movement with tiny distance
      start_x = 20.0_f32
      start_y = 20.0_f32
      end_x = 20.5_f32 # Only 0.5 pixels away
      end_y = 20.5_f32

      path = pathfinder.find_path(start_x, start_y, end_x, end_y)

      path.should_not be_nil
      path.not_nil!.size.should eq(1) # Should only have end point
      path.not_nil![0].x.should eq(end_x)
      path.not_nil![0].y.should eq(end_y)
    end

    it "finds proper path when moving between different grid cells" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 16)

      # Make all cells walkable
      10.times do |y|
        10.times do |x|
          grid.set_walkable(x, y, true)
        end
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Test movement between different cells
      start_x = 20.0_f32 # Grid cell (1, 1)
      start_y = 20.0_f32
      end_x = 50.0_f32 # Grid cell (3, 3)
      end_y = 50.0_f32

      path = pathfinder.find_path(start_x, start_y, end_x, end_y)

      path.should_not be_nil
      path.not_nil!.size.should be > 2 # Should have multiple waypoints

      # Verify start and end
      path.not_nil!.first.x.should be_close(start_x, 8.0) # Within half cell
      path.not_nil!.first.y.should be_close(start_y, 8.0)
      path.not_nil!.last.x.should be_close(end_x, 8.0)
      path.not_nil!.last.y.should be_close(end_y, 8.0)
    end
  end
end
