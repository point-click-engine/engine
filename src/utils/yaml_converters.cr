# YAML Converters for Raylib types and other serialization helpers

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Utils
    module YAMLConverters
      # Vector2 converter
      struct Vector2Converter
        def self.to_yaml(vec : RL::Vector2, yaml : YAML::Nodes::Builder)
          yaml.mapping do
            yaml.scalar "x"
            yaml.scalar vec.x
            yaml.scalar "y" 
            yaml.scalar vec.y
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          unless node.is_a?(YAML::Nodes::Mapping)
            node.raise "Expected mapping, not #{node.class}"
          end
          
          x = y = 0_f32
          node.each do |key, value|
            case key.as_s
            when "x"
              x = value.as_f32
            when "y"
              y = value.as_f32
            end
          end
          RL::Vector2.new(x: x, y: y)
        end
      end

      # Color converter
      struct ColorConverter
        def self.to_yaml(color : RL::Color, yaml : YAML::Nodes::Builder)
          yaml.mapping do
            yaml.scalar "r"
            yaml.scalar color.r
            yaml.scalar "g"
            yaml.scalar color.g
            yaml.scalar "b"
            yaml.scalar color.b
            yaml.scalar "a"
            yaml.scalar color.a
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          unless node.is_a?(YAML::Nodes::Mapping)
            node.raise "Expected mapping, not #{node.class}"
          end
          
          r = g = b = a = 0_u8
          node.each do |key, value|
            case key.as_s
            when "r"
              r = value.as_i.to_u8
            when "g"
              g = value.as_i.to_u8
            when "b"
              b = value.as_i.to_u8
            when "a"
              a = value.as_i.to_u8
            end
          end
          RL::Color.new(r: r, g: g, b: b, a: a)
        end
      end

      # Rectangle converter
      struct RectangleConverter
        def self.to_yaml(rect : RL::Rectangle, yaml : YAML::Nodes::Builder)
          yaml.mapping do
            yaml.scalar "x"
            yaml.scalar rect.x
            yaml.scalar "y"
            yaml.scalar rect.y
            yaml.scalar "width"
            yaml.scalar rect.width
            yaml.scalar "height"
            yaml.scalar rect.height
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          unless node.is_a?(YAML::Nodes::Mapping)
            node.raise "Expected mapping, not #{node.class}"
          end
          
          x = y = width = height = 0_f32
          node.each do |key, value|
            case key.as_s
            when "x"
              x = value.as_f32
            when "y"
              y = value.as_f32
            when "width"
              width = value.as_f32
            when "height"
              height = value.as_f32
            end
          end
          RL::Rectangle.new(x: x, y: y, width: width, height: height)
        end
      end

      # Array of Vector2 converter for patrol behaviors
      struct Vector2ArrayConverter
        def self.to_yaml(array : Array(RL::Vector2), yaml : YAML::Nodes::Builder)
          yaml.sequence do
            array.each do |vec|
              Vector2Converter.to_yaml(vec, yaml)
            end
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          unless node.is_a?(YAML::Nodes::Sequence)
            node.raise "Expected sequence, not #{node.class}"
          end
          
          result = [] of RL::Vector2
          node.each do |item_node|
            result << Vector2Converter.from_yaml(ctx, item_node)
          end
          result
        end
      end
    end
  end
end