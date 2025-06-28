# UI Rendering Demo - Shows all UI components

require "raylib-cr"
require "../src/graphics/graphics"

class UIRenderingDemo
  @display : PointClickEngine::Graphics::Display
  @renderer : PointClickEngine::Graphics::Renderer
  @layers : PointClickEngine::Graphics::LayerManager

  # UI Components
  @nine_patch_button : PointClickEngine::Graphics::UI::NinePatch
  @nine_patch_panel : PointClickEngine::Graphics::UI::NinePatch
  @text_renderer : PointClickEngine::Graphics::UI::TextRenderer
  @dialog_renderer : PointClickEngine::Graphics::UI::DialogRenderer
  @inventory_renderer : PointClickEngine::Graphics::UI::InventoryRenderer
  @quick_inventory : PointClickEngine::Graphics::UI::QuickInventoryRenderer

  # Demo state
  @current_tab : Int32 = 0
  @dialog_text : String = "Hello! This is a sample dialog with typewriter effect. It can wrap text automatically and display speech bubbles!"
  @text_animation_time : Float32 = 0.0f32
  @selected_slot : Int32? = nil
  @hover_slot : Int32? = nil

  def initialize
    RL.init_window(1280, 720, "UI Rendering Demo")
    RL.set_target_fps(60)

    @display = PointClickEngine::Graphics::Display.new(1280, 720)
    @renderer = PointClickEngine::Graphics::Renderer.new(@display)
    @layers = PointClickEngine::Graphics::LayerManager.new
    @layers.add_default_layers

    setup_ui_components
  end

  def run
    until RL.close_window?
      update
      draw
    end

    cleanup
  end

  private def setup_ui_components
    # Create nine-patch components (using colored rectangles for demo)
    @nine_patch_button = create_demo_nine_patch(RL::BLUE, 8)
    @nine_patch_panel = create_demo_nine_patch(RL::DARKGRAY, 16)

    # Text renderer
    @text_renderer = PointClickEngine::Graphics::UI::TextRenderer.new
    @text_renderer.font_size = 20
    @text_renderer.color = RL::WHITE
    @text_renderer.outline_color = RL::BLACK
    @text_renderer.outline_thickness = 1
    @text_renderer.enable_shadow = true

    # Dialog renderer
    dialog_nine_patch = create_demo_nine_patch(RL::Color.new(r: 240, g: 240, b: 220, a: 255), 12)
    @dialog_renderer = PointClickEngine::Graphics::UI::DialogRenderer.new(dialog_nine_patch)
    @dialog_renderer.text_color = RL::BLACK
    @dialog_renderer.show(@dialog_text)

    # Inventory renderer
    @inventory_renderer = PointClickEngine::Graphics::UI::InventoryRenderer.new(6, 4)
    @inventory_renderer.slot_background = create_demo_nine_patch(RL::Color.new(r: 80, g: 80, b: 80, a: 255), 4)
    @inventory_renderer.slot_highlight = create_demo_nine_patch(RL::Color.new(r: 120, g: 120, b: 120, a: 255), 4)
    @inventory_renderer.slot_selected = create_demo_nine_patch(RL::GOLD, 4)

    # Add some demo items
    setup_demo_inventory

    # Quick inventory
    @quick_inventory = PointClickEngine::Graphics::UI::QuickInventoryRenderer.new(8)
    @quick_inventory.slot_background = create_demo_nine_patch(RL::Color.new(r: 60, g: 60, b: 60, a: 255), 4)

    # Add items to quick inventory
    5.times do |i|
      @quick_inventory.set_item(i, "item_#{i}", i + 1)
    end
  end

  private def create_demo_nine_patch(color : RL::Color, border : Int32) : PointClickEngine::Graphics::UI::NinePatch
    # Create a simple texture for nine-patch demo
    size = border * 4
    image = RL.gen_image_color(size, size, color)

    # Add darker borders
    border_color = RL::Color.new(
      r: (color.r * 0.6).to_u8,
      g: (color.g * 0.6).to_u8,
      b: (color.b * 0.6).to_u8,
      a: color.a
    )

    # Draw borders
    RL.image_draw_rectangle(image, 0, 0, size, border, border_color)
    RL.image_draw_rectangle(image, 0, size - border, size, border, border_color)
    RL.image_draw_rectangle(image, 0, 0, border, size, border_color)
    RL.image_draw_rectangle(image, size - border, 0, border, size, border_color)

    texture = RL.load_texture_from_image(image)
    RL.unload_image(image)

    nine_patch = PointClickEngine::Graphics::UI::NinePatch.new(texture, border, border, border, border)
    nine_patch
  end

  private def setup_demo_inventory
    # Create colored rectangles as item sprites
    colors = [RL::RED, RL::GREEN, RL::BLUE, RL::YELLOW, RL::PURPLE, RL::ORANGE]

    6.times do |i|
      sprite = create_item_sprite(colors[i % colors.size], 48)
      @inventory_renderer.add_item_sprite("item_#{i}", sprite)
      @quick_inventory.add_item_sprite("item_#{i}", sprite)
    end

    # Add items to inventory
    @inventory_renderer.set_item(0, "item_0", 5)
    @inventory_renderer.set_item(1, "item_1", 1)
    @inventory_renderer.set_item(5, "item_2", 99)
    @inventory_renderer.set_item(10, "item_3", 7)
    @inventory_renderer.set_item(15, "item_4", 1)
    @inventory_renderer.set_item(20, "item_5", 42)
  end

  private def create_item_sprite(color : RL::Color, size : Int32) : PointClickEngine::Graphics::Sprite
    image = RL.gen_image_color(size, size, color)
    texture = RL.load_texture_from_image(image)
    RL.unload_image(image)

    sprite = PointClickEngine::Graphics::Sprite.new
    sprite.texture = texture
    sprite.center_origin
    sprite
  end

  private def update
    dt = RL.get_frame_time
    @text_animation_time += dt

    # Update dialog animation
    @dialog_renderer.update(dt)

    # Handle input
    handle_input

    # Update inventory hover
    mouse_pos = @display.screen_to_game(RL.get_mouse_x, RL.get_mouse_y)
    if @current_tab == 3 # Inventory tab
      inv_x = (1280 - @inventory_renderer.total_width) / 2
      inv_y = 200
      @hover_slot = @inventory_renderer.slot_at(mouse_pos.x - inv_x, mouse_pos.y - inv_y)
      @inventory_renderer.highlight_slot(@hover_slot)
    end
  end

  private def handle_input
    # Tab selection
    if RL.key_pressed?(RL::KeyboardKey::One)
      @current_tab = 0
    elsif RL.key_pressed?(RL::KeyboardKey::Two)
      @current_tab = 1
    elsif RL.key_pressed?(RL::KeyboardKey::Three)
      @current_tab = 2
    elsif RL.key_pressed?(RL::KeyboardKey::Four)
      @current_tab = 3
    end

    # Dialog controls
    if @current_tab == 2
      if RL.key_pressed?(RL::KeyboardKey::Space)
        if @dialog_renderer.animating?
          @dialog_renderer.skip_typewriter
        else
          texts = [
            "This is another message! Press space to continue...",
            "UI components support nine-patch scaling for perfect borders.",
            "Text can have outlines, shadows, and various effects!",
            "Inventory grids can display items with quantities.",
            @dialog_text,
          ]
          @dialog_renderer.show(texts.sample)
        end
      end
    end

    # Inventory click
    if @current_tab == 3 && RL.mouse_button_pressed?(RL::MouseButton::Left)
      if slot = @hover_slot
        @selected_slot = slot
        @inventory_renderer.select_slot(slot)
      end
    end
  end

  private def draw
    RL.begin_drawing
    RL.clear_background(RL::Color.new(r: 30, g: 30, b: 40, a: 255))

    @display.clear_screen

    # Draw tabs
    draw_tabs

    # Draw current tab content
    case @current_tab
    when 0
      draw_nine_patch_demo
    when 1
      draw_text_effects_demo
    when 2
      draw_dialog_demo
    when 3
      draw_inventory_demo
    end

    # Draw info
    draw_info

    RL.end_drawing
  end

  private def draw_tabs
    tab_names = ["Nine-Patch", "Text Effects", "Dialogs", "Inventory"]
    tab_width = 150
    tab_height = 40
    y = 50

    tab_names.each_with_index do |name, i|
      x = 100 + i * (tab_width + 10)

      # Draw tab background
      if i == @current_tab
        @nine_patch_button.tint = RL::SKYBLUE
        @nine_patch_button.draw(x, y, tab_width, tab_height)
      else
        @nine_patch_button.tint = RL::DARKBLUE
        @nine_patch_button.draw(x, y, tab_width, tab_height)
      end

      # Draw tab text
      @text_renderer.color = RL::WHITE
      @text_renderer.draw(name, x + tab_width/2, y + tab_height/2,
        PointClickEngine::Graphics::UI::TextAlign::Center,
        PointClickEngine::Graphics::UI::VerticalAlign::Middle)
    end
  end

  private def draw_nine_patch_demo
    y = 150

    @text_renderer.draw("Nine-Patch Scaling Demo", 640, y,
      PointClickEngine::Graphics::UI::TextAlign::Center)

    y += 50

    # Draw various sizes of nine-patch
    sizes = [
      {100, 50},
      {200, 60},
      {300, 80},
      {400, 100},
      {500, 120},
    ]

    sizes.each do |width, height|
      x = (1280 - width) / 2
      @nine_patch_panel.draw(x, y, width, height)

      @text_renderer.draw("#{width}x#{height}", x + width/2, y + height/2,
        PointClickEngine::Graphics::UI::TextAlign::Center,
        PointClickEngine::Graphics::UI::VerticalAlign::Middle)

      y += height + 20
    end
  end

  private def draw_text_effects_demo
    y = 150

    # Normal text
    @text_renderer.color = RL::WHITE
    @text_renderer.enable_shadow = false
    @text_renderer.outline_thickness = 0
    @text_renderer.draw("Normal Text", 640, y,
      PointClickEngine::Graphics::UI::TextAlign::Center)

    y += 40

    # Shadow text
    @text_renderer.enable_shadow = true
    @text_renderer.draw("Text with Shadow", 640, y,
      PointClickEngine::Graphics::UI::TextAlign::Center)

    y += 40

    # Outline text
    @text_renderer.enable_shadow = false
    @text_renderer.outline_thickness = 2
    @text_renderer.draw("Text with Outline", 640, y,
      PointClickEngine::Graphics::UI::TextAlign::Center)

    y += 40

    # Both shadow and outline
    @text_renderer.enable_shadow = true
    @text_renderer.draw("Shadow + Outline", 640, y,
      PointClickEngine::Graphics::UI::TextAlign::Center)

    y += 60

    # Wave effect
    @text_renderer.enable_shadow = false
    @text_renderer.outline_thickness = 1
    @text_renderer.draw_wave("Wavy Text Effect!", 640, y, 10, 0.1, @text_animation_time)

    y += 60

    # Gradient text
    @text_renderer.draw_gradient("Gradient Text", 640, y,
      RL::RED, RL::YELLOW, true)

    y += 60

    # Word wrap demo
    wrap_text = "This is a long text that demonstrates word wrapping. The text renderer can automatically break lines to fit within a specified width, making it perfect for dialog boxes and descriptions!"

    @nine_patch_panel.draw(340, y, 600, 150)
    @text_renderer.enable_shadow = false
    @text_renderer.outline_thickness = 0
    @text_renderer.color = RL::WHITE
    @text_renderer.draw_wrapped(wrap_text, 360, y + 20, 560)
  end

  private def draw_dialog_demo
    # Draw character sprite placeholder
    char_pos = RL::Vector2.new(x: 640, y: 400)
    RL.draw_circle(char_pos.x.to_i, char_pos.y.to_i, 40, RL::GREEN)
    RL.draw_text("Character", (char_pos.x - 35).to_i, (char_pos.y - 5).to_i, 12, RL::WHITE)

    # Draw dialog above character
    @dialog_renderer.draw_at_target(char_pos,
      PointClickEngine::Graphics::UI::DialogAnchor::AboveTarget)

    # Instructions
    @text_renderer.color = RL::YELLOW
    @text_renderer.draw("Press SPACE to change dialog", 640, 600,
      PointClickEngine::Graphics::UI::TextAlign::Center)
  end

  private def draw_inventory_demo
    # Draw main inventory
    @inventory_renderer.draw_centered

    # Draw quick inventory at bottom
    @quick_inventory.draw_bottom_center

    # Draw selected item info
    if slot = @selected_slot
      if item = @inventory_renderer.slots[slot]?.try(&.item_id)
        info = "Selected: #{item}"
        @text_renderer.color = RL::YELLOW
        @text_renderer.draw(info, 640, 150,
          PointClickEngine::Graphics::UI::TextAlign::Center)
      end
    end

    # Instructions
    @text_renderer.color = RL::GRAY
    @text_renderer.draw("Click to select items", 640, 600,
      PointClickEngine::Graphics::UI::TextAlign::Center)
  end

  private def draw_info
    @text_renderer.color = RL::WHITE
    @text_renderer.outline_thickness = 0
    @text_renderer.enable_shadow = false

    y = 10
    @text_renderer.draw("UI Rendering Demo", 10, y)
    y += 25
    @text_renderer.draw("Press 1-4 to switch tabs", 10, y)

    RL.draw_fps(1200, 10)
  end

  private def cleanup
    @renderer.cleanup
    @nine_patch_button.cleanup
    @nine_patch_panel.cleanup
    @inventory_renderer.slots.each do |slot|
      if item_id = slot.item_id
        @inventory_renderer.@item_sprites[item_id]?.try(&.cleanup)
      end
    end
    RL.close_window
  end
end

# Extension to allow direct texture assignment (for demo)
class PointClickEngine::Graphics::Sprites::Sprite
  property texture : RL::Texture2D?
end

# Run the demo
demo = UIRenderingDemo.new
demo.run
