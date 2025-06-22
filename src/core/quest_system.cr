# Quest System for managing multi-step quests and objectives
# Provides comprehensive quest tracking for Simon the Sorcerer 1 style adventure games

require "json"
require "yaml"

module PointClickEngine
  module Core
    # Quest objective that can be checked against game state
    class QuestObjective
      include JSON::Serializable
      include YAML::Serializable

      property id : String
      property description : String
      property condition : String
      property optional : Bool = false
      property hidden : Bool = false # Don't show in quest log until revealed
      property completed : Bool = false

      def initialize(@id : String, @description : String, @condition : String)
      end

      def check_completion(state_manager : GameStateManager) : Bool
        return true if @completed

        if state_manager.check_condition(@condition)
          @completed = true
          true
        else
          false
        end
      end

      def reset
        @completed = false
      end
    end

    # Reward given when quest is completed
    struct QuestReward
      include JSON::Serializable
      include YAML::Serializable

      property type : String # "item", "experience", "money", "flag"
      property identifier : String
      property amount : Int32 = 1

      def initialize(@type : String, @identifier : String, @amount : Int32 = 1)
      end
    end

    # Individual quest definition
    class Quest
      include JSON::Serializable
      include YAML::Serializable

      property id : String
      property name : String
      property description : String
      property start_condition : String = ""
      property objectives : Array(QuestObjective) = [] of QuestObjective
      property rewards : Array(QuestReward) = [] of QuestReward
      property journal_entries : Array(String) = [] of String

      # Quest state
      property active : Bool = false
      property completed : Bool = false
      property failed : Bool = false
      property current_step : String = "start"
      property completion_time : Float32 = 0.0f32

      # Quest metadata
      property category : String = "main" # "main", "side", "hidden"
      property priority : Int32 = 0
      property auto_start : Bool = false
      property can_abandon : Bool = true

      def initialize(@id : String, @name : String, @description : String)
      end

      def add_objective(id : String, description : String, condition : String, optional : Bool = false, hidden : Bool = false)
        objective = QuestObjective.new(id, description, condition)
        objective.optional = optional
        objective.hidden = hidden
        @objectives << objective
      end

      def add_reward(type : String, identifier : String, amount : Int32 = 1)
        @rewards << QuestReward.new(type, identifier, amount)
      end

      def can_start?(state_manager : GameStateManager) : Bool
        return false if @active || @completed
        return true if @start_condition.empty?
        state_manager.check_condition(@start_condition)
      end

      def start(state_manager : GameStateManager)
        return if @active || @completed

        @active = true
        @current_step = "start"

        # Add initial journal entry
        if !@journal_entries.empty?
          add_journal_entry(@journal_entries[0])
        end

        state_manager.start_quest(@id, @current_step)
      end

      def update_progress(state_manager : GameStateManager) : Bool
        return false unless @active
        return false if @completed || @failed

        # Check all objectives
        required_objectives = @objectives.reject(&.optional)
        completed_required = required_objectives.count(&.check_completion(state_manager))

        # Check if quest is complete
        if completed_required == required_objectives.size
          complete(state_manager)
          return true
        end

        # Check for step progression
        check_step_progression(state_manager)

        false
      end

      def complete(state_manager : GameStateManager)
        return if @completed

        @active = false
        @completed = true
        @completion_time = state_manager.game_time

        # Grant rewards
        grant_rewards(state_manager)

        # Add completion journal entry
        add_journal_entry("Quest completed: #{@name}")

        state_manager.complete_quest(@id)
      end

      def fail(state_manager : GameStateManager, reason : String = "")
        return if @completed || @failed

        @active = false
        @failed = true

        # Add failure journal entry
        entry = reason.empty? ? "Quest failed: #{@name}" : "Quest failed: #{@name} - #{reason}"
        add_journal_entry(entry)
      end

      def abandon(state_manager : GameStateManager)
        return unless @can_abandon
        return if @completed

        @active = false
        reset_objectives
        add_journal_entry("Quest abandoned: #{@name}")
      end

      def reset
        @active = false
        @completed = false
        @failed = false
        @current_step = "start"
        @completion_time = 0.0f32
        reset_objectives
      end

      def get_progress_text : String
        return "Completed" if @completed
        return "Failed" if @failed
        return "Not started" unless @active

        completed_count = @objectives.count(&.completed)
        total_count = @objectives.size
        optional_count = @objectives.count(&.optional)
        required_count = total_count - optional_count
        completed_required = @objectives.reject(&.optional).count(&.completed)

        "#{completed_required}/#{required_count} objectives completed"
      end

      def get_visible_objectives : Array(QuestObjective)
        @objectives.reject(&.hidden)
      end

      def get_completion_percentage : Float32
        return 100.0f32 if @completed
        return 0.0f32 unless @active

        total = @objectives.size
        return 0.0f32 if total == 0

        completed = @objectives.count(&.completed)
        (completed.to_f32 / total.to_f32) * 100.0f32
      end

      private def reset_objectives
        @objectives.each(&.reset)
      end

      private def grant_rewards(state_manager : GameStateManager)
        @rewards.each do |reward|
          case reward.type
          when "flag"
            state_manager.set_flag(reward.identifier, true)
          when "variable"
            current = state_manager.get_variable_as(reward.identifier, Int32) || 0
            state_manager.set_variable(reward.identifier, current + reward.amount)
          when "achievement"
            state_manager.unlock_achievement(reward.identifier)
            # Add more reward types as needed
          end
        end
      end

      private def check_step_progression(state_manager : GameStateManager)
        # This could be expanded for complex multi-step quests
        # For now, just track basic progression
        completed_objectives = @objectives.count(&.completed)

        case completed_objectives
        when 1
          @current_step = "in_progress"
          state_manager.advance_quest(@id, @current_step)
        when @objectives.size - 1
          @current_step = "nearly_complete"
          state_manager.advance_quest(@id, @current_step)
        end
      end

      private def add_journal_entry(entry : String)
        # This would integrate with a journal system if available
        puts "Journal: #{entry}"
      end
    end

    # Quest manager handles all quests and their interactions
    class QuestManager
      include JSON::Serializable
      include YAML::Serializable

      property quests : Hash(String, Quest) = {} of String => Quest
      property active_notifications : Array(String) = [] of String

      @[JSON::Field(ignore: true)]
      @[YAML::Field(ignore: true)]
      property state_manager : GameStateManager?

      def initialize
      end

      def add_quest(quest : Quest)
        @quests[quest.id] = quest
      end

      def create_quest(id : String, name : String, description : String) : Quest
        quest = Quest.new(id, name, description)
        add_quest(quest)
        quest
      end

      def get_quest(id : String) : Quest?
        @quests[id]?
      end

      def start_quest(id : String, state_manager : GameStateManager) : Bool
        quest = @quests[id]?
        return false unless quest
        return false unless quest.can_start?(state_manager)

        quest.start(state_manager)
        add_notification("Quest started: #{quest.name}")
        true
      end

      def update_all_quests(state_manager : GameStateManager, dt : Float32)
        @quests.values.each do |quest|
          next unless quest.active

          if quest.update_progress(state_manager)
            add_notification("Quest completed: #{quest.name}")
          end
        end

        # Check for auto-start quests
        @quests.values.each do |quest|
          if quest.auto_start && quest.can_start?(state_manager)
            start_quest(quest.id, state_manager)
          end
        end
      end

      def get_active_quests : Array(Quest)
        @quests.values.select(&.active)
      end

      def get_completed_quests : Array(Quest)
        @quests.values.select(&.completed)
      end

      def get_failed_quests : Array(Quest)
        @quests.values.select(&.failed)
      end

      def get_available_quests(state_manager : GameStateManager) : Array(Quest)
        @quests.values.select(&.can_start?(state_manager))
      end

      def get_quests_by_category(category : String) : Array(Quest)
        @quests.values.select { |q| q.category == category }
      end

      def abandon_quest(id : String, state_manager : GameStateManager) : Bool
        quest = @quests[id]?
        return false unless quest
        return false unless quest.can_abandon

        quest.abandon(state_manager)
        add_notification("Quest abandoned: #{quest.name}")
        true
      end

      def reset_quest(id : String) : Bool
        quest = @quests[id]?
        return false unless quest

        quest.reset
        true
      end

      def reset_all_quests
        @quests.values.each(&.reset)
      end

      # Event handlers for state manager integration
      def on_quest_started(quest_id : String)
        # Hook for additional quest start logic
      end

      def on_quest_advanced(quest_id : String, step : String)
        # Hook for quest step advancement
      end

      def on_quest_completed(quest_id : String)
        # Hook for additional quest completion logic
      end

      def check_objectives_for_flag(flag_name : String, value : Bool)
        get_active_quests.each do |quest|
          quest.update_progress(@state_manager.not_nil!) if @state_manager
        end
      end

      def check_objectives_for_variable(var_name : String, value : GameValue)
        get_active_quests.each do |quest|
          quest.update_progress(@state_manager.not_nil!) if @state_manager
        end
      end

      # Notification system
      def add_notification(message : String)
        @active_notifications << message
        puts "Quest Notification: #{message}"
      end

      def get_notifications : Array(String)
        @active_notifications.dup
      end

      def clear_notifications
        @active_notifications.clear
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
          loaded = QuestManager.from_json(json_data)
          @quests = loaded.quests
          @active_notifications = loaded.active_notifications
          true
        rescue
          false
        end
      end

      # Load quest definitions from YAML
      def load_quests_from_yaml(path : String) : Bool
        begin
          return false unless File.exists?(path)
          yaml_data = File.read(path)
          quest_data = YAML.parse(yaml_data)

          if quest_array = quest_data.as_a?
            quest_array.each do |quest_yaml|
              quest = Quest.from_yaml(quest_yaml.to_yaml)
              add_quest(quest)
            end
          end

          true
        rescue ex
          puts "Error loading quests: #{ex.message}"
          puts "Stack trace: #{ex.backtrace.join("\n")}" if ex.responds_to?(:backtrace)
          false
        end
      end

      # Debug utilities
      def debug_dump : String
        String.build do |str|
          str << "=== QUEST MANAGER DEBUG ===\n"
          str << "Total Quests: #{@quests.size}\n"
          str << "Active: #{get_active_quests.size}\n"
          str << "Completed: #{get_completed_quests.size}\n"
          str << "Failed: #{get_failed_quests.size}\n"

          get_active_quests.each do |quest|
            str << "\nActive Quest: #{quest.name}\n"
            str << "  Progress: #{quest.get_progress_text}\n"
            str << "  Step: #{quest.current_step}\n"
            quest.get_visible_objectives.each do |obj|
              status = obj.completed ? "✓" : "○"
              str << "    #{status} #{obj.description}\n"
            end
          end

          str << "===========================\n"
        end
      end
    end
  end
end
