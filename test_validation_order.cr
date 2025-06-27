require "./src/navigation/navigation_grid"
require "./src/navigation/pathfinding"
require "./src/navigation/movement_validator"
require "raylib-cr"

# Add the alias for consistency
alias RL = Raylib

# Test validation order
grid = PointClickEngine::Navigation::NavigationGrid.new(10, 10, 32)
validator = PointClickEngine::Navigation::MovementValidator.for_point_and_click

# Two points in same 32x32 cell but different positions
start_x, start_y = 50.0_f32, 50.0_f32 # Cell (1,1)
end_x, end_y = 60.0_f32, 55.0_f32     # Same cell (1,1)

# Check validation
valid = validator.validate_pathfinding_input(grid, start_x, start_y, end_x, end_y)
puts "Validation result: #{valid}"

# Check grid conversion
start_grid = grid.world_to_grid(start_x, start_y)
end_grid = grid.world_to_grid(end_x, end_y)
puts "Start grid: #{start_grid}, End grid: #{end_grid}"
puts "Same cell: #{start_grid[0] == end_grid[0] && start_grid[1] == end_grid[1]}"
