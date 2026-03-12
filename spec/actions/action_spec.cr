require "../spec_helper"
require "../../src/actions/action"

describe PointClickEngine::Actions::ActionData do
  describe "#initialize" do
    it "creates with type only" do
      data = PointClickEngine::Actions::ActionData.new("wait")
      data.type.should eq("wait")
      data.params.should be_empty
      data.duration.should eq(0.0f32)
    end

    it "creates with type and duration" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.5f32)
      data.type.should eq("wait")
      data.duration.should eq(2.5f32)
    end

    it "creates with params" do
      params = {"character" => YAML::Any.new("player"), "text" => YAML::Any.new("Hello")}
      data = PointClickEngine::Actions::ActionData.new("dialog", params, 3.0f32)
      data.type.should eq("dialog")
      data.params["character"].as_s.should eq("player")
      data.params["text"].as_s.should eq("Hello")
      data.duration.should eq(3.0f32)
    end
  end

  describe ".create" do
    it "creates with named parameters" do
      data = PointClickEngine::Actions::ActionData.create("character_move",
        duration: 1.0f32,
        character: "player",
        x: 400,
        y: 300
      )
      data.type.should eq("character_move")
      data.duration.should eq(1.0f32)
      data.params["character"].as_s.should eq("player")
      data.params["x"].as_i.should eq(400)
      data.params["y"].as_i.should eq(300)
    end

    it "handles various value types" do
      data = PointClickEngine::Actions::ActionData.create("test",
        str: "text",
        num: 42,
        float_val: 3.14,
        bool_val: true
      )
      data.params["str"].as_s.should eq("text")
      data.params["num"].as_i.should eq(42)
      data.params["float_val"].as_f.should be_close(3.14, 0.001)
      data.params["bool_val"].as_bool.should be_true
    end
  end
end

describe PointClickEngine::Actions::ActionInstance do
  describe "#initialize" do
    it "starts in pending state" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)

      instance.state.should eq(PointClickEngine::Actions::ActionState::Pending)
      instance.elapsed.should eq(0.0f32)
      instance.started.should be_false
      instance.finished?.should be_false
      instance.running?.should be_false
    end
  end

  describe "#progress" do
    it "returns 0 at start" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.progress.should eq(0.0f32)
    end

    it "returns 0.5 at halfway" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.elapsed = 1.0f32
      instance.progress.should eq(0.5f32)
    end

    it "returns 1 at completion" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.elapsed = 2.0f32
      instance.progress.should eq(1.0f32)
    end

    it "clamps to 1 when exceeded" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.elapsed = 5.0f32
      instance.progress.should eq(1.0f32)
    end

    it "returns 1 for instant actions (duration 0)" do
      data = PointClickEngine::Actions::ActionData.new("instant")
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.progress.should eq(1.0f32)
    end
  end

  describe "#remaining_time" do
    it "returns full duration at start" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.remaining_time.should eq(2.0f32)
    end

    it "returns correct remaining time" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.elapsed = 0.5f32
      instance.remaining_time.should eq(1.5f32)
    end

    it "returns 0 when completed" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 2.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.elapsed = 2.0f32
      instance.remaining_time.should eq(0.0f32)
    end
  end

  describe "state transitions" do
    it "transitions to running on start!" do
      data = PointClickEngine::Actions::ActionData.new("wait")
      instance = PointClickEngine::Actions::ActionInstance.new(data)

      instance.start!

      instance.started.should be_true
      instance.state.should eq(PointClickEngine::Actions::ActionState::Running)
      instance.running?.should be_true
      instance.finished?.should be_false
    end

    it "transitions to completed on complete!" do
      data = PointClickEngine::Actions::ActionData.new("wait")
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.start!

      instance.complete!

      instance.state.should eq(PointClickEngine::Actions::ActionState::Completed)
      instance.finished?.should be_true
      instance.running?.should be_false
    end

    it "transitions to cancelled on cancel!" do
      data = PointClickEngine::Actions::ActionData.new("wait")
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.start!

      instance.cancel!

      instance.state.should eq(PointClickEngine::Actions::ActionState::Cancelled)
      instance.finished?.should be_true
      instance.running?.should be_false
    end
  end

  describe "#reset" do
    it "resets all state" do
      data = PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32)
      instance = PointClickEngine::Actions::ActionInstance.new(data)
      instance.start!
      instance.elapsed = 0.5f32
      instance.set_custom("key", "value")
      instance.complete!

      instance.reset

      instance.state.should eq(PointClickEngine::Actions::ActionState::Pending)
      instance.elapsed.should eq(0.0f32)
      instance.started.should be_false
      instance.custom_data.should be_empty
    end
  end

  describe "custom data" do
    it "stores and retrieves custom data" do
      data = PointClickEngine::Actions::ActionData.new("wait")
      instance = PointClickEngine::Actions::ActionInstance.new(data)

      instance.set_custom("key1", "string_value")
      instance.set_custom("key2", 42)
      instance.set_custom("key3", true)

      instance.get_custom("key1").not_nil!.as_s.should eq("string_value")
      instance.get_custom("key2").not_nil!.as_i.should eq(42)
      instance.get_custom("key3").not_nil!.as_bool.should be_true
    end

    it "returns nil for missing keys" do
      data = PointClickEngine::Actions::ActionData.new("wait")
      instance = PointClickEngine::Actions::ActionInstance.new(data)

      instance.get_custom("nonexistent").should be_nil
    end
  end

  describe "callback support" do
    it "stores callback proc" do
      data = PointClickEngine::Actions::ActionData.new("callback")
      called = false
      callback = ->{ called = true; nil }

      instance = PointClickEngine::Actions::ActionInstance.new(data, callback)

      instance.callback.should_not be_nil
      instance.callback.not_nil!.call
      called.should be_true
    end
  end
end
