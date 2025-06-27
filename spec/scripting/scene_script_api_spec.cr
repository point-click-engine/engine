require "../spec_helper"
require "luajit"

module PointClickEngine::Scripting
  # Mock engine for testing
  class MockSceneEngine < Core::Engine
    property current_scene : Scenes::Scene?
    property scene_changed_to : String? = nil

    def initialize
      @window_width = 800
      @window_height = 600
      @window_title = "Test"
      @target_fps = 60
      @running = false
      @resolution = RL::Vector2.new(800f32, 600f32)
      @current_scene = nil
    end

    def change_scene(name : String) : Bool
      @scene_changed_to = name
      true
    end
  end

  # Mock scene for testing
  class MockSceneScene < Scenes::Scene
    property background_loaded : String? = nil
    property hotspots : Array(Scenes::Hotspot) = [] of Scenes::Hotspot

    def initialize(name : String)
      super(name, RL::Vector2.new(800f32, 600f32))
    end

    def add_hotspot(hotspot : Scenes::Hotspot)
      @hotspots << hotspot
    end

    def remove_hotspot(name : String) : Bool
      before_size = @hotspots.size
      @hotspots.reject! { |h| h.name == name }
      @hotspots.size < before_size
    end

    def get_hotspot_at(position : RL::Vector2) : Scenes::Hotspot?
      @hotspots.find { |h| h.contains_point?(position) }
    end

    def load_background(path : String) : Bool
      @background_loaded = path
      true
    end
  end

  describe SceneScriptAPI do
    describe "#initialize" do
      it "creates API with lua state and registry" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        api.should_not be_nil
      end
    end

    describe "#register" do
      it "creates scene module and registers functions" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        api.register

        # Verify module exists
        lua.execute!("return type(scene)")
        lua.to_string(-1).should eq("table")
        lua.pop(1)

        # Verify functions exist
        lua.execute!("return type(scene.change)")
        lua.to_string(-1).should eq("function")
        lua.pop(1)

        lua.execute!("return type(scene.get_current)")
        lua.to_string(-1).should eq("function")
        lua.pop(1)

        lua.execute!("return type(scene.add_hotspot)")
        lua.to_string(-1).should eq("function")
        lua.pop(1)
      end
    end

    describe "scene functions" do
      pending "changes scene" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        Core::Engine.instance = engine

        api.register

        lua.execute!("scene.change('level2')")

        engine.scene_changed_to.should eq("level2")
      end

      pending "gets current scene name" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        scene = MockSceneScene.new("test_level")
        engine.current_scene = scene
        Core::Engine.instance = engine

        api.register

        lua.execute!("return scene.get_current()")
        lua.to_string(-1).should eq("test_level")
        lua.pop(1)
      end

      pending "returns empty string when no current scene" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        Core::Engine.instance = engine

        api.register

        lua.execute!("return scene.get_current()")
        lua.to_string(-1).should eq("")
        lua.pop(1)
      end

      pending "adds hotspot to scene" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        scene = MockSceneScene.new("test_level")
        engine.current_scene = scene
        Core::Engine.instance = engine

        api.register

        lua.execute!("return scene.add_hotspot('door', 100, 200, 50, 80)")
        lua.to_boolean(-1).should be_true
        lua.pop(1)

        scene.hotspots.size.should eq(1)
        hotspot = scene.hotspots.first
        hotspot.name.should eq("door")
        hotspot.position.x.should eq(100)
        hotspot.position.y.should eq(200)
        hotspot.size.x.should eq(50)
        hotspot.size.y.should eq(80)
      end

      pending "removes hotspot from scene" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        scene = MockSceneScene.new("test_level")
        hotspot = Scenes::Hotspot.new("door", RL::Vector2.new(100, 200), RL::Vector2.new(50, 80))
        scene.add_hotspot(hotspot)
        engine.current_scene = scene
        Core::Engine.instance = engine

        api.register

        scene.hotspots.size.should eq(1)

        lua.execute!("scene.remove_hotspot('door')")

        scene.hotspots.size.should eq(0)
      end

      pending "sets scene background" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        scene = MockSceneScene.new("test_level")
        engine.current_scene = scene
        Core::Engine.instance = engine

        api.register

        lua.execute!("scene.set_background('backgrounds/forest.png')")

        scene.background_loaded.should eq("backgrounds/forest.png")
      end

      pending "gets hotspot at position" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        scene = MockSceneScene.new("test_level")

        # Add hotspot at 100,100 with size 50x50
        # Since Hotspot uses center position, adjust accordingly
        hotspot = Scenes::Hotspot.new("door", RL::Vector2.new(125, 125), RL::Vector2.new(50, 50))
        scene.add_hotspot(hotspot)

        engine.current_scene = scene
        Core::Engine.instance = engine

        api.register

        # Test point inside hotspot
        lua.execute!("return scene.get_hotspot_at(125, 125)")
        lua.to_string(-1).should eq("door")
        lua.pop(1)

        # Test point outside hotspot
        lua.execute!("return scene.get_hotspot_at(300, 300)")
        lua.is_nil?(-1).should be_true
        lua.pop(1)
      end

      pending "enables/disables hotspot" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        scene = MockSceneScene.new("test_level")
        hotspot = Scenes::Hotspot.new("door", RL::Vector2.new(100, 200), RL::Vector2.new(50, 80))
        scene.add_hotspot(hotspot)
        engine.current_scene = scene
        Core::Engine.instance = engine

        api.register

        # Disable hotspot
        lua.execute!("scene.enable_hotspot('door', false)")
        hotspot.visible.should be_false

        # Enable hotspot
        lua.execute!("scene.enable_hotspot('door', true)")
        hotspot.visible.should be_true
      end

      pending "handles missing scene gracefully" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = SceneScriptAPI.new(lua, registry)

        engine = MockSceneEngine.new
        engine.current_scene = nil
        Core::Engine.instance = engine

        api.register

        # Should return false when no scene
        lua.execute!("return scene.add_hotspot('test', 0, 0, 10, 10)")
        lua.to_boolean(-1).should be_false
        lua.pop(1)

        # Should not crash when removing hotspot
        lua.execute!("scene.remove_hotspot('test')")

        # Should return nil when getting hotspot
        lua.execute!("return scene.get_hotspot_at(0, 0)")
        lua.is_nil?(-1).should be_true
        lua.pop(1)
      end
    end
  end
end
