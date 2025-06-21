require "../spec_helper"
require "../../crystal_mystery/main"

describe "Crystal Mystery Diagnostic" do
  it "diagnoses why the game shows a black background" do
    puts "\n🔍 CRYSTAL MYSTERY DIAGNOSTIC REPORT"
    puts "======================================"

    game = CrystalMysteryGame.new

    puts "\n1. ENGINE INITIALIZATION"
    puts "   ✓ Engine created: #{!game.engine.nil?}"
    puts "   ✓ Window size: #{game.engine.window_width}x#{game.engine.window_height}"
    puts "   ✓ Title: #{game.engine.title}"

    puts "\n2. SCENES ANALYSIS"
    game.engine.scenes.each do |name, scene|
      puts "\n   📁 Scene: #{name}"
      puts "      - Background path: #{scene.background_path || "❌ NONE"}"
      puts "      - Background texture: #{scene.background ? "✓ loaded" : "❌ not loaded"}"
      puts "      - Hotspots: #{scene.hotspots.size}"
      puts "      - Characters: #{scene.characters.size}"
      puts "      - Objects: #{scene.objects.size}"

      # Check hotspot details
      scene.hotspots.each do |hotspot|
        puts "        • Hotspot '#{hotspot.name}': pos(#{hotspot.position.x}, #{hotspot.position.y}) size(#{hotspot.size.x}, #{hotspot.size.y})"
      end
    end

    puts "\n3. CURRENT SCENE STATUS"
    current = game.engine.current_scene
    if current
      puts "   ✓ Current scene: #{current.name}"
      puts "   ✓ Background path: #{current.background_path || "❌ NONE"}"
      puts "   ✓ Background loaded: #{current.background ? "YES" : "NO"}"
    else
      puts "   ❌ No current scene set!"
    end

    puts "\n4. GUI SYSTEM STATUS"
    gui = game.engine.gui
    if gui
      puts "   ✓ GUI manager exists"
      puts "   ✓ GUI visible: #{gui.visible}"
      puts "   ✓ Labels: #{gui.labels.size} (#{gui.labels.keys})"
      puts "   ✓ Buttons: #{gui.buttons.size} (#{gui.buttons.keys})"
    else
      puts "   ❌ No GUI manager!"
    end

    puts "\n5. DISPLAY MANAGER STATUS"
    dm = game.engine.display_manager
    if dm
      puts "   ✓ Display manager exists"
      puts "   ✓ Target size: #{dm.target_width}x#{dm.target_height}"
      puts "   ✓ Scaling mode: #{dm.scaling_mode}"
    else
      puts "   ⚠️  No display manager configured"
    end

    puts "\n6. ASSET DIRECTORIES CHECK"
    asset_paths = [
      "assets",
      "assets/backgrounds",
      "assets/characters",
      "assets/sounds",
      "assets/music",
      "crystal_mystery/scenes",
      "crystal_mystery/scripts",
    ]

    asset_paths.each do |path|
      if Dir.exists?(path)
        file_count = Dir.children(path).size
        puts "   ✓ #{path}: #{file_count} files"

        if file_count > 0 && path.includes?("assets")
          Dir.children(path).each do |file|
            puts "     - #{file}"
          end
        end
      else
        puts "   ❌ Missing: #{path}"
      end
    end

    puts "\n7. SCENE YAML FILES CHECK"
    yaml_files = ["library.yaml", "laboratory.yaml", "garden.yaml"]
    yaml_files.each do |yaml_file|
      path = "crystal_mystery/scenes/#{yaml_file}"
      if File.exists?(path)
        puts "   ✓ #{yaml_file} exists"

        # Try to read the YAML content
        begin
          content = File.read(path)
          yaml_data = YAML.parse(content)
          puts "     - Background path in YAML: #{yaml_data["background_path"]?}"
          puts "     - Hotspots count: #{yaml_data["hotspots"]?.try(&.as_a.size) || 0}"
        rescue ex
          puts "     ❌ Error reading YAML: #{ex.message}"
        end
      else
        puts "   ❌ Missing: #{yaml_file}"
      end
    end

    puts "\n8. TESTING BACKGROUND LOADING"
    # Try to load a background manually
    test_bg_paths = [
      "assets/backgrounds/library.png",
      "assets/backgrounds/laboratory.png",
      "assets/backgrounds/garden.png",
    ]

    test_bg_paths.each do |bg_path|
      if File.exists?(bg_path)
        puts "   ✓ Background file exists: #{bg_path}"
        file_size = File.size(bg_path)
        puts "     - File size: #{file_size} bytes"

        # Try to load it with Raylib (this might fail but will show us what happens)
        begin
          # texture = Raylib.load_texture(bg_path)
          puts "     - Would attempt to load with Raylib"
        rescue ex
          puts "     ❌ Failed to load: #{ex.message}"
        end
      else
        puts "   ❌ Missing background: #{bg_path}"
      end
    end

    puts "\n9. MAIN MENU BUTTON FUNCTIONALITY TEST"
    # Test if clicking new game actually works
    if gui = game.engine.gui
      if new_game_button = gui.buttons["new_game"]?
        puts "   ✓ New Game button exists"

        # Test the callback
        begin
          puts "   🔄 Testing New Game button callback..."
          new_game_button.callback.call

          # Check if scene changed
          new_scene = game.engine.current_scene.try(&.name)
          puts "   → Scene after New Game: #{new_scene}"

          if new_scene == "library"
            puts "   ✓ Scene change successful!"
          else
            puts "   ❌ Scene didn't change to library"
          end
        rescue ex
          puts "   ❌ New Game button failed: #{ex.message}"
        end
      else
        puts "   ❌ New Game button not found!"
      end
    end

    puts "\n10. CONCLUSION AND RECOMMENDATIONS"
    puts "=================================="

    # Check for specific issues
    issues = [] of String

    # Check if scenes have backgrounds
    game.engine.scenes.each do |name, scene|
      if !scene.background_path
        issues << "Scene '#{name}' has no background_path configured"
      elsif scene.background_path && !File.exists?(scene.background_path.not_nil!)
        issues << "Scene '#{name}' background file missing: #{scene.background_path}"
      end
    end

    # Check for asset directories
    if !Dir.exists?("assets/backgrounds")
      issues << "No assets/backgrounds directory found"
    end

    # Check for scene files
    if !Dir.exists?("crystal_mystery/scenes")
      issues << "No crystal_mystery/scenes directory found"
    end

    if issues.empty?
      puts "   🎉 No major issues found! The black background might be due to:"
      puts "      1. Background images not being drawn in the render loop"
      puts "      2. Background textures not being loaded at scene creation"
      puts "      3. Display scaling issues"
      puts "      4. Scene backgrounds being drawn but not visible (z-order, color, etc.)"
    else
      puts "   🚨 ISSUES FOUND:"
      issues.each_with_index do |issue, i|
        puts "      #{i + 1}. #{issue}"
      end

      puts "\n   💡 RECOMMENDED FIXES:"
      puts "      1. Create missing asset directories and files"
      puts "      2. Download or create background images for each scene"
      puts "      3. Ensure scene YAML files reference correct paths"
      puts "      4. Verify background loading in SceneLoader"
    end

    puts "\n   🔧 QUICK TEST:"
    puts "      Try creating a simple test background:"
    puts "      mkdir -p assets/backgrounds"
    puts "      # Create a simple colored PNG for testing"

    # This test should always pass - we're just gathering info
    true.should be_true
  end
end
