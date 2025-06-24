require "../../spec_helper"

describe "Engine GameStateManager Integration" do
  describe "engine properties" do
    it "can set and get game_state_manager" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "State Test")

      engine.game_state_manager.should be_nil

      gsm = PointClickEngine::GameStateManager.new
      engine.game_state_manager = gsm

      engine.game_state_manager.should eq(gsm)
    end

    it "can set and get quest_manager" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Quest Test")

      engine.quest_manager.should be_nil

      qm = PointClickEngine::QuestManager.new
      engine.quest_manager = qm

      engine.quest_manager.should eq(qm)
    end
  end

  describe "update callback integration" do
    it "updates game state manager during engine update" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Update Test")
      RL.init_window(800, 600, "Update Test")
      engine.init

      gsm = PointClickEngine::GameStateManager.new
      qm = PointClickEngine::QuestManager.new

      engine.game_state_manager = gsm
      engine.quest_manager = qm

      # Add a timer to test update
      timer_fired = false
      gsm.set_timer("test_timer", 1.0f32)

      # Add handler for timer expiration
      gsm.add_change_handler(->(name : String, value : PointClickEngine::Core::GameValue) {
        if name == "timer_expired:test_timer"
          timer_fired = true
        end
      })

      # Set up the update callback like GameConfig does
      engine.on_update = ->(dt : Float32) {
        gsm.update_timers(dt)
        gsm.update_game_time(dt)
        qm.update_all_quests(gsm, dt)
      }

      # Simulate updates
      engine.update(0.5f32)
      timer_fired.should be_false

      engine.update(0.6f32) # Total 1.1 seconds
      timer_fired.should be_true

      # Check game time was updated
      gsm.game_time.should be_close(1.1, 0.01)

      # Cleanup
      RL.close_window
    end
  end

  describe "config integration" do
    it "creates and connects managers from config" do
      config_yaml = <<-YAML
      game:
        title: "Manager Test"
      
      initial_state:
        flags:
          test_flag: true
        variables:
          test_var: 42
          game_time: 0.0
      YAML

      File.write("manager_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("manager_config.yaml")

      RL.init_window(800, 600, "Manager Test")
      engine = config.create_engine

      # Managers should be created
      engine.game_state_manager.should_not be_nil
      engine.quest_manager.should_not be_nil

      gsm = engine.game_state_manager.not_nil!

      # Initial state should be set
      gsm.get_flag("test_flag").should be_true
      gsm.get_variable("test_var").should eq(42)

      # Update callback should be set
      engine.on_update.should_not be_nil

      # Test update works
      engine.update(1.0f32)
      gsm.game_time.should be_close(1.0, 0.01)

      # Cleanup
      RL.close_window
      File.delete("manager_config.yaml")
    end

    it "handles state change events for quest updates" do
      config_yaml = <<-YAML
      game:
        title: "State Change Test"
      
      assets:
        scenes: ["test_scenes/*.yaml"]
        quests: ["test_quests/*.yaml"]
      
      start_scene: "test_scene"
      
      initial_state:
        flags:
          game_started: true
      YAML

      # Create directories and files
      Dir.mkdir_p("test_quests")
      Dir.mkdir_p("test_scenes")
      quest_yaml = <<-YAML
      - id: test_quest
        name: "Test Quest"
        description: "A test quest"
        category: main
        auto_start: true
        start_condition: "game_started"
        objectives:
          - id: obj1
            description: "Complete objective"
            condition: "objective_done"
      YAML

      File.write("test_quests/quest.yaml", quest_yaml)

      # Create minimal scene
      scene_yaml = <<-YAML
      name: test_scene
      YAML
      File.write("test_scenes/test_scene.yaml", scene_yaml)

      File.write("state_change_config.yaml", config_yaml)

      config = PointClickEngine::Core::GameConfig.from_file("state_change_config.yaml")

      RL.init_window(800, 600, "State Change Test")
      engine = config.create_engine

      gsm = engine.game_state_manager.not_nil!
      qm = engine.quest_manager.not_nil!

      # Quest should be loaded
      quest = qm.get_quest("test_quest")
      quest.should_not be_nil

      # The quest needs an update cycle to auto-start
      qm.update_all_quests(gsm, 0.0f32)

      # Quest should be active (not completed yet)
      quest.try(&.active).should be_true
      quest.try(&.completed).should be_false

      # Setting flag should trigger quest update through state change handler
      gsm.set_flag("objective_done", true)

      # Quest should complete
      quest.try(&.objectives.first.completed).should be_true

      # Cleanup
      RL.close_window
      File.delete("state_change_config.yaml")
      File.delete("test_quests/quest.yaml")
      File.delete("test_scenes/test_scene.yaml")
      Dir.delete("test_quests")
      Dir.delete("test_scenes")
    end
  end

  describe "timer management" do
    pending "creates UI hint timers that auto-hide elements" do
      # This functionality is not yet implemented in GameConfig
      config_yaml = <<-YAML
      game:
        title: "Timer Test"
      
      ui:
        hints:
          - text: "Test hint"
            duration: 0.5
      YAML

      File.write("timer_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("timer_config.yaml")

      RL.init_window(800, 600, "Timer Test")
      engine = config.create_engine

      # Trigger game:new to set up UI
      engine.event_system.trigger("game:new")
      engine.event_system.process_events

      gui = engine.gui
      gui.should_not be_nil

      # Hint should be added
      gui.try(&.labels.has_key?("hint_0")).should be_true

      gsm = engine.game_state_manager.not_nil!

      # Timer should exist
      gsm.has_timer?("hide_hint_0").should be_true

      # Simulate time passing
      10.times { engine.update(0.1f32) } # 1 second total

      # Hint should be removed after 0.5 seconds
      gui.try(&.labels.has_key?("hint_0")).should be_false

      # Cleanup
      RL.close_window
      File.delete("timer_config.yaml")
    end
  end
end
