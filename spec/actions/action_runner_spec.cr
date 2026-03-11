require "../spec_helper"
require "../../src/actions/action"
require "../../src/actions/action_runner"

describe PointClickEngine::Actions::ActionRunner do
  describe "#initialize" do
    it "creates with name" do
      runner = PointClickEngine::Actions::ActionRunner.new("test_sequence")
      runner.name.should eq("test_sequence")
      runner.running.should be_false
      runner.completed.should be_false
      runner.skippable.should be_true
      runner.action_count.should eq(0)
    end
  end

  describe "#add" do
    it "adds ActionData" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32)

      runner.add(data)

      runner.action_count.should eq(1)
    end

    it "adds ActionInstance" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)

      runner.add(instance)

      runner.action_count.should eq(1)
    end

    it "adds multiple actions" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")

      runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 0.5f32))
      runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 0.5f32))
      runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 0.5f32))

      runner.action_count.should eq(3)
    end
  end

  describe "#add_callback" do
    it "adds callback action" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      called = false

      runner.add_callback(-> { called = true; nil })

      runner.action_count.should eq(1)
      # Callback is stored in the action instance
      runner.actions.first.callback.should_not be_nil
    end
  end

  describe "#add_parallel" do
    it "creates parallel marker and runner" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")

      runner.add_parallel([
        PointClickEngine::Actions::ActionData.new("wait", duration: 0.5f32),
        PointClickEngine::Actions::ActionData.new("wait", duration: 0.5f32),
      ])

      # Should add one marker action
      runner.action_count.should eq(1)
      runner.actions.first.data.type.should eq("_parallel_marker")
    end
  end

  describe "#progress" do
    it "returns 0 initially" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32))
      runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32))

      runner.progress.should eq(0.0f32)
    end

    it "returns 1 for empty runner" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      runner.progress.should eq(1.0f32)
    end
  end

  describe "#reset" do
    it "resets runner state" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32))
      runner.running = true
      runner.completed = true
      runner.current_index = 1

      runner.reset

      runner.running.should be_false
      runner.completed.should be_false
      runner.current_index.should eq(0)
    end

    it "resets all action instances" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32)
      runner.add(data)

      # Manually modify action state
      runner.actions.first.start!
      runner.actions.first.elapsed = 0.5f32

      runner.reset

      runner.actions.first.started.should be_false
      runner.actions.first.elapsed.should eq(0.0f32)
      runner.actions.first.state.should eq(PointClickEngine::Actions::ActionState::Pending)
    end
  end

  describe "callbacks" do
    it "accepts on_complete callback" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")
      completed = false

      runner.on_complete = -> { completed = true; nil }

      runner.on_complete.should_not be_nil
    end

    it "accepts on_action_start callback" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")

      runner.on_action_start = ->(action : PointClickEngine::Actions::ActionInstance) { nil }

      runner.on_action_start.should_not be_nil
    end

    it "accepts on_action_complete callback" do
      runner = PointClickEngine::Actions::ActionRunner.new("test")

      runner.on_action_complete = ->(action : PointClickEngine::Actions::ActionInstance) { nil }

      runner.on_action_complete.should_not be_nil
    end
  end

  describe "start conditions" do
    it "evaluates skip conditions when playback begins" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        engine.current_scene = scene
        engine.game_state_manager = PointClickEngine::Core::GameStateManager.new(engine.event_bus)
        engine.game_state_manager.not_nil!.set_flag("skip_intro", true)

        yaml_content = <<-YAML
          name: conditional_sequence
          checkpoints:
            - name: mid_point
              time: 1.0
          conditions:
            - name: skip_intro
              check: "skip_intro"
              skip_to: "mid_point"
          actions:
            - type: wait
              duration: 1.0
            - type: wait
              duration: 1.0
          YAML

        temp_path = File.tempname("conditional_sequence", ".yaml")
        File.write(temp_path, yaml_content)

        begin
          runner = PointClickEngine::Actions::ActionLoader.load(temp_path)
          scene.run_script(runner)

          runner.current_index.should eq(1)
        ensure
          File.delete(temp_path) if File.exists?(temp_path)
        end
      end
    end
  end
end
