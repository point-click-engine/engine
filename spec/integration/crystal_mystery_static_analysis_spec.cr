require "../spec_helper"

describe "Crystal Mystery Static Analysis" do
  it "analyzes the Crystal Mystery game code to identify visual issues" do
    puts "\n🔍 STATIC ANALYSIS: Crystal Mystery Visual Issues"
    puts "================================================="

    puts "\n1. CHECKING ASSET DIRECTORIES"
    required_dirs = [
      "assets",
      "assets/backgrounds",
      "assets/characters",
      "crystal_mystery",
      "crystal_mystery/scenes",
    ]

    missing_dirs = [] of String
    required_dirs.each do |dir|
      if Dir.exists?(dir)
        file_count = Dir.children(dir).size
        puts "   ✓ #{dir}: #{file_count} files"
        if file_count > 0
          Dir.children(dir).first(3).each do |file|
            puts "     - #{file}"
          end
          puts "     #{"... and #{file_count - 3} more" if file_count > 3}"
        end
      else
        puts "   ❌ Missing: #{dir}"
        missing_dirs << dir
      end
    end

    puts "\n2. CHECKING CRYSTAL MYSTERY MAIN.CR STRUCTURE"
    main_file = "crystal_mystery/main.cr"
    if File.exists?(main_file)
      puts "   ✓ Main game file exists"

      content = File.read(main_file)

      # Check for scene creation
      if content.includes?("create_library_scene")
        puts "   ✓ Library scene creation found"
      else
        puts "   ❌ Library scene creation not found"
      end

      # Check for background paths in scene YAML
      if content.includes?("background_path:")
        puts "   ✓ Background paths configured in scenes"

        # Extract background paths
        content.scan(/background_path:\s*(.+)/) do |match|
          bg_path = match[1].strip
          puts "     - Background: #{bg_path}"

          # Check if file exists
          if File.exists?(bg_path)
            puts "       ✓ File exists"
          else
            puts "       ❌ File missing: #{bg_path}"
          end
        end
      else
        puts "   ❌ No background paths found in scene YAML"
      end

      # Check for scene loading
      if content.includes?("SceneLoader.load_from_yaml")
        puts "   ✓ Scene loading from YAML found"
      else
        puts "   ❌ Scene loading not found"
      end
    else
      puts "   ❌ Main game file not found: #{main_file}"
    end

    puts "\n3. CHECKING SCENE LOADER IMPLEMENTATION"
    scene_loader_file = "src/scenes/scene_loader.cr"
    if File.exists?(scene_loader_file)
      puts "   ✓ SceneLoader exists"

      content = File.read(scene_loader_file)

      # Check if it loads backgrounds
      if content.includes?("background_path") && content.includes?("load_texture")
        puts "   ✓ Background loading logic found"
      else
        puts "   ❌ Background loading logic missing or incomplete"

        # Show what's in the file
        puts "   📝 SceneLoader contains:"
        content.lines.first(10).each_with_index do |line, i|
          puts "     #{i + 1}: #{line.strip}" if line.strip.size > 0
        end
      end
    else
      puts "   ❌ SceneLoader not found: #{scene_loader_file}"
    end

    puts "\n4. CHECKING SCENE.CR BACKGROUND HANDLING"
    scene_file = "src/scenes/scene.cr"
    if File.exists?(scene_file)
      puts "   ✓ Scene class exists"

      content = File.read(scene_file)

      # Check for background properties
      if content.includes?("background_path") && content.includes?("background")
        puts "   ✓ Background properties found"
      else
        puts "   ❌ Background properties missing"
      end

      # Check for draw method
      if content.includes?("def draw")
        puts "   ✓ Scene draw method found"

        # Check if it draws the background
        if content.includes?("draw_texture") || content.includes?("background")
          puts "   ✓ Background drawing logic found"
        else
          puts "   ❌ Background drawing logic missing"
        end
      else
        puts "   ❌ Scene draw method not found"
      end
    else
      puts "   ❌ Scene file not found: #{scene_file}"
    end

    puts "\n5. SUGGESTED BACKGROUND FILES TO CREATE"
    background_files = [
      "assets/backgrounds/library.png",
      "assets/backgrounds/laboratory.png",
      "assets/backgrounds/garden.png",
    ]

    puts "   📁 Create these directories and files:"
    puts "      mkdir -p assets/backgrounds"

    background_files.each do |bg_file|
      if File.exists?(bg_file)
        puts "   ✓ #{bg_file} exists"
      else
        puts "   📝 Need to create: #{bg_file}"
      end
    end

    puts "\n6. PROBABLE ROOT CAUSE ANALYSIS"
    if missing_dirs.includes?("assets/backgrounds")
      puts "   🎯 PRIMARY ISSUE: Missing assets/backgrounds directory"
      puts "      → The game scenes reference background images that don't exist"
      puts "      → This causes backgrounds to fail loading, resulting in black screen"
      puts "      → The menu works because it uses GUI elements, not background images"
    elsif Dir.exists?("assets/backgrounds") && Dir.children("assets/backgrounds").empty?
      puts "   🎯 PRIMARY ISSUE: Empty assets/backgrounds directory"
      puts "      → Directory exists but contains no background images"
      puts "      → Scene YAML files reference images that don't exist"
    else
      puts "   🎯 POSSIBLE ISSUES:"
      puts "      → Background loading code may not be working"
      puts "      → Background drawing might not be implemented"
      puts "      → Asset paths in scene YAML may be incorrect"
    end

    puts "\n7. IMMEDIATE FIX RECOMMENDATIONS"
    puts "   💡 To fix the black background:"
    puts "      1. Create placeholder background images:"
    puts "         mkdir -p assets/backgrounds"
    puts "         # Create simple colored rectangles as PNG files"
    puts "      "
    puts "      2. Alternative quick fix - modify scene YAML to remove background_path:"
    puts "         # This will show just the GUI without trying to load missing images"
    puts "      "
    puts "      3. Check the SceneLoader loads and draws backgrounds properly"
    puts "      "
    puts "      4. Verify the Scene.draw method includes background rendering"

    # This always passes - it's just an analysis
    true.should be_true
  end

  it "creates minimal test background files for immediate testing" do
    puts "\n🛠️  CREATING TEST BACKGROUND FILES"
    puts "================================="

    # Create assets directory structure
    Dir.mkdir_p("assets/backgrounds") unless Dir.exists?("assets/backgrounds")

    # Create simple test "images" (really just text files that can be detected)
    test_backgrounds = [
      {name: "library.png", color: "blue library background"},
      {name: "laboratory.png", color: "green laboratory background"},
      {name: "garden.png", color: "brown garden background"},
    ]

    test_backgrounds.each do |bg|
      file_path = "assets/backgrounds/#{bg[:name]}"
      unless File.exists?(file_path)
        # Create a minimal PNG-like file (just for testing existence)
        # In a real scenario, you'd create actual PNG files
        File.write(file_path, "# Test background: #{bg[:color]}\n# This is a placeholder for #{bg[:name]}")
        puts "   📝 Created placeholder: #{file_path}"
      else
        puts "   ✓ Already exists: #{file_path}"
      end
    end

    # Create scene directories if needed
    Dir.mkdir_p("crystal_mystery/scenes") unless Dir.exists?("crystal_mystery/scenes")

    puts "\n   ✅ Test files created!"
    puts "   🎮 Try running the game again - it should now attempt to load backgrounds"
    puts "   📝 Note: These are placeholder files. For actual backgrounds, you need real PNG images"

    # Verify we created the files
    created_files = Dir.children("assets/backgrounds")
    created_files.size.should be >= 3
  end
end
