# Base GameObject and Drawable module for all game entities

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Core
    # Drawable module for objects that can be rendered
    module Drawable
      property visible : Bool = true
      
      @[YAML::Field(converter: Utils::YAMLConverters::Vector2Converter)]
      property position : RL::Vector2
      
      @[YAML::Field(converter: Utils::YAMLConverters::Vector2Converter)]
      property size : RL::Vector2 = RL::Vector2.new

      abstract def draw

      def bounds : RL::Rectangle
        RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y)
      end

      def contains_point?(point : RL::Vector2) : Bool
        bounds = self.bounds
        point.x >= bounds.x &&
          point.x <= bounds.x + bounds.width &&
          point.y >= bounds.y &&
          point.y <= bounds.y + bounds.height
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        # Override in subclasses to reload assets
      end

      def draw_at_screen_pos(screen_pos : RL::Vector2)
        if engine = Core::Engine.instance
          if dm = engine.display_manager
            game_pos = dm.screen_to_game(screen_pos)
            # Draw at game_pos - implement in subclasses
          end
        end
      end
    end

    # Base class for all game objects
    abstract class GameObject
      include YAML::Serializable
      include Drawable

      property active : Bool = true

      def initialize
        @position = RL::Vector2.new
        @size = RL::Vector2.new
      end

      def initialize(@position : RL::Vector2, @size : RL::Vector2)
      end

      abstract def update(dt : Float32)
    end
  end
end