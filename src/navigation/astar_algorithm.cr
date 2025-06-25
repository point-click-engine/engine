require "../core/game_constants"
require "./node"
require "./navigation_grid"
require "./heuristic_calculator"
require "./movement_validator"

module PointClickEngine
  module Navigation
    # A* pathfinding algorithm implementation
    #
    # The AStarAlgorithm class provides a pure implementation of the A* pathfinding
    # algorithm. It uses a heuristic function to efficiently find optimal paths
    # through a navigation grid while supporting various movement constraints.
    class AStarAlgorithm
      property grid : NavigationGrid
      property heuristic_calculator : HeuristicCalculator
      property movement_validator : MovementValidator
      property max_search_nodes : Int32

      # Algorithm state for debugging
      property last_nodes_searched : Int32 = 0
      property last_search_time : Float64 = 0.0

      def initialize(@grid : NavigationGrid,
                     @heuristic_calculator : HeuristicCalculator = HeuristicCalculator.for_point_and_click,
                     @movement_validator : MovementValidator = MovementValidator.for_point_and_click,
                     @max_search_nodes : Int32 = PointClickEngine::Core::GameConstants::MAX_PATHFINDING_SEARCH_NODES)
      end

      # Finds a path using A* algorithm
      def find_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Array(RL::Vector2)?
        start_time = Time.monotonic

        # Input validation
        return nil unless @movement_validator.validate_pathfinding_input(@grid, start_x, start_y, end_x, end_y)

        start_grid = @grid.world_to_grid(start_x, start_y)
        end_grid = @grid.world_to_grid(end_x, end_y)

        # Only check if end is walkable - start position doesn't need to be walkable since we're already there
        return nil unless @grid.is_walkable?(end_grid[0], end_grid[1])

        # Special case: already at destination grid cell
        if start_grid[0] == end_grid[0] && start_grid[1] == end_grid[1]
          # If we're in the same grid cell but at different positions,
          # return direct path to exact target position
          start_pos = RL::Vector2.new(x: start_x, y: start_y)
          end_pos = RL::Vector2.new(x: end_x, y: end_y)
          distance = Math.sqrt((end_x - start_x)**2 + (end_y - start_y)**2)

          # Only return direct path if there's meaningful distance
          result = if distance > PointClickEngine::Core::GameConstants::SAME_CELL_DISTANCE_THRESHOLD
                     [start_pos, end_pos]
                   else
                     [end_pos]
                   end

          @last_search_time = (Time.monotonic - start_time).total_seconds
          @last_nodes_searched = 1
          return result
        end

        # Run A* algorithm
        result = execute_astar(start_grid, end_grid)

        @last_search_time = (Time.monotonic - start_time).total_seconds
        result
      end

      # Finds path between grid coordinates
      def find_path_grid(start_x : Int32, start_y : Int32, end_x : Int32, end_y : Int32) : Array(Node)?
        # Validate grid coordinates
        return nil unless @grid.valid_grid_coords?(start_x, start_y)
        return nil unless @grid.valid_grid_coords?(end_x, end_y)
        return nil unless @grid.is_walkable?(end_x, end_y)

        # Same position
        if start_x == end_x && start_y == end_y
          return [Node.new(end_x, end_y)]
        end

        execute_astar_nodes({start_x, start_y}, {end_x, end_y})
      end

      # Core A* algorithm implementation returning world coordinates
      private def execute_astar(start_grid : {Int32, Int32}, end_grid : {Int32, Int32}) : Array(RL::Vector2)?
        result_nodes = execute_astar_nodes(start_grid, end_grid)
        return nil unless result_nodes

        # Convert nodes to world coordinates
        result_nodes.map do |node|
          world_pos = @grid.grid_to_world(node.x, node.y)
          RL::Vector2.new(x: world_pos[0], y: world_pos[1])
        end
      end

      # Core A* algorithm implementation returning nodes
      private def execute_astar_nodes(start_grid : {Int32, Int32}, end_grid : {Int32, Int32}) : Array(Node)?
        # A* algorithm with priority queue
        open_list = [] of Node
        closed_set = Set({Int32, Int32}).new

        start_node = Node.new(start_grid[0], start_grid[1])
        end_node = Node.new(end_grid[0], end_grid[1])

        start_node.h_cost = @heuristic_calculator.calculate(start_node, end_node)
        open_list << start_node

        # Track best node for each position
        best_g_cost = {} of {Int32, Int32} => Float32
        best_g_cost[{start_node.x, start_node.y}] = 0.0f32

        @last_nodes_searched = 0

        while !open_list.empty? && @last_nodes_searched < @max_search_nodes
          @last_nodes_searched += 1

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
            return reconstruct_path_nodes(current)
          end

          # Check neighbors
          neighbors = @movement_validator.get_valid_neighbors(@grid, current.x, current.y)
          neighbors.each do |neighbor_x, neighbor_y|
            neighbor_pos = {neighbor_x, neighbor_y}
            next if closed_set.includes?(neighbor_pos)

            # Calculate tentative g_cost
            move_cost = @movement_validator.calculate_move_cost(current.x, current.y, neighbor_x, neighbor_y)
            tentative_g = current.g_cost + move_cost

            # Skip if we've already found a better path to this node
            if best_g_cost.has_key?(neighbor_pos) && tentative_g >= best_g_cost[neighbor_pos]
              next
            end

            # This path is better
            best_g_cost[neighbor_pos] = tentative_g

            # Find or create neighbor node
            neighbor = open_list.find { |n| n.x == neighbor_x && n.y == neighbor_y }

            if neighbor.nil?
              neighbor = Node.new(neighbor_x, neighbor_y)
              neighbor.g_cost = tentative_g
              neighbor.h_cost = @heuristic_calculator.calculate(neighbor, end_node)
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

      # Reconstructs path from end node to start node
      private def reconstruct_path_nodes(end_node : Node) : Array(Node)
        path = [] of Node
        current = end_node

        while current
          path << current
          current = current.parent
        end

        path.reverse!
      end

      # Finds partial path when full path is not available
      def find_partial_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32, max_distance : Float32 = 100.0f32) : Array(RL::Vector2)?
        start_grid = @grid.world_to_grid(start_x, start_y)
        end_grid = @grid.world_to_grid(end_x, end_y)

        # Run A* but find closest reachable point to target
        open_list = [] of Node
        closed_set = Set({Int32, Int32}).new

        start_node = Node.new(start_grid[0], start_grid[1])
        target_node = Node.new(end_grid[0], end_grid[1])

        start_node.h_cost = @heuristic_calculator.calculate(start_node, target_node)
        open_list << start_node

        best_g_cost = {} of {Int32, Int32} => Float32
        best_g_cost[{start_node.x, start_node.y}] = 0.0f32

        closest_node = start_node
        closest_distance = @heuristic_calculator.calculate(start_node, target_node)

        nodes_searched = 0

        while !open_list.empty? && nodes_searched < @max_search_nodes
          nodes_searched += 1

          # Get node with lowest f_cost
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

          # Update closest node
          distance_to_target = @heuristic_calculator.calculate(current, target_node)
          if distance_to_target < closest_distance
            closest_distance = distance_to_target
            closest_node = current
          end

          # Stop if we've traveled far enough
          if current.g_cost > max_distance
            break
          end

          # Check neighbors
          neighbors = @movement_validator.get_valid_neighbors(@grid, current.x, current.y)
          neighbors.each do |neighbor_x, neighbor_y|
            neighbor_pos = {neighbor_x, neighbor_y}
            next if closed_set.includes?(neighbor_pos)

            move_cost = @movement_validator.calculate_move_cost(current.x, current.y, neighbor_x, neighbor_y)
            tentative_g = current.g_cost + move_cost

            if best_g_cost.has_key?(neighbor_pos) && tentative_g >= best_g_cost[neighbor_pos]
              next
            end

            best_g_cost[neighbor_pos] = tentative_g

            neighbor = open_list.find { |n| n.x == neighbor_x && n.y == neighbor_y }

            if neighbor.nil?
              neighbor = Node.new(neighbor_x, neighbor_y)
              neighbor.g_cost = tentative_g
              neighbor.h_cost = @heuristic_calculator.calculate(neighbor, target_node)
              neighbor.parent = current
              open_list << neighbor
            elsif tentative_g < neighbor.g_cost
              neighbor.g_cost = tentative_g
              neighbor.parent = current
            end
          end
        end

        # Return path to closest reachable point
        path_nodes = reconstruct_path_nodes(closest_node)
        path_nodes.map do |node|
          world_pos = @grid.grid_to_world(node.x, node.y)
          RL::Vector2.new(x: world_pos[0], y: world_pos[1])
        end
      end

      # Checks if a path exists without returning the full path
      def path_exists?(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Bool
        !find_path(start_x, start_y, end_x, end_y).nil?
      end

      # Gets search statistics from last pathfinding operation
      def get_search_stats : Hash(String, Float64 | Int32)
        {
          "nodes_searched"   => @last_nodes_searched,
          "search_time_ms"   => @last_search_time * 1000,
          "nodes_per_second" => @last_search_time > 0 ? (@last_nodes_searched / @last_search_time).to_i : 0,
          "max_nodes"        => @max_search_nodes,
        }
      end

      # Estimates the cost of a path without finding it
      def estimate_path_cost(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Float32
        start_grid = @grid.world_to_grid(start_x, start_y)
        end_grid = @grid.world_to_grid(end_x, end_y)

        start_node = Node.new(start_grid[0], start_grid[1])
        end_node = Node.new(end_grid[0], end_grid[1])

        @heuristic_calculator.calculate(start_node, end_node)
      end

      # Validates algorithm configuration
      def validate_configuration : Array(String)
        issues = [] of String

        if @max_search_nodes <= 0
          issues << "Max search nodes must be positive"
        end

        if @max_search_nodes > 100000
          issues << "Max search nodes is very high, may cause performance issues"
        end

        issues.concat(@heuristic_calculator.validate_configuration(@movement_validator.allow_diagonal))
        issues.concat(@movement_validator.validate_configuration)

        issues
      end

      # Creates A* algorithm with optimal settings for different game types
      def self.for_point_and_click(grid : NavigationGrid) : AStarAlgorithm
        heuristic = HeuristicCalculator.for_point_and_click
        movement = MovementValidator.for_point_and_click
        new(grid, heuristic, movement)
      end

      def self.for_grid_based(grid : NavigationGrid) : AStarAlgorithm
        heuristic = HeuristicCalculator.new(HeuristicCalculator::Method::Manhattan)
        movement = MovementValidator.for_grid_based
        new(grid, heuristic, movement)
      end

      def self.for_strategy(grid : NavigationGrid) : AStarAlgorithm
        heuristic = HeuristicCalculator.for_strategy
        movement = MovementValidator.for_strategy
        new(grid, heuristic, movement)
      end

      # String representation
      def to_s(io : IO) : Nil
        io << "AStarAlgorithm(grid: #{@grid.width}x#{@grid.height}, max_nodes: #{@max_search_nodes})"
      end
    end
  end
end
