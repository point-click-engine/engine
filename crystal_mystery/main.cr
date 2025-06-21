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
    # TODO: Implement save/load system
    @engine.dialog_manager.try &.show_message("Load game feature coming soon!")
  end

  private def show_options_menu
    # TODO: Implement options menu
    @engine.dialog_manager.try &.show_message("Options menu coming soon!")
  end

  private def setup_global_input
    # TODO: Set up global input handling in the engine's update loop
    # For now, we'll add input handling to each scene
  end
end

# Run the game
game = CrystalMysteryGame.new
game.run
