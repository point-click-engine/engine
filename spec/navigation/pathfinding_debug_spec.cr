require "../spec_helper"

describe "Pathfinding Debug Tests" do
  it "debugs complex obstacle navigation" do
    grid = PointClickEngine::Navigation::NavigationGrid.new(20, 20, 16)

    # Create a vertical wall that blocks direct path
    (0..19).each do |y|
      grid.set_walkable(10, y, false)
    end
    # Create a single gap in the wall
    grid.set_walkable(10, 10, true)

    pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)
    # Path from left side to right side - must go through gap
    path = pathfinder.find_path(80f32, 160f32, 240f32, 160f32) # x=5,y=10 to x=15,y=10

    if path
      puts "\nPath found with #{path.size} waypoints:"
      path.each_with_index do |point, i|
        grid_pos = grid.world_to_grid(point.x, point.y)
        puts "  #{i}: World(#{point.x}, #{point.y}) -> Grid(#{grid_pos[0]}, #{grid_pos[1]})"
      end

      # Check if any point is near the gap
      near_gap = path.any? do |point|
        grid_pos = grid.world_to_grid(point.x, point.y)
        near = (grid_pos[0] - 10).abs <= 1 && (grid_pos[1] - 10).abs <= 1
        puts "  Point at grid #{grid_pos} near gap? #{near}" if near
        near
      end
      puts "Has point near gap (10,10): #{near_gap}"
    else
      puts "No path found!"
    end

    # This test is just for debugging
    path.should_not be_nil
  end

  it "debugs narrow passage navigation" do
    grid = PointClickEngine::Navigation::NavigationGrid.new(20, 20, 16)

    # Create narrow passage - only x=10 is passable at y=10
    (0...20).each do |x|
      grid.set_walkable(x, 10, false) unless x == 10
    end

    pathfinder = PointClickEngine::Navigation::Pathfinding.new(grid)

    # Path through narrow passage from (10,5) to (10,15)
    path = pathfinder.find_path(160f32, 80f32, 160f32, 240f32)

    if path
      puts "\nNarrow passage path with #{path.size} waypoints:"
      path.each_with_index do |point, i|
        grid_pos = grid.world_to_grid(point.x, point.y)
        puts "  #{i}: World(#{point.x}, #{point.y}) -> Grid(#{grid_pos[0]}, #{grid_pos[1]})"
      end
    else
      puts "No path found through narrow passage!"
    end

    path.should_not be_nil
  end
end
