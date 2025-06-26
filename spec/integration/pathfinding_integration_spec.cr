require "../spec_helper"

# Integration tests for pathfinding with character size
# These tests verify the integration between Scene, NavigationGrid, and character bounds

describe "Pathfinding Integration" do
  describe "character size aware navigation" do
    it "creates navigation grids that account for character size" do
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

      # Add a wall
      wall = PointClickEngine::Scenes::PolygonRegion.new("wall", false)
      wall.vertices = [
        RL::Vector2.new(x: 350, y: 200),
        RL::Vector2.new(x: 450, y: 200),
        RL::Vector2.new(x: 450, y: 400),
        RL::Vector2.new(x: 350, y: 400),
      ]

      walkable_area.regions << floor
      walkable_area.regions << wall
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      # Create navigation grid with character radius
      character_radius = 40.0_f32
      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 800, 600, 20, character_radius
      )

      # Points too close to wall should be non-walkable
      near_wall_x, near_wall_y = grid.world_to_grid(340, 300)
      grid.is_walkable?(near_wall_x, near_wall_y).should be_false

      # Points far from wall should be walkable
      far_x, far_y = grid.world_to_grid(200, 300)
      grid.is_walkable?(far_x, far_y).should be_true
    end

    it "finds paths that respect character size" do
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

      # Obstacle
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

      # Create navigation grid
      character_radius = 40.0_f32
      grid = PointClickEngine::Navigation::NavigationGrid.from_scene(
        scene, 800, 600, 20, character_radius
      )

      pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

      # Find path around obstacle
      path = pathfinder.find_path(200, 300, 600, 300)
      path.should_not be_nil

      if path
        # Verify path maintains clearance from obstacle
        path.each do |waypoint|
          # Check distance from obstacle edges
          # Left edge at x=350
          if waypoint.y >= 200 && waypoint.y <= 400
            # If we're at obstacle height, must be far from edges
            if waypoint.x < 400                                    # Left side
              waypoint.x.should be < (350 - character_radius + 10) # Some tolerance
            else                                                   # Right side
              waypoint.x.should be > (450 + character_radius - 10)
            end
          end
        end
      end
    end
  end

  describe "scene area walkability" do
    it "correctly determines if character-sized areas are walkable" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Create floor with narrow passage
      floor = PointClickEngine::Scenes::PolygonRegion.new("floor", true)
      floor.vertices = [
        RL::Vector2.new(x: 0, y: 250),
        RL::Vector2.new(x: 800, y: 250),
        RL::Vector2.new(x: 800, y: 350), # 100 pixels high
        RL::Vector2.new(x: 0, y: 350),
      ]

      walkable_area.regions << floor
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      center = RL::Vector2.new(x: 400, y: 300)

      # Small character fits
      small_size = RL::Vector2.new(x: 40, y: 40)
      scene.is_area_walkable?(center, small_size, 1.0).should be_true

      # Large character doesn't fit
      large_size = RL::Vector2.new(x: 120, y: 120)
      scene.is_area_walkable?(center, large_size, 1.0).should be_false

      # Scaled character
      medium_size = RL::Vector2.new(x: 30, y: 30)
      scene.is_area_walkable?(center, medium_size, 2.0).should be_true  # 60x60 effective
      scene.is_area_walkable?(center, medium_size, 4.0).should be_false # 120x120 effective
    end

    it "prevents character bounds from extending outside walkable areas" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      walkable_area = PointClickEngine::Scenes::WalkableArea.new

      # Small platform
      platform = PointClickEngine::Scenes::PolygonRegion.new("platform", true)
      platform.vertices = [
        RL::Vector2.new(x: 300, y: 300),
        RL::Vector2.new(x: 500, y: 300),
        RL::Vector2.new(x: 500, y: 400),
        RL::Vector2.new(x: 300, y: 400),
      ]

      walkable_area.regions << platform
      walkable_area.update_bounds
      scene.walkable_area = walkable_area

      char_size = RL::Vector2.new(x: 60, y: 60)

      # Center of platform - character fits
      center = RL::Vector2.new(x: 400, y: 350)
      scene.is_area_walkable?(center, char_size, 1.0).should be_true

      # Too close to edge - character would extend off platform
      edge = RL::Vector2.new(x: 310, y: 350) # 10 pixels from left edge
      scene.is_area_walkable?(edge, char_size, 1.0).should be_false

      # Just enough clearance
      safe_edge = RL::Vector2.new(x: 330, y: 350) # 30 pixels from edge = half character width
      scene.is_area_walkable?(safe_edge, char_size, 1.0).should be_true
    end
  end
end
