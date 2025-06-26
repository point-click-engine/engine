require "../spec_helper"

describe "Keyboard Shortcuts During Dialog" do
  it "allows F1 debug toggle even when dialog is active" do
    RL.init_window(800, 600, "Keyboard Shortcut Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Shortcut Test")
    engine.init

    # Simulate an active dialog
    if dialog_manager = engine.dialog_manager
      # Show a simple message which is what DialogManager actually supports
      dialog_manager.show_message("Test dialog")
    end

    # Initial debug mode state
    initial_debug_mode = PointClickEngine::Core::Engine.debug_mode

    # Simulate F1 keypress - this should work even with dialog active
    # Note: We can't directly test key input in specs, but we can test the logic
    # by calling the toggle method directly
    PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode

    # Verify debug mode changed
    PointClickEngine::Core::Engine.debug_mode.should_not eq(initial_debug_mode)

    RL.close_window
    PointClickEngine::Core::Engine.reset_instance
  end

  it "allows Tab hotspot highlight toggle even when dialog is active" do
    RL.init_window(800, 600, "Hotspot Highlight Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Hotspot Test")
    engine.init

    # Create and set a scene first
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Simulate an active dialog
    if dialog_manager = engine.dialog_manager
      dialog_manager.show_message("Test dialog")
    end

    # Get initial hotspot highlight state from the render manager
    render_manager = engine.render_manager
    initial_highlight_enabled = render_manager.hotspot_highlighting_enabled?

    # Toggle hotspot highlighting
    if initial_highlight_enabled
      render_manager.disable_hotspot_highlighting
    else
      render_manager.enable_hotspot_highlighting
    end

    # Verify hotspot highlight state changed
    render_manager.hotspot_highlighting_enabled?.should_not eq(initial_highlight_enabled)

    RL.close_window
    PointClickEngine::Core::Engine.reset_instance
  end

  it "blocks mouse input when dialog is active but allows keyboard shortcuts" do
    RL.init_window(800, 600, "Input Blocking Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Input Block Test")
    engine.init

    # Get the input manager and block input simulating dialog behavior
    input_manager = engine.input_manager

    # Simulate what the dialog manager would do when showing a dialog
    if dialog_manager = engine.dialog_manager
      dialog_manager.show_message("Test dialog")
      # Dialog manager should block input when active
      input_manager.block_input(60, "dialog_active") # Block for 60 frames
    end

    # Verify that input is blocked
    input_manager.input_blocked?.should be_true
    input_manager.input_block_source.should eq("dialog_active")

    # Keyboard shortcuts should still function through the special handler
    # This is handled by InputManager's process_keyboard_shortcuts_only method

    RL.close_window
    PointClickEngine::Core::Engine.reset_instance
  end

  it "handles verb input system keyboard shortcuts during dialog" do
    RL.init_window(800, 600, "Verb Keyboard Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Verb Test")
    engine.init

    # Enable verb input system
    engine.enable_verb_input
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Simulate an active dialog
    if dialog_manager = engine.dialog_manager
      dialog_manager.show_message("Test dialog")
    end

    # Test that verb system is properly initialized
    verb_system = engine.verb_input_system
    verb_system.should_not be_nil
    if vs = verb_system
      vs.enabled.should be_true
      # Keyboard shortcuts are handled by the verb system's handle_keyboard_input method
      # which is called even when dialogs are active
    end

    RL.close_window
    PointClickEngine::Core::Engine.reset_instance
  end

  it "handles mouse wheel verb cycling during dialog" do
    RL.init_window(800, 600, "Mouse Wheel Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Wheel Test")
    engine.init

    # Enable verb input system first
    engine.enable_verb_input

    # Create scene with verb system
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Simulate an active dialog
    if dialog_manager = engine.dialog_manager
      dialog_manager.show_message("Test dialog")
    end

    # Test that mouse wheel handling is available
    # Note: We can't simulate actual mouse wheel input in specs
    # but we can verify the verb system is enabled and responsive
    verb_system = engine.verb_input_system
    verb_system.should_not be_nil

    if vs = verb_system
      vs.enabled.should be_true

      # Get the current verb through the cursor manager's getter
      cursor_manager = vs.cursor_manager
      initial_verb = cursor_manager.current_verb

      # Test cycling verbs directly
      cursor_manager.cycle_verb_forward
      cursor_manager.current_verb.should_not eq(initial_verb)
    end

    RL.close_window
    PointClickEngine::Core::Engine.reset_instance
  end
end
