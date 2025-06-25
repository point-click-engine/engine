module PointClickEngine
  module Core
    module Validation
      # Comprehensive result structure for validation operations
      #
      # The ValidationResult struct provides a standardized way to collect
      # and report validation outcomes across different validation components.
      # It supports multiple severity levels and different types of feedback.
      struct ValidationResult
        # Overall validation status
        property passed : Bool = true

        # Different severity levels of issues
        property errors : Array(String) = [] of String
        property warnings : Array(String) = [] of String
        property info : Array(String) = [] of String

        # Specialized feedback types
        property performance_hints : Array(String) = [] of String
        property security_issues : Array(String) = [] of String

        def initialize(@passed = true)
        end

        # Adds an error and marks validation as failed
        def add_error(message : String)
          @errors << message
          @passed = false
        end

        # Adds multiple errors and marks validation as failed
        def add_errors(messages : Array(String))
          @errors.concat(messages)
          @passed = false unless messages.empty?
        end

        # Adds a warning (doesn't affect passed status)
        def add_warning(message : String)
          @warnings << message
        end

        # Adds multiple warnings
        def add_warnings(messages : Array(String))
          @warnings.concat(messages)
        end

        # Adds an informational message
        def add_info(message : String)
          @info << message
        end

        # Adds multiple informational messages
        def add_infos(messages : Array(String))
          @info.concat(messages)
        end

        # Adds a performance hint
        def add_performance_hint(message : String)
          @performance_hints << message
        end

        # Adds a security issue
        def add_security_issue(message : String)
          @security_issues << message
        end

        # Merges another validation result into this one
        def merge(other : ValidationResult)
          @passed = @passed && other.passed
          @errors.concat(other.errors)
          @warnings.concat(other.warnings)
          @info.concat(other.info)
          @performance_hints.concat(other.performance_hints)
          @security_issues.concat(other.security_issues)
        end

        # Checks if there are any issues at all
        def has_issues? : Bool
          !@errors.empty? || !@warnings.empty? || !@security_issues.empty?
        end

        # Checks if there are critical issues
        def has_critical_issues? : Bool
          !@errors.empty? || !@security_issues.empty?
        end

        # Gets total count of all messages
        def total_message_count : Int32
          @errors.size + @warnings.size + @info.size + @performance_hints.size + @security_issues.size
        end

        # Gets count of issues (errors, warnings, security issues)
        def issue_count : Int32
          @errors.size + @warnings.size + @security_issues.size
        end

        # Creates a summary string
        def summary : String
          parts = [] of String

          if @passed
            parts << "PASSED"
          else
            parts << "FAILED"
          end

          if !@errors.empty?
            parts << "#{@errors.size} error(s)"
          end

          if !@warnings.empty?
            parts << "#{@warnings.size} warning(s)"
          end

          if !@security_issues.empty?
            parts << "#{@security_issues.size} security issue(s)"
          end

          if !@performance_hints.empty?
            parts << "#{@performance_hints.size} performance hint(s)"
          end

          parts.join(", ")
        end

        # String representation
        def to_s(io : IO) : Nil
          io << "ValidationResult(#{summary})"
        end
      end

      # Base interface for all validation components
      #
      # All validators should inherit from this abstract class to ensure
      # consistent interfaces and behavior across the validation system.
      abstract class BaseValidator
        # Validates the given configuration and context
        abstract def validate(config : GameConfig, context : ValidationContext) : ValidationResult

        # Gets the name of this validator for reporting
        def name : String
          self.class.name.split("::").last
        end

        # Gets a description of what this validator checks
        abstract def description : String

        # Checks if this validator should run in the current context
        def should_run?(context : ValidationContext) : Bool
          true
        end

        # Priority for ordering validators (lower numbers run first)
        def priority : Int32
          100
        end
      end

      # Context information for validation operations
      #
      # The ValidationContext provides shared state and configuration
      # that validators can use to make decisions and access resources.
      class ValidationContext
        property config_path : String
        property base_dir : String
        property strict_mode : Bool = false
        property development_mode : Bool = false
        property skip_optional_checks : Bool = false
        property max_warnings : Int32 = 100
        property include_performance_checks : Bool = true
        property include_security_checks : Bool = true

        # Cached data that validators can share
        property cache : Hash(String, String | Int32 | Bool | Array(String)) = {} of String => String | Int32 | Bool | Array(String)

        def initialize(@config_path : String)
          @base_dir = File.dirname(@config_path)
        end

        # Resolves a path relative to the configuration base directory
        def resolve_path(path : String) : String
          if Path[path].absolute?
            path
          else
            File.join(@base_dir, path)
          end
        end

        # Checks if a file exists relative to base directory
        def file_exists?(path : String) : Bool
          File.exists?(resolve_path(path))
        end

        # Gets file size for a path relative to base directory
        def file_size(path : String) : Int64?
          full_path = resolve_path(path)
          File.exists?(full_path) ? File.size(full_path) : nil
        end

        # Caches a value for sharing between validators
        def cache_set(key : String, value : String | Int32 | Bool | Array(String))
          @cache[key] = value
        end

        # Retrieves a cached value
        def cache_get(key : String, default = nil)
          @cache.fetch(key, default)
        end

        # Checks if a key exists in cache
        def cache_has?(key : String) : Bool
          @cache.has_key?(key)
        end

        # String representation
        def to_s(io : IO) : Nil
          io << "ValidationContext(config: #{File.basename(@config_path)}, base_dir: #{@base_dir})"
        end
      end

      # Factory for creating validation contexts
      module ValidationContextFactory
        def self.create(config_path : String, strict_mode : Bool = false, development_mode : Bool = false) : ValidationContext
          context = ValidationContext.new(config_path)
          context.strict_mode = strict_mode
          context.development_mode = development_mode
          context
        end

        def self.create_development(config_path : String) : ValidationContext
          create(config_path, strict_mode: false, development_mode: true)
        end

        def self.create_production(config_path : String) : ValidationContext
          context = create(config_path, strict_mode: true, development_mode: false)
          context.skip_optional_checks = true
          context.include_performance_checks = false
          context
        end
      end
    end
  end
end
