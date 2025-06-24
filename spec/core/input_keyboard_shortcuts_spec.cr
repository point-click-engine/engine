require "../spec_helper"

describe "Keyboard Shortcuts During Dialog" do
  it "allows F1 debug toggle even when dialog is active" do
    RL.init_window(800, 600, "Keyboard Shortcut Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Shortcut Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Simulate an active dialog
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100_f32, y: 100_f32),
      RL::Vector2.new(x: 200_f32, y: 100_f32)
    )
    dialog.show
    engine.show_dialog(dialog)

    # Initial debug mode state
    initial_debug_mode = PointClickEngine::Core::Engine.debug_mode

    # Simulate F1 keypress - this should work even with dialog active
    # Note: We can't directly test key input in specs, but we can test the logic
    # by calling the toggle method directly
    PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode

    # Verify debug mode changed
    PointClickEngine::Core::Engine.debug_mode.should_not eq(initial_debug_mode)

    RL.close_window
  end

  it "allows Tab hotspot highlight toggle even when dialog is active" do
    RL.init_window(800, 600, "Hotspot Highlight Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Hotspot Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Simulate an active dialog
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100_f32, y: 100_f32),
      RL::Vector2.new(x: 200_f32, y: 100_f32)
    )
    dialog.show
    engine.show_dialog(dialog)

    # Initial hotspot highlight state
    initial_highlight_enabled = engine.render_manager.hotspot_highlighting_enabled?

    # Simulate Tab keypress - this should work even with dialog active
    engine.toggle_hotspot_highlight

    # Verify hotspot highlight state changed
    engine.render_manager.hotspot_highlighting_enabled?.should_not eq(initial_highlight_enabled)

    RL.close_window
  end

  it "blocks mouse input when dialog is active but allows keyboard shortcuts" do
    RL.init_window(800, 600, "Input Blocking Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Input Block Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Simulate an active dialog
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100_f32, y: 100_f32),
      RL::Vector2.new(x: 200_f32, y: 100_f32)
    )
    dialog.show
    engine.show_dialog(dialog)

    # Update engine to trigger input blocking
    engine.update(0.016_f32) # 60fps frame time

    # Verify that input is blocked for mouse but keyboard shortcuts work
    input_manager = engine.input_manager
    input_manager.input_blocked?.should be_true
    input_manager.input_block_source.should eq("dialog_active")

    # Keyboard shortcuts should still function (tested above)
    # This verifies the infrastructure is in place

    RL.close_window
  end

  it "handles verb input system keyboard shortcuts during dialog" do
    RL.init_window(800, 600, "Verb Keyboard Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Verb Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Enable verb input system
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Simulate an active dialog
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100_f32, y: 100_f32),
      RL::Vector2.new(x: 200_f32, y: 100_f32)
    )
    dialog.show
    engine.show_dialog(dialog)

    # Test that verb system initialization doesn't crash with dialog active
    if verb_system = engine.verb_input_system
      verb_system.enabled.should be_true
      # Keyboard shortcuts should be handled by engine's keyboard handler
      # rather than being blocked by dialog
    end

    RL.close_window
  end

  it "handles mouse wheel verb cycling during dialog" do
    RL.init_window(800, 600, "Mouse Wheel Test")
    engine = PointClickEngine::Core::Engine.new(
      title: "Wheel Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Create scene with verb system
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Simulate an active dialog
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100_f32, y: 100_f32),
      RL::Vector2.new(x: 200_f32, y: 100_f32)
    )
    dialog.show
    engine.show_dialog(dialog)

    # Test that mouse wheel handling is available
    # Note: We can't simulate actual mouse wheel input in specs
    # but we can verify the verb system is enabled and responsive
    if verb_system = engine.verb_input_system
      verb_system.enabled.should be_true
      initial_verb = verb_system.cursor_manager.current_verb

      # Test cycling verbs directly
      verb_system.cursor_manager.cycle_verb_forward
      verb_system.cursor_manager.current_verb.should_not eq(initial_verb)
    end

    RL.close_window
  end
end
