# Hotspot-related Lua API component
#
# Provides hotspot interaction functions to Lua scripts.
# Note: Actual hotspot actions are defined in YAML. This API allows scripts to
# register additional handlers that are called when hotspots are interacted with.
#
# EventBus Integration:
# Scripts call hotspot.on_click() to register handlers
# Engine publishes HotspotClickedEvent to EventBus
# ScriptEngine subscribes and calls hotspot._handle_event()

require "luajit"
require "../core/engine"

module PointClickEngine
  module Scripting
    # Provides hotspot interaction functions to Lua scripts
    class HotspotScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry)
      end

      # Register all hotspot-related API functions
      def register
        @registry.create_module("hotspot")

        @lua.execute! <<-LUA
          hotspot._callbacks = {}

          -- Register a callback for when a hotspot is clicked
          -- The callback receives the verb used to interact
          function hotspot.on_click(hotspot_name, callback)
            if type(callback) == "function" then
              hotspot._callbacks[hotspot_name] = callback
            end
          end

          -- Internal: called by ScriptEngine when HotspotClickedEvent arrives from EventBus
          function hotspot._handle_event(hotspot_name, verb)
            local callback = hotspot._callbacks[hotspot_name]
            if callback then
              callback(verb)
              return true
            end
            return false
          end
        LUA

        # No Crystal callbacks needed - hotspot events come through EventBus
        # and are dispatched by ScriptEngine to the Lua handlers registered above
      end
    end
  end
end
