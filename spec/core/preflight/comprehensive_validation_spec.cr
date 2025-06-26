require "./spec_helper"

describe "PreflightCheck Comprehensive Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "full validation run" do
    it "performs all validation steps" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      # Run full validation
      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should have completed without crashing
      result.should_not be_nil

      # Should have some info messages from various validators
      result.info.should_not be_empty
    end

    it "handles missing config file gracefully" do
      result = PointClickEngine::Core::PreflightCheck.run("nonexistent_game.yaml")

      result.passed.should be_false
      result.errors.should_not be_empty

      # Should have specific error about missing file
      file_errors = result.errors.select { |e|
        e.includes?("not found") || e.includes?("does not exist") || e.includes?("missing")
      }
      file_errors.should_not be_empty
    end

    it "handles invalid YAML gracefully" do
      File.write("invalid.yaml", "invalid: yaml: content: {")

      result = PointClickEngine::Core::PreflightCheck.run("invalid.yaml")

      result.passed.should be_false
      result.errors.should_not be_empty

      # Should have YAML parsing error
      yaml_errors = result.errors.select { |e|
        e.includes?("YAML") || e.includes?("parse") || e.includes?("syntax")
      }
      yaml_errors.should_not be_empty
    end
  end

  describe "issue aggregation" do
    it "aggregates all issue types" do
      # Create a config with various issues
      config_yaml = <<-YAML
      game:
        title: "Problem Game"
      window:
        width: 0  # Invalid width
        height: -100  # Invalid height
      player:
        sprite_path: "missing.png"  # Missing file
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should have errors for invalid window size and missing sprite
      result.errors.should_not be_empty
      result.errors.size.should be >= 3 # width, height, and sprite errors
    end

    it "provides summary of all issues" do
      Dir.mkdir_p("test_scenes")

      # Config with multiple issues
      config_yaml = <<-YAML
      game:
        title: ""  # Empty title
      window:
        width: 1023  # Non-standard
        height: 767
      player:
        sprite_path: "missing_sprite.png"  # Missing file
      features:
        - "unknown_feature"  # Unknown feature
      api_secret: "hardcoded123"  # Security issue
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should fail validation
      result.passed.should be_false

      # Should have multiple issue types
      result.errors.size.should be > 0
      result.warnings.size.should be > 0
      # Note: security_issues is not available in regular PreflightCheck
    end
  end

  describe "validation completeness" do
    it "validates all major subsystems" do
      create_test_directory_structure

      # Comprehensive config touching all subsystems
      config_yaml = <<-YAML
      game:
        title: "Complete Game"
        version: "1.0.0"
      window:
        width: 1920
        height: 1080
        fullscreen: false
      player:
        name: "Hero"
        sprite_path: "test_sprites/player.png"
      assets:
        scenes:
          - "test_scenes/*.yaml"
        audio:
          music:
            theme: "test_audio/theme.ogg"
      features:
        - "auto_save"
        - "achievements"
        - "localization"
      start_scene: "intro"
      YAML

      File.write("test_game.yaml", config_yaml)

      # Create minimal required files
      File.write("test_sprites/player.png", "fake_png")
      File.write("test_audio/theme.ogg", "fake_ogg")
      File.write("test_scenes/intro.yaml", create_test_scene("intro"))

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should validate multiple subsystems
      validated_subsystems = result.info.select { |i|
        i.includes?("✓") || i.includes?("validated") || i.includes?("checked")
      }
      validated_subsystems.size.should be >= 3 # At least config, assets, and scenes
    end
  end

  describe "error recovery" do
    it "continues validation after encountering errors" do
      config_yaml = <<-YAML
      game:
        title: ""  # Error: empty title
      window:
        width: -100  # Error: negative width
        height: 768
      player:
        sprite_path: "missing.png"  # Error: missing file
      assets:
        scenes:
          - "scenes/*.yaml"  # Will try to validate even after errors
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should have multiple errors (not just the first one)
      result.errors.size.should be >= 3

      # Should still provide info about what was checked
      result.info.should_not be_empty
    end

    it "handles partial configuration gracefully" do
      # Minimal config missing many sections
      config_yaml = <<-YAML
      game:
        title: "Minimal Game"
      YAML

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should handle missing sections without crashing
      result.should_not be_nil

      # Should handle missing sections gracefully
      # The preflight check should either pass with warnings or fail with errors
      if result.passed
        # If it passed, it should have warnings about missing sections
        result.warnings.should_not be_empty
      else
        # If it failed, it should have errors about critical missing sections
        result.errors.should_not be_empty
      end
    end
  end
end
