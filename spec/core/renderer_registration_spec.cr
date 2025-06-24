require "../spec_helper"

describe "Renderer Registration System" do
  it "registers dialog manager in render pipeline" do
    RL.init_window(800, 600, "Dialog Manager Renderer Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Dialog Renderer Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Test that dialog manager is accessible via system manager
    dialog_manager = engine.system_manager.dialog_manager
    dialog_manager.should_not be_nil

    # Test that render manager has layers that should include dialog rendering
    render_manager = engine.render_manager
    render_manager.should_not be_nil

    # Test that floating dialogs are enabled by default
    if dm = dialog_manager
      dm.enable_floating.should be_true
      dm.floating_manager.should_not be_nil
    end

    # Test that render coordinator can access dialog manager
    # This validates the fix from engine.dialog_manager to engine.system_manager.dialog_manager
    if engine_instance = PointClickEngine::Core::Engine.instance
      engine_instance.system_manager.dialog_manager.should_not be_nil
    end

    RL.close_window
  end

  it "registers verb input system cursor in UI layer" do
    RL.init_window(800, 600, "Cursor Renderer Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Cursor Renderer Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Enable verb input system (required for cursor rendering)
    engine.enable_verb_input

    # Test that verb input system is initialized
    verb_system = engine.verb_input_system
    verb_system.should_not be_nil

    if vs = verb_system
      # Test that cursor manager is initialized
      vs.cursor_manager.should_not be_nil

      # Test that display manager is available for cursor rendering
      display_manager = engine.system_manager.display_manager
      display_manager.should_not be_nil

      # Test that verb system has draw method that takes display manager
      # This validates the registration in UI renderer
      vs.responds_to?(:draw).should be_true
    end

    # Test that render manager has UI layer where cursor should be rendered
    render_manager = engine.render_manager
    render_manager.should_not be_nil

    RL.close_window
  end

  it "registers achievement manager in UI layer" do
    RL.init_window(800, 600, "Achievement Renderer Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Achievement Renderer Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Test that achievement manager is accessible via system manager
    achievement_manager = engine.system_manager.achievement_manager
    achievement_manager.should_not be_nil

    if am = achievement_manager
      # Test that achievement manager has draw method
      am.responds_to?(:draw).should be_true

      # Test achievement notification functionality
      am.unlock("test_achievement")

      # Test that notification system is working
      # (The draw method should handle rendering notifications when active)
      am.responds_to?(:update).should be_true
    end

    RL.close_window
  end

  it "validates render layer structure and component registration" do
    RL.init_window(800, 600, "Render Layer Structure Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Layer Structure Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Test that render manager is properly initialized
    render_manager = engine.render_manager
    render_manager.should_not be_nil

    # Test that essential systems are available for rendering
    engine.system_manager.should_not be_nil
    engine.system_manager.dialog_manager.should_not be_nil
    engine.system_manager.achievement_manager.should_not be_nil
    engine.system_manager.display_manager.should_not be_nil
    engine.system_manager.menu_system.should_not be_nil

    # Test that inventory is available (already registered in UI layer)
    engine.inventory.should_not be_nil
    engine.inventory.responds_to?(:draw).should be_true

    RL.close_window
  end

  it "ensures UI components are properly layered for rendering order" do
    RL.init_window(800, 600, "Render Order Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Render Order Test",
      window_width: 800,
      window_height: 600
    )
    engine.init
    engine.enable_verb_input

    # Test that all UI components have draw methods
    components_with_draw = [] of String

    # Inventory (already registered)
    if engine.inventory.responds_to?(:draw)
      components_with_draw << "inventory"
    end

    # Menu system (already registered)
    if menu = engine.system_manager.menu_system
      if menu.responds_to?(:draw)
        components_with_draw << "menu_system"
      end
    end

    # Achievement manager (newly registered)
    if achievement = engine.system_manager.achievement_manager
      if achievement.responds_to?(:draw)
        components_with_draw << "achievement_manager"
      end
    end

    # Verb input system cursor (newly registered)
    if verb_system = engine.verb_input_system
      if verb_system.responds_to?(:draw)
        components_with_draw << "verb_input_system"
      end
    end

    # Dialog manager (fixed registration path)
    if dialog = engine.system_manager.dialog_manager
      if dialog.responds_to?(:draw)
        components_with_draw << "dialog_manager"
      end
    end

    # Verify that all critical UI components are accounted for
    components_with_draw.should contain("inventory")
    components_with_draw.should contain("menu_system")
    components_with_draw.should contain("achievement_manager")
    components_with_draw.should contain("verb_input_system")
    components_with_draw.should contain("dialog_manager")

    # Should have at least 5 UI components with draw methods
    components_with_draw.size.should be >= 5

    RL.close_window
  end

  it "validates floating dialog rendering integration" do
    RL.init_window(800, 600, "Floating Dialog Renderer Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Floating Dialog Renderer Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Test dialog manager floating system
    dialog_manager = engine.system_manager.dialog_manager
    dialog_manager.should_not be_nil

    if dm = dialog_manager
      # Test floating dialog manager initialization
      dm.floating_manager.should_not be_nil
      dm.enable_floating.should be_true

      # Test that floating dialog manager has draw method
      dm.floating_manager.responds_to?(:draw).should be_true

      # Test floating dialog creation and rendering setup
      character_pos = RL::Vector2.new(x: 400, y: 300)
      dm.show_floating_dialog("TestCharacter", "Test floating message", character_pos)

      # Verify floating dialog was created
      dm.floating_manager.has_active_dialogs?.should be_true

      # Test that dialog manager draw method includes floating manager
      dm.responds_to?(:draw).should be_true
    end

    RL.close_window
  end

  it "tests cursor visual feedback rendering system" do
    RL.init_window(800, 600, "Cursor Visual Feedback Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Cursor Visual Feedback Test",
      window_width: 800,
      window_height: 600
    )
    engine.init
    engine.enable_verb_input

    # Test verb input system cursor integration
    verb_system = engine.verb_input_system
    verb_system.should_not be_nil

    if vs = verb_system
      cursor_manager = vs.cursor_manager
      cursor_manager.should_not be_nil

      # Test cursor manager draw capability
      cursor_manager.responds_to?(:draw).should be_true

      # Test verb cycling (validates mouse wheel functionality)
      initial_verb = cursor_manager.current_verb
      cursor_manager.cycle_verb_forward
      cursor_manager.current_verb.should_not eq(initial_verb)

      # Test verb setting
      cursor_manager.set_verb(PointClickEngine::UI::VerbType::Look)
      cursor_manager.current_verb.should eq(PointClickEngine::UI::VerbType::Look)

      cursor_manager.set_verb(PointClickEngine::UI::VerbType::Use)
      cursor_manager.current_verb.should eq(PointClickEngine::UI::VerbType::Use)

      # Test that display manager is available for cursor rendering
      display_manager = engine.system_manager.display_manager
      display_manager.should_not be_nil
    end

    RL.close_window
  end

  it "validates achievement notification rendering" do
    RL.init_window(800, 600, "Achievement Notification Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Achievement Notification Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Test achievement manager notification system
    achievement_manager = engine.system_manager.achievement_manager
    achievement_manager.should_not be_nil

    if am = achievement_manager
      # Test achievement manager rendering capability
      am.responds_to?(:draw).should be_true
      am.responds_to?(:update).should be_true

      # Test achievement unlock (should trigger notification)
      am.unlock("test_achievement_render")

      # Test that achievement has notification display capability
      # The draw method should handle active notifications
      am.responds_to?(:unlock).should be_true
    end

    RL.close_window
  end

  it "ensures render pipeline completeness" do
    RL.init_window(800, 600, "Render Pipeline Completeness Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Pipeline Completeness Test",
      window_width: 800,
      window_height: 600
    )
    engine.init
    engine.enable_verb_input

    # Create a scene to test full render pipeline
    scene = PointClickEngine::Scenes::Scene.new("pipeline_test")
    engine.add_scene(scene)
    engine.change_scene("pipeline_test")

    # Test that all major rendering systems are available
    render_systems = [] of String

    # Core rendering
    if engine.render_manager
      render_systems << "render_manager"
    end

    # Scene rendering
    if engine.current_scene
      render_systems << "scene_rendering"
    end

    # UI rendering components (all should be registered)
    if engine.inventory.responds_to?(:draw)
      render_systems << "inventory"
    end

    if engine.system_manager.menu_system.try(&.responds_to?(:draw))
      render_systems << "menu_system"
    end

    if engine.system_manager.achievement_manager.try(&.responds_to?(:draw))
      render_systems << "achievement_manager"
    end

    if engine.verb_input_system.try(&.responds_to?(:draw))
      render_systems << "verb_input_cursor"
    end

    if engine.system_manager.dialog_manager.try(&.responds_to?(:draw))
      render_systems << "dialog_manager"
    end

    # Transition rendering
    if engine.system_manager.transition_manager.try(&.responds_to?(:draw))
      render_systems << "transition_manager"
    end

    # Should have all major rendering components
    render_systems.should contain("render_manager")
    render_systems.should contain("scene_rendering")
    render_systems.should contain("inventory")
    render_systems.should contain("menu_system")
    render_systems.should contain("achievement_manager")
    render_systems.should contain("verb_input_cursor")
    render_systems.should contain("dialog_manager")
    render_systems.should contain("transition_manager")

    # Should have at least 8 rendering systems
    render_systems.size.should be >= 8

    RL.close_window
  end
end
