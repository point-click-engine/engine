require "../core/game_constants"
require "./navigation_grid"

module PointClickEngine
  module Navigation
    # Debug visualization for pathfinding and navigation
    #
    # The PathfindingDebugRenderer provides visual debugging tools for
    # pathfinding algorithms, navigation grids, and character movement.
    # It should only be used during development and debugging.
    class PathfindingDebugRenderer
      property grid : NavigationGrid
      property enabled : Bool = false

      # Visual settings
      property grid_alpha : UInt8 = 100u8
      property path_thickness : Float32 = PointClickEngine::Core::GameConstants::DEBUG_PATH_LINE_THICKNESS
      property waypoint_radius : Float32 = PointClickEngine::Core::GameConstants::DEBUG_WAYPOINT_CIRCLE_RADIUS

      # Colors
      property walkable_color : RL::Color = RL::GREEN
      property blocked_color : RL::Color = RL::RED
      property path_color : RL::Color = RL::YELLOW
      property start_color : RL::Color = RL::BLUE
      property end_color : RL::Color = RL::PURPLE
      property visited_color : RL::Color = RL::ORANGE
      property open_color : RL::Color = RL::LIGHTGRAY

      def initialize(@grid : NavigationGrid)
      end

      # Draws the navigation grid
      def draw_grid(color_walkable : RL::Color = @walkable_color,
                    color_blocked : RL::Color = @blocked_color,
                    alpha : UInt8 = @grid_alpha)
        return unless @enabled

        (0...@grid.height).each do |y|
          (0...@grid.width).each do |x|
            world_pos = @grid.grid_to_world(x, y)
            color = @grid.is_walkable?(x, y) ? color_walkable : color_blocked
            color.a = alpha

            RL.draw_rectangle(
              (world_pos[0] - @grid.cell_size / 2).to_i,
              (world_pos[1] - @grid.cell_size / 2).to_i,
              @grid.cell_size,
              @grid.cell_size,
              color
            )
          end
        end
      end

      # Draws the navigation grid with outline
      def draw_grid_outlined(color_walkable : RL::Color = @walkable_color,
                             color_blocked : RL::Color = @blocked_color,
                             outline_color : RL::Color = RL::BLACK,
                             alpha : UInt8 = @grid_alpha)
        return unless @enabled

        (0...@grid.height).each do |y|
          (0...@grid.width).each do |x|
            world_pos = @grid.grid_to_world(x, y)
            color = @grid.is_walkable?(x, y) ? color_walkable : color_blocked
            color.a = alpha

            cell_x = (world_pos[0] - @grid.cell_size / 2).to_i
            cell_y = (world_pos[1] - @grid.cell_size / 2).to_i

            # Fill
            RL.draw_rectangle(cell_x, cell_y, @grid.cell_size, @grid.cell_size, color)

            # Outline
            RL.draw_rectangle_lines(cell_x, cell_y, @grid.cell_size, @grid.cell_size, outline_color)
          end
        end
      end

      # Draws a path with waypoints
      def draw_path(path : Array(RL::Vector2),
                    color : RL::Color = @path_color,
                    thickness : Float32 = @path_thickness)
        return unless @enabled
        return if path.size < 2

        # Draw path lines
        (0...path.size - 1).each do |i|
          RL.draw_line_ex(path[i], path[i + 1], thickness, color)
        end

        # Draw waypoints
        path.each_with_index do |point, index|
          if index == 0
            # Start point
            RL.draw_circle_v(point, @waypoint_radius * 1.5, @start_color)
          elsif index == path.size - 1
            # End point
            RL.draw_circle_v(point, @waypoint_radius * 1.5, @end_color)
          else
            # Intermediate waypoints
            RL.draw_circle_v(point, @waypoint_radius, color)
          end
        end
      end

      # Draws a simple path without waypoints
      def draw_path_simple(path : Array(RL::Vector2),
                           color : RL::Color = @path_color,
                           thickness : Float32 = @path_thickness)
        return unless @enabled
        return if path.size < 2

        (0...path.size - 1).each do |i|
          RL.draw_line_ex(path[i], path[i + 1], thickness, color)
        end
      end

      # Draws pathfinding algorithm state (visited and open nodes)
      def draw_algorithm_state(visited_nodes : Set(Tuple(Int32, Int32)),
                               open_nodes : Set(Tuple(Int32, Int32)),
                               alpha : UInt8 = 80u8)
        return unless @enabled

        # Draw visited nodes
        visited_color = @visited_color
        visited_color.a = alpha
        visited_nodes.each do |x, y|
          world_pos = @grid.grid_to_world(x, y)
          RL.draw_rectangle(
            (world_pos[0] - @grid.cell_size / 2).to_i,
            (world_pos[1] - @grid.cell_size / 2).to_i,
            @grid.cell_size,
            @grid.cell_size,
            visited_color
          )
        end

        # Draw open nodes
        open_color = @open_color
        open_color.a = alpha
        open_nodes.each do |x, y|
          world_pos = @grid.grid_to_world(x, y)
          RL.draw_rectangle(
            (world_pos[0] - @grid.cell_size / 2).to_i,
            (world_pos[1] - @grid.cell_size / 2).to_i,
            @grid.cell_size,
            @grid.cell_size,
            open_color
          )
        end
      end

      # Draws node costs for debugging
      def draw_node_costs(nodes : Hash(Tuple(Int32, Int32), Tuple(Float32, Float32, Float32)),
                          font_size : Int32 = 10)
        return unless @enabled

        nodes.each do |(x, y), (g_cost, h_cost, f_cost)|
          world_pos = @grid.grid_to_world(x, y)

          # Draw G cost (top-left)
          RL.draw_text(
            "G:#{g_cost.round(1)}",
            (world_pos[0] - @grid.cell_size / 2 + 2).to_i,
            (world_pos[1] - @grid.cell_size / 2 + 2).to_i,
            font_size,
            RL::WHITE
          )

          # Draw H cost (top-right)
          h_text = "H:#{h_cost.round(1)}"
          text_width = RL.measure_text(h_text, font_size)
          RL.draw_text(
            h_text,
            (world_pos[0] + @grid.cell_size / 2 - text_width - 2).to_i,
            (world_pos[1] - @grid.cell_size / 2 + 2).to_i,
            font_size,
            RL::WHITE
          )

          # Draw F cost (center)
          f_text = "F:#{f_cost.round(1)}"
          f_text_width = RL.measure_text(f_text, font_size)
          RL.draw_text(
            f_text,
            (world_pos[0] - f_text_width / 2).to_i,
            (world_pos[1] - font_size / 2).to_i,
            font_size,
            RL::YELLOW
          )
        end
      end

      # Draws character position and target
      def draw_character_info(character_pos : RL::Vector2,
                              target_pos : RL::Vector2? = nil,
                              character_radius : Float32 = 10.0f32)
        return unless @enabled

        # Draw character position
        RL.draw_circle_v(character_pos, character_radius, RL::BLUE)
        RL.draw_circle_lines_v(character_pos, character_radius, RL::DARKBLUE)

        # Draw target position if provided
        if target = target_pos
          RL.draw_circle_v(target, character_radius * 0.8, RL::RED)
          RL.draw_circle_lines_v(target, character_radius * 0.8, RL::DARKRED)

          # Draw line from character to target
          RL.draw_line_ex(character_pos, target, 2.0f32, RL::RED)
        end
      end

      # Draws grid coordinates for debugging
      def draw_grid_coordinates(font_size : Int32 = 8, spacing : Int32 = 4)
        return unless @enabled

        (0...@grid.height).step(spacing) do |y|
          (0...@grid.width).step(spacing) do |x|
            world_pos = @grid.grid_to_world(x, y)
            coord_text = "#{x},#{y}"
            text_width = RL.measure_text(coord_text, font_size)

            RL.draw_text(
              coord_text,
              (world_pos[0] - text_width / 2).to_i,
              (world_pos[1] - font_size / 2).to_i,
              font_size,
              RL::BLACK
            )
          end
        end
      end

      # Draws navigation grid statistics
      def draw_grid_stats(x : Int32 = 10, y : Int32 = 10, font_size : Int32 = 16)
        return unless @enabled

        stats = [
          "Grid Size: #{@grid.width}x#{@grid.height}",
          "Cell Size: #{@grid.cell_size}",
          "Walkable: #{@grid.walkable_percentage.round(1)}%",
          "Total Cells: #{@grid.width * @grid.height}",
          "Walkable Cells: #{@grid.walkable_cell_count}",
        ]

        stats.each_with_index do |stat, index|
          RL.draw_text(stat, x, y + index * (font_size + 2), font_size, RL::WHITE)
        end
      end

      # Draws pathfinding performance info
      def draw_performance_info(x : Int32, y : Int32,
                                search_time : Float64,
                                nodes_explored : Int32,
                                path_length : Float32,
                                font_size : Int32 = 16)
        return unless @enabled

        info = [
          "Search Time: #{(search_time * 1000).round(2)}ms",
          "Nodes Explored: #{nodes_explored}",
          "Path Length: #{path_length.round(2)}",
          "Nodes/sec: #{(nodes_explored / search_time).round(0)}",
        ]

        info.each_with_index do |line, index|
          RL.draw_text(line, x, y + index * (font_size + 2), font_size, RL::YELLOW)
        end
      end

      # Highlights specific grid cells
      def highlight_cells(cells : Array(Tuple(Int32, Int32)),
                          color : RL::Color = RL::MAGENTA,
                          alpha : UInt8 = 150u8)
        return unless @enabled

        highlight_color = color
        highlight_color.a = alpha

        cells.each do |x, y|
          next unless @grid.valid_grid_coords?(x, y)

          world_pos = @grid.grid_to_world(x, y)
          RL.draw_rectangle(
            (world_pos[0] - @grid.cell_size / 2).to_i,
            (world_pos[1] - @grid.cell_size / 2).to_i,
            @grid.cell_size,
            @grid.cell_size,
            highlight_color
          )
        end
      end

      # Draws directional arrows along path
      def draw_path_directions(path : Array(RL::Vector2),
                               arrow_size : Float32 = 5.0f32,
                               color : RL::Color = RL::GREEN)
        return unless @enabled
        return if path.size < 2

        (0...path.size - 1).each do |i|
          current = path[i]
          next_point = path[i + 1]

          # Calculate direction
          dx = next_point.x - current.x
          dy = next_point.y - current.y
          length = Math.sqrt(dx * dx + dy * dy)

          next if length == 0

          # Normalize direction
          dir_x = dx / length
          dir_y = dy / length

          # Calculate midpoint
          mid_x = current.x + dx * 0.5
          mid_y = current.y + dy * 0.5

          # Draw arrow
          arrow_tip = RL::Vector2.new(x: mid_x + dir_x * arrow_size, y: mid_y + dir_y * arrow_size)
          arrow_left = RL::Vector2.new(
            x: mid_x - dir_x * arrow_size - dir_y * arrow_size * 0.5,
            y: mid_y - dir_y * arrow_size + dir_x * arrow_size * 0.5
          )
          arrow_right = RL::Vector2.new(
            x: mid_x - dir_x * arrow_size + dir_y * arrow_size * 0.5,
            y: mid_y - dir_y * arrow_size - dir_x * arrow_size * 0.5
          )

          RL.draw_triangle(arrow_tip, arrow_left, arrow_right, color)
        end
      end

      # Enables debug rendering
      def enable
        @enabled = true
      end

      # Disables debug rendering
      def disable
        @enabled = false
      end

      # Toggles debug rendering
      def toggle
        @enabled = !@enabled
      end

      # String representation
      def to_s(io : IO) : Nil
        io << "PathfindingDebugRenderer(enabled: #{@enabled}, grid: #{@grid.width}x#{@grid.height})"
      end
    end
  end
end
