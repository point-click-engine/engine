require "../../spec_helper"
require "../../../src/core/validators/config_validator"
require "../../../src/core/game_config"

def create_temp_config_file(content : String, filename = "test_config.yaml")
  File.write(filename, content)
  filename
end

def cleanup_temp_files(files : Array(String))
  files.each { |f| File.delete(f) if File.exists?(f) }
end

describe PointClickEngine::Core::Validators::ConfigValidator do
  after_each do
    cleanup_temp_files([
      "test_config.yaml",
      "valid_config.yaml",
      "invalid_config.yaml",
      "minimal_config.yaml",
    ])
  end

  describe "YAML parsing validation" do
    it "validates syntactically correct YAML" do
      config_content = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_content)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      errors.should be_empty
    end

    it "detects YAML syntax errors" do
      invalid_yaml = <<-YAML
      game:
        title: "Test Game"
        version: 1.0.0
      window:
        width: 800
        height: 600
        invalid: [unclosed array
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(invalid_yaml)

      expect_raises(YAML::ParseException) do
        PointClickEngine::Core::GameConfig.from_file(config_file)
      end
    end

    it "handles missing configuration file" do
      nonexistent_file = "nonexistent_config.yaml"

      expect_raises(File::NotFoundError) do
        PointClickEngine::Core::GameConfig.from_file(nonexistent_file)
      end
    end

    it "validates required configuration sections" do
      minimal_config = <<-YAML
      game:
        title: "Test"
      YAML

      config_file = create_temp_config_file(minimal_config)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should have warnings about missing sections
      errors.any? { |e| e.includes?("window") }.should be_true
    end
  end

  describe "game configuration validation" do
    it "validates game title is present" do
      config_without_title = <<-YAML
      game:
        version: "1.0.0"
      window:
        width: 800
        height: 600
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_without_title)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      errors.any? { |e| e.includes?("title") }.should be_true
    end

    it "validates version format" do
      config_with_invalid_version = <<-YAML
      game:
        title: "Test Game"
        version: "invalid.version.format.too.long"
      window:
        width: 800
        height: 600
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_invalid_version)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should validate semantic versioning format
      errors.any? { |e| e.includes?("version") }.should be_true
    end

    it "validates start scene is specified" do
      config_without_start_scene = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      YAML

      config_file = create_temp_config_file(config_without_start_scene)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      errors.any? { |e| e.includes?("start_scene") }.should be_true
    end
  end

  describe "window configuration validation" do
    it "validates positive window dimensions" do
      config_with_invalid_dimensions = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: -800
        height: 0
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_invalid_dimensions)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      errors.any? { |e| e.includes?("width") }.should be_true
      errors.any? { |e| e.includes?("height") }.should be_true
    end

    it "validates reasonable window dimensions" do
      config_with_extreme_dimensions = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 100000
        height: 100000
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_extreme_dimensions)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should warn about extremely large dimensions
      errors.any? { |e| e.includes?("dimensions") || e.includes?("large") }.should be_true
    end

    it "validates aspect ratio considerations" do
      config_with_unusual_aspect = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 1000
        height: 100
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_unusual_aspect)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should warn about unusual aspect ratios
      errors.any? { |e| e.includes?("aspect") || e.includes?("ratio") }.should be_true
    end

    it "validates fullscreen configuration" do
      config_with_fullscreen = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
        fullscreen: true
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_fullscreen)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should handle fullscreen configuration appropriately
      errors.should be_empty
    end
  end

  describe "feature configuration validation" do
    it "validates known feature flags" do
      config_with_features = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      features:
        - verbs
        - floating_dialogs
        - unknown_feature
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_features)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should warn about unknown features
      errors.any? { |e| e.includes?("unknown_feature") }.should be_true
    end

    it "validates feature compatibility" do
      config_with_conflicting_features = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      features:
        - classic_interface
        - modern_interface
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_conflicting_features)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should detect conflicting features
      errors.any? { |e| e.includes?("conflict") || e.includes?("incompatible") }.should be_true
    end
  end

  describe "asset pattern validation" do
    it "validates asset pattern syntax" do
      config_with_asset_patterns = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["scenes/*.yaml"]
        dialogs: ["dialogs/**/*.yaml"]
        items: ["items/[invalid-glob"]
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_asset_patterns)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should detect invalid glob patterns
      errors.any? { |e| e.includes?("invalid") || e.includes?("pattern") }.should be_true
    end

    it "warns about asset patterns that match no files" do
      config_with_nonmatching_patterns = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["nonexistent_directory/*.yaml"]
        dialogs: ["another_missing_dir/**/*.yaml"]
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_nonmatching_patterns)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should warn about patterns that match no files
      errors.any? { |e| e.includes?("matches no files") }.should be_true
    end
  end

  describe "player configuration validation" do
    it "validates player sprite configuration" do
      config_with_player = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      player:
        name: "Hero"
        sprite_path: "assets/player.png"
        sprite:
          frame_width: -32
          frame_height: 0
          columns: 0
          rows: -1
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_player)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should validate sprite dimensions and grid
      errors.any? { |e| e.includes?("frame_width") || e.includes?("negative") }.should be_true
      errors.any? { |e| e.includes?("columns") || e.includes?("rows") }.should be_true
    end

    it "validates player starting position" do
      config_with_invalid_position = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      player:
        name: "Hero"
        start_x: -100
        start_y: 10000
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_invalid_position)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should warn about unusual starting positions
      errors.any? { |e| e.includes?("position") || e.includes?("coordinates") }.should be_true
    end
  end

  describe "localization configuration validation" do
    it "validates locale configuration" do
      config_with_locales = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      localization:
        default_locale: "invalid_locale_code"
        locales:
          - "en"
          - "invalid-format"
          - "toolonglocale"
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_locales)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should validate locale code format
      errors.any? { |e| e.includes?("locale") }.should be_true
    end
  end

  describe "performance configuration validation" do
    it "validates performance settings" do
      config_with_performance = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      performance:
        target_fps: -60
        max_memory_mb: 0
        cache_size_mb: -100
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_performance)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should validate performance settings are reasonable
      errors.any? { |e| e.includes?("fps") || e.includes?("negative") }.should be_true
      errors.any? { |e| e.includes?("memory") }.should be_true
    end

    it "warns about unrealistic performance settings" do
      config_with_extreme_performance = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      performance:
        target_fps: 1000
        max_memory_mb: 100000
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_extreme_performance)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should warn about unrealistic values
      errors.any? { |e| e.includes?("high") || e.includes?("unrealistic") }.should be_true
    end
  end

  describe "cross-reference validation" do
    it "validates start scene exists in assets" do
      config_with_missing_start_scene = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      assets:
        scenes: ["scenes/intro.yaml", "scenes/level1.yaml"]
      start_scene: "nonexistent_scene"
      YAML

      config_file = create_temp_config_file(config_with_missing_start_scene)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should detect that start scene is not in available scenes
      errors.any? { |e| e.includes?("start_scene") && e.includes?("not found") }.should be_true
    end

    it "validates referenced assets exist" do
      config_with_asset_references = <<-YAML
      game:
        title: "Test Game"
        version: "1.0.0"
      window:
        width: 800
        height: 600
      player:
        sprite_path: "nonexistent/player.png"
      audio:
        background_music: "missing/music.ogg"
      start_scene: "intro"
      YAML

      config_file = create_temp_config_file(config_with_asset_references)
      config = PointClickEngine::Core::GameConfig.from_file(config_file)

      errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, config_file)

      # Should warn about missing referenced files
      errors.any? { |e| e.includes?("not found") || e.includes?("missing") }.should be_true
    end
  end
end
