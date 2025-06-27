require "../spec_helper"

describe PointClickEngine::Navigation::NavigationGrid do
  describe ".from_scene with character radius" do
    it "marks cells as unwalkable if character won't fit" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor with narrow corridor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 400, y: 0),
        RL::Vector2.new(x: 400, y: 100), # Narrow corridor 100 pixels high
        RL::Vector2.new(x: 0, y: 100),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # No background needed - NavigationGrid.from_scene accepts explicit dimensions

      # Create grid with large character radius
      character_radius = 60.0_f32
      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 400, 200, 20, character_radius
      )

      # Check center of corridor
      grid_x, grid_y = grid.world_to_grid(200, 50)

      # Should be marked as non-walkable because character won't fit
      grid.is_walkable?(grid_x, grid_y).should be_false
    end

    it "creates proper clearance around obstacles" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 600, y: 0),
        RL::Vector2.new(x: 600, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      # Small obstacle in center
      obstacle = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle.vertices = [
        RL::Vector2.new(x: 280, y: 280),
        RL::Vector2.new(x: 320, y: 280),
        RL::Vector2.new(x: 320, y: 320),
        RL::Vector2.new(x: 280, y: 320),
      ]

      walkable_area.regions << floor
      walkable_area.regions << obstacle
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Grid with character radius
      character_radius = 30.0_f32
      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 600, 600, 20, character_radius
      )

      # Check positions around obstacle
      # Too close to obstacle (character would overlap)
      close_x, close_y = grid.world_to_grid(250, 300)
      grid.is_walkable?(close_x, close_y).should be_false

      # Far enough from obstacle
      far_x, far_y = grid.world_to_grid(200, 300)
      grid.is_walkable?(far_x, far_y).should be_true
    end

    it "allows smaller characters to fit in tighter spaces" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor with gap
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 200),
        RL::Vector2.new(x: 600, y: 200),
        RL::Vector2.new(x: 600, y: 300), # 100-pixel high corridor
        RL::Vector2.new(x: 0, y: 300),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Small character radius
      small_radius = 20.0_f32
      small_grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 600, 400, 20, small_radius
      )

      # Large character radius
      large_radius = 60.0_f32
      large_grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 600, 400, 20, large_radius
      )

      # Check center of corridor
      grid_x, grid_y = small_grid.world_to_grid(300, 250)

      # Small character can fit
      small_grid.is_walkable?(grid_x, grid_y).should be_true

      # Large character cannot fit
      large_grid.is_walkable?(grid_x, grid_y).should be_false
    end
  end
end

describe PointClickEngine::Navigation::Pathfinding do
  describe "pathfinding with character size constraints" do
    it "finds path around obstacles respecting character size" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Floor
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 800, y: 0),
        RL::Vector2.new(x: 800, y: 600),
        RL::Vector2.new(x: 0, y: 600),
      ]

      # Obstacle in middle
      obstacle = PointClickEngine::Scenes::PolygonRegion.new("obstacle", false)
      obstacle.vertices = [
        RL::Vector2.new(x: 350, y: 200),
        RL::Vector2.new(x: 450, y: 200),
        RL::Vector2.new(x: 450, y: 400),
        RL::Vector2.new(x: 350, y: 400),
      ]

      walkable_area.regions << floor
      walkable_area.regions << obstacle
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Create grid accounting for character size
      character_radius = 40.0_f32
      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 800, 600, 20, character_radius
      )

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Find path from left to right of obstacle
      start_pos = RL::Vector2.new(x: 200, y: 300)
      end_pos = RL::Vector2.new(x: 600, y: 300)

      path = pathfinder.find_path(start_pos.x, start_pos.y, end_pos.x, end_pos.y)
      path.should_not be_nil

      if path
        # Path should go around obstacle with enough clearance
        path.each do |waypoint|
          # Check distance from obstacle center
          obstacle_center = RL::Vector2.new(x: 400, y: 300)
          distance = Math.sqrt(
            (waypoint.x - obstacle_center.x) ** 2 +
            (waypoint.y - obstacle_center.y) ** 2
          )

          # Should maintain clearance (obstacle is 100x200, so min distance ~90 with character radius 40)
          distance.should be > 80
        end
      end
    end

    it "returns nil when passage is too narrow for character" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Two areas connected by narrow passage
      area1 = PointClickEngine::Scenes::PolygonRegion.new("area1", true)
      area1.vertices = [
        RL::Vector2.new(x: 0, y: 0),
        RL::Vector2.new(x: 300, y: 0),
        RL::Vector2.new(x: 300, y: 400),
        RL::Vector2.new(x: 0, y: 400),
      ]

      # Narrow connecting passage (40 pixels wide)
      passage = PointClickEngine::Scenes::PolygonRegion.new("passage", true)
      passage.vertices = [
        RL::Vector2.new(x: 300, y: 180),
        RL::Vector2.new(x: 340, y: 180),
        RL::Vector2.new(x: 340, y: 220),
        RL::Vector2.new(x: 300, y: 220),
      ]

      area2 = PointClickEngine::Scenes::PolygonRegion.new("area2", true)
      area2.vertices = [
        RL::Vector2.new(x: 340, y: 0),
        RL::Vector2.new(x: 640, y: 0),
        RL::Vector2.new(x: 640, y: 400),
        RL::Vector2.new(x: 340, y: 400),
      ]

      walkable_area.regions << area1
      walkable_area.regions << passage
      walkable_area.regions << area2
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Character too large for passage
      character_radius = 30.0_f32 # 60 pixel diameter won't fit through 40 pixel passage
      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 640, 400, 10, character_radius
      )

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Try to path from area1 to area2
      start_pos = RL::Vector2.new(x: 150, y: 200)
      end_pos = RL::Vector2.new(x: 490, y: 200)

      path = pathfinder.find_path(start_pos.x, start_pos.y, end_pos.x, end_pos.y)
      path.should be_nil # No valid path for large character
    end
  end
end
