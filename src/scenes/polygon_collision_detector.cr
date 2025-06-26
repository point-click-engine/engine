# Polygon collision detection component

require "raylib-cr"

module PointClickEngine
  module Scenes
    # Handles point-in-polygon collision detection
    class PolygonCollisionDetector
      # Check if a point is inside a polygon using ray casting algorithm
      def contains_point?(vertices : Array(RL::Vector2), point : RL::Vector2) : Bool
        return false if vertices.size < 3

        # Ray casting algorithm
        inside = false
        j = vertices.size - 1

        vertices.each_with_index do |vertex_i, i|
          vertex_j = vertices[j]

          if ((vertex_i.y > point.y) != (vertex_j.y > point.y)) &&
             (point.x < (vertex_j.x - vertex_i.x) * (point.y - vertex_i.y) / (vertex_j.y - vertex_i.y) + vertex_i.x)
            inside = !inside
          end

          j = i
        end

        inside
      end

      # Check if a point is within a rectangle (fast bounds check)
      def point_in_bounds?(point : RL::Vector2, bounds : RL::Rectangle) : Bool
        return false if bounds.width <= 0 || bounds.height <= 0
        RL.check_collision_point_rec?(point, bounds)
      end

      # Calculate bounding box for a set of vertices
      def calculate_bounds(vertices : Array(RL::Vector2)) : RL::Rectangle
        return RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0) if vertices.empty?

        min_x = vertices.first.x
        min_y = vertices.first.y
        max_x = vertices.first.x
        max_y = vertices.first.y

        vertices.each do |vertex|
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

      # Calculate bounding box for multiple polygons
      def calculate_combined_bounds(regions : Array(PolygonRegion)) : RL::Rectangle
        return RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0) if regions.empty?

        min_x = Float32::MAX
        min_y = Float32::MAX
        max_x = Float32::MIN
        max_y = Float32::MIN

        regions.each do |region|
          region.vertices.each do |vertex|
            min_x = vertex.x if vertex.x < min_x
            min_y = vertex.y if vertex.y < min_y
            max_x = vertex.x if vertex.x > max_x
            max_y = vertex.y if vertex.y > max_y
          end
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