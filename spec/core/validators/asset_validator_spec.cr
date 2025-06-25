require "../../spec_helper"
require "yaml"

describe PointClickEngine::Core::Validators::AssetValidator do
  describe "AssetCheck" do
    it "creates an asset check" do
      check = PointClickEngine::Core::Validators::AssetValidator::AssetCheck.new("sprites/player.png", "sprite", true)
      check.path.should eq("sprites/player.png")
      check.type.should eq("sprite")
      check.required.should be_true
      check.exists.should be_false
      check.error.should be_nil
    end
  end

  describe ".validate_all_assets" do
    it "validates assets from a simple config" do
      # Create temporary test structure
      temp_dir = File.tempname("asset_test")
      Dir.mkdir_p("#{temp_dir}/assets/sprites")
      Dir.mkdir_p("#{temp_dir}/assets/audio")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        # Create test files
        File.write("#{temp_dir}/assets/sprites/player.png", "fake png data")
        File.write("#{temp_dir}/assets/audio/theme.ogg", "fake ogg data")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          sprite_path: "assets/sprites/player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
        assets:
          scenes: []
          audio:
            music:
              theme: "assets/audio/theme.ogg"
            sounds:
              missing_sound: "assets/audio/missing.wav"
        YAML

        config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "#{temp_dir}/config.yaml")

        errors.includes?("Missing sound: assets/audio/missing.wav").should be_true
        errors.size.should eq(1)
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects missing player sprite" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      player:
        sprite_path: "sprites/missing_player.png"
        sprite:
          frame_width: 32
          frame_height: 48
          columns: 4
          rows: 4
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "/fake/path/config.yaml")

      errors.includes?("Missing sprite: sprites/missing_player.png").should be_true
    end

    it "validates asset formats" do
      temp_dir = File.tempname("asset_format_test")
      Dir.mkdir_p("#{temp_dir}/assets")

      begin
        # Create files with wrong extensions
        File.write("#{temp_dir}/assets/background.txt", "not an image")
        File.write("#{temp_dir}/assets/music.exe", "not audio")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
          audio:
            music:
              theme: "assets/music.exe"
        YAML

        # Create a fake scene that references the bad image
        Dir.mkdir("#{temp_dir}/scenes")
        scene_yaml = <<-YAML
        name: test_scene
        background: assets/background.txt
        YAML
        File.write("#{temp_dir}/scenes/test.yaml", scene_yaml)

        config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "#{temp_dir}/config.yaml")

        errors.any? { |e| e.includes?("Unsupported image format") && e.includes?(".txt") }.should be_true
        errors.any? { |e| e.includes?("Unsupported music format") && e.includes?(".exe") }.should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "checks multiple asset locations" do
      temp_dir = File.tempname("asset_location_test")
      Dir.mkdir_p("#{temp_dir}/assets")
      Dir.mkdir_p("#{temp_dir}/data")
      Dir.mkdir_p("#{temp_dir}/resources")

      begin
        # Place asset in data directory
        File.write("#{temp_dir}/data/sprite.png", "fake png")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          sprite_path: "sprite.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
        YAML

        config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "#{temp_dir}/config.yaml")

        # Should find the sprite in data directory
        errors.should be_empty
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects empty asset files" do
      temp_dir = File.tempname("empty_asset_test")
      Dir.mkdir_p("#{temp_dir}/assets")

      begin
        # Create empty file
        File.touch("#{temp_dir}/assets/empty.png")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          sprite_path: "assets/empty.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
        YAML

        config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "#{temp_dir}/config.yaml")

        errors.any? { |e| e.includes?("file is empty") }.should be_true
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "extracts and validates scene assets" do
      temp_dir = File.tempname("scene_asset_test")
      Dir.mkdir_p("#{temp_dir}/scenes")
      Dir.mkdir_p("#{temp_dir}/assets")

      begin
        # Create scene with various asset references
        scene_yaml = <<-YAML
        name: test_scene
        background: assets/bg.png
        hotspots:
          - name: door
            sprite: assets/door.png
            cursor: assets/cursor.png
        characters:
          - name: npc
            portrait: assets/npc_portrait.png
            sound: assets/voice.wav
        YAML
        File.write("#{temp_dir}/scenes/test.yaml", scene_yaml)

        # Only create some of the referenced assets
        File.write("#{temp_dir}/assets/bg.png", "fake bg")
        File.write("#{temp_dir}/assets/door.png", "fake door")

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
        errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "#{temp_dir}/config.yaml")

        # Should report missing optional assets (cursor, portrait, sound are optional)
        # But background is required
        errors.should be_empty # All extracted assets except background are optional
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "validates all audio asset types" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      assets:
        audio:
          music:
            intro: "music/intro.mp3"
            menu: "music/menu.ogg"
            game: "music/game.wav"
            boss: "music/boss.flac"
            wrong: "music/wrong.mid"
          sounds:
            click: "sfx/click.wav"
            boom: "sfx/boom.ogg"
            ding: "sfx/ding.mp3"
            swoosh: "sfx/swoosh.flac"
            bad: "sfx/bad.aiff"
      YAML

      config = PointClickEngine::Core::GameConfig.from_yaml(config_yaml)
      errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "/fake/config.yaml")

      # All files are missing
      errors.select { |e| e.starts_with?("Missing music:") }.size.should eq(5)
      errors.select { |e| e.starts_with?("Missing sound:") }.size.should eq(5)
    end
  end
end
