require "../spec_helper"
require "../../src/core/dependency_container"

module PointClickEngine::Core
  # Mock implementations for testing
  class MockResourceLoader
    include IResourceLoader

    def load_texture(path : String) : Result(Raylib::Texture2D, AssetError)
      Result(Raylib::Texture2D, AssetError).ok(Raylib::Texture2D.new)
    end

    def load_sound(path : String) : Result(RAudio::Sound, AssetError)
      Result(RAudio::Sound, AssetError).ok(RAudio::Sound.new)
    end

    def load_music(path : String) : Result(RAudio::Music, AssetError)
      Result(RAudio::Music, AssetError).ok(RAudio::Music.new)
    end

    def load_font(path : String, size : Int32) : Result(Raylib::Font, AssetError)
      Result(Raylib::Font, AssetError).ok(Raylib::Font.new)
    end

    def unload_texture(path : String) : Result(Nil, AssetError)
      Result(Nil, AssetError).ok(nil)
    end

    def unload_sound(path : String) : Result(Nil, AssetError)
      Result(Nil, AssetError).ok(nil)
    end

    def unload_music(path : String) : Result(Nil, AssetError)
      Result(Nil, AssetError).ok(nil)
    end

    def cleanup_all_resources
    end
  end

  class MockSceneManager
    include ISceneManager

    def add_scene(scene : Scenes::Scene) : Result(Nil, SceneError)
      Result(Nil, SceneError).ok(nil)
    end

    def change_scene(name : String) : Result(Scenes::Scene, SceneError)
      Result(Scenes::Scene, SceneError).ok(Scenes::Scene.new(name, RL::Vector2.new(800f32, 600f32)))
    end

    def get_scene(name : String) : Result(Scenes::Scene, SceneError)
      Result(Scenes::Scene, SceneError).ok(Scenes::Scene.new(name, RL::Vector2.new(800f32, 600f32)))
    end

    def remove_scene(name : String) : Result(Nil, SceneError)
      Result(Nil, SceneError).ok(nil)
    end

    def scene_names : Array(String)
      [] of String
    end

    def preload_scene(name : String) : Result(Scenes::Scene, SceneError)
      Result(Scenes::Scene, SceneError).ok(Scenes::Scene.new(name, RL::Vector2.new(800f32, 600f32)))
    end
  end

  class MockInputManager
    include IInputManager

    def process_input(dt : Float32)
    end

    def add_input_handler(handler : Proc(Float32, Bool), priority : Int32, enabled : Bool = true)
    end

    def remove_input_handler(handler : Proc(Float32, Bool)) : Bool
      true
    end

    def block_input(frames : Int32, source : String = "unknown")
    end

    def unblock_input
    end

    def input_blocked? : Bool
      false
    end

    def mouse_consumed? : Bool
      false
    end

    def keyboard_consumed? : Bool
      false
    end
  end

  class MockRenderManager
    include IRenderManager

    def render(dt : Float32)
    end

    def add_render_layer(name : String, priority : Int32, enabled : Bool = true) : Result(Nil, RenderError)
      Result(Nil, RenderError).ok(nil)
    end

    def set_layer_enabled(layer_name : String, enabled : Bool) : Result(Nil, RenderError)
      Result(Nil, RenderError).ok(nil)
    end

    def show_ui
    end

    def hide_ui
    end

    def ui_visible? : Bool
      true
    end

    def debug_mode? : Bool
      false
    end

    def get_render_stats : {objects_rendered: Int32, objects_culled: Int32, draw_calls: Int32, render_time: Float32, fps: Float32}
      {objects_rendered: 0, objects_culled: 0, draw_calls: 0, render_time: 0.0f32, fps: 60.0f32}
    end
  end

  class MockConfigManager
    include IConfigManager

    def get(key : String, default_value : String? = nil) : String?
      default_value
    end

    def set(key : String, value : String)
    end

    def has_key?(key : String) : Bool
      false
    end

    def save_config : Result(Nil, ConfigError)
      Result(Nil, ConfigError).ok(nil)
    end

    def load_config : Result(Nil, ConfigError)
      Result(Nil, ConfigError).ok(nil)
    end
  end

  class MockPerformanceMonitor
    include IPerformanceMonitor

    def start_timing(category : String)
    end

    def end_timing(category : String)
    end

    def get_metrics : Hash(String, Float32)
      {} of String => Float32
    end

    def reset_metrics
    end

    def enable_monitoring
    end

    def disable_monitoring
    end
  end

  describe DependencyContainer do
    describe "#initialize" do
      it "creates an empty container" do
        container = DependencyContainer.new
        container.should_not be_nil
      end
    end

    describe "resource loader registration" do
      it "registers and resolves a resource loader" do
        container = DependencyContainer.new
        loader = MockResourceLoader.new
        
        container.register_resource_loader(loader)
        resolved = container.resolve_resource_loader
        
        resolved.should eq(loader)
      end

      it "raises error when no resource loader is registered" do
        container = DependencyContainer.new
        
        expect_raises(DependencyError, "No resource loader registered") do
          container.resolve_resource_loader
        end
      end
    end

    describe "scene manager registration" do
      it "registers and resolves a scene manager" do
        container = DependencyContainer.new
        manager = MockSceneManager.new
        
        container.register_scene_manager(manager)
        resolved = container.resolve_scene_manager
        
        resolved.should eq(manager)
      end

      it "raises error when no scene manager is registered" do
        container = DependencyContainer.new
        
        expect_raises(DependencyError, "No scene manager registered") do
          container.resolve_scene_manager
        end
      end
    end

    describe "input manager registration" do
      it "registers and resolves an input manager" do
        container = DependencyContainer.new
        manager = MockInputManager.new
        
        container.register_input_manager(manager)
        resolved = container.resolve_input_manager
        
        resolved.should eq(manager)
      end

      it "raises error when no input manager is registered" do
        container = DependencyContainer.new
        
        expect_raises(DependencyError, "No input manager registered") do
          container.resolve_input_manager
        end
      end
    end

    describe "render manager registration" do
      it "registers and resolves a render manager" do
        container = DependencyContainer.new
        manager = MockRenderManager.new
        
        container.register_render_manager(manager)
        resolved = container.resolve_render_manager
        
        resolved.should eq(manager)
      end

      it "raises error when no render manager is registered" do
        container = DependencyContainer.new
        
        expect_raises(DependencyError, "No render manager registered") do
          container.resolve_render_manager
        end
      end
    end

    describe "config manager registration" do
      it "registers and resolves a config manager" do
        container = DependencyContainer.new
        manager = MockConfigManager.new
        
        container.register_config_manager(manager)
        resolved = container.resolve_config_manager
        
        resolved.should eq(manager)
      end

      it "raises error when no config manager is registered" do
        container = DependencyContainer.new
        
        expect_raises(DependencyError, "No config manager registered") do
          container.resolve_config_manager
        end
      end
    end

    describe "performance monitor registration" do
      it "registers and resolves a performance monitor" do
        container = DependencyContainer.new
        monitor = MockPerformanceMonitor.new
        
        container.register_performance_monitor(monitor)
        resolved = container.resolve_performance_monitor
        
        resolved.should eq(monitor)
      end

      it "raises error when no performance monitor is registered" do
        container = DependencyContainer.new
        
        expect_raises(DependencyError, "No performance monitor registered") do
          container.resolve_performance_monitor
        end
      end
    end

    describe "multiple registrations" do
      it "allows registering multiple different services" do
        container = DependencyContainer.new
        
        resource_loader = MockResourceLoader.new
        scene_manager = MockSceneManager.new
        input_manager = MockInputManager.new
        render_manager = MockRenderManager.new
        config_manager = MockConfigManager.new
        performance_monitor = MockPerformanceMonitor.new
        
        container.register_resource_loader(resource_loader)
        container.register_scene_manager(scene_manager)
        container.register_input_manager(input_manager)
        container.register_render_manager(render_manager)
        container.register_config_manager(config_manager)
        container.register_performance_monitor(performance_monitor)
        
        container.resolve_resource_loader.should eq(resource_loader)
        container.resolve_scene_manager.should eq(scene_manager)
        container.resolve_input_manager.should eq(input_manager)
        container.resolve_render_manager.should eq(render_manager)
        container.resolve_config_manager.should eq(config_manager)
        container.resolve_performance_monitor.should eq(performance_monitor)
      end

      it "overwrites existing registration when registering same type again" do
        container = DependencyContainer.new
        
        loader1 = MockResourceLoader.new
        loader2 = MockResourceLoader.new
        
        container.register_resource_loader(loader1)
        container.register_resource_loader(loader2)
        
        container.resolve_resource_loader.should eq(loader2)
      end
    end
  end
end