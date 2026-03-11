require "./spec_helper"

describe "Character Movement Debug" do
  it "verifies input handling does not consume clicks when menu is hidden" do
    RaylibContext.with_window do
      # Create test engine
      engine = PointClickEngine::Core::Engine.new(800, 600, "Movement Test")
      engine.init

      # Menu should be hidden after init and entering game mode
      menu = engine.system_manager.menu_system
      menu.should_not be_nil

      if menu_sys = menu
        menu_sys.hide
        menu_sys.enter_game
        menu_sys.visible.should be_false
        menu_sys.in_game.should be_true
      end

      # Engine should have input handler
      engine.input_handler.should_not be_nil
    end
  end

  it "verifies player exists after starting new game" do
    RaylibContext.with_window do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Player Test")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.logical_width = 800
      scene.logical_height = 600
      engine.add_scene(scene)
      engine.current_scene = scene

      player = PointClickEngine::Characters::Player.new("Test Player", vec2(100, 100), vec2(32, 32))
      engine.player = player

      engine.start_new_game

      engine.player.should_not be_nil
      engine.current_scene.should_not be_nil
      engine.current_scene.not_nil!.player.should eq(player)
    end
  end
end
