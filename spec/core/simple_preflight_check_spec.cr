require "../spec_helper"
require "../../src/core/preflight_check"
require "../../src/core/game_config"

describe "Simple Preflight Validation Tests" do
  describe "Basic validation flow" do
    it "runs without crashing on minimal config" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 1024
        height: 768
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")
        result.should_not be_nil
        result.passed.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "detects missing config file" do
      result = PointClickEngine::Core::PreflightCheck.run("nonexistent.yaml")

      result.passed.should be_false
      result.errors.should_not be_empty
    end

    it "validates window resolution" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 100
        height: 100
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should have error about too small resolution
        error_found = result.errors.any? { |e| e.includes?("too small") }
        error_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "checks for missing start scene" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      start_scene: "missing_scene"
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should warn about missing start scene
        warning_found = result.warnings.any? { |w| w.includes?("Start scene") && w.includes?("not found") }
        warning_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "detects large resolutions" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 3840
        height: 2160
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        warning_found = result.warnings.any? { |w| w.includes?("larger than 1920x1080") }
        warning_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "validates audio file formats" do
      Dir.mkdir_p("test_dir")

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          music:
            theme: "music/theme.midi"
          sounds:
            click: "sounds/click.aiff"
      YAML

      File.write("test_dir/game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_dir/game.yaml")

        # Should have errors about unsupported formats
        format_errors = result.errors.select { |e| e.includes?("Unsupported audio format") }
        format_errors.size.should eq(2)
      ensure
        File.delete("test_dir/game.yaml") if File.exists?("test_dir/game.yaml")
        Dir.delete("test_dir") if Dir.exists?("test_dir")
      end
    end

    it "checks for conflicting features" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      features:
        - "shaders"
        - "low_end_mode"
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        warning_found = result.warnings.any? { |w| w.includes?("conflict") }
        warning_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "validates player configuration" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      player:
        sprite_path: "missing_sprite.png"
        sprite:
          frame_width: 32
          frame_height: 64
          columns: 8
          rows: 4
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should error about missing sprite
        error_found = result.errors.any? { |e| e.includes?("Player sprite not found") }
        error_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "detects security issues" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      secret_api_key: "12345"
      database_password: "admin"
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should detect sensitive data
        security_issues_found = result.security_issues.any? { |s| s.includes?("sensitive data") }
        security_issues_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "provides performance hints" do
      Dir.mkdir_p("test_assets")

      # Create a "large" asset
      File.write("test_assets/big_music.ogg", "x" * 15_000_000) # 15MB

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          music:
            theme: "test_assets/big_music.ogg"
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should have warnings about large assets
        large_asset_warning = result.warnings.any? { |w| w.includes?("Large assets") }
        large_asset_warning.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
        File.delete("test_assets/big_music.ogg") if File.exists?("test_assets/big_music.ogg")
        Dir.delete("test_assets") if Dir.exists?("test_assets")
      end
    end

    it "reports platform information" do
      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should have platform info
        platform_info = result.info.any? { |i| i.includes?("Running on") }
        platform_info.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
      end
    end

    it "validates scene references" do
      Dir.mkdir_p("scenes")

      # Create scene with broken reference
      scene_yaml = <<-YAML
      name: "test_scene"
      hotspots:
        - name: "exit"
          type: "exit"
          target_scene: "nonexistent_scene"
      YAML

      File.write("scenes/test_scene.yaml", scene_yaml)

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        scenes:
          - "scenes/*.yaml"
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should detect broken reference
        error_found = result.errors.any? { |e| e.includes?("references non-existent scene") }
        error_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
        File.delete("scenes/test_scene.yaml") if File.exists?("scenes/test_scene.yaml")
        Dir.delete("scenes") if Dir.exists?("scenes")
      end
    end

    it "counts resources" do
      Dir.mkdir_p("sprites")
      Dir.mkdir_p("backgrounds")

      # Create some test files
      3.times { |i| File.write("sprites/sprite_#{i}.png", "png") }
      2.times { |i| File.write("backgrounds/bg_#{i}.jpg", "jpg") }

      config_yaml = <<-YAML
      game:
        title: "Test Game"
      window:
        width: 1024
        height: 768
      assets:
        audio:
          sounds:
            click: "click.wav"
          music:
            theme: "theme.ogg"
      YAML

      File.write("test_game.yaml", config_yaml)

      begin
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should have resource summary
        summary_found = result.info.any? { |i| i.includes?("Resource summary") }
        summary_found.should be_true
      ensure
        File.delete("test_game.yaml") if File.exists?("test_game.yaml")
        3.times { |i| File.delete("sprites/sprite_#{i}.png") if File.exists?("sprites/sprite_#{i}.png") }
        2.times { |i| File.delete("backgrounds/bg_#{i}.jpg") if File.exists?("backgrounds/bg_#{i}.jpg") }

        # Clean up any remaining files in directories before deleting them
        if Dir.exists?("sprites")
          Dir.glob("sprites/*").each { |f| File.delete(f) if File.exists?(f) }
          Dir.delete("sprites")
        end

        if Dir.exists?("backgrounds")
          Dir.glob("backgrounds/*").each { |f| File.delete(f) if File.exists?(f) }
          Dir.delete("backgrounds")
        end
      end
    end
  end
end
