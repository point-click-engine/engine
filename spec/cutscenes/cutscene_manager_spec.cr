require "../spec_helper"

describe PointClickEngine::Cutscenes::CutsceneManager do
  it "manages multiple cutscenes" do
    manager = PointClickEngine::Cutscenes::CutsceneManager.new

    cutscene1 = PointClickEngine::Cutscenes::Cutscene.new("intro")
    cutscene2 = PointClickEngine::Cutscenes::Cutscene.new("outro")

    manager.add_cutscene(cutscene1)
    manager.add_cutscene(cutscene2)

    manager.cutscenes.size.should eq(2)
  end

  it "plays cutscenes by name" do
    manager = PointClickEngine::Cutscenes::CutsceneManager.new

    counter = 0
    cutscene = PointClickEngine::Cutscenes::Cutscene.new("test")
    cutscene.run { counter = 42 }

    manager.add_cutscene(cutscene)
    manager.play_cutscene("test").should be_true
    manager.is_playing?.should be_true

    manager.update(0.1f32)
    counter.should eq(42)
  end

  it "returns false for non-existent cutscene" do
    manager = PointClickEngine::Cutscenes::CutsceneManager.new
    manager.play_cutscene("nonexistent").should be_false
  end

  it "clears current cutscene when completed" do
    manager = PointClickEngine::Cutscenes::CutsceneManager.new

    cutscene = PointClickEngine::Cutscenes::Cutscene.new("test")
    cutscene.wait(0.5f32)

    manager.add_cutscene(cutscene)
    manager.play_cutscene("test")

    manager.update(0.6f32)
    manager.is_playing?.should be_false
    manager.current_cutscene.should be_nil
  end

  it "creates cutscenes with DSL" do
    manager = PointClickEngine::Cutscenes::CutsceneManager.new
    counter = 0

    created_cutscene = manager.create_cutscene("dsl_test") do
      run { counter = 1 }
      wait(0.1f32)
      run { counter = 2 }
    end

    created_cutscene.name.should eq("dsl_test")
    manager.cutscenes.has_key?("dsl_test").should be_true

    manager.play_cutscene("dsl_test")
    manager.update(0.05f32) # Execute first callback
    counter.should eq(1)

    manager.update(0.1f32)  # Complete the 0.1s wait
    manager.update(0.01f32) # Execute second callback
    counter.should eq(2)
  end
end
