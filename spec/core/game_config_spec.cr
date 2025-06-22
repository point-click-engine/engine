require "../spec_helper"
require "../../src/core/game_config"

describe PointClickEngine::Core::GameConfig do
  describe ".from_file" do
    it "loads a valid game configuration from YAML" do
      yaml_content = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
        author: "Test Author"
      
      window:
        width: 800
        height: 600
        fullscreen: false
        target_fps: 60
      
      player:
        name: "TestPlayer"
        sprite_path: "assets/player.png"
        sprite:
          frame_width: 32
          frame_height: 32
          columns: 4
          rows: 4
      
      features:
        - verbs
        - floating_dialogs
      
      start_scene: "intro"
      YAML
      
      File.write("test_config.yaml", yaml_content)
      
      config = PointClickEngine::Core::GameConfig.from_file("test_config.yaml")
      
      config.game.title.should eq("Test Game")
      config.game.version.should eq("1.0.0")
      config.game.author.should eq("Test Author")
      config.window.try(&.width).should eq(800)
      config.window.try(&.height).should eq(600)
      config.features.should contain("verbs")
      config.features.should contain("floating_dialogs")
      config.start_scene.should eq("intro")
      
      File.delete("test_config.yaml")
    end
    
    it "uses default values for optional fields" do
      yaml_content = <<-YAML
      game:
        title: "Minimal Game"
      YAML
      
      File.write("minimal_config.yaml", yaml_content)
      
      config = PointClickEngine::Core::GameConfig.from_file("minimal_config.yaml")
      
      # Window should be nil and engine should use defaults
      config.window.should be_nil
      # Settings should also be nil with defaults used
      config.settings.should be_nil
      
      File.delete("minimal_config.yaml")
    end
    
    it "raises an error for invalid YAML" do
      File.write("invalid_config.yaml", "invalid: yaml: content:")
      
      expect_raises(YAML::ParseException) do
        PointClickEngine::Core::GameConfig.from_file("invalid_config.yaml")
      end
      
      File.delete("invalid_config.yaml")
    end
  end
  
  describe "#create_engine" do
    it "creates an engine with proper configuration" do
      yaml_content = <<-YAML
      game:
        title: "Engine Test"
      
      window:
        width: 1280
        height: 720
        target_fps: 120
      
      display:
        scaling_mode: "PixelPerfect"
        target_width: 640
        target_height: 480
      
      player:
        name: "Hero"
        sprite_path: "assets/hero.png"
        sprite:
          frame_width: 64
          frame_height: 64
          columns: 8
          rows: 4
        start_position:
          x: 100.0
          y: 200.0
      
      features:
        - verbs
        - portraits
        - debug
      
      settings:
        debug_mode: true
        show_fps: true
        master_volume: 0.5
      YAML
      
      File.write("engine_test_config.yaml", yaml_content)
      
      # Create dummy sprite file
      Dir.mkdir_p("assets")
      File.write("assets/hero.png", "dummy")
      
      config = PointClickEngine::Core::GameConfig.from_file("engine_test_config.yaml")
      
      # Mock window creation for testing
      RL.init_window(1280, 720, "Engine Test")
      
      engine = config.create_engine
      
      engine.window_width.should eq(1280)
      engine.window_height.should eq(720)
      engine.title.should eq("Engine Test")
      engine.target_fps.should eq(120)
      engine.show_fps.should be_true
      PointClickEngine::Core::Engine.debug_mode.should be_true
      
      # Check player configuration
      engine.player.should_not be_nil
      player = engine.player.not_nil!
      player.name.should eq("Hero")
      player.position.x.should eq(100.0)
      player.position.y.should eq(200.0)
      
      # Check features enabled
      engine.verb_input_system.should_not be_nil
      engine.dialog_manager.try(&.enable_portraits).should be_true
      
      # Check display manager configuration
      dm = engine.display_manager
      dm.should_not be_nil
      dm.try(&.scaling_mode).should eq(PointClickEngine::Graphics::DisplayManager::ScalingMode::PixelPerfect)
      
      RL.close_window
      File.delete("engine_test_config.yaml")
      File.delete("assets/hero.png")
      Dir.delete("assets")
    end
    
    it "loads assets from glob patterns" do
      # Create test directories and files
      Dir.mkdir_p("test_game/scenes")
      Dir.mkdir_p("test_game/quests")
      
      # Create test scene files
      scene1_yaml = <<-YAML
      name: scene1
      background_path: bg1.png
      YAML
      
      scene2_yaml = <<-YAML
      name: scene2
      background_path: bg2.png
      YAML
      
      File.write("test_game/scenes/scene1.yaml", scene1_yaml)
      File.write("test_game/scenes/scene2.yaml", scene2_yaml)
      
      # Create test quest file
      quest_yaml = <<-YAML
      - id: test_quest
        name: "Test Quest"
        description: "A test quest"
        category: main
        objectives:
          - id: obj1
            description: "Test objective"
            condition: "test_flag"
      YAML
      
      File.write("test_game/quests/main.yaml", quest_yaml)
      
      # Create config with asset paths
      config_yaml = <<-YAML
      game:
        title: "Asset Test"
      
      assets:
        scenes:
          - "test_game/scenes/*.yaml"
        quests:
          - "test_game/quests/*.yaml"
      YAML
      
      File.write("asset_test_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("asset_test_config.yaml")
      
      RL.init_window(800, 600, "Asset Test")
      engine = config.create_engine
      
      # Check scenes were loaded
      engine.scenes.size.should eq(2)
      engine.scenes.has_key?("scene1").should be_true
      engine.scenes.has_key?("scene2").should be_true
      
      # Check quests were loaded
      engine.quest_manager.should_not be_nil
      qm = engine.quest_manager.not_nil!
      qm.quests.size.should eq(1)
      qm.get_quest("test_quest").should_not be_nil
      
      # Cleanup
      RL.close_window
      File.delete("asset_test_config.yaml")
      File.delete("test_game/scenes/scene1.yaml")
      File.delete("test_game/scenes/scene2.yaml")
      File.delete("test_game/quests/main.yaml")
      Dir.delete("test_game/scenes")
      Dir.delete("test_game/quests")
      Dir.delete("test_game")
    end
    
    it "sets up initial game state" do
      yaml_content = <<-YAML
      game:
        title: "State Test"
      
      initial_state:
        flags:
          game_started: true
          tutorial_complete: false
        variables:
          player_health: 100
          score: 0
          player_name: "John"
      YAML
      
      File.write("state_test_config.yaml", yaml_content)
      config = PointClickEngine::Core::GameConfig.from_file("state_test_config.yaml")
      
      RL.init_window(800, 600, "State Test")
      engine = config.create_engine
      
      gsm = engine.game_state_manager
      gsm.should_not be_nil
      
      game_state = gsm.not_nil!
      game_state.get_flag("game_started").should be_true
      game_state.get_flag("tutorial_complete").should be_false
      game_state.get_variable("player_health").should eq(100)
      game_state.get_variable("score").should eq(0)
      game_state.get_variable("player_name").should eq("John")
      
      RL.close_window
      File.delete("state_test_config.yaml")
    end
    
    it "configures UI hints with auto-hide timers" do
      yaml_content = <<-YAML
      game:
        title: "UI Test"
      
      ui:
        hints:
          - text: "Welcome to the game!"
            duration: 2.0
          - text: "Press I for inventory"
            duration: 3.0
        opening_message: "The adventure begins..."
      
      start_scene: "intro"
      YAML
      
      File.write("ui_test_config.yaml", yaml_content)
      config = PointClickEngine::Core::GameConfig.from_file("ui_test_config.yaml")
      
      RL.init_window(800, 600, "UI Test")
      
      # Create a dummy intro scene since start_scene references it
      Dir.mkdir_p("scenes")
      scene_yaml = <<-YAML
      name: intro
      background_path: dummy.png
      YAML
      File.write("scenes/intro.yaml", scene_yaml)
      
      engine = config.create_engine
      
      # Add the scene manually since we're not loading from the proper path
      intro_scene = PointClickEngine::Scenes::Scene.new("intro")
      engine.add_scene(intro_scene)
      
      # Trigger game:new event to test UI setup
      engine.event_system.trigger("game:new")
      
      # Process the event queue
      engine.event_system.process_events
      
      # Check GUI has hints
      gui = engine.gui
      gui.should_not be_nil
      
      # Hints should be added
      gui.try(&.labels.has_key?("hint_0")).should be_true
      gui.try(&.labels.has_key?("hint_1")).should be_true
      
      # Note: Timer functionality for auto-hiding hints is not implemented
      # This would need GUI system support for timed element removal
      
      RL.close_window
      File.delete("ui_test_config.yaml")
      File.delete("scenes/intro.yaml")
      Dir.delete("scenes")
    end
  end
  
  describe "audio configuration" do
    pending "loads audio assets from config" do
      # This test requires audio flag to be enabled
      yaml_content = <<-YAML
      game:
        title: "Audio Test"
      
      assets:
        audio:
          music:
            main_theme: "assets/music/theme.ogg"
            battle_music: "assets/music/battle.ogg"
          sounds:
            click: "assets/sounds/click.ogg"
            explosion: "assets/sounds/boom.ogg"
      
      settings:
        master_volume: 0.7
        music_volume: 0.6
        sfx_volume: 0.8
      YAML
      
      File.write("audio_test_config.yaml", yaml_content)
      config = PointClickEngine::Core::GameConfig.from_file("audio_test_config.yaml")
      
      # Create dummy audio files
      Dir.mkdir_p("assets/music")
      Dir.mkdir_p("assets/sounds")
      File.write("assets/music/theme.ogg", "dummy")
      File.write("assets/music/battle.ogg", "dummy")
      File.write("assets/sounds/click.ogg", "dummy")
      File.write("assets/sounds/boom.ogg", "dummy")
      
      RL.init_window(800, 600, "Audio Test")
      
      engine = config.create_engine
      
      audio = engine.audio_manager
      audio.should_not be_nil
      
      if am = audio
        am.master_volume.should eq(0.7)
        am.music_volume.should eq(0.6)
        am.sfx_volume.should eq(0.8)
        
        # Check audio files were loaded
        am.has_music?("main_theme").should be_true
        am.has_music?("battle_music").should be_true
        am.has_sound?("click").should be_true
        am.has_sound?("explosion").should be_true
      end
      
      # Cleanup
      RL.close_window
      
      File.delete("audio_test_config.yaml")
      File.delete("assets/music/theme.ogg")
      File.delete("assets/music/battle.ogg")
      File.delete("assets/sounds/click.ogg")
      File.delete("assets/sounds/boom.ogg")
      Dir.delete("assets/music")
      Dir.delete("assets/sounds")
      Dir.delete("assets")
    end
  end
  
  describe "feature flags" do
    it "enables auto-save feature" do
      yaml_content = <<-YAML
      game:
        title: "Auto-save Test"
      
      features:
        - auto_save
      YAML
      
      File.write("autosave_test_config.yaml", yaml_content)
      config = PointClickEngine::Core::GameConfig.from_file("autosave_test_config.yaml")
      
      RL.init_window(800, 600, "Auto-save Test")
      engine = config.create_engine
      
      # Auto-save should be enabled with 5 minute interval
      engine.auto_save_interval.should eq(300.0f32)
      
      RL.close_window
      File.delete("autosave_test_config.yaml")
    end
    
    it "enables shader system" do
      yaml_content = <<-YAML
      game:
        title: "Shader Test"
      
      features:
        - shaders
      YAML
      
      File.write("shader_test_config.yaml", yaml_content)
      config = PointClickEngine::Core::GameConfig.from_file("shader_test_config.yaml")
      
      RL.init_window(800, 600, "Shader Test")
      engine = config.create_engine
      
      shader_system = engine.shader_system
      shader_system.should_not be_nil
      
      # Check default shaders were created
      shader_system.try(&.get_shader(:vignette)).should_not be_nil
      shader_system.try(&.get_shader(:bloom)).should_not be_nil
      
      RL.close_window
      File.delete("shader_test_config.yaml")
    end
  end
end