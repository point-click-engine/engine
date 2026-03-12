# Camera-related Lua API component
#
# Provides camera control functions to Lua scripts:
# - Camera shake effects
# - Zoom in/out
# - Panning
# - Sway effects
# - Reset to default

require "luajit"
require "../core/engine"

module PointClickEngine
  module Scripting
    # Provides camera control functions to Lua scripts
    class CameraScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry)
      end

      # Register all camera-related API functions
      def register
        @registry.create_module("camera")

        @lua.execute! <<-LUA
          function camera.shake(intensity, duration)
            _engine_camera_shake(intensity or 1.0, duration or 1.0)
          end

          function camera.zoom(factor, duration)
            _engine_camera_zoom(factor or 1.0, duration or 1.0)
          end

          function camera.pan(x, y, duration)
            _engine_camera_pan(x, y, duration or 1.0)
          end

          function camera.sway(amplitude, frequency, duration)
            _engine_camera_sway(amplitude or 10.0, frequency or 1.0, duration or 0.0)
          end

          function camera.reset(duration)
            _engine_camera_reset(duration or 1.0)
          end
        LUA

        register_callbacks
      end

      private def register_callbacks
        @registry.register_void_function("_engine_camera_shake") do |state|
          if state.size >= 2
            intensity = state.to_f64(1).to_f32
            duration = state.to_f64(2).to_f32

            if engine = Core::Engine.instance
              engine.effect_manager.add_camera_effect("shake",
                amplitude: intensity,
                frequency: 10.0f32,
                duration: duration)
            end
          end
        end

        @registry.register_void_function("_engine_camera_zoom") do |state|
          if state.size >= 2
            factor = state.to_f64(1).to_f32
            duration = state.to_f64(2).to_f32

            if engine = Core::Engine.instance
              engine.effect_manager.add_camera_effect("zoom",
                target: factor,
                duration: duration)
            end
          end
        end

        @registry.register_void_function("_engine_camera_pan") do |state|
          if state.size >= 3
            x = state.to_f64(1).to_f32
            y = state.to_f64(2).to_f32
            duration = state.to_f64(3).to_f32

            if engine = Core::Engine.instance
              engine.effect_manager.add_camera_effect("pan",
                target: [x, y],
                duration: duration)
            end
          end
        end

        @registry.register_void_function("_engine_camera_sway") do |state|
          if state.size >= 3
            amplitude = state.to_f64(1).to_f32
            frequency = state.to_f64(2).to_f32
            duration = state.to_f64(3).to_f32

            if engine = Core::Engine.instance
              engine.effect_manager.add_camera_effect("sway",
                amplitude_x: amplitude,
                amplitude_y: amplitude * 0.5f32,
                frequency_x: frequency,
                frequency_y: frequency * 0.6f32,
                duration: duration)
            end
          end
        end

        @registry.register_void_function("_engine_camera_reset") do |state|
          duration = state.size >= 1 ? state.to_f64(1).to_f32 : 1.0f32

          if engine = Core::Engine.instance
            # Clear camera effects and reset position
            engine.effect_manager.clear_camera_effects
            engine.camera.reset
          end
        end
      end
    end
  end
end
