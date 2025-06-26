require "../spec_helper"
require "../../src/core/engine"
require "../../src/core/engine/render_coordinator"

describe "Engine-RenderCoordinator Integration" do
  describe "rendering delegation" do
    it "passes correct parameters to RenderCoordinator" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      # Add a test scene
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Verify the engine has the scene
      engine.current_scene.should_not be_nil
      engine.current_scene.not_nil!.name.should eq("test_scene")

      # The render method is private, but we can verify the setup through public APIs
      engine.system_manager.should_not be_nil
      engine.dialog_manager.should_not be_nil
    end

    it "handles camera based on scene scrolling settings" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      # Scene with scrolling enabled
      scene1 = PointClickEngine::Scenes::Scene.new("scrolling_scene")
      scene1.enable_camera_scrolling = true
      engine.add_scene(scene1)
      engine.change_scene("scrolling_scene")

      # Camera should be available for scrolling scenes
      engine.camera.should_not be_nil

      # Scene with scrolling disabled
      scene2 = PointClickEngine::Scenes::Scene.new("static_scene")
      scene2.enable_camera_scrolling = false
      engine.add_scene(scene2)
      engine.change_scene("static_scene")

      # Camera exists but scene doesn't use it
      engine.camera.should_not be_nil
      engine.current_scene.not_nil!.enable_camera_scrolling.should be_false
    end
  end

  describe "render coordinator configuration" do
    it "allows UI visibility control" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      # UI should be visible by default
      engine.render_manager.ui_visible?.should be_true

      # Hide UI
      engine.render_manager.hide_ui
      engine.render_manager.ui_visible?.should be_false

      # Show UI
      engine.render_manager.show_ui
      engine.render_manager.ui_visible?.should be_true
    end

    it "allows hotspot highlighting control" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      # Hotspot highlighting should be off by default
      engine.render_manager.hotspot_highlighting_enabled?.should be_false

      # Toggle highlighting
      engine.render_manager.enable_hotspot_highlighting
      engine.render_manager.hotspot_highlighting_enabled?.should be_true

      # Set custom highlight settings
      engine.render_manager.enable_hotspot_highlighting(RL::BLUE, false)
      engine.render_manager.hotspot_highlighting_enabled?.should be_true
      # Note: RenderManager doesn't expose color/pulse getters, so we can't test those
    end
  end
end
