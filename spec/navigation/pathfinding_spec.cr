require "../spec_helper"

describe PointClickEngine::Navigation::Pathfinding do
  describe PointClickEngine::Navigation::Pathfinding::NavigationGrid do
    it "initializes with correct dimensions" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)
      grid.width.should eq(10)
      grid.height.should eq(10)
      grid.cell_size.should eq(32)
    end

    it "marks cells as walkable/non-walkable" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10)

      grid.is_walkable?(5, 5).should be_true
      grid.set_walkable(5, 5, false)
      grid.is_walkable?(5, 5).should be_false
    end

    it "handles out-of-bounds checks" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10)

      grid.is_walkable?(-1, 5).should be_false
      grid.is_walkable?(5, -1).should be_false
      grid.is_walkable?(10, 5).should be_false
      grid.is_walkable?(5, 10).should be_false
    end

    it "converts between world and grid coordinates" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # World to grid
      grid_pos = grid.world_to_grid(64.0f32, 96.0f32)
      grid_pos.should eq({2, 3})

      # Grid to world (centers of cells)
      world_pos = grid.grid_to_world(2, 3)
      world_pos.should eq({80.0f32, 112.0f32})
    end

    it "marks rectangles as walkable/non-walkable" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      grid.set_rect_walkable(64, 64, 64, 64, false)

      # Check affected cells
      grid.is_walkable?(2, 2).should be_false
      grid.is_walkable?(3, 3).should be_false
      grid.is_walkable?(4, 4).should be_false

      # Check unaffected cells
      grid.is_walkable?(1, 1).should be_true
      grid.is_walkable?(5, 5).should be_true
    end
  end

  describe PointClickEngine::Navigation::Pathfinding::Node do
    it "calculates f_cost correctly" do
      node = PointClickEngine::Navigation::Pathfinding::Node.new(5, 5, 10.0f32, 5.0f32)
      node.f_cost.should eq(15.0f32)
    end

    it "compares nodes by position" do
      node1 = PointClickEngine::Navigation::Pathfinding::Node.new(5, 5)
      node2 = PointClickEngine::Navigation::Pathfinding::Node.new(5, 5)
      node3 = PointClickEngine::Navigation::Pathfinding::Node.new(6, 5)

      (node1 == node2).should be_true
      (node1 == node3).should be_false
    end
  end

  describe "pathfinding" do
    it "finds a simple path in empty grid" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)
      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      path = pathfinder.find_path(16.0f32, 16.0f32, 144.0f32, 144.0f32)
      path.should_not be_nil
      path.not_nil!.size.should be > 0

      # Check start and end points
      start_point = path.not_nil!.first
      end_point = path.not_nil!.last

      # Allow for cell center positioning
      (start_point.x - 16.0f32).abs.should be < 32.0f32
      (start_point.y - 16.0f32).abs.should be < 32.0f32
      (end_point.x - 144.0f32).abs.should be < 32.0f32
      (end_point.y - 144.0f32).abs.should be < 32.0f32
    end

    it "returns nil when no path exists" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # Create a wall
      (0...10).each do |x|
        grid.set_walkable(x, 5, false)
      end

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)
      path = pathfinder.find_path(16.0f32, 16.0f32, 16.0f32, 240.0f32)
      path.should be_nil
    end

    it "finds path around obstacles" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # Create an obstacle
      grid.set_rect_walkable(64, 64, 64, 64, false)

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)
      path = pathfinder.find_path(16.0f32, 16.0f32, 240.0f32, 240.0f32)

      path.should_not be_nil

      # Path should go around the obstacle
      path.not_nil!.each do |point|
        grid_pos = grid.world_to_grid(point.x, point.y)
        grid.is_walkable?(grid_pos[0], grid_pos[1]).should be_true
      end
    end

    it "respects diagonal movement setting" do
      grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(10, 10, 32)

      # Test with diagonal movement
      pathfinder_diag = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: true)
      path_diag = pathfinder_diag.find_path(16.0f32, 16.0f32, 144.0f32, 144.0f32)

      # Test without diagonal movement
      pathfinder_no_diag = PointClickEngine::Navigation::Pathfinding.new(grid, allow_diagonal: false)
      path_no_diag = pathfinder_no_diag.find_path(16.0f32, 16.0f32, 144.0f32, 144.0f32)

      path_diag.should_not be_nil
      path_no_diag.should_not be_nil

      # Path without diagonal movement should generally be longer
      path_no_diag.not_nil!.size.should be >= path_diag.not_nil!.size
    end
  end
end
