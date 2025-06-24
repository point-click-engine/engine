require "../spec_helper"
require "yaml"

# Integration tests for the complete validation system
describe "Validation System Integration" do
  it "validates a complete game configuration end-to-end" do
    temp_dir = File.tempname("integration_test")
    Dir.mkdir_p("#{temp_dir}/assets/sprites")
    Dir.mkdir_p("#{temp_dir}/assets/audio")
    Dir.mkdir_p("#{temp_dir}/scenes")
    Dir.mkdir_p("#{temp_dir}/dialogs")

    begin
      # Create a complete game configuration
      config_yaml = <<-YAML
      game:
        title: "Integration Test Game"
        version: "1.0.0"
        author: "Test Author"
      
      window:
        width: 1280
        height: 720
        fullscreen: false
        target_fps: 60
      
      display:
        scaling_mode: FitWithBars
        target_width: 1280
        target_height: 720
      
      player:
        name: "TestPlayer"
        sprite_path: "assets/sprites/player.png"
        sprite:
          frame_width: 64
          frame_height: 96
          columns: 8
          rows: 4
        start_position:
          x: 640.0
          y: 600.0
      
      features:
        - verbs
        - floating_dialogs
        - auto_save
      
      assets:
        scenes:
          - "scenes/*.yaml"
        dialogs:
          - "dialogs/*.yaml"
        audio:
          music:
            theme: "assets/audio/theme.ogg"
            battle: "assets/audio/battle.mp3"
          sounds:
            click: "assets/audio/click.wav"
            door: "assets/audio/door.ogg"
      
      settings:
        debug_mode: false
        show_fps: true
        master_volume: 0.8
        music_volume: 0.7
        sfx_volume: 0.9
      
      initial_state:
        flags:
          has_key: false
          door_opened: false
        variables:
          player_health: 100
          score: 0
      
      start_scene: "intro"
      start_music: "theme"
      
      ui:
        opening_message: "Welcome to the Integration Test Game!"
        hints:
          - text: "Click to interact"
            duration: 3.0
          - text: "Press ESC for menu"
            duration: 5.0
      YAML

      # Create all referenced files
      File.write("#{temp_dir}/config.yaml", config_yaml)
      File.write("#{temp_dir}/assets/sprites/player.png", "fake player sprite")
      File.write("#{temp_dir}/assets/audio/theme.ogg", "fake theme music")
      File.write("#{temp_dir}/assets/audio/battle.mp3", "fake battle music")
      File.write("#{temp_dir}/assets/audio/click.wav", "fake click sound")
      File.write("#{temp_dir}/assets/audio/door.ogg", "fake door sound")

      # Create a complete scene
      scene_yaml = <<-YAML
      name: intro
      background_path: assets/intro_bg.png
      scale: 1.0
      enable_pathfinding: true
      navigation_cell_size: 10
      
      hotspots:
        - name: door
          type: rectangle
          x: 500
          y: 300
          width: 100
          height: 200
          actions:
            look: "A sturdy wooden door"
            use: "open_door"
        
        - name: window
          type: polygon
          points:
            - x: 100
              y: 100
            - x: 200
              y: 100
            - x: 200
              y: 200
            - x: 100
              y: 200
          actions:
            look: "You can see the garden outside"
      
      walkable_areas:
        - points:
            - x: 0
              y: 500
            - x: 1280
              y: 500
            - x: 1280
              y: 720
            - x: 0
              y: 720
      
      exits:
        - x: 0
          y: 400
          width: 50
          height: 200
          target_scene: hallway
          spawn_position:
            x: 1200
            y: 500
      
      scale_zones:
        - x: 0
          y: 500
          width: 1280
          height: 220
          min_scale: 0.8
          max_scale: 1.2
      
      characters:
        - name: Guard
          position:
            x: 800.0
            y: 550.0
          sprite: assets/sprites/guard.png
          dialog: guard_dialog
      YAML

      File.write("#{temp_dir}/scenes/intro.yaml", scene_yaml)
      File.write("#{temp_dir}/assets/intro_bg.png", "fake background")
      File.write("#{temp_dir}/assets/sprites/guard.png", "fake guard sprite")

      # Create a dialog file
      dialog_yaml = <<-YAML
      name: guard_dialog
      nodes:
        - id: start
          text: "Halt! Who goes there?"
      YAML

      File.write("#{temp_dir}/dialogs/guard_dialog.yaml", dialog_yaml)

      # Now run the complete validation pipeline
      config = PointClickEngine::Core::GameConfig.from_file("#{temp_dir}/config.yaml")
      config.should_not be_nil
      config.game.title.should eq("Integration Test Game")

      # Run pre-flight check
      result = PointClickEngine::Core::PreflightCheck.run("#{temp_dir}/config.yaml")
      result.passed.should be_true
      result.errors.should be_empty
      result.info.size.should be > 0
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  it "catches all types of validation errors" do
    temp_dir = File.tempname("error_test")
    Dir.mkdir_p("#{temp_dir}/scenes")

    begin
      # Create a config with validation errors (but valid YAML syntax)
      config_yaml = <<-YAML
      game:
        title: ""
      window:
        width: -100
        height: 0
        target_fps: 1000
      player:
        name: "TestPlayer"
        sprite_path: "missing.png"
        sprite:
          frame_width: -32
          frame_height: 0
          columns: 0
          rows: 1
        start_position:
          x: -100.0
          y: -200.0
      display:
        scaling_mode: "InvalidMode"
        target_width: 0
        target_height: -768
      settings:
        master_volume: 2.0
        music_volume: -0.5
        sfx_volume: 1.5
      initial_state:
        flags:
          "": true
          "null": false
        variables:
          "": "empty"
          "false": 42
      start_scene: "nonexistent"
      start_music: "missing_track"
      assets:
        scenes:
          - "scenes/*.yaml"
        audio:
          music:
            theme: "missing_theme.ogg"
      YAML

      File.write("#{temp_dir}/config.yaml", config_yaml)

      # Create an invalid scene
      scene_yaml = <<-YAML
      name: wrong_name
      scale: 20.0
      hotspots:
        - name: ""
          type: "invalid_type"
        - type: polygon
          name: "poly"
          points:
            - x: 0
              y: 0
            - x: 100
      exits:
        - x: -50
          y: -100
          target_scene: ""
      scale_zones:
        - x: 0
          y: 0
          width: -100
          height: -200
          min_scale: 2.0
          max_scale: 1.0
      characters:
        - name: ""
          x: -500
          y: -600
      YAML

      File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

      # Attempt to load and validate
      expect_raises(PointClickEngine::Core::ValidationError) do
        PointClickEngine::Core::GameConfig.from_file("#{temp_dir}/config.yaml")
      end

      # Run pre-flight check to see all errors
      result = PointClickEngine::Core::PreflightCheck.run("#{temp_dir}/config.yaml")
      result.passed.should be_false

      # Config validation errors
      result.errors.any? { |e| e.includes?("Game title cannot be empty") }.should be_true
      result.errors.any? { |e| e.includes?("Window width must be positive") }.should be_true
      result.errors.any? { |e| e.includes?("Target FPS must be between") }.should be_true
      result.errors.any? { |e| e.includes?("Player sprite frame_width must be positive") }.should be_true
      result.errors.any? { |e| e.includes?("Invalid scaling_mode") }.should be_true
      result.errors.any? { |e| e.includes?("master_volume must be between") }.should be_true
      result.errors.any? { |e| e.includes?("Flag names cannot be empty") }.should be_true
      result.errors.any? { |e| e.includes?("reserved and cannot be used") }.should be_true
    ensure
      FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
    end
  end

  it "properly reports errors through the error reporter" do
    # Test each error type through the reporter
    errors_to_test = [
      PointClickEngine::Core::ConfigError.new("Bad config", "test.yaml", "field"),
      PointClickEngine::Core::AssetError.new("Missing", "asset.png", "scene.yaml"),
      PointClickEngine::Core::SceneError.new("Invalid", "test_scene", "hotspot"),
      PointClickEngine::Core::ValidationError.new(["Error 1", "Error 2"], "file.yaml"),
      PointClickEngine::Core::SaveGameError.new("Corrupted", "save.dat"),
    ]

    errors_to_test.each do |error|
      # Note: We can't easily capture STDOUT in Crystal specs
      # Just verify that reporting doesn't crash
      PointClickEngine::Core::ErrorReporter.report_loading_error(error)
    end
  end
end
