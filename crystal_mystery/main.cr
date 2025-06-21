require "../lib/raylib-cr/src/raylib-cr"
require "yaml"
require "json"
require "../src/point_click_engine"

# The Crystal Mystery - A Point & Click Adventure Game
class CrystalMysteryGame
  property engine : PointClickEngine::Core::Engine
  property current_scene : String = "main_menu"

  def initialize
    @engine = PointClickEngine::Core::Engine.new
    @engine.init(1024, 768, "The Crystal Mystery")

    # Enable all engine systems
    @engine.script_engine = PointClickEngine::Scripting::ScriptEngine.new
    @engine.dialog_manager = PointClickEngine::UI::DialogManager.new
    @engine.achievement_manager = PointClickEngine::Core::AchievementManager.new
    @engine.audio_manager = PointClickEngine::Audio::AudioManager.new
    @engine.config = PointClickEngine::Core::ConfigManager.new
    @engine.gui = PointClickEngine::UI::GUIManager.new
    @engine.shader_system = PointClickEngine::Graphics::Shaders::ShaderSystem.new
    @engine.player = PointClickEngine::Characters::Player.new(
      "Detective",
      Raylib::Vector2.new(x: 500f32, y: 400f32),
      Raylib::Vector2.new(x: 64f32, y: 128f32)
    )

    # Configure display settings
    if dm = @engine.display_manager
      dm.scaling_mode = PointClickEngine::Graphics::DisplayManager::ScalingMode::FitWithBars
      dm.target_width = 1024
      dm.target_height = 768
    end

    # Load game configuration
    load_configuration

    # Create scenes
    create_main_menu
    create_game_scenes

    # Initialize shaders
    setup_shaders

    # Start with main menu
    @engine.change_scene("main_menu")

    # Set up global input handler
    setup_global_input
  end

  def run
    @engine.run
  end

  private def load_configuration
    # Load game settings
    @engine.config.try do |config|
      config.set("game.version", "1.0.0")
      config.set("game.debug", "false")
      config.set("audio.master_volume", "0.8")
      config.set("graphics.fullscreen", "false")
    end
  end

  private def create_main_menu
    menu_scene = PointClickEngine::Scenes::Scene.new("main_menu")

    # Create UI elements for main menu
    if gui = @engine.gui
      # Title
      title_pos = Raylib::Vector2.new(x: 512f32, y: 200f32)
      gui.add_label("title", "The Crystal Mystery", title_pos, 48, Raylib::WHITE)

      # Buttons
      new_game_pos = Raylib::Vector2.new(x: 412f32, y: 350f32)
      new_game_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

      gui.add_button("new_game", "New Game", new_game_pos, new_game_size) do
        start_new_game
      end

      load_pos = Raylib::Vector2.new(x: 412f32, y: 420f32)

      gui.add_button("load_game", "Load Game", load_pos, new_game_size) do
        show_load_menu
      end

      options_pos = Raylib::Vector2.new(x: 412f32, y: 490f32)

      gui.add_button("options", "Options", options_pos, new_game_size) do
        show_options_menu
      end

      quit_pos = Raylib::Vector2.new(x: 412f32, y: 560f32)

      gui.add_button("quit", "Quit", quit_pos, new_game_size) do
        @engine.running = false
      end
    end

    @engine.add_scene(menu_scene)
  end

  private def create_game_scenes
    # Create library scene
    create_library_scene

    # Create laboratory scene
    create_laboratory_scene

    # Create garden scene
    create_garden_scene
  end

  private def create_library_scene
    scene_yaml = <<-YAML
    name: library
    background_path: assets/backgrounds/library.png
    enable_pathfinding: true
    navigation_cell_size: 16
    script_path: scripts/library.lua
    hotspots:
      - name: bookshelf
        x: 100
        y: 200
        width: 150
        height: 300
        description: "Ancient books line the shelves"
      - name: desk
        x: 400
        y: 400
        width: 200
        height: 150
        description: "A mahogany desk with scattered papers"
      - name: door_to_lab
        x: 850
        y: 300
        width: 100
        height: 200
        description: "Door to the laboratory"
      - name: painting
        x: 500
        y: 100
        width: 120
        height: 150
        description: "A portrait of the mansion's founder"
    characters:
      - name: butler
        position:
          x: 300
          y: 450
        sprite_info:
          frame_width: 64
          frame_height: 128
    YAML

    File.write("crystal_mystery/scenes/library.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("crystal_mystery/scenes/library.yaml")

    # Add scene-specific logic
    setup_library_interactions(scene)

    @engine.add_scene(scene)
  end

  private def create_laboratory_scene
    scene_yaml = <<-YAML
    name: laboratory
    background_path: assets/backgrounds/laboratory.png
    enable_pathfinding: true
    navigation_cell_size: 16
    script_path: scripts/laboratory.lua
    hotspots:
      - name: workbench
        x: 200
        y: 350
        width: 300
        height: 200
        description: "A cluttered workbench with beakers and tools"
      - name: cabinet
        x: 600
        y: 200
        width: 150
        height: 400
        description: "A locked cabinet with glass doors"
      - name: door_to_library
        x: 50
        y: 300
        width: 100
        height: 200
        description: "Back to the library"
      - name: door_to_garden
        x: 850
        y: 300
        width: 100
        height: 200
        description: "Door to the garden"
    characters:
      - name: scientist
        position:
          x: 400
          y: 400
        sprite_info:
          frame_width: 64
          frame_height: 128
    YAML

    File.write("crystal_mystery/scenes/laboratory.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("crystal_mystery/scenes/laboratory.yaml")

    setup_laboratory_interactions(scene)

    @engine.add_scene(scene)
  end

  private def create_garden_scene
    scene_yaml = <<-YAML
    name: garden
    background_path: assets/backgrounds/garden.png
    enable_pathfinding: true
    navigation_cell_size: 16
    script_path: scripts/garden.lua
    hotspots:
      - name: fountain
        x: 400
        y: 300
        width: 200
        height: 200
        description: "An ornate fountain with crystal-clear water"
      - name: statue
        x: 700
        y: 200
        width: 100
        height: 300
        description: "A weathered statue holding something..."
      - name: flowerbed
        x: 150
        y: 450
        width: 250
        height: 100
        description: "Beautiful roses in full bloom"
      - name: door_to_lab
        x: 50
        y: 300
        width: 100
        height: 200
        description: "Back to the laboratory"
    YAML

    File.write("crystal_mystery/scenes/garden.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("crystal_mystery/scenes/garden.yaml")

    setup_garden_interactions(scene)

    @engine.add_scene(scene)
  end

  private def setup_library_interactions(scene : PointClickEngine::Scenes::Scene)
    scene.hotspots.each do |hotspot|
      case hotspot.name
      when "door_to_lab"
        hotspot.on_click = -> do
          @engine.change_scene("laboratory")
        end
      when "bookshelf"
        hotspot.on_click = -> do
          @engine.dialog_manager.try &.show_message("You find a book about ancient crystals...")
        end
      end
    end
  end

  private def setup_laboratory_interactions(scene : PointClickEngine::Scenes::Scene)
    scene.hotspots.each do |hotspot|
      case hotspot.name
      when "door_to_library"
        hotspot.on_click = -> do
          @engine.change_scene("library")
        end
      when "door_to_garden"
        hotspot.on_click = -> do
          @engine.change_scene("garden")
        end
      end
    end
  end

  private def setup_garden_interactions(scene : PointClickEngine::Scenes::Scene)
    scene.hotspots.each do |hotspot|
      case hotspot.name
      when "door_to_lab"
        hotspot.on_click = -> do
          @engine.change_scene("laboratory")
        end
      when "fountain"
        hotspot.on_click = -> do
          @engine.dialog_manager.try &.show_message("The water sparkles mysteriously...")
        end
      end
    end
  end

  private def setup_shaders
    if shader_system = @engine.shader_system
      # Create atmospheric effects
      PointClickEngine::Graphics::Shaders::ShaderHelpers.create_vignette_shader(shader_system)
      PointClickEngine::Graphics::Shaders::ShaderHelpers.create_bloom_shader(shader_system)

      # Apply vignette to game scenes
      shader_system.set_active(:vignette)
    end
  end

  private def start_new_game
    # Initialize player
    if player = @engine.player
      player.name = "Detective"
      player.position = Raylib::Vector2.new(x: 500f32, y: 400f32)
    end

    # Clear inventory
    @engine.inventory.clear

    # Reset game state
    @engine.script_engine.try do |scripting|
      scripting.execute_script(<<-LUA)
        -- Initialize game state
        game_state = {
          has_key = false,
          cabinet_unlocked = false,
          crystal_found = false,
          talked_to_butler = false,
          talked_to_scientist = false,
          puzzle_solved = false
        }
        
        function get_game_state(key)
          return game_state[key]
        end
        
        function set_game_state(key, value)
          game_state[key] = value
        end
      LUA
    end

    # Start in library
    @engine.change_scene("library")

    # Show opening message
    @engine.dialog_manager.try &.show_message("You arrive at the mysterious mansion to investigate the missing crystal...")
  end

  private def show_load_menu
    # Clear current GUI elements
    @engine.gui.try &.clear_all

    # Get available save files
    save_files = PointClickEngine::Core::SaveSystem.get_save_files

    if gui = @engine.gui
      # Title
      gui.add_label("load_title", "Load Game", Raylib::Vector2.new(x: 512f32, y: 150f32), 36, Raylib::WHITE)

      if save_files.empty?
        gui.add_label("no_saves", "No saved games found", Raylib::Vector2.new(x: 512f32, y: 300f32), 24, Raylib::GRAY)
      else
        y_offset = 250f32
        save_files.each_with_index do |save_name, i|
          button_pos = Raylib::Vector2.new(x: 412f32, y: y_offset + (i * 60f32))
          button_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

          gui.add_button("load_#{i}", save_name, button_pos, button_size) do
            load_game(save_name)
          end
        end
      end

      # Back button
      back_pos = Raylib::Vector2.new(x: 412f32, y: 600f32)
      back_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

      gui.add_button("back_to_menu", "Back to Menu", back_pos, back_size) do
        back_to_main_menu
      end
    end
  end

  private def show_options_menu
    # Clear current GUI elements
    @engine.gui.try &.clear_all

    if gui = @engine.gui
      # Title
      gui.add_label("options_title", "Options", Raylib::Vector2.new(x: 512f32, y: 150f32), 36, Raylib::WHITE)

      # Audio Settings
      gui.add_label("audio_label", "Audio Settings", Raylib::Vector2.new(x: 300f32, y: 250f32), 24, Raylib::WHITE)

      # Master Volume
      current_volume = @engine.config.try(&.get("audio.master_volume", "0.8").to_f32) || 0.8f32
      volume_text = "Master Volume: #{(current_volume * 100).to_i}%"
      gui.add_label("volume_label", volume_text, Raylib::Vector2.new(x: 300f32, y: 290f32), 20, Raylib::LIGHTGRAY)

      # Volume buttons
      vol_down_pos = Raylib::Vector2.new(x: 250f32, y: 320f32)
      vol_up_pos = Raylib::Vector2.new(x: 350f32, y: 320f32)
      vol_button_size = Raylib::Vector2.new(x: 50f32, y: 30f32)

      gui.add_button("vol_down", "- ", vol_down_pos, vol_button_size) do
        decrease_volume
      end

      gui.add_button("vol_up", "+ ", vol_up_pos, vol_button_size) do
        increase_volume
      end

      # Graphics Settings
      gui.add_label("graphics_label", "Graphics Settings", Raylib::Vector2.new(x: 300f32, y: 400f32), 24, Raylib::WHITE)

      # Fullscreen toggle
      is_fullscreen = @engine.config.try(&.get("graphics.fullscreen", "false")) == "true"
      fullscreen_text = "Fullscreen: #{is_fullscreen ? "ON" : "OFF"}"
      gui.add_label("fullscreen_label", fullscreen_text, Raylib::Vector2.new(x: 300f32, y: 440f32), 20, Raylib::LIGHTGRAY)

      fullscreen_pos = Raylib::Vector2.new(x: 300f32, y: 470f32)
      fullscreen_size = Raylib::Vector2.new(x: 150f32, y: 30f32)

      gui.add_button("toggle_fullscreen", "Toggle", fullscreen_pos, fullscreen_size) do
        toggle_fullscreen
      end

      # Debug Mode
      is_debug = PointClickEngine::Core::Engine.debug_mode
      debug_text = "Debug Mode: #{is_debug ? "ON" : "OFF"}"
      gui.add_label("debug_label", debug_text, Raylib::Vector2.new(x: 300f32, y: 520f32), 20, Raylib::LIGHTGRAY)

      debug_pos = Raylib::Vector2.new(x: 300f32, y: 550f32)
      debug_size = Raylib::Vector2.new(x: 150f32, y: 30f32)

      gui.add_button("toggle_debug", "Toggle", debug_pos, debug_size) do
        toggle_debug_mode
      end

      # Back button
      back_pos = Raylib::Vector2.new(x: 412f32, y: 650f32)
      back_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

      gui.add_button("back_to_menu", "Back to Menu", back_pos, back_size) do
        back_to_main_menu
      end
    end
  end

  private def save_game(slot_name : String = "quicksave")
    success = PointClickEngine::Core::SaveSystem.save_game(@engine, slot_name)
    message = success ? "Game saved successfully!" : "Failed to save game."
    @engine.dialog_manager.try &.show_message(message)
  end

  private def load_game(slot_name : String)
    success = PointClickEngine::Core::SaveSystem.load_game(@engine, slot_name)
    if success
      @engine.dialog_manager.try &.show_message("Game loaded successfully!")
      @current_scene = @engine.current_scene.try(&.name) || "library"
    else
      @engine.dialog_manager.try &.show_message("Failed to load game.")
    end
  end

  private def back_to_main_menu
    @engine.gui.try &.clear_all
    @engine.change_scene("main_menu")
    create_main_menu # Recreate main menu GUI
  end

  private def decrease_volume
    if config = @engine.config
      current_volume = config.get("audio.master_volume", "0.8").to_f32
      new_volume = Math.max(0.0f32, current_volume - 0.1f32)
      config.set("audio.master_volume", new_volume.to_s)
      @engine.audio_manager.try &.set_master_volume(new_volume)
      update_options_display
    end
  end

  private def increase_volume
    if config = @engine.config
      current_volume = config.get("audio.master_volume", "0.8").to_f32
      new_volume = Math.min(1.0f32, current_volume + 0.1f32)
      config.set("audio.master_volume", new_volume.to_s)
      @engine.audio_manager.try &.set_master_volume(new_volume)
      update_options_display
    end
  end

  private def toggle_fullscreen
    if config = @engine.config
      is_fullscreen = config.get("graphics.fullscreen", "false") == "true"
      new_fullscreen = !is_fullscreen
      config.set("graphics.fullscreen", new_fullscreen.to_s)

      # Note: In a real implementation, you would toggle the window mode here
      # Raylib.toggle_fullscreen

      update_options_display
    end
  end

  private def toggle_debug_mode
    PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
    update_options_display
  end

  private def update_options_display
    # Update the option labels with new values
    if gui = @engine.gui
      # Update volume label
      if config = @engine.config
        current_volume = config.get("audio.master_volume", "0.8").to_f32
        volume_text = "Master Volume: #{(current_volume * 100).to_i}%"
        gui.update_label("volume_label", volume_text)

        # Update fullscreen label
        is_fullscreen = config.get("graphics.fullscreen", "false") == "true"
        fullscreen_text = "Fullscreen: #{is_fullscreen ? "ON" : "OFF"}"
        gui.update_label("fullscreen_label", fullscreen_text)
      end

      # Update debug label
      is_debug = PointClickEngine::Core::Engine.debug_mode
      debug_text = "Debug Mode: #{is_debug ? "ON" : "OFF"}"
      gui.update_label("debug_label", debug_text)
    end
  end

  private def setup_global_input
    # Note: Global input handling would be implemented in the engine's main loop
    # For now, shortcuts are handled per-scene in the game logic
    # F5 = Quick Save, F9 = Quick Load, ESC = Main Menu
  end

  def handle_global_input
    # F5 = Quick Save
    if Raylib.key_pressed?(Raylib::KeyboardKey::F5.to_i)
      save_game("quicksave")
    end

    # F9 = Quick Load
    if Raylib.key_pressed?(Raylib::KeyboardKey::F9.to_i)
      if PointClickEngine::Core::SaveSystem.save_exists?("quicksave")
        load_game("quicksave")
      else
        @engine.dialog_manager.try &.show_message("No quicksave found!")
      end
    end

    # ESC = Back to main menu (if in game)
    if Raylib.key_pressed?(Raylib::KeyboardKey::Escape.to_i)
      current_scene_name = @engine.current_scene.try(&.name)
      if current_scene_name != "main_menu"
        back_to_main_menu
      end
    end
  end
end

# Run the game
game = CrystalMysteryGame.new
game.run
