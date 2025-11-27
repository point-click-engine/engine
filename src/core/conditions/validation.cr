# Condition Validation Result
#
# Provides detailed validation results for conditions with helpful error messages.
# Used by the ConditionValidator to report parsing and semantic errors.

module PointClickEngine
  module Core
    module Conditions
      # Detailed validation result for conditions
      class ConditionValidationResult
        enum ErrorType
          SyntaxError        # Malformed condition string
          UnknownFlag        # Flag not registered
          UnknownVariable    # Variable not registered
          UnknownQuest       # Quest ID not found
          UnknownAchievement # Achievement ID not found
          TypeMismatch       # Comparing incompatible types
          InvalidOperator    # Unknown operator
          UnbalancedParens   # Mismatched parentheses
        end

        record Error,
          type : ErrorType,
          message : String,
          position : Int32?,     # Character position in string
          suggestion : String?   # "Did you mean...?"

        getter errors : Array(Error)
        getter warnings : Array(Error)
        getter condition_string : String
        getter source_file : String?
        getter source_line : Int32?

        def initialize(@condition_string : String, @source_file : String? = nil, @source_line : Int32? = nil)
          @errors = [] of Error
          @warnings = [] of Error
        end

        def valid? : Bool
          @errors.empty?
        end

        def add_error(type : ErrorType, message : String, position : Int32? = nil, suggestion : String? = nil)
          @errors << Error.new(type, message, position, suggestion)
        end

        def add_warning(type : ErrorType, message : String, position : Int32? = nil, suggestion : String? = nil)
          @warnings << Error.new(type, message, position, suggestion)
        end

        # Format errors for display
        def format_errors : String
          return "Valid" if valid?

          String.build do |str|
            str << "Condition validation failed:\n"
            str << "  Condition: \"#{@condition_string}\"\n"

            if @source_file
              str << "  File: #{@source_file}"
              str << ":#{@source_line}" if @source_line
              str << "\n"
            end

            str << "\n  Errors:\n"
            @errors.each do |error|
              str << "    - [#{error.type}] #{error.message}\n"

              if pos = error.position
                # Show position indicator
                str << "      \"#{@condition_string}\"\n"
                str << "       " << " " * pos << "^\n"
              end

              if suggestion = error.suggestion
                str << "      Did you mean: #{suggestion}\n"
              end
            end

            unless @warnings.empty?
              str << "\n  Warnings:\n"
              @warnings.each do |warning|
                str << "    - #{warning.message}\n"
              end
            end
          end
        end

        # Convert to JSON-serializable format
        def to_h : Hash(String, String | Bool | Array(Hash(String, String | Int32 | Nil)))
          {
            "valid"     => valid?,
            "condition" => @condition_string,
            "file"      => @source_file || "",
            "line"      => @source_line.to_s,
            "errors"    => @errors.map { |e|
              {
                "type"       => e.type.to_s,
                "message"    => e.message,
                "position"   => e.position,
                "suggestion" => e.suggestion,
              }
            },
            "warnings" => @warnings.map { |w|
              {
                "type"       => w.type.to_s,
                "message"    => w.message,
                "position"   => w.position,
                "suggestion" => w.suggestion,
              }
            },
          }
        end
      end
    end
  end
end
