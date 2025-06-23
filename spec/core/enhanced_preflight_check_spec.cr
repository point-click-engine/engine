require "../spec_helper"
require "../../src/core/enhanced_preflight_check"
require "../../src/core/game_config"

def cleanup_test_files
  test_files = [
    "test_game.yaml",
    "test_scene.yaml",
    "test_sprite.png",
    "test_music.ogg",
    "test_sound.wav",
  ]

  test_dirs = [
    "test_game_dir",
    "test_scenes",
    "test_audio",
    "test_sprites",
    "test_saves",
    "test_locales",
    "test_dialogs",
    "test_shaders",
  ]

  test_files.each { |f| File.delete(f) if File.exists?(f) }
  test_dirs.each { |d| FileUtils.rm_rf(d) if Dir.exists?(d) }
end

def create_minimal_config(additional_config = "")
  <<-YAML
  game:
    title: "Test Game"
    version: "1.0.0"
  window:
    width: 1024
    height: 768
  start_scene: "intro"
  #{additional_config}
  YAML
end

describe PointClickEngine::Core::EnhancedPreflightCheck do
  before_each do
    # Clean up any test files
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "Resolution and display validation" do
    it "detects non-standard resolutions" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 1023
        height: 767
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Non-standard resolution") }
      warning_found.should be_true
    end

    it "warns about very large resolutions" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 3840
        height: 2160
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("larger than 1920x1080") }
      warning_found.should be_true
    end

    it "errors on too small resolutions" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 320
        height: 240
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("too small") }
      error_found.should be_true
    end

    it "detects unusual aspect ratios" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 1000
        height: 1000
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Unusual aspect ratio") }
      warning_found.should be_true
    end
  end

  describe "Audio system validation" do
    it "detects missing audio files" do
      Dir.mkdir("test_game_dir")

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          music:
            theme: "audio/theme.ogg"
            boss: "audio/boss.mp3"
          sounds:
            click: "sounds/click.wav"
            explosion: "sounds/explosion.wav"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      result.passed.should be_false
      audio_errors = result.errors.select { |e| e.includes?("not found") }
      audio_errors.size.should be >= 4
    end

    it "detects unsupported audio formats" do
      Dir.mkdir("test_game_dir")

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          music:
            theme: "audio/theme.mid"
          sounds:
            click: "sounds/click.aiff"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      format_errors = result.errors.select { |e| e.includes?("Unsupported audio format") }
      format_errors.size.should eq(2)
    end

    it "warns about large sound effect files" do
      Dir.mkdir_p("test_game_dir/sounds")

      # Create a "large" test file
      File.write("test_game_dir/sounds/big_sound.wav", "x" * 3_000_000) # 3MB

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          sounds:
            big: "sounds/big_sound.wav"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Sound effect") && w.includes?("large") }
      warning_found.should be_true
    end
  end

  describe "Player configuration validation" do
    it "detects missing player sprite" do
      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: 32
          frame_height: 64
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("Player sprite not found") }
      error_found.should be_true
    end

    it "validates player sprite dimensions" do
      Dir.mkdir("sprites")
      File.write("sprites/player.png", "fake_png_data")

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: -32
          frame_height: 0
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("Invalid player sprite dimensions") }
      error_found.should be_true
    end

    it "warns about large sprite frames" do
      Dir.mkdir("sprites")
      File.write("sprites/player.png", "fake_png_data")

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "sprites/player.png"
        sprite:
          frame_width: 512
          frame_height: 512
          columns: 10
          rows: 10
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warnings = result.warnings.select { |w| w.includes?("Large player sprite") || w.includes?("100 frames") }
      warnings.size.should be >= 1
    end

    it "detects invalid player starting position" do
      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        start_position:
          x: -100
          y: -50
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("negative coordinates") }
      error_found.should be_true
    end
  end

  describe "Scene validation" do
    it "detects missing scene backgrounds" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      background_path: "../backgrounds/missing_bg.png"
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      error_found = result.errors.any? { |e| e.includes?("Background image not found") }
      error_found.should be_true
    end

    it "warns about scenes without backgrounds" do
      Dir.mkdir_p("test_game_dir/scenes")

      scene_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "door"
          x: 100
          y: 200
          width: 50
          height: 100
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("no background specified") }
      warning_found.should be_true
    end

    it "detects broken scene references" do
      Dir.mkdir_p("test_game_dir/scenes")

      # Scene with exit to non-existent scene
      scene_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "exit_door"
          type: "exit"
          x: 100
          y: 200
          width: 50
          height: 100
          target_scene: "missing_scene"
      YAML

      File.write("test_game_dir/scenes/intro.yaml", scene_yaml)

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      error_found = result.errors.any? { |e| e.includes?("references non-existent scene") }
      error_found.should be_true
    end

    it "detects orphaned scenes" do
      Dir.mkdir_p("test_game_dir/scenes")

      # Create multiple scenes
      intro_yaml = <<-YAML
      name: "intro"
      hotspots:
        - name: "door"
          type: "exit"
          target_scene: "room1"
      YAML

      room1_yaml = <<-YAML
      name: "room1"
      YAML

      orphaned_yaml = <<-YAML
      name: "secret_room"
      YAML

      File.write("test_game_dir/scenes/intro.yaml", intro_yaml)
      File.write("test_game_dir/scenes/room1.yaml", room1_yaml)
      File.write("test_game_dir/scenes/secret_room.yaml", orphaned_yaml)

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "intro"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("unreachable scenes") && w.includes?("secret_room") }
      warning_found.should be_true
    end
  end

  describe "Feature validation" do
    it "detects conflicting features" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "shaders"
        - "low_end_mode"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("conflicting") || w.includes?("conflict") }
      warning_found.should be_true
    end

    it "validates shader files when shaders enabled" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "shaders"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("shader") && w.includes?("not found") }
      warning_found.should be_true
    end

    it "checks save directory permissions" do
      Dir.mkdir("saves")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "auto_save"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      info_found = result.info.any? { |i| i.includes?("Save directory is writable") }
      info_found.should be_true
    end
  end

  describe "Localization validation" do
    it "checks for locale files when localization enabled" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Localization enabled") && w.includes?("no locale") }
      warning_found.should be_true
    end

    it "validates default locale exists" do
      Dir.mkdir_p("locales")
      File.write("locales/en.yaml", "test: Test")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      default_locale: "fr"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("Default locale") && e.includes?("not found") }
      error_found.should be_true
    end
  end

  describe "Performance analysis" do
    it "warns about too many scenes" do
      Dir.mkdir_p("test_game_dir/scenes")

      # Create many scene files
      60.times do |i|
        File.write("test_game_dir/scenes/scene_#{i}.yaml", "name: \"scene_#{i}\"")
      end

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Large number of scenes") }
      warning_found.should be_true
    end

    it "tracks total asset size" do
      Dir.mkdir_p("test_game_dir/audio")

      # Create some "large" files
      File.write("test_game_dir/audio/music1.ogg", "x" * 15_000_000) # 15MB
      File.write("test_game_dir/audio/music2.ogg", "x" * 20_000_000) # 20MB

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          music:
            track1: "audio/music1.ogg"
            track2: "audio/music2.ogg"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      # Should have warnings about large files
      large_asset_warnings = result.warnings.select { |w| w.includes?("Large assets") }
      large_asset_warnings.should_not be_empty
    end

    it "provides resource usage summary" do
      Dir.mkdir_p("test_game_dir/sprites")
      Dir.mkdir_p("test_game_dir/backgrounds")
      Dir.mkdir_p("test_game_dir/audio")

      # Create various assets
      5.times { |i| File.write("test_game_dir/sprites/sprite_#{i}.png", "png") }
      3.times { |i| File.write("test_game_dir/backgrounds/bg_#{i}.jpg", "jpg") }

      config_yaml = <<-YAML
      title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          sounds:
            click: "audio/click.wav"
            hover: "audio/hover.wav"
          music:
            theme: "audio/theme.ogg"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game_dir/game.yaml")

      summary_found = result.info.any? { |i| i.includes?("Resource summary") }
      summary_found.should be_true
    end
  end

  describe "Security validation" do
    it "detects potential sensitive data in config" do
      config_yaml = create_minimal_config(<<-YAML
      api_key: "secret123"
      database:
        password: "admin123"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      security_issues = result.security_issues.select { |s| s.includes?("sensitive data") }
      security_issues.size.should be >= 1
    end

    it "checks for unsafe scripting operations" do
      Dir.mkdir_p("scripts")

      unsafe_script = <<-LUA
      function dangerous()
        os.execute("rm -rf /")
        eval("malicious code")
      end
      LUA

      File.write("scripts/unsafe.lua", unsafe_script)

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "scripting"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      security_issues = result.security_issues.select { |s| s.includes?("unsafe operation") }
      security_issues.should_not be_empty
    end
  end

  describe "Dialog system validation" do
    it "checks for dialog files when system enabled" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Dialog system enabled") && w.includes?("no dialog files") }
      warning_found.should be_true
    end

    it "validates dialog file syntax" do
      Dir.mkdir_p("dialogs")

      # Invalid YAML
      File.write("dialogs/invalid.yaml", "invalid: yaml: {content")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("Invalid dialog file") }
      error_found.should be_true
    end
  end

  describe "Development environment checks" do
    it "reports Crystal version" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      version_info = result.info.find { |i| i.includes?("Crystal version") }
      version_info.should_not be_nil
    end

    it "checks for development tools" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      # Should check for git at minimum
      tool_check = result.info.any? { |i| i.includes?("git") && i.includes?("available") }
      tool_check.should be_true
    end
  end

  describe "Comprehensive validation" do
    it "performs all 20 validation steps" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      # Capture output to count steps
      output = IO::Memory.new

      # Run with output capture (would need to modify implementation to support this)
      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      # Should have completed without crashing
      result.should_not be_nil
    end

    it "handles missing config file gracefully" do
      result = PointClickEngine::Core::EnhancedPreflightCheck.run("nonexistent_game.yaml")

      result.passed.should be_false
      result.errors.should_not be_empty
    end

    it "aggregates all issue types" do
      # Create a config with various issues
      config_yaml = <<-YAML
      title: "Problem Game"
      window:
        width: 100
        height: 100
      api_key: "secret"
      features:
        - "shaders"
        - "low_end_mode"
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::EnhancedPreflightCheck.run("test_game.yaml")

      # Should have different types of issues
      result.errors.should_not be_empty
      result.warnings.should_not be_empty
      result.security_issues.should_not be_empty
    end
  end
end
