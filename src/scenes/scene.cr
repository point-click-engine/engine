# Scene management for game environments

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Scenes
    # Game scene/room representation
    class Scene
      include YAML::Serializable

      property name : String
      property background_path : String?
      @[YAML::Field(ignore: true)]
      property background : RL::Texture2D?
      property hotspots : Array(Hotspot) = [] of Hotspot
      property objects : Array(Core::GameObject) = [] of Core::GameObject
      property characters : Array(Characters::Character) = [] of Characters::Character
      @[YAML::Field(ignore: true)]
      property on_enter : Proc(Nil)?
      @[YAML::Field(ignore: true)]
      property on_exit : Proc(Nil)?
      property scale : Float32 = 1.0

      property player_name_for_serialization : String?
      @[YAML::Field(ignore: true)]
      property player : Characters::Player?

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
        @background = RL.load_texture(path)
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
      end

      def draw
        if bg = @background
          RL.draw_texture_ex(bg, RL::Vector2.new(x: 0, y: 0), 0.0, @scale, RL::WHITE)
        end
        @objects.each(&.draw)
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
    end
  end
end
