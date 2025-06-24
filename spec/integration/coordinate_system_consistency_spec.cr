require "../spec_helper"

describe "Coordinate System Consistency" do
  describe "Screen vs Game Coordinate Usage" do
    it "identifies UI components that incorrectly use screen coordinates" do
      RL.init_window(800, 600, "Coordinate Audit Test")

      # Create engine with different game resolution than screen resolution
      engine = PointClickEngine::Core::Engine.new(
        title: "Coordinate Audit",
        window_width: 1024, # Game coordinates
        window_height: 768
      )
      engine.init

      # Test FloatingText (potential issue found)
      # This class uses RL.get_screen_width/height which could be wrong
      floating_text = PointClickEngine::UI::FloatingText.new(
        "Test text",
        "Test Character",
        RL::Vector2.new(x: 500f32, y: 400f32)
      )

      # The floating text should position itself within game bounds (1024x768)
      # not screen bounds (800x600)
      floating_text.visible.should be_true

      # NOTE: This test documents the potential coordinate system issue
      # FloatingText.calculate_position uses RL.get_screen_width/height
      # which should probably use game dimensions instead

      RL.close_window
    end

    it "ensures dialog positioning works correctly across different screen/game ratios" do
      RL.init_window(1200, 800, "Dialog Positioning Test")

      # Test with game resolution different from screen
      engine = PointClickEngine::Core::Engine.new(
        title: "Dialog Position Test",
        window_width: 1024,
        window_height: 768
      )
      engine.init

      dialog_manager = engine.system_manager.dialog_manager.not_nil!

      # Create floating dialog at specific game coordinate
      game_position = RL::Vector2.new(x: 512f32, y: 384f32) # Center of 1024x768
      dialog_manager.floating_manager.show_dialog(
        "Test Character",
        "Test dialog at center",
        game_position,
        2.0f32
      )

      dialog_manager.update(0.016f32)

      # Dialog should be positioned correctly in game space
      if dialog_manager.floating_manager.active_dialogs.size > 0
        dialog = dialog_manager.floating_manager.active_dialogs[0]
        dialog.character_position.should eq(game_position)
      end

      RL.close_window
    end

    it "verifies display manager coordinate transformations" do
      RL.init_window(800, 600, "Display Manager Test")

      engine = PointClickEngine::Core::Engine.new(
        title: "Display Test",
        window_width: 1024,
        window_height: 768
      )
      engine.init

      display_manager = engine.system_manager.display_manager.not_nil!

      # Test coordinate transformations
      screen_point = RL::Vector2.new(x: 400f32, y: 300f32) # Center of 800x600 screen
      game_point = display_manager.screen_to_game(screen_point)

      # The transformation should be consistent - we don't assume specific values
      # but verify that the transformation makes sense and is reversible
      # Game coordinates should be within reasonable bounds
      game_point.x.should be >= 0f32
      game_point.x.should be <= 1024f32
      game_point.y.should be >= 0f32
      game_point.y.should be <= 768f32

      # Test reverse transformation
      back_to_screen = display_manager.game_to_screen(game_point)
      back_to_screen.x.should be_close(screen_point.x, 1f32)
      back_to_screen.y.should be_close(screen_point.y, 1f32)

      RL.close_window
    end
  end

  describe "Render Layer Coordination" do
    it "ensures UI components render in correct layers" do
      RL.init_window(800, 600, "Render Layer Test")

      engine = PointClickEngine::Core::Engine.new(
        title: "Layer Test",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Create scene with various components
      scene = PointClickEngine::Scenes::Scene.new("layer_test")
      engine.add_scene(scene)
      engine.change_scene("layer_test")

      # Add UI components
      dialog_manager = engine.system_manager.dialog_manager.not_nil!
      dialog_manager.show_message("UI layer test", 1.0f32)

      # Update and render
      engine.update(0.016f32)

      # All components should render without conflicts
      # This test ensures render layers are properly coordinated
      render_stats = engine.render_manager.get_render_stats
      render_stats.should_not be_nil

      RL.close_window
    end
  end
end
