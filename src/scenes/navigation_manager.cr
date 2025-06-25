require "../navigation/pathfinding"

module PointClickEngine
  module Scenes
    # Manages navigation and pathfinding for a scene
    #
    # The NavigationManager handles all pathfinding-related functionality including:
    # - Navigation grid setup and management
    # - Pathfinding system initialization
    # - Path calculation between points
    # - Navigation debug visualization
    class NavigationManager
      # Navigation grid for pathfinding
      property navigation_grid : Navigation::NavigationGrid?

      # A* pathfinder instance
      property pathfinder : Navigation::AStarPathfinder?

      # Scene dimensions for navigation setup
      property scene_width : Int32
      property scene_height : Int32

      # Navigation grid cell size (default: 10 pixels per cell)
      property grid_cell_size : Int32 = 10

      def initialize(@scene_width : Int32, @scene_height : Int32)
      end

      # Sets up navigation grid and pathfinding system
      #
      # Creates a navigation grid based on scene dimensions and initializes
      # the A* pathfinder. Must be called before using pathfinding.
      #
      # - *walkable_area* : Optional walkable area for navigation constraints
      def setup_navigation(walkable_area : WalkableArea? = nil)
        # Calculate grid dimensions based on scene size and cell size
        grid_width = (@scene_width / @grid_cell_size).ceil.to_i
        grid_height = (@scene_height / @grid_cell_size).ceil.to_i

        # Create navigation grid
        @navigation_grid = Navigation::NavigationGrid.new(grid_width, grid_height, @grid_cell_size)

        # Mark walkable cells based on walkable area
        if nav_grid = @navigation_grid
          if walkable_area
            mark_walkable_cells(nav_grid, walkable_area)
          else
            # If no walkable area specified, mark entire grid as walkable
            mark_all_cells_walkable(nav_grid)
          end

          # Initialize pathfinder with the grid
          @pathfinder = Navigation::AStarPathfinder.new(nav_grid)
        end
      end

      # Finds a path between two points using A* pathfinding
      #
      # Returns an array of waypoints from start to end position, or nil if
      # no path exists. Coordinates are in world space.
      #
      # - *start_x* : Starting X coordinate in world space
      # - *start_y* : Starting Y coordinate in world space
      # - *end_x* : Target X coordinate in world space
      # - *end_y* : Target Y coordinate in world space
      #
      # Returns: Array of Vector2 waypoints, or nil if no path found
      def find_path(start_x : Int32, start_y : Int32, end_x : Int32, end_y : Int32) : Array(RL::Vector2)?
        return nil unless pathfinder = @pathfinder
        return nil unless nav_grid = @navigation_grid

        # Convert world coordinates to grid coordinates
        start_grid_x = (start_x / @grid_cell_size).to_i
        start_grid_y = (start_y / @grid_cell_size).to_i
        end_grid_x = (end_x / @grid_cell_size).to_i
        end_grid_y = (end_y / @grid_cell_size).to_i

        # Ensure coordinates are within grid bounds
        start_grid_x = start_grid_x.clamp(0, nav_grid.width - 1)
        start_grid_y = start_grid_y.clamp(0, nav_grid.height - 1)
        end_grid_x = end_grid_x.clamp(0, nav_grid.width - 1)
        end_grid_y = end_grid_y.clamp(0, nav_grid.height - 1)

        # Find path in grid coordinates
        grid_path = pathfinder.find_path(start_grid_x, start_grid_y, end_grid_x, end_grid_y)
        return nil unless grid_path

        # Convert grid path back to world coordinates
        world_path = [] of RL::Vector2
        grid_path.each do |node|
          world_x = node.x * @grid_cell_size + @grid_cell_size // 2
          world_y = node.y * @grid_cell_size + @grid_cell_size // 2
          world_path << RL::Vector2.new(x: world_x.to_f32, y: world_y.to_f32)
        end

        world_path
      end

      # Checks if a specific position is navigable
      #
      # - *x* : X coordinate in world space
      # - *y* : Y coordinate in world space
      #
      # Returns: true if the position can be navigated to
      def is_navigable?(x : Int32, y : Int32) : Bool
        return false unless nav_grid = @navigation_grid

        grid_x = (x / @grid_cell_size).to_i
        grid_y = (y / @grid_cell_size).to_i

        return false if grid_x < 0 || grid_x >= nav_grid.width
        return false if grid_y < 0 || grid_y >= nav_grid.height

        nav_grid.is_walkable?(grid_x, grid_y)
      end

      # Updates navigation grid based on scene changes
      #
      # Recalculates walkable cells when scene layout changes.
      # Should be called when walkable areas are modified.
      #
      # - *walkable_area* : Updated walkable area definition
      def update_navigation(walkable_area : WalkableArea? = nil)
        return unless nav_grid = @navigation_grid

        if walkable_area
          mark_walkable_cells(nav_grid, walkable_area)
        else
          mark_all_cells_walkable(nav_grid)
        end
      end

      # Draws debug visualization for navigation system
      #
      # Renders the navigation grid, showing walkable and blocked cells.
      # Only draws when debug mode is enabled.
      #
      # - *camera_offset* : Camera offset for proper positioning
      def draw_navigation_debug(camera_offset : RL::Vector2)
        return unless Core::Engine.debug_mode
        return unless nav_grid = @navigation_grid

        (0...nav_grid.width).each do |x|
          (0...nav_grid.height).each do |y|
            cell_world_x = x * @grid_cell_size
            cell_world_y = y * @grid_cell_size

            # Adjust for camera offset
            draw_x = cell_world_x - camera_offset.x.to_i
            draw_y = cell_world_y - camera_offset.y.to_i

            color = if nav_grid.is_walkable?(x, y)
                      RL::Color.new(r: 0, g: 255, b: 0, a: 50) # Green for walkable
                    else
                      RL::Color.new(r: 255, g: 0, b: 0, a: 50) # Red for blocked
                    end

            RL.draw_rectangle(draw_x, draw_y, @grid_cell_size, @grid_cell_size, color)
          end
        end

        # Draw grid lines
        (0..nav_grid.width).each do |x|
          line_x = x * @grid_cell_size - camera_offset.x.to_i
          RL.draw_line(line_x, -camera_offset.y.to_i, line_x, (@scene_height - camera_offset.y).to_i, RL::GRAY)
        end

        (0..nav_grid.height).each do |y|
          line_y = y * @grid_cell_size - camera_offset.y.to_i
          RL.draw_line(-camera_offset.x.to_i, line_y, (@scene_width - camera_offset.x).to_i, line_y, RL::GRAY)
        end
      end

      # Marks walkable cells in the navigation grid based on walkable area
      private def mark_walkable_cells(nav_grid : Navigation::NavigationGrid, walkable_area : WalkableArea)
        (0...nav_grid.width).each do |x|
          (0...nav_grid.height).each do |y|
            # Calculate center point of grid cell in world coordinates
            world_x = x * @grid_cell_size + @grid_cell_size // 2
            world_y = y * @grid_cell_size + @grid_cell_size // 2

            # Check if this world position is within the walkable area
            walkable = walkable_area.contains_point?(RL::Vector2.new(x: world_x.to_f32, y: world_y.to_f32))
            nav_grid.set_walkable(x, y, walkable)
          end
        end
      end

      # Marks all cells in the navigation grid as walkable
      private def mark_all_cells_walkable(nav_grid : Navigation::NavigationGrid)
        (0...nav_grid.width).each do |x|
          (0...nav_grid.height).each do |y|
            nav_grid.set_walkable(x, y, true)
          end
        end
      end

      # Gets navigation statistics for debugging
      def get_navigation_stats : Hash(String, Int32)
        stats = {} of String => Int32

        if nav_grid = @navigation_grid
          total_cells = nav_grid.width * nav_grid.height
          walkable_cells = 0

          (0...nav_grid.width).each do |x|
            (0...nav_grid.height).each do |y|
              walkable_cells += 1 if nav_grid.is_walkable?(x, y)
            end
          end

          stats["total_cells"] = total_cells
          stats["walkable_cells"] = walkable_cells
          stats["blocked_cells"] = total_cells - walkable_cells
          stats["grid_width"] = nav_grid.width
          stats["grid_height"] = nav_grid.height
          stats["cell_size"] = @grid_cell_size
        end

        stats
      end

      # Optimizes navigation grid by removing unnecessary nodes
      def optimize_navigation
        # Implementation could include:
        # - Removing isolated walkable cells
        # - Smoothing path waypoints
        # - Combining adjacent walkable regions
        # This is a placeholder for future optimization
      end

      # Exports navigation data for external tools
      def export_navigation_data : String
        return "" unless nav_grid = @navigation_grid

        data = {
          "width"          => nav_grid.width,
          "height"         => nav_grid.height,
          "cell_size"      => @grid_cell_size,
          "walkable_cells" => [] of Array(Int32),
        }

        (0...nav_grid.width).each do |x|
          (0...nav_grid.height).each do |y|
            if nav_grid.is_walkable?(x, y)
              data["walkable_cells"] << [x, y]
            end
          end
        end

        data.to_json
      end

      # Imports navigation data from external source
      def import_navigation_data(json_data : String)
        # Implementation for importing navigation data
        # This would be useful for editor integration
      end

      # Checks if navigation system is properly initialized
      def initialized? : Bool
        @navigation_grid != nil && @pathfinder != nil
      end

      # Clears navigation data and resets system
      def clear_navigation
        @navigation_grid = nil
        @pathfinder = nil
      end
    end
  end
end
