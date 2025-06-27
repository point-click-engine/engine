require "../spec_helper"

describe "Door Interaction System" do
  describe "Action-based transitions for doors" do
    it "triggers scene transitions through hotspot actions" do
      RL.init_window(800, 600, "Door Interaction Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Door Test")
      engine.init
      engine.enable_verb_input

      # Create a scene with a door hotspot
      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Create a door hotspot with transition action
      door_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "door_hotspot",
        RL::Vector2.new(x: 850f32, y: 300f32),
        RL::Vector2.new(x: 100f32, y: 200f32)
      )
      door_hotspot.description = "A wooden door"
      door_hotspot.default_verb = PointClickEngine::UI::VerbType::Open
      door_hotspot.object_type = PointClickEngine::UI::ObjectType::Door
      door_hotspot.action_commands["open"] = "transition:next_scene:swirl:2.0:100,400"
      door_hotspot.action_commands["use"] = "transition:next_scene:swirl:2.0:100,400"
      scene.add_hotspot(door_hotspot)

      # Get the verb input system
      verb_system = engine.verb_input_system
      verb_system.should_not be_nil
      verb_system = verb_system.not_nil!

      # Verify door is configured correctly
      door_position = RL::Vector2.new(x: 850f32, y: 300f32)
      found_hotspot = scene.get_hotspot_at(door_position)
      found_hotspot.should_not be_nil
      found_hotspot.should be(door_hotspot)

      # Check action commands
      door_hotspot.action_commands["open"].should eq("transition:next_scene:swirl:2.0:100,400")

      RL.close_window
    end

    it "parses transition commands correctly" do
      # Test full transition command
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:laboratory:star_wipe:4.5:200,300")
      result.should_not be_nil
      if result
        result[:scene].should eq("laboratory")
        result[:effect].should eq(PointClickEngine::Graphics::TransitionEffect::StarWipe)
        result[:duration].should eq(4.5f32)
        result[:position].should_not be_nil
        if pos = result[:position]
          pos.x.should eq(200f32)
          pos.y.should eq(300f32)
        end
      end

      # Test minimal transition command
      result2 = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden")
      result2.should_not be_nil
      if result2
        result2[:scene].should eq("garden")
        result2[:effect].should eq(PointClickEngine::Graphics::TransitionEffect::Fade)
        result2[:duration].should eq(-1.0f32) # -1.0 signals to use scene's default duration
        result2[:position].should be_nil
      end

      # Test non-transition command
      result3 = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("look_at_painting")
      result3.should be_nil
    end

    it "supports different verbs triggering transitions" do
      RL.init_window(800, 600, "Multi-verb Transition Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Multi-verb Test")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Create an NPC that can teleport you when talked to
      npc_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "wizard",
        RL::Vector2.new(x: 400f32, y: 300f32),
        RL::Vector2.new(x: 64f32, y: 96f32)
      )
      npc_hotspot.description = "A mysterious wizard"
      npc_hotspot.default_verb = PointClickEngine::UI::VerbType::Talk
      npc_hotspot.object_type = PointClickEngine::UI::ObjectType::Character
      npc_hotspot.action_commands["talk"] = "transition:wizard_tower:vortex:3.0:500,300"
      scene.add_hotspot(npc_hotspot)

      # Create a button that triggers scene change
      button_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "magic_button",
        RL::Vector2.new(x: 200f32, y: 200f32),
        RL::Vector2.new(x: 50f32, y: 50f32)
      )
      button_hotspot.description = "A glowing button"
      button_hotspot.default_verb = PointClickEngine::UI::VerbType::Use
      button_hotspot.object_type = PointClickEngine::UI::ObjectType::Device
      button_hotspot.action_commands["use"] = "transition:control_room:matrix_rain:2.5"
      button_hotspot.action_commands["push"] = "transition:control_room:matrix_rain:2.5"
      scene.add_hotspot(button_hotspot)

      # Verify hotspots are configured correctly
      npc_hotspot.action_commands["talk"].should eq("transition:wizard_tower:vortex:3.0:500,300")
      button_hotspot.action_commands["use"].should eq("transition:control_room:matrix_rain:2.5")
      button_hotspot.action_commands["push"].should eq("transition:control_room:matrix_rain:2.5")

      RL.close_window
    end
  end

  describe "Verb System Integration" do
    it "correctly handles door hotspots with open verb" do
      RL.init_window(800, 600, "Verb Integration Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Verb Test")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      engine.add_scene(scene)
      engine.change_scene("test_scene")

      # Create multiple hotspots including doors
      regular_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "bookshelf",
        RL::Vector2.new(x: 100f32, y: 200f32),
        RL::Vector2.new(x: 150f32, y: 300f32)
      )
      regular_hotspot.default_verb = PointClickEngine::UI::VerbType::Look
      scene.add_hotspot(regular_hotspot)

      door_hotspot = PointClickEngine::Scenes::Hotspot.new(
        "exit_door",
        RL::Vector2.new(x: 800f32, y: 300f32),
        RL::Vector2.new(x: 100f32, y: 200f32)
      )
      door_hotspot.default_verb = PointClickEngine::UI::VerbType::Open
      door_hotspot.object_type = PointClickEngine::UI::ObjectType::Door
      door_hotspot.action_commands["open"] = "transition:next_room:fade:1.0"
      scene.add_hotspot(door_hotspot)

      # Test door identification
      door_position = RL::Vector2.new(x: 850f32, y: 400f32)
      found_door = scene.get_hotspot_at(door_position)
      found_door.should_not be_nil
      found_door.should be(door_hotspot)
      if door = found_door
        door.default_verb.should eq(PointClickEngine::UI::VerbType::Open)
        door.object_type.should eq(PointClickEngine::UI::ObjectType::Door)
      end

      # Test that regular hotspots have different properties
      bookshelf_position = RL::Vector2.new(x: 175f32, y: 350f32)
      found_bookshelf = scene.get_hotspot_at(bookshelf_position)
      found_bookshelf.should be(regular_hotspot)
      if bookshelf = found_bookshelf
        bookshelf.default_verb.should eq(PointClickEngine::UI::VerbType::Look)
      end

      RL.close_window
    end

    it "preserves backward compatibility for non-door hotspots" do
      RL.init_window(800, 600, "Compatibility Test")
      engine = PointClickEngine::Core::Engine.new(800, 600, "Compatibility Test")
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
      chest_hotspot.default_verb = PointClickEngine::UI::VerbType::Open
      chest_hotspot.object_type = PointClickEngine::UI::ObjectType::Container
      scene.add_hotspot(chest_hotspot)

      # Regular hotspots should still be found normally
      chest_position = RL::Vector2.new(x: 540f32, y: 430f32)
      found_hotspot = scene.get_hotspot_at(chest_position)
      found_hotspot.should be(chest_hotspot)

      # Should not have transition actions by default
      if hotspot = found_hotspot
        hotspot.action_commands.empty?.should be_true
      end

      RL.close_window
    end

    it "handles action commands without transitions" do
      scene = PointClickEngine::Scenes::Scene.new("test")

      hotspot = PointClickEngine::Scenes::Hotspot.new(
        "painting",
        RL::Vector2.new(x: 300f32, y: 200f32),
        RL::Vector2.new(x: 100f32, y: 150f32)
      )
      hotspot.action_commands["look"] = "It's a beautiful landscape painting"
      hotspot.action_commands["use"] = "I can't interact with the painting"
      scene.add_hotspot(hotspot)

      # Non-transition commands should remain as-is
      hotspot.action_commands["look"].should eq("It's a beautiful landscape painting")
      hotspot.action_commands["use"].should eq("I can't interact with the painting")
    end
  end
end
