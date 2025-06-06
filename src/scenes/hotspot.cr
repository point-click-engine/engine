# Hotspot implementation for interactive areas

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Scenes
    # Clickable hotspot in the game
    class Hotspot < Core::GameObject
      property name : String
      property cursor_type : CursorType = CursorType::Hand
      @[YAML::Field(ignore: true)]
      property on_click : Proc(Nil)?
      @[YAML::Field(ignore: true)]
      property on_hover : Proc(Nil)?
      
      @[YAML::Field(converter: Utils::YAMLConverters::ColorConverter)]
      property debug_color : RL::Color = RL::Color.new(r: 255, g: 0, b: 0, a: 100)

      enum CursorType
        Default
        Hand
        Look
        Talk
        Use
      end

      def initialize
        super(RL::Vector2.new, RL::Vector2.new)
        @name = ""
      end

      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(position, size)
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
          RL.draw_rectangle_rec(bounds, @debug_color)
        end
      end
    end
  end
end