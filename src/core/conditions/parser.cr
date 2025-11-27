# Condition Parser
#
# Parses string conditions (from YAML) into typed Condition objects.
# Maintains backwards compatibility with existing string-based conditions.
#
# Supported syntax:
# - Flags: "door_unlocked", "!door_locked"
# - Variables: "gold >= 100", "health == 50"
# - Quests: "quest:main:active", "quest:side:completed", "quest:main:step1"
# - Time: "time:day", "time:night", "time:morning"
# - Achievements: "achievement:master", "!achievement:novice"
# - Boolean: "cond1 && cond2", "cond1 || cond2"
# - Negation: "!condition"

require "./condition"
require "./composite"
require "../error_handling"

module PointClickEngine
  module Core
    module Conditions
      # Parses string conditions into typed Condition objects
      class ConditionParser
        # Parse a string condition into a typed Condition
        def self.parse(condition_string : String) : Result(ConditionWrapper, String)
          condition_string = condition_string.strip
          return Result(ConditionWrapper, String).success(ConditionWrapper.new(TrueCondition.new)) if condition_string.empty?

          begin
            condition = parse_internal(condition_string)
            Result(ConditionWrapper, String).success(condition)
          rescue ex
            Result(ConditionWrapper, String).failure("Parse error: #{ex.message}")
          end
        end

        # Parse and return the condition directly, raising on error
        def self.parse!(condition_string : String) : ConditionWrapper
          result = parse(condition_string)
          raise result.error if result.failure?
          result.value
        end

        private def self.parse_internal(s : String) : ConditionWrapper
          s = s.strip

          # Handle AND (&&)
          if s.includes?("&&")
            parts = split_at_operator(s, "&&")
            conditions = parts.map { |p| parse_internal(p) }
            return ConditionWrapper.new(AndCondition.new(conditions))
          end

          # Handle OR (||)
          if s.includes?("||")
            parts = split_at_operator(s, "||")
            conditions = parts.map { |p| parse_internal(p) }
            return ConditionWrapper.new(OrCondition.new(conditions))
          end

          # Handle NOT (!)
          if s.starts_with?("!")
            inner = parse_internal(s[1..-1])
            return ConditionWrapper.new(NotCondition.new(inner.unwrap))
          end

          # Handle parentheses
          if s.starts_with?("(") && s.ends_with?(")")
            return parse_internal(s[1..-2])
          end

          # Handle comparisons
          if comparison = parse_comparison(s)
            return ConditionWrapper.new(comparison)
          end

          # Handle special conditions
          if s.starts_with?("quest:")
            return ConditionWrapper.new(parse_quest_condition(s[6..-1]))
          end

          if s.starts_with?("achievement:")
            id = s[12..-1]
            return ConditionWrapper.new(AchievementCondition.new(id))
          end

          if s.starts_with?("time:")
            return ConditionWrapper.new(parse_time_condition(s[5..-1]))
          end

          # Default: flag check
          ConditionWrapper.new(FlagCondition.new(s))
        end

        # Split a string at an operator, respecting parentheses
        private def self.split_at_operator(s : String, op : String) : Array(String)
          parts = [] of String
          current = ""
          paren_depth = 0
          i = 0

          while i < s.size
            # Check for operator at this position
            if paren_depth == 0 && s[i..i + op.size - 1]? == op
              parts << current.strip
              current = ""
              i += op.size
              next
            end

            char = s[i]
            if char == '('
              paren_depth += 1
            elsif char == ')'
              paren_depth -= 1
            end

            current += char
            i += 1
          end

          parts << current.strip
          parts
        end

        private def self.parse_comparison(s : String) : VariableCondition?
          operators = [">=", "<=", "!=", "==", ">", "<"]

          operators.each do |op|
            if s.includes?(op)
              parts = s.split(op, 2).map(&.strip)
              return nil if parts.size != 2

              name = parts[0]
              value = parse_value(parts[1])

              operator = case op
                         when "==" then VariableCondition::Operator::Equal
                         when "!=" then VariableCondition::Operator::NotEqual
                         when ">"  then VariableCondition::Operator::GreaterThan
                         when ">=" then VariableCondition::Operator::GreaterOrEqual
                         when "<"  then VariableCondition::Operator::LessThan
                         when "<=" then VariableCondition::Operator::LessOrEqual
                         else           return nil
                         end

              return VariableCondition.new(name, operator, value)
            end
          end

          nil
        end

        private def self.parse_value(s : String) : Int32 | Float32 | String | Bool
          s = s.strip

          # Try boolean
          return true if s.downcase == "true"
          return false if s.downcase == "false"

          # Try integer
          if int_val = s.to_i32?
            return int_val
          end

          # Try float
          if float_val = s.to_f32?
            return float_val
          end

          # Default to string (remove quotes if present)
          if (s.starts_with?('"') && s.ends_with?('"')) || (s.starts_with?("'") && s.ends_with?("'"))
            s[1..-2]
          else
            s
          end
        end

        private def self.parse_quest_condition(s : String) : QuestCondition
          parts = s.split(":", 2)
          quest_id = parts[0]

          status = case parts[1]?
                   when "active"    then QuestCondition::Status::Active
                   when "completed" then QuestCondition::Status::Completed
                   when nil         then QuestCondition::Status::Active
                   else
                     # Assume it's a step name
                     return QuestCondition.new(quest_id, QuestCondition::Status::AtStep, parts[1])
                   end

          QuestCondition.new(quest_id, status)
        end

        private def self.parse_time_condition(s : String) : TimeCondition
          period = case s.downcase
                   when "day"       then TimeCondition::Period::Day
                   when "night"     then TimeCondition::Period::Night
                   when "morning"   then TimeCondition::Period::Morning
                   when "afternoon" then TimeCondition::Period::Afternoon
                   when "evening"   then TimeCondition::Period::Evening
                   else
                     raise "Unknown time period: #{s}"
                   end

          TimeCondition.new(period)
        end
      end
    end
  end
end
