# Walkable area system for defining where characters can move - Refactored with components

require "yaml"
require "./polygon_collision_detector"
require "./walkable_point_finder"
require "./scale_zone_manager"
require "./walk_behind_manager"
require "./polygon_renderer"

module PointClickEngine
  module Scenes
    # Manages walkable and non-walkable regions in a scene using component-based architecture
    #
    # This refactored WalkableArea class delegates responsibilities to specialized components:
    # - PolygonCollisionDetector: Point-in-polygon collision detection
    # - WalkablePointFinder: Finding and constraining movement to walkable areas
    # - ScaleZoneManager: Character scaling based on Y position
    # - WalkBehindManager: Depth sorting for walk-behind regions
    # - PolygonRenderer: Debug visualization
    class WalkableArea
      include YAML::Serializable

      getter regions : Array(PolygonRegion) = [] of PolygonRegion

      @[YAML::Field(ignore: true)]
      property bounds : RL::Rectangle = RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0)

      # Component managers
      @[YAML::Field(ignore: true)]
      @collision_detector : PolygonCollisionDetector = PolygonCollisionDetector.new

      @[YAML::Field(ignore: true)]
      @point_finder : WalkablePointFinder = WalkablePointFinder.new

      @[YAML::Field(ignore: true)]
      @scale_zone_manager : ScaleZoneManager = ScaleZoneManager.new

      @[YAML::Field(ignore: true)]
      @walk_behind_manager : WalkBehindManager = WalkBehindManager.new

      @[YAML::Field(ignore: true)]
      @polygon_renderer : PolygonRenderer = PolygonRenderer.new

      # Legacy property accessors for compatibility
      def walk_behind_regions : Array(WalkBehindRegion)
        @walk_behind_manager.regions
      end

      def walk_behind_regions=(value : Array(WalkBehindRegion))
        @walk_behind_manager.clear
        value.each { |region| @walk_behind_manager.add_region(region) }
      end

      def scale_zones : Array(ScaleZone)
        @scale_zone_manager.zones
      end

      def scale_zones=(value : Array(ScaleZone))
        @scale_zone_manager.clear
        value.each { |zone| @scale_zone_manager.add_zone(zone) }
      end

      # Custom setter for regions that updates bounds
      def regions=(value : Array(PolygonRegion))
        @regions = value
        update_bounds
      end

      def initialize
        @regions = [] of PolygonRegion
        @collision_detector = PolygonCollisionDetector.new
        @point_finder = WalkablePointFinder.new
        @scale_zone_manager = ScaleZoneManager.new
        @walk_behind_manager = WalkBehindManager.new
        @polygon_renderer = PolygonRenderer.new
      end

      # Check if a point is within a walkable area
      def is_point_walkable?(point : RL::Vector2) : Bool
        # If no regions defined, assume walkable
        return true if @regions.empty?

        # Quick bounds check
        if @bounds.width > 0 && @bounds.height > 0
          return false unless @collision_detector.point_in_bounds?(point, @bounds)
        end

        # Check each region
        in_walkable = false
        in_non_walkable = false

        @regions.each do |region|
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

      # Get character scale based on Y position (delegate to manager)
      def get_scale_at_y(y : Float32) : Float32
        @scale_zone_manager.get_scale_at_y(y)
      end

      # Get walk-behind regions that should render in front of a character at given Y
      def get_walk_behind_at_y(y : Float32) : Array(WalkBehindRegion)
        @walk_behind_manager.get_regions_at_y(y)
      end

      # Constrain movement to walkable area (delegate to finder)
      def constrain_to_walkable(from : RL::Vector2, to : RL::Vector2) : RL::Vector2
        @point_finder.constrain_to_walkable(from, to, @regions)
      end

      # Find the nearest walkable point to a given position (delegate to finder)
      def find_nearest_walkable_point(target : RL::Vector2) : RL::Vector2
        @point_finder.find_nearest_walkable_point(target, @regions)
      end

      # Update the overall bounds
      def update_bounds
        @bounds = @collision_detector.calculate_combined_bounds(@regions)
      end

      # Draw debug visualization
      def draw_debug
        # Draw walkable/non-walkable regions
        @regions.each do |region|
          @polygon_renderer.draw_walkable_debug(region)
        end

        # Draw walk-behind regions
        @walk_behind_manager.regions.each do |region|
          @polygon_renderer.draw_walk_behind_debug(region)
        end

        # Draw scale zones
        @polygon_renderer.draw_scale_zones(
          @scale_zone_manager.zones,
          RL.get_screen_width
        )
      end

      # Add a walkable/non-walkable region
      def add_region(region : PolygonRegion) : Nil
        @regions << region
        update_bounds
      end

      # Remove a region by name
      def remove_region(name : String) : Bool
        initial_size = @regions.size
        @regions.reject! { |r| r.name == name }
        if @regions.size < initial_size
          update_bounds
          true
        else
          false
        end
      end

      # Clear all regions
      def clear_regions : Nil
        @regions.clear
        @bounds = RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0)
      end

      # Add a scale zone
      def add_scale_zone(zone : ScaleZone) : Nil
        @scale_zone_manager.add_zone(zone)
      end

      # Add a walk-behind region
      def add_walk_behind(region : WalkBehindRegion) : Nil
        @walk_behind_manager.add_region(region)
      end

      # Validate the walkable area configuration
      def validate : Array(String)
        errors = [] of String

        # Validate scale zones
        errors.concat(@scale_zone_manager.validate_zones)

        # Validate walk-behind regions
        errors.concat(@walk_behind_manager.validate_regions)

        # Validate polygon regions
        @regions.each_with_index do |region, i|
          if region.vertices.empty?
            errors << "Region '#{region.name}' (#{i}) has no vertices"
          elsif region.vertices.size < 3
            errors << "Region '#{region.name}' (#{i}) has less than 3 vertices"
          end
        end

        errors
      end

      # Get statistics about the walkable area
      def get_stats : NamedTuple(
        region_count: Int32,
        walkable_count: Int32,
        obstacle_count: Int32,
        scale_zone_count: Int32,
        walk_behind_count: Int32,
        total_vertices: Int32
      )
        walkable_count = @regions.count(&.walkable)
        obstacle_count = @regions.size - walkable_count
        total_vertices = @regions.sum { |r| r.vertices.size }

        {
          region_count: @regions.size,
          walkable_count: walkable_count,
          obstacle_count: obstacle_count,
          scale_zone_count: @scale_zone_manager.zones.size,
          walk_behind_count: @walk_behind_manager.regions.size,
          total_vertices: total_vertices
        }
      end
    end

    # A polygon region that can be walkable or non-walkable
    class PolygonRegion
      include YAML::Serializable

      property name : String = ""
      property walkable : Bool = true
      property vertices : Array(RL::Vector2) = [] of RL::Vector2

      def initialize(@name : String = "", @walkable : Bool = true)
        @vertices = [] of RL::Vector2
      end

      # Legacy method - delegates to collision detector
      def contains_point?(point : RL::Vector2) : Bool
        detector = PolygonCollisionDetector.new
        detector.contains_point?(@vertices, point)
      end

      # Legacy method - delegates to renderer
      def draw_filled(color : RL::Color)
        renderer = PolygonRenderer.new
        renderer.draw_filled(@vertices, color)
      end

      # Legacy method - delegates to renderer
      def draw_outline(color : RL::Color, thickness : Int32)
        renderer = PolygonRenderer.new
        renderer.draw_outline(@vertices, color, thickness.to_f32)
      end
    end

    # Walk-behind region for depth sorting
    class WalkBehindRegion < PolygonRegion
      property y_threshold : Float32 = 0
      property z_order : Int32 = 0

      def initialize(@name : String = "", @y_threshold : Float32 = 0, @z_order : Int32 = 0)
        super(name, true)
      end
    end

    # Scale zone for character perspective
    class ScaleZone
      include YAML::Serializable

      property min_y : Float32
      property max_y : Float32
      property min_scale : Float32 = 0.5f32
      property max_scale : Float32 = 1.0f32

      def initialize(@min_y : Float32, @max_y : Float32,
                     @min_scale : Float32 = 0.5f32, @max_scale : Float32 = 1.0f32)
      end
    end
  end
end