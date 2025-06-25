# Scene management for game environments

require "yaml"
require "../navigation/pathfinding"
require "../assets/asset_loader"
require "./walkable_area"
require "../graphics/camera"

module PointClickEngine
  module Scenes
    # Represents a game scene or room in a point-and-click adventure game.
    #
    # A Scene is the primary container for game content, managing backgrounds,
    # characters, interactive hotspots, navigation, and game objects. Each scene
    # represents a distinct location or room that the player can explore.
    #
    # ## Key Responsibilities
    # - Background image rendering and scaling
    # - Character management and depth sorting
    # - Hotspot interaction handling
    # - Pathfinding and navigation setup
    # - Walkable area constraints
    # - Script execution and event handling
    #
    # ## Usage Example
    # ```
    # scene = Scene.new("bedroom")
    # scene.load_background("assets/bedroom.png")
    # scene.add_character(player)
    # scene.add_hotspot(door_hotspot)
    # scene.setup_navigation
    # ```
    #
    # NOTE: Scenes support YAML serialization for save/load functionality
    class Scene
      include YAML::Serializable

      # The unique name identifier for this scene
      property name : String

      # File path to the background image for this scene
      property background_path : String?

      # The loaded background texture (runtime only)
      @[YAML::Field(ignore: true)]
      property background : RL::Texture2D?

      # Collection of interactive hotspots in the scene
      @[YAML::Field(ignore: true)]
      property hotspots : Array(Hotspot) = [] of Hotspot

      # All game objects present in the scene
      @[YAML::Field(ignore: true)]
      property objects : Array(Core::GameObject) = [] of Core::GameObject

      # Characters present in the scene (excluding player)
      @[YAML::Field(ignore: true)]
      property characters : Array(Characters::Character) = [] of Characters::Character

      # Callback executed when entering this scene
      @[YAML::Field(ignore: true)]
      property on_enter : Proc(Nil)?

      # Callback executed when exiting this scene
      @[YAML::Field(ignore: true)]
      property on_exit : Proc(Nil)?

      # Rendering scale factor for the background (1.0 = original size)
      property scale : Float32 = 1.0

      # Player character name for serialization purposes
      property player_name_for_serialization : String?

      # Reference to the player character (runtime only)
      @[YAML::Field(ignore: true)]
      property player : Characters::Character?

      # Navigation grid for pathfinding (runtime only)
      @[YAML::Field(ignore: true)]
      property navigation_grid : Navigation::Pathfinding::NavigationGrid?

      # Pathfinding system instance (runtime only)
      @[YAML::Field(ignore: true)]
      property pathfinder : Navigation::Pathfinding?

      # Whether pathfinding is enabled for this scene
      property enable_pathfinding : Bool = true

      # Size of navigation grid cells in pixels (smaller = more precise)
      property navigation_cell_size : Int32 = 16

      # Optional path to scene-specific script file
      property script_path : String?

      # Walkable area definition for character movement constraints
      @[YAML::Field(ignore: true)]
      property walkable_area : WalkableArea?

      # Whether camera scrolling is enabled for this scene
      property enable_camera_scrolling : Bool = true

      # Default transition duration for this scene (in seconds)
      # This is used when no duration is specified in transition commands
      property default_transition_duration : Float32 = 1.0f32

      # Logical dimensions of the scene (independent of texture size)
      # These define the coordinate space for all scene elements
      property logical_width : Int32 = 1024
      property logical_height : Int32 = 768

      # Creates a new scene with empty name and collections
      def initialize
        @name = ""
        @objects = [] of Core::GameObject
        @hotspots = [] of Hotspot
        @characters = [] of Characters::Character
      end

      # Creates a new scene with the specified *name*
      #
      # - *name* : Unique identifier for the scene
      def initialize(@name : String)
        @objects = [] of Core::GameObject
        @hotspots = [] of Hotspot
        @characters = [] of Characters::Character
      end

      # Called after YAML deserialization to restore runtime state
      #
      # Loads the background texture, restores character state, and
      # reconnects the player character reference.
      #
      # - *ctx* : YAML parsing context
      def after_yaml_deserialize(ctx : YAML::ParseContext)
        if path = @background_path
          load_background(path, @scale)
        end

        @characters.each &.after_yaml_deserialize(ctx)

        if name = @player_name_for_serialization
          found_player = @characters.find { |char| char.name == name }.as?(Characters::Player)
          @player = found_player if found_player
        end
      end

      # Loads a background image for the scene
      #
      # The background will be automatically scaled to fit the screen dimensions
      # while maintaining aspect ratio.
      #
      # - *path* : File path to the background image
      # - *scale* : Optional scaling factor (default: 1.0)
      #
      # ```
      # scene.load_background("assets/backgrounds/room.png", 1.5)
      # ```
      def load_background(path : String, scale : Float32 = 1.0)
        # Store the original path, not the resolved one
        @background_path = path
        @background = PointClickEngine::AssetLoader.load_texture(path)
        @scale = scale
      end

      # Alternative method that stores a specific path
      def load_background(path : String, original_path : String, scale : Float32 = 1.0)
        @background_path = original_path
        @background = PointClickEngine::AssetLoader.load_texture(path)
        @scale = scale
      end

      # Adds an interactive hotspot to the scene
      #
      # The hotspot will be added to both the hotspot collection and the
      # general objects collection for unified processing.
      #
      # - *hotspot* : The hotspot to add
      def add_hotspot(hotspot : Hotspot)
        @hotspots << hotspot unless @hotspots.includes?(hotspot)
        @objects << hotspot unless @objects.includes?(hotspot)
      end

      # Removes a hotspot from the scene by name
      #
      # Removes the hotspot from both the hotspots collection and the
      # general objects collection. Returns true if the hotspot was found
      # and removed, false otherwise.
      #
      # - *name* : The name of the hotspot to remove
      #
      # Returns: true if hotspot was removed, false if not found
      def remove_hotspot(name : String) : Bool
        hotspot = @hotspots.find { |h| h.name == name }
        return false unless hotspot

        @hotspots.delete(hotspot)
        @objects.delete(hotspot)
        true
      end

      # Removes a hotspot from the scene
      #
      # Removes the hotspot from both the hotspots collection and the
      # general objects collection. Returns true if the hotspot was found
      # and removed, false otherwise.
      #
      # - *hotspot* : The hotspot object to remove
      #
      # Returns: true if hotspot was removed, false if not found
      def remove_hotspot(hotspot : Hotspot) : Bool
        found = @hotspots.delete(hotspot)
        @objects.delete(hotspot) if found
        found != nil
      end

      # Adds a game object to the scene
      #
      # Objects are processed during update and draw cycles.
      # Duplicates are automatically prevented.
      #
      # - *object* : The game object to add
      def add_object(object : Core::GameObject)
        @objects << object unless @objects.includes?(object)
      end

      # Adds a character to the scene
      #
      # Characters are added to both the character collection and the
      # general objects collection for proper rendering and interaction.
      #
      # - *character* : The character to add
      def add_character(character : Characters::Character)
        @characters << character unless @characters.includes?(character)
        add_object(character) unless @objects.includes?(character)
      end

      # Sets the player character for this scene
      #
      # The player character receives special handling for input processing
      # and is automatically added to the scene if not already present.
      #
      # - *player* : The character to set as player
      def set_player(player : Characters::Character)
        @player = player
        @player_name_for_serialization = player.name
        add_character(player) unless @characters.includes?(player)
      end

      # Updates the scene and all contained objects
      #
      # Processes all game objects, updates character scaling based on
      # walkable area depth, and handles scene-specific logic.
      #
      # - *dt* : Delta time in seconds since last update
      def update(dt : Float32)
        @objects.each(&.update(dt))

        # Update character scales based on position
        if walkable = @walkable_area
          @characters.each do |character|
            # Only apply dynamic scaling if no manual scale is set
            if character.manual_scale.nil?
              scale = walkable.get_scale_at_y(character.position.y)
              character.scale = scale
            end
          end

          @player.try do |p|
            # Only apply dynamic scaling if no manual scale is set
            if p.manual_scale.nil?
              scale = walkable.get_scale_at_y(p.position.y)
              p.scale = scale
            end
          end
        end
      end

      # Renders the scene and all contained elements
      #
      # Handles background rendering with automatic scaling, depth-sorted
      # character drawing, walk-behind regions, and debug visualization.
      # Characters are automatically sorted by Y position for proper depth.
      def draw(camera : Graphics::Camera? = nil)
        if bg = @background
          if camera
            # Calculate scale to fit screen while maintaining aspect ratio
            scale_x = 1024.0f32 / bg.width
            scale_y = 768.0f32 / bg.height
            scale = Math.max(scale_x, scale_y) # Use the larger scale to fill screen

            # Draw background with camera offset and proper scaling
            RL.draw_texture_ex(bg, RL::Vector2.new(x: -camera.position.x, y: -camera.position.y), 0.0, scale, RL::WHITE)
          else
            # Legacy mode: Calculate scale to fit screen (1024x768)
            scale_x = 1024.0f32 / bg.width
            scale_y = 768.0f32 / bg.height
            scale = Math.max(scale_x, scale_y) # Use the larger scale to fill screen

            RL.draw_texture_ex(bg, RL::Vector2.new(x: 0, y: 0), 0.0, scale, RL::WHITE)
          end
        end

        # Sort characters by Y position for proper depth
        all_characters = @characters.dup
        if player = @player
          all_characters << player
        end
        sorted_characters = all_characters.sort_by(&.position.y)

        # Draw scene elements with camera offset
        camera_offset = camera ? RL::Vector2.new(x: -camera.position.x, y: -camera.position.y) : RL::Vector2.new(x: 0, y: 0)

        # Draw hotspots with camera offset
        @hotspots.each do |hotspot|
          draw_with_camera_offset(hotspot, camera_offset) if camera
          hotspot.draw if !camera
        end

        # Draw objects and characters with walk-behind support
        if walkable = @walkable_area
          sorted_characters.each do |character|
            # Draw walk-behind regions that should appear in front
            behind_regions = walkable.get_walk_behind_at_y(character.position.y)

            # Draw the character with camera offset
            draw_with_camera_offset(character, camera_offset) if camera
            character.draw if !camera

            # Draw walk-behind regions on top if needed
            # (In a full implementation, we'd draw masked background parts here)
          end

          # Draw other objects
          @objects.each do |obj|
            unless obj.is_a?(Characters::Character)
              draw_with_camera_offset(obj, camera_offset) if camera
              obj.draw if !camera
            end
          end
        else
          # No walkable area defined, use simple drawing
          # Draw objects that aren't characters first
          @objects.each do |obj|
            unless obj.is_a?(Characters::Character)
              draw_with_camera_offset(obj, camera_offset) if camera
              obj.draw if !camera
            end
          end
          # Then draw all characters in sorted order
          sorted_characters.each do |character|
            draw_with_camera_offset(character, camera_offset) if camera
            character.draw if !camera
          end
        end

        # Draw navigation debug if enabled
        if Core::Engine.debug_mode
          if @navigation_grid && camera
            draw_navigation_debug_with_offset(camera_offset)
          elsif @navigation_grid
            draw_navigation_debug
          end

          # Draw walkable area debug
          if camera && (walkable = @walkable_area)
            draw_walkable_debug_with_offset(walkable, camera_offset)
          else
            @walkable_area.try(&.draw_debug)
          end
        end
      end

      # Helper method to draw objects with camera offset by temporarily modifying their position
      private def draw_with_camera_offset(obj : Core::GameObject, offset : RL::Vector2)
        # Save original position
        original_pos = obj.position

        # Apply camera offset
        obj.position = RL::Vector2.new(
          x: original_pos.x + offset.x,
          y: original_pos.y + offset.y
        )

        # Draw the object
        obj.draw

        # Restore original position
        obj.position = original_pos
      end

      # Draw navigation debug with camera offset
      private def draw_navigation_debug_with_offset(offset : RL::Vector2)
        return unless pf = @pathfinder
        return unless grid = @navigation_grid

        cell_size = @navigation_cell_size

        grid.walkable.each_with_index do |row, y|
          row.each_with_index do |walkable, x|
            screen_x = (x * cell_size).to_i + offset.x.to_i
            screen_y = (y * cell_size).to_i + offset.y.to_i

            color = walkable ? RL::Color.new(r: 0, g: 255, b: 0, a: 50) : RL::Color.new(r: 255, g: 0, b: 0, a: 50)
            RL.draw_rectangle(screen_x, screen_y, cell_size, cell_size, color)
          end
        end
      end

      # Draw walkable area debug with camera offset
      private def draw_walkable_debug_with_offset(walkable : WalkableArea, offset : RL::Vector2)
        walkable.regions.each do |region|
          next unless region.vertices.size >= 3

          # Draw polygon outline
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

      # Called when the player enters this scene
      #
      # Executes the scene's entry callback if one is defined.
      # Use this for triggering cutscenes, playing music, or setting up
      # scene-specific state.
      def enter
        @on_enter.try &.call
      end

      # Called when the player exits this scene
      #
      # Executes the scene's exit callback if one is defined.
      # Use this for cleanup, stopping music, or saving scene state.
      def exit
        @on_exit.try &.call
      end

      # Finds the topmost active hotspot at the specified screen position
      #
      # Used for mouse interaction detection. Returns `nil` if no active
      # hotspot is found at the given position.
      #
      # - *point* : Screen position to check
      #
      # Returns: The hotspot at that position, or `nil`
      def get_hotspot_at(point : RL::Vector2) : Hotspot?
        @hotspots.reverse.find { |h| h.active && h.visible && h.contains_point?(point) }
      end

      # Finds an active character (excluding player) at the specified position
      #
      # Used for character interaction detection. The player character
      # is automatically excluded from results.
      #
      # - *point* : Screen position to check
      #
      # Returns: The character at that position, or `nil`
      def get_character_at(point : RL::Vector2) : Characters::Character?
        @characters.find { |c| c.active && c.visible && c.contains_point?(point) && c != @player }
      end

      # Finds a character by name
      #
      # Searches all characters in the scene for one with the specified name.
      #
      # - *name* : The character's name to search for
      #
      # Returns: The character with that name, or `nil`
      def get_character(name : String) : Characters::Character?
        @characters.find { |c| c.name == name }
      end

      # Initializes the pathfinding system for this scene
      #
      # Creates a navigation grid based on the background dimensions and
      # walkable areas. Must be called after loading the background.
      # Only runs if pathfinding is enabled for this scene.
      #
      # ```
      # scene.load_background("room.png")
      # scene.setup_navigation
      # ```
      def setup_navigation(character_radius : Float32 = 56.0_f32)
        return unless @enable_pathfinding
        return unless bg = @background

        # Use the provided character radius or a reasonable default
        # This ensures paths leave enough room for characters to pass
        # Default increased from 32 to 56 to better match typical character sizes

        # Get logical scene dimensions from game config or scene properties
        # This should NOT depend on texture size!
        logical_width = @logical_width
        logical_height = @logical_height

        puts "[NAVIGATION] Background texture dimensions: #{bg.width}x#{bg.height}"
        puts "[NAVIGATION] Logical scene dimensions: #{logical_width}x#{logical_height}"
        puts "[NAVIGATION] Creating grid with cell size: #{@navigation_cell_size}"

        # Validate that walkable areas fit within logical dimensions
        if walkable = @walkable_area
          walkable.regions.each do |region|
            region.vertices.each do |vertex|
              if vertex.x < 0 || vertex.x > logical_width || vertex.y < 0 || vertex.y > logical_height
                puts "[WARNING] Walkable region '#{region.name}' has vertex outside logical bounds: #{vertex}"
              end
            end
          end
        end

        @navigation_grid = Navigation::Pathfinding::NavigationGrid.from_scene(
          self,
          logical_width,
          logical_height,
          @navigation_cell_size,
          character_radius
        )

        @pathfinder = Navigation::Pathfinding.new(@navigation_grid.not_nil!)

        # Debug: Count walkable cells
        if grid = @navigation_grid
          walkable_count = 0
          total_count = 0
          grid.walkable.each do |row|
            row.each do |cell|
              total_count += 1
              walkable_count += 1 if cell
            end
          end
          puts "\n========== NAVIGATION GRID DEBUG =========="
          puts "[NAVIGATION] Grid created: #{grid.width}x#{grid.height} cells (cell size: #{@navigation_cell_size})"
          puts "[NAVIGATION] Total cells: #{total_count}, Walkable: #{walkable_count} (#{(walkable_count * 100.0 / total_count).round(1)}%)"

          if walkable_count == 0
            puts "[NAVIGATION] WARNING: No walkable cells found! This means pathfinding will not work."
            puts "[NAVIGATION] This could be caused by:"
            puts "[NAVIGATION]   1. Walkable area not properly defined"
            puts "[NAVIGATION]   2. Character radius too large for the space"
            puts "[NAVIGATION]   3. Bug in navigation grid generation"
          end
          puts "=========================================\n"
        end
      end

      # Checks if a point is walkable within the scene
      #
      # Uses the walkable area definition to determine if characters
      # can move to the specified position. If no walkable area is
      # defined, all positions are considered walkable.
      #
      # - *point* : Position to check
      #
      # Returns: `true` if the position is walkable, `false` otherwise
      def is_walkable?(point : RL::Vector2) : Bool
        if walkable = @walkable_area
          walkable.is_point_walkable?(point)
        else
          # If no walkable area defined, allow movement everywhere
          true
        end
      end

      # Checks if a character-sized area is walkable
      #
      # Tests multiple points around the character's bounds to ensure
      # the entire character can fit in the space, not just their center point.
      #
      # - *center* : Center position of the character
      # - *size* : Character's size (width, height)
      # - *scale* : Character's scale factor
      def is_area_walkable?(center : RL::Vector2, size : RL::Vector2, scale : Float32 = 1.0) : Bool
        return true unless walkable = @walkable_area

        # Calculate half extents with scale
        half_width = (size.x * scale) / 2.0
        half_height = (size.y * scale) / 2.0

        # Use a significantly smaller collision box to allow for easier movement
        # This prevents characters from getting stuck on edges and allows smoother navigation
        collision_margin = 0.6_f32 # Use 60% of actual size for more forgiving collision

        # Check multiple points around the character bounds
        # We check corners and midpoints for better accuracy
        check_points = [
          # Center
          center,
          # Corners (with margin)
          RL::Vector2.new(x: center.x - half_width * collision_margin, y: center.y - half_height * collision_margin),
          RL::Vector2.new(x: center.x + half_width * collision_margin, y: center.y - half_height * collision_margin),
          RL::Vector2.new(x: center.x - half_width * collision_margin, y: center.y + half_height * collision_margin),
          RL::Vector2.new(x: center.x + half_width * collision_margin, y: center.y + half_height * collision_margin),
          # Midpoints of edges (with margin)
          RL::Vector2.new(x: center.x, y: center.y - half_height * collision_margin),
          RL::Vector2.new(x: center.x, y: center.y + half_height * collision_margin),
          RL::Vector2.new(x: center.x - half_width * collision_margin, y: center.y),
          RL::Vector2.new(x: center.x + half_width * collision_margin, y: center.y),
        ]

        # Debug - check which points are failing
        if Core::Engine.debug_mode
          failed_points = [] of RL::Vector2
          check_points.each do |point|
            unless walkable.is_point_walkable?(point)
              failed_points << point
            end
          end

          if failed_points.size > 0
            puts "[AREA_CHECK] #{failed_points.size}/#{check_points.size} points failed at center #{center}"
            puts "[AREA_CHECK] Character bounds: #{size.x * scale}x#{size.y * scale}"
            failed_points.first(3).each do |fp|
              puts "[AREA_CHECK]   Failed point: #{fp}"
            end
          end
        end

        # Require at least 5 out of 9 points to be walkable (very lenient)
        # This allows characters to navigate tight spaces and clip corners without getting stuck
        # The center point must always be walkable, plus at least 4 other points
        walkable_count = check_points.count { |point| walkable.is_point_walkable?(point) }
        center_walkable = walkable.is_point_walkable?(center)

        # Center must be walkable AND at least 4 other points (5 total)
        center_walkable && walkable_count >= 5
      end

      # Gets the character scale factor at a specific Y position
      #
      # Uses the walkable area's depth information to determine the
      # appropriate scale for characters at different Y positions,
      # creating perspective effects.
      #
      # - *y_position* : Y coordinate to check
      #
      # Returns: Scale factor (1.0 = normal size)
      def get_character_scale(y_position : Float32) : Float32
        @walkable_area.try(&.get_scale_at_y(y_position)) || 1.0f32
      end

      # Finds a path between two points using the pathfinding system
      #
      # Calculates the optimal route between start and end positions,
      # taking into account walkable areas and obstacles.
      #
      # - *start_x* : Starting X coordinate
      # - *start_y* : Starting Y coordinate
      # - *end_x* : Destination X coordinate
      # - *end_y* : Destination Y coordinate
      #
      # Returns: Array of waypoints forming the path, or `nil` if no path exists
      def find_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Array(Raylib::Vector2)?
        return nil unless pf = @pathfinder
        return nil unless grid = @navigation_grid

        # Debug: Check if start/end positions are walkable
        start_grid_x, start_grid_y = grid.world_to_grid(start_x, start_y)
        end_grid_x, end_grid_y = grid.world_to_grid(end_x, end_y)

        start_walkable = grid.is_walkable?(start_grid_x, start_grid_y)
        end_walkable = grid.is_walkable?(end_grid_x, end_grid_y)

        puts "[PATHFINDING] Start (#{start_x.round(1)}, #{start_y.round(1)}) -> Grid(#{start_grid_x}, #{start_grid_y}) walkable: #{start_walkable}"
        puts "[PATHFINDING] End (#{end_x.round(1)}, #{end_y.round(1)}) -> Grid(#{end_grid_x}, #{end_grid_y}) walkable: #{end_walkable}"

        # Debug: Check if this is near the player spawn
        if (start_x - 300).abs < 10 && (start_y - 500).abs < 10
          puts "[DEBUG] This is near player spawn (300, 500)!"
          # Check surrounding cells
          (-1..1).each do |dy|
            (-1..1).each do |dx|
              gx = start_grid_x + dx
              gy = start_grid_y + dy
              if gx >= 0 && gy >= 0 && gx < grid.width && gy < grid.height
                walkable = grid.is_walkable?(gx, gy)
                wx, wy = grid.grid_to_world(gx, gy)
                puts "[DEBUG]   Grid(#{gx}, #{gy}) at world(#{wx}, #{wy}) = #{walkable ? "WALK" : "BLOCK"}"
              end
            end
          end
        end

        if !end_walkable
          puts "[PATHFINDING] Cannot find path: end position is not walkable!"
          return nil
        end

        if !start_walkable
          puts "[PATHFINDING] Warning: Start position is not walkable, but attempting pathfinding anyway (character is already there)"
        end

        pf.find_path(start_x, start_y, end_x, end_y)
      end

      # Draws navigation debug information
      #
      # Renders the pathfinding grid and navigation data when debug mode
      # is enabled. Green indicates walkable areas, red indicates obstacles.
      private def draw_navigation_debug
        @pathfinder.try &.draw_debug(Raylib::GREEN, Raylib::RED, 50u8)
      end

      # Loads and executes the scene's script file
      #
      # Runs any scene-specific scripting logic defined in the script file.
      # Used for cutscenes, dialogue setup, and custom scene behavior.
      #
      # - *engine* : The game engine instance
      def load_script(engine : Core::Engine)
        return unless script_path = @script_path
        engine.script_engine.try &.execute_script_file(script_path)
      end
    end
  end
end
