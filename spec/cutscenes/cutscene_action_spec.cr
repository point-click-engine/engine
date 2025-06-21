require "../spec_helper"

describe PointClickEngine::Cutscenes::CutsceneAction do
  describe PointClickEngine::Cutscenes::WaitAction do
    it "completes after specified duration" do
      action = PointClickEngine::Cutscenes::WaitAction.new(1.0f32)

      action.completed.should be_false
      action.update(0.5f32)
      action.completed.should be_false

      action.update(0.5f32)
      action.completed.should be_true
    end

    it "can be reset" do
      action = PointClickEngine::Cutscenes::WaitAction.new(1.0f32)
      action.update(1.0f32)
      action.completed.should be_true

      action.reset
      action.completed.should be_false
      action.started.should be_false
    end
  end

  describe PointClickEngine::Cutscenes::CallbackAction do
    it "executes callback immediately" do
      called = false
      action = PointClickEngine::Cutscenes::CallbackAction.new(-> { called = true })

      action.update(0.1f32)
      called.should be_true
      action.completed.should be_true
    end
  end

  describe PointClickEngine::Cutscenes::ParallelAction do
    it "runs all actions in parallel" do
      counter = 0
      action1 = PointClickEngine::Cutscenes::CallbackAction.new(-> { counter += 1 })
      action2 = PointClickEngine::Cutscenes::CallbackAction.new(-> { counter += 10 })
      action3 = PointClickEngine::Cutscenes::WaitAction.new(0.5f32)

      parallel = PointClickEngine::Cutscenes::ParallelAction.new([action1, action2, action3])

      parallel.update(0.1f32)
      counter.should eq(11)              # Both callbacks executed
      parallel.completed.should be_false # Wait action still running

      parallel.update(0.5f32)
      parallel.completed.should be_true # All actions completed
    end
  end
end
