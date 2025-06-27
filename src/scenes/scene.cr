# Scene management using component-based architecture
#
# This refactored Scene class delegates responsibilities to specialized components:
# - NavigationManager: Handles pathfinding and navigation
# - BackgroundRenderer: Manages background rendering
# - HotspotManager: Manages interactive hotspots

require "yaml"
require "./navigation_manager"
require "./background_renderer"
require "./hotspot_manager"
require "./walkable_area"
require "../characters/character"
require "../core/game_object"
require "../graphics/camera"

module PointClickEngine
  module Scenes
    # Refactored Scene class using component architecture
    class Scene
      include YAML::Serializable

      # Core properties
      property name : String
      property enable_pathfinding : Bool = true
      property enable_camera_scrolling : Bool = true
      property default_transition_duration : Float32 = 1.0f32
      property logical_width : Int32 = 1024
      property logical_height : Int32 = 768

      # Scene components
      @[YAML::Field(ignore: true)]
      property navigation_manager : NavigationManager?

      @[YAML::Field(ignore: true)]
      property background_renderer : BackgroundRenderer?

      @[YAML::Field(ignore: true)]
      property hotspot_manager : HotspotManager?

      # Scene state
      @[YAML::Field(ignore: true)]
      property objects : Array(Core::GameObject) = [] of Core::GameObject

      @[YAML::Field(ignore: true)]
      property characters : Array(Characters::Character) = [] of Characters::Character

      @[YAML::Field(ignore: true)]
      property player : Characters::Character?

      @[YAML::Field(ignore: true)]
      property walkable_area : WalkableArea?

      # Callbacks
      @[YAML::Field(ignore: true)]
      property on_enter : Proc(Nil)?

      @[YAML::Field(ignore: true)]
      property on_exit : Proc(Nil)?

      # Serialization support
      property background_path : String?
      property scale : Float32 = 1.0
      property player_name_for_serialization : String?
      property navigation_cell_size : Int32 = 16
      property script_path : String?

      # Legacy compatibility - will be removed
      @[YAML::Field(ignore: true)]
      property background : RL::Texture2D?

      @[YAML::Field(ignore: true)]
      property highlight_hotspots : Bool = false

      @[YAML::Field(ignore: true)]
      property navigation_grid : Navigation::NavigationGrid?

      @[YAML::Field(ignore: true)]
      property pathfinder : Navigation::Pathfinding?

      @[YAML::Field(ignore: true)]
      property hotspots : Array(Hotspot) = [] of Hotspot

      def initialize
        @name = ""
        @background_renderer = BackgroundRenderer.new(@logical_width, @logical_height)
        @hotspot_manager = HotspotManager.new
        initialize_collections
      end

      def initialize(@name : String)
        @background_renderer = BackgroundRenderer.new(@logical_width, @logical_height)
        @hotspot_manager = HotspotManager.new
        initialize_collections
      end

      private def initialize_collections
        @objects = [] of Core::GameObject
        @characters = [] of Characters::Character
        # Keep legacy hotspots array in sync
        @hotspots = [] of Hotspot
      end

      # YAML deserialization support
      def after_yaml_deserialize(ctx : YAML::ParseContext)
        # Initialize components
        @background_renderer = BackgroundRenderer.new(@logical_width, @logical_height)
        @hotspot_manager = HotspotManager.new
        initialize_collections

        # Load background if path exists
        if path = @background_path
          load_background(path, @scale)
        end

        # Restore character state
        @characters.each &.after_yaml_deserialize(ctx)

        # Restore player reference
        if name = @player_name_for_serialization
          found_player = @characters.find { |char| char.name == name }.as?(Characters::Player)
          @player = found_player if found_player
        end
      end

      # Background management (delegates to BackgroundRenderer)
      def load_background(path : String, scale : Float32 = 1.0)
        @background_path = path
        @scale = scale
        @background_renderer.not_nil!.load_background(path)
        # Use Fit mode to maintain aspect ratio with letterboxing
        if bg = @background_renderer
          bg.set_scaling_mode(BackgroundRenderer::ScalingMode::Fit)
        end
        # Legacy support
        @background = @background_renderer.try(&.background_texture)
      end

      def load_background(path : String, original_path : String, scale : Float32 = 1.0)
        @background_path = original_path
        @scale = scale
        @background_renderer.not_nil!.load_background(path)
        # Use Fit mode to maintain aspect ratio with letterboxing
        if bg = @background_renderer
          bg.set_scaling_mode(BackgroundRenderer::ScalingMode::Fit)
        end
        # Legacy support
        @background = @background_renderer.try(&.background_texture)
      end

      # Hotspot management (delegates to HotspotManager)
      def add_hotspot(hotspot : Hotspot)
        @hotspot_manager.not_nil!.add_hotspot(hotspot)
        @objects << hotspot unless @objects.includes?(hotspot)
        # Legacy support
        @hotspots = @hotspot_manager.not_nil!.hotspots
      end

      def remove_hotspot(name : String) : Bool
        if hotspot = @hotspot_manager.not_nil!.get_hotspot_by_name(name)
          @hotspot_manager.not_nil!.remove_hotspot(hotspot)
          @objects.delete(hotspot)
          # Legacy support
          @hotspots = @hotspot_manager.not_nil!.hotspots
          true
        else
          false
        end
      end

      def remove_hotspot(hotspot : Hotspot) : Bool
        # Check if hotspot exists before removing
        if @hotspot_manager.not_nil!.hotspots.includes?(hotspot)
          @hotspot_manager.not_nil!.remove_hotspot(hotspot)
          @objects.delete(hotspot)
          # Legacy support
          @hotspots = @hotspot_manager.not_nil!.hotspots
          true
        else
          false
        end
      end

      def get_hotspot_at(point : RL::Vector2) : Hotspot?
        @hotspot_manager.not_nil!.get_hotspot_at(point)
      end

      # Object management
      def add_object(object : Core::GameObject)
        @objects << object unless @objects.includes?(object)
      end

      # Character management
      def add_character(character : Characters::Character)
        @characters << character unless @characters.includes?(character)
        add_object(character) unless @objects.includes?(character)
      end

      def set_player(player : Characters::Character)
        @player = player
        @player_name_for_serialization = player.name
        add_character(player) unless @characters.includes?(player)
      end

      def get_character(name : String) : Characters::Character?
        @characters.find { |c| c.name == name }
      end

      def get_character_at(point : RL::Vector2) : Characters::Character?
        @characters.find { |c| c.active && c.visible && c.contains_point?(point) && c != @player }
      end

      # Navigation setup (delegates to NavigationManager)
      def setup_navigation(character_radius : Float32 = 56.0_f32)
        return unless @enable_pathfinding
        return unless @background_renderer.try(&.background_texture)

        @navigation_manager = NavigationManager.new(@logical_width, @logical_height)
        @navigation_manager.not_nil!.grid_cell_size = @navigation_cell_size
        @navigation_manager.not_nil!.setup_navigation(@walkable_area)

        # Legacy support - need to create proper NavigationGrid from scene
        if walkable = @walkable_area
          @navigation_grid = Navigation::NavigationGrid.from_scene(
            self,
            @logical_width,
            @logical_height,
            @navigation_cell_size,
            character_radius
          )
          @pathfinder = Navigation::Pathfinding.new(@navigation_grid.not_nil!)
        end

        # Debug output
        if Core::Engine.debug_mode
          puts "\n========== NAVIGATION SETUP =========="
          puts "[NAVIGATION] Background texture dimensions: #{@background_renderer.try(&.background_texture).try(&.width)}x#{@background_renderer.try(&.background_texture).try(&.height)}"
          puts "[NAVIGATION] Logical scene dimensions: #{@logical_width}x#{@logical_height}"
          puts "[NAVIGATION] Creating grid with cell size: #{@navigation_cell_size}"

          if grid = @navigation_grid
            walkable_count = 0
            total_count = 0
            grid.walkable.each do |row|
              row.each do |cell|
                total_count += 1
                walkable_count += 1 if cell
              end
            end
            puts "[NAVIGATION] Grid created: #{grid.width}x#{grid.height} cells (cell size: #{@navigation_cell_size})"
            puts "[NAVIGATION] Total cells: #{total_count}, Walkable: #{walkable_count} (#{(walkable_count * 100.0 / total_count).round(1)}%)"

            if walkable_count == 0
              puts "[NAVIGATION] WARNING: No walkable cells found! This means pathfinding will not work."
            end
          end
          puts "====================================\n"
        end
      end

      # Pathfinding (delegates to NavigationManager)
      def find_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Array(Raylib::Vector2)?
        @navigation_manager.try(&.find_path(start_x.to_i, start_y.to_i, end_x.to_i, end_y.to_i))
      end

      # Walkability checks
      def is_walkable?(point : RL::Vector2) : Bool
        if walkable = @walkable_area
          walkable.is_point_walkable?(point)
        else
          true
        end
      end

      def is_area_walkable?(center : RL::Vector2, size : RL::Vector2, scale : Float32 = 1.0) : Bool
        # First check with walkable area polygons if available
        if walkable = @walkable_area
          # Use the same collision margin as original (90% for smoother gameplay)
          collision_margin = 0.9_f32
          half_width = (size.x * scale) / 2.0
          half_height = (size.y * scale) / 2.0

          check_points = [
            center,
            RL::Vector2.new(x: center.x - half_width * collision_margin, y: center.y - half_height * collision_margin),
            RL::Vector2.new(x: center.x + half_width * collision_margin, y: center.y - half_height * collision_margin),
            RL::Vector2.new(x: center.x - half_width * collision_margin, y: center.y + half_height * collision_margin),
            RL::Vector2.new(x: center.x + half_width * collision_margin, y: center.y + half_height * collision_margin),
            RL::Vector2.new(x: center.x, y: center.y - half_height * collision_margin),
            RL::Vector2.new(x: center.x, y: center.y + half_height * collision_margin),
            RL::Vector2.new(x: center.x - half_width * collision_margin, y: center.y),
            RL::Vector2.new(x: center.x + half_width * collision_margin, y: center.y),
          ]

          walkable_count = check_points.count { |point| walkable.is_point_walkable?(point) }
          center_walkable = walkable.is_point_walkable?(center)

          # Require center to be walkable AND at least 7 other points (8 total out of 9)
          # This provides a good balance between strictness and gameplay forgiveness
          polygon_result = center_walkable && walkable_count >= 8

          # If navigation grid is available, also check grid-based walkability
          if grid = @navigation_grid
            # Check corners of the character bounds in the navigation grid
            grid_points = [
              RL::Vector2.new(x: center.x - half_width, y: center.y - half_height),
              RL::Vector2.new(x: center.x + half_width, y: center.y - half_height),
              RL::Vector2.new(x: center.x - half_width, y: center.y + half_height),
              RL::Vector2.new(x: center.x + half_width, y: center.y + half_height),
            ]

            # All grid cells covered by character must be walkable
            grid_walkable = grid_points.all? do |point|
              grid_x, grid_y = grid.world_to_grid(point.x, point.y)
              grid.is_walkable?(grid_x, grid_y)
            end

            # Both polygon and grid checks must pass
            return polygon_result && grid_walkable
          else
            return polygon_result
          end
        end

        # No walkable area defined, assume walkable
        true
      end

      def get_character_scale(y_position : Float32) : Float32
        @walkable_area.try(&.get_scale_at_y(y_position)) || 1.0f32
      end

      # Update scene
      def update(dt : Float32)
        # Update player
        @player.try(&.update(dt))
        
        # Update all objects
        @objects.each(&.update(dt))

        # Update character scales based on walkable area
        if walkable = @walkable_area
          all_characters = @characters.dup
          @player.try { |p| all_characters << p unless all_characters.includes?(p) }

          all_characters.each do |character|
            # Only apply dynamic scaling if no manual scale is set
            if character.manual_scale.nil?
              scale = walkable.get_scale_at_y(character.position.y)
              character.scale = scale
            end
          end
        end
      end

      # Render scene
      def draw(camera : Graphics::Camera? = nil)
        # Calculate camera offset
        camera_offset = camera ? RL::Vector2.new(x: -camera.position.x, y: -camera.position.y) : RL::Vector2.new(x: 0, y: 0)

        # Clear scene area with black for letterboxing
        RL.draw_rectangle(0, 0, @logical_width, @logical_height, RL::BLACK)

        # Draw background
        if camera
          @background_renderer.not_nil!.draw(camera_offset)
        else
          @background_renderer.not_nil!.draw_static
        end

        # Get all characters and sort by Y position for depth
        all_characters = @characters.dup
        @player.try { |p| all_characters << p unless all_characters.includes?(p) }
        sorted_characters = all_characters.sort_by(&.position.y)

        # Draw hotspots
        @hotspot_manager.not_nil!.hotspots.each do |hotspot|
          if camera
            draw_with_camera_offset(hotspot, camera_offset)
          else
            hotspot.draw
          end
        end

        # Draw objects and characters with walk-behind support
        if walkable = @walkable_area
          sorted_characters.each do |character|
            # Draw the character
            if camera
              draw_with_camera_offset(character, camera_offset)
            else
              character.draw
            end
          end

          # Draw other objects
          @objects.each do |obj|
            unless obj.is_a?(Characters::Character)
              if camera
                draw_with_camera_offset(obj, camera_offset)
              else
                obj.draw
              end
            end
          end
        else
          # No walkable area - simple drawing
          # Draw non-character objects first
          @objects.each do |obj|
            unless obj.is_a?(Characters::Character)
              if camera
                draw_with_camera_offset(obj, camera_offset)
              else
                obj.draw
              end
            end
          end

          # Then draw all characters in sorted order
          sorted_characters.each do |character|
            if camera
              draw_with_camera_offset(character, camera_offset)
            else
              character.draw
            end
          end
        end

        # Draw navigation debug if enabled
        if Core::Engine.debug_mode
          # Use NavigationManager's debug rendering
          if nm = @navigation_manager
            nm.draw_navigation_debug(camera_offset)
          end

          # Draw walkable area debug
          if camera && (walkable = @walkable_area)
            draw_walkable_debug_with_offset(walkable, camera_offset)
          else
            @walkable_area.try(&.draw_debug)
          end
        end
      end

      # Helper to draw objects with camera offset
      private def draw_with_camera_offset(obj : Core::GameObject, offset : RL::Vector2)
        original_pos = obj.position
        obj.position = RL::Vector2.new(
          x: original_pos.x + offset.x,
          y: original_pos.y + offset.y
        )
        obj.draw
        obj.position = original_pos
      end

      # Draw walkable area debug with camera offset
      private def draw_walkable_debug_with_offset(walkable : WalkableArea, offset : RL::Vector2)
        walkable.regions.each do |region|
          next unless region.vertices.size >= 3

          (0...region.vertices.size).each do |i|
            v1 = region.vertices[i]
            v2 = region.vertices[(i + 1) % region.vertices.size]

            start_pos = RL::Vector2.new(x: v1.x + offset.x, y: v1.y + offset.y)
            end_pos = RL::Vector2.new(x: v2.x + offset.x, y: v2.y + offset.y)

            color = region.walkable ? RL::GREEN : RL::RED
            RL.draw_line_v(start_pos, end_pos, color)
          end
        end
      end

      # Scene lifecycle
      def enter
        @on_enter.try &.call
      end

      def exit
        @on_exit.try &.call
      end

      # Script loading
      def load_script(engine : Core::Engine)
        return unless script_path = @script_path
        engine.system_manager.script_engine.try &.execute_script_file(script_path)
      end

      # Toggle hotspot highlighting
      def toggle_hotspot_highlight
        @highlight_hotspots = !@highlight_hotspots
      end
    end
  end
end
