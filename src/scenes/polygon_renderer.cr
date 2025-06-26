# Polygon rendering component for debug visualization

require "raylib-cr"

module PointClickEngine
  module Scenes
    # Handles polygon rendering for debug visualization
    class PolygonRenderer
      # Draw filled polygon using triangle fan method
      def draw_filled(vertices : Array(RL::Vector2), color : RL::Color) : Nil
        return if vertices.size < 3

        # Calculate center for triangle fan
        center = calculate_center(vertices)

        # Draw as triangle fan
        vertices.each_with_index do |vertex, i|
          next_vertex = vertices[(i + 1) % vertices.size]
          RL.draw_triangle(center, vertex, next_vertex, color)
        end
      end

      # Draw polygon outline
      def draw_outline(vertices : Array(RL::Vector2), color : RL::Color, thickness : Float32 = 1.0) : Nil
        return if vertices.size < 2

        vertices.each_with_index do |vertex, i|
          next_vertex = vertices[(i + 1) % vertices.size]
          RL.draw_line_ex(vertex, next_vertex, thickness, color)
        end
      end

      # Draw polygon with both fill and outline
      def draw_filled_with_outline(
        vertices : Array(RL::Vector2),
        fill_color : RL::Color,
        outline_color : RL::Color,
        outline_thickness : Float32 = 1.0,
      ) : Nil
        draw_filled(vertices, fill_color)
        draw_outline(vertices, outline_color, outline_thickness)
      end

      # Draw debug visualization for walkable regions
      def draw_walkable_debug(region : PolygonRegion) : Nil
        if region.walkable
          # Green for walkable
          fill_color = RL::Color.new(r: 0, g: 255, b: 0, a: 80)
          outline_color = RL::Color.new(r: 0, g: 255, b: 0, a: 255)
        else
          # Red for non-walkable
          fill_color = RL::Color.new(r: 255, g: 0, b: 0, a: 80)
          outline_color = RL::Color.new(r: 255, g: 0, b: 0, a: 255)
        end

        draw_filled_with_outline(region.vertices, fill_color, outline_color)
      end

      # Draw debug visualization for walk-behind regions
      def draw_walk_behind_debug(region : WalkBehindRegion) : Nil
        # Blue for walk-behind regions
        outline_color = RL::Color.new(r: 0, g: 100, b: 255, a: 255)
        draw_outline(region.vertices, outline_color, 2.0)

        # Draw Y threshold line
        if region.vertices.size > 0
          bounds = calculate_bounds(region.vertices)
          start_point = RL::Vector2.new(x: bounds.x, y: region.y_threshold)
          end_point = RL::Vector2.new(x: bounds.x + bounds.width, y: region.y_threshold)
          RL.draw_line_ex(start_point, end_point, 1.0, outline_color)
        end
      end

      # Draw scale zone visualization
      def draw_scale_zones(zones : Array(ScaleZone), screen_width : Int32) : Nil
        return if zones.empty?

        x = screen_width - 50

        zones.each do |zone|
          # Draw gradient bar
          steps = 20
          (0...steps).each do |i|
            t = i.to_f32 / (steps - 1)
            y = zone.min_y + t * (zone.max_y - zone.min_y)
            scale = zone.min_scale + t * (zone.max_scale - zone.min_scale)
            intensity = Math.min(255, (scale * 255).to_i).to_u8
            color = RL::Color.new(r: intensity, g: intensity, b: 0, a: 200)

            RL.draw_rectangle(x, y.to_i, 40, ((zone.max_y - zone.min_y) / steps).to_i + 1, color)
          end

          # Draw scale values
          RL.draw_text("#{zone.min_scale.round(1)}", x + 5, zone.min_y.to_i, 10, RL::WHITE)
          RL.draw_text("#{zone.max_scale.round(1)}", x + 5, zone.max_y.to_i - 10, 10, RL::WHITE)
        end
      end

      private def calculate_center(vertices : Array(RL::Vector2)) : RL::Vector2
        center = RL::Vector2.new(x: 0, y: 0)
        vertices.each do |vertex|
          center.x += vertex.x
          center.y += vertex.y
        end
        center.x /= vertices.size
        center.y /= vertices.size
        center
      end

      private def calculate_bounds(vertices : Array(RL::Vector2)) : RL::Rectangle
        collision_detector = PolygonCollisionDetector.new
        collision_detector.calculate_bounds(vertices)
      end
    end
  end
end
