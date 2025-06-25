require "../spec_helper"
require "../../src/core/game_state_manager"

describe PointClickEngine::Core::GameStateManager do
  it "initializes with empty state" do
    manager = PointClickEngine::Core::GameStateManager.new

    manager.flags.should be_empty
    manager.variables.should be_empty
    manager.timers.should be_empty
    manager.active_quests.should be_empty
    manager.completed_quests.should be_empty
    manager.unlocked_achievements.should be_empty
    manager.game_time.should eq 0.0f32
    manager.day_cycle.should eq 0.0f32
  end

  describe "flag management" do
    it "sets and gets flags" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_flag("test_flag", true)
      manager.get_flag("test_flag").should be_true
      manager.has_flag?("test_flag").should be_true

      manager.set_flag("test_flag", false)
      manager.get_flag("test_flag").should be_false
      manager.has_flag?("test_flag").should be_false
    end

    it "returns false for non-existent flags" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.get_flag("nonexistent").should be_false
      manager.has_flag?("nonexistent").should be_false
    end
  end

  describe "variable management" do
    it "sets and gets variables of different types" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_variable("bool_var", true)
      manager.set_variable("int_var", 42)
      manager.set_variable("float_var", 3.14f32)
      manager.set_variable("string_var", "hello")

      manager.get_variable("bool_var").should eq true
      manager.get_variable("int_var").should eq 42
      manager.get_variable("float_var").should eq 3.14f32
      manager.get_variable("string_var").should eq "hello"
    end

    it "gets typed variables" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_variable("int_var", 42)
      manager.set_variable("string_var", "hello")

      manager.get_variable_as("int_var", Int32).should eq 42
      manager.get_variable_as("string_var", String).should eq "hello"
      manager.get_variable_as("int_var", String).should be_nil
    end
  end

  describe "timer management" do
    it "sets and updates timers" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_timer("test_timer", 5.0f32)
      manager.get_timer("test_timer").should eq 5.0f32
      manager.has_timer?("test_timer").should be_true

      # Update timer
      manager.update_timers(1.0f32)
      manager.get_timer("test_timer").should eq 4.0f32

      # Timer expires
      manager.update_timers(5.0f32)
      manager.has_timer?("test_timer").should be_false
    end
  end

  describe "quest management" do
    it "manages quest lifecycle" do
      manager = PointClickEngine::Core::GameStateManager.new

      # Start quest
      manager.start_quest("find_key", "search_desk")
      manager.is_quest_active?("find_key").should be_true
      manager.get_quest_step("find_key").should eq "search_desk"

      # Advance quest
      manager.advance_quest("find_key", "found_key")
      manager.get_quest_step("find_key").should eq "found_key"

      # Complete quest
      manager.complete_quest("find_key")
      manager.is_quest_active?("find_key").should be_false
      manager.is_quest_completed?("find_key").should be_true
    end

    it "prevents duplicate quest completion" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.complete_quest("test_quest")
      manager.start_quest("test_quest") # Should not start

      manager.is_quest_active?("test_quest").should be_false
      manager.is_quest_completed?("test_quest").should be_true
    end
  end

  describe "achievement management" do
    it "unlocks achievements uniquely" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.unlock_achievement("first_key")
      manager.is_achievement_unlocked?("first_key").should be_true

      # Try to unlock again
      initial_count = manager.unlocked_achievements.size
      manager.unlock_achievement("first_key")
      manager.unlocked_achievements.size.should eq initial_count
    end
  end

  describe "time management" do
    it "updates game time and day cycle" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.update_game_time(720.0f32) # 12 minutes = half day
      manager.day_cycle.should be > 0.0f32
      manager.day_cycle.should be < 1.0f32
    end

    it "determines time of day correctly" do
      manager = PointClickEngine::Core::GameStateManager.new

      # Test different times
      manager.day_cycle = 0.25f32 # 6 AM
      manager.get_time_of_day.should eq "morning"
      manager.is_day?.should be_true

      manager.day_cycle = 0.75f32 # 6 PM
      manager.get_time_of_day.should eq "evening"

      manager.day_cycle = 0.0f32 # Midnight
      manager.get_time_of_day.should eq "night"
      manager.is_night?.should be_true
    end
  end

  describe "condition evaluation" do
    it "evaluates simple boolean conditions" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_flag("has_key", true)
      manager.check_condition("has_key").should be_true
      manager.check_condition("!has_key").should be_false
      manager.check_condition("missing_flag").should be_false
    end

    it "evaluates equality conditions" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_variable("gold", 100)
      manager.check_condition("gold == 100").should be_true
      manager.check_condition("gold == 50").should be_false
      manager.check_condition("gold != 50").should be_true
    end

    it "evaluates comparison conditions" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_variable("level", 5)
      manager.check_condition("level >= 5").should be_true
      manager.check_condition("level > 10").should be_false
      manager.check_condition("level < 10").should be_true
      manager.check_condition("level <= 5").should be_true
    end

    it "evaluates compound conditions" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_flag("has_key", true)
      manager.set_variable("gold", 100)

      manager.check_condition("has_key && gold >= 100").should be_true
      manager.check_condition("has_key && gold >= 200").should be_false
      manager.check_condition("has_key || gold >= 200").should be_true
    end

    it "evaluates quest conditions" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.start_quest("test_quest")
      manager.check_condition("quest:test_quest:active").should be_true

      manager.complete_quest("test_quest")
      manager.check_condition("quest:test_quest:completed").should be_true
      manager.check_condition("quest:test_quest:active").should be_false
    end

    it "evaluates time conditions" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.day_cycle = 0.5f32 # Noon
      manager.check_condition("time:day").should be_true
      manager.check_condition("time:night").should be_false
      manager.check_condition("time:afternoon").should be_true
    end
  end

  describe "event handling" do
    it "triggers change events" do
      manager = PointClickEngine::Core::GameStateManager.new
      events_received = [] of String

      handler = ->(name : String, value : PointClickEngine::Core::GameValue) {
        events_received << "#{name}:#{value}"
      }

      manager.add_change_handler(handler)
      manager.set_flag("test_flag", true)
      manager.set_variable("test_var", 42)

      events_received.includes?("test_flag:true").should be_true
      events_received.includes?("test_var:42").should be_true
    end
  end

  describe "serialization" do
    it "saves and loads state" do
      manager = PointClickEngine::Core::GameStateManager.new

      # Set up some state
      manager.set_flag("test_flag", true)
      manager.set_variable("test_var", 42)
      manager.start_quest("test_quest")
      manager.unlock_achievement("test_achievement")

      # Save to JSON
      json_str = manager.to_json
      json_str.includes?("test_flag").should be_true
      json_str.includes?("test_var").should be_true

      # Load from JSON
      loaded = PointClickEngine::Core::GameStateManager.from_json(json_str)
      loaded.get_flag("test_flag").should be_true
      loaded.get_variable("test_var").should eq 42
      loaded.is_quest_active?("test_quest").should be_true
      loaded.is_achievement_unlocked?("test_achievement").should be_true
    end
  end

  describe "debug utilities" do
    it "generates debug dump" do
      manager = PointClickEngine::Core::GameStateManager.new

      manager.set_flag("test_flag", true)
      manager.set_variable("test_var", 42)

      dump = manager.debug_dump
      dump.includes?("test_flag").should be_true
      dump.includes?("test_var").should be_true
      dump.includes?("GAME STATE DEBUG").should be_true
    end
  end
end
