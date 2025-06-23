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
      
      # The render method is private, but we can verify the setup
      engine.render_coordinator.should be_a(PointClickEngine::Core::EngineComponents::RenderCoordinator)
      engine.dialogs.should be_a(Array(PointClickEngine::UI::Dialog))
      engine.cutscene_manager.should be_a(PointClickEngine::Cutscenes::CutsceneManager)
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
      engine.render_coordinator.ui_visible.should be_true
      
      # Hide UI
      engine.hide_ui
      engine.render_coordinator.ui_visible.should be_false
      
      # Show UI
      engine.show_ui
      engine.render_coordinator.ui_visible.should be_true
    end
    
    it "allows hotspot highlighting control" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init
      
      # Hotspot highlighting should be off by default
      engine.render_coordinator.hotspot_highlight_enabled.should be_false
      
      # Toggle highlighting
      engine.toggle_hotspot_highlight
      engine.render_coordinator.hotspot_highlight_enabled.should be_true
      
      # Set custom highlight settings
      engine.set_hotspot_highlight(true, RL::BLUE, false)
      engine.render_coordinator.hotspot_highlight_enabled.should be_true
      engine.render_coordinator.hotspot_highlight_color.should eq(RL::BLUE)
      engine.render_coordinator.hotspot_highlight_pulse.should be_false
    end
  end
end