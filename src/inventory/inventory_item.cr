# Inventory item implementation

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Inventory
    # Individual inventory item
    class InventoryItem
      include YAML::Serializable

      property name : String
      property description : String
      property icon_path : String?
      @[YAML::Field(ignore: true)]
      property icon : RL::Texture2D?
      property combinable_with : Array(String) = [] of String

      def initialize
        @name = ""
        @description = ""
      end

      def initialize(@name : String, @description : String)
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        if path = @icon_path
          load_icon(path)
        end
      end

      def load_icon(path : String)
        @icon_path = path
        @icon = RL.load_texture(path)
      end
    end
  end
end