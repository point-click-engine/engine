require "../spec_helper"

describe "Scene script loading" do
  describe "Scene#load_script" do
    it "loads script from script_path when base_dir is set" do
      RaylibContext.ensure_window
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")

      # Create a temporary script
      temp_dir = File.tempname("test_game", "")
      Dir.mkdir_p(temp_dir)
      scripts_dir = File.join(temp_dir, "scripts")
      Dir.mkdir_p(scripts_dir)

      script_path = File.join(scripts_dir, "test.lua")
      File.write(script_path, <<-LUA)
        set_game_state("scene_script_loaded", "true")

        function on_enter()
          set_game_state("scene_entered", "true")
        end
      LUA

      begin
        scene.base_dir = temp_dir
        scene.script_path = "scripts/test.lua"

        scene.load_script(engine)

        # Verify script was executed
        if script_engine = engine.script_engine
          script_engine.game_state["scene_script_loaded"].should eq("true")
        else
          fail "Script engine not available"
        end
      ensure
        File.delete(script_path) if File.exists?(script_path)
        Dir.delete(scripts_dir) if Dir.exists?(scripts_dir)
        Dir.delete(temp_dir) if Dir.exists?(temp_dir)
      end
    end

    it "handles missing script_path gracefully" do
      RaylibContext.ensure_window
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.script_path = nil

      # Should not raise
      scene.load_script(engine)
    end

    it "handles missing script file gracefully" do
      RaylibContext.ensure_window
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
      engine.init

      scene = PointClickEngine::Scenes::Scene.new("test_scene")
      scene.base_dir = "/nonexistent"
      scene.script_path = "scripts/missing.lua"

      # Should not raise, just return false
      scene.load_script(engine)
    end
  end

  describe "Scene#base_dir" do
    it "defaults to empty string" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.base_dir.should eq("")
    end

    it "can be set" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.base_dir = "/some/path"
      scene.base_dir.should eq("/some/path")
    end
  end

  describe "SceneLoader sets base_dir" do
    it "sets base_dir when loading from YAML" do
      # Create a temporary scene file
      temp_dir = File.tempname("test_game", "")
      Dir.mkdir_p(temp_dir)
      scenes_dir = File.join(temp_dir, "scenes")
      Dir.mkdir_p(scenes_dir)

      scene_path = File.join(scenes_dir, "test_scene.yaml")
      File.write(scene_path, <<-YAML)
        name: test_scene
        display_name: "Test Scene"
        script_path: scripts/test.lua
        logical_width: 1024
        logical_height: 768
      YAML

      begin
        scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml(scene_path)

        # base_dir should be the parent of the scenes directory (temp_dir)
        scene.base_dir.should eq(temp_dir)
        scene.script_path.should eq("scripts/test.lua")
      ensure
        File.delete(scene_path) if File.exists?(scene_path)
        Dir.delete(scenes_dir) if Dir.exists?(scenes_dir)
        Dir.delete(temp_dir) if Dir.exists?(temp_dir)
      end
    end
  end
end
