require "../spec_helper"

describe PointClickEngine::Navigation::NavigationGrid do
  describe "#initialize" do
    it "creates a grid with specified dimensions" do
      grid = PointClickEngine::Navigation::NavigationGrid.new(10, 15, 32)

      grid.width.should eq(10)
      grid.height.should eq(15)
      grid.cell_size.should eq(32)
    end

    it "initializes all cells as walkable by default" do
      grid = PointClickEngine::Navigation::NavigationGrid.new(5, 5, 16)

      (0...5).each do |y|
        (0...5).each do |x|
          grid.is_walkable?(x, y).should be_true
        end
      end
    end
  end

  describe "#world_to_grid" do
    it "converts world coordinates to grid coordinates" do
      grid = PointClickEngine::Navigation::NavigationGrid.new(10, 10, 20)

      # Test various points
      grid_x, grid_y = grid.world_to_grid(0, 0)
      grid_x.should eq(0)
      grid_y.should eq(0)

      grid_x, grid_y = grid.world_to_grid(25, 45)
      grid_x.should eq(1) # 25 / 20 = 1
      grid_y.should eq(2) # 45 / 20 = 2

      grid_x, grid_y = grid.world_to_grid(199, 199)
      grid_x.should eq(9) # 199 / 20 = 9
      grid_y.should eq(9) # 199 / 20 = 9
    end

    it "handles negative coordinates" do
      grid = PointClickEngine::Navigation::NavigationGrid.new(10, 10, 20)

      grid_x, grid_y = grid.world_to_grid(-10, -10)
      # Crystal integer division truncates towards zero, so -10/20 = 0
      grid_x.should eq(0)
      grid_y.should eq(0)
    end
  end

  describe "#grid_to_world" do
    it "converts grid coordinates to world center coordinates" do
      grid = PointClickEngine::Navigation::NavigationGrid.new(10, 10, 20)

      # Grid cells are centered
      world_x, world_y = grid.grid_to_world(0, 0)
      world_x.should eq(10.0) # 0 * 20 + 20/2
      world_y.should eq(10.0)

      world_x, world_y = grid.grid_to_world(5, 3)
      world_x.should eq(110.0) # 5 * 20 + 10
      world_y.should eq(70.0)  # 3 * 20 + 10
    end
  end

  describe "#set_walkable and #is_walkable?" do
    it "allows setting and checking walkability of cells" do
      grid = PointClickEngine::Navigation::NavigationGrid.new(5, 5, 16)

      # Set some cells as non-walkable
      grid.set_walkable(2, 2, false)
      grid.set_walkable(3, 3, false)

      grid.is_walkable?(2, 2).should be_false
      grid.is_walkable?(3, 3).should be_false
      grid.is_walkable?(1, 1).should be_true
      grid.is_walkable?(4, 4).should be_true
    end

    it "returns false for out-of-bounds coordinates" do
      grid = PointClickEngine::Navigation::NavigationGrid.new(5, 5, 16)

      grid.is_walkable?(-1, 0).should be_false
      grid.is_walkable?(0, -1).should be_false
      grid.is_walkable?(5, 0).should be_false
      grid.is_walkable?(0, 5).should be_false
    end
  end

  describe ".from_scene" do
    it "creates a grid based on scene dimensions" do
      scene = PointClickEngine::Scenes::Scene.new("test")

      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 640, 480, 32
      )

      # Grid dimensions should cover the entire area
      grid.width.should eq(21)  # (640 / 32) + 1
      grid.height.should eq(16) # (480 / 32) + 1
      grid.cell_size.should eq(32)
    end

    it "marks cells based on walkable areas" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Create a simple rectangular walkable floor
      # Make it larger to account for character radius checking
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 50, y: 50),
        RL::Vector2.new(x: 350, y: 50),
        RL::Vector2.new(x: 350, y: 250),
        RL::Vector2.new(x: 50, y: 250),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 400, 300, 50, 32.0_f32
      )

      # Check that cells inside the floor are walkable
      grid_x, grid_y = grid.world_to_grid(200, 150) # Center of floor
      grid.is_walkable?(grid_x, grid_y).should be_true

      # Check that cells outside are not walkable
      grid_x, grid_y = grid.world_to_grid(25, 25) # Outside floor
      grid.is_walkable?(grid_x, grid_y).should be_false
    end

    it "accounts for character radius when marking cells" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Create a large rectangular area to test radius properly
      area = PointClickEngine::Scenes::PolygonRegion.new("area", true)
      area.vertices = [
        RL::Vector2.new(x: 50, y: 50),
        RL::Vector2.new(x: 350, y: 50),
        RL::Vector2.new(x: 350, y: 250),
        RL::Vector2.new(x: 50, y: 250),
      ]

      walkable_area.regions << area
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Create grid with large character radius
      grid_large = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 400, 300, 25, 45.0_f32
      )

      # With large radius, cells near edges should not be walkable
      grid_x_edge, grid_y_edge = grid_large.world_to_grid(62, 150) # Near left edge
      grid_large.is_walkable?(grid_x_edge, grid_y_edge).should be_false

      # But center cells should be walkable
      grid_x_center, grid_y_center = grid_large.world_to_grid(200, 150) # Center
      grid_large.is_walkable?(grid_x_center, grid_y_center).should be_true

      # Now test with small character radius
      grid_small = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 400, 300, 25, 10.0_f32
      )

      # With small radius, more cells near edges should be walkable
      grid_x2, grid_y2 = grid_small.world_to_grid(62, 150) # Same edge position
      grid_small.is_walkable?(grid_x2, grid_y2).should be_true
    end

    it "marks hotspots that block movement as non-walkable" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Create floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 400, y: 0),
        RL::Vector2.new(x: 400, y: 300),
        RL::Vector2.new(x: 0, y: 300),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Add blocking hotspot
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "obstacle",
        RL::Vector2.new(x: 200, y: 150), # Center
        RL::Vector2.new(x: 100, y: 100)  # Size
      )
      hotspot.blocks_movement = true
      scene.hotspots << hotspot

      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 400, 300, 50
      )

      # Center of hotspot should be non-walkable
      grid_x, grid_y = grid.world_to_grid(200, 150)
      grid.is_walkable?(grid_x, grid_y).should be_false

      # Outside hotspot should be walkable
      grid_x, grid_y = grid.world_to_grid(50, 50)
      grid.is_walkable?(grid_x, grid_y).should be_true
    end
  end

  describe "coordinate independence" do
    it "works correctly regardless of texture size" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.logical_width = 1024
      scene.logical_height = 768

      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Define walkable area in logical coordinates
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 100, y: 350),
        RL::Vector2.new(x: 900, y: 350),
        RL::Vector2.new(x: 900, y: 700),
        RL::Vector2.new(x: 100, y: 700),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Create grid using logical dimensions, not texture dimensions
      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, scene.logical_width, scene.logical_height, 32
      )

      # Verify cells are marked correctly based on logical coordinates
      grid_x, grid_y = grid.world_to_grid(500, 500) # Center of floor
      grid.is_walkable?(grid_x, grid_y).should be_true

      grid_x, grid_y = grid.world_to_grid(500, 300) # Above floor
      grid.is_walkable?(grid_x, grid_y).should be_false
    end
  end
end
