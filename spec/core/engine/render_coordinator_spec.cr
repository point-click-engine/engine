require "../../spec_helper"

describe PointClickEngine::Core::EngineComponents::RenderCoordinator do
  describe "hotspot highlighting" do
    it "initializes with highlighting disabled" do
      coordinator = PointClickEngine::Core::EngineComponents::RenderCoordinator.new
      
      coordinator.hotspot_highlight_enabled.should be_false
      coordinator.hotspot_highlight_pulse.should be_true
      coordinator.hotspot_highlight_color.should eq(RL::Color.new(r: 255, g: 215, b: 0, a: 255))
    end
    
    it "can toggle highlighting" do
      coordinator = PointClickEngine::Core::EngineComponents::RenderCoordinator.new
      
      coordinator.hotspot_highlight_enabled = true
      coordinator.hotspot_highlight_enabled.should be_true
    end
    
    it "allows custom highlight colors" do
      coordinator = PointClickEngine::Core::EngineComponents::RenderCoordinator.new
      
      blue = RL::Color.new(r: 0, g: 0, b: 255, a: 255)
      coordinator.hotspot_highlight_color = blue
      coordinator.hotspot_highlight_color.should eq(blue)
    end
    
    it "can disable pulsing effect" do
      coordinator = PointClickEngine::Core::EngineComponents::RenderCoordinator.new
      
      coordinator.hotspot_highlight_pulse = false
      coordinator.hotspot_highlight_pulse.should be_false
    end
  end
  
  describe "#render" do
    it "respects UI visibility setting" do
      coordinator = PointClickEngine::Core::EngineComponents::RenderCoordinator.new
      
      coordinator.ui_visible = false
      coordinator.ui_visible.should be_false
      
      coordinator.ui_visible = true
      coordinator.ui_visible.should be_true
    end
  end
  
  describe "#update_cursor" do
    it "sets cursor based on hotspot type" do
      coordinator = PointClickEngine::Core::EngineComponents::RenderCoordinator.new
      
      scene = PointClickEngine::Scenes::Scene.new("test")
      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "test",
        RL::Vector2.new(x: 100, y: 100),
        RL::Vector2.new(x: 50, y: 50)
      )
      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
      scene.add_hotspot(hotspot)
      
      # This would update the cursor in a real environment
      coordinator.update_cursor(scene)
    end
  end
end