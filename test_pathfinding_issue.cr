#!/usr/bin/env crystal

require "./src/point_click_engine"

# Create test scene
scene = PointClickEngine::Scenes::Scene.new("test")
scene.logical_width = 1024
scene.logical_height = 768
scene.enable_pathfinding = true
scene.navigation_cell_size = 16

# Create walkable area matching library.yaml
walkable_area = PointClickEngine::Scenes::WalkableArea.new

# Main floor
floor = PointClickEngine::Scenes::PolygonRegion.new("main_floor", true)
floor.vertices = [
  RL::Vector2.new(x: 100, y: 350),
  RL::Vector2.new(x: 900, y: 350),
  RL::Vector2.new(x: 900, y: 700),
  RL::Vector2.new(x: 100, y: 700),
]

# Desk area (obstacle)
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

# Test player position
player_pos = RL::Vector2.new(x: 300, y: 500)
puts "Testing player position: #{player_pos}"
puts "Is walkable in scene: #{scene.walkable_area.not_nil!.is_point_walkable?(player_pos)}"

# Setup navigation with radius 20
puts "\nSetting up navigation with radius 20..."
grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
  scene, scene.logical_width, scene.logical_height, 16, 20.0_f32
)

# Check grid cell for player position
grid_x, grid_y = grid.world_to_grid(player_pos.x, player_pos.y)
puts "Player grid position: (#{grid_x}, #{grid_y})"
puts "Is walkable in grid: #{grid.is_walkable?(grid_x, grid_y)}"

# Check surrounding cells
puts "\nChecking surrounding cells:"
(-2..2).each do |dy|
  (-2..2).each do |dx|
    gx = grid_x + dx
    gy = grid_y + dy
    if gx >= 0 && gy >= 0 && gx < grid.width && gy < grid.height
      world_x, world_y = grid.grid_to_world(gx, gy)
      walkable = grid.is_walkable?(gx, gy)
      print walkable ? "O" : "X"
    else
      print " "
    end
  end
  puts
end

puts "\nLegend: O = walkable, X = not walkable, center is player position"

# Try different radii
puts "\nTesting with different character radii:"
[0, 5, 10, 15, 20, 25, 30].each do |radius|
  test_grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.from_scene(
    scene, scene.logical_width, scene.logical_height, 16, radius.to_f32
  )
  gx, gy = test_grid.world_to_grid(player_pos.x, player_pos.y)
  walkable = test_grid.is_walkable?(gx, gy)
  puts "Radius #{radius}: Grid(#{gx}, #{gy}) = #{walkable ? "WALKABLE" : "NOT WALKABLE"}"
end
