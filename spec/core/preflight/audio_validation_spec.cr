require "./spec_helper"

describe "PreflightCheck Audio System Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "audio file validation" do
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

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      result.passed.should be_false
      audio_errors = result.errors.select { |e| e.includes?("not found") }
      audio_errors.size.should be >= 4
    end

    it "validates existing audio files" do
      Dir.mkdir_p("test_game_dir/audio")
      Dir.mkdir_p("test_game_dir/sounds")

      # Create fake audio files
      File.write("test_game_dir/audio/theme.ogg", "fake_ogg_data")
      File.write("test_game_dir/sounds/click.wav", "fake_wav_data")

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
          sounds:
            click: "sounds/click.wav"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should not have errors for existing files
      audio_errors = result.errors.select { |e| e.includes?("theme.ogg") || e.includes?("click.wav") }
      audio_errors.should be_empty
    end
  end

  describe "audio format validation" do
    it "detects unsupported audio formats" do
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
            theme: "audio/theme.mid"
          sounds:
            click: "sounds/click.aiff"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      format_errors = result.errors.select { |e| e.includes?("Unsupported audio format") }
      format_errors.size.should eq(2)
    end

    it "accepts supported audio formats" do
      Dir.mkdir_p("test_game_dir/audio")
      Dir.mkdir_p("test_game_dir/sounds")

      # Create files with supported formats
      File.write("test_game_dir/audio/theme.ogg", "fake_data")
      File.write("test_game_dir/audio/ambient.mp3", "fake_data")
      File.write("test_game_dir/sounds/click.wav", "fake_data")

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
            ambient: "audio/ambient.mp3"
          sounds:
            click: "sounds/click.wav"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should not have format errors for supported formats
      format_errors = result.errors.select { |e| e.includes?("Unsupported audio format") }
      format_errors.should be_empty
    end
  end

  describe "audio file size validation" do
    it "warns about large sound effect files" do
      Dir.mkdir_p("test_game_dir/sounds")

      # Create a "large" test file
      File.write("test_game_dir/sounds/big_sound.wav", "x" * 6_000_000) # 6MB

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes: ["*.yaml"]
        audio:
          sounds:
            big: "sounds/big_sound.wav"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      hint_found = result.performance_hints.any? { |h| h.includes?("Sound effect") && h.includes?("large") }
      hint_found.should be_true
    end

    it "accepts reasonable sound effect sizes" do
      Dir.mkdir_p("test_game_dir/sounds")

      # Create a reasonable size file
      File.write("test_game_dir/sounds/normal_sound.wav", "x" * 500_000) # 500KB

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          sounds:
            normal: "sounds/normal_sound.wav"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should not warn about reasonable sizes
      size_warnings = result.warnings.select { |w| w.includes?("normal_sound.wav") && w.includes?("large") }
      size_warnings.should be_empty
    end

    it "accepts large music files" do
      Dir.mkdir_p("test_game_dir/music")

      # Create a large music file (music files are expected to be larger)
      File.write("test_game_dir/music/theme.ogg", "x" * 10_000_000) # 10MB

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          music:
            theme: "music/theme.ogg"
      YAML

      File.write("test_game_dir/game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/game.yaml")

      # Should not error on large music files (might warn though)
      music_errors = result.errors.select { |e| e.includes?("theme.ogg") && e.includes?("large") }
      music_errors.should be_empty
    end
  end

  describe "user settings validation" do
    it "validates volume settings in user settings file" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      YAML

      user_settings_yaml = <<-YAML
      audio:
        master_volume: 150.0
        music_volume: -10.0
        sfx_volume: 80.0
      YAML

      File.write("test_game.yaml", config_yaml)
      File.write("user_settings.yaml", user_settings_yaml)

      user_settings = PointClickEngine::Core::UserSettings.load("user_settings.yaml")
      validation_errors = user_settings.validate

      # Should error about invalid volume levels
      validation_errors.should_not be_empty
      volume_errors = validation_errors.select { |e| e.includes?("volume") }
      volume_errors.should_not be_empty
    end

    it "accepts valid volume settings in user settings file" do
      user_settings_yaml = <<-YAML
      audio:
        master_volume: 100.0
        music_volume: 80.0
        sfx_volume: 90.0
      YAML

      File.write("user_settings.yaml", user_settings_yaml)

      user_settings = PointClickEngine::Core::UserSettings.load("user_settings.yaml")
      validation_errors = user_settings.validate

      # Should not error about valid volume levels
      validation_errors.should be_empty
    end
  end
end
