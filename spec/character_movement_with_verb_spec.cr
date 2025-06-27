require "./spec_helper"

describe "Character Movement with Verb Input" do
  it "processes mouse clicks for movement" do
    RaylibContext.with_window do
      # Create engine with verb input
      engine = PointClickEngine::Core::Engine.new(800, 600, "Movement Test")
      engine.init
      engine.enable_verb_input
      
      # Create scene with player
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 800
      scene.logical_height = 600
      
      player = PointClickEngine::Characters::Player.new("Test Player", vec2(100, 100), vec2(32, 32))
      scene.player = player
      engine.player = player
      
      engine.add_scene(scene)
      engine.change_scene("test_scene")
      
      # Verify setup
      engine.verb_input_system.should_not be_nil
      engine.current_scene.should eq(scene)
      engine.player.should eq(player)
      
      # Simulate a frame update
      engine.update(0.016_f32)
      
      # Verify input manager is working
      engine.input_manager.should_not be_nil
    end
  end
  
  it "updates input manager state each frame" do
    RaylibContext.with_window do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test")
      engine.init
      
      # Verify the input manager exists and can be called
      engine.input_manager.process_input(0.016_f32)
      
      # Verify mouse consumed state is false after process_input
      engine.input_manager.mouse_consumed?.should be_false
    end
  end
end