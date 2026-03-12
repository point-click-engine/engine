# Interface definitions for dependency injection and better testability
#
# Defines protocols and interfaces that allow components to be decoupled
# and easily tested with mock implementations.

require "raylib-cr"
require "raylib-cr/audio"
require "./error_handling"
require "../graphics/graphics"

module PointClickEngine
  # Forward declaration for CameraError
  module Graphics
    module Cameras
      class CameraError < PointClickEngine::Core::LoadingError; end
    end
  end

  module Core
    # Interface for resource loading operations
    module IResourceLoader
      abstract def load_texture(path : String) : Result(Raylib::Texture2D, AssetError)
      abstract def load_sound(path : String) : Result(RAudio::Sound, AssetError)
      abstract def load_music(path : String) : Result(RAudio::Music, AssetError)
      abstract def load_font(path : String, size : Int32) : Result(Raylib::Font, AssetError)
      abstract def unload_texture(path : String) : Result(Nil, AssetError)
      abstract def unload_sound(path : String) : Result(Nil, AssetError)
      abstract def unload_music(path : String) : Result(Nil, AssetError)
      abstract def cleanup_all_resources
    end

    # Interface for scene management operations
    module ISceneManager
      abstract def add_scene(scene : Scenes::Scene) : Result(Nil, SceneError)
      abstract def change_scene(name : String) : Result(Scenes::Scene, SceneError)
      abstract def get_scene(name : String) : Result(Scenes::Scene, SceneError)
      abstract def remove_scene(name : String) : Result(Nil, SceneError)
      abstract def scene_names : Array(String)
      abstract def preload_scene(name : String) : Result(Scenes::Scene, SceneError)
    end

    # Interface for input handling operations
    module IInputManager
      abstract def process_input(dt : Float32)
      abstract def add_input_handler(handler : Proc(Float32, Bool), priority : Int32, enabled : Bool = true)
      abstract def remove_input_handler(handler : Proc(Float32, Bool)) : Bool
      abstract def block_input(frames : Int32, source : String = "unknown")
      abstract def unblock_input
      abstract def input_blocked? : Bool
      abstract def mouse_consumed? : Bool
      abstract def keyboard_consumed? : Bool
    end

    # Interface for rendering operations
    module IRenderManager
      abstract def render(dt : Float32)
      abstract def add_render_layer(name : String, priority : Int32, enabled : Bool = true) : Result(Nil, RenderError)
      abstract def set_layer_enabled(layer_name : String, enabled : Bool) : Result(Nil, RenderError)
      abstract def show_ui
      abstract def hide_ui
      abstract def ui_visible? : Bool
      abstract def debug_mode? : Bool
      abstract def get_render_stats : {objects_rendered: Int32, objects_culled: Int32, draw_calls: Int32, render_time: Float32, fps: Float32}
    end

    # Interface for event system operations
    module IEventSystem
      abstract def publish(event_type : String, data : Hash(String, String))
      abstract def subscribe(event_type : String, handler : Proc(Hash(String, String), Nil))
      abstract def unsubscribe(event_type : String, handler : Proc(Hash(String, String), Nil))
      abstract def process_events
    end

    # Interface for configuration management
    module IConfigManager
      abstract def get(key : String, default_value : String? = nil) : String?
      abstract def set(key : String, value : String)
      abstract def has_key?(key : String) : Bool
      abstract def save_config : Result(Nil, ConfigError)
      abstract def load_config : Result(Nil, ConfigError)
    end

    # Interface for logging operations
    module ILogger
      abstract def debug(message : String)
      abstract def info(message : String)
      abstract def warning(message : String)
      abstract def error(message : String)
      abstract def fatal(message : String)
      abstract def set_log_level(level)
    end

    # Interface for asset validation
    module IAssetValidator
      abstract def validate_texture(path : String) : Result(Nil, ValidationError)
      abstract def validate_sound(path : String) : Result(Nil, ValidationError)
      abstract def validate_music(path : String) : Result(Nil, ValidationError)
      abstract def validate_font(path : String) : Result(Nil, ValidationError)
      abstract def validate_scene(path : String) : Result(Nil, ValidationError)
    end

    # Interface for game state persistence
    module IGameStateManager
      abstract def save_state(slot : String) : Result(Nil, SaveGameError)
      abstract def load_state(slot : String) : Result(Nil, SaveGameError)
      abstract def has_save?(slot : String) : Bool
      abstract def delete_save(slot : String) : Result(Nil, SaveGameError)
      abstract def list_saves : Array(String)
    end

    # Interface for performance monitoring
    module IPerformanceMonitor
      abstract def start_timing(category : String)
      abstract def end_timing(category : String)
      abstract def get_metrics : Hash(String, Float32)
      abstract def reset_metrics
      abstract def enable_monitoring
      abstract def disable_monitoring
    end

    # Interface for memory management
    module IMemoryManager
      abstract def track_allocation(size : Int64, category : String)
      abstract def track_deallocation(size : Int64, category : String)
      abstract def get_memory_usage : {current: Int64, peak: Int64, by_category: Hash(String, Int64)}
      abstract def trigger_cleanup
      abstract def set_memory_limit(limit : Int64)
    end

    # Interface for camera management operations
    module ICameraManager
      abstract def add_camera(name : String, camera : Graphics::Camera) : Core::Result(Nil, Graphics::Cameras::CameraError)
      abstract def switch_camera(name : String, transition_duration : Float32 = 0.0f32) : Core::Result(Nil, Graphics::Cameras::CameraError)
      abstract def get_camera(name : String) : Graphics::Camera?
      abstract def remove_camera(name : String) : Core::Result(Nil, Graphics::Cameras::CameraError)
      abstract def apply_effect(type : Symbol, **params)
      abstract def remove_effect(type : Symbol)
      abstract def remove_all_effects
      abstract def has_effect?(type : Symbol) : Bool
      abstract def update(dt : Float32, mouse_x : Int32, mouse_y : Int32)
      abstract def set_scene_bounds(width : Int32, height : Int32)
      abstract def transform_position(world_pos : RL::Vector2) : RL::Vector2
      abstract def screen_to_world(screen_pos : RL::Vector2) : RL::Vector2
      abstract def is_visible?(world_pos : RL::Vector2, margin : Float32 = 0.0f32) : Bool
      abstract def center_on(x : Float32, y : Float32)
      abstract def get_visible_area : RL::Rectangle
    end
  end
end
