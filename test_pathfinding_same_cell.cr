require "./src/navigation/navigation_grid"
require "./src/navigation/pathfinding"
require "raylib-cr"

# Add the alias for consistency
alias RL = Raylib

# Test same-cell pathfinding
grid = PointClickEngine::Navigation::NavigationGrid.new(10, 10, 32)
pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

# Two points in same 32x32 cell but different positions
start_x, start_y = 50.0_f32, 50.0_f32 # Cell (1,1)
end_x, end_y = 60.0_f32, 55.0_f32     # Same cell (1,1)

puts "Grid cell size: #{grid.cell_size}"
start_grid = grid.world_to_grid(start_x, start_y)
end_grid = grid.world_to_grid(end_x, end_y)
puts "Start position: (#{start_x}, #{start_y}) -> grid cell: #{start_grid}"
puts "End position: (#{end_x}, #{end_y}) -> grid cell: #{end_grid}"

distance = Math.sqrt((end_x - start_x)**2 + (end_y - start_y)**2)
puts "Distance between points: #{distance}"
puts "SAME_CELL_DISTANCE_THRESHOLD: #{PointClickEngine::Core::GameConstants::SAME_CELL_DISTANCE_THRESHOLD}"

puts "\nFinding path..."
path = pathfinder.find_path(start_x, start_y, end_x, end_y)
if path
  puts "Path found with #{path.size} waypoints:"
  path.each_with_index do |waypoint, i|
    puts "  #{i}: #{waypoint}"
  end
else
  puts "No path found!"
end

# Test very small distance
puts "\n--- Testing very small distance ---"
start_x2, start_y2 = 50.0_f32, 50.0_f32
end_x2, end_y2 = 50.5_f32, 50.0_f32

distance2 = Math.sqrt((end_x2 - start_x2)**2 + (end_y2 - start_y2)**2)
puts "Distance: #{distance2}"

path2 = pathfinder.find_path(start_x2, start_y2, end_x2, end_y2)
if path2
  puts "Path found with #{path2.size} waypoints"
else
  puts "No path found!"
end
