# Player inventory system

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Inventory
    # Manages the player's inventory of items and item interactions
    #
    # The InventorySystem provides a visual grid-based interface for managing
    # collected items, supports item combination mechanics, and handles item
    # usage on scene objects. Items can be selected, combined with other items,
    # or used on hotspots and characters in the game world.
    #
    # ## Key Features
    # - Grid-based visual inventory display
    # - Item selection and combination system
    # - Drag-and-drop style interactions
    # - Item usage callbacks for scene integration
    # - Automatic item icon rendering
    # - YAML serialization for save/load functionality
    #
    # ## Usage Example
    # ```crystal
    # inventory = InventorySystem.new(Vector2.new(10, 10))
    # inventory.add_item(key_item)
    # inventory.add_item(potion_item)
    # 
    # inventory.on_item_used = ->(item : InventoryItem, target : String) {
    #   handle_item_usage(item, target)
    # }
    # 
    # inventory.on_items_combined = ->(item1, item2, action) {
    #   create_combined_item(item1, item2, action)
    # }
    # ```
    #
    # NOTE: The inventory automatically handles screen coordinate conversion
    # when used with the display manager.
    class InventorySystem
      include YAML::Serializable
      include Core::Drawable

      # Collection of items currently in the inventory
      property items : Array(InventoryItem) = [] of InventoryItem
      
      # Size of each inventory slot in pixels
      property slot_size : Float32 = 64.0
      
      # Padding between inventory slots in pixels
      property padding : Float32 = 8.0

      # Background color for the inventory panel (runtime only)
      @[YAML::Field(ignore: true)]
      property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 200)

      # Name of currently selected item for serialization
      property selected_item_name : String?
      
      # Reference to currently selected item (runtime only)
      @[YAML::Field(ignore: true)]
      property selected_item : InventoryItem?
      
      # Whether the system is in combination mode (runtime only)
      @[YAML::Field(ignore: true)]
      property combination_mode : Bool = false
      
      # Callback for when an item is used on a target (runtime only)
      @[YAML::Field(ignore: true)]
      property on_item_used : Proc(InventoryItem, String, Nil)?
      
      # Callback for when two items are combined (runtime only)
      @[YAML::Field(ignore: true)]
      property on_items_combined : Proc(InventoryItem, InventoryItem, String?, Nil)?

      # Creates an inventory system with default position
      #
      # The inventory starts hidden and must be made visible to display.
      def initialize
        @position = RL::Vector2.new(x: 10, y: 10)
        @visible = false
        @items = [] of InventoryItem
      end

      # Creates an inventory system at the specified position
      #
      # - *position* : Screen position for the inventory panel (default: 10,10)
      def initialize(@position : RL::Vector2 = RL::Vector2.new(x: 10, y: 10))
        @visible = false
        @items = [] of InventoryItem
      end

      # Restores runtime state after YAML deserialization
      #
      # Restores item state and reconnects the selected item reference.
      #
      # - *ctx* : YAML parsing context
      def after_yaml_deserialize(ctx : YAML::ParseContext)
        @items.each &.after_yaml_deserialize(ctx)
        if name = @selected_item_name
          @selected_item = get_item(name)
        end
      end

      # Adds an item to the inventory
      #
      # Prevents duplicate items with the same name from being added.
      # If an item with the same name already exists, it won't be added again.
      #
      # - *item* : The inventory item to add
      def add_item(item : InventoryItem)
        @items << item unless @items.any? { |existing_item| existing_item.name == item.name }
      end

      # Clears all items from the inventory
      #
      # Removes all items, deselects any selected item, and exits combination mode.
      def clear
        @items.clear
        @selected_item = nil
        @combination_mode = false
      end

      # Removes an item from the inventory by name
      #
      # If the removed item was selected, it will be deselected.
      #
      # - *item_name* : Name of the item to remove
      def remove_item(item_name : String)
        @items.reject! { |i| i.name == item_name }
        if @selected_item.try(&.name) == item_name
          @selected_item = nil
          @selected_item_name = nil
        end
      end

      # Removes an item from the inventory
      #
      # - *item* : The inventory item to remove
      def remove_item(item : InventoryItem)
        remove_item(item.name)
      end

      # Checks if an item with the specified name exists in the inventory
      #
      # - *name* : Name of the item to check for
      #
      # Returns: `true` if the item exists, `false` otherwise
      def has_item?(name : String) : Bool
        @items.any? { |i| i.name == name }
      end

      # Gets an item from the inventory by name
      #
      # - *name* : Name of the item to retrieve
      #
      # Returns: The inventory item, or `nil` if not found
      def get_item(name : String) : InventoryItem?
        @items.find { |i| i.name == name }
      end
      
      # Gets the item at a specific screen position
      #
      # Used for mouse interaction to determine which item was clicked.
      # Only works when the inventory is visible.
      #
      # - *pos* : Screen position to check
      #
      # Returns: The item at that position, or `nil` if none found
      def get_item_at_position(pos : RL::Vector2) : InventoryItem?
        return nil unless @visible
        
        @items.each_with_index do |item, index|
          item_rect = get_item_rect(index)
          if RL.check_collision_point_rec?(pos, item_rect)
            return item
          end
        end
        
        nil
      end

      # Selects an item by name
      #
      # The selected item will be highlighted and available for use or combination.
      #
      # - *name* : Name of the item to select
      def select_item(name : String)
        if item = get_item(name)
          @selected_item = item
          @selected_item_name = name
        end
      end

      # Deselects the currently selected item
      #
      # Also exits combination mode if active.
      def deselect_item
        @selected_item = nil
        @selected_item_name = nil
        @combination_mode = false
      end

      # Updates inventory interaction and input handling
      #
      # Processes mouse clicks on inventory items, handles selection and
      # combination mode, and manages coordinate conversion for proper
      # display scaling.
      #
      # - *dt* : Delta time in seconds since last update
      def update(dt : Float32)
        return unless @visible

        # Get the game coordinates from the display manager
        raw_mouse_pos = RL.get_mouse_position
        mouse_pos = raw_mouse_pos
        
        if engine = Core::Engine.instance
          if dm = engine.display_manager
            mouse_pos = dm.screen_to_game(raw_mouse_pos)
          end
        end
        
        if RL::MouseButton::Left.pressed?
          @items.each_with_index do |item, index|
            item_rect = get_item_rect(index)
            if RL.check_collision_point_rec?(mouse_pos, item_rect)
              handle_item_click(item)
              break
            end
          end
        end

        # Right click to cancel combination mode
        if RL::MouseButton::Right.pressed?
          @combination_mode = false
        end
      end

      # Handles clicking on an inventory item
      #
      # If in combination mode and a different item is clicked, attempts
      # to combine the items. Otherwise, selects the clicked item.
      #
      # - *item* : The item that was clicked
      private def handle_item_click(item : InventoryItem)
        if @combination_mode && @selected_item && @selected_item != item
          try_combine_items(@selected_item.not_nil!, item)
          @combination_mode = false
        else
          @selected_item = item
          @selected_item_name = item.name
        end
      end

      # Attempts to combine two inventory items
      #
      # Checks if either item can be combined with the other, then
      # executes the combination callback if a valid combination exists.
      #
      # - *item1* : First item in the combination
      # - *item2* : Second item in the combination
      private def try_combine_items(item1 : InventoryItem, item2 : InventoryItem)
        if item1.can_combine_with?(item2)
          action = item1.get_combine_action(item2.name)
          @on_items_combined.try(&.call(item1, item2, action))
        elsif item2.can_combine_with?(item1)
          action = item2.get_combine_action(item1.name)
          @on_items_combined.try(&.call(item2, item1, action))
        end
      end

      # Uses the selected item on a target object
      #
      # Checks if the selected item can be used on the specified target,
      # then executes the usage callback. Removes consumable items after use.
      #
      # - *target_name* : Name of the target object/character/hotspot
      def use_selected_item_on(target_name : String)
        return unless selected = @selected_item
        if selected.can_use_on?(target_name)
          @on_item_used.try(&.call(selected, target_name))
          remove_item(selected) if selected.consumable
        end
      end

      # Enters combination mode for the selected item
      #
      # Only works if an item is currently selected. In combination mode,
      # clicking another item will attempt to combine them.
      def start_combination_mode
        @combination_mode = true if @selected_item
      end

      # Renders the inventory panel and all contained items
      #
      # Draws the background panel, item slots, icons or names, selection
      # highlights, and combination mode indicators.
      def draw
        return unless @visible
        total_width = (@items.size * (@slot_size + @padding)) + @padding
        bg_rect = RL::Rectangle.new(x: @position.x, y: @position.y, width: total_width, height: @slot_size + @padding * 2)
        RL.draw_rectangle_rec(bg_rect, @background_color)

        @items.each_with_index do |item, index|
          item_rect = get_item_rect(index)
          RL.draw_rectangle_rec(item_rect, RL::Color.new(r: 50, g: 50, b: 50, a: 255))
          if icon = item.icon
            RL.draw_texture_ex(icon, RL::Vector2.new(x: item_rect.x, y: item_rect.y), 0.0,
              @slot_size / icon.width.to_f, RL::WHITE)
          else
            # Draw item name if no icon
            name_text = item.name.size > 8 ? item.name[0..7] : item.name
            text_size = 12
            text_width = RL.measure_text(name_text, text_size)
            text_x = (item_rect.x + @slot_size/2 - text_width/2).to_i
            text_y = (item_rect.y + @slot_size/2 - text_size/2).to_i
            RL.draw_text(name_text, text_x, text_y, text_size, RL::WHITE)
          end
          if item == @selected_item
            color = @combination_mode ? RL::RED : RL::YELLOW
            RL.draw_rectangle_lines_ex(item_rect, 2, color)
          end
        end

        # Draw combination mode indicator
        if @combination_mode
          text = "Combination Mode - Click another item"
          text_width = RL.measure_text(text, 16)
          RL.draw_text(text, (@position.x + total_width/2 - text_width/2).to_i,
            (@position.y - 25).to_i, 16, RL::RED)
        end
      end

      # Calculates the screen rectangle for an item slot
      #
      # Used for rendering and collision detection for inventory items.
      #
      # - *index* : Index of the item in the inventory array
      #
      # Returns: Rectangle defining the item's screen area
      private def get_item_rect(index : Int32) : RL::Rectangle
        x = @position.x + @padding + (index * (@slot_size + @padding))
        y = @position.y + @padding
        RL::Rectangle.new(x: x, y: y, width: @slot_size, height: @slot_size)
      end
    end
  end
end
