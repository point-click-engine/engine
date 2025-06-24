require "../spec_helper"

describe "Door Interaction System" do
  describe "ExitZone Priority for Open Verb" do
    it "prioritizes ExitZones over regular hotspots when using open verb" do
      RL.init_window(800, 600, "Door Interaction Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Door Test",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Create a scene with overlapping hotspot and exit zone (like library door)
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Create a regular hotspot at door location
      door_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door_hotspot",
        RL::Vector2.new(x: 850f32, y: 300f32),
        RL::Vector2.new(x: 100f32, y: 200f32)
      )
      door_hotspot.description = "A wooden door"
      scene.add_hotspot(door_hotspot)

      # Create an exit zone at the same location
      exit_zone = PointClickEngine::Scenes::ExitZone.new(
        "door_exit",
        RL::Vector2.new(x: 850f32, y: 300f32),
        RL::Vector2.new(x: 100f32, y: 200f32),
        "next_scene"
      )
      scene.add_hotspot(exit_zone)

      # Get the verb input system (may be nil if not initialized)
      verb_system = engine.verb_input_system
      if verb_system.nil?
        # Initialize verb system if not already done
        engine.enable_verb_coin = true
        engine.update(0.016f32) # trigger initialization
        verb_system = engine.verb_input_system.not_nil!
      end

      # Set up the "open" verb
      verb_system.cursor_manager.set_verb(PointClickEngine::UI::VerbType::Open)

      # Click at the door position (850, 300 is center of the door)
      door_position = RL::Vector2.new(x: 875f32, y: 400f32)

      # Test that both hotspots are found at this position
      found_hotspot = scene.get_hotspot_at(door_position)
      found_hotspot.should_not be_nil

      # The regular hotspot should be found by default (it was added last)
      found_hotspot.should be(door_hotspot)

      # But ExitZones should be findable too
      found_exit = scene.hotspots.find { |h| h.is_a?(PointClickEngine::Scenes::ExitZone) && h.contains_point?(door_position) }
      found_exit.should_not be_nil
      found_exit.should be(exit_zone)

      RL.close_window
    end

    it "handles scene transitions when opening doors" do
      RL.init_window(800, 600, "Scene Transition Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Transition Test",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Create source scene
      library_scene = PointClickEngine::Scenes::Scene.new("library")
      engine.add_scene(library_scene)

      # Create target scene
      lab_scene = PointClickEngine::Scenes::Scene.new("laboratory")
      engine.add_scene(lab_scene)

      engine.change_scene("library")

      # Create exit zone that leads to laboratory
      exit_zone = PointClickEngine::Scenes::ExitZone.new(
        "door_to_lab",
        RL::Vector2.new(x: 850f32, y: 300f32),
        RL::Vector2.new(x: 100f32, y: 200f32),
        "laboratory"
      )
      exit_zone.target_position = RL::Vector2.new(x: 100f32, y: 400f32)
      library_scene.add_hotspot(exit_zone)

      # Verify we start in library
      engine.current_scene.should be(library_scene)

      # The exit zone should be accessible (no item requirements)
      exit_zone.is_accessible?(engine.inventory).should be_true

      RL.close_window
    end

    it "shows appropriate message when door cannot be opened" do
      RL.init_window(800, 600, "Locked Door Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Locked Door Test",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Create a locked exit zone
      locked_exit = PointClickEngine::Scenes::ExitZone.new(
        "locked_door",
        RL::Vector2.new(x: 400f32, y: 300f32),
        RL::Vector2.new(x: 100f32, y: 200f32),
        "secret_room"
      )
      locked_exit.requires_item = "key"
      locked_exit.locked_message = "The door is locked. You need a key."
      scene.add_hotspot(locked_exit)

      # The exit should not be accessible without the required item
      locked_exit.is_accessible?(engine.inventory).should be_false

      RL.close_window
    end
  end

  describe "Verb System Integration" do
    it "correctly identifies ExitZones when processing open verb" do
      RL.init_window(800, 600, "Verb Integration Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Verb Test",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Create multiple hotspots including an ExitZone
      regular_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "bookshelf",
        RL::Vector2.new(x: 100f32, y: 200f32),
        RL::Vector2.new(x: 150f32, y: 300f32)
      )
      scene.add_hotspot(regular_hotspot)

      exit_zone = PointClickEngine::Scenes::ExitZone.new(
        "exit_door",
        RL::Vector2.new(x: 800f32, y: 300f32),
        RL::Vector2.new(x: 100f32, y: 200f32),
        "next_room"
      )
      scene.add_hotspot(exit_zone)

      # Test ExitZone identification
      exit_position = RL::Vector2.new(x: 850f32, y: 400f32)
      found_exits = scene.hotspots.select { |h| h.is_a?(PointClickEngine::Scenes::ExitZone) && h.contains_point?(exit_position) }
      found_exits.size.should eq(1)
      found_exits[0].should be(exit_zone)

      # Test that regular hotspots are not identified as ExitZones
      bookshelf_position = RL::Vector2.new(x: 175f32, y: 350f32)
      found_regular_exits = scene.hotspots.select { |h| h.is_a?(PointClickEngine::Scenes::ExitZone) && h.contains_point?(bookshelf_position) }
      found_regular_exits.size.should eq(0)

      RL.close_window
    end

    it "preserves backward compatibility for non-door hotspots" do
      RL.init_window(800, 600, "Compatibility Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Compatibility Test",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Create a regular hotspot that's not a door
      chest_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "treasure_chest",
        RL::Vector2.new(x: 500f32, y: 400f32),
        RL::Vector2.new(x: 80f32, y: 60f32)
      )
      chest_hotspot.description = "A mysterious chest"
      scene.add_hotspot(chest_hotspot)

      # Regular hotspots should still be found normally
      chest_position = RL::Vector2.new(x: 540f32, y: 430f32)
      found_hotspot = scene.get_hotspot_at(chest_position)
      found_hotspot.should be(chest_hotspot)

      # Should not be identified as ExitZone
      found_hotspot.is_a?(PointClickEngine::Scenes::ExitZone).should be_false

      RL.close_window
    end
  end
end
