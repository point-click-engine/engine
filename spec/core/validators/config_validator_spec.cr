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

      # Try to parse incomplete config - should raise exception
      expect_raises(YAML::ParseException, "Missing YAML attribute: game") do
        PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      end
    end

    it "detects empty game title" do
      config_yaml = <<-YAML
      game:
        title: ""
        version: "1.0.0"
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.includes?("Game title cannot be empty").should be_true
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

      errors.includes?("Window width must be positive (got -100).should be_true")
      errors.includes?("Window height must be positive (got 0).should be_true")
      errors.includes?("Target FPS must be between 1 and 300 (got 500).should be_true")
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

      errors.includes?("Player sprite_path cannot be empty").should be_true
      errors.includes?("Player sprite frame_width must be positive").should be_true
      errors.includes?("Player sprite frame_height must be positive").should be_true
      errors.includes?("Player sprite columns must be positive").should be_true
      errors.includes?("Player sprite rows must be positive").should be_true
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

      errors.includes?("Invalid scaling_mode 'InvalidMode'. Must be one of: FitWithBars, Stretch, PixelPerfect").should be_true
      errors.includes?("Display target_width must be positive").should be_true
      errors.includes?("Display target_height must be positive").should be_true
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

      errors.includes?("master_volume must be between 0 and 1 (got 1.5).should be_true")
      errors.includes?("music_volume must be between 0 and 1 (got -0.1).should be_true")
      errors.includes?("sfx_volume must be between 0 and 1 (got 2.0).should be_true")
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

      errors.includes?("Flag names cannot be empty").should be_true
      errors.includes?("Flag name 'true' is reserved and cannot be used").should be_true
      errors.includes?("Variable name 'null' is reserved and cannot be used").should be_true
      errors.includes?("Variable names cannot be empty").should be_true
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
            - "scenes/*.yaml"
            - "nonexistent/*.yaml"
          dialogs:
            - "dialogs/*.yaml"
          audio:
            music:
              theme: "music/theme.ogg"
            sounds:
              click: "sounds/click.wav"
        YAML

        config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "#{temp_dir}/config.yaml")

        errors.includes?("Scene pattern 'scenes/*.yaml' matches no files").should be_true
        errors.includes?("Scene pattern 'nonexistent/*.yaml' matches no files").should be_true
        errors.includes?("No scene files found using provided patterns").should be_true
        errors.includes?("Dialog pattern 'dialogs/*.yaml' matches no files").should be_true
        errors.includes?("Music file 'theme' not found at: music/theme.ogg").should be_true
        errors.includes?("Sound file 'click' not found at: sounds/click.wav").should be_true
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
      errors.includes?("Start music 'missing_music' not defined in audio.music section").should be_true
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
          x: -100.0
          y: -50.0
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "test_config.yaml")

      errors.includes?("Player start position X cannot be negative").should be_true
      errors.includes?("Player start position Y cannot be negative").should be_true
    end
  end
end
