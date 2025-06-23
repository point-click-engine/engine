require "../spec_helper"

describe "Dialog Input Handling" do
  it "prevents scene input when dialog is handling input" do
    # Create test engine
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    # Create and add a test scene
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Create a test player
    player = PointClickEngine::Characters::Player.new(
      "TestPlayer",
      RL::Vector2.new(x: 400, y: 300),
      RL::Vector2.new(x: 32, y: 64)
    )
    engine.player = player
    scene.set_player(player)

    # Track if player moved
    player_moved = false
    original_walk_to = player.walk_to
    player.define_singleton_method(:walk_to) do |target|
      player_moved = true
      original_walk_to.call(target)
    end

    # Show a dialog with choices
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 600, y: 200)
    )
    dialog.add_choice("Choice 1") { }
    dialog.add_choice("Choice 2") { }
    dialog.show

    engine.show_dialog(dialog)

    # Simulate first frame update to set ready_to_process_input
    engine.update(0.016)

    # Verify dialog is ready
    dialog.visible.should be_true
    dialog.ready_to_process_input.should be_true

    # Simulate mouse click
    RL.set_mouse_position(400, 400)

    # Mock mouse button press
    original_pressed = RL.mouse_button_pressed?
    RL.define_singleton_method(:mouse_button_pressed?) do |button|
      button == RL::MouseButton::Left
    end

    # Update engine - dialog should handle input, player should not move
    engine.update(0.016)

    # Restore original method
    RL.define_singleton_method(:mouse_button_pressed?) do |button|
      original_pressed.call(button)
    end

    # Verify player did not move
    player_moved.should be_false
  end

  it "allows scene input when no dialog is visible" do
    # Create test engine
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    # Create and add a test scene
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Create a test player
    player = PointClickEngine::Characters::Player.new(
      "TestPlayer",
      RL::Vector2.new(x: 400, y: 300),
      RL::Vector2.new(x: 32, y: 64)
    )
    engine.player = player
    scene.set_player(player)

    # Track if input was processed
    input_processed = false

    # Mock the input handler to track if it was called
    original_process = engine.input_handler.process_input
    engine.input_handler.define_singleton_method(:process_input) do |scene, player, camera|
      input_processed = true
      original_process.call(scene, player, camera)
    end

    # No dialogs shown

    # Update engine - input should be processed
    engine.update(0.016)

    # Verify input was processed
    input_processed.should be_true
  end

  it "allows scene input when dialog is visible but not ready" do
    # Create test engine
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    # Create and add a test scene
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Show a dialog
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 600, y: 200)
    )
    dialog.show
    engine.show_dialog(dialog)

    # Dialog is visible but not ready (first frame)
    dialog.visible.should be_true
    dialog.ready_to_process_input.should be_false

    # Track if input was processed
    input_processed = false

    # Mock the input handler to track if it was called
    original_process = engine.input_handler.process_input
    engine.input_handler.define_singleton_method(:process_input) do |scene, player, camera|
      input_processed = true
      original_process.call(scene, player, camera)
    end

    # Update engine - input should be processed because dialog is not ready
    engine.update(0.016)

    # Verify input was processed
    input_processed.should be_true
  end
end
