require "../spec_helper"
require "../../src/core/error_handling"

describe "Error Recovery Tests" do
  describe "Asset loading error recovery" do
    it "handles missing files gracefully" do
      result = PointClickEngine::Core::ErrorHelpers.safe_file_read("nonexistent_file.txt")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::FileError)

      # Test fallback behavior
      fallback_content = result.value_or("default content")
      fallback_content.should eq("default content")
    end

    it "successfully reads existing files" do
      File.write("temp_test_file.txt", "test content")

      begin
        result = PointClickEngine::Core::ErrorHelpers.safe_file_read("temp_test_file.txt")

        result.success?.should be_true
        result.value.should eq("test content")
      ensure
        File.delete("temp_test_file.txt") if File.exists?("temp_test_file.txt")
      end
    end

    it "handles file writing errors" do
      # Try to write to a directory that doesn't exist
      result = PointClickEngine::Core::ErrorHelpers.safe_file_write("/nonexistent/directory/file.txt", "content")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::FileError)
    end

    it "successfully writes to valid paths" do
      result = PointClickEngine::Core::ErrorHelpers.safe_file_write("temp_write_test.txt", "write test")

      begin
        result.success?.should be_true

        # Verify file was written
        File.exists?("temp_write_test.txt").should be_true
        File.read("temp_write_test.txt").should eq("write test")
      ensure
        File.delete("temp_write_test.txt") if File.exists?("temp_write_test.txt")
      end
    end
  end

  describe "Directory validation and recovery" do
    it "creates missing directories" do
      dir_path = "temp_test_dir_#{Random.rand(1000)}"

      result = PointClickEngine::Core::ErrorHelpers.ensure_directory_exists(dir_path)

      begin
        result.success?.should be_true
        Dir.exists?(dir_path).should be_true
      ensure
        Dir.delete(dir_path) if Dir.exists?(dir_path)
      end
    end

    it "validates existing directories" do
      Dir.mkdir_p("temp_existing_dir")

      begin
        result = PointClickEngine::Core::ErrorHelpers.validate_directory_exists("temp_existing_dir")

        result.success?.should be_true
        result.value.should eq("temp_existing_dir")
      ensure
        Dir.delete("temp_existing_dir") if Dir.exists?("temp_existing_dir")
      end
    end

    it "detects missing directories" do
      result = PointClickEngine::Core::ErrorHelpers.validate_directory_exists("definitely_missing_dir")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::FileError)
    end
  end

  describe "Validation error aggregation" do
    it "collects multiple validation failures" do
      errors = [] of String

      # Test empty string validation
      result1 = PointClickEngine::Core::ErrorHelpers.validate_not_empty("", "username")
      if result1.failure?
        error_msg = result1.error.message
        errors << (error_msg || "Unknown error")
      end

      # Test range validation
      result2 = PointClickEngine::Core::ErrorHelpers.validate_range(-5, 0, 100, "age")
      if result2.failure?
        error_msg = result2.error.message
        errors << (error_msg || "Unknown error")
      end

      # Test nil validation
      result3 = PointClickEngine::Core::ErrorHelpers.validate_not_nil(nil, "required_field")
      if result3.failure?
        error_msg = result3.error.message
        errors << (error_msg || "Unknown error")
      end

      errors.size.should eq(3)
      errors[0].should contain("username")
      errors[1].should contain("age")
      errors[2].should contain("required_field")

      # Create aggregated validation error
      validation_error = PointClickEngine::Core::ValidationError.new(errors, "test_validation")
      validation_error.errors.size.should eq(3)
    end

    it "handles successful validations" do
      # Test successful validations
      result1 = PointClickEngine::Core::ErrorHelpers.validate_not_empty("valid", "username")
      result2 = PointClickEngine::Core::ErrorHelpers.validate_range(50, 0, 100, "percentage")
      result3 = PointClickEngine::Core::ErrorHelpers.validate_not_nil("present", "field")

      result1.success?.should be_true
      result2.success?.should be_true
      result3.success?.should be_true

      result1.value.should eq("valid")
      result2.value.should eq(50)
      result3.value.should eq("present")
    end
  end

  describe "Result chaining and error propagation" do
    it "chains successful operations" do
      result = PointClickEngine::Core::Result(Int32, String).success(10)
        .map { |x| x * 2 }
        .and_then { |x| PointClickEngine::Core::Result(String, String).success(x.to_s) }
        .map { |s| s + " items" }

      result.success?.should be_true
      result.value.should eq("20 items")
    end

    it "short-circuits on first failure" do
      result = PointClickEngine::Core::Result(Int32, String).success(10)
        .map { |x| x * 2 }
        .and_then { |x| PointClickEngine::Core::Result(String, String).failure("conversion failed") }
        .map { |s| s + " items" }

      result.failure?.should be_true
      result.error.should eq("conversion failed")
    end

    it "transforms errors while preserving type safety" do
      original_result = PointClickEngine::Core::Result(String, Int32).failure(404)

      transformed = original_result.map_error { |code| "HTTP Error: #{code}" }

      transformed.failure?.should be_true
      transformed.error.should eq("HTTP Error: 404")
    end
  end

  describe "Error recovery strategies" do
    it "implements retry logic with fallback" do
      attempt_count = 0

      # Simulate retry logic
      result = nil
      3.times do
        result = PointClickEngine::Core::ErrorHelpers.safe_execute(
          PointClickEngine::Core::FileError,
          "Attempting operation"
        ) do
          attempt_count += 1
          if attempt_count < 3
            raise "Temporary failure #{attempt_count}"
          else
            "success after #{attempt_count} attempts"
          end
        end

        break if result.success?
      end

      result.should_not be_nil
      result.not_nil!.success?.should be_true
      result.not_nil!.value.should eq("success after 3 attempts")
    end

    it "provides fallback values for critical operations" do
      # Simulate a critical operation that must always return a value
      critical_operation = ->(should_fail : Bool) {
        if should_fail
          PointClickEngine::Core::Result(String, String).failure("operation failed")
        else
          PointClickEngine::Core::Result(String, String).success("operation succeeded")
        end
      }

      # Test successful case
      success_result = critical_operation.call(false)
      final_value = success_result.value_or("default fallback")
      final_value.should eq("operation succeeded")

      # Test failure case with fallback
      failure_result = critical_operation.call(true)
      final_value = failure_result.value_or("default fallback")
      final_value.should eq("default fallback")
    end

    it "handles cascading failures with multiple fallbacks" do
      # Simulate primary, secondary, and tertiary systems
      primary_system = PointClickEngine::Core::Result(String, String).failure("primary offline")
      secondary_system = PointClickEngine::Core::Result(String, String).failure("secondary offline")
      tertiary_system = PointClickEngine::Core::Result(String, String).success("tertiary online")

      # Try systems in order
      final_result = if primary_system.success?
                       primary_system
                     elsif secondary_system.success?
                       secondary_system
                     else
                       tertiary_system
                     end

      final_result.success?.should be_true
      final_result.value.should eq("tertiary online")
    end
  end
end
