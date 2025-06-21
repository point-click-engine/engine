#!/usr/bin/env crystal

# Simple script to create basic colored background images for testing
# This creates actual PNG files that Raylib can load

require "raylib-cr"

puts "🎨 Creating test background images for Crystal Mystery..."

# Initialize Raylib in headless mode for image creation
Raylib.init_window(1024, 768, "Background Creator")
Raylib.set_target_fps(60)

backgrounds = [
  {name: "library", color: Raylib::DARKBLUE, title: "Ancient Library"},
  {name: "laboratory", color: Raylib::DARKGREEN, title: "Mad Scientist's Lab"},
  {name: "garden", color: Raylib::DARKBROWN, title: "Mysterious Garden"},
]

backgrounds.each do |bg|
  puts "  📝 Creating #{bg[:name]}.png..."

  # Create a render texture
  render_texture = Raylib.load_render_texture(1024, 768)

  # Draw to the render texture
  Raylib.begin_texture_mode(render_texture)
  Raylib.clear_background(bg[:color])

  # Add some simple decoration
  Raylib.draw_rectangle(50, 50, 924, 668, Raylib.fade(Raylib::WHITE, 0.1f32))
  Raylib.draw_rectangle_lines(50, 50, 924, 668, Raylib::WHITE)

  # Add title text
  title_text = bg[:title]
  text_width = Raylib.measure_text(title_text, 48)
  text_x = (1024 - text_width) // 2
  Raylib.draw_text(title_text, text_x, 300, 48, Raylib::WHITE)

  # Add some fake UI elements to make it look like a game scene
  case bg[:name]
  when "library"
    # Draw bookshelves
    Raylib.draw_rectangle(100, 200, 150, 300, Raylib::BROWN)
    Raylib.draw_text("Bookshelf", 105, 520, 20, Raylib::WHITE)

    Raylib.draw_rectangle(400, 400, 200, 150, Raylib::DARKBROWN)
    Raylib.draw_text("Desk", 450, 560, 20, Raylib::WHITE)
  when "laboratory"
    # Draw lab equipment
    Raylib.draw_rectangle(200, 350, 300, 200, Raylib::GRAY)
    Raylib.draw_text("Workbench", 270, 570, 20, Raylib::WHITE)

    Raylib.draw_rectangle(600, 200, 150, 400, Raylib::LIGHTGRAY)
    Raylib.draw_text("Cabinet", 620, 620, 20, Raylib::WHITE)
  when "garden"
    # Draw garden elements
    Raylib.draw_circle(200, 400, 80, Raylib::GREEN)
    Raylib.draw_text("Fountain", 160, 500, 20, Raylib::WHITE)

    Raylib.draw_rectangle(600, 300, 100, 200, Raylib::BROWN)
    Raylib.draw_text("Gate", 620, 520, 20, Raylib::WHITE)
  end

  # Add instructions
  Raylib.draw_text("Click on objects to interact", 50, 700, 20, Raylib.fade(Raylib::WHITE, 0.7f32))

  Raylib.end_texture_mode

  # Take a screenshot and save it
  image = Raylib.load_image_from_texture(render_texture.texture)
  Raylib.image_flip_vertical(pointerof(image))

  output_path = "assets/backgrounds/#{bg[:name]}.png"
  success = Raylib.export_image(image, output_path.to_unsafe)

  if success
    puts "    ✅ Created: #{output_path}"
  else
    puts "    ❌ Failed to create: #{output_path}"
  end

  # Cleanup
  Raylib.unload_image(image)
  Raylib.unload_render_texture(render_texture)
end

Raylib.close_window

puts "\n🎮 Test backgrounds created!"
puts "   Now try running: ./crystal_mystery_game"
puts "   The game should display colored backgrounds instead of black!"
