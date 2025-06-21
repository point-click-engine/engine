require "../spec_helper"
require "../../src/scenes/scene_loader"
require "../../src/scenes/scene"
require "../../src/scenes/hotspot"
require "../../src/characters/character"
require "../../src/core/engine"

describe PointClickEngine::Scenes::SceneLoader do
  describe ".load_from_yaml" do
    it "loads a complete scene from YAML" do
      yaml_content = <<-YAML
      name: test_room
      background_path: assets/backgrounds/room.png
      scale: 2.0
      enable_pathfinding: true
      navigation_cell_size: 32
      script_path: scripts/test_room.lua
      hotspots:
        - name: door
          x: 100
          y: 50
          width: 50
          height: 100
          description: "A wooden door"
        - name: window
          x: 300
          y: 100
          width: 80
          height: 60
          description: "A window with a view"
      characters:
        - name: guard
          position:
            x: 200
            y: 150
          sprite_path: assets/characters/guard.png
        - name: merchant
          position:
            x: 400
            y: 180
      YAML

      File.write("temp_scene.yaml", yaml_content)

      scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("temp_scene.yaml")

      scene.name.should eq("test_room")
      scene.background_path.should eq("assets/backgrounds/room.png")
      scene.scale.should eq(2.0f32)
      scene.enable_pathfinding.should be_true
      scene.navigation_cell_size.should eq(32)
      scene.script_path.should eq("scripts/test_room.lua")

      scene.hotspots.size.should eq(2)
      door = scene.hotspots[0]
      door.name.should eq("door")
      door.bounds.x.should eq(100f32)
      door.bounds.y.should eq(50f32)
      door.bounds.width.should eq(50f32)
      door.bounds.height.should eq(100f32)
      door.description.should eq("A wooden door")

      window = scene.hotspots[1]
      window.name.should eq("window")
      window.description.should eq("A window with a view")

      scene.characters.size.should eq(2)
      guard = scene.characters[0]
      guard.name.should eq("guard")
      guard.position.x.should eq(200f32)
      guard.position.y.should eq(150f32)

      File.delete("temp_scene.yaml")
    end
  end

  describe ".save_to_yaml" do
    it "saves a scene to YAML format" do
      scene = PointClickEngine::Scenes::Scene.new("save_test")
      scene.background_path = "bg.png"
      scene.scale = 1.5f32

      pos = Raylib::Vector2.new(x: 10f32, y: 20f32)
      size = Raylib::Vector2.new(x: 30f32, y: 40f32)
      hotspot = PointClickEngine::Scenes::Hotspot.new("test_hotspot", pos, size)
      hotspot.description = "Test description"
      scene.add_hotspot(hotspot)

      char_pos = Raylib::Vector2.new(x: 50f32, y: 60f32)
      char_size = Raylib::Vector2.new(x: 32f32, y: 64f32)
      character = PointClickEngine::Characters::NPC.new("test_char", char_pos, char_size)
      scene.add_character(character)

      PointClickEngine::Scenes::SceneLoader.save_to_yaml(scene, "temp_save.yaml")

      loaded_scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("temp_save.yaml")
      loaded_scene.name.should eq("save_test")
      loaded_scene.background_path.should eq("bg.png")
      loaded_scene.scale.should eq(1.5f32)
      loaded_scene.hotspots.size.should eq(1)
      loaded_scene.characters.size.should eq(1)

      File.delete("temp_save.yaml")
    end
  end
end

describe "Scene Integration Test" do
  it "loads scene assets and handles interactions" do
    engine = PointClickEngine::Core::Engine.new

    yaml_content = <<-YAML
    name: integration_test_room
    background_path: assets/test_bg.png
    hotspots:
      - name: interactive_object
        x: 50
        y: 50
        width: 100
        height: 100
        description: "Click me!"
    characters:
      - name: npc
        position:
          x: 200
          y: 200
    YAML

    File.write("integration_test.yaml", yaml_content)

    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("integration_test.yaml")

    clicked = false
    scene.hotspots[0].on_click = -> { clicked = true }

    # Test that hotspot contains the point
    test_point = Raylib::Vector2.new(x: 75f32, y: 75f32)
    scene.hotspots[0].contains_point?(test_point).should be_true

    # Test click callback
    scene.hotspots[0].on_click.not_nil!.call
    clicked.should be_true

    npc = scene.characters[0]
    npc.should_not be_nil
    npc.name.should eq("npc")
    npc.position.x.should eq(200f32)

    if scene.enable_pathfinding
      # Note: setup_navigation requires a background texture to be loaded
      # which isn't done in this test
    end

    File.delete("integration_test.yaml")
  end
end

describe "Lua Script Integration" do
  it "loads and executes scene scripts" do
    engine = PointClickEngine::Core::Engine.new
    engine.script_engine = PointClickEngine::Scripting::ScriptEngine.new

    lua_script = <<-LUA
    scene_loaded = true
    test_value = 42
    
    function on_enter()
      entered = true
    end
    
    function on_hotspot_click(name)
      last_clicked = name
    end
    LUA

    File.write("test_script.lua", lua_script)

    yaml_content = <<-YAML
    name: scripted_room
    script_path: test_script.lua
    hotspots:
      - name: scripted_object
        x: 0
        y: 0
        width: 50
        height: 50
    YAML

    File.write("scripted_scene.yaml", yaml_content)

    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("scripted_scene.yaml")
    scene.load_script(engine)

    value = engine.script_engine.not_nil!.get_global("test_value")
    value.should eq(42.0)

    File.delete("test_script.lua")
    File.delete("scripted_scene.yaml")
  end
end
