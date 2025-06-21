# Scene management for game environments

require "raylib-cr"
require "yaml"
require "../navigation/pathfinding"
require "../assets/asset_loader"
require "./walkable_area"

module PointClickEngine
  module Scenes
    # Game scene/room representation
    class Scene
      include YAML::Serializable

      property name : String
      property background_path : String?
      @[YAML::Field(ignore: true)]
      property background : RL::Texture2D?
      @[YAML::Field(ignore: true)]
      property hotspots : Array(Hotspot) = [] of Hotspot
      @[YAML::Field(ignore: true)]
      property objects : Array(Core::GameObject) = [] of Core::GameObject
      @[YAML::Field(ignore: true)]
      property characters : Array(Characters::Character) = [] of Characters::Character
      @[YAML::Field(ignore: true)]
      property on_enter : Proc(Nil)?
      @[YAML::Field(ignore: true)]
      property on_exit : Proc(Nil)?
      property scale : Float32 = 1.0

      property player_name_for_serialization : String?
      @[YAML::Field(ignore: true)]
      property player : Characters::Player?

      @[YAML::Field(ignore: true)]
      property navigation_grid : Navigation::Pathfinding::NavigationGrid?
      @[YAML::Field(ignore: true)]
      property pathfinder : Navigation::Pathfinding?

      property enable_pathfinding : Bool = true
      property navigation_cell_size : Int32 = 16
      property script_path : String?
      
      @[YAML::Field(ignore: true)]
      property walkable_area : WalkableArea?

      def initialize
        @name = ""
        @objects = [] of Core::GameObject
        @hotspots = [] of Hotspot
        @characters = [] of Characters::Character
      end

      def initialize(@name : String)
        @objects = [] of Core::GameObject
        @hotspots = [] of Hotspot
        @characters = [] of Characters::Character
      end

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

      def load_background(path : String, scale : Float32 = 1.0)
        @background_path = path
        @background = PointClickEngine::AssetLoader.load_texture(path)
        @scale = scale
      end

      def add_hotspot(hotspot : Hotspot)
        @hotspots << hotspot
        @objects << hotspot unless @objects.includes?(hotspot)
      end

      def add_object(object : Core::GameObject)
        @objects << object unless @objects.includes?(object)
      end

      def add_character(character : Characters::Character)
        @characters << character unless @characters.includes?(character)
        add_object(character) unless @objects.includes?(character)
      end

      def set_player(player : Characters::Player)
        @player = player
        @player_name_for_serialization = player.name
        add_character(player) unless @characters.includes?(player)
      end

      def update(dt : Float32)
        @objects.each(&.update(dt))
        
        # Update character scales based on position
        if walkable = @walkable_area
          @characters.each do |character|
            scale = walkable.get_scale_at_y(character.position.y)
            character.scale = scale
          end
          
          @player.try do |p|
            scale = walkable.get_scale_at_y(p.position.y)
            p.scale = scale
          end
        end
      end

      def draw
        if bg = @background
          # Calculate scale to fit screen (1024x768)
          scale_x = 1024.0f32 / bg.width
          scale_y = 768.0f32 / bg.height
          scale = Math.max(scale_x, scale_y) # Use the larger scale to fill screen

          RL.draw_texture_ex(bg, RL::Vector2.new(x: 0, y: 0), 0.0, scale, RL::WHITE)
        end
        
        # Sort characters by Y position for proper depth
        all_characters = @characters.dup
        if player = @player
          all_characters << player
        end
        sorted_characters = all_characters.sort_by(&.position.y)
        
        # Draw scene elements with proper depth sorting
        @hotspots.each(&.draw)
        
        # Draw objects and characters with walk-behind support
        if walkable = @walkable_area
          sorted_characters.each do |character|
            # Draw walk-behind regions that should appear in front
            behind_regions = walkable.get_walk_behind_at_y(character.position.y)
            
            # Draw the character
            character.draw
            
            # Draw walk-behind regions on top if needed
            # (In a full implementation, we'd draw masked background parts here)
          end
          
          # Draw other objects
          @objects.each do |obj|
            obj.draw unless obj.is_a?(Characters::Character)
          end
        else
          # No walkable area defined, use simple drawing
          @objects.each(&.draw)
          sorted_characters.each(&.draw)
        end
        
        # Draw navigation debug if enabled
        if Core::Engine.debug_mode
          if @navigation_grid
            draw_navigation_debug
          end
          
          # Draw walkable area debug
          @walkable_area.try(&.draw_debug)
        end
      end

      def enter
        @on_enter.try &.call
      end

      def exit
        @on_exit.try &.call
      end

      def get_hotspot_at(point : RL::Vector2) : Hotspot?
        @hotspots.find { |h| h.active && h.contains_point?(point) }
      end

      def get_character_at(point : RL::Vector2) : Characters::Character?
        @characters.find { |c| c.active && c.contains_point?(point) && c != @player }
      end

      def get_character(name : String) : Characters::Character?
        @characters.find { |c| c.name == name }
      end

      def setup_navigation
        return unless @enable_pathfinding
        return unless bg = @background

        @navigation_grid = Navigation::Pathfinding::NavigationGrid.from_scene(
          self,
          bg.width,
          bg.height,
          @navigation_cell_size
        )

        @pathfinder = Navigation::Pathfinding.new(@navigation_grid.not_nil!)
      end
      
      # Check if a point is walkable
      def is_walkable?(point : RL::Vector2) : Bool
        if walkable = @walkable_area
          walkable.is_point_walkable?(point)
        else
          # If no walkable area defined, allow movement everywhere
          true
        end
      end
      
      # Get character scale at Y position
      def get_character_scale(y_position : Float32) : Float32
        @walkable_area.try(&.get_scale_at_y(y_position)) || 1.0f32
      end

      def find_path(start_x : Float32, start_y : Float32, end_x : Float32, end_y : Float32) : Array(Raylib::Vector2)?
        return nil unless pf = @pathfinder
        pf.find_path(start_x, start_y, end_x, end_y)
      end

      def draw_navigation_debug
        @pathfinder.try &.draw_debug(Raylib::GREEN, Raylib::RED, 50u8)
      end

      def load_script(engine : Core::Engine)
        return unless script_path = @script_path
        engine.script_engine.try &.execute_script_file(script_path)
      end
    end
  end
end
