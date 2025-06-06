#!/usr/bin/env crystal

# Archive Loading Example
# Demonstrates how to load a complete game from a ZIP archive

require "../src/point_click_engine"

# First, create a sample game archive for testing
def create_sample_archive
  puts "Creating sample game archive..."
  
  # Create archive with sample game assets
  archive_path = "sample_game.zip"
  
  File.open(archive_path, "w") do |file|
    Compress::Zip::Writer.open(file) do |zip|
      # Add a background image (we'll use a placeholder)
      background_data = Bytes[0x89, 0x50, 0x4E, 0x47] # PNG header placeholder
      zip.add("assets/background.png", IO::Memory.new(background_data))
      
      # Add a character sprite (placeholder)
      sprite_data = Bytes[0x89, 0x50, 0x4E, 0x47] # PNG header placeholder  
      zip.add("assets/wizard.png", IO::Memory.new(sprite_data))
      
      # Add a Lua script
      lua_script = <<-LUA
      function on_init(character)
          print("Wizard initialized from archive!")
          character:set_position(400, 300)
      end
      
      function on_interact(character, player)
          print("Player interacted with wizard from archive")
          return "Greetings! I was loaded from an archive."
      end
      
      function on_update(character, dt)
          -- Simple idle animation logic could go here
      end
      LUA
      zip.add("scripts/wizard.lua", IO::Memory.new(lua_script))
      
      # Add a dialog tree YAML
      dialog_yaml = <<-YAML
      name: "Wizard Dialog"
      nodes:
        start:
          id: "start"
          text: "Hello traveler! I'm a wizard loaded from an archive."
          choices:
            - text: "How do archives work?"
              target_node_id: "explain"
            - text: "Goodbye"
              target_node_id: "end"
        explain:
          id: "explain"
          text: "Archives allow you to package all your game assets into a single file!"
          choices:
            - text: "That's amazing!"
              target_node_id: "amazing"
            - text: "Tell me more"
              target_node_id: "more"
        amazing:
          id: "amazing"
          text: "Indeed! This makes distribution much easier."
          choices:
            - text: "Goodbye"
              target_node_id: "end"
        more:
          id: "more"
          text: "You can include textures, sounds, scripts, and data files all in one ZIP."
          choices:
            - text: "Goodbye"
              target_node_id: "end"
        end:
          id: "end"
          text: "Farewell!"
          is_end: true
      YAML
      zip.add("dialogs/wizard_dialog.yml", IO::Memory.new(dialog_yaml))
      
      # Add a scene configuration
      scene_yaml = <<-YAML
      name: "wizard_chamber"
      background_path: "assets/background.png"
      characters:
        - name: "wizard"
          position:
            x: 400
            y: 300
          size:
            x: 64
            y: 64
          sprite_path: "assets/wizard.png"
          script_file: "scripts/wizard.lua"
      YAML
      zip.add("scenes/wizard_chamber.yml", IO::Memory.new(scene_yaml))
    end
  end
  
  puts "Sample archive created: #{archive_path}"
  archive_path
end

def run_archive_example
  puts "=== Point & Click Engine - Archive Loading Example ==="
  
  # Create sample archive
  archive_path = create_sample_archive
  
  begin
    # Create and initialize the game engine
    engine = PointClickEngine::Game.new(
      window_width: 800,
      window_height: 600,
      title: "Archive Loading Example"
    )
    
    # Mount the game archive
    puts "Mounting game archive..."
    engine.mount_archive(archive_path)
    
    # Verify archive contents
    puts "Archive contents:"
    files = PointClickEngine::AssetManager.list_files
    files.each { |file| puts "  - #{file}" }
    
    # Load assets from archive
    puts "\\nLoading assets from archive..."
    
    # Test script loading
    if PointClickEngine::AssetLoader.exists?("scripts/wizard.lua")
      script_content = PointClickEngine::AssetLoader.read_script("scripts/wizard.lua")
      puts "✓ Loaded Lua script (#{script_content.size} characters)"
    end
    
    # Test dialog loading
    if PointClickEngine::AssetLoader.exists?("dialogs/wizard_dialog.yml")
      dialog_content = PointClickEngine::AssetLoader.read_yaml("dialogs/wizard_dialog.yml")
      puts "✓ Loaded dialog YAML (#{dialog_content.size} characters)"
      
      # Parse and display dialog tree info
      dialog_tree = PointClickEngine::DialogTree.from_yaml(dialog_content)
      puts "  Dialog: '#{dialog_tree.name}' with #{dialog_tree.nodes.size} nodes"
    end
    
    # Test scene loading
    if PointClickEngine::AssetLoader.exists?("scenes/wizard_chamber.yml")
      scene_content = PointClickEngine::AssetLoader.read_yaml("scenes/wizard_chamber.yml")
      puts "✓ Loaded scene YAML (#{scene_content.size} characters)"
    end
    
    puts "\\n=== Archive Loading Successful! ==="
    puts "All game assets were successfully loaded from the archive."
    puts "In a real game, you would now initialize Raylib and start the game loop."
    puts "\\nTo run this with graphics, uncomment the game loop section below."
    
    # Uncomment to run with full graphics (requires display)
    # engine.init
    # puts "\\nStarting game... (Press ESC to quit)"
    # engine.run
    
    # Clean up
    engine.unmount_archive
    
  ensure
    # Clean up sample archive
    File.delete(archive_path) if File.exists?(archive_path)
  end
end

# Handle command line arguments
if ARGV.includes?("--help") || ARGV.includes?("-h")
  puts "Archive Loading Example"
  puts "Usage: crystal example/archive_example.cr"
  puts ""
  puts "This example demonstrates:"
  puts "- Creating a ZIP archive with game assets"
  puts "- Mounting the archive in the engine"
  puts "- Loading scripts, dialogs, and configurations from the archive"
  puts "- Listing archive contents"
  puts ""
  puts "The example runs without opening a window by default."
  puts "Edit the code to enable the full game loop with graphics."
  exit
end

# Run the example
begin
  run_archive_example
rescue ex
  puts "Error: #{ex.message}"
  puts ex.backtrace.join("\\n")
  exit 1
end