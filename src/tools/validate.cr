#!/usr/bin/env crystal

# Condition Validator CLI Tool
#
# Validates all condition strings in YAML files before running the game.
# This helps catch typos and errors in game configuration early.
#
# Usage:
#   crystal src/tools/validate.cr [options] [paths...]
#
# Options:
#   -v, --verbose    Show all validation details
#   -s, --strict     Treat warnings as errors
#   -c, --config     Path to game config file for identifier registration
#   -f, --format     Output format: text (default), json
#   -h, --help       Show this help
#
# Examples:
#   crystal src/tools/validate.cr scenes/
#   crystal src/tools/validate.cr -v -s scenes/ dialogs/
#   crystal src/tools/validate.cr -c config/game.yaml scenes/

require "option_parser"
require "yaml"
require "json"
require "../core/conditions/conditions"

module PointClickEngine
  module Tools
    class ValidatorCLI
      @verbose = false
      @strict = false
      @paths = [] of String
      @config_path : String? = nil
      @output_format = "text" # text, json

      def run(args : Array(String))
        parse_args(args)

        if @paths.empty?
          @paths = ["scenes/", "quests/", "dialogs/"] # Default paths
        end

        validator = Core::Conditions::ConditionValidator.new

        # Load known identifiers from config
        if config = @config_path
          load_config(config, validator)
        end

        results = validate_all_files(validator)
        output_results(results)

        # Exit with error code if any errors found
        has_errors = results.any? { |r| !r[:result].valid? }
        has_warnings = @strict && results.any? { |r| !r[:result].warnings.empty? }
        exit(1) if has_errors || has_warnings
      end

      private def parse_args(args : Array(String))
        OptionParser.parse(args) do |parser|
          parser.banner = "Usage: validate [options] [paths...]"

          parser.on("-v", "--verbose", "Show all validation details") { @verbose = true }
          parser.on("-s", "--strict", "Treat warnings as errors") { @strict = true }
          parser.on("-c CONFIG", "--config=CONFIG", "Path to game config file") { |c| @config_path = c }
          parser.on("-f FORMAT", "--format=FORMAT", "Output format: text, json") { |f| @output_format = f }
          parser.on("-h", "--help", "Show this help") do
            puts parser
            exit
          end

          parser.unknown_args do |paths|
            @paths = paths unless paths.empty?
          end
        end
      end

      private def load_config(path : String, validator : Core::Conditions::ConditionValidator)
        return unless File.exists?(path)

        begin
          yaml = YAML.parse(File.read(path))

          # Try to extract known identifiers from config
          if flags = yaml["flags"]?
            if flags_hash = flags.as_h?
              flags_hash.each_key { |k| validator.register_flag(k.to_s) }
            elsif flags_arr = flags.as_a?
              flags_arr.each { |f| validator.register_flag(f.to_s) }
            end
          end

          if variables = yaml["variables"]?
            if vars_hash = variables.as_h?
              vars_hash.each_key { |k| validator.register_variable(k.to_s) }
            elsif vars_arr = variables.as_a?
              vars_arr.each { |v| validator.register_variable(v.to_s) }
            end
          end

          if quests = yaml["quests"]?
            if quests_hash = quests.as_h?
              quests_hash.each_key { |k| validator.register_quest(k.to_s) }
            elsif quests_arr = quests.as_a?
              quests_arr.each { |q| validator.register_quest(q.to_s) }
            end
          end

          if achievements = yaml["achievements"]?
            if ach_hash = achievements.as_h?
              ach_hash.each_key { |k| validator.register_achievement(k.to_s) }
            elsif ach_arr = achievements.as_a?
              ach_arr.each { |a| validator.register_achievement(a.to_s) }
            end
          end

          puts "Loaded config from #{path}" if @verbose
        rescue ex
          puts "Warning: Could not load config from #{path}: #{ex.message}"
        end
      end

      private def validate_all_files(validator : Core::Conditions::ConditionValidator) : Array(NamedTuple(file: String, result: Core::Conditions::ConditionValidationResult))
        results = [] of NamedTuple(file: String, result: Core::Conditions::ConditionValidationResult)

        @paths.each do |path|
          if File.directory?(path)
            Dir.glob(File.join(path, "**/*.yaml")) do |file|
              results.concat(validate_yaml_file(file, validator))
            end
            Dir.glob(File.join(path, "**/*.yml")) do |file|
              results.concat(validate_yaml_file(file, validator))
            end
          elsif File.exists?(path)
            results.concat(validate_yaml_file(path, validator))
          else
            puts "Warning: Path not found: #{path}" if @verbose
          end
        end

        results
      end

      private def validate_yaml_file(path : String, validator : Core::Conditions::ConditionValidator) : Array(NamedTuple(file: String, result: Core::Conditions::ConditionValidationResult))
        results = [] of NamedTuple(file: String, result: Core::Conditions::ConditionValidationResult)

        begin
          content = File.read(path)
          yaml = YAML.parse(content)

          # Extract all condition strings from YAML
          conditions = extract_conditions(yaml, path)

          puts "Found #{conditions.size} conditions in #{path}" if @verbose && !conditions.empty?

          conditions.each do |condition_info|
            result = validator.validate(
              condition_info[:condition],
              condition_info[:file],
              condition_info[:line]
            )

            # In strict mode, warnings become errors
            if @strict
              result.warnings.each do |warning|
                result.add_error(warning.type, warning.message, warning.position, warning.suggestion)
              end
            end

            # Only add to results if there are issues
            if !result.valid? || !result.warnings.empty?
              results << {file: path, result: result}
            elsif @verbose
              puts "  ✓ #{condition_info[:condition]}"
            end
          end
        rescue ex
          puts "Error parsing #{path}: #{ex.message}"
        end

        results
      end

      private def extract_conditions(yaml : YAML::Any, file : String, line_offset : Int32 = 0) : Array(NamedTuple(condition: String, file: String, line: Int32))
        conditions = [] of NamedTuple(condition: String, file: String, line: Int32)

        case yaml.raw
        when Hash
          yaml.as_h.each do |key, value|
            key_str = key.to_s

            # Look for condition fields
            if key_str == "condition" || key_str == "start_condition" || key_str == "unlock_condition" ||
               key_str == "visible_condition" || key_str == "enabled_condition" || key_str == "requirements"
              if cond = value.as_s?
                conditions << {condition: cond, file: file, line: line_offset}
              end
            end

            # Recurse into nested structures
            conditions.concat(extract_conditions(value, file, line_offset))
          end
        when Array
          yaml.as_a.each_with_index do |item, index|
            conditions.concat(extract_conditions(item, file, line_offset + index))
          end
        end

        conditions
      end

      private def output_results(results : Array(NamedTuple(file: String, result: Core::Conditions::ConditionValidationResult)))
        case @output_format
        when "json"
          output_json(results)
        else
          output_text(results)
        end
      end

      private def output_text(results : Array(NamedTuple(file: String, result: Core::Conditions::ConditionValidationResult)))
        if results.empty?
          puts "✓ All conditions validated successfully!"
          return
        end

        error_count = results.count { |r| !r[:result].valid? }
        warning_count = results.sum { |r| r[:result].warnings.size }

        puts "Validation Results:"
        puts "=" * 60

        results.each do |entry|
          puts entry[:result].format_errors
          puts "-" * 40
        end

        puts "=" * 60
        puts "Summary: #{error_count} error(s), #{warning_count} warning(s)"
      end

      private def output_json(results : Array(NamedTuple(file: String, result: Core::Conditions::ConditionValidationResult)))
        output = {
          "valid"    => results.all? { |r| r[:result].valid? },
          "errors"   => results.flat_map { |entry|
            entry[:result].errors.map { |error|
              {
                "file"       => entry[:file],
                "condition"  => entry[:result].condition_string,
                "type"       => error.type.to_s,
                "message"    => error.message,
                "suggestion" => error.suggestion,
              }
            }
          },
          "warnings" => results.flat_map { |entry|
            entry[:result].warnings.map { |warning|
              {
                "file"       => entry[:file],
                "condition"  => entry[:result].condition_string,
                "type"       => warning.type.to_s,
                "message"    => warning.message,
                "suggestion" => warning.suggestion,
              }
            }
          },
        }

        puts output.to_json
      end
    end
  end
end

# Run the CLI
PointClickEngine::Tools::ValidatorCLI.new.run(ARGV)
