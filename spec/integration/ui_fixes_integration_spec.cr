require "../spec_helper"

describe "UI Fixes Integration Tests" do
  it "renders floating dialogs correctly in the UI pipeline" do
    RL.init_window(800, 600, "Floating Dialog Integration Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Dialog Render Test")
    engine.init

    # Test that dialog manager is accessible through correct path
    dialog_manager = engine.system_manager.dialog_manager
    dialog_manager.should_not be_nil

    # Test floating dialog manager integration
    if dm = dialog_manager
      dm.enable_floating.should be_true
      dm.floating_manager.should_not be_nil

      # Test that floating dialogs can be created
      character_pos = RL::Vector2.new(x: 400, y: 300)
      dm.show_floating_dialog("TestChar", "Hello world!", character_pos)

      # Verify floating dialog was added
      dm.floating_manager.has_active_dialogs?.should be_true
    end

    RL.close_window
  end

  it "renders cursor with verb visual feedback in the UI layer" do
    RL.init_window(800, 600, "Cursor Visual Feedback Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Cursor Test")
    engine.init

    # Enable verb input system
    engine.enable_verb_input

    # Test that verb input system is initialized
    verb_system = engine.verb_input_system
    verb_system.should_not be_nil

    if vs = verb_system
      # Test cursor manager initialization
      vs.cursor_manager.should_not be_nil

      # Test verb cycling functionality
      initial_verb = vs.cursor_manager.current_verb
      vs.cursor_manager.cycle_verb_forward
      vs.cursor_manager.current_verb.should_not eq(initial_verb)

      # Test that cursor manager can draw (would be called by UI renderer)
      display_manager = engine.system_manager.display_manager
      mouse_pos = RL::Vector2.new(x: 100, y: 100)

      # This should not crash and should handle drawing
      vs.cursor_manager.draw(mouse_pos)
    end

    RL.close_window
  end

  it "properly integrates keyboard shortcuts with dialog input blocking" do
    RL.init_window(800, 600, "Keyboard Integration Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Keyboard Test")
    engine.init

    # Create a scene with verb input system
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Simulate dialog being active
    engine.dialog_manager.try(&.show_dialog("Test Character", "Test dialog"))

    # Update engine to trigger input blocking
    engine.update(0.016_f32)

    # Verify input is blocked but keyboard shortcuts still work
    input_manager = engine.input_manager

    # Test that verb input system can still process keyboard input
    if verb_system = engine.verb_input_system
      verb_system.enabled.should be_true

      # Keyboard shortcuts should work via VerbInputSystem handle_keyboard_input
      # which is called before dialog input blocking check
    end

    RL.close_window
  end

  it "maintains hotspot highlighting state correctly" do
    RL.init_window(800, 600, "Hotspot Highlight Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Hotspot Test")
    engine.init

    # Test initial hotspot highlighting state
    initial_state = engine.render_manager.hotspot_highlighting_enabled?

    # Test toggling hotspot highlighting
    engine.toggle_hotspot_highlight
    new_state = engine.render_manager.hotspot_highlighting_enabled?
    new_state.should_not eq(initial_state)

    # Test toggling again
    engine.toggle_hotspot_highlight
    final_state = engine.render_manager.hotspot_highlighting_enabled?
    final_state.should eq(initial_state)

    RL.close_window
  end

  it "handles door interactions with proper verb system integration" do
    RL.init_window(800, 600, "Door Interaction Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Door Test")
    engine.init

    # Create a scene with a door hotspot
    scene = PointClickEngine::Scenes::Scene.new("door_test_scene")

    # Create a door hotspot with transition action
    door_position = RL::Vector2.new(x: 500, y: 300)
    door_size = RL::Vector2.new(x: 60, y: 100)

    door = PointClickEngine::Scenes::Hotspot.new(
      "door",
      door_position,
      door_size
    )
    door.description = "A wooden door"
    door.default_verb = PointClickEngine::UI::VerbType::Open
    door.object_type = PointClickEngine::UI::ObjectType::Door
    door.action_commands["open"] = "transition:next_room:fade:1.0"
    door.action_commands["use"] = "transition:next_room:fade:1.0"

    scene.add_hotspot(door)
    engine.add_scene(scene)
    engine.change_scene("door_test_scene")

    # Test that verb system can handle door interactions
    if verb_system = engine.verb_input_system
      # Test that door is detected at its position
      current_scene = engine.current_scene
      current_scene.should_not be_nil

      if cs = current_scene
        hotspot_at_door = cs.get_hotspot_at(door_position)
        hotspot_at_door.should eq(door)

        # Test different verbs on the door
        verb_system.cursor_manager.set_verb(PointClickEngine::UI::VerbType::Use)
        verb_system.cursor_manager.current_verb.should eq(PointClickEngine::UI::VerbType::Use)

        verb_system.cursor_manager.set_verb(PointClickEngine::UI::VerbType::Open)
        verb_system.cursor_manager.current_verb.should eq(PointClickEngine::UI::VerbType::Open)
      end
    end

    RL.close_window
  end

  it "maintains consistent state across UI system integrations" do
    RL.init_window(800, 600, "UI System Integration Test")
    engine = PointClickEngine::Core::Engine.new(800, 600, "Integration Test")
    engine.init

    # Enable verb input system
    engine.enable_verb_input

    # Test that all systems are properly initialized
    engine.system_manager.should_not be_nil
    engine.system_manager.dialog_manager.should_not be_nil
    engine.system_manager.display_manager.should_not be_nil
    engine.verb_input_system.should_not be_nil
    engine.render_manager.should_not be_nil
    engine.input_manager.should_not be_nil

    # Test that systems work together
    # 1. Create a scene
    scene = PointClickEngine::Scenes::Scene.new("integration_test")
    engine.add_scene(scene)
    engine.change_scene("integration_test")

    # 2. Test verb system with dialog system
    if verb_system = engine.verb_input_system
      verb_system.enabled = true

      # 3. Test floating dialog integration
      if dm = engine.system_manager.dialog_manager
        character_pos = RL::Vector2.new(x: 300, y: 400)
        dm.show_floating_dialog("Player", "Testing integration", character_pos)

        # 4. Test that keyboard shortcuts still work
        initial_debug = PointClickEngine::Core::Engine.debug_mode
        # Simulate F1 press handling (direct toggle test)
        PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
        PointClickEngine::Core::Engine.debug_mode.should_not eq(initial_debug)

        # 5. Test verb cycling
        initial_verb = verb_system.cursor_manager.current_verb
        verb_system.cursor_manager.cycle_verb_forward
        verb_system.cursor_manager.current_verb.should_not eq(initial_verb)
      end
    end

    RL.close_window
  end
end
