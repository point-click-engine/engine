require "./node"
require "./navigation_grid"
require "./heuristic_calculator"
require "./movement_validator"
require "./astar_algorithm"
require "./path_optimizer"
require "./pathfinding_debug_renderer"

module PointClickEngine
  module Navigation
    # Refactored pathfinding system using extracted components
    #
    # This refactored Pathfinding class delegates responsibilities to specialized components:
    # - NavigationGrid: Grid management and walkable areas
    # - AStarAlgorithm: Core A* pathfinding implementation
    # - PathOptimizer: Path smoothing and optimization
    # - HeuristicCalculator: Distance calculation strategies
    # - MovementValidator: Movement rules and validation
    # - PathfindingDebugRenderer: Debug visualization
    class RefactoredPathfinding
      # Core components
      property grid : NavigationGrid
      property algorithm : AStarAlgorithm
      property optimizer : PathOptimizer
      property debug_renderer : PathfindingDebugRenderer

      # Pathfinding settings
      property optimize_paths : Bool = true
      property enable_debug : Bool = false

      def initialize(@grid : NavigationGrid,
                     heuristic_calculator : HeuristicCalculator? = nil,
                     movement_validator : MovementValidator? = nil)
        # Use provided components or create defaults
        heuristic = heuristic_calculator || HeuristicCalculator.for_point_and_click
        movement = movement_validator || MovementValidator.for_point_and_click

        @algorithm = AStarAlgorithm.new(@grid, heuristic, movement)
        @optimizer = PathOptimizer.new(@grid)
        @debug_renderer = PathfindingDebugRenderer.new(@grid)
      end

      # Finds an optimal path between two world positions
      def find_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Array(RL::Vector2)?
        # Use A* algorithm to find raw path
        raw_path = @algorithm.find_path(start_x, start_y, end_x, end_y)
        return nil unless raw_path

        # Optimize path if enabled
        if @optimize_paths && raw_path.size > 2
          @optimizer.optimize_path(raw_path)
        else
          raw_path
        end
      end

      # Finds path using Vector2 positions
      def find_path(start_pos : RL::Vector2, end_pos : RL::Vector2) : Array(RL::Vector2)?
        find_path(start_pos.x, start_pos.y, end_pos.x, end_pos.y)
      end

      # Finds path with specific optimization level
      def find_path_with_optimization(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32, optimization : Symbol = :normal) : Array(RL::Vector2)?
        raw_path = @algorithm.find_path(start_x, start_y, end_x, end_y)
        return nil unless raw_path
        return raw_path if raw_path.size <= 2

        case optimization
        when :none
          raw_path
        when :conservative
          @optimizer.conservative_optimize(raw_path)
        when :normal
          @optimizer.optimize_path(raw_path)
        when :aggressive
          @optimizer.aggressive_optimize(raw_path)
        when :smooth
          optimized = @optimizer.optimize_path(raw_path)
          @optimizer.smooth_path(optimized)
        else
          @optimizer.optimize_path(raw_path)
        end
      end

      # Finds partial path when full path is not available
      def find_partial_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32, max_distance : Float32 = 100.0f32) : Array(RL::Vector2)?
        raw_path = @algorithm.find_partial_path(start_x, start_y, end_x, end_y, max_distance)
        return nil unless raw_path

        if @optimize_paths && raw_path.size > 2
          @optimizer.optimize_path(raw_path)
        else
          raw_path
        end
      end

      # Checks if a path exists without returning the full path
      def path_exists?(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Bool
        @algorithm.path_exists?(start_x, start_y, end_x, end_y)
      end

      # Checks if a path exists using Vector2 positions
      def path_exists?(start_pos : RL::Vector2, end_pos : RL::Vector2) : Bool
        path_exists?(start_pos.x, start_pos.y, end_pos.x, end_pos.y)
      end

      # Validates if an existing path is still walkable
      def is_path_valid?(path : Array(RL::Vector2)) : Bool
        @optimizer.is_path_valid?(path)
      end

      # Gets the movement validator for external configuration
      def get_movement_validator : MovementValidator
        @algorithm.movement_validator
      end

      # Gets the heuristic calculator for external configuration
      def get_heuristic_calculator : HeuristicCalculator
        @algorithm.heuristic_calculator
      end

      # Updates pathfinding settings
      def configure(allow_diagonal : Bool? = nil,
                    prevent_corner_cutting : Bool? = nil,
                    heuristic_method : HeuristicCalculator::Method? = nil,
                    max_search_nodes : Int32? = nil)
        if allow_diagonal
          @algorithm.movement_validator.allow_diagonal = allow_diagonal.not_nil!
        end

        if prevent_corner_cutting
          @algorithm.movement_validator.prevent_corner_cutting = prevent_corner_cutting.not_nil!
        end

        if heuristic_method
          @algorithm.heuristic_calculator.method = heuristic_method.not_nil!
        end

        if max_search_nodes
          @algorithm.max_search_nodes = max_search_nodes.not_nil!
        end
      end

      # Gets pathfinding statistics from last operation
      def get_stats : Hash(String, Float64 | Int32 | Bool)
        stats = @algorithm.get_search_stats
        stats["optimization_enabled"] = @optimize_paths
        stats["debug_enabled"] = @enable_debug
        stats["grid_size"] = @grid.width * @grid.height
        stats["walkable_percentage"] = @grid.walkable_percentage.to_f64
        stats
      end

      # Calculates approximate path cost without finding full path
      def estimate_path_cost(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Float32
        @algorithm.estimate_path_cost(start_x, start_y, end_x, end_y)
      end

      # Calculates actual path length
      def calculate_path_length(path : Array(RL::Vector2)) : Float32
        @optimizer.calculate_path_length(path)
      end

      # Finds closest point on path to a given position
      def find_closest_point_on_path(path : Array(RL::Vector2), position : RL::Vector2) : {point: RL::Vector2, index: Int32, distance: Float32}
        @optimizer.find_closest_point_on_path(path, position)
      end

      # Debug rendering methods
      def draw_grid(color_walkable : RL::Color = RL::GREEN, color_blocked : RL::Color = RL::RED, alpha : UInt8 = 100u8)
        return unless @enable_debug
        @debug_renderer.draw_grid(color_walkable, color_blocked, alpha)
      end

      def draw_path(path : Array(RL::Vector2), color : RL::Color = RL::YELLOW, thickness : Float32 = 3.0f32)
        return unless @enable_debug
        @debug_renderer.draw_path(path, color, thickness)
      end

      def draw_character_info(character_pos : RL::Vector2, target_pos : RL::Vector2? = nil)
        return unless @enable_debug
        @debug_renderer.draw_character_info(character_pos, target_pos)
      end

      def draw_grid_stats(x : Int32 = 10, y : Int32 = 10)
        return unless @enable_debug
        @debug_renderer.draw_grid_stats(x, y)
      end

      def draw_performance_info(x : Int32, y : Int32, path_length : Float32)
        return unless @enable_debug
        stats = @algorithm.get_search_stats
        @debug_renderer.draw_performance_info(
          x, y,
          stats["search_time_ms"].as(Float64) / 1000,
          stats["nodes_searched"].as(Int32),
          path_length
        )
      end

      # Enables debug rendering
      def enable_debug
        @enable_debug = true
        @debug_renderer.enable
      end

      # Disables debug rendering
      def disable_debug
        @enable_debug = false
        @debug_renderer.disable
      end

      # Toggles debug rendering
      def toggle_debug
        @enable_debug = !@enable_debug
        @debug_renderer.toggle
      end

      # Validates entire pathfinding system
      def validate_system : Array(String)
        issues = [] of String

        # Validate algorithm configuration
        issues.concat(@algorithm.validate_configuration)

        # Validate grid state
        if @grid.walkable_cell_count == 0
          issues << "Navigation grid has no walkable cells"
        end

        if @grid.walkable_percentage < 10.0
          issues << "Navigation grid has very few walkable cells (#{@grid.walkable_percentage.round(1)}%)"
        end

        # Validate component consistency
        movement_validator = @algorithm.movement_validator
        heuristic_calculator = @algorithm.heuristic_calculator

        unless heuristic_calculator.is_admissible?(movement_validator.allow_diagonal)
          issues << "Heuristic may not be admissible for current movement settings"
        end

        issues
      end

      # Optimizes pathfinding performance for the current grid
      def optimize_performance
        # Adjust max search nodes based on grid size
        grid_size = @grid.width * @grid.height

        if grid_size < 1000
          @algorithm.max_search_nodes = 5000
        elsif grid_size < 10000
          @algorithm.max_search_nodes = 10000
        else
          @algorithm.max_search_nodes = 20000
        end

        # Adjust optimizer settings based on grid density
        walkable_percentage = @grid.walkable_percentage

        if walkable_percentage > 80.0
          # Dense grids can handle more aggressive optimization
          @optimizer.max_lookahead = 10
        elsif walkable_percentage > 50.0
          @optimizer.max_lookahead = 6
        else
          # Sparse grids need conservative optimization
          @optimizer.max_lookahead = 4
        end
      end

      # Creates pathfinding system with optimal settings for different game types
      def self.for_point_and_click(grid : NavigationGrid) : RefactoredPathfinding
        heuristic = HeuristicCalculator.for_point_and_click
        movement = MovementValidator.for_point_and_click

        pathfinding = new(grid, heuristic, movement)
        pathfinding.optimize_paths = true
        pathfinding
      end

      def self.for_grid_based(grid : NavigationGrid) : RefactoredPathfinding
        heuristic = HeuristicCalculator.new(HeuristicCalculator::Method::Manhattan)
        movement = MovementValidator.for_grid_based

        pathfinding = new(grid, heuristic, movement)
        pathfinding.optimize_paths = false # Grid-based games often need exact paths
        pathfinding
      end

      def self.for_strategy(grid : NavigationGrid) : RefactoredPathfinding
        heuristic = HeuristicCalculator.for_strategy
        movement = MovementValidator.for_strategy

        pathfinding = new(grid, heuristic, movement)
        pathfinding.optimize_paths = true
        pathfinding
      end

      # String representation
      def to_s(io : IO) : Nil
        io << "RefactoredPathfinding(grid: #{@grid.width}x#{@grid.height}, optimization: #{@optimize_paths}, debug: #{@enable_debug})"
      end
    end
  end
end
