require "../spec_helper"

describe "Dialog input blocking" do
  it "blocks game input when dialog is active" do
    # Create a minimal engine setup
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    # Create a scene
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Create a player
    player = PointClickEngine::Characters::Player.new(
      "player",
      RL::Vector2.new(x: 400, y: 300),
      RL::Vector2.new(x: 32, y: 64)
    )
    engine.player = player
    scene.set_player(player)

    # Track player position to see if they moved
    original_position = player.position

    # Show a dialog with choices
    choices = [
      PointClickEngine::UI::DialogChoice.new("Choice 1", -> { }),
      PointClickEngine::UI::DialogChoice.new("Choice 2", -> { })
    ]

    engine.dialog_manager.try(&.show_dialog("Test Character", "Test dialog", choices))

    # Update engine - dialog should be active
    engine.update(0.016_f32)

    # Player should not have moved
    player.position.should eq(original_position)

    # Dialog should still be visible
    engine.dialog_manager.try(&.current_dialog).should_not be_nil
  end

  it "resumes game input after dialog closes" do
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    # Create a scene
    scene = PointClickEngine::Scenes::Scene.new("test_scene")
    engine.add_scene(scene)
    engine.change_scene("test_scene")

    # Create a player
    player = PointClickEngine::Characters::Player.new(
      "player",
      RL::Vector2.new(x: 400, y: 300),
      RL::Vector2.new(x: 32, y: 64)
    )
    engine.player = player
    scene.set_player(player)

    # Show and immediately hide dialog
    engine.dialog_manager.try(&.show_dialog("Test Character", "Test dialog"))

    # Close the dialog
    engine.dialog_manager.try(&.close_current_dialog)

    # Update engine
    engine.update(0.016_f32)

    # Dialog should be hidden
    engine.dialog_manager.try(&.current_dialog).should be_nil
  end
end
