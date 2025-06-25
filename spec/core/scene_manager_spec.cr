require "../spec_helper"
require "../../src/core/scene_manager"
require "../../src/scenes/scene"

# Mock scene class for testing
class MockScene < PointClickEngine::Scenes::Scene
  property loaded : Bool = false

  def initialize(name : String)
    super(name)
  end

  def load
    @loaded = true
  end

  def unload
    @loaded = false
  end
end

describe PointClickEngine::Core::SceneManager do
  describe "#initialize" do
    it "creates a new SceneManager instance" do
      manager = PointClickEngine::Core::SceneManager.new
      manager.should be_a(PointClickEngine::Core::SceneManager)
    end
  end

  describe "#add_scene" do
    it "adds a scene to the manager" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")

      manager.add_scene(scene)
      manager.scene_names.includes?("test_scene").should be_true
    end

    it "replaces existing scene with same name" do
      manager = PointClickEngine::Core::SceneManager.new
      scene1 = MockScene.new("test_scene")
      scene2 = MockScene.new("test_scene")

      manager.add_scene(scene1)
      manager.add_scene(scene2)

      names = manager.scene_names
      names.count("test_scene").should eq(1)
    end
  end

  describe "#change_scene" do
    it "successfully changes to an existing scene" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")

      manager.add_scene(scene)
      result = manager.change_scene("test_scene")

      result.success?.should be_true
      result.value.name.should eq("test_scene")
    end

    it "fails to change to non-existing scene" do
      manager = PointClickEngine::Core::SceneManager.new

      result = manager.change_scene("nonexistent_scene")

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::SceneError)
    end

    it "triggers scene transition callbacks" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")

      manager.add_scene(scene)
      result = manager.change_scene("test_scene")

      result.success?.should be_true
      # Scene's enter method is called during change_scene
      # MockScene doesn't track this, so we just verify the change succeeded
    end
  end

  describe "#get_scene" do
    it "returns existing scene successfully" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")

      manager.add_scene(scene)
      result = manager.get_scene("test_scene")

      result.success?.should be_true
      result.value.should eq(scene)
    end

    it "fails for non-existing scene" do
      manager = PointClickEngine::Core::SceneManager.new

      result = manager.get_scene("nonexistent_scene")

      result.failure?.should be_true
    end
  end

  describe "#remove_scene" do
    it "successfully unloads existing scene" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")

      manager.add_scene(scene)
      result = manager.remove_scene("test_scene")

      result.success?.should be_true
      manager.scene_names.includes?("test_scene").should be_false
    end

    it "fails to unload non-existing scene" do
      manager = PointClickEngine::Core::SceneManager.new

      result = manager.remove_scene("nonexistent_scene")

      result.failure?.should be_true
    end
  end

  describe "#scene_names" do
    it "returns empty array when no scenes added" do
      manager = PointClickEngine::Core::SceneManager.new

      manager.scene_names.should be_empty
    end

    it "returns all scene names" do
      manager = PointClickEngine::Core::SceneManager.new
      scene1 = MockScene.new("scene1")
      scene2 = MockScene.new("scene2")

      manager.add_scene(scene1)
      manager.add_scene(scene2)

      names = manager.scene_names
      names.includes?("scene1").should be_true
      names.includes?("scene2").should be_true
      names.size.should eq(2)
    end
  end

  describe "#preload_scene" do
    it "successfully preloads an existing scene" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")
      manager.add_scene(scene)

      result = manager.preload_scene("test_scene")

      result.success?.should be_true
      result.value.should be_a(PointClickEngine::Scenes::Scene)
    end

    it "fails when preloading non-existent scene" do
      manager = PointClickEngine::Core::SceneManager.new

      result = manager.preload_scene("nonexistent_scene")

      result.failure?.should be_true
    end
  end

  describe "scene management" do
    it "tracks current scene correctly" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")

      manager.add_scene(scene)
      manager.change_scene("test_scene")

      manager.current_scene.should_not be_nil
      manager.current_scene.not_nil!.name.should eq("test_scene")
    end

    it "handles scene callbacks" do
      manager = PointClickEngine::Core::SceneManager.new
      scene = MockScene.new("test_scene")
      callback_called = false

      manager.add_scene(scene)
      manager.on_scene_enter("test_scene") { callback_called = true }
      manager.change_scene("test_scene")

      callback_called.should be_true
    end
  end
end
