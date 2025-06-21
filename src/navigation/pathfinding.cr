module PointClickEngine
  module Navigation
    # A* pathfinding implementation for point & click navigation
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

      def initialize(@grid : NavigationGrid, @allow_diagonal : Bool = true)
      end

      # Find path using A* algorithm
      def find_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Array(Raylib::Vector2)?
        start_grid = @grid.world_to_grid(start_x, start_y)
        end_grid = @grid.world_to_grid(end_x, end_y)

        # Check if start and end are walkable
        return nil unless @grid.is_walkable?(start_grid[0], start_grid[1])
        return nil unless @grid.is_walkable?(end_grid[0], end_grid[1])

        # A* algorithm
        open_set = Set(Node).new
        closed_set = Set(Node).new

        start_node = Node.new(start_grid[0], start_grid[1])
        end_node = Node.new(end_grid[0], end_grid[1])

        start_node.h_cost = heuristic(start_node, end_node)
        open_set.add(start_node)

        # Track nodes by position for quick lookup
        node_map = {} of {Int32, Int32} => Node
        node_map[{start_node.x, start_node.y}] = start_node

        while !open_set.empty?
          # Get node with lowest f_cost
          current = open_set.min_by(&.f_cost)
          open_set.delete(current)
          closed_set.add(current)

          # Found the goal
          if current.x == end_node.x && current.y == end_node.y
            return reconstruct_path(current)
          end

          # Check neighbors
          neighbors = get_neighbors(current)
          neighbors.each do |neighbor_pos|
            next unless @grid.is_walkable?(neighbor_pos[0], neighbor_pos[1])

            neighbor = node_map[neighbor_pos]? || Node.new(neighbor_pos[0], neighbor_pos[1])
            node_map[neighbor_pos] = neighbor

            next if closed_set.includes?(neighbor)

            # Calculate tentative g_cost
            tentative_g = current.g_cost + distance(current, neighbor)

            if !open_set.includes?(neighbor) || tentative_g < neighbor.g_cost
              neighbor.parent = current
              neighbor.g_cost = tentative_g
              neighbor.h_cost = heuristic(neighbor, end_node)

              if !open_set.includes?(neighbor)
                open_set.add(neighbor)
              end
            end
          end
        end

        nil # No path found
      end

      # Get walkable neighbors
      private def get_neighbors(node : Node) : Array({Int32, Int32})
        neighbors = [] of {Int32, Int32}

        # Cardinal directions
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

      # Heuristic function (Euclidean distance)
      private def heuristic(a : Node, b : Node) : Float32
        dx = (a.x - b.x).abs
        dy = (a.y - b.y).abs

        if @allow_diagonal
          # Euclidean distance
          Math.sqrt(dx * dx + dy * dy).to_f32
        else
          # Manhattan distance
          (dx + dy).to_f32
        end
      end

      # Distance between adjacent nodes
      private def distance(a : Node, b : Node) : Float32
        dx = (a.x - b.x).abs
        dy = (a.y - b.y).abs

        if dx == 1 && dy == 1
          Math.sqrt(2.0).to_f32 # Diagonal movement
        else
          1.0f32 # Cardinal movement
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
        smooth_path(path)
      end

      # Simple path smoothing
      private def smooth_path(path : Array(Raylib::Vector2)) : Array(Raylib::Vector2)
        return path if path.size < 3

        smoothed = [path[0]]
        i = 0

        while i < path.size - 1
          j = i + 2

          # Try to skip nodes if there's a direct line of sight
          while j < path.size
            if has_line_of_sight(path[i], path[j])
              j += 1
            else
              break
            end
          end

          smoothed << path[j - 1]
          i = j - 1
        end

        smoothed
      end

      # Check if there's a clear line of sight between two points
      private def has_line_of_sight(start : Raylib::Vector2, target : Raylib::Vector2) : Bool
        x0 = (start.x / @grid.cell_size).to_i
        y0 = (start.y / @grid.cell_size).to_i
        x1 = (target.x / @grid.cell_size).to_i
        y1 = (target.y / @grid.cell_size).to_i

        dx = (x1 - x0).abs
        dy = (y1 - y0).abs
        sx = x0 < x1 ? 1 : -1
        sy = y0 < y1 ? 1 : -1
        err = dx - dy

        while true
          return false unless @grid.is_walkable?(x0, y0)

          break if x0 == x1 && y0 == y1

          e2 = 2 * err
          if e2 > -dy
            err -= dy
            x0 += sx
          end
          if e2 < dx
            err += dx
            y0 += sy
          end
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
