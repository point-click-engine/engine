require "../spec_helper"

describe PointClickEngine::Cutscenes::Cutscene do
  it "executes actions in sequence" do
    cutscene = PointClickEngine::Cutscenes::Cutscene.new("test_cutscene")

    counter = 0
    cutscene.run { counter += 1 }
    cutscene.wait(0.5f32)
    cutscene.run { counter += 10 }

    cutscene.play
    cutscene.playing.should be_true

    # First action (instant callback)
    cutscene.update(0.1f32)
    counter.should eq(1)
    cutscene.current_action_index.should eq(1) # Should move to wait action

    # Wait action (0.5s duration)
    cutscene.update(0.3f32)
    counter.should eq(1)                       # Still waiting
    cutscene.current_action_index.should eq(1) # Still on wait action

    cutscene.update(0.3f32)                    # Complete wait (total 0.6s for wait action)
    cutscene.current_action_index.should eq(2) # Should move to third action

    # Need another update to execute the third action
    cutscene.update(0.1f32)
    counter.should eq(11) # Second callback executed

    cutscene.completed.should be_true
    cutscene.playing.should be_false
  end

  it "can be stopped" do
    cutscene = PointClickEngine::Cutscenes::Cutscene.new("test_cutscene")
    completed = false

    cutscene.wait(1.0f32)
    cutscene.on_complete = -> { completed = true }

    cutscene.play
    cutscene.update(0.1f32)

    cutscene.stop
    cutscene.playing.should be_false
    completed.should be_true
  end

  it "can be skipped if skippable" do
    cutscene = PointClickEngine::Cutscenes::Cutscene.new("test_cutscene")
    cutscene.skippable = true

    cutscene.wait(10.0f32)
    cutscene.play

    cutscene.skip
    cutscene.playing.should be_false
  end

  it "cannot be skipped if not skippable" do
    cutscene = PointClickEngine::Cutscenes::Cutscene.new("test_cutscene")
    cutscene.skippable = false

    cutscene.wait(10.0f32)
    cutscene.play

    cutscene.skip
    cutscene.playing.should be_true
  end

  it "supports parallel actions with DSL" do
    cutscene = PointClickEngine::Cutscenes::Cutscene.new("test_cutscene")
    counter = 0

    cutscene.parallel do
      run { counter += 1 }
      wait(0.5f32)
      run { counter += 10 }
    end

    cutscene.play
    cutscene.update(0.1f32)

    counter.should eq(11) # Both callbacks in parallel block executed
  end
end
