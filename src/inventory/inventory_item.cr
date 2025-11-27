# Inventory item implementation

require "yaml"
require "../core/error_handling"

module PointClickEngine
  module Inventory
    # Validation error for inventory items
    class ItemValidationError < Core::ValidationError
      getter item_name : String?

      def initialize(errors : Array(String), @item_name : String? = nil)
        super(errors)
      end

      def initialize(message : String, @item_name : String? = nil)
        super(message)
      end
    end

    # Individual inventory item
    class InventoryItem
      include YAML::Serializable

      # Valid characters for item names: alphanumeric, underscore, dash
      NAME_PATTERN = /\A[a-zA-Z][a-zA-Z0-9_-]*\z/

      # Maximum lengths
      MAX_NAME_LENGTH      = 64
      MAX_DESC_LENGTH      = 500
      MAX_COMBINABLES      = 50
      MAX_USABLE_ON        = 50
      MAX_COMBINE_ACTIONS  = 50

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
        validate!
      end

      # Validates the item and raises ItemValidationError if invalid
      def validate! : Nil
        errors = validate
        unless errors.empty?
          raise ItemValidationError.new(errors, @name)
        end
      end

      # Validates the item and returns an array of error messages
      def validate : Array(String)
        errors = [] of String

        # Validate name
        if @name.empty?
          errors << "Item name cannot be empty"
        elsif @name.size > MAX_NAME_LENGTH
          errors << "Item name too long (max #{MAX_NAME_LENGTH} characters)"
        elsif !NAME_PATTERN.matches?(@name)
          errors << "Item name must start with a letter and contain only letters, numbers, underscores, and dashes"
        end

        # Validate description
        if @description.size > MAX_DESC_LENGTH
          errors << "Item description too long (max #{MAX_DESC_LENGTH} characters)"
        end

        # Validate arrays
        if @combinable_with.size > MAX_COMBINABLES
          errors << "Too many combinable items (max #{MAX_COMBINABLES})"
        end

        if @usable_on.size > MAX_USABLE_ON
          errors << "Too many usable_on targets (max #{MAX_USABLE_ON})"
        end

        if @combine_actions.size > MAX_COMBINE_ACTIONS
          errors << "Too many combine actions (max #{MAX_COMBINE_ACTIONS})"
        end

        # Validate combinable items are also in combine_actions
        @combinable_with.each do |item|
          unless NAME_PATTERN.matches?(item)
            errors << "Invalid combinable item name: #{item}"
          end
        end

        # Validate usable_on targets
        @usable_on.each do |target|
          if target.empty?
            errors << "Empty target name in usable_on list"
          end
        end

        errors
      end

      # Check if item is valid
      def valid? : Bool
        validate.empty?
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
        @icon = AssetLoader.load_texture(path)
      end
    end
  end
end
