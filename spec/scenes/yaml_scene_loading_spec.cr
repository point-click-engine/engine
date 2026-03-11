require "../spec_helper"

private def with_yaml_scene_test_dir(&)
  test_dir = File.tempname("yaml_scene_loading", "")
  Dir.mkdir_p(test_dir)

  begin
    yield test_dir
  ensure
    FileUtils.rm_rf(test_dir) if Dir.exists?(test_dir)
  end
end

describe "YAML Scene Loading" do
  describe "loading scenes from config patterns" do
    it "loads all scenes matching glob pattern" do
      with_yaml_scene_test_dir do |test_dir|
        scenes_dir = File.join(test_dir, "test_scenes")
        Dir.mkdir_p(scenes_dir)

        scene1 = <<-YAML
name: room1
background_path: bg1.png
hotspots:
  - name: object1
    x: 10
    y: 10
    width: 20
    height: 20
    description: "Object 1"
YAML

        scene2 = <<-YAML
name: room2
background_path: bg2.png
hotspots:
  - name: object2
    x: 30
    y: 30
    width: 40
    height: 40
    description: "Object 2"
YAML

        File.write(File.join(scenes_dir, "room1.yaml"), scene1)
        File.write(File.join(scenes_dir, "room2.yaml"), scene2)

        config_yaml = <<-YAML
game:
  title: "Scene Loading Test"

assets:
  scenes: ["test_scenes/*.yaml"]
YAML

        config_path = File.join(test_dir, "scene_load_config.yaml")
        File.write(config_path, config_yaml)
        config = PointClickEngine::Core::GameConfig.from_file(config_path, skip_preflight: true)

        RaylibContext.ensure_window(800, 600, "Scene Loading Test")
        engine = config.create_engine

        engine.scenes.size.should eq(2)
        engine.scenes.has_key?("room1").should be_true
        engine.scenes.has_key?("room2").should be_true

        room1 = engine.scenes["room1"]
        room1.hotspots.size.should eq(1)
        room1.hotspots.first.name.should eq("object1")

        room2 = engine.scenes["room2"]
        room2.hotspots.size.should eq(1)
        room2.hotspots.first.name.should eq("object2")
      end
    end

    it "loads scenes from multiple patterns" do
      with_yaml_scene_test_dir do |test_dir|
        scenes_dir = File.join(test_dir, "test_scenes")
        Dir.mkdir_p(File.join(scenes_dir, "main"))
        Dir.mkdir_p(File.join(scenes_dir, "bonus"))

        main_scene = <<-YAML
name: main
background_path: main_bg.png
YAML

        bonus_scene = <<-YAML
name: bonus
background_path: bonus_bg.png
YAML

        File.write(File.join(scenes_dir, "main", "main.yaml"), main_scene)
        File.write(File.join(scenes_dir, "bonus", "bonus.yaml"), bonus_scene)

        config_yaml = <<-YAML
game:
  title: "Multi Pattern Test"

assets:
  scenes:
    - "test_scenes/main/*.yaml"
    - "test_scenes/bonus/*.yaml"
YAML

        config_path = File.join(test_dir, "multi_pattern_config.yaml")
        File.write(config_path, config_yaml)
        config = PointClickEngine::Core::GameConfig.from_file(config_path, skip_preflight: true)

        RaylibContext.ensure_window(800, 600, "Multi Pattern Test")
        engine = config.create_engine

        engine.scenes.size.should eq(2)
        engine.scenes.has_key?("main").should be_true
        engine.scenes.has_key?("bonus").should be_true
      end
    end

    it "handles missing scene files gracefully" do
      with_yaml_scene_test_dir do |test_dir|
        config_yaml = <<-YAML
game:
  title: "Missing Scene Test"

assets:
  scenes: ["nonexistent/*.yaml"]
YAML

        config_path = File.join(test_dir, "missing_scene_config.yaml")
        File.write(config_path, config_yaml)

        expect_raises(PointClickEngine::Core::ValidationError) do
          PointClickEngine::Core::GameConfig.from_file(config_path)
        end
      end
    end

    it "loads scenes with associated Lua scripts" do
      with_yaml_scene_test_dir do |test_dir|
        scenes_dir = File.join(test_dir, "test_scenes")
        Dir.mkdir_p(scenes_dir)

        scene_yaml = <<-YAML
name: scripted_room
background_path: bg.png
script_path: test_scenes/scripted_room.lua
hotspots:
  - name: button
    x: 50
    y: 50
    width: 30
    height: 30
    description: "A button"
YAML

        lua_script = <<-LUA
-- Test script
function on_enter()
  print("Entered scripted room")
end

hotspot.on_click("button", function()
  set_flag("button_clicked", true)
end)
LUA

        File.write(File.join(scenes_dir, "scripted_room.yaml"), scene_yaml)
        File.write(File.join(scenes_dir, "scripted_room.lua"), lua_script)

        config_yaml = <<-YAML
game:
  title: "Script Test"

assets:
  scenes: ["test_scenes/scripted_room.yaml"]
YAML

        config_path = File.join(test_dir, "script_config.yaml")
        File.write(config_path, config_yaml)
        config = PointClickEngine::Core::GameConfig.from_file(config_path, skip_preflight: true)

        RaylibContext.ensure_window(800, 600, "Script Test")
        engine = config.create_engine

        engine.scenes.has_key?("scripted_room").should be_true
        scene = engine.scenes["scripted_room"]
        scene.script_path.should eq("test_scenes/scripted_room.lua")
      end
    end
  end

  describe "scene validation" do
    it "validates required scene properties" do
      with_yaml_scene_test_dir do |test_dir|
        scenes_dir = File.join(test_dir, "test_scenes")
        Dir.mkdir_p(scenes_dir)

        invalid_scene = <<-YAML
# Missing name
background_path: bg.png
YAML

        File.write(File.join(scenes_dir, "invalid.yaml"), invalid_scene)

        config_yaml = <<-YAML
game:
  title: "Invalid Scene Test"

assets:
  scenes: ["test_scenes/invalid.yaml"]
YAML

        config_path = File.join(test_dir, "invalid_config.yaml")
        File.write(config_path, config_yaml)
        config = PointClickEngine::Core::GameConfig.from_file(config_path, skip_preflight: true)

        RaylibContext.ensure_window(800, 600, "Invalid Scene Test")

        expect_raises(PointClickEngine::Core::SceneError) do
          config.create_engine
        end
      end
    end
  end
end
