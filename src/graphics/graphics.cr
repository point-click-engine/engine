# Main graphics module for the Point & Click Engine
#
# This module provides all graphics and rendering functionality including:
# - Display management and resolution scaling
# - Camera and viewport systems
# - Sprite rendering and animation
# - Special effects for objects and scenes
# - Layer-based rendering
# - UI rendering components
# - Shader effects

require "log"
require "raylib-cr"

# Core graphics components
require "./core/display"
require "./core/renderer"
require "./core/camera"
require "./core/viewport"

# Sprite system
require "./sprites/sprite"
require "./sprites/animated_sprite"

# Effects system
require "./effects/effect"
require "./effects/effect_manager"
require "./effects/object_effects"
require "./effects/scene_effects/base_scene_effect"
require "./effects/scene_effects/ambient_effects"
require "./effects/scene_effects/transition_effect"

# Layer system
require "./layers/layer"
require "./layers/layer_manager"

# Particle system
require "./particles/particle"
require "./particles/emitter"

# UI rendering
require "./ui/nine_patch"
require "./ui/text_renderer"
require "./ui/dialog_renderer"

# Utilities
require "./utils/color"
require "./utils/bitmap_font"
require "./utils/palette"
require "./utils/screenshot"

# Shader effects
require "./shaders/shader_system"
require "./shaders/shader_helpers"
require "./shaders/shader_manager"
require "./shaders/shader_effect"
require "./shaders/post_processor"

module PointClickEngine
  module Graphics
    # Version info
    VERSION = "2.0.0"

    # Re-export commonly used types for convenience
    alias Display = Core::Display
    alias Renderer = Core::Renderer
    alias Camera = Core::Camera
    alias Viewport = Core::Viewport
    alias RenderContext = Core::RenderContext
    alias Layer = Layers::Layer
    alias LayerManager = Layers::LayerManager
    alias Sprite = Sprites::Sprite
    alias AnimatedSprite = Sprites::AnimatedSprite
    alias Effect = Effects::Effect
    alias EffectManager = Effects::EffectManager
    alias ShaderSystem = Shaders::ShaderSystem
    alias ShaderHelpers = Shaders::ShaderHelpers
    alias TransitionEffect = Effects::SceneEffects::TransitionType
    alias TransitionSceneEffect = Effects::SceneEffects::TransitionEffect

    # Graphics module initialization
    def self.init
      Log.info { "Initializing Graphics module v#{VERSION}" }
    end

    # Cleanup graphics resources
    def self.cleanup
      Log.info { "Cleaning up Graphics module" }
    end
  end
end
