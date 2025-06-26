require "./validation/preflight_orchestrator"
require "./validation/validation_result"

module PointClickEngine
  module Core
    # Preflight check using the validation system
    class PreflightCheck
      # Main validation orchestrator
      @@orchestrator = Validation::PreflightOrchestrator.new

      # Runs comprehensive validation
      def self.run(config_path : String) : Validation::ValidationResult
        validation_result = @@orchestrator.run_all_validations(config_path)
        display_summary(validation_result)
        validation_result
      end

      # Runs validation in strict mode
      def self.run_strict(config_path : String) : Validation::ValidationResult
        validation_result = @@orchestrator.run_all_validations(config_path, strict_mode: true)
        display_summary(validation_result)
        validation_result
      end

      # Runs validation in development mode
      def self.run_development(config_path : String) : Validation::ValidationResult
        validation_result = @@orchestrator.run_all_validations(config_path, development_mode: true)
        display_summary(validation_result)
        validation_result
      end

      # Runs quick validation (essential checks only)
      def self.run_quick(config_path : String) : Validation::ValidationResult
        validation_result = @@orchestrator.run_quick_validation(config_path)
        display_summary(validation_result)
        validation_result
      end

      # Runs only configuration validation
      def self.validate_config_only(config_path : String) : Validation::ValidationResult
        validation_result = @@orchestrator.validate_config_only(config_path)
        display_summary(validation_result)
        validation_result
      end

      # Runs specific validations only
      def self.run_specific(config_path : String, validators : Array(String)) : Validation::ValidationResult
        validation_result = @@orchestrator.run_specific_validations(config_path, validators)
        display_summary(validation_result)
        validation_result
      end

      # Gets list of available validators
      def self.get_available_validators : Array(String)
        @@orchestrator.get_validator_names
      end

      # Adds a custom validator
      def self.add_validator(validator : Validation::BaseValidator)
        @@orchestrator.add_validator(validator)
      end

      # Removes a validator
      def self.remove_validator(name : String)
        @@orchestrator.remove_validator(name)
      end

      # Creates a detailed report
      def self.create_report(config_path : String, format : String = "text") : String
        validation_result = @@orchestrator.run_all_validations(config_path)
        @@orchestrator.create_report(validation_result, format)
      end

      # Creates a quick report
      def self.create_quick_report(config_path : String, format : String = "text") : String
        validation_result = @@orchestrator.run_quick_validation(config_path)
        @@orchestrator.create_report(validation_result, format)
      end

      # Display validation summary
      private def self.display_summary(result : Validation::ValidationResult)
        puts "\n" + "=" * 60
        puts "VALIDATION SUMMARY"
        puts "=" * 60

        if result.passed
          puts "✅ PRE-FLIGHT CHECK PASSED"
        else
          puts "❌ PRE-FLIGHT CHECK FAILED"
        end

        # Display counts
        total_issues = result.errors.size + result.warnings.size + result.security_issues.size
        puts "\nIssue Summary:"
        puts "  Errors: #{result.errors.size}"
        puts "  Warnings: #{result.warnings.size}"
        puts "  Security Issues: #{result.security_issues.size}"
        puts "  Performance Hints: #{result.performance_hints.size}"
        puts "  Total Issues: #{total_issues}"

        # Display errors
        if result.errors.any?
          puts "\n❌ ERRORS:"
          result.errors.each { |error| puts "  - #{error}" }
        end

        # Display warnings
        if result.warnings.any?
          puts "\n⚠️  WARNINGS:"
          result.warnings.each { |warning| puts "  - #{warning}" }
        end

        # Display security issues
        if result.security_issues.any?
          puts "\n🔒 SECURITY ISSUES:"
          result.security_issues.each { |issue| puts "  - #{issue}" }
        end

        # Display performance hints (limited to avoid spam)
        if result.performance_hints.any?
          puts "\n💡 PERFORMANCE HINTS:"
          result.performance_hints.first(10).each { |hint| puts "  - #{hint}" }
          if result.performance_hints.size > 10
            puts "  ... and #{result.performance_hints.size - 10} more hints"
          end
        end

        # Display info messages (limited)
        if result.info.any?
          puts "\nℹ️  INFORMATION:"
          result.info.first(5).each { |info| puts "  - #{info}" }
          if result.info.size > 5
            puts "  ... and #{result.info.size - 5} more info messages"
          end
        end

        puts "\n" + "=" * 60

        # Provide next steps
        if result.passed
          puts "🎉 Your game configuration looks good! You can proceed with development."
          if result.performance_hints.any?
            puts "💡 Consider reviewing the performance hints for optimization opportunities."
          end
        else
          puts "🔧 Please fix the errors above before proceeding."
          puts "💡 Check the documentation for help with common issues."
        end

        puts "=" * 60
      end

      # Validates and returns detailed metrics
      def self.get_validation_metrics(config_path : String) : Hash(String, Int32 | Float64 | Bool)
        validation_result = @@orchestrator.run_all_validations(config_path)

        {
          "passed"                 => validation_result.passed,
          "error_count"            => validation_result.errors.size,
          "warning_count"          => validation_result.warnings.size,
          "security_issue_count"   => validation_result.security_issues.size,
          "performance_hint_count" => validation_result.performance_hints.size,
          "info_count"             => validation_result.info.size,
          "total_message_count"    => validation_result.total_message_count,
          "has_critical_issues"    => validation_result.has_critical_issues?,
        }
      end

      # Checks if configuration passes basic validation
      def self.is_valid?(config_path : String) : Bool
        validation_result = @@orchestrator.run_quick_validation(config_path)
        validation_result.passed
      end

      # Gets validation summary string
      def self.get_summary(config_path : String) : String
        validation_result = @@orchestrator.run_all_validations(config_path)
        validation_result.summary
      end

      # Batch validation for multiple configurations
      def self.validate_batch(config_paths : Array(String)) : Hash(String, Validation::ValidationResult)
        results = {} of String => Validation::ValidationResult

        config_paths.each do |path|
          begin
            results[path] = run_quick(path)
          rescue ex
            error_result = Validation::ValidationResult.new(false)
            error_result.errors << "Failed to validate #{path}: #{ex.message}"
            results[path] = error_result
          end
        end

        results
      end

      # Validates configuration and returns only errors (for CI/CD)
      def self.get_errors_only(config_path : String) : Array(String)
        validation_result = @@orchestrator.run_all_validations(config_path)
        validation_result.errors + validation_result.security_issues
      end

      # Validates configuration and returns only warnings
      def self.get_warnings_only(config_path : String) : Array(String)
        validation_result = @@orchestrator.run_all_validations(config_path)
        validation_result.warnings
      end

      # Gets performance recommendations
      def self.get_performance_recommendations(config_path : String) : Array(String)
        validation_result = @@orchestrator.run_all_validations(config_path)
        validation_result.performance_hints
      end

      # Convenience method to run checks and raise on failure
      def self.run!(config_path : String)
        result = run(config_path)
        unless result.passed
          raise ValidationError.new(result.errors, config_path)
        end
      end
    end
  end
end
