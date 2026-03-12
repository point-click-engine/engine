# Condition Builder DSL
#
# Provides a fluent interface for building conditions with compile-time type safety.
#
# Example usage:
# ```
# # Simple flag check
# condition = ConditionBuilder.new
#   .flag("door_unlocked")
#   .build
#
# # Complex condition
# condition = ConditionBuilder.new
#   .flag("has_key")
#   .and
#   .var("gold").>=(100)
#   .and
#   .quest("main").is_active
#   .build
#
# # Check condition
# result = condition.evaluate(state_manager)
# ```

require "./condition"
require "./composite"

module PointClickEngine
  module Core
    module Conditions
      # Fluent condition builder
      class ConditionBuilder
        @conditions : Array(ConditionWrapper) = [] of ConditionWrapper
        @combine_with : Symbol = :and

        # Flag conditions
        def flag(name : String, expected : Bool = true) : self
          @conditions << ConditionWrapper.new(FlagCondition.new(name, expected))
          self
        end

        def flag_set(name : String) : self
          flag(name, true)
        end

        def flag_not_set(name : String) : self
          flag(name, false)
        end

        # Variable conditions - returns a sub-builder
        def var(name : String) : VariableConditionBuilder
          VariableConditionBuilder.new(self, name)
        end

        def variable(name : String) : VariableConditionBuilder
          var(name)
        end

        # Quest conditions - returns a sub-builder
        def quest(id : String) : QuestConditionBuilder
          QuestConditionBuilder.new(self, id)
        end

        # Time conditions
        def time_is(period : TimeCondition::Period) : self
          @conditions << ConditionWrapper.new(TimeCondition.new(period))
          self
        end

        def is_day : self
          time_is(TimeCondition::Period::Day)
        end

        def is_night : self
          time_is(TimeCondition::Period::Night)
        end

        def is_morning : self
          time_is(TimeCondition::Period::Morning)
        end

        def is_afternoon : self
          time_is(TimeCondition::Period::Afternoon)
        end

        def is_evening : self
          time_is(TimeCondition::Period::Evening)
        end

        # Achievement conditions
        def achievement(id : String, unlocked : Bool = true) : self
          @conditions << ConditionWrapper.new(AchievementCondition.new(id, unlocked))
          self
        end

        def achievement_unlocked(id : String) : self
          achievement(id, true)
        end

        def achievement_locked(id : String) : self
          achievement(id, false)
        end

        # Combinators
        def and : self
          @combine_with = :and
          self
        end

        def or : self
          @combine_with = :or
          self
        end

        # Add a raw condition
        def add(condition : FlagCondition | VariableCondition | QuestCondition | TimeCondition | AchievementCondition | TrueCondition | FalseCondition | AndCondition | OrCondition | NotCondition) : self
          @conditions << ConditionWrapper.new(condition)
          self
        end

        # Build the final condition
        def build : ConditionWrapper
          case @conditions.size
          when 0
            ConditionWrapper.new(TrueCondition.new)
          when 1
            @conditions.first
          else
            case @combine_with
            when :and
              ConditionWrapper.new(AndCondition.new(@conditions))
            when :or
              ConditionWrapper.new(OrCondition.new(@conditions))
            else
              ConditionWrapper.new(AndCondition.new(@conditions))
            end
          end
        end

        # Direct evaluation shortcut
        def check(state : GameStateManager) : Bool
          build.evaluate(state).success
        end

        def evaluate(state : GameStateManager) : ConditionResult
          build.evaluate(state)
        end

        # Class method for starting builder with block
        def self.build(&block : ConditionBuilder ->) : ConditionWrapper
          builder = new
          yield builder
          builder.build
        end
      end

      # Sub-builder for variable conditions
      class VariableConditionBuilder
        def initialize(@parent : ConditionBuilder, @name : String)
        end

        def equals(value : Int32 | Float32 | String | Bool) : ConditionBuilder
          add_condition(VariableCondition::Operator::Equal, value)
        end

        def not_equals(value : Int32 | Float32 | String | Bool) : ConditionBuilder
          add_condition(VariableCondition::Operator::NotEqual, value)
        end

        def greater_than(value : Int32 | Float32) : ConditionBuilder
          add_condition(VariableCondition::Operator::GreaterThan, value)
        end

        def greater_or_equal(value : Int32 | Float32) : ConditionBuilder
          add_condition(VariableCondition::Operator::GreaterOrEqual, value)
        end

        def less_than(value : Int32 | Float32) : ConditionBuilder
          add_condition(VariableCondition::Operator::LessThan, value)
        end

        def less_or_equal(value : Int32 | Float32) : ConditionBuilder
          add_condition(VariableCondition::Operator::LessOrEqual, value)
        end

        # Operator aliases
        def ==(value : Int32 | Float32 | String | Bool) : ConditionBuilder
          equals(value)
        end

        def !=(value : Int32 | Float32 | String | Bool) : ConditionBuilder
          not_equals(value)
        end

        def >(value : Int32 | Float32) : ConditionBuilder
          greater_than(value)
        end

        def >=(value : Int32 | Float32) : ConditionBuilder
          greater_or_equal(value)
        end

        def <(value : Int32 | Float32) : ConditionBuilder
          less_than(value)
        end

        def <=(value : Int32 | Float32) : ConditionBuilder
          less_or_equal(value)
        end

        private def add_condition(op : VariableCondition::Operator, value : Int32 | Float32 | String | Bool) : ConditionBuilder
          @parent.add(VariableCondition.new(@name, op, value))
          @parent
        end
      end

      # Sub-builder for quest conditions
      class QuestConditionBuilder
        def initialize(@parent : ConditionBuilder, @quest_id : String)
        end

        def is_active : ConditionBuilder
          @parent.add(QuestCondition.new(@quest_id, QuestCondition::Status::Active))
          @parent
        end

        def is_completed : ConditionBuilder
          @parent.add(QuestCondition.new(@quest_id, QuestCondition::Status::Completed))
          @parent
        end

        def at_step(step : String) : ConditionBuilder
          @parent.add(QuestCondition.new(@quest_id, QuestCondition::Status::AtStep, step))
          @parent
        end
      end
    end
  end
end
