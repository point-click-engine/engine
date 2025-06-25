module PointClickEngine
  # # Navigation and pathfinding systems for character movement.
  ##
  # # The `Navigation` module provides intelligent pathfinding for characters
  # # to navigate around obstacles. It implements the A* algorithm with
  # # grid-based navigation meshes for efficient path calculation.
  ##
  # # ## Core Components
  ##
  # # - `Pathfinding` - A* pathfinding algorithm implementation
  # # - `NavigationGrid` - Grid-based walkable area representation
  # # - `Node` - Pathfinding graph nodes
  ##
  # # ## Basic Usage
  ##
  # # ```crystal
  # # # Create navigation grid from scene
  # # nav_grid = NavigationGrid.from_scene(scene, 800, 600, cell_size: 16)
  ##
  # # # Create pathfinder
  # # pathfinder = Pathfinding.new(nav_grid)
  ##
  # # # Find path
  # # path = pathfinder.find_path(
  # #   start_pos: Vector2.new(100, 100),
  # #   end_pos: Vector2.new(700, 500)
  # # )
  ##
  # # # Follow path
  # # if path
  # #   character.follow_path(path)
  # # end
  # # ```
  ##
  # # ## Navigation Grid Setup
  ##
  # # ```crystal
  # # # Manual grid creation
  # # grid = NavigationGrid.new(50, 40, cell_size: 16)
  ##
  # # # Mark obstacles
  # # grid.set_rect_walkable(200, 150, 100, 80, walkable: false)
  ##
  # # # Set individual cells
  # # grid.set_walkable(10, 15, false)
  # # ```
  ##
  # # ## Path Smoothing
  ##
  # # ```crystal
  # # # Get smoothed path for natural movement
  # # raw_path = pathfinder.find_path(start, goal)
  # # smooth_path = pathfinder.smooth_path(raw_path)
  # # ```
  ##
  # # ## Performance Optimization
  ##
  # # ```crystal
  # # # Larger cell sizes = faster but less precise
  # # nav_grid = NavigationGrid.new(width, height, cell_size: 32)
  ##
  # # # Cache paths for common routes
  # # @path_cache = {} of {Vector2, Vector2} => Array(Vector2)?
  # # ```
  ##
  # # ## Common Patterns
  ##
  # # ### Dynamic Obstacles
  # # ```crystal
  # # # Update grid when objects move
  # # grid.set_rect_walkable(old_pos.x, old_pos.y, size.x, size.y, true)
  # # grid.set_rect_walkable(new_pos.x, new_pos.y, size.x, size.y, false)
  # # ```
  ##
  # # ### Path Validation
  # # ```crystal
  # # # Check if path still valid after scene change
  # # if path && !pathfinder.is_path_valid?(path)
  # #   # Recalculate path
  # #   path = pathfinder.find_path(current_pos, target_pos)
  # # end
  # # ```
  ##
  # # ## See Also
  ##
  # # - `Character#walk_to` - High-level movement API
  # # - `Scene#setup_navigation` - Automatic grid generation
  # # - `WalkableArea` - Polygon-based navigation
  module Navigation
    # # A* pathfinding implementation for point & click navigation.
    ##
    # # The `Pathfinding` class implements the A* algorithm to find optimal
    # # paths through a grid-based navigation mesh. It supports diagonal
    # # movement and path smoothing for natural character movement.
    ##
    # # ## Algorithm Details
    ##
    # # A* combines:
    # # - **G cost**: Distance from start node
    # # - **H cost**: Heuristic distance to goal (Manhattan or Euclidean)
    # # - **F cost**: G + H (total estimated cost)
    ##
    # # ## Basic Usage
    ##
    # # ```crystal
    # # # Create pathfinder with navigation grid
    # # grid = NavigationGrid.new(50, 40, cell_size: 16)
    # # pathfinder = Pathfinding.new(grid)
    ##
    # # # Find path between two points
    # # start = Vector2.new(100, 100)
    # # goal = Vector2.new(600, 400)
    # # path = pathfinder.find_path(start, goal)
    ##
    # # if path
    # #   puts "Path found with #{path.size} waypoints"
    # #   character.follow_path(path)
    # # else
    # #   puts "No path available"
    # # end
    # # ```
    ##
    # # ## Diagonal Movement
    ##
    # # ```crystal
    # # # Enable/disable diagonal movement
    # # pathfinder.allow_diagonal = true  # 8-directional
    # # pathfinder.allow_diagonal = false # 4-directional
    ##
    # # # Diagonal movement cost
    # # pathfinder.diagonal_cost = 1.414  # sqrt(2)
    # # ```
    ##
    # # ## Path Smoothing
    ##
    # # ```crystal
    # # # Smooth path for more natural movement
    # # raw_path = pathfinder.find_path(start, goal)
    # # smooth_path = pathfinder.smooth_path(raw_path)
    ##
    # # # Reduces unnecessary waypoints
    # # # [A->B->C->D] might become [A->D] if no obstacles
    # # ```
    ##
    # # ## Heuristics
    ##
    # # ```crystal
    # # # Manhattan distance (grid-based movement)
    # # pathfinder.heuristic = :manhattan
    ##
    # # # Euclidean distance (more accurate)
    # # pathfinder.heuristic = :euclidean
    ##
    # # # Custom heuristic
    # # pathfinder.heuristic_func = ->(a : Node, b : Node) {
    # #   # Your custom distance calculation
    # #   (a.x - b.x).abs + (a.y - b.y).abs
    # # }
    # # ```
    ##
    # # ## Performance Considerations
    ##
    # # - **Grid size**: Smaller cells = more precise but slower
    # # - **Search limit**: Set max nodes to prevent hanging
    # # - **Path caching**: Cache frequently used paths
    # # - **Hierarchical**: Use multiple grid resolutions
    ##
    # # ```crystal
    # # # Limit search space
    # # pathfinder.max_search_nodes = 1000
    ##
    # # # Early exit for long paths
    # # path = pathfinder.find_path(start, goal, max_distance: 500)
    # # ```
    ##
    # # ## Common Gotchas
    ##
    # # 1. **Grid alignment**: Ensure positions align with grid
    # #    ```crystal
    # #    # Snap to grid center
    # #    grid_x, grid_y = grid.world_to_grid(pos.x, pos.y)
    # #    snapped_x, snapped_y = grid.grid_to_world(grid_x, grid_y)
    # #    ```
    ##
    # # 2. **Dynamic obstacles**: Update grid when scene changes
    # #    ```crystal
    # #    # Moving obstacle
    # #    update_grid_for_object(old_pos, new_pos)
    # #    ```
    ##
    # # 3. **Path invalidation**: Stored paths can become invalid
    # #    ```crystal
    # #    # Validate before use
    # #    if !pathfinder.is_path_valid?(stored_path)
    # #      stored_path = pathfinder.find_path(start, goal)
    # #    end
    # #    ```
    ##
    # # ## Debugging
    ##
    # # ```crystal
    # # # Visualize pathfinding
    # # if Engine.debug_mode
    # #   pathfinder.draw_grid
    # #   pathfinder.draw_path(current_path)
    # # end
    # # ```
    ##
    # # ## See Also
    ##
    # # - `NavigationGrid` - Grid-based navigation mesh
    # # - `Node` - Pathfinding graph nodes
    # # - `Character#path` - Character path following
    class Pathfinding
      # Node used in pathfinding
      class Node
        property x : Int32
        property y : Int32
        property g_cost : Float32 # Cost from start
        property h_cost : Float32 # Heuristic cost to end
        property parent : Node?

        def initialize(@x : Int32, @y : Int32, @g_cost = 0.0f32, @h_cost = 0.0f32, @parent = nil)
        end

        def f_cost
          @g_cost + @h_cost
        end

        def ==(other : Node)
          @x == other.x && @y == other.y
        end

        def hash
          {@x, @y}.hash
        end
      end

      # Grid-based navigation mesh
      class NavigationGrid
        property width : Int32
        property height : Int32
        property cell_size : Int32
        property walkable : Array(Array(Bool))

        def initialize(@width : Int32, @height : Int32, @cell_size : Int32 = 32)
          @walkable = Array.new(@height) { Array.new(@width, true) }
        end

        def set_walkable(x : Int32, y : Int32, walkable : Bool)
          return if x < 0 || y < 0 || x >= @width || y >= @height
          @walkable[y][x] = walkable
        end

        def is_walkable?(x : Int32, y : Int32) : Bool
          return false if x < 0 || y < 0 || x >= @width || y >= @height
          @walkable[y][x]
        end

        def world_to_grid(world_x : Float32, world_y : Float32) : {Int32, Int32}
          grid_x = (world_x / @cell_size).to_i
          grid_y = (world_y / @cell_size).to_i
          {grid_x, grid_y}
        end

        def grid_to_world(grid_x : Int32, grid_y : Int32) : {Float32, Float32}
          world_x = (grid_x * @cell_size + @cell_size / 2).to_f32
          world_y = (grid_y * @cell_size + @cell_size / 2).to_f32
          {world_x, world_y}
        end

        # Mark a rectangle as walkable or not
        def set_rect_walkable(x : Int32, y : Int32, width : Int32, height : Int32, walkable : Bool)
          grid_x1, grid_y1 = world_to_grid(x.to_f32, y.to_f32)
          grid_x2, grid_y2 = world_to_grid((x + width).to_f32, (y + height).to_f32)

          (grid_y1..grid_y2).each do |gy|
            (grid_x1..grid_x2).each do |gx|
              set_walkable(gx, gy, walkable)
            end
          end
        end

        # Create from scene hotspots and objects
        def self.from_scene(scene : Scenes::Scene, width : Int32, height : Int32, cell_size : Int32 = 32) : NavigationGrid
          grid_width = (width / cell_size).to_i + 1
          grid_height = (height / cell_size).to_i + 1
          grid = new(grid_width, grid_height, cell_size)

          # Apply walkable area restrictions if defined
          if walkable_area = scene.walkable_area
            # Mark all cells based on walkable area
            (0...grid.height).each do |y|
              (0...grid.width).each do |x|
                world_x, world_y = grid.grid_to_world(x, y)
                world_pos = RL::Vector2.new(x: world_x, y: world_y)
                is_walkable = walkable_area.is_point_walkable?(world_pos)
                grid.set_walkable(x, y, is_walkable)
              end
            end
          end

          # Mark non-walkable areas from hotspots
          scene.hotspots.each do |hotspot|
            if hotspot.blocks_movement
              grid.set_rect_walkable(
                hotspot.bounds.x.to_i,
                hotspot.bounds.y.to_i,
                hotspot.bounds.width.to_i,
                hotspot.bounds.height.to_i,
                false
              )
            end
          end

          # Mark non-walkable areas from characters
          scene.characters.each do |character|
            next if character.is_a?(Characters::Player) # Don't block player's own path
            grid.set_rect_walkable(
              (character.position.x - character.size.x / 2).to_i,
              (character.position.y - character.size.y / 2).to_i,
              character.size.x.to_i,
              character.size.y.to_i,
              false
            )
          end

          grid
        end
      end

      property grid : NavigationGrid
      property allow_diagonal : Bool
      property max_search_nodes : Int32 = 5000

      def initialize(@grid : NavigationGrid, @allow_diagonal : Bool = true)
      end

      # Find path using A* algorithm
      def find_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Array(Raylib::Vector2)?
        start_grid = @grid.world_to_grid(start_x, start_y)
        end_grid = @grid.world_to_grid(end_x, end_y)

        # Check if start and end are walkable
        return nil unless @grid.is_walkable?(start_grid[0], start_grid[1])
        return nil unless @grid.is_walkable?(end_grid[0], end_grid[1])

        # Special case: already at destination
        if start_grid[0] == end_grid[0] && start_grid[1] == end_grid[1]
          return [Raylib::Vector2.new(x: end_x, y: end_y)]
        end

        # A* algorithm with priority queue
        open_list = [] of Node
        closed_set = Set({Int32, Int32}).new

        start_node = Node.new(start_grid[0], start_grid[1])
        end_node = Node.new(end_grid[0], end_grid[1])

        start_node.h_cost = heuristic(start_node, end_node)
        open_list << start_node

        # Track best node for each position
        best_g_cost = {} of {Int32, Int32} => Float32
        best_g_cost[{start_node.x, start_node.y}] = 0.0f32

        nodes_searched = 0

        while !open_list.empty? && nodes_searched < @max_search_nodes
          nodes_searched += 1

          # Get node with lowest f_cost (using heap would be more efficient)
          current_index = 0
          current = open_list[0]
          open_list.each_with_index do |node, index|
            if node.f_cost < current.f_cost || (node.f_cost == current.f_cost && node.h_cost < current.h_cost)
              current = node
              current_index = index
            end
          end

          open_list.delete_at(current_index)
          closed_set.add({current.x, current.y})

          # Found the goal
          if current.x == end_node.x && current.y == end_node.y
            return reconstruct_path(current)
          end

          # Check neighbors
          neighbors = get_neighbors(current)
          neighbors.each do |neighbor_pos|
            next if closed_set.includes?(neighbor_pos)
            next unless @grid.is_walkable?(neighbor_pos[0], neighbor_pos[1])

            # For diagonal movement, check if we can actually move diagonally
            if @allow_diagonal && is_diagonal_move(current, neighbor_pos)
              next unless can_move_diagonally(current.x, current.y, neighbor_pos[0], neighbor_pos[1])
            end

            # Calculate tentative g_cost
            move_cost = calculate_move_cost(current, neighbor_pos)
            tentative_g = current.g_cost + move_cost

            # Skip if we've already found a better path to this node
            if best_g_cost.has_key?(neighbor_pos) && tentative_g >= best_g_cost[neighbor_pos]
              next
            end

            # This path is better
            best_g_cost[neighbor_pos] = tentative_g

            # Find or create neighbor node
            neighbor = open_list.find { |n| n.x == neighbor_pos[0] && n.y == neighbor_pos[1] }

            if neighbor.nil?
              neighbor = Node.new(neighbor_pos[0], neighbor_pos[1])
              neighbor.g_cost = tentative_g
              neighbor.h_cost = heuristic(neighbor, end_node)
              neighbor.parent = current
              open_list << neighbor
            elsif tentative_g < neighbor.g_cost
              neighbor.g_cost = tentative_g
              neighbor.parent = current
            end
          end
        end

        nil # No path found
      end

      # Check if movement is diagonal
      private def is_diagonal_move(from : Node, to : {Int32, Int32}) : Bool
        dx = (from.x - to[0]).abs
        dy = (from.y - to[1]).abs
        dx == 1 && dy == 1
      end

      # Check if diagonal movement is valid (not cutting corners)
      private def can_move_diagonally(from_x : Int32, from_y : Int32, to_x : Int32, to_y : Int32) : Bool
        # Check both adjacent cells to prevent corner cutting
        @grid.is_walkable?(from_x, to_y) && @grid.is_walkable?(to_x, from_y)
      end

      # Calculate movement cost
      private def calculate_move_cost(from : Node, to : {Int32, Int32}) : Float32
        dx = (from.x - to[0]).abs
        dy = (from.y - to[1]).abs

        if dx == 1 && dy == 1
          1.414f32 # Diagonal cost (sqrt(2))
        else
          1.0f32 # Cardinal cost
        end
      end

      # Get walkable neighbors
      private def get_neighbors(node : Node) : Array({Int32, Int32})
        neighbors = [] of {Int32, Int32}

        # Cardinal directions - always check these
        neighbors << {node.x - 1, node.y} # Left
        neighbors << {node.x + 1, node.y} # Right
        neighbors << {node.x, node.y - 1} # Up
        neighbors << {node.x, node.y + 1} # Down

        if @allow_diagonal
          # Diagonal directions
          neighbors << {node.x - 1, node.y - 1} # Top-left
          neighbors << {node.x + 1, node.y - 1} # Top-right
          neighbors << {node.x - 1, node.y + 1} # Bottom-left
          neighbors << {node.x + 1, node.y + 1} # Bottom-right
        end

        neighbors
      end

      # Heuristic function
      private def heuristic(a : Node, b : Node) : Float32
        dx = (a.x - b.x).abs.to_f32
        dy = (a.y - b.y).abs.to_f32

        if @allow_diagonal
          # Octile distance (better for diagonal movement)
          d_min = Math.min(dx, dy)
          d_max = Math.max(dx, dy)
          1.414f32 * d_min + (d_max - d_min)
        else
          # Manhattan distance
          dx + dy
        end
      end

      # Reconstruct path from end node
      private def reconstruct_path(end_node : Node) : Array(Raylib::Vector2)
        path = [] of Raylib::Vector2
        current = end_node

        while current
          world_pos = @grid.grid_to_world(current.x, current.y)
          path << Raylib::Vector2.new(x: world_pos[0], y: world_pos[1])
          current = current.parent
        end

        path.reverse!
        # Don't over-smooth the path - just remove redundant points
        optimize_path(path)
      end

      # Optimize path by removing redundant waypoints
      private def optimize_path(path : Array(Raylib::Vector2)) : Array(Raylib::Vector2)
        return path if path.size < 3

        # For very short paths, keep at least one intermediate point
        if path.size <= 3
          return path
        end

        optimized = [path[0]]
        i = 0

        while i < path.size - 1
          # Look ahead to find furthest reachable point
          j = i + 1
          furthest = i + 1

          # Don't optimize away all intermediate points
          max_lookahead = Math.min(i + 5, path.size - 1)

          while j < path.size && j <= max_lookahead
            if has_clear_path(path[i], path[j])
              furthest = j
            else
              break # Stop at first obstacle
            end
            j += 1
          end

          # Always include at least some intermediate points for long paths
          if furthest == path.size - 1 && path.size > 5 && optimized.size == 1
            # Keep a midpoint for long direct paths
            mid = (path.size / 2).to_i
            optimized << path[mid]
          end

          optimized << path[furthest]
          i = furthest
        end

        # Ensure we always include the final destination
        if optimized.last != path.last
          optimized << path.last
        end

        optimized
      end

      # Check if there's a clear path between two points using Bresenham's line algorithm
      private def has_clear_path(start : Raylib::Vector2, target : Raylib::Vector2) : Bool
        # Convert to grid coordinates for precise checking
        start_grid = @grid.world_to_grid(start.x, start.y)
        end_grid = @grid.world_to_grid(target.x, target.y)

        x0, y0 = start_grid
        x1, y1 = end_grid

        # Bresenham's line algorithm to check all cells along the path
        dx = (x1 - x0).abs
        dy = (y1 - y0).abs
        sx = x0 < x1 ? 1 : -1
        sy = y0 < y1 ? 1 : -1
        err = dx - dy

        x, y = x0, y0

        while true
          # Check if current cell is walkable
          return false unless @grid.is_walkable?(x, y)

          # Reached the end
          break if x == x1 && y == y1

          # Calculate next position
          e2 = 2 * err
          if e2 > -dy
            err -= dy
            x += sx
          end
          if e2 < dx
            err += dx
            y += sy
          end
        end

        true
      end

      # Check if a path is still valid
      def is_path_valid?(path : Array(Raylib::Vector2)) : Bool
        return false if path.empty?

        path.each do |point|
          grid_pos = @grid.world_to_grid(point.x, point.y)
          return false unless @grid.is_walkable?(grid_pos[0], grid_pos[1])
        end

        true
      end

      # Debug visualization
      def draw_debug(color_walkable : Raylib::Color = Raylib::GREEN,
                     color_blocked : Raylib::Color = Raylib::RED,
                     alpha : UInt8 = 100u8)
        (0...@grid.height).each do |y|
          (0...@grid.width).each do |x|
            world_pos = @grid.grid_to_world(x, y)
            color = @grid.is_walkable?(x, y) ? color_walkable : color_blocked
            color.a = alpha

            Raylib.draw_rectangle(
              (world_pos[0] - @grid.cell_size / 2).to_i,
              (world_pos[1] - @grid.cell_size / 2).to_i,
              @grid.cell_size,
              @grid.cell_size,
              color
            )
          end
        end
      end

      # Draw a path
      def draw_path(path : Array(Raylib::Vector2), color : Raylib::Color = Raylib::YELLOW, thickness : Float32 = 3.0f32)
        return if path.size < 2

        (0...path.size - 1).each do |i|
          Raylib.draw_line_ex(path[i], path[i + 1], thickness, color)
        end

        # Draw waypoints
        path.each do |point|
          Raylib.draw_circle_v(point, 5.0f32, color)
        end
      end
    end
  end
end
