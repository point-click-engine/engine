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
      error_message.should contain("Test operation")
      error_message.should contain("Test exception")
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
