# YAML Converters for Raylib types and other serialization helpers

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Utils
    module YAMLConverters
      # Helper to convert Vector2 to/from YAML
      def self.vector2_to_yaml(vec : RL::Vector2) : String
        {"x" => vec.x, "y" => vec.y}.to_yaml
      end

      def self.vector2_from_yaml(yaml_string : String) : RL::Vector2
        data = Hash(String, Float32 | Float64).from_yaml(yaml_string)
        RL::Vector2.new(x: data["x"].to_f32, y: data["y"].to_f32)
      end

      # Helper to convert Color to/from YAML
      def self.color_to_yaml(color : RL::Color) : String
        {"r" => color.r, "g" => color.g, "b" => color.b, "a" => color.a}.to_yaml
      end

      def self.color_from_yaml(yaml_string : String) : RL::Color
        data = Hash(String, Int32).from_yaml(yaml_string)
        RL::Color.new(r: data["r"].to_u8, g: data["g"].to_u8, b: data["b"].to_u8, a: data["a"].to_u8)
      end

      # Helper to convert Rectangle to/from YAML
      def self.rectangle_to_yaml(rect : RL::Rectangle) : String
        {"x" => rect.x, "y" => rect.y, "width" => rect.width, "height" => rect.height}.to_yaml
      end

      def self.rectangle_from_yaml(yaml_string : String) : RL::Rectangle
        data = Hash(String, Float32 | Float64).from_yaml(yaml_string)
        RL::Rectangle.new(x: data["x"].to_f32, y: data["y"].to_f32, width: data["width"].to_f32, height: data["height"].to_f32)
      end

      # Helper to convert Array(Vector2) to/from YAML
      def self.vector2_array_to_yaml(array : Array(RL::Vector2)) : String
        array.map { |v| {"x" => v.x, "y" => v.y} }.to_yaml
      end

      def self.vector2_array_from_yaml(yaml_string : String) : Array(RL::Vector2)
        data = Array(Hash(String, Float32 | Float64)).from_yaml(yaml_string)
        data.map { |h| RL::Vector2.new(x: h["x"].to_f32, y: h["y"].to_f32) }
      end
    end
  end
end
