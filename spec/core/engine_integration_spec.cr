require "../spec_helper"

describe "Engine Integration" do
  describe "menu system integration" do
    it "shows main menu on startup" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.init
      
      engine.show_main_menu
      
      engine.menu_system.should_not be_nil
      menu = engine.menu_system.not_nil!
      menu.current_menu.should eq(menu.main_menu)
    end
    
    it "pauses game with ESC key" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.init
      
      # Start the game
      engine.start_game
      
      # Simulate ESC key press through menu system
      menu = engine.menu_system.not_nil!
      menu.toggle_pause_menu
      
      menu.game_paused.should be_true
      menu.current_menu.should eq(menu.pause_menu)
    end
  end
  
  describe "verb input system" do
    it "can be enabled on engine" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.init
      
      engine.verb_input_system.should be_nil
      
      engine.enable_verb_input
      
      engine.verb_input_system.should_not be_nil
      engine.handle_clicks.should be_false
    end
  end
  
  describe "hotspot highlighting" do
    it "can toggle highlighting" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.init
      
      initial_state = engine.render_coordinator.hotspot_highlight_enabled
      
      engine.toggle_hotspot_highlight
      
      engine.render_coordinator.hotspot_highlight_enabled.should eq(!initial_state)
    end
    
    it "can set custom highlight settings" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.init
      
      blue = RL::Color.new(r: 0, g: 0, b: 255, a: 255)
      
      engine.set_hotspot_highlight(true, blue, false)
      
      coordinator = engine.render_coordinator
      coordinator.hotspot_highlight_enabled.should be_true
      coordinator.hotspot_highlight_color.should eq(blue)
      coordinator.hotspot_highlight_pulse.should be_false
    end
  end
end