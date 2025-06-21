#!/usr/bin/env crystal

# Debug renderer that captures actual screenshots and analyzes the rendering pipeline

require "raylib-cr"
require "./src/point_click_engine"
require "./crystal_mystery/main"

puts "🔍 Crystal Mystery Debug Renderer"
puts "================================="

# Initialize Raylib for screenshot capture
Raylib.init_window(1024, 768, "Crystal Mystery Debug")
Raylib.set_target_fps(60)

# Create the game
puts "🎮 Creating game instance..."
game = CrystalMysteryGame.new

# Create screenshot directory
Dir.mkdir_p("debug_screenshots") unless Dir.exists?("debug_screenshots")

class DebugRenderer
  @@screenshot_count = 0

  def self.take_debug_screenshot(description : String, game : CrystalMysteryGame)
    @@screenshot_count += 1

    filename = "debug_screenshots/#{@@screenshot_count.to_s.rjust(2, '0')}_#{description.gsub(/[^a-zA-Z0-9]/, "_")}.png"

    puts "📸 Screenshot #{@@screenshot_count}: #{description}"

    # Render one frame
    Raylib.begin_drawing

    # Clear with a test color first to see if we can draw anything
    Raylib.clear_background(Raylib::PURPLE)

    # Try to draw a test rectangle to verify rendering works
    Raylib.draw_rectangle(10, 10, 100, 50, Raylib::YELLOW)
    Raylib.draw_text("DEBUG", 20, 25, 20, Raylib::BLACK)

    # Now try to draw the actual game
    begin
      # Draw current scene if it exists
      if current_scene = game.engine.current_scene
        puts "   → Drawing scene: #{current_scene.name}"

        # Check if scene has background
        if current_scene.background_path
          puts "   → Background path: #{current_scene.background_path}"

          if current_scene.background
            puts "   → Background texture loaded: YES"
            # Try to draw the background
            Raylib.draw_texture(current_scene.background.not_nil!, 0, 0, Raylib::WHITE)
          else
            puts "   → Background texture loaded: NO"
            # Draw a placeholder background
            Raylib.draw_rectangle(0, 0, 1024, 768, Raylib::BLUE)
            Raylib.draw_text("NO BACKGROUND TEXTURE", 300, 350, 24, Raylib::WHITE)
          end
        else
          puts "   → No background path configured"
          Raylib.draw_rectangle(0, 0, 1024, 768, Raylib::MAROON)
          Raylib.draw_text("NO BACKGROUND PATH", 300, 350, 24, Raylib::WHITE)
        end

        # Draw hotspots in debug mode
        current_scene.hotspots.each do |hotspot|
          Raylib.draw_rectangle_lines(
            hotspot.position.x.to_i,
            hotspot.position.y.to_i,
            hotspot.size.x.to_i,
            hotspot.size.y.to_i,
            Raylib::GREEN
          )
          Raylib.draw_text(hotspot.name, hotspot.position.x.to_i, hotspot.position.y.to_i - 25, 16, Raylib::GREEN)
        end

        # Draw player if exists
        if player = game.engine.player
          player_rect = Raylib::Rectangle.new(
            x: player.position.x,
            y: player.position.y,
            width: player.size.x,
            height: player.size.y
          )
          Raylib.draw_rectangle_rec(player_rect, Raylib::BLUE)
          Raylib.draw_text("PLAYER", player.position.x.to_i, player.position.y.to_i - 20, 14, Raylib::WHITE)
        end
      else
        puts "   → No current scene"
        Raylib.draw_text("NO CURRENT SCENE", 300, 350, 24, Raylib::WHITE)
      end

      # Draw GUI
      if gui = game.engine.gui
        if gui.visible
          puts "   → Drawing GUI: #{gui.labels.size} labels, #{gui.buttons.size} buttons"

          # Draw labels
          gui.labels.each do |id, label|
            if label.visible
              Raylib.draw_text(label.text, label.position.x.to_i, label.position.y.to_i, label.font_size, label.color)
            end
          end

          # Draw buttons
          gui.buttons.each do |id, button|
            if button.visible
              # Draw button background
              Raylib.draw_rectangle_rec(button.bounds, Raylib::GRAY)
              Raylib.draw_rectangle_lines_ex(button.bounds, 2, Raylib::WHITE)

              # Draw button text
              text_width = Raylib.measure_text(button.text, 20)
              text_x = button.position.x + (button.size.x - text_width) / 2
              text_y = button.position.y + (button.size.y - 20) / 2
              Raylib.draw_text(button.text, text_x.to_i, text_y.to_i, 20, Raylib::WHITE)
            end
          end
        else
          puts "   → GUI not visible"
        end
      else
        puts "   → No GUI manager"
      end

      # Draw debug info overlay
      debug_info = [
        "Scene: #{game.engine.current_scene.try(&.name) || "none"}",
        "GUI Visible: #{game.engine.gui.try(&.visible) || false}",
        "UI Visible: #{game.engine.ui_visible}",
        "Background Path: #{game.engine.current_scene.try(&.background_path) || "none"}",
        "Background Loaded: #{game.engine.current_scene.try(&.background) ? "YES" : "NO"}",
      ]

      debug_info.each_with_index do |info, i|
        Raylib.draw_text(info, 10, 70 + (i * 20), 16, Raylib::YELLOW)
      end
    rescue ex
      puts "   ❌ Rendering error: #{ex.message}"
      Raylib.draw_text("RENDER ERROR: #{ex.message}", 50, 400, 20, Raylib::RED)
    end

    Raylib.end_drawing

    # Take screenshot
    Raylib.take_screenshot(filename)
    puts "   💾 Saved: #{filename}"

    filename
  end
end

# Test sequence
puts "\n🧪 Starting debug sequence..."

# Enable debug mode to see all objects (set to false for normal mode)
PointClickEngine::Core::Engine.debug_mode = false

# 1. Initial state
DebugRenderer.take_debug_screenshot("01_initial_state", game)

# 2. Check if we can manually load a background
puts "\n🖼️ Testing manual background loading..."
begin
  test_texture = Raylib.load_texture("assets/backgrounds/library.png")
  puts "   ✅ Successfully loaded library.png"

  # Draw just the texture
  Raylib.begin_drawing
  Raylib.clear_background(Raylib::BLACK)
  Raylib.draw_texture(test_texture, 0, 0, Raylib::WHITE)
  Raylib.draw_text("MANUAL TEXTURE LOAD TEST", 300, 50, 24, Raylib::YELLOW)
  Raylib.end_drawing

  Raylib.take_screenshot("debug_screenshots/03_manual_texture_test.png")
  puts "   💾 Manual texture test saved"

  Raylib.unload_texture(test_texture)
rescue ex
  puts "   ❌ Failed to load texture manually: #{ex.message}"
end

# 3. Test main menu
puts "\n📋 Testing main menu..."
game.engine.change_scene("main_menu")
DebugRenderer.take_debug_screenshot("04_main_menu", game)

# 4. Test new game transition
puts "\n🚀 Testing new game..."
if gui = game.engine.gui
  if new_game_button = gui.buttons["new_game"]?
    new_game_button.callback.call
    DebugRenderer.take_debug_screenshot("05_after_new_game", game)
  end
end

# 5. Check library scene specifically
puts "\n📚 Testing library scene directly..."
game.engine.change_scene("library")
DebugRenderer.take_debug_screenshot("06_library_scene_direct", game)

# 6. Test with debug mode (enable at start)
puts "\n🐛 Testing with debug mode..."
PointClickEngine::Core::Engine.debug_mode = true
DebugRenderer.take_debug_screenshot("07_debug_mode", game)

# 7. Test background loading process
puts "\n🔍 Analyzing background loading..."
if library_scene = game.engine.scenes["library"]?
  puts "   📁 Library scene exists"
  puts "   📂 Background path: #{library_scene.background_path}"
  puts "   🖼️ Background texture: #{library_scene.background ? "loaded" : "not loaded"}"

  if library_scene.background_path && !library_scene.background
    puts "   🔧 Attempting to load background manually..."
    begin
      bg_path = library_scene.background_path.not_nil!
      if File.exists?(bg_path)
        puts "   📁 Background file exists: #{bg_path}"
        library_scene.background = Raylib.load_texture(bg_path)
        puts "   ✅ Background loaded manually"
        DebugRenderer.take_debug_screenshot("08_manual_bg_load", game)
      else
        puts "   ❌ Background file doesn't exist: #{bg_path}"
      end
    rescue ex
      puts "   ❌ Manual background load failed: #{ex.message}"
    end
  end
end

# 8. Final test with all fixes
DebugRenderer.take_debug_screenshot("09_final_state", game)

puts "\n✅ Debug sequence complete!"
puts "📁 Screenshots saved in debug_screenshots/"
puts "🔍 Check the images to see what's actually being rendered"

# Show file list
puts "\n📋 Generated files:"
Dir.children("debug_screenshots").sort.each do |file|
  puts "   - #{file}"
end

# Cleanup
Raylib.close_window

puts "\n💡 Analysis complete! Check debug_screenshots/ to see what's actually being rendered."
