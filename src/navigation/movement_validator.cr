require "../core/game_constants"
require "./node"
require "./navigation_grid"

module PointClickEngine
  module Navigation
    # Validates movement rules and calculates movement costs
    #
    # The MovementValidator handles validation of character movement
    # including diagonal movement rules, corner cutting prevention,
    # and movement cost calculations for pathfinding algorithms.
    class MovementValidator
      property allow_diagonal : Bool
      property prevent_corner_cutting : Bool
      property diagonal_cost : Float32
      property orthogonal_cost : Float32

      def initialize(@allow_diagonal : Bool = true, @prevent_corner_cutting : Bool = true, @diagonal_cost : Float32 = PointClickEngine::Core::GameConstants::DIAGONAL_MOVEMENT_COST, @orthogonal_cost : Float32 = PointClickEngine::Core::GameConstants::CARDINAL_MOVEMENT_COST)
      end

      # Validates if movement from one position to another is allowed
      def can_move?(grid : NavigationGrid, from_x : Int32, from_y : Int32, to_x : Int32, to_y : Int32) : Bool
        # Check if destination is walkable
        return false unless grid.is_walkable?(to_x, to_y)

        # Check if movement is within bounds
        return false unless grid.valid_grid_coords?(to_x, to_y)

        # Check if movement is valid distance (adjacent cells only)
        dx = (from_x - to_x).abs
        dy = (from_y - to_y).abs

        # Must be adjacent (including diagonals)
        return false unless dx <= 1 && dy <= 1

        # Can't move to same position
        return false if dx == 0 && dy == 0

        # Check diagonal movement rules
        if is_diagonal_move?(from_x, from_y, to_x, to_y)
          return false unless @allow_diagonal
          return false if @prevent_corner_cutting && !can_move_diagonally?(grid, from_x, from_y, to_x, to_y)
        end

        true
      end

      # Validates movement between nodes
      def can_move?(grid : NavigationGrid, from : Node, to : Node) : Bool
        can_move?(grid, from.x, from.y, to.x, to.y)
      end

      # Checks if movement is diagonal
      def is_diagonal_move?(from_x : Int32, from_y : Int32, to_x : Int32, to_y : Int32) : Bool
        dx = (from_x - to_x).abs
        dy = (from_y - to_y).abs
        dx == 1 && dy == 1
      end

      # Checks if movement between nodes is diagonal
      def is_diagonal_move?(from : Node, to : Node) : Bool
        is_diagonal_move?(from.x, from.y, to.x, to.y)
      end

      # Checks if diagonal movement is valid (prevents corner cutting)
      def can_move_diagonally?(grid : NavigationGrid, from_x : Int32, from_y : Int32, to_x : Int32, to_y : Int32) : Bool
        return true unless @prevent_corner_cutting

        # Check both adjacent cells to prevent corner cutting
        # For diagonal movement from (fx,fy) to (tx,ty), both (fx,ty) and (tx,fy) must be walkable
        grid.is_walkable?(from_x, to_y) && grid.is_walkable?(to_x, from_y)
      end

      # Calculates movement cost between two positions
      def calculate_move_cost(from_x : Int32, from_y : Int32, to_x : Int32, to_y : Int32) : Float32
        dx = (from_x - to_x).abs
        dy = (from_y - to_y).abs

        if dx == 1 && dy == 1
          @diagonal_cost
        elsif (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
          @orthogonal_cost
        else
          # Non-adjacent movement - should not happen in normal pathfinding
          Math.sqrt(dx * dx + dy * dy).to_f32 * @orthogonal_cost
        end
      end

      # Calculates movement cost between nodes
      def calculate_move_cost(from : Node, to : Node) : Float32
        calculate_move_cost(from.x, from.y, to.x, to.y)
      end

      # Gets all valid neighbor positions for a given position
      def get_valid_neighbors(grid : NavigationGrid, x : Int32, y : Int32) : Array({Int32, Int32})
        neighbors = [] of {Int32, Int32}

        # Cardinal directions (always check these first)
        cardinal_neighbors = [
          {x - 1, y}, # Left
          {x + 1, y}, # Right
          {x, y - 1}, # Up
          {x, y + 1}, # Down
        ]

        cardinal_neighbors.each do |nx, ny|
          if can_move?(grid, x, y, nx, ny)
            neighbors << {nx, ny}
          end
        end

        # Diagonal directions (if allowed)
        if @allow_diagonal
          diagonal_neighbors = [
            {x - 1, y - 1}, # Top-left
            {x + 1, y - 1}, # Top-right
            {x - 1, y + 1}, # Bottom-left
            {x + 1, y + 1}, # Bottom-right
          ]

          diagonal_neighbors.each do |nx, ny|
            if can_move?(grid, x, y, nx, ny)
              neighbors << {nx, ny}
            end
          end
        end

        neighbors
      end

      # Gets all valid neighbor nodes for a given node
      def get_valid_neighbors(grid : NavigationGrid, node : Node) : Array(Node)
        positions = get_valid_neighbors(grid, node.x, node.y)
        positions.map { |x, y| Node.new(x, y) }
      end

      # Validates pathfinding input parameters
      def validate_pathfinding_input(grid : NavigationGrid, start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Bool
        # Check if coordinates are within grid bounds
        return false unless grid.in_bounds?(start_x, start_y)
        return false unless grid.in_bounds?(end_x, end_y)

        # Convert to grid coordinates
        start_grid_x, start_grid_y = grid.world_to_grid(start_x, start_y)
        end_grid_x, end_grid_y = grid.world_to_grid(end_x, end_y)

        # Check if start and end positions are walkable
        return false unless grid.is_walkable?(start_grid_x, start_grid_y)
        return false unless grid.is_walkable?(end_grid_x, end_grid_y)

        # Same-cell movements are valid - the algorithm handles them
        # by returning a direct path from start to end
        true
      end

      # Validates if a complete path is still valid
      def is_path_valid?(grid : NavigationGrid, path : Array(RL::Vector2)) : Bool
        return false if path.empty?
        return true if path.size == 1

        # Check each segment of the path
        (0...path.size - 1).each do |i|
          current_pos = path[i]
          next_pos = path[i + 1]

          # Convert to grid coordinates
          current_x, current_y = grid.world_to_grid(current_pos.x, current_pos.y)
          next_x, next_y = grid.world_to_grid(next_pos.x, next_pos.y)

          # Check if movement is still valid
          unless can_move?(grid, current_x, current_y, next_x, next_y)
            return false
          end
        end

        true
      end

      # Gets movement type description
      def get_movement_type : String
        if @allow_diagonal
          if @prevent_corner_cutting
            "8-directional with corner cutting prevention"
          else
            "8-directional"
          end
        else
          "4-directional (orthogonal only)"
        end
      end

      # Validates movement configuration
      def validate_configuration : Array(String)
        issues = [] of String

        if @diagonal_cost <= 0
          issues << "Diagonal movement cost must be positive"
        end

        if @orthogonal_cost <= 0
          issues << "Orthogonal movement cost must be positive"
        end

        if @allow_diagonal && @diagonal_cost < @orthogonal_cost
          issues << "Diagonal movement cost should be greater than or equal to orthogonal cost"
        end

        if @allow_diagonal && @diagonal_cost < @orthogonal_cost * 1.4
          issues << "Diagonal movement cost may be too low (should be approximately sqrt(2) times orthogonal cost)"
        end

        issues
      end

      # Creates validator with optimal settings for point and click games
      def self.for_point_and_click : MovementValidator
        new(
          allow_diagonal: true,
          prevent_corner_cutting: true,
          diagonal_cost: PointClickEngine::Core::GameConstants::DIAGONAL_MOVEMENT_COST,
          orthogonal_cost: PointClickEngine::Core::GameConstants::CARDINAL_MOVEMENT_COST
        )
      end

      # Creates validator for grid-based games
      def self.for_grid_based : MovementValidator
        new(
          allow_diagonal: false,
          prevent_corner_cutting: true,
          diagonal_cost: 1.0f32,
          orthogonal_cost: 1.0f32
        )
      end

      # Creates validator for strategy games
      def self.for_strategy : MovementValidator
        new(
          allow_diagonal: true,
          prevent_corner_cutting: false,
          diagonal_cost: 1.0f32,
          orthogonal_cost: 1.0f32
        )
      end

      # String representation
      def to_s(io : IO) : Nil
        io << "MovementValidator(#{get_movement_type}, orthogonal: #{@orthogonal_cost}, diagonal: #{@diagonal_cost})"
      end
    end
  end
end
