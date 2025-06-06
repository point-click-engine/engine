# YAML Converters for Raylib types and other serialization helpers

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Utils
    module YAMLConverters
      # Vector2 converter
      struct Vector2Converter
        def self.to_yaml(vec : RL::Vector2, builder : YAML::Nodes::Builder)
          builder.mapping do |map|
            map.entry "x", vec.x
            map.entry "y", vec.y
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          x = node["x"].as(Float32)
          y = node["y"].as(Float32)
          RL::Vector2.new(x: x, y: y)
        end
      end

      # Color converter
      struct ColorConverter
        def self.to_yaml(color : RL::Color, builder : YAML::Nodes::Builder)
          builder.mapping do |map|
            map.entry "r", color.r
            map.entry "g", color.g
            map.entry "b", color.b
            map.entry "a", color.a
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          r = node["r"].as(UInt8)
          g = node["g"].as(UInt8)
          b = node["b"].as(UInt8)
          a = node["a"].as(UInt8)
          RL::Color.new(r: r, g: g, b: b, a: a)
        end
      end

      # Rectangle converter
      struct RectangleConverter
        def self.to_yaml(rect : RL::Rectangle, builder : YAML::Nodes::Builder)
          builder.mapping do |map|
            map.entry "x", rect.x
            map.entry "y", rect.y
            map.entry "width", rect.width
            map.entry "height", rect.height
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          x = node["x"].as(Float32)
          y = node["y"].as(Float32)
          width = node["width"].as(Float32)
          height = node["height"].as(Float32)
          RL::Rectangle.new(x: x, y: y, width: width, height: height)
        end
      end

      # Array of Vector2 converter for patrol behaviors
      struct Vector2ArrayConverter
        def self.to_yaml(array : Array(RL::Vector2), builder : YAML::Nodes::Builder)
          builder.sequence do |seq|
            array.each do |vec|
              seq.node do |node_builder|
                Vector2Converter.to_yaml(vec, node_builder)
              end
            end
          end
        end

        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          node.as_sequence.map do |item_node|
            Vector2Converter.from_yaml(ctx, item_node)
          end
        end
      end
    end
  end
end