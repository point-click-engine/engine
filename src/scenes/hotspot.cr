# Hotspot implementation for interactive areas

require "raylib-cr"
require "yaml"
require "../utils/yaml_converters"
require "../ui/cursor_manager"

module PointClickEngine
  module Scenes
    # Clickable hotspot in the game
    class Hotspot < Core::GameObject
      property name : String
      property description : String = ""
      property cursor_type : CursorType = CursorType::Hand
      property blocks_movement : Bool = false
      property default_verb : UI::VerbType?
      property object_type : UI::ObjectType = UI::ObjectType::Background
      @[YAML::Field(ignore: true)]
      property on_click : Proc(Nil)?
      @[YAML::Field(ignore: true)]
      property on_hover : Proc(Nil)?

      @[YAML::Field(ignore: true)]
      property debug_color : RL::Color = RL::Color.new(r: 255, g: 0, b: 0, a: 100)

      enum CursorType
        Default
        Hand
        Look
        Talk
        Use
      end

      def initialize
        super()
        @name = ""
        @description = ""
      end

      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(position, size)
        @description = ""
      end

      def update(dt : Float32)
        return unless @active

        mouse_pos = RL.get_mouse_position
        if contains_point?(mouse_pos)
          @on_hover.try &.call
          if RL::MouseButton::Left.pressed?
            @on_click.try &.call
          end
        end
      end

      def draw
        if Core::Engine.debug_mode && @visible
          draw_debug
        end
      end
      
      # Override this method in subclasses for custom debug rendering
      def draw_debug
        RL.draw_rectangle_rec(bounds, @debug_color)
      end
      
      # Get outline points for rendering (override in polygon hotspot)
      def get_outline_points : Array(RL::Vector2)
        # Return rectangle corners for rectangular hotspot
        [
          RL::Vector2.new(x: @position.x, y: @position.y),
          RL::Vector2.new(x: @position.x + @size.x, y: @position.y),
          RL::Vector2.new(x: @position.x + @size.x, y: @position.y + @size.y),
          RL::Vector2.new(x: @position.x, y: @position.y + @size.y)
        ]
      end
    end
  end
end
