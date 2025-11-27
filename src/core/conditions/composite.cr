# Composite Conditions
#
# Provides AND, OR, and NOT combinators for building complex conditions.

require "./condition"

module PointClickEngine
  module Core
    module Conditions
      # Wrapper class for conditions to enable polymorphism
      # Crystal structs can't be stored in arrays polymorphically,
      # so we use this wrapper class
      class ConditionWrapper
        include Condition

        @condition : FlagCondition | VariableCondition | QuestCondition | TimeCondition | AchievementCondition | TrueCondition | FalseCondition | AndCondition | OrCondition | NotCondition

        def initialize(@condition)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          @condition.evaluate(state)
        end

        def to_s : String
          @condition.to_s
        end

        def unwrap
          @condition
        end
      end

      # AND composite - all conditions must be true
      class AndCondition
        include Condition

        getter conditions : Array(ConditionWrapper)

        def initialize
          @conditions = [] of ConditionWrapper
        end

        def initialize(@conditions : Array(ConditionWrapper))
        end

        def add(condition : FlagCondition | VariableCondition | QuestCondition | TimeCondition | AchievementCondition | TrueCondition | FalseCondition | AndCondition | OrCondition | NotCondition)
          @conditions << ConditionWrapper.new(condition)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          return ConditionResult.new(true, "Empty AND (always true)") if @conditions.empty?

          results = @conditions.map(&.evaluate(state))
          success = results.all?(&.success)

          if success
            ConditionResult.new(true, "All #{@conditions.size} conditions met")
          else
            failed = results.reject(&.success).map(&.message).join(", ")
            ConditionResult.new(false, "Failed: #{failed}")
          end
        end

        def to_s : String
          @conditions.map(&.to_s).join(" && ")
        end
      end

      # OR composite - at least one condition must be true
      class OrCondition
        include Condition

        getter conditions : Array(ConditionWrapper)

        def initialize
          @conditions = [] of ConditionWrapper
        end

        def initialize(@conditions : Array(ConditionWrapper))
        end

        def add(condition : FlagCondition | VariableCondition | QuestCondition | TimeCondition | AchievementCondition | TrueCondition | FalseCondition | AndCondition | OrCondition | NotCondition)
          @conditions << ConditionWrapper.new(condition)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          return ConditionResult.new(false, "Empty OR (always false)") if @conditions.empty?

          results = @conditions.map(&.evaluate(state))
          success = results.any?(&.success)

          if success
            passed = results.find(&.success).try(&.message) || ""
            ConditionResult.new(true, "Passed: #{passed}")
          else
            ConditionResult.new(false, "No conditions met in OR")
          end
        end

        def to_s : String
          "(#{@conditions.map(&.to_s).join(" || ")})"
        end
      end

      # NOT wrapper - inverts the result of a condition
      class NotCondition
        include Condition

        @condition : ConditionWrapper

        def initialize(condition : FlagCondition | VariableCondition | QuestCondition | TimeCondition | AchievementCondition | TrueCondition | FalseCondition | AndCondition | OrCondition | NotCondition)
          @condition = ConditionWrapper.new(condition)
        end

        def evaluate(state : GameStateManager) : ConditionResult
          result = @condition.evaluate(state)
          ConditionResult.new(!result.success, "NOT: #{result.message}")
        end

        def to_s : String
          "!(#{@condition.to_s})"
        end
      end
    end
  end
end
