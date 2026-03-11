# Scene Integration Spec - Tests action runner integration
# Verifies that Scenes can run ActionRunners directly

require "../spec_helper"

describe "Scene Action Runner Integration" do
  describe "script_runner property" do
    it "initializes with nil script_runner" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.script_runner.should be_nil
    end

    it "allows setting script_runner" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
      scene.script_runner = runner
      scene.script_runner.should eq(runner)
    end
  end

  describe "#run_script" do
    it "sets and starts the action runner" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
        runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32))

        scene.run_script(runner)

        scene.script_runner.should eq(runner)
        runner.running.should be_true
      end
    end
  end

  describe "#script_running?" do
    it "returns false when no script is running" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.script_running?.should be_false
    end

    it "returns true when a script is running" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
        runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32))
        scene.run_script(runner)

        scene.script_running?.should be_true
      end
    end
  end

  describe "#stop_script" do
    it "stops a running script" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
        runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32))
        scene.run_script(runner)

        scene.stop_script

        scene.script_runner.should be_nil
        runner.running.should be_false
      end
    end

    it "handles stop when no script is running" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.stop_script
      scene.script_runner.should be_nil
    end
  end

  describe "#skip_script" do
    it "skips a running script" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        engine.current_scene = scene  # Set as current scene for ActionRunner
        runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
        runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 5.0f32))
        scene.run_script(runner)

        scene.skip_script

        runner.running.should be_false
        runner.completed.should be_true
      end
    end

    it "handles skip when no script is running" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.skip_script
      # Should not raise
      scene.script_runner.should be_nil
    end
  end

  describe "#update integration" do
    it "updates the script runner when called" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        engine.current_scene = scene  # Set as current scene for ActionRunner
        runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
        runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 0.1f32))
        scene.run_script(runner)

        # Update should progress the action
        scene.update(0.05f32)
        runner.running.should be_true

        # Complete the action
        scene.update(0.1f32)
        runner.completed.should be_true
      end
    end

    it "clears completed script runner" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        engine.current_scene = scene  # Set as current scene for ActionRunner
        runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
        runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 0.05f32))
        scene.run_script(runner)

        # Complete the action
        scene.update(0.1f32)

        # Script runner should be cleared
        scene.script_runner.should be_nil
      end
    end
  end

  describe "#draw integration" do
    it "calls draw on script runner without error" do
      with_test_window do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        scene = PointClickEngine::Scenes::Scene.new("test")
        engine.current_scene = scene  # Set as current scene for ActionRunner
        runner = PointClickEngine::Actions::ActionRunner.new("test_runner")
        runner.add(PointClickEngine::Actions::ActionData.new("show_text", {
          "text" => YAML::Any.new("Hello"),
        } of String => YAML::Any, duration: 1.0f32))
        scene.run_script(runner)

        # This should not raise
        RL.begin_drawing
        scene.draw(nil)
        RL.end_drawing
      end
    end
  end
end

describe "ActionLoader" do
  describe ".load" do
    it "loads an action sequence from YAML content" do
      # Create a temporary YAML file
      yaml_content = <<-YAML
        name: test_sequence
        skippable: true
        actions:
          - type: wait
            duration: 1.0
          - type: fade_in
            duration: 0.5
        YAML

      # Write to temp file
      temp_path = File.tempname("action_sequence", ".yaml")
      File.write(temp_path, yaml_content)

      begin
        runner = PointClickEngine::Actions::ActionLoader.load(temp_path)

        runner.name.should eq("test_sequence")
        runner.skippable.should be_true
        runner.actions.size.should eq(2)
        runner.actions[0].data.type.should eq("wait")
        runner.actions[0].data.duration.should eq(1.0f32)
        runner.actions[1].data.type.should eq("fade_in")
        runner.actions[1].data.duration.should eq(0.5f32)
      ensure
        File.delete(temp_path) if File.exists?(temp_path)
      end
    end

    it "parses parallel action blocks" do
      yaml_content = <<-YAML
        name: parallel_test
        actions:
          - type: parallel
            actions:
              - type: character_move
                character: player
                to: {x: 100, y: 200}
              - type: camera_pan
                to: {x: 500, y: 300}
                duration: 2.0
        YAML

      temp_path = File.tempname("parallel_sequence", ".yaml")
      File.write(temp_path, yaml_content)

      begin
        runner = PointClickEngine::Actions::ActionLoader.load(temp_path)

        runner.name.should eq("parallel_test")
        # The main runner should have a parallel marker
        runner.actions.size.should eq(1)
        runner.actions[0].data.type.should eq("_parallel_marker")
      ensure
        File.delete(temp_path) if File.exists?(temp_path)
      end
    end

    it "uses filename as name when not specified" do
      yaml_content = <<-YAML
        actions:
          - type: wait
            duration: 1.0
        YAML

      temp_path = File.tempname("my_custom_sequence", ".yaml")
      File.write(temp_path, yaml_content)

      begin
        runner = PointClickEngine::Actions::ActionLoader.load(temp_path)
        # Name should be derived from filename (minus extension and temp prefix)
        runner.name.should_not be_empty
      ensure
        File.delete(temp_path) if File.exists?(temp_path)
      end
    end

    it "preserves action parameters" do
      yaml_content = <<-YAML
        name: params_test
        actions:
          - type: character_move
            character: hero
            to:
              x: 400
              y: 300
            pathfinding: false
        YAML

      temp_path = File.tempname("params_sequence", ".yaml")
      File.write(temp_path, yaml_content)

      begin
        runner = PointClickEngine::Actions::ActionLoader.load(temp_path)

        runner.actions.size.should eq(1)
        action = runner.actions[0]
        action.data.params["character"]?.should_not be_nil
        action.data.params["character"].as_s.should eq("hero")
        action.data.params["to"]?.should_not be_nil
        action.data.params["pathfinding"]?.try(&.as_bool).should eq(false)
      ensure
        File.delete(temp_path) if File.exists?(temp_path)
      end
    end
  end
end
