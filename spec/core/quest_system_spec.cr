require "../spec_helper"
require "../../src/core/game_state_manager"
require "../../src/core/quest_system"

describe PointClickEngine::Core::QuestObjective do
  it "initializes with required properties" do
    objective = PointClickEngine::Core::QuestObjective.new("find_key", "Find the brass key", "has_key == true")

    objective.id.should eq "find_key"
    objective.description.should eq "Find the brass key"
    objective.condition.should eq "has_key == true"
    objective.completed.should be_false
    objective.optional.should be_false
    objective.hidden.should be_false
  end

  it "checks completion against game state" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    objective = PointClickEngine::Core::QuestObjective.new("find_key", "Find the brass key", "has_key")

    # Objective not complete initially
    objective.check_completion(state_manager).should be_false
    objective.completed.should be_false

    # Set flag to complete objective
    state_manager.set_flag("has_key", true)
    objective.check_completion(state_manager).should be_true
    objective.completed.should be_true

    # Once completed, stays completed
    state_manager.set_flag("has_key", false)
    objective.check_completion(state_manager).should be_true
  end

  it "can be reset" do
    objective = PointClickEngine::Core::QuestObjective.new("test", "Test objective", "test_flag")
    objective.completed = true

    objective.reset
    objective.completed.should be_false
  end
end

describe PointClickEngine::Core::QuestReward do
  it "initializes with reward data" do
    reward = PointClickEngine::Core::QuestReward.new("item", "gold_coin", 10)

    reward.type.should eq "item"
    reward.identifier.should eq "gold_coin"
    reward.amount.should eq 10
  end
end

describe PointClickEngine::Core::Quest do
  it "initializes with basic properties" do
    quest = PointClickEngine::Core::Quest.new("find_wizard", "Find the Wizard", "Locate the missing wizard")

    quest.id.should eq "find_wizard"
    quest.name.should eq "Find the Wizard"
    quest.description.should eq "Locate the missing wizard"
    quest.active.should be_false
    quest.completed.should be_false
    quest.failed.should be_false
    quest.current_step.should eq "start"
  end

  it "adds objectives and rewards" do
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")

    quest.add_objective("obj1", "First objective", "flag1")
    quest.add_reward("flag", "quest_reward", 1)

    quest.objectives.size.should eq 1
    quest.rewards.size.should eq 1

    objective = quest.objectives[0]
    objective.id.should eq "obj1"
    objective.description.should eq "First objective"
    objective.condition.should eq "flag1"

    reward = quest.rewards[0]
    reward.type.should eq "flag"
    reward.identifier.should eq "quest_reward"
  end

  it "manages quest lifecycle" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")

    # Quest can start
    quest.can_start?(state_manager).should be_true

    # Start quest
    quest.start(state_manager)
    quest.active.should be_true
    quest.completed.should be_false

    # Can't start again while active
    quest.can_start?(state_manager).should be_false

    # Complete quest
    quest.complete(state_manager)
    quest.active.should be_false
    quest.completed.should be_true
    quest.completion_time.should eq state_manager.game_time
  end

  it "tracks objective completion" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")

    quest.add_objective("obj1", "Find key", "has_key")
    quest.add_objective("obj2", "Open door", "door_open")
    quest.start(state_manager)

    # No objectives complete initially
    quest.update_progress(state_manager).should be_false
    quest.completed.should be_false

    # Complete first objective
    state_manager.set_flag("has_key", true)
    quest.update_progress(state_manager).should be_false # Still not complete

    # Complete second objective
    state_manager.set_flag("door_open", true)
    quest.update_progress(state_manager).should be_true # Quest complete
    quest.completed.should be_true
  end

  it "handles optional objectives" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")

    quest.add_objective("required", "Required objective", "required_flag")
    quest.add_objective("optional", "Optional objective", "optional_flag", optional: true)
    quest.start(state_manager)

    # Complete only required objective
    state_manager.set_flag("required_flag", true)
    quest.update_progress(state_manager).should be_true # Quest complete without optional
    quest.completed.should be_true
  end

  it "can be failed and abandoned" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")
    quest.start(state_manager)

    # Fail quest
    quest.fail(state_manager, "Time ran out")
    quest.active.should be_false
    quest.failed.should be_true
    quest.completed.should be_false

    # Reset and test abandonment
    quest.reset
    quest.start(state_manager)
    quest.abandon(state_manager)
    quest.active.should be_false
    quest.failed.should be_false
    quest.completed.should be_false
  end

  it "calculates progress correctly" do
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")

    quest.add_objective("obj1", "Objective 1", "flag1")
    quest.add_objective("obj2", "Objective 2", "flag2")
    quest.add_objective("obj3", "Objective 3", "flag3")

    # Quest needs to be active for progress calculation
    quest.active = true
    quest.get_completion_percentage.should eq 0.0f32

    # Complete one objective
    quest.objectives[0].completed = true
    quest.get_completion_percentage.should be_close(33.33f32, 0.1f32)

    # Complete all objectives
    quest.objectives.each { |obj| obj.completed = true }
    quest.get_completion_percentage.should eq 100.0f32
  end

  it "gets progress text" do
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")

    quest.get_progress_text.should eq "Not started"

    quest.active = true
    quest.add_objective("obj1", "Objective 1", "flag1")
    quest.get_progress_text.should eq "0/1 objectives completed"

    quest.completed = true
    quest.get_progress_text.should eq "Completed"

    quest.completed = false
    quest.failed = true
    quest.get_progress_text.should eq "Failed"
  end
end

describe PointClickEngine::Core::QuestManager do
  it "initializes empty" do
    manager = PointClickEngine::Core::QuestManager.new

    manager.quests.should be_empty
    manager.active_notifications.should be_empty
  end

  it "adds and manages quests" do
    manager = PointClickEngine::Core::QuestManager.new
    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")

    manager.add_quest(quest)
    manager.quests.size.should eq 1
    manager.get_quest("test_quest").should eq quest
  end

  it "creates quests with helper method" do
    manager = PointClickEngine::Core::QuestManager.new

    quest = manager.create_quest("new_quest", "New Quest", "Description")
    quest.id.should eq "new_quest"
    quest.name.should eq "New Quest"
    manager.get_quest("new_quest").should eq quest
  end

  it "starts quests with state validation" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    manager = PointClickEngine::Core::QuestManager.new

    quest = PointClickEngine::Core::Quest.new("test_quest", "Test Quest", "A test quest")
    quest.start_condition = "has_permission"
    manager.add_quest(quest)

    # Can't start without condition
    manager.start_quest("test_quest", state_manager).should be_false
    quest.active.should be_false

    # Can start with condition
    state_manager.set_flag("has_permission", true)
    manager.start_quest("test_quest", state_manager).should be_true
    quest.active.should be_true
  end

  it "filters quests by status" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    manager = PointClickEngine::Core::QuestManager.new

    # Create test quests
    quest1 = manager.create_quest("active", "Active Quest", "")
    quest2 = manager.create_quest("completed", "Completed Quest", "")
    quest3 = manager.create_quest("failed", "Failed Quest", "")

    quest1.start(state_manager)
    quest2.start(state_manager)
    quest2.complete(state_manager)
    quest3.start(state_manager)
    quest3.fail(state_manager)

    manager.get_active_quests.size.should eq 1
    manager.get_completed_quests.size.should eq 1
    manager.get_failed_quests.size.should eq 1

    manager.get_active_quests[0].should eq quest1
    manager.get_completed_quests[0].should eq quest2
    manager.get_failed_quests[0].should eq quest3
  end

  it "filters quests by category" do
    manager = PointClickEngine::Core::QuestManager.new

    main_quest = manager.create_quest("main", "Main Quest", "")
    main_quest.category = "main"

    side_quest = manager.create_quest("side", "Side Quest", "")
    side_quest.category = "side"

    main_quests = manager.get_quests_by_category("main")
    side_quests = manager.get_quests_by_category("side")

    main_quests.size.should eq 1
    side_quests.size.should eq 1
    main_quests[0].should eq main_quest
    side_quests[0].should eq side_quest
  end

  it "updates all quest progress" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    manager = PointClickEngine::Core::QuestManager.new

    quest = manager.create_quest("test", "Test Quest", "")
    quest.add_objective("find_key", "Find key", "has_key")
    quest.start(state_manager)

    # Quest not complete initially
    manager.update_all_quests(state_manager, 0.1f32)
    quest.completed.should be_false

    # Complete objective
    state_manager.set_flag("has_key", true)
    manager.update_all_quests(state_manager, 0.1f32)
    quest.completed.should be_true
  end

  it "handles auto-start quests" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    manager = PointClickEngine::Core::QuestManager.new

    quest = manager.create_quest("auto", "Auto Quest", "")
    quest.auto_start = true
    quest.start_condition = "auto_trigger"

    # Not auto-started initially
    manager.update_all_quests(state_manager, 0.1f32)
    quest.active.should be_false

    # Auto-started when condition met
    state_manager.set_flag("auto_trigger", true)
    manager.update_all_quests(state_manager, 0.1f32)
    quest.active.should be_true
  end

  it "manages quest abandonment" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    manager = PointClickEngine::Core::QuestManager.new

    quest = manager.create_quest("abandon_test", "Abandon Test", "")
    quest.can_abandon = true
    quest.start(state_manager)

    manager.abandon_quest("abandon_test", state_manager).should be_true
    quest.active.should be_false
    quest.completed.should be_false
    quest.failed.should be_false
  end

  it "handles notifications" do
    manager = PointClickEngine::Core::QuestManager.new

    manager.add_notification("Test notification")
    notifications = manager.get_notifications
    notifications.size.should eq 1
    notifications[0].should eq "Test notification"

    manager.clear_notifications
    manager.get_notifications.should be_empty
  end

  it "generates debug dump" do
    state_manager = PointClickEngine::Core::GameStateManager.new
    manager = PointClickEngine::Core::QuestManager.new

    quest = manager.create_quest("test", "Test Quest", "")
    quest.start(state_manager)

    dump = manager.debug_dump
    dump.should contain "QUEST MANAGER DEBUG"
    dump.should contain "Total Quests: 1"
    dump.should contain "Active: 1"
  end
end
