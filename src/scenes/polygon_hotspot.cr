# Polygon-shaped hotspot implementation for precise click detection

require "raylib-cr"
require "yaml"
require "./hotspot"

module PointClickEngine
  module Scenes
    # Polygon-shaped clickable hotspot
    class PolygonHotspot < Hotspot
      property vertices : Array(RL::Vector2) = [] of RL::Vector2
      @cached_bounds : RL::Rectangle?

      def initialize
        super()
        @vertices = [] of RL::Vector2
      end

      def initialize(@name : String, vertices : Array(RL::Vector2))
        super()
        @vertices = vertices
        update_bounds
      end

      # Add a vertex to the polygon
      def add_vertex(point : RL::Vector2)
        @vertices << point
        @cached_bounds = nil
      end

      # Remove a vertex by index
      def remove_vertex(index : Int32)
        @vertices.delete_at(index) if index >= 0 && index < @vertices.size
        @cached_bounds = nil
      end

      # Get the bounding rectangle (cached for performance)
      def bounds : RL::Rectangle
        @cached_bounds ||= calculate_bounds
      end

      # Update the cached bounds
      def update_bounds
        @cached_bounds = calculate_bounds
      end

      # Check if a point is inside the polygon using ray casting algorithm
      def contains_point?(point : RL::Vector2) : Bool
        return false unless @active
        return false if @vertices.size < 3

        # Quick rejection using bounding box
        return false unless RL.check_collision_point_rec?(point, bounds)

        # Ray casting algorithm for point in polygon
        inside = false
        j = @vertices.size - 1

        @vertices.each_with_index do |vertex_i, i|
          vertex_j = @vertices[j]

          if ((vertex_i.y > point.y) != (vertex_j.y > point.y)) &&
             (point.x < (vertex_j.x - vertex_i.x) * (point.y - vertex_i.y) / (vertex_j.y - vertex_i.y) + vertex_i.x)
            inside = !inside
          end

          j = i
        end

        inside
      end

      # Get outline points for rendering
      def get_outline_points : Array(RL::Vector2)
        @vertices
      end

      # Draw the polygon hotspot
      def draw
        return unless @visible

        if Core::Engine.debug_mode && @vertices.size >= 3
          # Draw filled polygon in debug mode
          draw_polygon(@debug_color)

          # Draw outline
          outline_color = RL::Color.new(r: 255, g: 255, b: 255, a: 200)
          draw_polygon_outline(outline_color, 2)

          # Draw vertices as small squares
          @vertices.each do |vertex|
            RL.draw_rectangle(
              (vertex.x - 2).to_i,
              (vertex.y - 2).to_i,
              4, 4,
              RL::WHITE
            )
          end

          # Draw bounding box
          if Core::Engine.debug_mode
            RL.draw_rectangle_lines_ex(bounds, 1, RL::YELLOW)
          end
        end
      end

      # Draw filled polygon
      def draw_polygon(color : RL::Color)
        return if @vertices.size < 3

        # Use triangle fan rendering for convex polygons
        # For concave polygons, this might not render correctly
        # but it's good enough for most use cases
        center = calculate_center

        @vertices.each_with_index do |vertex, i|
          next_vertex = @vertices[(i + 1) % @vertices.size]
          RL.draw_triangle(center, vertex, next_vertex, color)
        end
      end

      # Draw polygon outline
      def draw_polygon_outline(color : RL::Color, thickness : Int32)
        return if @vertices.size < 2

        @vertices.each_with_index do |vertex, i|
          next_vertex = @vertices[(i + 1) % @vertices.size]
          RL.draw_line_ex(vertex, next_vertex, thickness.to_f32, color)
        end
      end

      # Calculate the center point of the polygon
      def calculate_center : RL::Vector2
        return RL::Vector2.new(x: 0, y: 0) if @vertices.empty?

        sum_x = 0f32
        sum_y = 0f32

        @vertices.each do |vertex|
          sum_x += vertex.x
          sum_y += vertex.y
        end

        RL::Vector2.new(
          x: sum_x / @vertices.size,
          y: sum_y / @vertices.size
        )
      end

      private def calculate_bounds : RL::Rectangle
        return RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0) if @vertices.empty?

        min_x = @vertices.first.x
        min_y = @vertices.first.y
        max_x = min_x
        max_y = min_y

        @vertices.each do |vertex|
          min_x = vertex.x if vertex.x < min_x
          min_y = vertex.y if vertex.y < min_y
          max_x = vertex.x if vertex.x > max_x
          max_y = vertex.y if vertex.y > max_y
        end

        RL::Rectangle.new(
          x: min_x,
          y: min_y,
          width: max_x - min_x,
          height: max_y - min_y
        )
      end
    end
  end
end
