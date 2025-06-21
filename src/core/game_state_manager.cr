# Game State Manager for tracking flags, variables, quests, and achievements
# Provides comprehensive state management for Simon the Sorcerer 1 style adventure games

require "json"
require "yaml"

module PointClickEngine
  module Core
    # Value types that can be stored as game variables
    alias GameValue = Bool | Int32 | Float32 | String

    # Event handler for state changes
    alias StateChangeHandler = String, GameValue -> Nil

    # Condition evaluation result
    struct ConditionResult
      property success : Bool
      property message : String

      def initialize(@success : Bool, @message : String = "")
      end
    end

    # Game state manager handles all persistent game state
    class GameStateManager
      include JSON::Serializable
      include YAML::Serializable

      # Core state storage
      property flags : Hash(String, Bool) = {} of String => Bool
      property variables : Hash(String, GameValue) = {} of String => GameValue
      property timers : Hash(String, Float32) = {} of String => Float32

      # Quest and achievement tracking
      property active_quests : Hash(String, String) = {} of String => String # quest_id => current_step
      property completed_quests : Array(String) = [] of String
      property unlocked_achievements : Array(String) = [] of String

      # Game time tracking
      property game_time : Float32 = 0.0f32
      property day_cycle : Float32 = 0.0f32 # 0.0-1.0 representing 24-hour cycle

      # Event handling
      @[JSON::Field(ignore: true)]
      @[YAML::Field(ignore: true)]
      property change_handlers : Array(StateChangeHandler) = [] of StateChangeHandler

      def initialize
      end

      # Flag management
      def set_flag(name : String, value : Bool)
        old_value = @flags[name]?
        @flags[name] = value

        # Trigger change events if value actually changed
        if old_value != value
          trigger_change_event(name, value)
        end
      end

      def get_flag(name : String) : Bool
        @flags[name]? || false
      end

      def has_flag?(name : String) : Bool
        @flags.has_key?(name) && @flags[name]
      end

      # Variable management
      def set_variable(name : String, value : GameValue)
        old_value = @variables[name]?
        @variables[name] = value

        if old_value != value
          trigger_change_event(name, value)
        end
      end

      def get_variable(name : String) : GameValue?
        @variables[name]?
      end

      def get_variable_as(name : String, type : T.class) : T? forall T
        value = @variables[name]?
        value.is_a?(T) ? value : nil
      end

      # Timer management
      def set_timer(name : String, duration : Float32)
        @timers[name] = duration
      end

      def update_timers(dt : Float32)
        @timers.each do |name, remaining|
          new_time = remaining - dt
          if new_time <= 0
            @timers.delete(name)
            trigger_timer_expired(name)
          else
            @timers[name] = new_time
          end
        end
      end

      def get_timer(name : String) : Float32?
        @timers[name]?
      end

      def has_timer?(name : String) : Bool
        @timers.has_key?(name)
      end

      # Quest management
      def start_quest(quest_id : String, initial_step : String = "start")
        return if @completed_quests.includes?(quest_id)
        @active_quests[quest_id] = initial_step
      end

      def advance_quest(quest_id : String, next_step : String)
        return unless @active_quests.has_key?(quest_id)
        @active_quests[quest_id] = next_step
      end

      def complete_quest(quest_id : String)
        @active_quests.delete(quest_id)
        @completed_quests << quest_id unless @completed_quests.includes?(quest_id)
      end

      def is_quest_active?(quest_id : String) : Bool
        @active_quests.has_key?(quest_id)
      end

      def is_quest_completed?(quest_id : String) : Bool
        @completed_quests.includes?(quest_id)
      end

      def get_quest_step(quest_id : String) : String?
        @active_quests[quest_id]?
      end

      # Achievement management
      def unlock_achievement(achievement_id : String)
        return if @unlocked_achievements.includes?(achievement_id)
        @unlocked_achievements << achievement_id
      end

      def is_achievement_unlocked?(achievement_id : String) : Bool
        @unlocked_achievements.includes?(achievement_id)
      end

      # Time management
      def update_game_time(dt : Float32)
        @game_time += dt

        # Update day cycle (24 hours = 1440 minutes)
        day_length = 1440.0f32 # seconds for full day cycle
        @day_cycle = (@game_time % day_length) / day_length
      end

      def get_time_of_day : String
        hour = (@day_cycle * 24).to_i
        case hour
        when 0..5   then "night"
        when 6..11  then "morning"
        when 12..17 then "afternoon"
        when 18..20 then "evening"
        else             "night"
        end
      end

      def is_day? : Bool
        hour = (@day_cycle * 24).to_i
        hour >= 6 && hour < 18
      end

      def is_night? : Bool
        !is_day?
      end

      # Condition evaluation
      def check_condition(condition : String) : Bool
        begin
          evaluate_condition(condition).success
        rescue
          false
        end
      end

      # Advanced condition parsing
      def evaluate_condition(condition : String) : ConditionResult
        condition = condition.strip

        # Handle boolean operators
        if condition.includes?("&&")
          parts = condition.split("&&").map(&.strip)
          results = parts.map { |part| evaluate_condition(part) }
          success = results.all?(&.success)
          message = success ? "All conditions met" : "Some conditions failed: #{results.reject(&.success).map(&.message).join(", ")}"
          return ConditionResult.new(success, message)
        end

        if condition.includes?("||")
          parts = condition.split("||").map(&.strip)
          results = parts.map { |part| evaluate_condition(part) }
          success = results.any?(&.success)
          message = success ? "At least one condition met" : "No conditions met"
          return ConditionResult.new(success, message)
        end

        # Handle negation
        if condition.starts_with?("!")
          result = evaluate_condition(condition[1..-1])
          return ConditionResult.new(!result.success, "Negated: #{result.message}")
        end

        # Parse individual conditions
        if condition.includes?("==")
          left, right = condition.split("==").map(&.strip)
          return evaluate_equality(left, right)
        elsif condition.includes?("!=")
          left, right = condition.split("!=").map(&.strip)
          result = evaluate_equality(left, right)
          return ConditionResult.new(!result.success, "Not equal: #{result.message}")
        elsif condition.includes?(">=")
          left, right = condition.split(">=").map(&.strip)
          return evaluate_comparison(left, right, ">=")
        elsif condition.includes?("<=")
          left, right = condition.split("<=").map(&.strip)
          return evaluate_comparison(left, right, "<=")
        elsif condition.includes?(">")
          left, right = condition.split(">").map(&.strip)
          return evaluate_comparison(left, right, ">")
        elsif condition.includes?("<")
          left, right = condition.split("<").map(&.strip)
          return evaluate_comparison(left, right, "<")
        end

        # Simple boolean check
        return evaluate_boolean(condition)
      end

      # Event system
      def add_change_handler(handler : StateChangeHandler)
        @change_handlers << handler
      end

      def remove_change_handler(handler : StateChangeHandler)
        @change_handlers.delete(handler)
      end

      # Save/Load
      def save_to_file(path : String) : Bool
        begin
          File.write(path, to_json)
          true
        rescue
          false
        end
      end

      def load_from_file(path : String) : Bool
        begin
          return false unless File.exists?(path)
          json_data = File.read(path)
          loaded = GameStateManager.from_json(json_data)
          copy_state_from(loaded)
          true
        rescue
          false
        end
      end

      # Debug utilities
      def debug_dump : String
        String.build do |str|
          str << "=== GAME STATE DEBUG ===\n"
          str << "Flags (#{@flags.size}):\n"
          @flags.each { |k, v| str << "  #{k} = #{v}\n" }
          str << "Variables (#{@variables.size}):\n"
          @variables.each { |k, v| str << "  #{k} = #{v}\n" }
          str << "Active Quests (#{@active_quests.size}):\n"
          @active_quests.each { |k, v| str << "  #{k} => #{v}\n" }
          str << "Completed Quests (#{@completed_quests.size}):\n"
          @completed_quests.each { |q| str << "  #{q}\n" }
          str << "Achievements (#{@unlocked_achievements.size}):\n"
          @unlocked_achievements.each { |a| str << "  #{a}\n" }
          str << "Game Time: #{@game_time}s (#{get_time_of_day})\n"
          str << "========================\n"
        end
      end

      # Private implementation methods
      private def trigger_change_event(name : String, value : GameValue)
        @change_handlers.each do |handler|
          begin
            handler.call(name, value)
          rescue ex
            puts "Error in state change handler: #{ex.message}"
          end
        end
      end

      private def trigger_timer_expired(name : String)
        trigger_change_event("timer_expired:#{name}", true)
      end

      private def evaluate_equality(left : String, right : String) : ConditionResult
        left_val = get_value(left)
        right_val = parse_value(right)

        success = left_val == right_val
        message = "#{left} (#{left_val}) == #{right} (#{right_val})"
        ConditionResult.new(success, message)
      end

      private def evaluate_comparison(left : String, right : String, operator : String) : ConditionResult
        left_val = get_numeric_value(left)
        right_val = parse_numeric_value(right)

        return ConditionResult.new(false, "Non-numeric comparison") if left_val.nil? || right_val.nil?

        success = case operator
                  when ">=" then left_val >= right_val
                  when "<=" then left_val <= right_val
                  when ">"  then left_val > right_val
                  when "<"  then left_val < right_val
                  else           false
                  end

        message = "#{left} (#{left_val}) #{operator} #{right} (#{right_val})"
        ConditionResult.new(success, message)
      end

      private def evaluate_boolean(condition : String) : ConditionResult
        # Check for quest conditions
        if condition.starts_with?("quest:")
          quest_part = condition[6..-1]
          if quest_part.includes?(":")
            quest_id, status = quest_part.split(":", 2)
            case status
            when "active"    then ConditionResult.new(is_quest_active?(quest_id), "Quest #{quest_id} active")
            when "completed" then ConditionResult.new(is_quest_completed?(quest_id), "Quest #{quest_id} completed")
            else
              step = get_quest_step(quest_id)
              success = step == status
              ConditionResult.new(success, "Quest #{quest_id} step: #{step}")
            end
          else
            success = is_quest_active?(quest_part) || is_quest_completed?(quest_part)
            ConditionResult.new(success, "Quest #{quest_part} exists")
          end
          # Check for achievement conditions
        elsif condition.starts_with?("achievement:")
          achievement_id = condition[12..-1]
          success = is_achievement_unlocked?(achievement_id)
          ConditionResult.new(success, "Achievement #{achievement_id}")
          # Check for time conditions
        elsif condition.starts_with?("time:")
          time_condition = condition[5..-1]
          success = case time_condition
                    when "day"       then is_day?
                    when "night"     then is_night?
                    when "morning"   then get_time_of_day == "morning"
                    when "afternoon" then get_time_of_day == "afternoon"
                    when "evening"   then get_time_of_day == "evening"
                    else                  false
                    end
          ConditionResult.new(success, "Time condition: #{time_condition}")
        else
          # Simple flag check
          success = get_flag(condition)
          ConditionResult.new(success, "Flag #{condition}")
        end
      end

      private def get_value(name : String) : GameValue?
        if @flags.has_key?(name)
          @flags[name]
        elsif @variables.has_key?(name)
          @variables[name]
        else
          nil
        end
      end

      private def get_numeric_value(name : String) : Float32?
        value = get_value(name)
        case value
        when Int32   then value.to_f32
        when Float32 then value
        else              nil
        end
      end

      private def parse_value(str : String) : GameValue
        # Try boolean
        case str.downcase
        when "true"  then return true
        when "false" then return false
        end

        # Try integer
        if int_val = str.to_i32?
          return int_val
        end

        # Try float
        if float_val = str.to_f32?
          return float_val
        end

        # Default to string (remove quotes if present)
        str.starts_with?('"') && str.ends_with?('"') ? str[1..-2] : str
      end

      private def parse_numeric_value(str : String) : Float32?
        if int_val = str.to_i32?
          int_val.to_f32
        elsif float_val = str.to_f32?
          float_val
        else
          nil
        end
      end

      private def copy_state_from(other : GameStateManager)
        @flags = other.flags
        @variables = other.variables
        @timers = other.timers
        @active_quests = other.active_quests
        @completed_quests = other.completed_quests
        @unlocked_achievements = other.unlocked_achievements
        @game_time = other.game_time
        @day_cycle = other.day_cycle
      end
    end
  end
end
