#!/usr/bin/env crystal

# Theory: The first click fails because the grid cell at player position (300, 500) is marked as non-walkable
# But the test script shows it should be walkable with radius 20
#
# Possible causes:
# 1. Grid is modified after creation
# 2. Player position is slightly different than expected
# 3. There's a race condition or initialization order issue

require "./src/point_click_engine"

# Recreate the exact scenario
scene = PointClickEngine::Scenes::Scene.new("library")
scene.logical_width = 1024
scene.logical_height = 768
scene.enable_pathfinding = true
scene.navigation_cell_size = 16

# Create walkable area
walkable_area = PointClickEngine::Scenes::WalkableArea.new

# Main floor
floor = PointClickEngine::Scenes::PolygonRegion.new("main_floor", true)
floor.vertices = [
  RL::Vector2.new(x: 100, y: 350),
  RL::Vector2.new(x: 900, y: 350),
  RL::Vector2.new(x: 900, y: 700),
  RL::Vector2.new(x: 100, y: 700),
]

# Desk area
desk = PointClickEngine::Scenes::PolygonRegion.new("desk_area", false)
desk.vertices = [
  RL::Vector2.new(x: 380, y: 380),
  RL::Vector2.new(x: 620, y: 380),
  RL::Vector2.new(x: 620, y: 550),
  RL::Vector2.new(x: 380, y: 550),
]

walkable_area.regions << floor
walkable_area.regions << desk
walkable_area.update_bounds
scene.walkable_area = walkable_area

# Create a minimal background to satisfy setup_navigation requirements
# This is a workaround since we can't easily create a real texture
class FakeBackground
  getter width : Int32 = 320
  getter height : Int32 = 180
end

scene.instance_variable_set("@background", FakeBackground.new)

# Setup navigation with radius 20 (matching the game)
puts "Setting up navigation..."
scene.setup_navigation(20.0_f32)

# Get the grid
if grid = scene.instance_variable_get("@navigation_grid").as?(PointClickEngine::Navigation::Pathfinding::NavigationGrid)
  puts "Grid created successfully"

  # Check player spawn position
  player_x = 300.0_f32
  player_y = 500.0_f32
  gx, gy = grid.world_to_grid(player_x, player_y)

  puts "\nPlayer spawn (#{player_x}, #{player_y}) -> Grid(#{gx}, #{gy})"
  puts "Is walkable: #{grid.is_walkable?(gx, gy)}"

  # Now try pathfinding
  if pathfinder = scene.instance_variable_get("@pathfinder").as?(PointClickEngine::Navigation::Pathfinding)
    puts "\nTrying pathfinding from player position to (261, 629)..."
    path = scene.find_path(player_x, player_y, 261.0_f32, 629.0_f32)
    if path
      puts "Path found with #{path.size} waypoints"
    else
      puts "No path found!"
    end
  end
else
  puts "Failed to create grid!"
end
