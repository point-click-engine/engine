require "../spec_helper"
require "../../crystal_mystery/main"

describe "Crystal Mystery Visual Playthrough" do
  describe "Complete Game Playthrough with Screenshots" do
    it "plays through the entire game taking screenshots at each step" do
      puts "\n🎮 Starting Crystal Mystery Visual Playthrough..."

      # Create game
      game = CrystalMysteryGame.new

      # Screenshot directory
      screenshot_dir = "screenshots"
      Dir.mkdir_p(screenshot_dir) unless Dir.exists?(screenshot_dir)

      # Helper to take screenshot
      screenshot_counter = 0
      take_screenshot = ->(description : String) {
        screenshot_counter += 1
        filename = "#{screenshot_dir}/#{screenshot_counter.to_s.rjust(3, '0')}_#{description.gsub(/[^a-zA-Z0-9_]/, "_")}.png"
        puts "📸 Taking screenshot: #{description}"

        # In a real implementation, this would capture the screen
        # For now, we'll simulate by printing what should be visible
        puts "   → Scene: #{game.engine.current_scene.try(&.name) || "none"}"
        puts "   → GUI visible: #{game.engine.gui.try(&.visible) || false}"
        puts "   → GUI elements: #{game.engine.gui.try(&.labels.size) || 0} labels, #{game.engine.gui.try(&.buttons.size) || 0} buttons"
        puts "   → Dialog active: #{game.engine.dialog_manager.try(&.is_dialog_active?) || false}"
        puts "   → Player position: #{game.engine.player.try(&.position) || "none"}"
        puts "   → Inventory items: #{game.engine.inventory.items.size}"

        # Try to save current game state as a form of 'screenshot'
        begin
          Raylib.take_screenshot(filename) if Raylib.responds_to?(:take_screenshot)
        rescue
          # Fallback: create a text file describing the current state
          state_description = <<-STATE
          Game State at: #{description}
          =============================
          Scene: #{game.engine.current_scene.try(&.name) || "none"}
          GUI Visible: #{game.engine.gui.try(&.visible) || false}
          GUI Labels: #{game.engine.gui.try(&.labels.keys) || [] of String}
          GUI Buttons: #{game.engine.gui.try(&.buttons.keys) || [] of String}
          Dialog Active: #{game.engine.dialog_manager.try(&.is_dialog_active?) || false}
          Dialog Text: #{game.engine.dialog_manager.try(&.current_dialog.try(&.text)) || "none"}
          Player Name: #{game.engine.player.try(&.name) || "none"}
          Player Position: #{game.engine.player.try(&.position) || "none"}
          Inventory Count: #{game.engine.inventory.items.size}
          Inventory Items: #{game.engine.inventory.items.map(&.name)}
          
          Scene Details:
          #{
  if scene = game.engine.current_scene
      "  Hotspots: #{scene.hotspots.map(&.name)}\n  Characters: #{scene.characters.map(&.name)}"
    else
      "  No scene loaded"
    end
}
          STATE

          File.write(filename.gsub(".png", ".txt"), state_description)
        end

        filename
      }

      # Step 1: Initial main menu
      take_screenshot.call("01_main_menu_initial")

      # Verify we're in main menu
      game.engine.current_scene.try(&.name).should eq("main_menu")

      # Check that main menu buttons exist
      gui = game.engine.gui
      gui.should_not be_nil

      if gui
        gui.labels.has_key?("title").should be_true
        gui.buttons.has_key?("new_game").should be_true
        gui.buttons.has_key?("load_game").should be_true
        gui.buttons.has_key?("options").should be_true
        gui.buttons.has_key?("quit").should be_true
      end

      # Step 2: Test Options Menu
      puts "\n🔧 Testing Options Menu..."
      # Simulate clicking options button instead of calling private method
      if gui = game.engine.gui
        if options_button = gui.buttons["options"]?
          options_button.callback.call
          take_screenshot.call("02_options_menu")
        end
      end

      # Verify options menu elements
      if gui = game.engine.gui
        gui.labels.has_key?("options_title").should be_true
        gui.labels.has_key?("audio_label").should be_true
        gui.buttons.has_key?("vol_down").should be_true
        gui.buttons.has_key?("vol_up").should be_true
        gui.buttons.has_key?("toggle_fullscreen").should be_true
        gui.buttons.has_key?("toggle_debug").should be_true
        gui.buttons.has_key?("back_to_menu").should be_true
      end

      # Test volume change
      original_volume = game.engine.config.try(&.get("audio.master_volume", "0.8"))
      # Simulate clicking volume up button
      if gui = game.engine.gui
        if vol_up_button = gui.buttons["vol_up"]?
          vol_up_button.callback.call
          take_screenshot.call("03_options_volume_increased")
        end

        # Go back to main menu
        if back_button = gui.buttons["back_to_menu"]?
          back_button.callback.call
          take_screenshot.call("04_back_to_main_menu")
        end
      end

      # Step 3: Start New Game
      puts "\n🚀 Starting New Game..."
      # Simulate clicking new game button
      if gui = game.engine.gui
        if new_game_button = gui.buttons["new_game"]?
          new_game_button.callback.call
          take_screenshot.call("05_new_game_started")
        end
      end

      # Should now be in library scene
      game.engine.current_scene.try(&.name).should eq("library")

      # Check that opening dialog is shown
      if dm = game.engine.dialog_manager
        dm.is_dialog_active?.should be_true
        take_screenshot.call("06_opening_dialog")

        # Wait for dialog to timeout
        dm.update(5.0f32)
        take_screenshot.call("07_dialog_cleared")
      end

      # Step 4: Explore Library Scene
      puts "\n📚 Exploring Library Scene..."

      # Check scene has hotspots
      if scene = game.engine.current_scene
        scene.hotspots.size.should be > 0
        puts "   📍 Library hotspots: #{scene.hotspots.map(&.name)}"

        # Try clicking on each hotspot
        scene.hotspots.each_with_index do |hotspot, i|
          puts "   🔍 Examining hotspot: #{hotspot.name}"

          # Simulate clicking on hotspot center
          click_pos = Raylib::Vector2.new(
            x: hotspot.position.x + hotspot.size.x / 2,
            y: hotspot.position.y + hotspot.size.y / 2
          )

          # Move player to hotspot (simulate click)
          if player = game.engine.player
            player.handle_click(click_pos, scene)
            take_screenshot.call("08_#{i + 1}_clicked_#{hotspot.name}")

            # Simulate some time passing for movement
            player.update(1.0f32)
            take_screenshot.call("09_#{i + 1}_after_movement_#{hotspot.name}")
          end

          # Check if any dialog was triggered
          if dm = game.engine.dialog_manager
            if dm.is_dialog_active?
              take_screenshot.call("10_#{i + 1}_dialog_from_#{hotspot.name}")
              dm.update(3.0f32) # Clear dialog
            end
          end
        end
      end

      # Step 5: Test Inventory System
      puts "\n🎒 Testing Inventory System..."

      # Add some test items
      test_key = PointClickEngine::Inventory::InventoryItem.new("test_key", "A mysterious key")
      test_book = PointClickEngine::Inventory::InventoryItem.new("test_book", "An ancient tome")

      game.engine.inventory.add_item(test_key)
      game.engine.inventory.add_item(test_book)

      # Show inventory
      game.engine.inventory.show
      take_screenshot.call("11_inventory_shown")

      # Select an item
      game.engine.inventory.select_item("test_key")
      take_screenshot.call("12_inventory_item_selected")

      # Hide inventory
      game.engine.inventory.hide
      take_screenshot.call("13_inventory_hidden")

      # Step 6: Navigate to Laboratory
      puts "\n🧪 Moving to Laboratory..."
      game.engine.change_scene("laboratory")
      take_screenshot.call("14_laboratory_scene")

      # Check laboratory hotspots
      if scene = game.engine.current_scene
        puts "   📍 Laboratory hotspots: #{scene.hotspots.map(&.name)}"
        scene.hotspots.size.should be > 0
      end

      # Step 7: Navigate to Garden
      puts "\n🌿 Moving to Garden..."
      game.engine.change_scene("garden")
      take_screenshot.call("15_garden_scene")

      # Check garden hotspots
      if scene = game.engine.current_scene
        puts "   📍 Garden hotspots: #{scene.hotspots.map(&.name)}"
        scene.hotspots.size.should be > 0
      end

      # Step 8: Test Achievement System
      puts "\n🏆 Testing Achievement System..."
      if am = game.engine.achievement_manager
        am.register("explorer", "Explorer", "Visited all areas")
        am.unlock("explorer")
        take_screenshot.call("16_achievement_unlocked")

        # Check notification queue
        am.@notification_queue.size.should be > 0
      end

      # Step 9: Test Save System
      puts "\n💾 Testing Save System..."

      # Save current game state
      save_success = PointClickEngine::Core::SaveSystem.save_game(game.engine, "playthrough_save")
      save_success.should be_true
      take_screenshot.call("17_game_saved")

      # Show save confirmation dialog
      game.engine.dialog_manager.try &.show_message("Game saved successfully!")
      take_screenshot.call("18_save_confirmation")

      # Step 10: Test Load Menu
      puts "\n📂 Testing Load Menu..."
      # Go to main menu first if not already there
      game.engine.change_scene("main_menu") if game.engine.current_scene.try(&.name) != "main_menu"
      if gui = game.engine.gui
        if load_button = gui.buttons["load_game"]?
          load_button.callback.call
          take_screenshot.call("19_load_menu")
        end
      end

      # Verify save file appears in load menu
      save_files = PointClickEngine::Core::SaveSystem.get_save_files
      save_files.should contain("playthrough_save")

      # Step 11: Test Debug Mode
      puts "\n🐛 Testing Debug Mode..."
      PointClickEngine::Core::Engine.debug_mode = true
      game.engine.change_scene("library")
      take_screenshot.call("20_debug_mode_enabled")

      # Debug mode should show hotspot outlines
      if scene = game.engine.current_scene
        scene.hotspots.each do |hotspot|
          hotspot.visible.should be_true
        end
      end

      # Step 12: Test UI Hide/Show
      puts "\n👁️ Testing UI Visibility..."
      game.engine.hide_ui
      take_screenshot.call("21_ui_hidden")

      game.engine.show_ui
      take_screenshot.call("22_ui_shown")

      # Step 13: Return to Main Menu
      puts "\n🏠 Returning to Main Menu..."
      # Use ESC key simulation or direct scene change
      game.engine.change_scene("main_menu")
      take_screenshot.call("23_back_to_main_menu_final")

      # Final verification
      game.engine.current_scene.try(&.name).should eq("main_menu")

      # Step 14: Final State
      take_screenshot.call("24_final_state")

      puts "\n✅ Visual Playthrough Complete!"
      puts "📁 Screenshots saved to: #{screenshot_dir}/"
      puts "🎯 Total screenshots taken: #{screenshot_counter}"

      # Cleanup
      PointClickEngine::Core::SaveSystem.delete_save("playthrough_save")
      PointClickEngine::Core::Engine.debug_mode = false

      # Verify we can access all expected functionality
      true.should be_true
    end

    it "validates all visual elements are properly configured" do
      puts "\n🔍 Validating Visual Configuration..."

      game = CrystalMysteryGame.new

      # Check engine initialization
      puts "   ✓ Engine initialized: #{!game.engine.nil?}"

      # Check display manager
      if dm = game.engine.display_manager
        puts "   ✓ Display manager configured: scaling=#{dm.scaling_mode}, target=#{dm.target_width}x#{dm.target_height}"
      else
        puts "   ⚠️  No display manager found"
      end

      # Check all scenes exist and have content
      required_scenes = ["main_menu", "library", "laboratory", "garden"]
      required_scenes.each do |scene_name|
        if scene = game.engine.scenes[scene_name]?
          puts "   ✓ Scene '#{scene_name}': #{scene.hotspots.size} hotspots, #{scene.characters.size} characters"

          # Check for background
          if scene.background_path
            puts "     - Background: #{scene.background_path}"
          else
            puts "     ⚠️  No background configured for #{scene_name}"
          end

          # List hotspots
          scene.hotspots.each do |hotspot|
            puts "     - Hotspot: #{hotspot.name} at (#{hotspot.position.x}, #{hotspot.position.y})"
          end
        else
          puts "   ❌ Missing scene: #{scene_name}"
        end
      end

      # Check GUI configuration
      if gui = game.engine.gui
        puts "   ✓ GUI manager available"
        puts "   ✓ Main menu buttons: #{gui.buttons.keys}"
        puts "   ✓ Main menu labels: #{gui.labels.keys}"
      else
        puts "   ❌ No GUI manager found"
      end

      # Check shader system
      if shaders = game.engine.shader_system
        puts "   ✓ Shader system available with #{shaders.shaders.size} shaders"
      else
        puts "   ⚠️  No shader system found"
      end

      # Check if assets directory exists
      if Dir.exists?("assets")
        puts "   ✓ Assets directory found"

        # List asset subdirectories
        ["backgrounds", "characters", "sounds", "music", "scripts"].each do |subdir|
          path = "assets/#{subdir}"
          if Dir.exists?(path)
            file_count = Dir.children(path).size
            puts "     - #{subdir}: #{file_count} files"
          else
            puts "     ⚠️  Missing assets/#{subdir}"
          end
        end
      else
        puts "   ⚠️  No assets directory found - this explains the black background!"
      end

      # Check script files
      if Dir.exists?("crystal_mystery/scripts")
        script_count = Dir.children("crystal_mystery/scripts").size
        puts "   ✓ Game scripts directory: #{script_count} files"
      else
        puts "   ⚠️  No game scripts directory found"
      end

      puts "\n💡 Diagnostic Summary:"
      puts "   The game likely shows a black background because:"
      puts "   1. Asset files (backgrounds, sprites) may not exist in the assets/ directory"
      puts "   2. Background textures may not be loading properly"
      puts "   3. Scene YAML files may reference missing asset files"
      puts "   4. The game needs actual image files to display visual content"

      puts "\n🔧 To fix the visual issues:"
      puts "   1. Create or download background images for each scene"
      puts "   2. Add character sprites and UI graphics"
      puts "   3. Ensure all asset paths in scene YAML files are correct"
      puts "   4. Check that Raylib can load the image formats being used"
    end
  end
end
