require "../../spec_helper"
require "../../../src/core/validators/config_validator"
require "../../../src/core/game_config"

def with_temp_config_game(&)
  temp_dir = File.tempname("config_validator")
  Dir.mkdir_p(temp_dir)
  yield temp_dir
ensure
  FileUtils.rm_rf(temp_dir) if temp_dir && Dir.exists?(temp_dir)
end

def write_temp_config(temp_dir : String, content : String) : String
  path = File.join(temp_dir, "game_config.yaml")
  File.write(path, content)
  path
end

def load_temp_config(config_path : String) : PointClickEngine::Core::GameConfig
  PointClickEngine::Core::GameConfig.from_file(config_path, skip_preflight: true)
end

describe PointClickEngine::Core::Validators::ConfigValidator do
  describe "configuration loading behavior" do
    it "wraps YAML parse failures in ConfigError" do
      with_temp_config_game do |temp_dir|
        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
          window:
            width: 800
            height: 600
            invalid: [unclosed array
        YAML
        )

        expect_raises(PointClickEngine::Core::ConfigError, /Invalid YAML syntax/) do
          PointClickEngine::Core::GameConfig.from_file(config_path, skip_preflight: true)
        end
      end
    end

    it "wraps missing files in ConfigError" do
      expect_raises(PointClickEngine::Core::ConfigError, /Configuration file not found/) do
        PointClickEngine::Core::GameConfig.from_file("nonexistent_config.yaml", skip_preflight: true)
      end
    end
  end

  describe ".validate" do
    it "accepts a valid minimal runtime config" do
      with_temp_config_game do |temp_dir|
        Dir.mkdir_p(File.join(temp_dir, "scenes"))
        Dir.mkdir_p(File.join(temp_dir, "sprites"))
        File.write(File.join(temp_dir, "sprites", "player.png"), "fake_png")
        File.write(File.join(temp_dir, "scenes", "intro.yaml"), <<-YAML
          name: intro
          background_path: sprites/player.png
        YAML
        )

        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
            version: "1.0.0"
          window:
            width: 800
            height: 600
          player:
            sprite_path: "sprites/player.png"
            sprite:
              frame_width: 32
              frame_height: 48
              columns: 4
              rows: 4
            start_position:
              x: 100.0
              y: 100.0
          assets:
            scenes:
              - "scenes/*.yaml"
          start_scene: "intro"
        YAML
        )

        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(load_temp_config(config_path), config_path)
        errors.should be_empty
      end
    end

    it "reports invalid window dimensions" do
      with_temp_config_game do |temp_dir|
        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
          window:
            width: -800
            height: 0
            target_fps: 999
        YAML
        )

        config = PointClickEngine::Core::GameConfig.from_yaml(File.read(config_path))
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_path)

        errors.should contain("Window width must be positive (got -800)")
        errors.should contain("Window height must be positive (got 0)")
        errors.should contain("Target FPS must be between 1 and 300 (got 999)")
      end
    end

    it "reports missing player sprite files and invalid sprite sheet data" do
      with_temp_config_game do |temp_dir|
        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
          player:
            sprite_path: "sprites/missing.png"
            sprite:
              frame_width: 0
              frame_height: -1
              columns: 0
              rows: 0
            start_position:
              x: -5.0
              y: -10.0
        YAML
        )

        config = PointClickEngine::Core::GameConfig.from_yaml(File.read(config_path))
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_path)

        errors.should contain("Player sprite not found: sprites/missing.png")
        errors.should contain("Player sprite frame_width must be positive")
        errors.should contain("Player sprite frame_height must be positive")
        errors.should contain("Player sprite columns must be positive")
        errors.should contain("Player sprite rows must be positive")
        errors.should contain("Player start position X cannot be negative")
        errors.should contain("Player start position Y cannot be negative")
      end
    end

    it "reports scene and dialog patterns that match no files" do
      with_temp_config_game do |temp_dir|
        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
          assets:
            scenes:
              - "scenes/*.yaml"
            dialogs:
              - "dialogs/**/*.yaml"
          start_scene: "intro"
        YAML
        )

        config = PointClickEngine::Core::GameConfig.from_yaml(File.read(config_path))
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_path)

        errors.should contain("Scene pattern 'scenes/*.yaml' matches no files")
        errors.should contain("No scene files found using provided patterns")
        errors.should contain("Dialog pattern 'dialogs/**/*.yaml' matches no files")
        errors.should contain("Start scene 'intro' not found in asset patterns")
      end
    end

    it "validates audio file existence and formats" do
      with_temp_config_game do |temp_dir|
        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
          assets:
            audio:
              music:
                theme: "audio/theme.mid"
              sounds:
                click: "sounds/click.aiff"
        YAML
        )

        config = PointClickEngine::Core::GameConfig.from_yaml(File.read(config_path))
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_path)

        errors.should contain("Unsupported audio format: theme.mid (.mid)")
        errors.should contain("Music file 'theme' not found at: audio/theme.mid")
        errors.should contain("Unsupported audio format: click.aiff (.aiff)")
        errors.should contain("Sound file 'click' not found at: sounds/click.aiff")
      end
    end

    it "validates display and settings ranges" do
      with_temp_config_game do |temp_dir|
        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
          display:
            scaling_mode: "BadMode"
            target_width: 0
            target_height: -1
          settings:
            master_volume: 2.0
            music_volume: -1.0
            sfx_volume: 1.5
        YAML
        )

        config = PointClickEngine::Core::GameConfig.from_yaml(File.read(config_path))
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_path)

        errors.should contain("Invalid scaling_mode 'BadMode'. Must be one of: FitWithBars, Stretch, PixelPerfect")
        errors.should contain("Display target_width must be positive")
        errors.should contain("Display target_height must be positive")
        errors.should contain("master_volume must be between 0.0 and 1.0 (got 2.0)")
        errors.should contain("music_volume must be between 0.0 and 1.0 (got -1.0)")
        errors.should contain("sfx_volume must be between 0.0 and 1.0 (got 1.5)")
      end
    end

    it "validates reserved initial state names and start music references" do
      with_temp_config_game do |temp_dir|
        config_path = write_temp_config(temp_dir, <<-YAML
          game:
            title: "Test Game"
          initial_state:
            flags:
              true: true
              "": false
            variables:
              nil: "bad"
              "": "also bad"
          assets:
            audio:
              music:
                title: "music/title.ogg"
          start_music: "missing_track"
        YAML
        )

        config = PointClickEngine::Core::GameConfig.from_yaml(File.read(config_path))
        errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_path)

        errors.should contain("Flag name 'true' is reserved and cannot be used")
        errors.should contain("Flag names cannot be empty")
        errors.should contain("Variable name 'nil' is reserved and cannot be used")
        errors.should contain("Variable names cannot be empty")
        errors.should contain("Start music 'missing_track' not defined in audio.music section")
      end
    end
  end
end
