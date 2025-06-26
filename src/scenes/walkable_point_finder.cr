# Component for finding walkable points in a scene

require "raylib-cr"

module PointClickEngine
  module Scenes
    # Finds walkable points and constrains movement to walkable areas
    class WalkablePointFinder
      @collision_detector : PolygonCollisionDetector

      def initialize
        @collision_detector = PolygonCollisionDetector.new
      end

      # Find the nearest walkable point to a target position
      def find_nearest_walkable_point(
        target : RL::Vector2,
        regions : Array(PolygonRegion),
        max_radius : Float32 = 200.0,
        step_radius : Float32 = 10.0,
        angle_steps : Int32 = 16
      ) : RL::Vector2
        # If the target is already walkable, return it
        return target if is_point_walkable?(target, regions)

        # Search in expanding circles to find the nearest walkable point
        (step_radius..max_radius).step(step_radius).each do |radius|
          (0...angle_steps).each do |i|
            angle = (i.to_f32 / angle_steps) * Math::TAU
            test_point = RL::Vector2.new(
              x: target.x + Math.cos(angle) * radius,
              y: target.y + Math.sin(angle) * radius
            )

            if is_point_walkable?(test_point, regions)
              return test_point
            end
          end
        end

        # If no walkable point found within radius, return original target
        # This shouldn't happen in a well-designed level
        target
      end

      # Constrain movement path to walkable area
      def constrain_to_walkable(
        from : RL::Vector2,
        to : RL::Vector2,
        regions : Array(PolygonRegion),
        sample_steps : Int32 = 10
      ) : RL::Vector2
        # If destination is walkable, return it
        return to if is_point_walkable?(to, regions)

        # Otherwise, find the closest walkable point along the line
        best_point = from

        (1..sample_steps).each do |i|
          t = i.to_f32 / sample_steps
          test_point = RL::Vector2.new(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t
          )

          if is_point_walkable?(test_point, regions)
            best_point = test_point
          else
            break
          end
        end

        best_point
      end

      # Check if a point is walkable based on regions
      private def is_point_walkable?(point : RL::Vector2, regions : Array(PolygonRegion)) : Bool
        # If no regions defined, assume walkable
        return true if regions.empty?

        # Check each region
        in_walkable = false
        in_non_walkable = false

        regions.each do |region|
          if @collision_detector.contains_point?(region.vertices, point)
            if region.walkable
              in_walkable = true
            else
              in_non_walkable = true
            end
          end
        end

        # Non-walkable regions take precedence
        return false if in_non_walkable

        # Otherwise, must be in a walkable region
        in_walkable
      end
    end
  end
end