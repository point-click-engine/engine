# Graphics Utilities Demo

require "raylib-cr"
require "../src/graphics/graphics"

class UtilitiesDemo
  @display : PointClickEngine::Graphics::Display
  @renderer : PointClickEngine::Graphics::Renderer

  # Utility demos
  @current_demo : Int32 = 0
  @demo_names = ["Color Utils", "Bitmap Fonts", "Palettes", "Screenshots"]

  # Color demo
  @color_time : Float32 = 0.0f32
  @gradient_colors : Array(RL::Color)
  @rainbow_colors : Array(RL::Color)

  # Bitmap font demo
  @bitmap_font : PointClickEngine::Graphics::Utils::BitmapFont?
  @font_scale : Float32 = 1.0f32

  # Palette demo
  @palettes : Array(PointClickEngine::Graphics::Utils::Palette)
  @current_palette : Int32 = 0
  @palette_cycler : PointClickEngine::Graphics::Utils::PaletteCycler?
  @demo_image : RL::Image?
  @original_texture : RL::Texture2D?
  @remapped_texture : RL::Texture2D?

  # Screenshot demo
  @screenshot_manager : PointClickEngine::Graphics::Utils::ScreenshotManager
  @last_screenshot : String?

  def initialize
    RL.init_window(1280, 720, "Graphics Utilities Demo")
    RL.set_target_fps(60)

    @display = PointClickEngine::Graphics::Display.new(1280, 720)
    @renderer = PointClickEngine::Graphics::Renderer.new(@display)

    setup_demos

    @screenshot_manager = PointClickEngine::Graphics::Utils::ScreenshotManager.new
    @screenshot_manager.on_screenshot = ->(filename : String) do
      @last_screenshot = filename
      puts "Screenshot saved: #{filename}"
    end
  end

  def run
    until RL.close_window?
      update
      draw
    end

    cleanup
  end

  private def setup_demos
    # Color demo setup
    start_color = RL::RED
    end_color = RL::BLUE
    @gradient_colors = PointClickEngine::Graphics::Utils::Color.gradient(start_color, end_color, 10)
    @rainbow_colors = PointClickEngine::Graphics::Utils::Color.rainbow(12)

    # Bitmap font demo setup
    setup_bitmap_font

    # Palette demo setup
    setup_palettes

    # Create demo image for palette remapping
    create_demo_image
  end

  private def setup_bitmap_font
    # Create a simple grid font texture for demo
    font_image = RL.gen_image_color(256, 128, RL::WHITE)

    # Draw simple ASCII characters
    16.times do |row|
      16.times do |col|
        char_code = row * 16 + col
        next if char_code < 32 # Skip control characters

        x = col * 16
        y = row * 16

        # Draw character background
        RL.image_draw_rectangle(font_image, x + 1, y + 1, 14, 14, RL::BLACK)

        # Draw simple representation (just a box with number for demo)
        if char_code >= 65 && char_code <= 90 # A-Z
          RL.image_draw_rectangle(font_image, x + 4, y + 4, 8, 8, RL::WHITE)
        elsif char_code >= 97 && char_code <= 122 # a-z
          RL.image_draw_rectangle(font_image, x + 5, y + 5, 6, 6, RL::WHITE)
        elsif char_code >= 48 && char_code <= 57 # 0-9
          RL.image_draw_circle(font_image, x + 8, y + 8, 4, RL::WHITE)
        else
          RL.image_draw_pixel(font_image, x + 8, y + 8, RL::WHITE)
        end
      end
    end

    texture = RL.load_texture_from_image(font_image)
    RL.unload_image(font_image)

    @bitmap_font = PointClickEngine::Graphics::Utils::BitmapFont.load_grid(
      "demo_font", # This would normally be a file path
      16, 16,      # Character size
      ' ',         # First character
      16           # Characters per row
    )

    # Manually set the texture since we created it
    if font = @bitmap_font
      font.texture = texture
    end
  end

  private def setup_palettes
    @palettes = [
      PointClickEngine::Graphics::Utils::Palettes.cga,
      PointClickEngine::Graphics::Utils::Palettes.gameboy,
      PointClickEngine::Graphics::Utils::Palettes.sepia,
      PointClickEngine::Graphics::Utils::Palettes.night_vision,
    ]

    # Setup palette cycling for CGA
    cycle_indices = (0...8).to_a # Cycle first 8 colors
    @palette_cycler = PointClickEngine::Graphics::Utils::PaletteCycler.new(
      @palettes[0].clone,
      cycle_indices,
      2.0f32
    )
  end

  private def create_demo_image
    # Create a colorful test image
    size = 128
    @demo_image = RL.gen_image_color(size, size, RL::WHITE)

    # Draw colorful pattern
    size.times do |y|
      size.times do |x|
        hue = ((x + y).to_f32 / size) * 360.0f32
        color = PointClickEngine::Graphics::Utils::Color.hsv_to_rgb(hue, 1.0f32, 1.0f32)
        RL.image_draw_pixel(@demo_image.not_nil!, x, y, color)
      end
    end

    @original_texture = RL.load_texture_from_image(@demo_image.not_nil!)
    update_remapped_texture
  end

  private def update_remapped_texture
    return unless image = @demo_image
    return unless palette = @palettes[@current_palette]?

    # Remap image to current palette
    remapped = palette.remap_image(image)

    # Update texture
    if texture = @remapped_texture
      RL.unload_texture(texture)
    end

    @remapped_texture = RL.load_texture_from_image(remapped)
    RL.unload_image(remapped)
  end

  private def update
    dt = RL.get_frame_time
    @color_time += dt

    # Update screenshot manager
    @screenshot_manager.update(dt)

    # Update palette cycler
    @palette_cycler.try(&.update(dt))

    # Handle input
    if RL.key_pressed?(RL::KeyboardKey::Left)
      @current_demo = (@current_demo - 1) % @demo_names.size
    elsif RL.key_pressed?(RL::KeyboardKey::Right)
      @current_demo = (@current_demo + 1) % @demo_names.size
    end

    # Demo-specific input
    case @current_demo
    when 2 # Palette demo
      if RL.key_pressed?(RL::KeyboardKey::Space)
        @current_palette = (@current_palette + 1) % @palettes.size
        update_remapped_texture
      end
    end
  end

  private def draw
    RL.begin_drawing
    RL.clear_background(RL::Color.new(r: 20, g: 20, b: 30, a: 255))

    # Draw header
    draw_header

    # Draw current demo
    case @current_demo
    when 0
      draw_color_demo
    when 1
      draw_bitmap_font_demo
    when 2
      draw_palette_demo
    when 3
      draw_screenshot_demo
    end

    # Draw instructions
    draw_instructions

    RL.end_drawing
  end

  private def draw_header
    RL.draw_text("Graphics Utilities Demo", 10, 10, 24, RL::WHITE)
    RL.draw_text("Current: #{@demo_names[@current_demo]}", 10, 40, 20, RL::YELLOW)
    RL.draw_text("Use LEFT/RIGHT arrows to switch demos", 10, 65, 16, RL::GRAY)
    RL.draw_fps(1200, 10)
  end

  private def draw_color_demo
    y = 120

    # Color interpolation
    RL.draw_text("Color Interpolation (Lerp)", 50, y, 20, RL::WHITE)
    y += 30

    x = 50
    @gradient_colors.each_with_index do |color, i|
      RL.draw_rectangle(x + i * 40, y, 35, 35, color)
    end

    y += 50

    # HSV colors (rainbow)
    RL.draw_text("HSV Rainbow", 50, y, 20, RL::WHITE)
    y += 30

    @rainbow_colors.each_with_index do |color, i|
      RL.draw_rectangle(x + i * 40, y, 35, 35, color)
    end

    y += 50

    # Color effects
    RL.draw_text("Color Effects", 50, y, 20, RL::WHITE)
    y += 30

    base_color = RL::ORANGE
    effects = [
      {"Original", base_color},
      {"Brighten", PointClickEngine::Graphics::Utils::Color.brighten(base_color, 0.3f32)},
      {"Darken", PointClickEngine::Graphics::Utils::Color.darken(base_color, 0.3f32)},
      {"Saturate", PointClickEngine::Graphics::Utils::Color.saturate(base_color, 0.5f32)},
      {"Desaturate", PointClickEngine::Graphics::Utils::Color.desaturate(base_color, 0.5f32)},
      {"Grayscale", PointClickEngine::Graphics::Utils::Color.grayscale(base_color)},
      {"Invert", PointClickEngine::Graphics::Utils::Color.invert(base_color)},
      {"Sepia", PointClickEngine::Graphics::Utils::Color.sepia(base_color)},
    ]

    effects.each_with_index do |(name, color), i|
      x_pos = 50 + (i % 4) * 200
      y_pos = y + (i // 4) * 80

      RL.draw_rectangle(x_pos, y_pos, 60, 60, color)
      RL.draw_text(name, x_pos, y_pos + 65, 14, RL::WHITE)
    end

    y += 160

    # Animated color
    t = (Math.sin(@color_time) + 1.0f32) / 2.0f32
    animated_color = PointClickEngine::Graphics::Utils::Color.lerp(RL::RED, RL::BLUE, t)
    RL.draw_rectangle(50, y, 200, 50, animated_color)
    RL.draw_text("Animated Color Lerp", 50, y + 55, 16, RL::WHITE)
  end

  private def draw_bitmap_font_demo
    return unless font = @bitmap_font

    y = 120

    RL.draw_text("Bitmap Font Rendering", 50, y, 20, RL::WHITE)
    y += 40

    # Normal text
    font.draw("Hello, Bitmap World!", 50, y, RL::WHITE)
    y += 30

    # Scaled text
    font.draw_scaled("Scaled Text", 50, y, 2.0f32, RL::YELLOW)
    y += 60

    # Different colors
    font.draw("Colorful", 50, y, RL::RED)
    font.draw("Bitmap", 150, y, RL::GREEN)
    font.draw("Text", 250, y, RL::BLUE)
    y += 40

    # Character set display
    RL.draw_text("Character Set:", 50, y, 16, RL::GRAY)
    y += 25

    chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    font.draw(chars, 50, y, RL::WHITE)
    y += 20

    chars = "abcdefghijklmnopqrstuvwxyz"
    font.draw(chars, 50, y, RL::WHITE)
    y += 20

    chars = "0123456789"
    font.draw(chars, 50, y, RL::WHITE)
    y += 20

    chars = "!@#$%^&*()_+-=[]{}|;:,.<>?"
    font.draw(chars, 50, y, RL::WHITE)

    # Measure text
    y += 40
    test_text = "Measure this text"
    size = font.measure(test_text)
    font.draw(test_text, 50, y, RL::YELLOW)
    RL.draw_rectangle_lines(50, y.to_i, size.x.to_i, size.y.to_i, RL::YELLOW)
    RL.draw_text("Size: #{size.x.to_i}x#{size.y.to_i}", 50, y + 25, 14, RL::GRAY)
  end

  private def draw_palette_demo
    y = 120

    RL.draw_text("Color Palettes", 50, y, 20, RL::WHITE)
    y += 30

    # Current palette name
    palette = @palettes[@current_palette]
    RL.draw_text("Current: #{palette.name} (#{palette.size} colors)", 50, y, 18, RL::YELLOW)
    RL.draw_text("Press SPACE to cycle palettes", 50, y + 25, 14, RL::GRAY)
    y += 50

    # Draw palette colors
    x = 50
    col = 0
    palette.each do |entry|
      RL.draw_rectangle(x + (col % 8) * 40, y + (col // 8) * 40, 35, 35, entry.color)
      col += 1
    end

    y += ((palette.size + 7) // 8) * 40 + 20

    # Draw original and remapped images
    if original = @original_texture
      RL.draw_text("Original", 200, y, 16, RL::WHITE)
      RL.draw_texture_ex(original, RL::Vector2.new(x: 200, y: y + 25), 0, 2.0f32, RL::WHITE)
    end

    if remapped = @remapped_texture
      RL.draw_text("Remapped to #{palette.name}", 400, y, 16, RL::WHITE)
      RL.draw_texture_ex(remapped, RL::Vector2.new(x: 400, y: y + 25), 0, 2.0f32, RL::WHITE)
    end

    # Palette cycling demo
    if @current_palette == 0 && (cycler = @palette_cycler)
      y += 300
      RL.draw_text("Palette Cycling (CGA)", 50, y, 16, RL::WHITE)
      y += 25

      # Draw cycling colors
      cycling_palette = cycler.current_palette
      8.times do |i|
        if color = cycling_palette[i]
          RL.draw_rectangle(50 + i * 40, y, 35, 35, color)
        end
      end
    end
  end

  private def draw_screenshot_demo
    y = 120

    RL.draw_text("Screenshot Capture", 50, y, 20, RL::WHITE)
    y += 40

    # Instructions
    instructions = [
      "Press F12 to take a screenshot",
      "Press Shift+F12 to start/stop recording sequence",
      "Screenshots are saved to: #{@screenshot_manager.directory}/",
    ]

    instructions.each do |instruction|
      RL.draw_text(instruction, 50, y, 18, RL::WHITE)
      y += 25
    end

    y += 20

    # Status
    if @screenshot_manager.recording?
      RL.draw_text("RECORDING", 50, y, 24, RL::RED)
      y += 35
    end

    # Last screenshot
    if screenshot = @last_screenshot
      RL.draw_text("Last screenshot: #{File.basename(screenshot)}", 50, y, 16, RL::GREEN)
      y += 25
    end

    # Draw some content to screenshot
    y += 20
    RL.draw_text("Sample content for screenshots:", 50, y, 16, RL::GRAY)
    y += 30

    # Animated content
    time = Time.local
    RL.draw_text(time.to_s("%H:%M:%S"), 50, y, 48, RL::SKYBLUE)
    y += 60

    # Moving circle
    circle_x = 640 + Math.sin(@color_time * 2) * 200
    circle_y = y + 50
    RL.draw_circle(circle_x.to_i, circle_y.to_i, 30, RL::ORANGE)
  end

  private def draw_instructions
    y = 680

    case @current_demo
    when 2 # Palette
      RL.draw_text("SPACE: Change palette", 10, y, 14, RL::GRAY)
    when 3 # Screenshot
      RL.draw_text("F12: Screenshot | Shift+F12: Record sequence", 10, y, 14, RL::GRAY)
    end
  end

  private def cleanup
    @renderer.cleanup

    # Cleanup textures
    [@original_texture, @remapped_texture].each do |texture|
      RL.unload_texture(texture) if texture
    end

    # Cleanup demo image
    RL.unload_image(@demo_image) if @demo_image

    RL.close_window
  end
end

# Run the demo
demo = UtilitiesDemo.new
demo.run
