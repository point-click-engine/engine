# Condition Validator
#
# Validates condition strings with helpful error messages and suggestions.
# Supports registering known identifiers for more accurate validation.

require "./validation"

module PointClickEngine
  module Core
    module Conditions
      # Validates condition strings with helpful error messages
      class ConditionValidator
        # Known flags, variables, quests, achievements for validation
        @known_flags : Set(String) = Set(String).new
        @known_variables : Set(String) = Set(String).new
        @known_quests : Set(String) = Set(String).new
        @known_achievements : Set(String) = Set(String).new

        def initialize
        end

        # Register known identifiers (called during game initialization)
        def register_flag(name : String)
          @known_flags << name
        end

        def register_flags(names : Enumerable(String))
          names.each { |n| @known_flags << n }
        end

        def register_variable(name : String)
          @known_variables << name
        end

        def register_variables(names : Enumerable(String))
          names.each { |n| @known_variables << n }
        end

        def register_quest(id : String)
          @known_quests << id
        end

        def register_quests(ids : Enumerable(String))
          ids.each { |id| @known_quests << id }
        end

        def register_achievement(id : String)
          @known_achievements << id
        end

        def register_achievements(ids : Enumerable(String))
          ids.each { |id| @known_achievements << id }
        end

        # Load known identifiers from a GameStateManager
        def load_from_state_manager(gsm : GameStateManager)
          gsm.flags.keys.each { |k| @known_flags << k }
          gsm.variables.keys.each { |k| @known_variables << k }
          gsm.active_quests.each { |q| @known_quests << q }
          gsm.completed_quests.each { |q| @known_quests << q }
        end

        # Validate a condition string
        def validate(
          condition : String,
          source_file : String? = nil,
          source_line : Int32? = nil
        ) : ConditionValidationResult
          result = ConditionValidationResult.new(condition, source_file, source_line)

          # Check for empty condition
          if condition.strip.empty?
            result.add_error(
              ConditionValidationResult::ErrorType::SyntaxError,
              "Empty condition string"
            )
            return result
          end

          # Check balanced parentheses
          unless balanced_parens?(condition)
            result.add_error(
              ConditionValidationResult::ErrorType::UnbalancedParens,
              "Unbalanced parentheses"
            )
          end

          # Tokenize and validate each part
          tokens = tokenize(condition)
          validate_tokens(tokens, result)

          result
        end

        # Validate multiple conditions (batch mode)
        def validate_batch(conditions : Array(NamedTuple(condition: String, file: String, line: Int32))) : Array(ConditionValidationResult)
          conditions.map do |c|
            validate(c[:condition], c[:file], c[:line])
          end
        end

        private def balanced_parens?(s : String) : Bool
          count = 0
          s.each_char do |c|
            count += 1 if c == '('
            count -= 1 if c == ')'
            return false if count < 0
          end
          count == 0
        end

        private def tokenize(condition : String) : Array(String)
          tokens = [] of String
          current = ""
          paren_depth = 0

          i = 0
          while i < condition.size
            char = condition[i]

            case char
            when '('
              tokens << current.strip unless current.strip.empty?
              current = ""
              paren_depth += 1
              tokens << "("
            when ')'
              tokens << current.strip unless current.strip.empty?
              current = ""
              paren_depth -= 1
              tokens << ")"
            when '&'
              if condition[i + 1]? == '&'
                tokens << current.strip unless current.strip.empty?
                current = ""
                tokens << "&&"
                i += 1
              else
                current += char
              end
            when '|'
              if condition[i + 1]? == '|'
                tokens << current.strip unless current.strip.empty?
                current = ""
                tokens << "||"
                i += 1
              else
                current += char
              end
            when ' ', '\t', '\n'
              # Skip whitespace but add token if we have one
              unless current.strip.empty?
                tokens << current.strip
                current = ""
              end
            else
              current += char
            end

            i += 1
          end

          tokens << current.strip unless current.strip.empty?
          tokens
        end

        private def validate_tokens(tokens : Array(String), result : ConditionValidationResult)
          tokens.each do |token|
            next if token == "(" || token == ")" || token == "&&" || token == "||"
            validate_condition_token(token, result)
          end
        end

        private def validate_condition_token(token : String, result : ConditionValidationResult)
          token = token.strip

          # Handle negation
          if token.starts_with?("!")
            validate_condition_token(token[1..-1], result)
            return
          end

          # Check for quest condition
          if token.starts_with?("quest:")
            validate_quest_condition(token[6..-1], result)
            return
          end

          # Check for achievement condition
          if token.starts_with?("achievement:")
            validate_achievement_condition(token[12..-1], result)
            return
          end

          # Check for time condition
          if token.starts_with?("time:")
            validate_time_condition(token[5..-1], result)
            return
          end

          # Check for comparison operators
          operators = [">=", "<=", "!=", "==", ">", "<"]
          operators.each do |op|
            if token.includes?(op)
              validate_comparison(token, op, result)
              return
            end
          end

          # Must be a flag
          validate_flag(token, result)
        end

        private def validate_flag(flag : String, result : ConditionValidationResult)
          return if @known_flags.empty? # Can't validate without known flags

          unless @known_flags.includes?(flag)
            suggestion = find_closest_match(flag, @known_flags)
            result.add_warning(
              ConditionValidationResult::ErrorType::UnknownFlag,
              "Unknown flag '#{flag}'",
              suggestion: suggestion
            )
          end
        end

        private def validate_comparison(token : String, op : String, result : ConditionValidationResult)
          parts = token.split(op, 2).map(&.strip)
          return if parts.size != 2

          var_name = parts[0]

          return if @known_variables.empty? # Can't validate without known variables

          unless @known_variables.includes?(var_name)
            suggestion = find_closest_match(var_name, @known_variables)
            result.add_warning(
              ConditionValidationResult::ErrorType::UnknownVariable,
              "Unknown variable '#{var_name}'",
              suggestion: suggestion
            )
          end
        end

        private def validate_quest_condition(quest_part : String, result : ConditionValidationResult)
          parts = quest_part.split(":", 2)
          quest_id = parts[0]

          return if @known_quests.empty? # Can't validate without known quests

          unless @known_quests.includes?(quest_id)
            suggestion = find_closest_match(quest_id, @known_quests)
            result.add_warning(
              ConditionValidationResult::ErrorType::UnknownQuest,
              "Unknown quest '#{quest_id}'",
              suggestion: suggestion
            )
          end

          # Validate status
          if status = parts[1]?
            valid_statuses = ["active", "completed", "failed"]
            unless valid_statuses.includes?(status) || status.match(/^step/)
              # Could be a step name, that's OK
            end
          end
        end

        private def validate_achievement_condition(achievement_id : String, result : ConditionValidationResult)
          return if @known_achievements.empty?

          unless @known_achievements.includes?(achievement_id)
            suggestion = find_closest_match(achievement_id, @known_achievements)
            result.add_warning(
              ConditionValidationResult::ErrorType::UnknownAchievement,
              "Unknown achievement '#{achievement_id}'",
              suggestion: suggestion
            )
          end
        end

        private def validate_time_condition(time_part : String, result : ConditionValidationResult)
          valid_periods = ["day", "night", "morning", "afternoon", "evening"]
          unless valid_periods.includes?(time_part.downcase)
            suggestion = find_closest_match(time_part, valid_periods.to_set)
            result.add_error(
              ConditionValidationResult::ErrorType::SyntaxError,
              "Unknown time period '#{time_part}'",
              suggestion: suggestion
            )
          end
        end

        # Find the closest matching string using Levenshtein distance
        private def find_closest_match(target : String, candidates : Set(String)) : String?
          return nil if candidates.empty?

          best_match = nil
          best_distance = Int32::MAX

          candidates.each do |candidate|
            distance = levenshtein_distance(target.downcase, candidate.downcase)
            if distance < best_distance && distance <= 3 # Only suggest if reasonably close
              best_distance = distance
              best_match = candidate
            end
          end

          best_match
        end

        # Calculate Levenshtein distance between two strings
        private def levenshtein_distance(s1 : String, s2 : String) : Int32
          return s2.size if s1.empty?
          return s1.size if s2.empty?

          # Create matrix
          rows = s1.size + 1
          cols = s2.size + 1

          # Initialize first row and column
          prev_row = Array.new(cols) { |i| i }
          curr_row = Array.new(cols, 0)

          s1.each_char_with_index do |c1, i|
            curr_row[0] = i + 1

            s2.each_char_with_index do |c2, j|
              cost = c1 == c2 ? 0 : 1
              curr_row[j + 1] = {
                prev_row[j + 1] + 1,   # deletion
                curr_row[j] + 1,       # insertion
                prev_row[j] + cost,    # substitution
              }.min
            end

            prev_row, curr_row = curr_row, prev_row
          end

          prev_row[cols - 1]
        end
      end
    end
  end
end
