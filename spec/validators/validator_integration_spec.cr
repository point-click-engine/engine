require "../spec_helper"
require "../../src/core/validators/config_validator"
require "../../src/core/validators/asset_validator"
require "../../src/core/validators/scene_validator"
require "../../src/core/preflight_check"

describe "Validator Integration Tests" do
  describe "ConfigValidator error handling" do
    it "handles missing required fields gracefully" do
      # Create invalid config content with proper structure
      invalid_yaml = <<-YAML
        title: "Test Game"
        # Missing required version and other fields
        YAML

      File.write("temp_invalid_config.yaml", invalid_yaml)

      begin
        result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::ConfigError,
          "Validating invalid config"
        ) do
          config = PointClickEngine::Core::GameConfig.from_file("temp_invalid_config.yaml")
          errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "temp_invalid_config.yaml")
          raise "Config validation failed" unless errors.empty?
          config
        end

        result.failure?.should be_true
        result.error.should be_a(PointClickEngine::Core::ConfigError)
      ensure
        File.delete("temp_invalid_config.yaml") if File.exists?("temp_invalid_config.yaml")
      end
    end

    it "validates config field types correctly" do
      # Create config with wrong types
      invalid_types_yaml = <<-YAML
        game:
          name: "Test Game"
          version: "1.0.0"
        window:
          width: "not_a_number"
          height: 600
          fullscreen: "not_a_boolean"
        YAML

      File.write("temp_invalid_types.yaml", invalid_types_yaml)

      begin
        result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::ConfigError,
          "Validating config with wrong types"
        ) do
          config = PointClickEngine::Core::GameConfig.from_file("temp_invalid_types.yaml")
          errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "temp_invalid_types.yaml")
          raise "Config validation failed" unless errors.empty?
          config
        end

        result.failure?.should be_true
      ensure
        File.delete("temp_invalid_types.yaml") if File.exists?("temp_invalid_types.yaml")
      end
    end

    it "validates window resolution ranges" do
      # Create config with invalid resolution
      invalid_resolution_yaml = <<-YAML
        game:
          name: "Test Game"
          version: "1.0.0"
        window:
          width: -100
          height: 1000000
          fullscreen: false
        YAML

      File.write("temp_invalid_resolution.yaml", invalid_resolution_yaml)

      begin
        result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::ConfigError,
          "Validating invalid resolution"
        ) do
          config = PointClickEngine::Core::GameConfig.from_file("temp_invalid_resolution.yaml")
          errors = PointClickEngine::Core::Validators::ConfigValidator.validate(config, "temp_invalid_resolution.yaml")
          raise "Config validation failed" unless errors.empty?
          config
        end

        result.failure?.should be_true
      ensure
        File.delete("temp_invalid_resolution.yaml") if File.exists?("temp_invalid_resolution.yaml")
      end
    end
  end

  describe "AssetValidator error recovery" do
    it "handles missing asset directories" do
      # Create minimal valid config
      test_config_yaml = <<-YAML
        game:
          name: "Test Game"
          version: "1.0.0"
        window:
          width: 1024
          height: 768
        assets:
          scenes:
            - "nonexistent_scenes/*.yaml"
          audio:
            music:
              theme: "nonexistent_music/theme.ogg"
            sounds:
              click: "nonexistent_sounds/click.wav"
        YAML

      File.write("temp_test_config.yaml", test_config_yaml)

      begin
        config = PointClickEngine::Core::GameConfig.from_file("temp_test_config.yaml")

        # Validate assets and expect errors but no crashes
        asset_errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "temp_test_config.yaml")

        # Should have errors for missing assets
        asset_errors.should_not be_empty

        # But should not crash the validation process
        asset_errors.each do |error|
          error.should be_a(String)
          error.should_not be_empty
        end
      ensure
        File.delete("temp_test_config.yaml") if File.exists?("temp_test_config.yaml")
      end
    end

    it "continues validation after encountering corrupt files" do
      # Create test directories and files
      Dir.mkdir_p("temp_asset_test/scenes")
      Dir.mkdir_p("temp_asset_test/audio")

      # Create a valid scene file
      valid_scene = <<-YAML
        name: "test_scene"
        background_path: "../backgrounds/test_bg.png"
        hotspots:
          - name: "test_hotspot"
            x: 100
            y: 200
            width: 50
            height: 75
        YAML

      File.write("temp_asset_test/scenes/valid_scene.yaml", valid_scene)

      # Create a corrupt scene file
      File.write("temp_asset_test/scenes/corrupt_scene.yaml", "invalid: yaml: content: {")

      # Create config referencing these scenes
      test_config_yaml = <<-YAML
        game:
          name: "Test Game"
          version: "1.0.0"
        window:
          width: 1024
          height: 768
        assets:
          scenes:
            - "temp_asset_test/scenes/*.yaml"
        YAML

      File.write("temp_asset_config.yaml", test_config_yaml)

      begin
        config = PointClickEngine::Core::GameConfig.from_file("temp_asset_config.yaml")
        asset_errors = PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config, "temp_asset_config.yaml")

        # Should have some errors but continue processing
        asset_errors.size.should be > 0

        # Should mention the corrupt file
        corrupt_error_found = asset_errors.any? { |e| e.includes?("corrupt_scene") }
        corrupt_error_found.should be_true
      ensure
        # Cleanup
        File.delete("temp_asset_test/scenes/valid_scene.yaml") if File.exists?("temp_asset_test/scenes/valid_scene.yaml")
        File.delete("temp_asset_test/scenes/corrupt_scene.yaml") if File.exists?("temp_asset_test/scenes/corrupt_scene.yaml")
        Dir.delete("temp_asset_test/scenes") if Dir.exists?("temp_asset_test/scenes")
        Dir.delete("temp_asset_test/audio") if Dir.exists?("temp_asset_test/audio")
        Dir.delete("temp_asset_test") if Dir.exists?("temp_asset_test")
        File.delete("temp_asset_config.yaml") if File.exists?("temp_asset_config.yaml")
      end
    end
  end

  describe "SceneValidator edge cases" do
    it "handles malformed YAML gracefully" do
      # Create malformed scene file
      malformed_yaml = <<-YAML
        name: "test_scene"
        hotspots:
          - name: "hotspot1"
            x: 100
            y: [unclosed array
        YAML

      File.write("temp_malformed_scene.yaml", malformed_yaml)

      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file("temp_malformed_scene.yaml")

        # Should capture YAML parsing errors
        errors.should_not be_empty
        yaml_error_found = errors.any? { |e| e.downcase.includes?("yaml") || e.downcase.includes?("parse") }
        yaml_error_found.should be_true
      ensure
        File.delete("temp_malformed_scene.yaml") if File.exists?("temp_malformed_scene.yaml")
      end
    end

    it "validates hotspot coordinate boundaries" do
      # Create scene with out-of-bounds hotspots
      out_of_bounds_scene = <<-YAML
        name: "boundary_test_scene"
        hotspots:
          - name: "negative_hotspot"
            x: -100
            y: -50
            width: 200
            height: 100
          - name: "huge_hotspot"
            x: 1000
            y: 1000
            width: 999999
            height: 999999
        YAML

      File.write("temp_boundary_scene.yaml", out_of_bounds_scene)

      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file("temp_boundary_scene.yaml")

        # Should detect boundary issues
        errors.should_not be_empty
        boundary_error_found = errors.any? { |e| e.downcase.includes?("coordinate") || e.downcase.includes?("bound") }
        boundary_error_found.should be_true
      ensure
        File.delete("temp_boundary_scene.yaml") if File.exists?("temp_boundary_scene.yaml")
      end
    end

    it "validates character positioning and scaling" do
      # Create scene with problematic character setup
      problematic_characters_scene = <<-YAML
        name: "character_test_scene"
        characters:
          - name: "invisible_character"
            position:
              x: 0
              y: 0
            scale: 0
          - name: "giant_character"
            position:
              x: 500
              y: 300
            scale: 100.0
        YAML

      File.write("temp_character_scene.yaml", problematic_characters_scene)

      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file("temp_character_scene.yaml")

        # Should detect character issues
        scale_warnings = errors.any? { |e| e.downcase.includes?("scale") }
        scale_warnings.should be_true
      ensure
        File.delete("temp_character_scene.yaml") if File.exists?("temp_character_scene.yaml")
      end
    end
  end

  describe "PreflightCheck integration" do
    it "performs comprehensive validation workflow" do
      # Create a complete test game structure
      Dir.mkdir_p("temp_game_test/scenes")
      Dir.mkdir_p("temp_game_test/backgrounds")
      Dir.mkdir_p("temp_game_test/audio/music")
      Dir.mkdir_p("temp_game_test/audio/sounds")
      Dir.mkdir_p("temp_game_test/sprites")

      # Create valid game config
      game_config = <<-YAML
        game:
          name: "Test Adventure Game"
          version: "1.0.0"
        window:
          width: 1024
          height: 768
          fullscreen: false
        player:
          sprite_path: "sprites/player.png"
          sprite:
            frame_width: 32
            frame_height: 64
          start_position:
            x: 400
            y: 300
        start_scene: "intro"
        assets:
          scenes:
            - "scenes/*.yaml"
          audio:
            music:
              theme: "audio/music/theme.ogg"
            sounds:
              click: "audio/sounds/click.wav"
        features:
          - "auto_save"
          - "shaders"
        YAML

      File.write("temp_game_test/game.yaml", game_config)

      # Create test scene
      intro_scene = <<-YAML
        name: "intro"
        background_path: "../backgrounds/intro_bg.png"
        hotspots:
          - name: "start_button"
            x: 400
            y: 500
            width: 200
            height: 50
            default_verb: "use"
        walkable_areas:
          regions:
            - name: "main_area"
              walkable: true
              vertices:
                - {x: 100, y: 350}
                - {x: 900, y: 350}
                - {x: 900, y: 700}
                - {x: 100, y: 700}
        YAML

      File.write("temp_game_test/scenes/intro.yaml", intro_scene)

      # Create placeholder assets
      File.write("temp_game_test/backgrounds/intro_bg.png", "fake_png_data")
      File.write("temp_game_test/sprites/player.png", "fake_png_data")
      File.write("temp_game_test/audio/music/theme.ogg", "fake_audio_data")
      File.write("temp_game_test/audio/sounds/click.wav", "fake_audio_data")

      begin
        # Run preflight check
        result = PointClickEngine::Core::PreflightCheck.run("temp_game_test/game.yaml")

        # Should complete without crashing
        result.should_not be_nil

        # Check that it found our test scene
        scene_info_found = result.info.any? { |info| info.includes?("scene") && info.includes?("validated") }
        scene_info_found.should be_true

        # Should have some warnings about fake assets but not crash
        result.warnings.should_not be_empty
      rescue ex
        # Even if preflight check fails, it should be a controlled failure, not a crash
        ex.should be_a(PointClickEngine::Core::ValidationError)
      ensure
        # Cleanup test directory
        ["temp_game_test/scenes/intro.yaml",
         "temp_game_test/backgrounds/intro_bg.png",
         "temp_game_test/sprites/player.png",
         "temp_game_test/audio/music/theme.ogg",
         "temp_game_test/audio/sounds/click.wav",
         "temp_game_test/game.yaml"].each do |file|
          File.delete(file) if File.exists?(file)
        end

        ["temp_game_test/scenes",
         "temp_game_test/backgrounds",
         "temp_game_test/audio/music",
         "temp_game_test/audio/sounds",
         "temp_game_test/sprites",
         "temp_game_test/audio",
         "temp_game_test"].each do |dir|
          Dir.delete(dir) if Dir.exists?(dir)
        end
      end
    end

    it "handles graceful degradation on partial failures" do
      # Create config with some valid and some invalid elements
      mixed_config = <<-YAML
        game:
          name: "Mixed Test Game"
          version: "1.0.0"
        window:
          width: 1024
          height: 768
        player:
          sprite_path: "nonexistent/player.png"
          sprite:
            frame_width: 32
            frame_height: 64
        start_scene: "nonexistent_scene"
        assets:
          scenes:
            - "nonexistent_scenes/*.yaml"
        YAML

      File.write("temp_mixed_config.yaml", mixed_config)

      begin
        # Should handle partial failures gracefully
        result = PointClickEngine::Core::PreflightCheck.run("temp_mixed_config.yaml")

        # Should fail overall but provide detailed feedback
        result.passed.should be_false
        result.errors.should_not be_empty

        # Should identify specific issues
        asset_errors = result.errors.any? { |e| e.downcase.includes?("asset") || e.downcase.includes?("sprite") }
        scene_errors = result.errors.any? { |e| e.downcase.includes?("scene") }

        (asset_errors || scene_errors).should be_true
      rescue ex
        # If it throws an exception, it should be a controlled validation error
        ex.should be_a(PointClickEngine::Core::ValidationError)
      ensure
        File.delete("temp_mixed_config.yaml") if File.exists?("temp_mixed_config.yaml")
      end
    end
  end

  describe "Error propagation across components" do
    it "maintains error context through validation pipeline" do
      # Create config that will fail at different validation stages
      failing_config = <<-YAML
        game:
          name: "Failing Test Game"
          version: "1.0.0"
        window:
          width: 0
          height: -100
        player:
          sprite_path: "missing/player.png"
        start_scene: "missing_start"
        YAML

      File.write("temp_failing_config.yaml", failing_config)

      begin
        # Test error propagation through the validation chain
        config_result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::ConfigError,
          "Loading problematic config"
        ) do
          PointClickEngine::Core::GameConfig.from_file("temp_failing_config.yaml")
        end

        if config_result.failure?
          # Config validation should catch invalid window dimensions
          config_result.error.should be_a(PointClickEngine::Core::ConfigError)
          error_message = config_result.error.message || ""
          (error_message.includes?("window") || error_message.includes?("width") || error_message.includes?("height")).should be_true
        else
          # If config loads, asset validation should catch missing files
          asset_validation_result = PointClickEngine::Core::ErrorHelpers.safe_execute(
            PointClickEngine::Core::AssetError,
            "Validating missing assets"
          ) do
            PointClickEngine::Core::Validators::AssetValidator.validate_all_assets(config_result.value, "temp_failing_config.yaml")
          end

          asset_validation_result.failure?.should be_true
        end
      ensure
        File.delete("temp_failing_config.yaml") if File.exists?("temp_failing_config.yaml")
      end
    end

    it "aggregates multiple validation failures" do
      # Create scene with multiple issues
      problematic_scene = <<-YAML
        name: ""
        # Missing background_path
        hotspots:
          - name: ""
            # Missing coordinates
            width: -50
            height: 0
          - name: "overlapping_hotspot"
            x: 100
            y: 100
            width: 50
            height: 50
          - name: "also_overlapping"
            x: 120
            y: 120
            width: 50
            height: 50
        characters:
          - name: ""
            # Missing position
            scale: -1
        YAML

      File.write("temp_problematic_scene.yaml", problematic_scene)

      begin
        errors = PointClickEngine::Core::Validators::SceneValidator.validate_scene_file("temp_problematic_scene.yaml")

        # Should capture multiple types of errors
        errors.size.should be > 3

        # Should include various error types
        name_errors = errors.any? { |e| e.downcase.includes?("name") && e.downcase.includes?("empty") }
        coordinate_errors = errors.any? { |e| e.downcase.includes?("coordinate") || e.downcase.includes?("position") }
        dimension_errors = errors.any? { |e| e.downcase.includes?("width") || e.downcase.includes?("height") || e.downcase.includes?("scale") }

        [name_errors, coordinate_errors, dimension_errors].count(true).should be >= 2
      ensure
        File.delete("temp_problematic_scene.yaml") if File.exists?("temp_problematic_scene.yaml")
      end
    end
  end
end
