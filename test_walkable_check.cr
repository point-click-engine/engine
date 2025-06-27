require "./src/navigation/navigation_grid"
require "raylib-cr"

# Add the alias for consistency
alias RL = Raylib

# Test walkability
grid = PointClickEngine::Navigation::NavigationGrid.new(10, 10, 32)

# Check if cells are walkable by default
puts "Grid dimensions: #{grid.width}x#{grid.height}, cell size: #{grid.cell_size}"

# Check cell (1,1)
walkable = grid.is_walkable?(1, 1)
puts "Cell (1,1) walkable: #{walkable}"

# Check all cells
walkable_count = 0
(0...grid.width).each do |x|
  (0...grid.height).each do |y|
    if grid.is_walkable?(x, y)
      walkable_count += 1
    end
  end
end

puts "Total walkable cells: #{walkable_count} out of #{grid.width * grid.height}"
