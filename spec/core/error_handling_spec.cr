require "../spec_helper"
require "../../src/core/error_handling"

describe PointClickEngine::Core::Result do
  describe ".success" do
    it "creates a successful result" do
      result = PointClickEngine::Core::Result(String, String).success("test_value")

      result.success?.should be_true
      result.failure?.should be_false
      result.value.should eq("test_value")
    end
  end

  describe ".failure" do
    it "creates a failed result" do
      result = PointClickEngine::Core::Result(String, String).failure("test_error")

      result.success?.should be_false
      result.failure?.should be_true
      result.error.should eq("test_error")
    end
  end

  describe "#value" do
    it "returns value for successful result" do
      result = PointClickEngine::Core::Result(String, String).success("test_value")

      result.value.should eq("test_value")
    end

    it "raises for failed result" do
      result = PointClickEngine::Core::Result(String, String).failure("test_error")

      expect_raises(Exception, "Attempted to get value from failed result") do
        result.value
      end
    end
  end

  describe "#error" do
    it "returns error for failed result" do
      result = PointClickEngine::Core::Result(String, String).failure("test_error")

      result.error.should eq("test_error")
    end

    it "raises for successful result" do
      result = PointClickEngine::Core::Result(String, String).success("test_value")

      expect_raises(Exception, "Attempted to get error from successful result") do
        result.error
      end
    end
  end

  describe "#value_or" do
    it "returns value for successful result" do
      result = PointClickEngine::Core::Result(String, String).success("test_value")

      result.value_or("default").should eq("test_value")
    end

    it "returns default for failed result" do
      result = PointClickEngine::Core::Result(String, String).failure("test_error")

      result.value_or("default").should eq("default")
    end
  end

  describe "#map" do
    it "transforms successful result value" do
      result = PointClickEngine::Core::Result(Int32, String).success(42)

      mapped = result.map { |x| x.to_s }

      mapped.success?.should be_true
      mapped.value.should eq("42")
    end

    it "preserves error in failed result" do
      result = PointClickEngine::Core::Result(Int32, String).failure("test_error")

      mapped = result.map { |x| x.to_s }

      mapped.failure?.should be_true
      mapped.error.should eq("test_error")
    end
  end

  describe "#map_error" do
    it "preserves value in successful result" do
      result = PointClickEngine::Core::Result(String, Int32).success("test_value")

      mapped = result.map_error { |x| x.to_s }

      mapped.success?.should be_true
      mapped.value.should eq("test_value")
    end

    it "transforms failed result error" do
      result = PointClickEngine::Core::Result(String, Int32).failure(42)

      mapped = result.map_error { |x| x.to_s }

      mapped.failure?.should be_true
      mapped.error.should eq("42")
    end
  end

  describe "#and_then" do
    it "chains successful operations" do
      result = PointClickEngine::Core::Result(Int32, String).success(42)

      chained = result.and_then { |x| PointClickEngine::Core::Result(String, String).success(x.to_s) }

      chained.success?.should be_true
      chained.value.should eq("42")
    end

    it "short-circuits on failure" do
      result = PointClickEngine::Core::Result(Int32, String).failure("initial_error")

      chained = result.and_then { |x| PointClickEngine::Core::Result(String, String).success(x.to_s) }

      chained.failure?.should be_true
      chained.error.should eq("initial_error")
    end

    it "propagates failures from chained operations" do
      result = PointClickEngine::Core::Result(Int32, String).success(42)

      chained = result.and_then { |x| PointClickEngine::Core::Result(String, String).failure("chained_error") }

      chained.failure?.should be_true
      chained.error.should eq("chained_error")
    end
  end
end

describe PointClickEngine::Core::ErrorHelpers do
  describe "#safe_execute" do
    it "returns success for operations that don't raise" do
      result = PointClickEngine::Core::ErrorHelpers.safe_execute(
        PointClickEngine::Core::FileError,
        "Test operation"
      ) do
        "success_value"
      end

      result.success?.should be_true
      result.value.should eq("success_value")
    end

    it "catches exceptions and returns failure" do
      result = PointClickEngine::Core::ErrorHelpers.safe_execute(
        PointClickEngine::Core::FileError,
        "Test operation"
      ) do
        raise "Test exception"
      end

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::FileError)
      error_message = result.error.message || ""
      error_message.includes?("Test operation").should be_true
      error_message.includes?("Test exception").should be_true
    end
  end

  describe "#validate_file_exists" do
    it "returns success for existing files" do
      # Create a temporary file for testing
      File.write("temp_test_file.txt", "test content")

      result = PointClickEngine::Core::ErrorHelpers.validate_file_exists("temp_test_file.txt")

      result.success?.should be_true
      result.value.should eq("temp_test_file.txt")

      # Clean up
      File.delete("temp_test_file.txt")
    end

    it "returns failure for non-existing files" do
      result = PointClickEngine::Core::ErrorHelpers.validate_file_exists("nonexistent_file.txt")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::FileError)
    end
  end

  describe "#validate_directory_exists" do
    it "returns success for existing directories" do
      # Create a temporary directory
      Dir.mkdir_p("temp_test_dir")

      result = PointClickEngine::Core::ErrorHelpers.validate_directory_exists("temp_test_dir")

      result.success?.should be_true
      result.value.should eq("temp_test_dir")

      # Clean up
      Dir.delete("temp_test_dir")
    end

    it "returns failure for non-existing directories" do
      result = PointClickEngine::Core::ErrorHelpers.validate_directory_exists("nonexistent_dir")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::FileError)
    end
  end

  describe "#ensure_directory_exists" do
    it "creates directory if it doesn't exist" do
      result = PointClickEngine::Core::ErrorHelpers.ensure_directory_exists("temp_test_create_dir")

      result.success?.should be_true
      Dir.exists?("temp_test_create_dir").should be_true

      # Clean up
      Dir.delete("temp_test_create_dir")
    end

    it "succeeds if directory already exists" do
      Dir.mkdir_p("temp_existing_dir")

      result = PointClickEngine::Core::ErrorHelpers.ensure_directory_exists("temp_existing_dir")

      result.success?.should be_true

      # Clean up
      Dir.delete("temp_existing_dir")
    end
  end

  describe "#validate_not_nil" do
    it "returns success for non-nil values" do
      result = PointClickEngine::Core::ErrorHelpers.validate_not_nil("test_value", "Test field")

      result.success?.should be_true
      result.value.should eq("test_value")
    end

    it "returns failure for nil values" do
      result = PointClickEngine::Core::ErrorHelpers.validate_not_nil(nil, "Test field")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::ValidationError)
    end
  end

  describe "#validate_not_empty" do
    it "returns success for non-empty strings" do
      result = PointClickEngine::Core::ErrorHelpers.validate_not_empty("test", "test_field")

      result.success?.should be_true
      result.value.should eq("test")
    end

    it "returns failure for empty strings" do
      result = PointClickEngine::Core::ErrorHelpers.validate_not_empty("", "test_field")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::ValidationError)
    end
  end

  describe "#validate_range" do
    it "returns success for values within range" do
      result = PointClickEngine::Core::ErrorHelpers.validate_range(50, 0, 100, "test_value")

      result.success?.should be_true
      result.value.should eq(50)
    end

    it "returns failure for values below range" do
      result = PointClickEngine::Core::ErrorHelpers.validate_range(-10, 0, 100, "test_value")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::ValidationError)
    end

    it "returns failure for values above range" do
      result = PointClickEngine::Core::ErrorHelpers.validate_range(150, 0, 100, "test_value")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::ValidationError)
    end
  end
end

describe PointClickEngine::Core::ErrorLogger do
  describe "logging methods" do
    it "logs debug messages" do
      # Should not raise exceptions
      PointClickEngine::Core::ErrorLogger.debug("Test debug message")
    end

    it "logs info messages" do
      PointClickEngine::Core::ErrorLogger.info("Test info message")
    end

    it "logs warning messages" do
      PointClickEngine::Core::ErrorLogger.warning("Test warning message")
    end

    it "logs error messages" do
      PointClickEngine::Core::ErrorLogger.error("Test error message")
    end

    it "logs fatal messages" do
      PointClickEngine::Core::ErrorLogger.fatal("Test fatal message")
    end
  end

  describe "#set_log_level" do
    it "changes the log level" do
      original_level = PointClickEngine::Core::ErrorLogger::LogLevel::Info

      PointClickEngine::Core::ErrorLogger.set_log_level(PointClickEngine::Core::ErrorLogger::LogLevel::Warning)
      PointClickEngine::Core::ErrorLogger.set_log_level(original_level)
    end
  end
end

describe PointClickEngine::Core do
  describe "Exception hierarchy" do
    it "creates specific error types" do
      # ConfigError
      config_error = PointClickEngine::Core::ConfigError.new("Invalid config", "config.yaml", "window.width")
      (config_error.message || "").includes?("Invalid config").should be_true
      config_error.filename.should eq("config.yaml")
      config_error.field.should eq("window.width")

      # AssetError
      asset_error = PointClickEngine::Core::AssetError.new("Asset not found", "sprite.png", "scene1.yaml")
      (asset_error.message || "").includes?("Asset not found").should be_true
      asset_error.asset_path.should eq("sprite.png")
      asset_error.filename.should eq("scene1.yaml")

      # SceneError
      scene_error = PointClickEngine::Core::SceneError.new("Invalid hotspot", "intro_scene", "hotspots[0]")
      (scene_error.message || "").includes?("Invalid hotspot").should be_true
      scene_error.scene_name.should eq("intro_scene")
      scene_error.field.should eq("hotspots[0]")

      # ValidationError
      validation_errors = ["Missing field", "Invalid value"]
      validation_error = PointClickEngine::Core::ValidationError.new(validation_errors, "test.yaml")
      validation_error.errors.should eq(validation_errors)
      validation_error.filename.should eq("test.yaml")
    end

    it "creates engine-specific errors" do
      # FileError
      file_error = PointClickEngine::Core::FileError.new("Permission denied", "/restricted/file.txt")
      (file_error.message || "").includes?("Permission denied").should be_true
      file_error.filename.should eq("/restricted/file.txt")

      # LoadingError
      loading_error = PointClickEngine::Core::LoadingError.new("Failed to load", "config.yaml", "textures")
      (loading_error.message || "").includes?("Failed to load").should be_true
      loading_error.filename.should eq("config.yaml")
      loading_error.field.should eq("textures")

      # RenderError
      render_error = PointClickEngine::Core::RenderError.new("Shader compilation failed")
      (render_error.message || "").includes?("Shader compilation failed").should be_true
    end
  end

  describe "Error recovery mechanisms" do
    describe "fallback strategies" do
      it "handles asset loading failures gracefully" do
        # Test fallback asset loading
        begin
          result = PointClickEngine::Core::ErrorHelpers.safe_execute(
            PointClickEngine::Core::AssetError,
            "Loading missing texture"
          ) do
            raise "File not found: missing_texture.png"
          end

          result.failure?.should be_true
          result.error.should be_a(PointClickEngine::Core::AssetError)
        end
      end

      it "provides default configurations on config errors" do
        result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::ConfigError,
          "Loading invalid config"
        ) do
          "valid_config" # This would be the actual config content
        end

        if result.success?
          result.value.should eq("valid_config")
        end

        # Test with an actual failure
        failure_result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::ConfigError,
          "Loading invalid config"
        ) do
          raise "Invalid YAML syntax"
          "never_reached"
        end

        failure_result.failure?.should be_true

        # Test fallback to default value
        default_value = failure_result.value_or("default_config")
        default_value.should eq("default_config")
      end

      it "handles scene loading errors with recovery" do
        result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::SceneError,
          "Loading corrupted scene"
        ) do
          raise "Malformed scene data"
        end

        result.failure?.should be_true
        result.error.should be_a(PointClickEngine::Core::SceneError)

        # Test error chaining for recovery
        recovery_result = result.map_error do |error|
          PointClickEngine::Core::LoadingError.new("Scene recovery initiated", "scene")
        end

        recovery_result.failure?.should be_true
        recovery_result.error.should be_a(PointClickEngine::Core::LoadingError)
      end
    end

    describe "error propagation" do
      it "chains errors through Result operations" do
        # Start with a successful result
        initial = PointClickEngine::Core::Result(Int32, String).success(42)

        # Chain operations that might fail
        result = initial
          .and_then { |x| PointClickEngine::Core::Result(String, String).success(x.to_s) }
          .and_then { |s| PointClickEngine::Core::Result(Float32, String).failure("Conversion failed") }
          .and_then { |f| PointClickEngine::Core::Result(Bool, String).success(true) }

        result.failure?.should be_true
        result.error.should eq("Conversion failed")
      end

      it "preserves error context through transformations" do
        original_error = PointClickEngine::Core::ConfigError.new("Invalid window size", "game.yaml", "window.width")
        result = PointClickEngine::Core::Result(String, PointClickEngine::Core::ConfigError).failure(original_error)

        # Transform error while preserving context
        mapped_result = result.map_error do |error|
          PointClickEngine::Core::ValidationError.new([error.message || "Unknown error"], error.filename || "unknown")
        end

        mapped_result.failure?.should be_true
        mapped_result.error.should be_a(PointClickEngine::Core::ValidationError)
        mapped_result.error.filename.should eq("game.yaml")
      end
    end

    describe "error aggregation" do
      it "collects multiple validation errors" do
        errors = [] of String

        # Simulate multiple validation failures
        validation_result_1 = PointClickEngine::Core::ErrorHelpers.validate_not_empty("", "field1")
        if validation_result_1.failure?
          error_msg = validation_result_1.error.message
          errors << (error_msg || "Unknown error")
        end

        validation_result_2 = PointClickEngine::Core::ErrorHelpers.validate_range(-5, 0, 100, "field2")
        if validation_result_2.failure?
          error_msg = validation_result_2.error.message
          errors << (error_msg || "Unknown error")
        end

        validation_result_3 = PointClickEngine::Core::ErrorHelpers.validate_not_nil(nil, "field3")
        if validation_result_3.failure?
          error_msg = validation_result_3.error.message
          errors << (error_msg || "Unknown error")
        end

        errors.size.should eq(3)

        # Create aggregated error
        aggregated_error = PointClickEngine::Core::ValidationError.new(errors, "test_validation")
        aggregated_error.errors.size.should eq(3)
      end
    end

    describe "graceful degradation" do
      it "continues operation with partial failures" do
        # Simulate loading multiple assets where some fail
        asset_results = [] of PointClickEngine::Core::Result(String, PointClickEngine::Core::AssetError)

        # Successful loads
        asset_results << PointClickEngine::Core::Result(String, PointClickEngine::Core::AssetError).success("texture1.png")
        asset_results << PointClickEngine::Core::Result(String, PointClickEngine::Core::AssetError).success("texture2.png")

        # Failed load
        asset_results << PointClickEngine::Core::Result(String, PointClickEngine::Core::AssetError).failure(
          PointClickEngine::Core::AssetError.new("File not found", "missing.png")
        )

        # Successful load
        asset_results << PointClickEngine::Core::Result(String, PointClickEngine::Core::AssetError).success("texture3.png")

        # Count successful vs failed loads
        successful_loads = asset_results.count(&.success?)
        failed_loads = asset_results.count(&.failure?)

        successful_loads.should eq(3)
        failed_loads.should eq(1)

        # System should continue with successfully loaded assets
        loaded_assets = asset_results.select(&.success?).map(&.value)
        loaded_assets.size.should eq(3)
        loaded_assets.includes?("texture1.png").should be_true
        loaded_assets.includes?("texture2.png").should be_true
        loaded_assets.includes?("texture3.png").should be_true
      end
    end
  end

  describe "Error reporting integration" do
    it "formats error reports consistently" do
      config_error = PointClickEngine::Core::ConfigError.new("Invalid resolution", "config.yaml", "window.height")
      asset_error = PointClickEngine::Core::AssetError.new("Texture not found", "player.png", "player_scene.yaml")

      errors = [config_error, asset_error] of Exception

      # Should not crash when reporting multiple errors
      PointClickEngine::Core::ErrorReporter.report_multiple_errors(errors, "Initialization Failed")
    end

    it "handles different error severity levels" do
      # Info level
      PointClickEngine::Core::ErrorReporter.report_info("Game initialization started")

      # Warning level
      PointClickEngine::Core::ErrorReporter.report_warning("Using fallback renderer", "Graphics Setup")

      # Error level
      error = PointClickEngine::Core::RenderError.new("Failed to create OpenGL context")
      PointClickEngine::Core::ErrorReporter.report_loading_error(error, "Graphics Initialization")

      # Success level
      PointClickEngine::Core::ErrorReporter.report_success("All systems initialized successfully")
    end
  end
end
