# Item Registry - Stores item definitions loaded from YAML
#
# Items are defined in YAML files and loaded at game start.
# When scripts call add_to_inventory("item_name"), the registry
# is consulted to get the full item definition (icon, description, etc.)

require "yaml"
require "./inventory_item"

module PointClickEngine
  module Inventory
    # Registry for item definitions loaded from YAML
    class ItemRegistry
      # Item definitions indexed by name
      @definitions : Hash(String, ItemDefinition) = {} of String => ItemDefinition

      # Base directory for resolving asset paths
      property base_dir : String = ""

      # Item definition from YAML
      class ItemDefinition
        include YAML::Serializable

        property name : String
        property display_name : String?
        property description : String = ""
        property examine_text : String?
        property icon_path : String?
        property usable_on : Array(String) = [] of String
        property combinable_with : Array(String) = [] of String
        property stackable : Bool = false
        property consumable : Bool = false
        property quest_item : Bool = false
        property readable : Bool = false
        property light_source : Bool = false
        property on_pickup : String?
        property on_use_wrong : String?
        property on_use_success : String?
      end

      # Items file wrapper for YAML parsing
      class ItemsFile
        include YAML::Serializable
        property items : Hash(String, ItemDefinition) = {} of String => ItemDefinition
      end

      def initialize
        @definitions = {} of String => ItemDefinition
      end

      # Load item definitions from a YAML file
      def load_from_file(path : String) : Bool
        return false unless File.exists?(path)

        begin
          content = File.read(path)
          items_file = ItemsFile.from_yaml(content)

          items_file.items.each do |name, definition|
            # Ensure the name field matches the key
            definition.name = name
            @definitions[name] = definition
          end

          puts "[ItemRegistry] Loaded #{items_file.items.size} item definitions from #{File.basename(path)}"
          true
        rescue ex
          puts "[ItemRegistry] Error loading items from #{path}: #{ex.message}"
          false
        end
      end

      # Get an item definition by name
      def get(name : String) : ItemDefinition?
        @definitions[name]?
      end

      # Check if an item is defined
      def has?(name : String) : Bool
        @definitions.has_key?(name)
      end

      # Create an InventoryItem from a definition
      def create_item(name : String) : InventoryItem?
        definition = get(name)
        return nil unless definition

        # Create item with full definition
        item = InventoryItem.new(
          definition.name,
          definition.description
        )

        # Set additional properties
        item.usable_on = definition.usable_on
        item.combinable_with = definition.combinable_with
        item.consumable = definition.consumable

        # Load icon if path specified
        if icon_path = definition.icon_path
          full_path = if base_dir.empty?
                        icon_path
                      else
                        File.join(base_dir, icon_path)
                      end

          if File.exists?(full_path)
            begin
              item.icon = RL.load_texture(full_path)
              item.icon_path = full_path
            rescue
              puts "[ItemRegistry] Warning: Could not load icon for #{name}: #{full_path}"
            end
          else
            puts "[ItemRegistry] Warning: Icon not found for #{name}: #{full_path}"
          end
        end

        item
      end

      # Get all defined item names
      def all_names : Array(String)
        @definitions.keys
      end

      # Get count of registered items
      def size : Int32
        @definitions.size
      end

      # Get on_pickup message for an item
      def on_pickup_message(name : String) : String?
        get(name).try(&.on_pickup)
      end

      # Get examine text for an item
      def examine_text(name : String) : String?
        get(name).try(&.examine_text)
      end

      # Get display name for an item
      def display_name(name : String) : String
        get(name).try(&.display_name) || name.gsub("_", " ").capitalize
      end
    end
  end
end
