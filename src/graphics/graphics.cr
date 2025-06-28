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

# Layer system
require "./layers/layer"
require "./layers/layer_manager"

# Particle system
require "./particles"

# Transition system
require "./transitions"

# UI rendering
require "./ui"

# Utilities
require "./utils"

# Shader effects
require "./shaders"

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
