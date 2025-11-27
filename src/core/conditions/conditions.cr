# Conditions Module
#
# Type-safe condition system for game logic.
#
# This module provides:
# - Type-safe condition types (FlagCondition, VariableCondition, etc.)
# - Composite conditions (AND, OR, NOT)
# - Fluent builder DSL
# - String parser for YAML compatibility
#
# Example usage:
# ```
# require "./conditions/conditions"
#
# # Using the builder
# condition = Conditions::ConditionBuilder.build do |c|
#   c.flag("has_key")
#    .and
#    .var("gold").>=(100)
# end
#
# # Using the parser
# condition = Conditions::ConditionParser.parse!("has_key && gold >= 100")
#
# # Evaluate
# result = condition.evaluate(game_state_manager)
# puts result.success  # => true/false
# ```

require "./condition"
require "./composite"
require "./builder"
require "./parser"
require "./validation"
require "./validator"

module PointClickEngine
  module Core
    module Conditions
      VERSION = "1.0.0"

      # Convenience method to build a condition
      def self.build(&block : ConditionBuilder ->) : ConditionWrapper
        ConditionBuilder.build(&block)
      end

      # Convenience method to parse a string condition
      def self.parse(condition_string : String) : Result(ConditionWrapper, String)
        ConditionParser.parse(condition_string)
      end

      # Convenience method to parse a string condition (raises on error)
      def self.parse!(condition_string : String) : ConditionWrapper
        ConditionParser.parse!(condition_string)
      end
    end
  end
end
