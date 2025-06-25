require "../spec_helper"

describe "Wall Detection Test" do
  it "verifies wall blocks path" do
    grid = PointClickEngine::Navigation::Pathfinding::NavigationGrid.new(20, 20, 16)

    # Create a vertical wall
    (0..19).each do |y|
      grid.set_walkable(10, y, false)
    end
    grid.set_walkable(10, 10, true) # gap

    # Check if cells are properly marked
    puts "\nChecking wall cells:"
    puts "Cell (10, 9) walkable? #{grid.is_walkable?(10, 9)} (should be false)"
    puts "Cell (10, 10) walkable? #{grid.is_walkable?(10, 10)} (should be true)"
    puts "Cell (10, 11) walkable? #{grid.is_walkable?(10, 11)} (should be false)"

    # Check from world coordinates
    world_pos1 = grid.grid_to_world(10, 9)
    world_pos2 = grid.grid_to_world(10, 10)
    world_pos3 = grid.grid_to_world(10, 11)

    puts "\nWorld positions:"
    puts "Grid (10,9) -> World #{world_pos1}"
    puts "Grid (10,10) -> World #{world_pos2}"
    puts "Grid (10,11) -> World #{world_pos3}"

    # Now create pathfinder and test
    pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

    # Try to find path without optimization first
    start_pos = grid.grid_to_world(5, 10)
    end_pos = grid.grid_to_world(15, 10)

    puts "\nFinding path from (5,10) to (15,10)"
    puts "Start world: (#{start_pos[0]}, #{start_pos[1]})"
    puts "End world: (#{end_pos[0]}, #{end_pos[1]})"

    path = pathfinder.find_path(start_pos[0], start_pos[1], end_pos[0], end_pos[1])

    if path
      puts "\nRaw path nodes:"
      path.each do |point|
        grid_pos = grid.world_to_grid(point.x, point.y)
        puts "  World(#{point.x}, #{point.y}) -> Grid(#{grid_pos[0]}, #{grid_pos[1]})"
      end
    end

    path.should_not be_nil
  end
end
