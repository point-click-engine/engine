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
      property usable_on : Array(String) = [] of String
      property consumable : Bool = false
      property use_action : String?
      property combine_actions : Hash(String, String) = {} of String => String

      def initialize
        @name = ""
        @description = ""
      end

      def initialize(@name : String, @description : String)
      end

      def can_combine_with?(other_item : InventoryItem) : Bool
        @combinable_with.includes?(other_item.name)
      end

      def can_use_on?(target_name : String) : Bool
        @usable_on.includes?(target_name)
      end

      def get_combine_action(other_item_name : String) : String?
        @combine_actions[other_item_name]?
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
