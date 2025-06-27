require "./spec_helper"

describe "Pathfinding Coordinate Handling" do
  it "correctly handles world coordinates through the pathfinding pipeline" do
    RaylibContext.with_window do
      # Create a scene with navigation
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 800
      scene.logical_height = 600
      scene.enable_pathfinding = true
      scene.navigation_cell_size = 16
      
      # Create walkable area
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      region = PointClickEngine::Scenes::PolygonRegion.new(
        name: "main",
        walkable: true
      )
      region.vertices = [
        vec2(0, 0),
        vec2(800, 0),
        vec2(800, 600),
        vec2(0, 600)
      ]
      walkable_area.regions << region
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      
      # Setup navigation
      scene.setup_navigation
      
      # Test that pathfinding preserves coordinate system
      start_pos = vec2(100, 100)
      end_pos = vec2(700, 500)
      
      path = scene.find_path(start_pos.x, start_pos.y, end_pos.x, end_pos.y)
      path.should_not be_nil
      
      # First waypoint should be near start position
      path.not_nil!.first.x.should be_close(start_pos.x, 20)
      path.not_nil!.first.y.should be_close(start_pos.y, 20)
      
      # Last waypoint should be near end position
      path.not_nil!.last.x.should be_close(end_pos.x, 20)
      path.not_nil!.last.y.should be_close(end_pos.y, 20)
      
      # All waypoints should be within scene bounds
      path.not_nil!.each do |waypoint|
        waypoint.x.should be >= 0
        waypoint.x.should be <= 800
        waypoint.y.should be >= 0
        waypoint.y.should be <= 600
      end
    end
  end
  
  it "returns nil for unreachable destinations" do
    RaylibContext.with_window do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 800
      scene.logical_height = 600
      scene.enable_pathfinding = true
      
      # Create walkable area with a gap
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      
      # Left area
      left_region = PointClickEngine::Scenes::PolygonRegion.new(
        name: "left",
        walkable: true
      )
      left_region.vertices = [
        vec2(0, 0),
        vec2(300, 0),
        vec2(300, 600),
        vec2(0, 600)
      ]
      walkable_area.regions << left_region
      
      # Right area (separated from left)
      right_region = PointClickEngine::Scenes::PolygonRegion.new(
        name: "right",
        walkable: true
      )
      right_region.vertices = [
        vec2(500, 0),
        vec2(800, 0),
        vec2(800, 600),
        vec2(500, 600)
      ]
      walkable_area.regions << right_region
      
      # Non-walkable middle area
      middle_region = PointClickEngine::Scenes::PolygonRegion.new(
        name: "middle",
        walkable: false
      )
      middle_region.vertices = [
        vec2(300, 0),
        vec2(500, 0),
        vec2(500, 600),
        vec2(300, 600)
      ]
      walkable_area.regions << middle_region
      
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      scene.setup_navigation
      
      # Try to path from left to right area (should fail)
      path = scene.find_path(150, 300, 650, 300)
      path.should be_nil
    end
  end
  
  it "handles pathfinding with obstacles" do
    RaylibContext.with_window do
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 800
      scene.logical_height = 600
      scene.enable_pathfinding = true
      scene.navigation_cell_size = 16
      
      # Create walkable area with an obstacle
      walkable_area = PointClickEngine::Scenes::WalkableArea.new
      
      # Main walkable area
      main_region = PointClickEngine::Scenes::PolygonRegion.new(
        name: "main",
        walkable: true
      )
      main_region.vertices = [
        vec2(0, 0),
        vec2(800, 0),
        vec2(800, 600),
        vec2(0, 600)
      ]
      walkable_area.regions << main_region
      
      # Obstacle in the middle
      obstacle = PointClickEngine::Scenes::PolygonRegion.new(
        name: "obstacle",
        walkable: false
      )
      obstacle.vertices = [
        vec2(350, 250),
        vec2(450, 250),
        vec2(450, 350),
        vec2(350, 350)
      ]
      walkable_area.regions << obstacle
      
      walkable_area.update_bounds
      scene.walkable_area = walkable_area
      scene.setup_navigation
      
      # Path from left to right should go around obstacle
      path = scene.find_path(300, 300, 500, 300)
      path.should_not be_nil
      
      # Path should have more than 2 waypoints (not direct)
      path.not_nil!.size.should be > 2
      
      # Path should avoid the obstacle area
      path.not_nil!.each do |waypoint|
        # Check if waypoint is outside obstacle bounds
        in_obstacle = waypoint.x >= 350 && waypoint.x <= 450 &&
                      waypoint.y >= 250 && waypoint.y <= 350
        in_obstacle.should be_false
      end
    end
  end
end