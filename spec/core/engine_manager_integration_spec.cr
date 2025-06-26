require "../spec_helper"
require "../../src/core/engine"

describe "Engine-Manager Integration" do
  describe "dependency injection setup" do
    it "initializes all managers through DI container" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")

      # Managers should be initialized via DI
      engine.scene_manager.should be_a(PointClickEngine::Core::SceneManager)
      engine.input_manager.should be_a(PointClickEngine::Core::InputManager)
      engine.render_manager.should be_a(PointClickEngine::Core::RenderManager)
      engine.resource_manager.should be_a(PointClickEngine::Core::ResourceManager)
    end

    it "managers are ready before engine initialization" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")

      # Even before init, managers should be available
      engine.scene_manager.should_not be_nil
      engine.input_manager.should_not be_nil
      engine.render_manager.should_not be_nil
      engine.resource_manager.should_not be_nil

      engine.init

      # And still available after init
      engine.scene_manager.should_not be_nil
      engine.input_manager.should_not be_nil
      engine.render_manager.should_not be_nil
      engine.resource_manager.should_not be_nil
    end
  end

  describe "scene management delegation" do
    it "delegates scene operations to SceneManager" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Add scene through engine
      result = engine.add_scene(scene)
      result.success?.should be_true

      # Scene should be in both engine and scene manager
      engine.scenes.has_key?("test_scene").should be_true
      engine.scene_manager.has_scene?("test_scene").should be_true

      # Get scene names
      names = engine.scene_manager.scenes.keys
      names.includes?("test_scene").should be_true

      # Change scene
      engine.change_scene("test_scene")
      engine.current_scene.should_not be_nil
      # engine.current_scene_name.should eq("test_scene")
      engine.scene_manager.current_scene.should_not be_nil
    end

    it "handles scene removal correctly" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      scene1 = PointClickEngine::Scenes::Scene.new("scene1")
      scene2 = PointClickEngine::Scenes::Scene.new("scene2")

      engine.add_scene(scene1)
      engine.add_scene(scene2)
      engine.change_scene("scene1")

      # Remove non-active scene
      result = engine.scene_manager.remove_scene("scene2")
      result.success?.should be_true

      # Should be removed from both engine and manager
      engine.scenes.has_key?("scene2").should be_false
      engine.scene_manager.has_scene?("scene2").should be_false

      # Cannot remove active scene
      result = engine.scene_manager.remove_scene("scene1")
      result.failure?.should be_true
    end
  end

  describe "resource management delegation" do
    it "delegates resource operations to ResourceManager" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      # These operations should delegate to ResourceManager
      # We can't test actual loading without files, but we can verify the methods exist
      engine.responds_to?(:load_texture).should be_true
      engine.responds_to?(:load_sound).should be_true
      engine.responds_to?(:load_music).should be_true
      engine.responds_to?(:load_font).should be_true
      engine.responds_to?(:preload_assets).should be_true
      engine.responds_to?(:get_memory_usage).should be_true
      engine.responds_to?(:set_memory_limit).should be_true
      engine.responds_to?(:enable_hot_reload).should be_true
      engine.responds_to?(:disable_hot_reload).should be_true
    end
  end

  describe "input management delegation" do
    it "delegates input operations to InputManager" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      # Register a handler
      engine.input_manager.register_handler("test_handler", 10)

      # Check if input is consumed  
      engine.input_manager.input_blocked?.should be_false

      # Block input temporarily
      engine.input_manager.block_input(60, "test")
      engine.input_manager.input_blocked?.should be_true

      # Unregister handler
      engine.input_manager.unregister_handler("test_handler")
    end
  end

  describe "render management delegation" do
    it "delegates render operations to RenderManager" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      # Add a render layer
      engine.render_manager.add_render_layer("ui", 100)

      # Modify layer properties
      engine.render_manager.set_layer_enabled("ui", false)

      # Performance tracking  
      stats = engine.render_manager.get_render_stats
      stats.should_not be_nil
    end
  end
end
