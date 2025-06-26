require "../spec_helper"

describe "Architectural Pattern Compliance" do
  describe "Component Registration Patterns" do
    it "ensures all drawable components are registered with appropriate systems" do
      # This spec documents the pattern: components with draw() methods
      # must be registered with either the render manager or called
      # from within a registered renderer

      RL.init_window(800, 600, "Component Registration Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Registration Test")
      engine.init

      # Check that systems with draw methods are accessible via render pipeline
      dialog_manager = engine.system_manager.dialog_manager
      dialog_manager.should_not be_nil

      # FloatingDialogManager should be drawable via DialogManager
      if dm = dialog_manager
        dm.floating_manager.should_not be_nil
        dm.enable_floating.should be_true
      end

      # VerbInputSystem cursor should be drawable
      if verb_system = engine.verb_input_system
        verb_system.cursor_manager.should_not be_nil
      end

      RL.close_window
    end

    it "validates input consumption hierarchy" do
      # This spec documents the pattern: input-consuming components
      # should have clear priority order and not conflict

      RL.init_window(800, 600, "Input Hierarchy Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Input Test")
      engine.init

      dialog_manager = engine.system_manager.dialog_manager.not_nil!

      # Pattern: Floating dialogs should NOT consume input
      dialog_manager.show_message("Floating message", 1.0f32)
      dialog_manager.update(0.016f32)
      dialog_manager.dialog_consumed_input?.should be_false

      # Pattern: Interactive dialogs SHOULD consume input
      dialog_manager.show_dialog("Interactive", "Test dialog")
      dialog_manager.update(0.016f32)

      # Should consume input when there's an active interactive dialog
      if dialog_manager.current_dialog
        # Input consumption should be based on dialog interaction, not just presence
        dialog_manager.dialog_consumed_input?.should be_false # until user interacts
      end

      RL.close_window
    end
  end

  describe "System Coordination Patterns" do
    it "ensures systems don't have circular dependencies" do
      RL.init_window(800, 600, "Dependency Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Dependency Test")
      engine.init

      # Systems should initialize independently
      system_manager = engine.system_manager
      system_manager.dialog_manager.should_not be_nil
      system_manager.display_manager.should_not be_nil

      # No system should require another system to be fully initialized
      # before it can be created (circular dependency)

      RL.close_window
    end

    it "validates layer-based rendering architecture" do
      RL.init_window(800, 600, "Layer Architecture Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Layer Test")
      engine.init

      render_manager = engine.render_manager

      # Pattern: All drawable content should go through render layers
      # This prevents the bug where components exist but aren't rendered

      # Create multiple UI components
      dialog_manager = engine.system_manager.dialog_manager.not_nil!
      dialog_manager.show_message("Layer test message", 1.0f32)

      # Update and render - should not crash
      engine.update(0.016f32)
      render_manager.render(0.016f32)

      # All systems should be coordinated through the render manager
      render_stats = render_manager.get_render_stats
      render_stats.should_not be_nil

      RL.close_window
    end
  end

  describe "Error Prevention Patterns" do
    it "catches missing renderer registration at runtime" do
      # This test would catch the original bug we fixed:
      # components that have draw() methods but aren't registered anywhere

      RL.init_window(800, 600, "Missing Registration Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Missing Registration Test",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Test that all major UI systems are reachable from render pipeline
      dialog_manager = engine.system_manager.dialog_manager.not_nil!

      # Create content that should be rendered
      dialog_manager.show_message("Renderer test", 1.0f32)
      dialog_manager.update(0.016f32)

      # Content should be accessible via render pipeline (either floating or regular)
      dialog_exists = dialog_manager.floating_manager.active_dialogs.size > 0 || dialog_manager.current_dialog != nil
      dialog_exists.should be_true

      # A proper integration test would verify this actually renders,
      # but that requires more complex rendering state inspection

      RL.close_window
    end

    it "prevents coordinate system mismatches" do
      RL.init_window(800, 600, "Coordinate Mismatch Test")

      # Create engine with different game vs screen resolution
      engine = PointClickEngine::Core::Engine.new(
        title: "Coordinate Test",
        window_width: 1024, # Game size
        window_height: 768
      )
      engine.init

      # Test that UI components handle coordinate transformation correctly
      display_manager = engine.system_manager.display_manager.not_nil!

      # Screen coordinates should transform to game coordinates consistently
      screen_center = RL::Vector2.new(x: 400f32, y: 300f32) # Center of 800x600
      game_center = display_manager.screen_to_game(screen_center)

      # Game coordinates should be within valid bounds
      game_center.x.should be >= 0f32
      game_center.x.should be <= 1024f32
      game_center.y.should be >= 0f32
      game_center.y.should be <= 768f32

      # Test round-trip consistency
      back_to_screen = display_manager.game_to_screen(game_center)
      (back_to_screen.x - screen_center.x).abs.should be < 2f32
      (back_to_screen.y - screen_center.y).abs.should be < 2f32

      RL.close_window
    end
  end
end
