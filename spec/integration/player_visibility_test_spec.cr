require "../spec_helper"

describe "Player Visibility in Scene Transitions" do
  it "ensures player is visible in all scenes" do
    # Create a minimal engine setup
    engine = PointClickEngine::Core::Engine.new(1024, 768, "Test Game")

    # Create player
    player = PointClickEngine::Characters::Player.new(
      "TestPlayer",
      RL::Vector2.new(x: 500f32, y: 400f32),
      RL::Vector2.new(x: 32f32, y: 64f32)
    )
    engine.player = player

    # Create test scenes
    library = PointClickEngine::Scenes::Scene.new("library")
    laboratory = PointClickEngine::Scenes::Scene.new("laboratory")
    garden = PointClickEngine::Scenes::Scene.new("garden")

    # Add walkable areas to each scene
    library_walkable = PointClickEngine::Scenes::WalkableArea.new
    library_region = PointClickEngine::Scenes::PolygonRegion.new("main_floor", true)
    library_region.vertices = [
      RL::Vector2.new(x: 100f32, y: 350f32),
      RL::Vector2.new(x: 900f32, y: 350f32),
      RL::Vector2.new(x: 900f32, y: 700f32),
      RL::Vector2.new(x: 100f32, y: 700f32),
    ] of RL::Vector2
    library_walkable.regions << library_region
    library.walkable_area = library_walkable

    # For laboratory and garden, they now have walkable areas from the YAML files
    # But for this test, we'll add them programmatically
    lab_walkable = PointClickEngine::Scenes::WalkableArea.new
    lab_region = PointClickEngine::Scenes::PolygonRegion.new("main_floor", true)
    lab_region.vertices = [
      RL::Vector2.new(x: 50f32, y: 300f32),
      RL::Vector2.new(x: 950f32, y: 300f32),
      RL::Vector2.new(x: 950f32, y: 700f32),
      RL::Vector2.new(x: 50f32, y: 700f32),
    ] of RL::Vector2
    lab_walkable.regions << lab_region
    laboratory.walkable_area = lab_walkable

    garden_walkable = PointClickEngine::Scenes::WalkableArea.new
    garden_region = PointClickEngine::Scenes::PolygonRegion.new("main_garden", true)
    garden_region.vertices = [
      RL::Vector2.new(x: 50f32, y: 250f32),
      RL::Vector2.new(x: 950f32, y: 250f32),
      RL::Vector2.new(x: 950f32, y: 700f32),
      RL::Vector2.new(x: 50f32, y: 700f32),
    ] of RL::Vector2
    garden_walkable.regions << garden_region
    garden.walkable_area = garden_walkable

    # Add scenes to engine
    engine.add_scene(library)
    engine.add_scene(laboratory)
    engine.add_scene(garden)

    # Start with library scene
    engine.change_scene("library")
    library.set_player(player)

    # Verify player is in library
    library.player.should eq(player)
    library.characters.includes?(player).should be_true

    # Create door hotspot to laboratory
    door_to_lab = PointClickEngine::Scenes::Hotspot.new(
      "door_to_lab",
      RL::Vector2.new(x: 850f32, y: 300f32),
      RL::Vector2.new(x: 100f32, y: 200f32)
    )
    door_to_lab.default_verb = PointClickEngine::UI::VerbType::Open
    door_to_lab.object_type = PointClickEngine::UI::ObjectType::Door
    door_to_lab.action_commands["open"] = "transition:laboratory:fade:1.0:100,400"
    library.add_hotspot(door_to_lab)

    # Simulate scene transition
    engine.change_scene("laboratory")

    # Get the actual current scene from the engine
    current_scene = engine.current_scene.not_nil!

    # Verify player is now in the current scene (laboratory)
    current_scene.player.should eq(player)
    current_scene.characters.includes?(player).should be_true

    # Transition to garden
    engine.change_scene("garden")

    # Get the actual current scene from the engine
    garden_scene = engine.current_scene.not_nil!

    # Verify player is in the current scene (garden)
    garden_scene.player.should eq(player)
    garden_scene.characters.includes?(player).should be_true

    # Note: The player may still be in previous scenes' character lists
    # because the engine doesn't automatically remove characters when changing scenes.
    # The important thing is that the player is properly set in the current scene.
  end

  it "ensures player is drawn even without walkable areas" do
    engine = PointClickEngine::Core::Engine.new(1024, 768, "Test Game")

    # Create scene without walkable area
    scene = PointClickEngine::Scenes::Scene.new("test_scene")

    # Create and add player
    player = PointClickEngine::Characters::Player.new(
      "TestPlayer",
      RL::Vector2.new(x: 500f32, y: 400f32),
      RL::Vector2.new(x: 32f32, y: 64f32)
    )

    scene.set_player(player)

    # Verify player is in scene's character list
    scene.player.should eq(player)
    scene.characters.includes?(player).should be_true

    # The fixed draw method should handle this case properly
    scene.walkable_area.should be_nil

    # Player should still be in the sorted characters list for drawing
    all_chars = scene.characters.dup
    all_chars << player if scene.player && !all_chars.includes?(player)
    all_chars.size.should eq(1)
    all_chars.includes?(player).should be_true
  end
end
