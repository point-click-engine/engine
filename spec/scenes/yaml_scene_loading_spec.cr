require "../spec_helper"

describe "YAML Scene Loading" do
  describe "loading scenes from config patterns" do
    before_each do
      Dir.mkdir_p("test_scenes")
    end

    after_each do
      if Dir.exists?("test_scenes")
        Dir.each_child("test_scenes") do |child|
          path = "test_scenes/#{child}"
          if File.directory?(path)
            Dir.each_child(path) { |f| File.delete("#{path}/#{f}") rescue nil }
            Dir.delete(path) rescue nil
          else
            File.delete(path) rescue nil
          end
        end
        Dir.delete("test_scenes") rescue nil
      end
    end

    it "loads all scenes matching glob pattern" do
      # Create multiple scene files
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

      File.write("test_scenes/room1.yaml", scene1)
      File.write("test_scenes/room2.yaml", scene2)

      config_yaml = <<-YAML
      game:
        title: "Scene Loading Test"
      
      assets:
        scenes: ["test_scenes/*.yaml"]
      YAML

      File.write("scene_load_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("scene_load_config.yaml")

      RL.init_window(800, 600, "Scene Loading Test")
      engine = config.create_engine

      # Both scenes should be loaded
      engine.scenes.size.should eq(2)
      engine.scenes.has_key?("room1").should be_true
      engine.scenes.has_key?("room2").should be_true

      # Verify scene content
      room1 = engine.scenes["room1"]
      room1.hotspots.size.should eq(1)
      room1.hotspots.first.name.should eq("object1")

      room2 = engine.scenes["room2"]
      room2.hotspots.size.should eq(1)
      room2.hotspots.first.name.should eq("object2")

      # Cleanup
      RL.close_window
      File.delete("scene_load_config.yaml")
    end

    it "loads scenes from multiple patterns" do
      Dir.mkdir_p("test_scenes/main")
      Dir.mkdir_p("test_scenes/bonus")

      main_scene = <<-YAML
      name: main_room
      background_path: main_bg.png
      YAML

      bonus_scene = <<-YAML
      name: bonus_room
      background_path: bonus_bg.png
      YAML

      File.write("test_scenes/main/main.yaml", main_scene)
      File.write("test_scenes/bonus/bonus.yaml", bonus_scene)

      config_yaml = <<-YAML
      game:
        title: "Multi Pattern Test"
      
      assets:
        scenes:
          - "test_scenes/main/*.yaml"
          - "test_scenes/bonus/*.yaml"
      YAML

      File.write("multi_pattern_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("multi_pattern_config.yaml")

      RL.init_window(800, 600, "Multi Pattern Test")
      engine = config.create_engine

      engine.scenes.size.should eq(2)
      engine.scenes.has_key?("main_room").should be_true
      engine.scenes.has_key?("bonus_room").should be_true

      # Cleanup
      RL.close_window
      File.delete("multi_pattern_config.yaml")
      Dir.delete("test_scenes/main")
      Dir.delete("test_scenes/bonus")
    end

    it "handles missing scene files gracefully" do
      config_yaml = <<-YAML
      game:
        title: "Missing Scene Test"
      
      assets:
        scenes: ["nonexistent/*.yaml"]
      YAML

      File.write("missing_scene_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("missing_scene_config.yaml")

      RL.init_window(800, 600, "Missing Scene Test")

      # Should not crash
      engine = config.create_engine
      engine.scenes.size.should eq(0)

      # Cleanup
      RL.close_window
      File.delete("missing_scene_config.yaml")
    end

    it "loads scenes with associated Lua scripts" do
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

      File.write("test_scenes/scripted_room.yaml", scene_yaml)
      File.write("test_scenes/scripted_room.lua", lua_script)

      config_yaml = <<-YAML
      game:
        title: "Script Test"
      
      assets:
        scenes: ["test_scenes/scripted_room.yaml"]
      YAML

      File.write("script_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("script_config.yaml")

      RL.init_window(800, 600, "Script Test")
      engine = config.create_engine

      engine.scenes.has_key?("scripted_room").should be_true
      scene = engine.scenes["scripted_room"]
      scene.script_path.should eq("test_scenes/scripted_room.lua")

      # Cleanup
      RL.close_window
      File.delete("script_config.yaml")
      File.delete("test_scenes/scripted_room.lua")
    end
  end

  describe "scene validation" do
    it "validates required scene properties" do
      invalid_scene = <<-YAML
      # Missing name
      background_path: bg.png
      YAML

      File.write("test_scenes/invalid.yaml", invalid_scene)

      config_yaml = <<-YAML
      game:
        title: "Invalid Scene Test"
      
      assets:
        scenes: ["test_scenes/invalid.yaml"]
      YAML

      File.write("invalid_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("invalid_config.yaml")

      RL.init_window(800, 600, "Invalid Scene Test")

      # Should handle error gracefully
      engine = config.create_engine
      engine.scenes.size.should eq(0) # Failed to load

      # Cleanup
      RL.close_window
      File.delete("invalid_config.yaml")
      File.delete("test_scenes/invalid.yaml")
      Dir.delete("test_scenes")
    end
  end
end
