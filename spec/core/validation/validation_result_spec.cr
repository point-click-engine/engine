require "../../spec_helper"
require "../../../src/core/validation/validation_result"

describe PointClickEngine::Core::Validation::ValidationResult do
  describe "initialization" do
    it "initializes with passed status by default" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.passed.should be_true
      result.errors.should be_empty
      result.warnings.should be_empty
      result.info.should be_empty
      result.performance_hints.should be_empty
      result.security_issues.should be_empty
    end

    it "can initialize with failed status" do
      failed_result = PointClickEngine::Core::Validation::ValidationResult.new(false)
      failed_result.passed.should be_false
    end
  end

  describe "adding messages" do
    it "adds errors and marks as failed" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_error("Test error")

      result.passed.should be_false
      result.errors.should contain("Test error")
    end

    it "adds multiple errors" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      errors = ["Error 1", "Error 2"]
      result.add_errors(errors)

      result.passed.should be_false
      result.errors.should eq(errors)
    end

    it "adds warnings without affecting passed status" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_warning("Test warning")

      result.passed.should be_true
      result.warnings.should contain("Test warning")
    end

    it "adds multiple warnings" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      warnings = ["Warning 1", "Warning 2"]
      result.add_warnings(warnings)

      result.passed.should be_true
      result.warnings.should eq(warnings)
    end

    it "adds info messages" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_info("Test info")

      result.info.should contain("Test info")
      result.passed.should be_true
    end

    it "adds performance hints" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_performance_hint("Optimize this")

      result.performance_hints.should contain("Optimize this")
    end

    it "adds security issues" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_security_issue("Security problem")

      result.security_issues.should contain("Security problem")
    end
  end

  describe "merging results" do
    it "merges another validation result" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      other = PointClickEngine::Core::Validation::ValidationResult.new
      other.add_error("Other error")
      other.add_warning("Other warning")
      other.add_info("Other info")

      result.add_warning("Original warning")
      result.merge(other)

      result.passed.should be_false # Inherited from other
      result.errors.should contain("Other error")
      result.warnings.should contain("Original warning")
      result.warnings.should contain("Other warning")
      result.info.should contain("Other info")
    end

    it "maintains failed status when merging" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.passed = false
      other = PointClickEngine::Core::Validation::ValidationResult.new(true)

      result.merge(other)

      result.passed.should be_false
    end
  end

  describe "status checking" do
    it "detects when there are issues" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.has_issues?.should be_false

      result.add_warning("Warning")
      result.has_issues?.should be_true
    end

    it "detects critical issues" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.has_critical_issues?.should be_false

      result.add_warning("Warning")
      result.has_critical_issues?.should be_false

      result.add_error("Error")
      result.has_critical_issues?.should be_true
    end

    it "considers security issues as critical" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_security_issue("Security issue")
      result.has_critical_issues?.should be_true
    end
  end

  describe "counting" do
    it "counts total messages" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_error("Error")
      result.add_warning("Warning")
      result.add_info("Info")
      result.add_performance_hint("Hint")
      result.add_security_issue("Security")

      result.total_message_count.should eq(5)
    end

    it "counts only issues" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_error("Error")
      result.add_warning("Warning")
      result.add_info("Info")             # Not counted as issue
      result.add_performance_hint("Hint") # Not counted as issue
      result.add_security_issue("Security")

      result.issue_count.should eq(3)
    end
  end

  describe "summary" do
    it "creates summary for passed result" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_info("Some info")

      summary = result.summary
      summary.should contain("PASSED")
    end

    it "creates summary for failed result" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_error("Error")
      result.add_warning("Warning")

      summary = result.summary
      summary.should contain("FAILED")
      summary.should contain("1 error(s)")
      summary.should contain("1 warning(s)")
    end

    it "includes all issue types in summary" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_error("Error")
      result.add_warning("Warning")
      result.add_security_issue("Security")
      result.add_performance_hint("Hint")

      summary = result.summary
      summary.should contain("1 error(s)")
      summary.should contain("1 warning(s)")
      summary.should contain("1 security issue(s)")
      summary.should contain("1 performance hint(s)")
    end
  end

  describe "string representation" do
    it "provides readable string representation" do
      result = PointClickEngine::Core::Validation::ValidationResult.new
      result.add_error("Error")

      str = result.to_s
      str.should contain("ValidationResult")
      str.should contain("FAILED")
    end
  end
end

describe PointClickEngine::Core::Validation::ValidationContext do
  describe "initialization" do
    it "initializes with config path" do
      config_path = "/test/config.yaml"
      context = PointClickEngine::Core::Validation::ValidationContext.new(config_path)
      context.config_path.should eq(config_path)
      context.base_dir.should eq("/test")
    end

    it "sets default values" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      context.strict_mode.should be_false
      context.development_mode.should be_false
      context.skip_optional_checks.should be_false
      context.include_performance_checks.should be_true
      context.include_security_checks.should be_true
    end
  end

  describe "path resolution" do
    it "resolves relative paths" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      resolved = context.resolve_path("assets/sprites")
      resolved.should eq("/test/assets/sprites")
    end

    it "keeps absolute paths unchanged" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      absolute_path = "/absolute/path/to/file"
      resolved = context.resolve_path(absolute_path)
      resolved.should eq(absolute_path)
    end
  end

  describe "file operations" do
    it "checks file existence" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      # This would need actual file system setup for proper testing
      context.file_exists?("nonexistent").should be_false
    end
  end

  describe "caching" do
    it "caches and retrieves values" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      context.cache_set("test_key", "test_value")

      context.cache_get("test_key").should eq("test_value")
      context.cache_has?("test_key").should be_true
    end

    it "returns default for missing keys" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      context.cache_get("missing_key", "default").should eq("default")
    end

    it "handles different value types" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      context.cache_set("string", "value")
      context.cache_set("int", 42)
      context.cache_set("bool", true)
      context.cache_set("array", ["a", "b", "c"])

      context.cache_get("string").should eq("value")
      context.cache_get("int").should eq(42)
      context.cache_get("bool").should eq(true)
      context.cache_get("array").should eq(["a", "b", "c"])
    end
  end

  describe "string representation" do
    it "provides readable string representation" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      str = context.to_s
      str.should contain("ValidationContext")
      str.should contain("config.yaml")
      str.should contain("/test")
    end
  end
end

describe PointClickEngine::Core::Validation::ValidationContextFactory do
  describe "context creation" do
    it "creates basic context" do
      config_path = "/test/config.yaml"
      context = PointClickEngine::Core::Validation::ValidationContextFactory.create(config_path)

      context.config_path.should eq(config_path)
      context.strict_mode.should be_false
      context.development_mode.should be_false
    end

    it "creates strict context" do
      config_path = "/test/config.yaml"
      context = PointClickEngine::Core::Validation::ValidationContextFactory.create(config_path, strict_mode: true)

      context.strict_mode.should be_true
    end

    it "creates development context" do
      config_path = "/test/config.yaml"
      context = PointClickEngine::Core::Validation::ValidationContextFactory.create_development(config_path)

      context.development_mode.should be_true
      context.strict_mode.should be_false
    end

    it "creates production context" do
      config_path = "/test/config.yaml"
      context = PointClickEngine::Core::Validation::ValidationContextFactory.create_production(config_path)

      context.strict_mode.should be_true
      context.development_mode.should be_false
      context.skip_optional_checks.should be_true
      context.include_performance_checks.should be_false
    end
  end
end

class TestValidator < PointClickEngine::Core::Validation::BaseValidator
  def validate(config : PointClickEngine::Core::GameConfig, context : PointClickEngine::Core::Validation::ValidationContext) : PointClickEngine::Core::Validation::ValidationResult
    result = PointClickEngine::Core::Validation::ValidationResult.new
    result.add_info("Test validator executed")
    result
  end

  def description : String
    "Test validator for specifications"
  end
end

describe PointClickEngine::Core::Validation::BaseValidator do
  describe "interface" do
    it "has default name based on class" do
      validator = TestValidator.new
      validator.name.should eq("TestValidator")
    end

    it "has description" do
      validator = TestValidator.new
      validator.description.should eq("Test validator for specifications")
    end

    it "should run by default" do
      context = PointClickEngine::Core::Validation::ValidationContext.new("/test/config.yaml")
      validator = TestValidator.new
      validator.should_run?(context).should be_true
    end

    it "has default priority" do
      validator = TestValidator.new
      validator.priority.should eq(100)
    end
  end
end
