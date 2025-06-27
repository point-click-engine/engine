require "./validation_result"
require "./asset_validation_checker"
require "./rendering_validation_checker"
require "./performance_validation_checker"
require "./security_validation_checker"
require "./platform_info_validator"
require "../validators/config_validator"
require "../validators/asset_validator"
require "../validators/scene_validator"
require "../validators/scene_coordinate_validator"

module PointClickEngine
  module Core
    module Validation
      # Orchestrates the execution of all validation components
      #
      # The PreflightOrchestrator coordinates multiple validators to provide
      # comprehensive game configuration validation. It manages validator
      # execution order, result aggregation, and error handling.
      class PreflightOrchestrator
        property validators : Array(BaseValidator)
        property context : ValidationContext?
        property config : GameConfig?

        def initialize
          @validators = [] of BaseValidator
          setup_default_validators
        end

        # Runs all validations on the specified configuration
        def run_all_validations(config_path : String, strict_mode : Bool = false, development_mode : Bool = false) : ValidationResult
          puts "Running comprehensive pre-flight checks..."
          puts "=" * 60

          # Initialize context
          context = ValidationContextFactory.create(config_path, strict_mode, development_mode)
          @context = context

          # Load and validate configuration first
          config_result = load_and_validate_config(config_path, context)
          return config_result unless config_result.passed

          # Run all validators in priority order
          overall_result = ValidationResult.new
          overall_result.merge(config_result)

          sorted_validators = @validators.sort_by(&.priority)

          sorted_validators.each do |validator|
            next unless validator.should_run?(context)

            puts "\n#{get_step_number(validator)}. #{validator.description}..."

            begin
              validator_result = validator.validate(@config.not_nil!, context)
              overall_result.merge(validator_result)

              # Report progress
              if validator_result.errors.any?
                puts "  ❌ #{validator_result.errors.size} error(s) found"
              elsif validator_result.warnings.any?
                puts "  ⚠️  #{validator_result.warnings.size} warning(s) found"
              else
                puts "  ✅ Validation passed"
              end
            rescue ex
              error_message = "Validator '#{validator.name}' failed: #{ex.message}"
              overall_result.add_error(error_message)
              puts "  ❌ #{error_message}"
            end
          end

          # Add summary information
          add_validation_summary(overall_result, context)

          overall_result
        end

        # Runs only specific validators
        def run_specific_validations(config_path : String, validator_names : Array(String)) : ValidationResult
          context = ValidationContextFactory.create(config_path)
          @context = context

          # Load configuration
          config_result = load_and_validate_config(config_path, context)
          return config_result unless config_result.passed

          overall_result = ValidationResult.new
          overall_result.merge(config_result)

          # Run only requested validators
          @validators.each do |validator|
            if validator_names.includes?(validator.name)
              validator_result = validator.validate(@config.not_nil!, context)
              overall_result.merge(validator_result)
            end
          end

          overall_result
        end

        # Adds a custom validator
        def add_validator(validator : BaseValidator)
          @validators << validator
        end

        # Removes a validator by name
        def remove_validator(name : String)
          @validators.reject! { |v| v.name == name }
        end

        # Gets available validator names
        def get_validator_names : Array(String)
          @validators.map(&.name)
        end

        # Runs a quick validation (skips optional checks)
        def run_quick_validation(config_path : String) : ValidationResult
          context = ValidationContextFactory.create(config_path)
          context.skip_optional_checks = true
          context.include_performance_checks = false
          @context = context

          config_result = load_and_validate_config(config_path, context)
          return config_result unless config_result.passed

          overall_result = ValidationResult.new
          overall_result.merge(config_result)

          # Run only critical validators
          critical_validators = @validators.select { |v| v.priority <= 30 }
          critical_validators.each do |validator|
            next unless validator.should_run?(context)

            validator_result = validator.validate(@config.not_nil!, context)
            overall_result.merge(validator_result)
          end

          overall_result
        end

        # Validates only configuration without running full validation
        def validate_config_only(config_path : String) : ValidationResult
          context = ValidationContextFactory.create(config_path)
          load_and_validate_config(config_path, context)
        end

        private def setup_default_validators
          # Add built-in validators in priority order
          @validators << PlatformInfoValidator.new
          @validators << AssetValidationChecker.new
          @validators << SecurityValidationChecker.new
          @validators << RenderingValidationChecker.new
          @validators << PerformanceValidationChecker.new
        end

        private def load_and_validate_config(config_path : String, context : ValidationContext) : ValidationResult
          result = ValidationResult.new

          puts "\n1. Checking game configuration..."

          # Check if file exists
          unless File.exists?(config_path)
            result.add_error("Configuration file not found: #{config_path}")
            return result
          end

          begin
            # Load configuration
            yaml_content = File.read(config_path)
            config = GameConfig.from_yaml(yaml_content)
            config.config_base_dir = File.dirname(config_path)
            @config = config

            result.add_info("✓ Configuration loaded successfully")

            # Run config validation
            validation_errors = Validators::ConfigValidator.validate(config, config_path)
            unless validation_errors.empty?
              validation_errors.each do |error|
                if error.includes?("matches no files") || error.includes?("not found in asset patterns")
                  result.add_warning(error)
                else
                  result.add_error(error)
                end
              end
            end

            # Validate all assets
            asset_errors = Validators::AssetValidator.validate_all_assets(config, config_path)
            if asset_errors.empty?
              result.add_info("✓ All assets validated")
            else
              result.add_errors(asset_errors)
            end

            # Validate scenes
            validate_scenes(config, config_path, result)

            # Validate scene coordinates
            validate_scene_coordinates(config, result)
          rescue ex : YAML::ParseException
            result.add_error("Invalid YAML syntax: #{ex.message}")
          rescue ex
            result.add_error("Unexpected error loading config: #{ex.message}")
          end

          result
        end

        private def validate_scenes(config : GameConfig, config_path : String, result : ValidationResult)
          puts "\n3. Checking scene files..."
          scene_count = 0
          scene_errors = [] of String

          if assets = config.assets
            assets.scenes.each do |pattern|
              Dir.glob(File.join(File.dirname(config_path), pattern)).each do |scene_path|
                scene_count += 1
                errors = Validators::SceneValidator.validate_scene_file(scene_path)
                unless errors.empty?
                  scene_errors << "Scene '#{File.basename(scene_path)}':"
                  errors.each { |e| scene_errors << "  - #{e}" }
                end
              end
            end
          end

          if scene_errors.empty?
            result.add_info("✓ #{scene_count} scene(s) validated")
          else
            result.add_errors(scene_errors)
          end
        end

        private def validate_scene_coordinates(config : GameConfig, result : ValidationResult)
          puts "\n3.5. Checking scene coordinate consistency..."
          coord_validator = Validators::SceneCoordinateValidator.new
          coord_result = coord_validator.validate(config)

          result.add_errors(coord_result.errors)
          result.add_warnings(coord_result.warnings)
          result.add_infos(coord_result.infos)
        end

        private def get_step_number(validator : BaseValidator) : Int32
          # Calculate step number based on validator priority and position
          sorted_validators = @validators.sort_by(&.priority)
          base_step = 4 # Steps 1-3 are config, assets, scenes

          index = sorted_validators.index(validator)
          return base_step + (index || 0) + 1
        end

        private def add_validation_summary(result : ValidationResult, context : ValidationContext)
          # Add context information
          result.add_info("Validation completed for: #{File.basename(context.config_path)}")
          result.add_info("Base directory: #{context.base_dir}")

          if context.strict_mode
            result.add_info("Strict mode: enabled")
          end

          if context.development_mode
            result.add_info("Development mode: enabled")
          end

          # Add performance summary if available
          if context.include_performance_checks && @config
            performance_validator = @validators.find { |v| v.is_a?(PerformanceValidationChecker) }
            if performance_validator.is_a?(PerformanceValidationChecker)
              estimates = performance_validator.get_performance_estimates(@config.not_nil!, context)
              if estimates.any?
                result.add_info("Performance estimates:")
                estimates.each do |key, value|
                  # Convert underscore_case to human readable format
                  humanized_key = key.gsub('_', ' ').split.map(&.capitalize).join(' ')
                  result.add_info("  #{humanized_key}: #{value}")
                end
              end
            end
          end
        end

        # Creates a validation report
        def create_report(result : ValidationResult, format : String = "text") : String
          case format
          when "text"
            create_text_report(result)
          when "json"
            create_json_report(result)
          when "markdown"
            create_markdown_report(result)
          else
            create_text_report(result)
          end
        end

        private def create_text_report(result : ValidationResult) : String
          report = String::Builder.new

          report << "VALIDATION REPORT\n"
          report << "=" * 50 << "\n\n"
          report << "Status: #{result.passed ? "PASSED" : "FAILED"}\n"
          report << "Total Issues: #{result.issue_count}\n\n"

          if result.errors.any?
            report << "ERRORS (#{result.errors.size}):\n"
            result.errors.each { |error| report << "  ❌ #{error}\n" }
            report << "\n"
          end

          if result.warnings.any?
            report << "WARNINGS (#{result.warnings.size}):\n"
            result.warnings.each { |warning| report << "  ⚠️  #{warning}\n" }
            report << "\n"
          end

          if result.security_issues.any?
            report << "SECURITY ISSUES (#{result.security_issues.size}):\n"
            result.security_issues.each { |issue| report << "  🔒 #{issue}\n" }
            report << "\n"
          end

          if result.performance_hints.any?
            report << "PERFORMANCE HINTS (#{result.performance_hints.size}):\n"
            result.performance_hints.each { |hint| report << "  💡 #{hint}\n" }
            report << "\n"
          end

          if result.info.any?
            report << "INFORMATION (#{result.info.size}):\n"
            result.info.each { |info| report << "  ℹ️  #{info}\n" }
          end

          report.to_s
        end

        private def create_json_report(result : ValidationResult) : String
          {
            "status"            => result.passed ? "passed" : "failed",
            "summary"           => result.summary,
            "errors"            => result.errors,
            "warnings"          => result.warnings,
            "security_issues"   => result.security_issues,
            "performance_hints" => result.performance_hints,
            "info"              => result.info,
            "total_issues"      => result.issue_count,
          }.to_json
        end

        private def create_markdown_report(result : ValidationResult) : String
          report = String::Builder.new

          report << "# Validation Report\n\n"
          report << "**Status:** #{result.passed ? "✅ PASSED" : "❌ FAILED"}\n"
          report << "**Total Issues:** #{result.issue_count}\n\n"

          if result.errors.any?
            report << "## ❌ Errors (#{result.errors.size})\n\n"
            result.errors.each { |error| report << "- #{error}\n" }
            report << "\n"
          end

          if result.warnings.any?
            report << "## ⚠️ Warnings (#{result.warnings.size})\n\n"
            result.warnings.each { |warning| report << "- #{warning}\n" }
            report << "\n"
          end

          if result.security_issues.any?
            report << "## 🔒 Security Issues (#{result.security_issues.size})\n\n"
            result.security_issues.each { |issue| report << "- #{issue}\n" }
            report << "\n"
          end

          if result.performance_hints.any?
            report << "## 💡 Performance Hints (#{result.performance_hints.size})\n\n"
            result.performance_hints.each { |hint| report << "- #{hint}\n" }
            report << "\n"
          end

          report.to_s
        end
      end
    end
  end
end
