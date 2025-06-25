#!/usr/bin/env crystal

require "./src/point_click_engine"

# Test grid coordinate conversion
grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(65, 49, 16)

# Test player position
player_x = 300.0_f32
player_y = 500.0_f32

puts "Player position: (#{player_x}, #{player_y})"

# Convert to grid
grid_x, grid_y = grid.world_to_grid(player_x, player_y)
puts "Grid position: (#{grid_x}, #{grid_y})"

# Convert back to world (center of cell)
world_x, world_y = grid.grid_to_world(grid_x, grid_y)
puts "Cell center: (#{world_x}, #{world_y})"

# The issue is that world_to_grid truncates, not rounds
# So 300/16 = 18.75, which truncates to 18
# Cell 18 has center at 18*16 + 8 = 296

puts "\nDetailed calculation:"
puts "300.0 / 16 = #{300.0 / 16}"
puts "Truncated: #{(300.0 / 16).to_i}"
puts "Cell center: #{18 * 16 + 8}"

# Try slightly different positions
puts "\nTesting nearby positions:"
[299.0_f32, 299.5_f32, 300.0_f32, 300.5_f32, 301.0_f32, 304.0_f32].each do |x|
  gx, gy = grid.world_to_grid(x, player_y)
  wx, wy = grid.grid_to_world(gx, gy)
  puts "World (#{x}, #{player_y}) -> Grid (#{gx}, #{gy}) -> Center (#{wx}, #{wy})"
end
