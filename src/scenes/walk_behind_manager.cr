# Walk-behind regions for depth sorting component

require "raylib-cr"

module PointClickEngine
  module Scenes
    # Manages walk-behind regions for proper depth sorting
    class WalkBehindManager
      @walk_behind_regions : Array(WalkBehindRegion)

      def initialize
        @walk_behind_regions = [] of WalkBehindRegion
      end

      # Add a walk-behind region
      def add_region(region : WalkBehindRegion) : Nil
        @walk_behind_regions << region
        # Sort by z_order to maintain proper rendering order
        @walk_behind_regions.sort_by! { |r| r.z_order }
      end

      # Get all walk-behind regions
      def regions : Array(WalkBehindRegion)
        @walk_behind_regions
      end

      # Clear all regions
      def clear : Nil
        @walk_behind_regions.clear
      end

      # Get walk-behind regions that should render in front of a character at given Y
      def get_regions_at_y(y : Float32) : Array(WalkBehindRegion)
        @walk_behind_regions.select { |region| y > region.y_threshold }
      end

      # Get walk-behind regions that a character is behind (character renders first)
      def get_regions_character_behind(y : Float32) : Array(WalkBehindRegion)
        @walk_behind_regions.select { |region| y <= region.y_threshold }
      end

      # Check if a point is within any walk-behind region
      def point_in_walk_behind?(point : RL::Vector2) : Bool
        detector = PolygonCollisionDetector.new
        @walk_behind_regions.any? do |region|
          detector.contains_point?(region.vertices, point)
        end
      end

      # Get the walk-behind region at a specific point
      def get_region_at_point(point : RL::Vector2) : WalkBehindRegion?
        detector = PolygonCollisionDetector.new
        @walk_behind_regions.find do |region|
          detector.contains_point?(region.vertices, point)
        end
      end

      # Sort regions by z-order
      def sort_by_z_order! : Nil
        @walk_behind_regions.sort_by! { |r| r.z_order }
      end

      # Get regions within a specific z-order range
      def get_regions_in_z_range(min_z : Int32, max_z : Int32) : Array(WalkBehindRegion)
        @walk_behind_regions.select do |region|
          region.z_order >= min_z && region.z_order <= max_z
        end
      end

      # Validate walk-behind regions
      def validate_regions : Array(String)
        errors = [] of String

        @walk_behind_regions.each_with_index do |region, i|
          # Check for empty vertices
          if region.vertices.empty?
            errors << "Walk-behind region '#{region.name}' (#{i}) has no vertices"
          elsif region.vertices.size < 3
            errors << "Walk-behind region '#{region.name}' (#{i}) has less than 3 vertices"
          end

          # Check for duplicate names
          duplicate_count = @walk_behind_regions.count { |r| r.name == region.name }
          if duplicate_count > 1
            errors << "Walk-behind region name '#{region.name}' is used #{duplicate_count} times"
          end
        end

        errors
      end
    end
  end
end
