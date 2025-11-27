# Type-Safe Condition System
#
# Provides compile-time checked conditions as an alternative to string-based
# conditions. Works alongside the existing string parser for YAML compatibility.
#
# Example usage:
# ```
# # Using the builder
# can_enter = Conditions.build do |c|
#   c.flag("has_key")
#    .and
#    .quest("find_treasure").is_active
#    .and
#    .var("player_level").>=(5)
# end
#
# result = can_enter.evaluate(game_state_manager)
# puts result.success  # => true/false
# puts result.message  # => explains why
# ```

require "../game_state_manager"

module PointClickEngine
  module Core
    module Conditions
      # Result of evaluating a condition
      struct ConditionResult
        getter success : Bool
        getter message : String

        def initialize(@success : Bool, @message : String = "")
        end

        def to_s : String
          "#{@success ? "✓" : "✗"} #{@message}"
        end
      end

      # Base module for all conditions
      module Condition
        abstract def evaluate(state : GameStateManager) : ConditionResult
        abstract def to_s : String
      end

      # Always true condition
      struct TrueCondition
        include Condition

        def evaluate(state : GameStateManager) : ConditionResult
          ConditionResult.new(true, "Always true")
        end

        def to_s : String
          "true"
        end
      end

      # Always false condition
      struct FalseCondition
        include Condition

        def evaluate(state : GameStateManager) : ConditionResult
          ConditionResult.new(false, "Always false")
        end

        def to_s : String
          "false"
        end
      end

      # Flag condition - checks if a boolean flag is set
      struct FlagCondition
        include Condition

        getter name : String
        getter expected : Bool

        def initialize(@name : String, @expected : Bool = true)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          actual = state.get_flag(@name)
          success = actual == @expected
          message = if @expected
                      success ? "Flag '#{@name}' is set" : "Flag '#{@name}' is not set"
                    else
                      success ? "Flag '#{@name}' is not set" : "Flag '#{@name}' is set"
                    end
          ConditionResult.new(success, message)
        end

        def to_s : String
          @expected ? @name : "!#{@name}"
        end
      end

      # Variable comparison condition
      struct VariableCondition
        include Condition

        enum Operator
          Equal
          NotEqual
          GreaterThan
          GreaterOrEqual
          LessThan
          LessOrEqual
        end

        getter name : String
        getter operator : Operator
        getter value : Int32 | Float32 | String | Bool

        def initialize(@name : String, @operator : Operator, @value : Int32 | Float32 | String | Bool)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          actual = state.get_variable(@name)
          return ConditionResult.new(false, "Variable '#{@name}' not found") unless actual

          success = compare(actual, @operator, @value)
          ConditionResult.new(success, "#{@name} (#{actual}) #{operator_str} #{@value}")
        end

        private def compare(actual : GameValue, op : Operator, expected : Int32 | Float32 | String | Bool) : Bool
          case {actual, expected}
          when {Int32, Int32}
            compare_numeric(actual.to_f32, op, expected.to_f32)
          when {Int32, Float32}
            compare_numeric(actual.to_f32, op, expected)
          when {Float32, Int32}
            compare_numeric(actual, op, expected.to_f32)
          when {Float32, Float32}
            compare_numeric(actual, op, expected)
          when {String, String}
            compare_string(actual, op, expected)
          when {Bool, Bool}
            compare_bool(actual, op, expected)
          else
            # Type mismatch - try string comparison
            actual.to_s == expected.to_s && op.equal?
          end
        end

        private def compare_numeric(a : Float32, op : Operator, b : Float32) : Bool
          case op
          when .equal?            then a == b
          when .not_equal?        then a != b
          when .greater_than?     then a > b
          when .greater_or_equal? then a >= b
          when .less_than?        then a < b
          when .less_or_equal?    then a <= b
          else                         false
          end
        end

        private def compare_string(a : String, op : Operator, b : String) : Bool
          case op
          when .equal?     then a == b
          when .not_equal? then a != b
          else                  false # Other operators don't make sense for strings
          end
        end

        private def compare_bool(a : Bool, op : Operator, b : Bool) : Bool
          case op
          when .equal?     then a == b
          when .not_equal? then a != b
          else                  false
          end
        end

        private def operator_str : String
          case @operator
          when .equal?            then "=="
          when .not_equal?        then "!="
          when .greater_than?     then ">"
          when .greater_or_equal? then ">="
          when .less_than?        then "<"
          when .less_or_equal?    then "<="
          else                         "?"
          end
        end

        def to_s : String
          "#{@name} #{operator_str} #{@value}"
        end
      end

      # Quest condition
      struct QuestCondition
        include Condition

        enum Status
          Active
          Completed
          AtStep
        end

        getter quest_id : String
        getter status : Status
        getter step : String?

        def initialize(@quest_id : String, @status : Status, @step : String? = nil)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          success = case @status
                    when .active?
                      state.is_quest_active?(@quest_id)
                    when .completed?
                      state.is_quest_completed?(@quest_id)
                    when .at_step?
                      state.get_quest_step(@quest_id) == @step
                    else
                      false
                    end

          message = case @status
                    when .at_step?
                      actual_step = state.get_quest_step(@quest_id)
                      "Quest '#{@quest_id}' at step '#{actual_step}' (expected '#{@step}')"
                    else
                      "Quest '#{@quest_id}' #{@status.to_s.downcase}: #{success}"
                    end

          ConditionResult.new(success, message)
        end

        def to_s : String
          case @status
          when .at_step? then "quest:#{@quest_id}:#{@step}"
          else                "quest:#{@quest_id}:#{@status.to_s.downcase}"
          end
        end
      end

      # Time of day condition
      struct TimeCondition
        include Condition

        enum Period
          Day
          Night
          Morning
          Afternoon
          Evening
        end

        getter period : Period

        def initialize(@period : Period)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          success = case @period
                    when .day?       then state.is_day?
                    when .night?     then state.is_night?
                    when .morning?   then state.get_time_of_day == "morning"
                    when .afternoon? then state.get_time_of_day == "afternoon"
                    when .evening?   then state.get_time_of_day == "evening"
                    else                  false
                    end

          actual_time = state.get_time_of_day
          ConditionResult.new(success, "Time is #{actual_time} (expected #{@period.to_s.downcase})")
        end

        def to_s : String
          "time:#{@period.to_s.downcase}"
        end
      end

      # Achievement condition
      struct AchievementCondition
        include Condition

        getter achievement_id : String
        getter unlocked : Bool

        def initialize(@achievement_id : String, @unlocked : Bool = true)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          actual = state.is_achievement_unlocked?(@achievement_id)
          success = actual == @unlocked
          message = if @unlocked
                      success ? "Achievement '#{@achievement_id}' is unlocked" : "Achievement '#{@achievement_id}' is not unlocked"
                    else
                      success ? "Achievement '#{@achievement_id}' is not unlocked" : "Achievement '#{@achievement_id}' is unlocked"
                    end
          ConditionResult.new(success, message)
        end

        def to_s : String
          @unlocked ? "achievement:#{@achievement_id}" : "!achievement:#{@achievement_id}"
        end
      end
    end
  end
end
