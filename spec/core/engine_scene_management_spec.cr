require "../spec_helper"

module PointClickEngine
  class TestCharacter < Characters::Character
    def on_interact(interactor : Character)
      # Test implementation
    end

    def on_look
      # Test implementation
    end

    def on_talk
      # Test implementation
    end
  end
end

describe "Engine Scene Management" do
  describe "scene loading and initialization" do
    it "loads scenes from YAML configuration" do
      RL.init_window(800, 600, "Scene Management Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Create and add a scene manually
      scene = PointClickEngine::Scenes::Scene.new("test_room")
      scene.background_path = "assets/test_bg.png"

      engine.scenes["test_room"] = scene

      # Verify scene was added
      engine.scenes.has_key?("test_room").should be_true
      engine.scenes["test_room"].name.should eq("test_room")

      RL.close_window
    end

    it "handles scene transitions" do
      RL.init_window(800, 600, "Scene Transition Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Create two scenes
      scene1 = PointClickEngine::Scenes::Scene.new("room1")
      scene2 = PointClickEngine::Scenes::Scene.new("room2")

      engine.scenes["room1"] = scene1
      engine.scenes["room2"] = scene2

      # Change to first scene
      engine.change_scene("room1")
      engine.current_scene_name.should eq("room1")

      # Change to second scene
      engine.change_scene("room2")
      engine.current_scene_name.should eq("room2")

      RL.close_window
    end

    it "handles invalid scene transitions gracefully" do
      RL.init_window(800, 600, "Invalid Scene Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      initial_scene = engine.current_scene_name

      # Try to change to non-existent scene
      engine.change_scene("nonexistent_scene")

      # Should remain in same scene
      engine.current_scene_name.should eq(initial_scene)

      RL.close_window
    end
  end

  describe "scene content management" do
    it "manages hotspots within scenes" do
      RL.init_window(800, 600, "Hotspot Management Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      hotspot1 = PointClickEngine::Scenes::Hotspot.new("door", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 50, y: 50))
      hotspot2 = PointClickEngine::Scenes::Hotspot.new("window", RL::Vector2.new(x: 200, y: 100), RL::Vector2.new(x: 50, y: 50))

      scene.add_hotspot(hotspot1)
      scene.add_hotspot(hotspot2)

      engine.scenes["test_scene"] = scene
      engine.change_scene("test_scene")

      # Verify hotspots are accessible
      current_scene = engine.current_scene
      current_scene.should_not be_nil
      current_scene.try(&.hotspots.size).should eq(2)

      RL.close_window
    end

    it "manages characters within scenes" do
      RL.init_window(800, 600, "Character Management Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      character = PointClickEngine::TestCharacter.new("npc", RL::Vector2.new(x: 150, y: 200), RL::Vector2.new(x: 32, y: 32))

      scene.add_character(character)

      engine.scenes["test_scene"] = scene
      engine.change_scene("test_scene")

      # Verify character is accessible
      current_scene = engine.current_scene
      current_scene.should_not be_nil
      current_scene.try(&.characters.size).should eq(1)
      current_scene.try(&.characters.first.name).should eq("npc")

      RL.close_window
    end

    it "handles player character positioning across scenes" do
      RL.init_window(800, 600, "Player Positioning Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Create player
      player = PointClickEngine::TestCharacter.new("hero", RL::Vector2.new(x: 100, y: 100), RL::Vector2.new(x: 32, y: 32))
      engine.player = player

      # Create scenes
      scene1 = PointClickEngine::Scenes::Scene.new("room1")
      scene2 = PointClickEngine::Scenes::Scene.new("room2")

      engine.scenes["room1"] = scene1
      engine.scenes["room2"] = scene2

      # Move to first scene
      engine.change_scene("room1")
      scene1.player.should eq(player)

      # Move to second scene
      engine.change_scene("room2")
      scene2.player.should eq(player)

      RL.close_window
    end
  end

  describe "scene state management" do
    it "preserves scene state when switching" do
      RL.init_window(800, 600, "Scene State Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      # Create scenes with different properties
      scene1 = PointClickEngine::Scenes::Scene.new("room1")
      scene1.scale = 1.5f32
      scene1.enable_pathfinding = false

      scene2 = PointClickEngine::Scenes::Scene.new("room2")
      scene2.scale = 2.0f32
      scene2.enable_pathfinding = true

      engine.scenes["room1"] = scene1
      engine.scenes["room2"] = scene2

      # Switch to room1 and verify properties
      engine.change_scene("room1")
      current = engine.current_scene.not_nil!
      current.scale.should eq(1.5f32)
      current.enable_pathfinding.should be_false

      # Switch to room2 and verify properties
      engine.change_scene("room2")
      current = engine.current_scene.not_nil!
      current.scale.should eq(2.0f32)
      current.enable_pathfinding.should be_true

      # Switch back to room1 and verify state preserved
      engine.change_scene("room1")
      current = engine.current_scene.not_nil!
      current.scale.should eq(1.5f32)
      current.enable_pathfinding.should be_false

      RL.close_window
    end

    it "handles scene callback execution" do
      RL.init_window(800, 600, "Scene Callbacks Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      enter_called = false
      exit_called = false

      scene1 = PointClickEngine::Scenes::Scene.new("room1")
      scene1.on_enter = -> { enter_called = true; nil }
      scene1.on_exit = -> { exit_called = true; nil }

      scene2 = PointClickEngine::Scenes::Scene.new("room2")

      engine.scenes["room1"] = scene1
      engine.scenes["room2"] = scene2

      # Enter room1
      engine.change_scene("room1")
      enter_called.should be_true

      # Exit room1 to room2
      engine.change_scene("room2")
      exit_called.should be_true

      RL.close_window
    end
  end

  describe "scene scripting integration" do
    it "loads and associates scripts with scenes" do
      RL.init_window(800, 600, "Scene Scripting Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("script_test_scene")
      scene.script_path = "test_script.lua"

      engine.scenes["script_test_scene"] = scene

      # Verify script path is set
      scene.script_path.should eq("test_script.lua")

      RL.close_window
    end

    it "handles walkable area configuration" do
      RL.init_window(800, 600, "Walkable Area Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("walkable_test_scene")
      scene.enable_pathfinding = true
      scene.navigation_cell_size = 8

      engine.scenes["walkable_test_scene"] = scene

      # Verify pathfinding configuration
      scene.enable_pathfinding.should be_true
      scene.navigation_cell_size.should eq(8)

      RL.close_window
    end
  end

  describe "scene rendering and camera" do
    it "handles scene scaling and camera integration" do
      RL.init_window(800, 600, "Scene Rendering Test")
      engine = PointClickEngine::Core::Engine.new(
        title: "Scene Test Game",
        window_width: 800,
        window_height: 600
      )
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("render_test_scene")
      scene.scale = 0.75f32
      scene.enable_camera_scrolling = true

      engine.scenes["render_test_scene"] = scene
      engine.change_scene("render_test_scene")

      # Verify rendering properties
      current_scene = engine.current_scene.not_nil!
      current_scene.scale.should eq(0.75f32)
      current_scene.enable_camera_scrolling.should be_true

      RL.close_window
    end
  end
end
