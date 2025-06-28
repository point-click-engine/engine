# Inventory rendering for grid-based item displays

require "./nine_patch"
require "../sprites/sprite"

module PointClickEngine
  module Graphics
    module UI
      # Inventory slot for rendering
      struct InventorySlot
        property position : RL::Vector2
        property size : RL::Vector2
        property item_id : String?
        property quantity : Int32 = 1
        property highlighted : Bool = false
        property selected : Bool = false

        def initialize(@position : RL::Vector2, @size : RL::Vector2)
        end

        def bounds : RL::Rectangle
          RL::Rectangle.new(
            x: @position.x,
            y: @position.y,
            width: @size.x,
            height: @size.y
          )
        end

        def contains?(x : Float32, y : Float32) : Bool
          bounds = self.bounds
          x >= bounds.x && x <= bounds.x + bounds.width &&
            y >= bounds.y && y <= bounds.y + bounds.height
        end
      end

      # Inventory grid renderer
      class InventoryRenderer
        # Grid properties
        property columns : Int32 = 6
        property rows : Int32 = 4
        property slot_size : Float32 = 64.0f32
        property slot_spacing : Float32 = 8.0f32
        property padding : Float32 = 16.0f32

        # Visual properties
        property background : NinePatch?
        property slot_background : NinePatch?
        property slot_highlight : NinePatch?
        property slot_selected : NinePatch?

        # Colors
        property background_color : RL::Color = RL::Color.new(r: 40, g: 40, b: 40, a: 200)
        property slot_color : RL::Color = RL::Color.new(r: 60, g: 60, b: 60, a: 255)
        property highlight_color : RL::Color = RL::Color.new(r: 100, g: 100, b: 100, a: 255)
        property selected_color : RL::Color = RL::Color.new(r: 200, g: 200, b: 100, a: 255)

        # Item rendering
        property item_scale : Float32 = 0.8f32 # Scale items to fit in slots
        property show_quantity : Bool = true
        property quantity_offset : RL::Vector2 = RL::Vector2.new(x: -8, y: -8)

        # Slots
        getter slots : Array(InventorySlot)

        # Item sprites cache
        @item_sprites : Hash(String, Sprites::Sprite) = {} of String => Sprites::Sprite

        # Text renderer for quantity
        @text_renderer : TextRenderer

        def initialize(@columns : Int32 = 6, @rows : Int32 = 4)
          @slots = [] of InventorySlot
          @text_renderer = TextRenderer.new
          @text_renderer.font_size = 12
          @text_renderer.color = RL::WHITE
          @text_renderer.outline_color = RL::BLACK
          @text_renderer.outline_thickness = 1

          create_slots
        end

        # Create inventory slots
        def create_slots
          @slots.clear

          @rows.times do |row|
            @columns.times do |col|
              x = @padding + col * (@slot_size + @slot_spacing)
              y = @padding + row * (@slot_size + @slot_spacing)

              slot = InventorySlot.new(
                RL::Vector2.new(x: x, y: y),
                RL::Vector2.new(x: @slot_size, y: @slot_size)
              )
              @slots << slot
            end
          end
        end

        # Set item in slot
        def set_item(index : Int32, item_id : String?, quantity : Int32 = 1)
          return unless slot = @slots[index]?

          slot.item_id = item_id
          slot.quantity = quantity
        end

        # Set item in grid position
        def set_item_at(column : Int32, row : Int32, item_id : String?, quantity : Int32 = 1)
          index = row * @columns + column
          set_item(index, item_id, quantity)
        end

        # Add item sprite to cache
        def add_item_sprite(item_id : String, sprite : Sprites::Sprite)
          @item_sprites[item_id] = sprite
        end

        # Load item sprite
        def load_item_sprite(item_id : String, texture_path : String)
          sprite = Sprites::Sprite.new(texture_path)
          sprite.center_origin
          add_item_sprite(item_id, sprite)
        end

        # Get total size
        def total_width : Float32
          @padding * 2 + @columns * @slot_size + (@columns - 1) * @slot_spacing
        end

        def total_height : Float32
          @padding * 2 + @rows * @slot_size + (@rows - 1) * @slot_spacing
        end

        # Get slot at position
        def slot_at(x : Float32, y : Float32) : Int32?
          @slots.each_with_index do |slot, index|
            return index if slot.contains?(x, y)
          end
          nil
        end

        # Highlight slot
        def highlight_slot(index : Int32?)
          @slots.each_with_index do |slot, i|
            slot.highlighted = (i == index)
          end
        end

        # Select slot
        def select_slot(index : Int32?)
          @slots.each_with_index do |slot, i|
            slot.selected = (i == index)
          end
        end

        # Draw inventory at position
        def draw(x : Float32, y : Float32)
          # Draw background
          if bg = @background
            bg.draw(x, y, total_width, total_height)
          else
            RL.draw_rectangle(x.to_i, y.to_i, total_width.to_i, total_height.to_i, @background_color)
          end

          # Draw slots
          @slots.each do |slot|
            draw_slot(slot, x, y)
          end
        end

        # Draw centered on screen
        def draw_centered(screen_width : Float32 = Display::REFERENCE_WIDTH.to_f32,
                          screen_height : Float32 = Display::REFERENCE_HEIGHT.to_f32)
          x = (screen_width - total_width) / 2
          y = (screen_height - total_height) / 2
          draw(x, y)
        end

        private def draw_slot(slot : InventorySlot, offset_x : Float32, offset_y : Float32)
          x = offset_x + slot.position.x
          y = offset_y + slot.position.y

          # Draw slot background
          if slot.selected && (selected_bg = @slot_selected)
            selected_bg.draw(x, y, slot.size.x, slot.size.y)
          elsif slot.highlighted && (highlight_bg = @slot_highlight)
            highlight_bg.draw(x, y, slot.size.x, slot.size.y)
          elsif slot_bg = @slot_background
            slot_bg.draw(x, y, slot.size.x, slot.size.y)
          else
            # Simple rectangle
            color = if slot.selected
                      @selected_color
                    elsif slot.highlighted
                      @highlight_color
                    else
                      @slot_color
                    end
            RL.draw_rectangle(x.to_i, y.to_i, slot.size.x.to_i, slot.size.y.to_i, color)
            RL.draw_rectangle_lines(x.to_i, y.to_i, slot.size.x.to_i, slot.size.y.to_i, RL::BLACK)
          end

          # Draw item if present
          if item_id = slot.item_id
            draw_item(item_id, x, y, slot.size.x, slot.size.y, slot.quantity)
          end
        end

        private def draw_item(item_id : String, x : Float32, y : Float32,
                              width : Float32, height : Float32, quantity : Int32)
          return unless sprite = @item_sprites[item_id]?

          # Calculate scale to fit in slot
          if tex = sprite.texture
            scale_x = (width * @item_scale) / tex.width
            scale_y = (height * @item_scale) / tex.height
            scale = Math.min(scale_x, scale_y)

            # Store original scale
            original_scale = sprite.scale
            sprite.scale = scale

            # Center in slot
            center_x = x + width / 2
            center_y = y + height / 2
            sprite.position = RL::Vector2.new(x: center_x, y: center_y)

            # Draw sprite
            sprite.draw

            # Restore scale
            sprite.scale = original_scale
          end

          # Draw quantity if more than 1
          if @show_quantity && quantity > 1
            quantity_x = x + width + @quantity_offset.x
            quantity_y = y + height + @quantity_offset.y

            @text_renderer.draw(
              quantity.to_s,
              quantity_x,
              quantity_y,
              TextAlign::Right,
              VerticalAlign::Bottom
            )
          end
        end
      end

      # Quick inventory bar (hotbar style)
      class QuickInventoryRenderer < InventoryRenderer
        def initialize(slots : Int32 = 8)
          super(slots, 1) # Single row
          @slot_size = 48.0f32
          @padding = 8.0f32
          @show_quantity = true
        end

        # Draw at bottom center of screen
        def draw_bottom_center(screen_width : Float32 = Display::REFERENCE_WIDTH.to_f32,
                               screen_height : Float32 = Display::REFERENCE_HEIGHT.to_f32,
                               margin : Float32 = 20.0f32)
          x = (screen_width - total_width) / 2
          y = screen_height - total_height - margin
          draw(x, y)
        end
      end
    end
  end
end
