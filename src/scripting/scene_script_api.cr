# Scene-related Lua API component

require "luajit"
require "../core/engine"
require "../scenes/hotspot"

module PointClickEngine
  module Scripting
    # Provides scene management functions to Lua scripts
    class SceneScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry)
      end

      # Register all scene-related API functions
      def register
        # Create scene module
        @registry.create_module("scene")

        # Add Lua functions
        @lua.execute! <<-LUA
          function scene.change(scene_name)
            _engine_change_scene(scene_name)
          end
          
          function scene.get_current()
            return _engine_get_current_scene()
          end
          
          function scene.add_hotspot(name, x, y, width, height)
            return _engine_add_hotspot(name, x, y, width, height)
          end

          function scene.remove_hotspot(name)
            _engine_remove_hotspot(name)
          end

          function scene.set_background(path)
            _engine_set_background(path)
          end

          function scene.get_hotspot_at(x, y)
            return _engine_get_hotspot_at(x, y)
          end

          function scene.enable_hotspot(name, enabled)
            _engine_enable_hotspot(name, enabled)
          end
        LUA

        # Register Crystal callbacks
        register_change_scene
        register_get_current_scene
        register_add_hotspot
        register_remove_hotspot
        register_set_background
        register_get_hotspot_at
        register_enable_hotspot
      end

      private def register_change_scene
        @registry.register_void_function("_engine_change_scene") do |state|
          if state.size >= 1
            scene_name = state.to_string(1)
            Core::Engine.instance.change_scene(scene_name)
          end
        end
      end

      private def register_get_current_scene
        @registry.register_value_function("_engine_get_current_scene", 1) do |state|
          scene_name = Core::Engine.instance.current_scene.try(&.name) || ""
          state.push(scene_name)
        end
      end

      private def register_add_hotspot
        @registry.register_value_function("_engine_add_hotspot", 1) do |state|
          if state.size >= 5
            name = state.to_string(1)
            x = state.to_f32(2)
            y = state.to_f32(3)
            width = state.to_f32(4)
            height = state.to_f32(5)

            hotspot = Scenes::Hotspot.new(
              name, 
              RL::Vector2.new(x: x, y: y), 
              RL::Vector2.new(x: width, y: height)
            )
            
            if scene = Core::Engine.instance.current_scene
              scene.add_hotspot(hotspot)
              state.push(true)
            else
              state.push(false)
            end
          else
            state.push(false)
          end
        end
      end

      private def register_remove_hotspot
        @registry.register_void_function("_engine_remove_hotspot") do |state|
          if state.size >= 1
            name = state.to_string(1)
            if scene = Core::Engine.instance.current_scene
              scene.remove_hotspot(name)
            end
          end
        end
      end

      private def register_set_background
        @registry.register_void_function("_engine_set_background") do |state|
          if state.size >= 1
            path = state.to_string(1)
            if scene = Core::Engine.instance.current_scene
              scene.load_background(path)
            end
          end
        end
      end

      private def register_get_hotspot_at
        @registry.register_value_function("_engine_get_hotspot_at", 1) do |state|
          if state.size >= 2
            x = state.to_f32(1)
            y = state.to_f32(2)
            
            if scene = Core::Engine.instance.current_scene
              if hotspot = scene.get_hotspot_at(RL::Vector2.new(x: x, y: y))
                state.push(hotspot.name)
              else
                state.push(nil)
              end
            else
              state.push(nil)
            end
          else
            state.push(nil)
          end
        end
      end

      private def register_enable_hotspot
        @registry.register_void_function("_engine_enable_hotspot") do |state|
          if state.size >= 2
            name = state.to_string(1)
            enabled = state.to_boolean(2)
            
            if scene = Core::Engine.instance.current_scene
              if hotspot = scene.hotspots.find { |h| h.name == name }
                hotspot.visible = enabled
              end
            end
          end
        end
      end
    end
  end
end