require "../spec_helper"
require "yaml"

describe PointClickEngine::Core::PreflightCheck do
  describe "CheckResult" do
    it "initializes with default values" do
      result = PointClickEngine::Core::PreflightCheck::CheckResult.new
      result.passed.should be_true
      result.errors.should be_empty
      result.warnings.should be_empty
      result.info.should be_empty
    end
  end

  describe ".run" do
    it "returns success for valid configuration" do
      temp_dir = File.tempname("preflight_test")
      Dir.mkdir_p("#{temp_dir}/assets")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        # Create valid config
        config_yaml = <<-YAML
        game:
          title: "Test Game"
          version: "1.0.0"
        window:
          width: 1024
          height: 768
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create a valid scene
        scene_yaml = <<-YAML
        name: test_scene
        background_path: assets/bg.png
        YAML
        File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

        # Create the background asset
        File.write("#{temp_dir}/assets/bg.png", "fake png")

        # Capture output to avoid cluttering test output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          # Redirect stdout temporarily
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          result = PointClickEngine::Core::PreflightCheck.run(config_path)

          result.passed.should be_true
          result.errors.should be_empty
          result.info.should contain("✓ Configuration loaded successfully")
          result.info.should contain("✓ All assets validated")
          result.info.should contain("✓ 1 scene(s) validated")
        ensure
          # Restore stdout
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "fails on configuration errors" do
      temp_file = File.tempname("bad_config", ".yaml")
      File.write(temp_file, "invalid yaml content:")

      begin
        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          result = PointClickEngine::Core::PreflightCheck.run(temp_file)

          result.passed.should be_false
          result.errors.should_not be_empty
          result.errors.first.should contain("Configuration Error")
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "fails on validation errors" do
      temp_dir = File.tempname("validation_test")
      Dir.mkdir_p(temp_dir)

      begin
        # Config with validation errors
        config_yaml = <<-YAML
        game:
          title: ""
        window:
          width: -100
          height: 768
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          result = PointClickEngine::Core::PreflightCheck.run(config_path)

          result.passed.should be_false
          result.errors.should contain("Game title cannot be empty")
          result.errors.should contain("Window width must be positive (got -100)")
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "detects missing assets" do
      temp_dir = File.tempname("asset_test")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        player:
          sprite_path: "missing_player.png"
          sprite:
            frame_width: 32
            frame_height: 48
            columns: 4
            rows: 4
        assets:
          scenes: []
          audio:
            music:
              theme: "missing_theme.ogg"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          result = PointClickEngine::Core::PreflightCheck.run(config_path)

          result.passed.should be_false
          result.errors.any? { |e| e.includes?("Missing sprite: missing_player.png") }.should be_true
          result.errors.any? { |e| e.includes?("Missing music: missing_theme.ogg") }.should be_true
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "validates scene files" do
      temp_dir = File.tempname("scene_validation")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Create invalid scene
        scene_yaml = <<-YAML
        name: wrong_name
        YAML
        File.write("#{temp_dir}/scenes/test_scene.yaml", scene_yaml)

        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          result = PointClickEngine::Core::PreflightCheck.run(config_path)

          result.passed.should be_false
          result.errors.any? { |e| e.includes?("Scene 'test_scene.yaml':") }.should be_true
          result.errors.any? { |e| e.includes?("Missing required field 'background_path'") }.should be_true
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "generates warnings for common issues" do
      temp_dir = File.tempname("warning_test")
      Dir.mkdir_p(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        window:
          width: 4096
          height: 2160
        start_scene: "missing_scene"
        assets:
          scenes: []
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          result = PointClickEngine::Core::PreflightCheck.run(config_path)

          # Should pass but with warnings
          result.passed.should be_true
          result.warnings.should contain("Window size (4096x2160) is larger than 1920x1080 - may cause performance issues")
          result.warnings.should contain("Start scene 'missing_scene' not found in scene files")
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "checks performance considerations" do
      temp_dir = File.tempname("performance_test")
      Dir.mkdir_p("#{temp_dir}/music")
      Dir.mkdir_p("#{temp_dir}/scenes")

      begin
        # Create large music file (simulate)
        File.write("#{temp_dir}/music/theme.ogg", "x" * (15 * 1024 * 1024)) # 15MB

        # Create many scenes
        60.times do |i|
          scene_yaml = <<-YAML
          name: scene#{i}
          background_path: bg.png
          YAML
          File.write("#{temp_dir}/scenes/scene#{i}.yaml", scene_yaml)
        end

        config_yaml = <<-YAML
        game:
          title: "Test Game"
        assets:
          scenes:
            - "scenes/*.yaml"
          audio:
            music:
              theme: "music/theme.ogg"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          result = PointClickEngine::Core::PreflightCheck.run(config_path)

          result.warnings.any? { |w| w.includes?("Large assets detected") }.should be_true
          result.warnings.any? { |w| w.includes?("Music 'theme': 15.0 MB") }.should be_true
          result.warnings.should contain("Large number of scenes (60) may increase loading time")
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end

  describe ".run!" do
    it "raises on failure" do
      temp_file = File.tempname("bad_config", ".yaml")
      File.write(temp_file, "invalid yaml:")

      begin
        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          expect_raises(PointClickEngine::Core::ValidationError) do
            PointClickEngine::Core::PreflightCheck.run!(temp_file)
          end
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "succeeds without raising for valid config" do
      temp_dir = File.tempname("valid_config")
      Dir.mkdir_p(temp_dir)

      begin
        config_yaml = <<-YAML
        game:
          title: "Test Game"
        YAML

        config_path = "#{temp_dir}/config.yaml"
        File.write(config_path, config_yaml)

        # Suppress output
        original_stdout = STDOUT
        captured = IO::Memory.new

        begin
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(captured)
          {% end %}

          # Should not raise
          PointClickEngine::Core::PreflightCheck.run!(config_path)
        ensure
          {% if flag?(:darwin) || flag?(:linux) %}
            STDOUT.reopen(original_stdout)
          {% end %}
        end
      ensure
        FileUtils.rm_rf(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end
end
