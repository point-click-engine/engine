# Player inventory system

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Inventory
    # Player inventory management
    class InventorySystem
      include YAML::Serializable
      include Core::Drawable

      property items : Array(InventoryItem) = [] of InventoryItem
      property slot_size : Float32 = 64.0
      property padding : Float32 = 8.0

      @[YAML::Field(ignore: true)]
      property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 200)

      property selected_item_name : String?
      @[YAML::Field(ignore: true)]
      property selected_item : InventoryItem?
      @[YAML::Field(ignore: true)]
      property combination_mode : Bool = false
      @[YAML::Field(ignore: true)]
      property on_item_used : Proc(InventoryItem, String, Nil)?
      @[YAML::Field(ignore: true)]
      property on_items_combined : Proc(InventoryItem, InventoryItem, String?, Nil)?

      def initialize
        @position = RL::Vector2.new(x: 10, y: 10)
        @visible = false
        @items = [] of InventoryItem
      end

      def initialize(@position : RL::Vector2 = RL::Vector2.new(x: 10, y: 10))
        @visible = false
        @items = [] of InventoryItem
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        @items.each &.after_yaml_deserialize(ctx)
        if name = @selected_item_name
          @selected_item = get_item(name)
        end
      end

      def add_item(item : InventoryItem)
        @items << item unless @items.any? { |existing_item| existing_item.name == item.name }
      end

      def remove_item(item_name : String)
        @items.reject! { |i| i.name == item_name }
        if @selected_item.try(&.name) == item_name
          @selected_item = nil
          @selected_item_name = nil
        end
      end

      def remove_item(item : InventoryItem)
        remove_item(item.name)
      end

      def has_item?(name : String) : Bool
        @items.any? { |i| i.name == name }
      end

      def get_item(name : String) : InventoryItem?
        @items.find { |i| i.name == name }
      end

      def update(dt : Float32)
        return unless @visible

        mouse_pos = RL.get_mouse_position
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

      def handle_item_click(item : InventoryItem)
        if @combination_mode && @selected_item && @selected_item != item
          try_combine_items(@selected_item.not_nil!, item)
          @combination_mode = false
        else
          @selected_item = item
          @selected_item_name = item.name
        end
      end

      def try_combine_items(item1 : InventoryItem, item2 : InventoryItem)
        if item1.can_combine_with?(item2)
          action = item1.get_combine_action(item2.name)
          @on_items_combined.try(&.call(item1, item2, action))
        elsif item2.can_combine_with?(item1)
          action = item2.get_combine_action(item1.name)
          @on_items_combined.try(&.call(item2, item1, action))
        end
      end

      def use_selected_item_on(target_name : String)
        return unless selected = @selected_item
        if selected.can_use_on?(target_name)
          @on_item_used.try(&.call(selected, target_name))
          remove_item(selected) if selected.consumable
        end
      end

      def start_combination_mode
        @combination_mode = true if @selected_item
      end

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

      private def get_item_rect(index : Int32) : RL::Rectangle
        x = @position.x + @padding + (index * (@slot_size + @padding))
        y = @position.y + @padding
        RL::Rectangle.new(x: x, y: y, width: @slot_size, height: @slot_size)
      end
    end
  end
end
