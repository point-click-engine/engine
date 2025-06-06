# YAML Converters for Raylib types and other serialization helpers

require "raylib-cr"
require "yaml"

# Extend Vector2 with YAML support
struct RL::Vector2
  include YAML::Serializable

  # Keep the original constructors
  def initialize
    @x = 0.0f32
    @y = 0.0f32
  end

  def initialize(@x : Float32, @y : Float32)
  end
end

module PointClickEngine
  module Utils
    module YAMLConverters
      # YAML::Field converter for Vector2
      module Vector2Converter
        def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : RL::Vector2
          case node
          when YAML::Nodes::Mapping
            x = y = 0.0f32
            node.each do |key_node, value_node|
              case key_node
              when YAML::Nodes::Scalar
                key = key_node.value
                case value_node
                when YAML::Nodes::Scalar
                  value = value_node.value.to_f32
                  case key
                  when "x"
                    x = value
                  when "y"
                    y = value
                  end
                end
              end
            end
            RL::Vector2.new(x: x, y: y)
          else
            RL::Vector2.new(x: 0.0f32, y: 0.0f32)
          end
        end

        def self.to_yaml(value : RL::Vector2, yaml : YAML::Nodes::Builder) : Nil
          yaml.mapping do
            yaml.scalar "x"
            yaml.scalar value.x.to_s
            yaml.scalar "y"
            yaml.scalar value.y.to_s
          end
        end
      end

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
