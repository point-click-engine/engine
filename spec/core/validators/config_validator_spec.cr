require "../../spec_helper"
require "yaml"

describe PointClickEngine::Core::Validators::ConfigValidator do
  describe ".validate" do
    it "validates a valid configuration" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 1024
        height: 768
        target_fps: 60
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should be_empty
    end

    it "detects missing game section" do
      config_yaml = <<-YAML
      window:
        width: 1024
        height: 768
      YAML

      # Create a config without game section by manipulating the parsed data
      yaml_data = YAML.parse(config_yaml)
      config = PointClickEngine::Core::GameConfig.new
      config.window = PointClickEngine::Core::GameConfig::WindowConfig.from_yaml(yaml_data["window"].to_yaml)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("Missing required 'game' section")
    end

    it "detects empty game title" do
      config_yaml = <<-YAML
      game:
        title: ""
        version: "1.0.0"
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("Game title cannot be empty")
    end

    it "validates window configuration" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: -100
        height: 0
        target_fps: 500
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("Window width must be positive (got -100)")
      errors.should contain("Window height must be positive (got 0)")
      errors.should contain("Target FPS must be between 1 and 300 (got 500)")
    end

    it "validates player configuration" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      player:
        name: "Player"
        sprite_path: ""
        sprite:
          frame_width: 0
          frame_height: -10
          columns: 0
          rows: -1
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("Player sprite_path cannot be empty")
      errors.should contain("Player sprite frame_width must be positive")
      errors.should contain("Player sprite frame_height must be positive")
      errors.should contain("Player sprite columns must be positive")
      errors.should contain("Player sprite rows must be positive")
    end

    it "validates display configuration" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      display:
        scaling_mode: "InvalidMode"
        target_width: -1024
        target_height: 0
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("Invalid scaling_mode 'InvalidMode'. Must be one of: FitWithBars, Stretch, PixelPerfect")
      errors.should contain("Display target_width must be positive")
      errors.should contain("Display target_height must be positive")
    end

    it "validates audio volume settings" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      settings:
        master_volume: 1.5
        music_volume: -0.1
        sfx_volume: 2.0
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("master_volume must be between 0 and 1 (got 1.5)")
      errors.should contain("music_volume must be between 0 and 1 (got -0.1)")
      errors.should contain("sfx_volume must be between 0 and 1 (got 2.0)")
    end

    it "validates initial state variable names" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      initial_state:
        flags:
          "": true
          "true": false
        variables:
          "null": 42
          "": "value"
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("Flag names cannot be empty")
      errors.should contain("Flag name 'true' is reserved and cannot be used")
      errors.should contain("Variable name 'null' is reserved and cannot be used")
      errors.should contain("Variable names cannot be empty")
    end

    it "validates asset patterns" do
      # Create temporary directory structure for testing
      temp_dir = File.tempname("config_test")
      Dir.mkdir(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "#{temp_dir}/scenes/*.yaml"
            - "#{temp_dir}/nonexistent/*.yaml"
          dialogs:
            - "#{temp_dir}/dialogs/*.yaml"
          audio:
            music:
              theme: "#{temp_dir}/music/theme.ogg"
            sounds:
              click: "#{temp_dir}/sounds/click.wav"
        YAML

        config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "#{temp_dir}/config.yaml")

        errors.should contain("Scene pattern 'scenes/*.yaml' matches no files")
        errors.should contain("Scene pattern 'nonexistent/*.yaml' matches no files")
        errors.should contain("No scene files found using provided patterns")
        errors.should contain("Dialog pattern 'dialogs/*.yaml' matches no files")
        errors.should contain("Music file 'theme' not found at: music/theme.ogg")
        errors.should contain("Sound file 'click' not found at: sounds/click.wav")
      ensure
        Dir.delete(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "validates start scene and music references" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      start_scene: "missing_scene"
      start_music: "missing_music"
      assets:
        scenes:
          - "scenes/*.yaml"
        audio:
          music:
            theme: "music/theme.ogg"
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.any? { |e| e.includes?("Start scene 'missing_scene' not found") }.should be_true
      errors.should contain("Start music 'missing_music' not defined in audio.music section")
    end

    it "validates player start position" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      player:
        name: "Player"
        sprite_path: "player.png"
        sprite:
          frame_width: 32
          frame_height: 48
          columns: 4
          rows: 4
        start_position:
          x: -100
          y: -50
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.should contain("Player start position X cannot be negative")
      errors.should contain("Player start position Y cannot be negative")
    end
  end
end
