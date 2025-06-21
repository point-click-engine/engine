# Walkable area system for defining where characters can move

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Scenes
    # Defines walkable and non-walkable regions in a scene
    class WalkableArea
      include YAML::Serializable
      
      property regions : Array(PolygonRegion) = [] of PolygonRegion
      property walk_behind_regions : Array(WalkBehindRegion) = [] of WalkBehindRegion
      property scale_zones : Array(ScaleZone) = [] of ScaleZone
      
      @[YAML::Field(ignore: true)]
      property bounds : RL::Rectangle = RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0)
      
      def initialize
        @regions = [] of PolygonRegion
        @walk_behind_regions = [] of WalkBehindRegion
        @scale_zones = [] of ScaleZone
      end
      
      # Check if a point is in a walkable area
      def is_point_walkable?(point : RL::Vector2) : Bool
        # If no regions defined, assume walkable
        return true if @regions.empty?
        
        # Quick bounds check
        if @bounds.width > 0 && @bounds.height > 0
          return false unless RL.check_collision_point_rec?(point, @bounds)
        end
        
        # Check each region
        in_walkable = false
        in_non_walkable = false
        
        @regions.each do |region|
          if region.contains_point?(point)
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
      
      # Get character scale based on Y position
      def get_scale_at_y(y : Float32) : Float32
        return 1.0f32 if @scale_zones.empty?
        
        # Find the appropriate scale zone
        @scale_zones.each do |zone|
          if y >= zone.min_y && y <= zone.max_y
            # Linear interpolation within the zone
            t = (y - zone.min_y) / (zone.max_y - zone.min_y)
            return zone.min_scale + t * (zone.max_scale - zone.min_scale)
          end
        end
        
        # Default scale if outside all zones
        1.0f32
      end
      
      # Get walk-behind regions that should render in front of a character at given Y
      def get_walk_behind_at_y(y : Float32) : Array(WalkBehindRegion)
        @walk_behind_regions.select { |region| y > region.y_threshold }
      end
      
      # Constrain movement to walkable area
      def constrain_to_walkable(from : RL::Vector2, to : RL::Vector2) : RL::Vector2
        # If destination is walkable, return it
        return to if is_point_walkable?(to)
        
        # Otherwise, find the closest walkable point along the line
        # Sample points along the line from 'from' to 'to'
        steps = 10
        best_point = from
        
        (1..steps).each do |i|
          t = i.to_f32 / steps
          test_point = RL::Vector2.new(
            x: from.x + (to.x - from.x) * t,
            y: from.y + (to.y - from.y) * t
          )
          
          if is_point_walkable?(test_point)
            best_point = test_point
          else
            break
          end
        end
        
        best_point
      end
      
      # Update the overall bounds
      def update_bounds
        return if @regions.empty?
        
        min_x = Float32::MAX
        min_y = Float32::MAX
        max_x = Float32::MIN
        max_y = Float32::MIN
        
        @regions.each do |region|
          region.vertices.each do |vertex|
            min_x = vertex.x if vertex.x < min_x
            min_y = vertex.y if vertex.y < min_y
            max_x = vertex.x if vertex.x > max_x
            max_y = vertex.y if vertex.y > max_y
          end
        end
        
        @bounds = RL::Rectangle.new(
          x: min_x,
          y: min_y,
          width: max_x - min_x,
          height: max_y - min_y
        )
      end
      
      # Draw debug visualization
      def draw_debug
        # Draw walkable regions in green
        @regions.each do |region|
          color = region.walkable ? 
            RL::Color.new(r: 0, g: 255, b: 0, a: 80) : 
            RL::Color.new(r: 255, g: 0, b: 0, a: 80)
          region.draw_filled(color)
          region.draw_outline(RL::WHITE, 1)
        end
        
        # Draw walk-behind regions in blue
        @walk_behind_regions.each do |region|
          region.draw_outline(RL::Color.new(r: 0, g: 100, b: 255, a: 255), 2)
        end
        
        # Draw scale zones as gradient bars on the right
        if !@scale_zones.empty?
          x = RL.get_screen_width - 50
          @scale_zones.each do |zone|
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
      
      # Check if point is inside polygon
      def contains_point?(point : RL::Vector2) : Bool
        return false if @vertices.size < 3
        
        # Ray casting algorithm
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
      
      # Draw filled polygon
      def draw_filled(color : RL::Color)
        return if @vertices.size < 3
        
        # Calculate center for triangle fan
        center = RL::Vector2.new(x: 0, y: 0)
        @vertices.each do |vertex|
          center.x += vertex.x
          center.y += vertex.y
        end
        center.x /= @vertices.size
        center.y /= @vertices.size
        
        # Draw as triangle fan
        @vertices.each_with_index do |vertex, i|
          next_vertex = @vertices[(i + 1) % @vertices.size]
          RL.draw_triangle(center, vertex, next_vertex, color)
        end
      end
      
      # Draw polygon outline
      def draw_outline(color : RL::Color, thickness : Int32)
        return if @vertices.size < 2
        
        @vertices.each_with_index do |vertex, i|
          next_vertex = @vertices[(i + 1) % @vertices.size]
          RL.draw_line_ex(vertex, next_vertex, thickness.to_f32, color)
        end
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