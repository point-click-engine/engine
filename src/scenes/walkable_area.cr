# Walkable area system for defining where characters can move

require "yaml"

module PointClickEngine
  # # Scene management and interactive environments.
  ##
  # # The `Scenes` module provides all components for creating game locations,
  # # including backgrounds, interactive hotspots, navigation meshes, and
  # # scene transitions. Scenes are the primary containers for gameplay.
  ##
  # # ## Core Components
  ##
  # # - `Scene` - Main scene container and manager
  # # - `Hotspot` - Interactive clickable areas
  # # - `PolygonHotspot` - Non-rectangular hotspots
  # # - `WalkableArea` - Navigation and movement constraints
  # # - `ExitZone` - Scene transition triggers
  # # - `SceneLoader` - YAML-based scene loading
  ##
  # # ## Scene Structure
  ##
  # # ```
  # # Scene
  # # ├── Background (image)
  # # ├── Walkable Areas (navigation mesh)
  # # ├── Hotspots (interactive objects)
  # # ├── Characters (NPCs)
  # # ├── Objects (props)
  # # └── Exits (to other scenes)
  # # ```
  ##
  # # ## Creating Scenes
  ##
  # # ```crystal
  # # # Programmatically
  # # scene = Scene.new("kitchen")
  # # scene.load_background("assets/kitchen.png")
  # # scene.add_hotspot(stove_hotspot)
  # # scene.add_character(chef_npc)
  ##
  # # # From YAML
  # # scene = SceneLoader.load("scenes/kitchen.yaml")
  # # ```
  ##
  # # ## Navigation System
  ##
  # # ```crystal
  # # # Define walkable areas
  # # walkable = WalkableArea.new
  # # walkable.add_region(floor_polygon, walkable: true)
  # # walkable.add_region(table_polygon, walkable: false)
  # # scene.walkable_area = walkable
  ##
  # # # Characters automatically path around obstacles
  # # ```
  ##
  # # ## Scene Transitions
  ##
  # # ```crystal
  # # # Define exit zones
  # # door = ExitZone.new("door", rect, "hallway")
  # # door.transition_type = TransitionType::FadeBlack
  # # scene.add_exit(door)
  # # ```
  ##
  # # ## Common Patterns
  ##
  # # ### Dynamic Scene Changes
  # # ```crystal
  # # scene.on_enter = -> {
  # #   if game.has_flag?("lights_off")
  # #     scene.load_background("assets/kitchen_dark.png")
  # #   end
  # # }
  # # ```
  ##
  # # ### Conditional Exits
  # # ```crystal
  # # exit.on_use = -> {
  # #   if player.has_item?("key")
  # #     engine.change_scene(exit.target_scene)
  # #   else
  # #     player.say("The door is locked")
  # #   end
  # # }
  # # ```
  ##
  # # ## See Also
  ##
  # # - `Engine#change_scene` - Scene switching
  # # - `Character#walk_to` - Character navigation
  # # - `Hotspot` - Interactive elements
  module Scenes
    # # Manages walkable and non-walkable regions in a scene.
    ##
    # # The `WalkableArea` class defines where characters can move using polygon regions.
    # # It supports obstacles, walk-behind areas for depth sorting, and scale zones
    # # for perspective effects. Multiple regions can overlap with non-walkable areas
    # # taking precedence.
    ##
    # # ## Features
    ##
    # # - Polygon-based walkable/non-walkable regions
    # # - Walk-behind areas for objects in front of characters
    # # - Scale zones for character size based on Y position
    # # - Path constraint to keep movement within bounds
    # # - Efficient point-in-polygon collision detection
    ##
    # # ## Basic Usage
    ##
    # # ```crystal
    # # walkable = WalkableArea.new
    ##
    # # # Define the main walkable floor
    # # floor = PolygonRegion.new("floor", walkable: true)
    # # floor.vertices = [
    # #   Vector2.new(100, 400),
    # #   Vector2.new(700, 400),
    # #   Vector2.new(700, 550),
    # #   Vector2.new(100, 550)
    # # ]
    # # walkable.regions << floor
    ##
    # # # Add an obstacle (table)
    # # table = PolygonRegion.new("table", walkable: false)
    # # table.vertices = [
    # #   Vector2.new(300, 450),
    # #   Vector2.new(400, 450),
    # #   Vector2.new(400, 500),
    # #   Vector2.new(300, 500)
    # # ]
    # # walkable.regions << table
    # # ```
    ##
    # # ## Walk-Behind Regions
    ##
    # # ```crystal
    # # # Create a column that characters can walk behind
    # # column = WalkBehindRegion.new("column")
    # # column.y_threshold = 400  # Characters below Y=400 appear behind
    # # column.texture = load_texture("column.png")
    # # column.position = Vector2.new(350, 300)
    # # walkable.walk_behind_regions << column
    # # ```
    ##
    # # ## Scale Zones (Perspective)
    ##
    # # ```crystal
    # # # Characters appear smaller in the background
    # # perspective = ScaleZone.new
    # # perspective.min_y = 200    # Far background
    # # perspective.max_y = 550    # Foreground
    # # perspective.min_scale = 0.5  # 50% size at back
    # # perspective.max_scale = 1.0  # 100% size at front
    # # walkable.scale_zones << perspective
    ##
    # # # Character scale interpolates smoothly between zones
    # # ```
    ##
    # # ## Path Constraints
    ##
    # # ```crystal
    # # # Constrain movement to walkable area
    # # start_pos = Vector2.new(100, 400)
    # # click_pos = Vector2.new(500, 300)  # In non-walkable area
    ##
    # # # Returns closest walkable point along the path
    # # actual_target = walkable.constrain_to_walkable(start_pos, click_pos)
    # # character.walk_to(actual_target)
    # # ```
    ##
    # # ## Common Gotchas
    ##
    # # 1. **Empty regions = everything walkable**: No regions means no restrictions
    # #    ```crystal
    # #    walkable.regions.empty?  # true = entire scene is walkable
    # #    ```
    ##
    # # 2. **Non-walkable takes precedence**: Overlapping regions favor blocking
    # #    ```crystal
    # #    # If point is in both walkable and non-walkable regions,
    # #    # it's considered non-walkable
    # #    ```
    ##
    # # 3. **Polygon winding matters**: Use consistent clockwise/counter-clockwise
    # #    ```crystal
    # #    # Clockwise winding
    # #    vertices = [top_left, top_right, bottom_right, bottom_left]
    # #    ```
    ##
    # # 4. **Scale zones are Y-based only**: X position doesn't affect scale
    # #    ```crystal
    # #    scale = walkable.get_scale_at_y(character.position.y)
    # #    # X coordinate is ignored for scaling
    # #    ```
    ##
    # # ## Performance Tips
    ##
    # # - Keep polygon vertex counts reasonable (4-8 vertices typical)
    # # - Use bounding box pre-check for complex areas
    # # - Combine adjacent walkable regions when possible
    # # - Limit scale zones to 2-3 for smooth interpolation
    ##
    # # ## Debugging
    ##
    # # ```crystal
    # # # Visualize walkable areas in debug mode
    # # if Engine.debug_mode
    # #   walkable.draw_debug  # Green = walkable, Red = blocked
    # # end
    # # ```
    ##
    # # ## See Also
    ##
    # # - `PolygonRegion` - Individual walkable/non-walkable areas
    # # - `Scene#walkable_area` - Assigning to scenes
    # # - `Character#walk_to` - Character pathfinding
    # # - `Navigation::Pathfinding` - A* pathfinding system
    class WalkableArea
      include YAML::Serializable

      getter regions : Array(PolygonRegion) = [] of PolygonRegion
      property walk_behind_regions : Array(WalkBehindRegion) = [] of WalkBehindRegion
      property scale_zones : Array(ScaleZone) = [] of ScaleZone

      @[YAML::Field(ignore: true)]
      property bounds : RL::Rectangle = RL::Rectangle.new(x: 0, y: 0, width: 0, height: 0)

      # Custom setter for regions that updates bounds
      def regions=(value : Array(PolygonRegion))
        @regions = value
        update_bounds
      end

      def initialize
        @regions = [] of PolygonRegion
        @walk_behind_regions = [] of WalkBehindRegion
        @scale_zones = [] of ScaleZone
      end

      # # Checks if a point is within a walkable area.
      ##
      # # Tests the point against all defined regions. Non-walkable regions
      # # take precedence over walkable ones when regions overlap.
      ##
      # # - *point* : The position to test
      # # - Returns true if the point is walkable, false otherwise
      ##
      # # ## Algorithm
      ##
      # # 1. If no regions defined, returns true (everything walkable)
      # # 2. Quick bounding box check for early rejection
      # # 3. Test point against each polygon region
      # # 4. Non-walkable regions override walkable ones
      ##
      # # ```crystal
      # # if walkable_area.is_point_walkable?(mouse_pos)
      # #   character.walk_to(mouse_pos)
      # # else
      # #   character.say("I can't walk there")
      # # end
      # # ```
      ##
      # # NOTE: Uses point-in-polygon algorithm internally
      def is_point_walkable?(point : RL::Vector2) : Bool
        # If no regions defined, assume walkable
        return true if @regions.empty?

        # Quick bounds check
        if @bounds.width > 0 && @bounds.height > 0
          in_bounds = RL.check_collision_point_rec?(point, @bounds)
          # Don't log during grid generation - too noisy
          return false unless in_bounds
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

      # Find the nearest walkable point to a given position
      def find_nearest_walkable_point(target : RL::Vector2) : RL::Vector2
        # If the target is already walkable, return it
        return target if is_point_walkable?(target)

        # Search in expanding circles to find the nearest walkable point
        max_radius = 200.0_f32
        step_radius = 10.0_f32
        angle_steps = 16

        (step_radius..max_radius).step(step_radius).each do |radius|
          (0...angle_steps).each do |i|
            angle = (i.to_f32 / angle_steps) * Math::TAU
            test_point = RL::Vector2.new(
              x: target.x + Math.cos(angle) * radius,
              y: target.y + Math.sin(angle) * radius
            )

            if is_point_walkable?(test_point)
              return test_point
            end
          end
        end

        # If no walkable point found within radius, return original target
        # This shouldn't happen in a well-designed level
        target
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
          color = region.walkable ? RL::Color.new(r: 0, g: 255, b: 0, a: 80) : RL::Color.new(r: 255, g: 0, b: 0, a: 80)
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
