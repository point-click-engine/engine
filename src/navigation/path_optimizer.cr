require "../core/game_constants"
require "./navigation_grid"

module PointClickEngine
  module Navigation
    # Optimizes paths by removing redundant waypoints and smoothing
    #
    # The PathOptimizer improves pathfinding results by removing unnecessary
    # intermediate points while maintaining path validity. It uses line-of-sight
    # checks to determine when waypoints can be safely removed.
    class PathOptimizer
      property grid : NavigationGrid
      property max_lookahead : Int32
      property midpoint_threshold : Int32
      property preserve_intermediate_points : Bool

      def initialize(@grid : NavigationGrid, @max_lookahead : Int32 = PointClickEngine::Core::GameConstants::PATH_OPTIMIZATION_MAX_LOOKAHEAD, @midpoint_threshold : Int32 = PointClickEngine::Core::GameConstants::PATH_MIDPOINT_INSERTION_THRESHOLD, @preserve_intermediate_points : Bool = true)
      end

      # Optimizes a path by removing redundant waypoints
      def optimize_path(path : Array(RL::Vector2)) : Array(RL::Vector2)
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
          max_lookahead_index = Math.min(i + @max_lookahead, path.size - 1)

          while j < path.size && j <= max_lookahead_index
            if has_clear_path(path[i], path[j])
              furthest = j
            else
              break # Stop at first obstacle
            end
            j += 1
          end

          # Always include at least some intermediate points for long paths
          if @preserve_intermediate_points && furthest == path.size - 1 &&
             path.size > @midpoint_threshold && optimized.size == 1
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

      # Aggressively optimizes path by removing as many points as possible
      def aggressive_optimize(path : Array(RL::Vector2)) : Array(RL::Vector2)
        return path if path.size < 3

        optimized = [path[0]]
        i = 0

        while i < path.size - 1
          # Look for the furthest reachable point without intermediate points
          furthest = i + 1

          (i + 2...path.size).each do |j|
            if has_clear_path(path[i], path[j])
              furthest = j
            else
              break
            end
          end

          optimized << path[furthest]
          i = furthest
        end

        optimized
      end

      # Conservative optimization that keeps more intermediate points
      def conservative_optimize(path : Array(RL::Vector2)) : Array(RL::Vector2)
        return path if path.size < 4

        optimized = [path[0]]
        i = 0

        while i < path.size - 1
          # Look ahead but with smaller steps
          furthest = i + 1
          max_step = Math.min(@max_lookahead / 2, 3)

          (i + 1..Math.min(i + max_step, path.size - 1)).each do |j|
            if has_clear_path(path[i], path[j])
              furthest = j
            else
              break
            end
          end

          optimized << path[furthest]
          i = furthest
        end

        optimized
      end

      # Smooths path using spline-like interpolation
      def smooth_path(path : Array(RL::Vector2), smoothing_factor : Float32 = 0.5f32) : Array(RL::Vector2)
        return path if path.size < 3

        smoothed = [path[0]]

        (1...path.size - 1).each do |i|
          current = path[i]
          prev = path[i - 1]
          next_point = path[i + 1]

          # Calculate smoothed position
          smoothed_x = current.x + smoothing_factor * ((prev.x + next_point.x) / 2 - current.x)
          smoothed_y = current.y + smoothing_factor * ((prev.y + next_point.y) / 2 - current.y)

          smoothed_point = RL::Vector2.new(x: smoothed_x, y: smoothed_y)

          # Only use smoothed point if it's still walkable
          grid_pos = @grid.world_to_grid(smoothed_point.x, smoothed_point.y)
          if @grid.is_walkable?(grid_pos[0], grid_pos[1])
            smoothed << smoothed_point
          else
            smoothed << current
          end
        end

        smoothed << path.last
        smoothed
      end

      # Checks if there's a clear path between two points using Bresenham's line algorithm
      def has_clear_path(start : RL::Vector2, target : RL::Vector2) : Bool
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

      # Checks line of sight with sub-grid precision
      def has_clear_path_precise(start : RL::Vector2, target : RL::Vector2, samples : Int32 = 10) : Bool
        # Sample points along the line for more precise checking
        distance = Math.sqrt((target.x - start.x) ** 2 + (target.y - start.y) ** 2)

        if distance == 0
          return true
        end

        step_x = (target.x - start.x) / samples
        step_y = (target.y - start.y) / samples

        (0..samples).each do |i|
          sample_x = start.x + step_x * i
          sample_y = start.y + step_y * i

          grid_pos = @grid.world_to_grid(sample_x, sample_y)
          return false unless @grid.is_walkable?(grid_pos[0], grid_pos[1])
        end

        true
      end

      # Validates if a path is still walkable
      def is_path_valid?(path : Array(RL::Vector2)) : Bool
        return false if path.empty?

        path.each do |point|
          grid_pos = @grid.world_to_grid(point.x, point.y)
          return false unless @grid.is_walkable?(grid_pos[0], grid_pos[1])
        end

        # Check continuity between adjacent points
        (0...path.size - 1).each do |i|
          return false unless has_clear_path(path[i], path[i + 1])
        end

        true
      end

      # Calculates path length
      def calculate_path_length(path : Array(RL::Vector2)) : Float32
        return 0.0f32 if path.size < 2

        total_length = 0.0f32
        (0...path.size - 1).each do |i|
          current = path[i]
          next_point = path[i + 1]

          dx = next_point.x - current.x
          dy = next_point.y - current.y
          segment_length = Math.sqrt(dx * dx + dy * dy).to_f32

          total_length += segment_length
        end

        total_length
      end

      # Finds the closest point on path to a given position
      def find_closest_point_on_path(path : Array(RL::Vector2), position : RL::Vector2) : {point: RL::Vector2, index: Int32, distance: Float32}
        return {point: path[0], index: 0, distance: 0.0f32} if path.size == 1

        closest_point = path[0]
        closest_index = 0
        min_distance = distance_to_point(position, path[0])

        (1...path.size).each do |i|
          distance = distance_to_point(position, path[i])
          if distance < min_distance
            min_distance = distance
            closest_point = path[i]
            closest_index = i
          end
        end

        {point: closest_point, index: closest_index, distance: min_distance}
      end

      # Inserts intermediate points for smoother movement
      def densify_path(path : Array(RL::Vector2), max_segment_length : Float32) : Array(RL::Vector2)
        return path if path.size < 2

        densified = [path[0]]

        (0...path.size - 1).each do |i|
          current = path[i]
          next_point = path[i + 1]

          dx = next_point.x - current.x
          dy = next_point.y - current.y
          segment_length = Math.sqrt(dx * dx + dy * dy).to_f32

          if segment_length > max_segment_length
            # Insert intermediate points
            num_segments = (segment_length / max_segment_length).ceil.to_i

            (1...num_segments).each do |j|
              t = j.to_f32 / num_segments
              interpolated_x = current.x + dx * t
              interpolated_y = current.y + dy * t

              densified << RL::Vector2.new(x: interpolated_x, y: interpolated_y)
            end
          end

          densified << next_point
        end

        densified
      end

      # Removes points that are too close together
      def simplify_path(path : Array(RL::Vector2), min_distance : Float32) : Array(RL::Vector2)
        return path if path.size < 2

        simplified = [path[0]]

        (1...path.size).each do |i|
          current = path[i]
          last_added = simplified.last

          distance = distance_to_point(current, last_added)

          # Always include the last point
          if i == path.size - 1 || distance >= min_distance
            simplified << current
          end
        end

        simplified
      end

      # Calculates distance between two points
      private def distance_to_point(p1 : RL::Vector2, p2 : RL::Vector2) : Float32
        dx = p1.x - p2.x
        dy = p1.y - p2.y
        Math.sqrt(dx * dx + dy * dy).to_f32
      end

      # Gets optimization statistics
      def get_optimization_stats(original : Array(RL::Vector2), optimized : Array(RL::Vector2)) : Hash(String, Float32)
        original_length = calculate_path_length(original)
        optimized_length = calculate_path_length(optimized)

        {
          "original_points"          => original.size.to_f32,
          "optimized_points"         => optimized.size.to_f32,
          "points_removed"           => (original.size - optimized.size).to_f32,
          "reduction_percentage"     => ((original.size - optimized.size).to_f32 / original.size * 100),
          "original_length"          => original_length,
          "optimized_length"         => optimized_length,
          "length_change_percentage" => ((optimized_length - original_length) / original_length * 100),
        }
      end

      # String representation
      def to_s(io : IO) : Nil
        io << "PathOptimizer(lookahead: #{@max_lookahead}, midpoint_threshold: #{@midpoint_threshold})"
      end
    end
  end
end
