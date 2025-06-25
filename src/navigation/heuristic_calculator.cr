require "../core/game_constants"
require "./node"

module PointClickEngine
  module Navigation
    # Heuristic calculation strategies for pathfinding algorithms
    #
    # The HeuristicCalculator provides different distance calculation methods
    # for use with pathfinding algorithms like A*. Different heuristics are
    # suitable for different movement types and game requirements.
    class HeuristicCalculator
      # Available heuristic calculation methods
      enum Method
        Manhattan # Only orthogonal movement (L1 norm)
        Euclidean # Direct distance (L2 norm)
        Octile    # Diagonal movement with cost (D1 + (D2-D1) * min(dx,dy))
        Chebyshev # Diagonal movement same cost as orthogonal (L∞ norm)
      end

      property method : Method
      property diagonal_cost : Float32
      property orthogonal_cost : Float32

      def initialize(@method : Method = Method::Octile, @diagonal_cost : Float32 = PointClickEngine::Core::GameConstants::HEURISTIC_DIAGONAL_MULTIPLIER, @orthogonal_cost : Float32 = 1.0f32)
      end

      # Calculates heuristic distance between two nodes
      def calculate(from : Node, to : Node) : Float32
        dx = (from.x - to.x).abs.to_f32
        dy = (from.y - to.y).abs.to_f32

        case @method
        when .manhattan?
          manhattan_distance(dx, dy)
        when .euclidean?
          euclidean_distance(dx, dy)
        when .octile?
          octile_distance(dx, dy)
        when .chebyshev?
          chebyshev_distance(dx, dy)
        else
          manhattan_distance(dx, dy)
        end
      end

      # Calculates heuristic distance between grid coordinates
      def calculate(from_x : Int32, from_y : Int32, to_x : Int32, to_y : Int32) : Float32
        dx = (from_x - to_x).abs.to_f32
        dy = (from_y - to_y).abs.to_f32

        case @method
        when .manhattan?
          manhattan_distance(dx, dy)
        when .euclidean?
          euclidean_distance(dx, dy)
        when .octile?
          octile_distance(dx, dy)
        when .chebyshev?
          chebyshev_distance(dx, dy)
        else
          manhattan_distance(dx, dy)
        end
      end

      # Manhattan distance (L1 norm) - only orthogonal movement
      # Best for grid-based movement without diagonals
      private def manhattan_distance(dx : Float32, dy : Float32) : Float32
        (dx + dy) * @orthogonal_cost
      end

      # Euclidean distance (L2 norm) - direct line distance
      # Best for free movement in any direction
      private def euclidean_distance(dx : Float32, dy : Float32) : Float32
        Math.sqrt(dx * dx + dy * dy).to_f32 * @orthogonal_cost
      end

      # Octile distance - diagonal movement with different cost
      # Best for grid-based movement with diagonals
      # Formula: D1 * (dx + dy) + (D2 - 2 * D1) * min(dx, dy)
      # Where D1 = orthogonal cost, D2 = diagonal cost
      private def octile_distance(dx : Float32, dy : Float32) : Float32
        d_min = Math.min(dx, dy)
        d_max = Math.max(dx, dy)
        @diagonal_cost * d_min + @orthogonal_cost * (d_max - d_min)
      end

      # Chebyshev distance (L∞ norm) - diagonal movement same cost as orthogonal
      # Best for grid movement where diagonal movement has same cost
      private def chebyshev_distance(dx : Float32, dy : Float32) : Float32
        Math.max(dx, dy) * @orthogonal_cost
      end

      # Gets the movement cost for traveling between two adjacent nodes
      def movement_cost(from : Node, to : Node) : Float32
        dx = (from.x - to.x).abs
        dy = (from.y - to.y).abs

        # Check if movement is diagonal
        if dx == 1 && dy == 1
          @diagonal_cost
        elsif (dx == 1 && dy == 0) || (dx == 0 && dy == 1)
          @orthogonal_cost
        else
          # Non-adjacent nodes - use heuristic
          calculate(from, to)
        end
      end

      # Validates if the heuristic is admissible (never overestimates)
      def is_admissible?(allow_diagonal : Bool) : Bool
        case @method
        when .manhattan?
          !allow_diagonal || @orthogonal_cost <= @diagonal_cost
        when .euclidean?
          # Euclidean is always admissible for any movement
          true
        when .octile?
          # Octile is admissible if diagonal cost is accurate
          @diagonal_cost >= @orthogonal_cost * Math.sqrt(2)
        when .chebyshev?
          # Chebyshev can overestimate for orthogonal-only movement
          allow_diagonal
        else
          true
        end
      end

      # Gets the ideal heuristic method for given movement constraints
      def self.optimal_method(allow_diagonal : Bool, equal_costs : Bool = false) : Method
        if allow_diagonal
          equal_costs ? Method::Chebyshev : Method::Octile
        else
          Method::Manhattan
        end
      end

      # Creates calculator with optimal settings for movement type
      def self.for_movement(allow_diagonal : Bool, equal_costs : Bool = false) : HeuristicCalculator
        method = optimal_method(allow_diagonal, equal_costs)
        new(method)
      end

      # Creates calculator for specific game type
      def self.for_point_and_click : HeuristicCalculator
        # Point and click games typically allow diagonal movement
        # with appropriate cost scaling
        new(Method::Octile)
      end

      # Creates calculator for platformer games
      def self.for_platformer : HeuristicCalculator
        # Platformers typically use Manhattan distance
        new(Method::Manhattan)
      end

      # Creates calculator for strategy games
      def self.for_strategy : HeuristicCalculator
        # Strategy games often use Chebyshev for equal movement costs
        new(Method::Chebyshev)
      end

      # Benchmarks different heuristic methods
      def self.benchmark(iterations : Int32 = 10000) : Hash(Method, Float64)
        results = {} of Method => Float64
        nodes = Array.new(iterations) { |i| Node.new(i % 100, i / 100) }
        target = Node.new(50, 50)

        Method.each do |method|
          calculator = new(method)
          start_time = Time.monotonic

          nodes.each do |node|
            calculator.calculate(node, target)
          end

          end_time = Time.monotonic
          results[method] = (end_time - start_time).total_seconds
        end

        results
      end

      # String representation
      def to_s(io : IO) : Nil
        io << "HeuristicCalculator(#{@method}, orthogonal: #{@orthogonal_cost}, diagonal: #{@diagonal_cost})"
      end
    end
  end
end
