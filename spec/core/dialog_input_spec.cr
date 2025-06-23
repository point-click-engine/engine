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
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 600, y: 200)
    )
    dialog.add_choice("Choice 1") { }
    dialog.add_choice("Choice 2") { }
    dialog.show
    
    engine.show_dialog(dialog)
    
    # Update engine - dialog should be active
    engine.update(0.016_f32)
    
    # Player should not have moved
    player.position.should eq(original_position)
    
    # Dialog should still be visible
    dialog.visible.should be_true
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
    dialog = PointClickEngine::UI::Dialog.new(
      "Test dialog",
      RL::Vector2.new(x: 100, y: 100),
      RL::Vector2.new(x: 600, y: 200)
    )
    dialog.show
    engine.show_dialog(dialog)
    
    # Close the dialog
    dialog.hide
    
    # Update engine
    engine.update(0.016_f32)
    
    # Dialog should be hidden
    dialog.visible.should be_false
  end
end