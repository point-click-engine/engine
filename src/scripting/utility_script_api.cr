# Utility-related Lua API component
#
# Provides utility and game management functions to Lua scripts:
# - Game state management (save/load, variables)
# - Timers and delays
# - Action sequences
# - Quest system
# - Player functions
# - Achievement triggers
# - Random numbers and time

require "luajit"
require "../core/engine"
require "./lua_state_manager"

module PointClickEngine
  module Scripting
    # Provides utility and game management functions to Lua scripts
    class UtilityScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry
      @state_manager : LuaStateManager

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry, @state_manager : LuaStateManager)
      end

      # Register all utility-related API functions
      def register
        @registry.create_module("game")

        @lua.execute! <<-LUA
          function game.save(filename)
            _engine_save_game(filename)
          end

          function game.load(filename)
            _engine_load_game(filename)
          end

          function game.debug_log(message)
            _engine_debug_log(message)
          end

          function game.get_time()
            return _engine_get_time()
          end

          function game.wait(seconds)
            _engine_wait(seconds)
          end

          function game.random(min, max)
            return _engine_random(min, max)
          end

          -- Game state management
          function set_game_state(key, value)
            _engine_set_game_state(key, value)
          end

          function get_game_state(key)
            return _engine_get_game_state(key)
          end

          function has_game_state(key)
            return _engine_has_game_state(key)
          end

          function remove_game_state(key)
            _engine_remove_game_state(key)
          end

          -- Quest system functions
          function start_quest(quest_id)
            _engine_start_quest(quest_id)
          end

          function complete_quest(quest_id)
            _engine_complete_quest(quest_id)
          end

          function complete_quest_objective(quest_id, objective_id)
            _engine_complete_quest_objective(quest_id, objective_id)
          end

          function is_quest_active(quest_id)
            return _engine_is_quest_active(quest_id)
          end

          function is_quest_complete(quest_id)
            return _engine_is_quest_complete(quest_id)
          end

          -- Local variable storage (scene-scoped, not persisted)
          _local_variables = {}

          function set_variable(key, value)
            _local_variables[key] = value
          end

          function get_variable(key, default_value)
            local val = _local_variables[key]
            if val == nil then
              return default_value
            end
            return val
          end

          function increase_variable(key, amount)
            local current = get_variable(key, 0)
            set_variable(key, current + (amount or 1))
          end

          -- Timer functions with callback support
          _timer_callbacks = {}

          function add_timer(delay, callback)
            -- Get timer_id from engine first
            local timer_id = _engine_add_timer(delay, "")

            -- Store the callback function with the timer_id
            if timer_id and type(callback) == "function" then
              _timer_callbacks[timer_id] = callback
            end

            return timer_id
          end

          -- Cancel a timer
          function cancel_timer(timer_id)
            if timer_id then
              _timer_callbacks[timer_id] = nil
              _engine_cancel_timer(timer_id)
            end
          end

          -- Achievement functions
          function trigger_achievement(achievement_id)
            _engine_trigger_achievement(achievement_id)
          end

          -- Sequence functions with callback support
          _sequence_callbacks = {}

          function start_sequence(sequence_id, on_complete)
            -- Store callback if provided
            if type(on_complete) == "function" then
              _sequence_callbacks[sequence_id] = on_complete
            end

            return _engine_start_sequence(sequence_id)
          end

          function is_sequence_playing()
            return _engine_is_sequence_playing()
          end

          function skip_sequence()
            _engine_skip_sequence()
          end

          -- Player functions
          function get_player_position()
            return _engine_get_player_position()
          end

          -- Hotspot helpers (delegates to scene module)
          function set_hotspot_visible(hotspot_name, visible)
            scene.enable_hotspot(hotspot_name, visible)
          end

          function set_hotspot_enabled(hotspot_name, enabled)
            scene.enable_hotspot(hotspot_name, enabled)
          end
        LUA

        register_callbacks
      end

      private def register_callbacks
        state_manager = @state_manager # Capture for closures

        @registry.register_void_function("_engine_save_game") do |state|
          if state.size >= 1
            filename = state.to_string(1)
            Core::Engine.instance.save_game(filename)
          end
        end

        @registry.register_void_function("_engine_load_game") do |state|
          if state.size >= 1
            filename = state.to_string(1)
            if engine = Core::Engine.instance
              engine.load_game(filename)
            end
          end
        end

        @registry.register_void_function("_engine_debug_log") do |state|
          if state.size >= 1
            message = state.to_string(1)
            puts "[Script Debug] #{message}"
          end
        end

        @registry.register_value_function("_engine_get_time", 1) do |state|
          current_time = Time.utc.to_unix_f
          state.push(current_time)
        end

        @registry.register_void_function("_engine_wait") do |state|
          if state.size >= 1
            seconds = state.to_f64(1)
            # Note: This would need to be handled differently in a real game loop
            sleep seconds.seconds
          end
        end

        @registry.register_value_function("_engine_random", 1) do |state|
          if state.size >= 2
            min = state.to_f64(1)
            max = state.to_f64(2)
            value = min + (max - min) * rand
            state.push(value)
          else
            state.push(rand)
          end
        end

        # Game state callbacks
        @registry.register_void_function("_engine_set_game_state") do |state|
          if state.size >= 2
            key = state.to_string(1)
            value = state.to_any?(2)
            state_manager.set_state(key, value)
          end
        end

        @registry.register_value_function("_engine_get_game_state", 1) do |state|
          if state.size >= 1
            key = state.to_string(1)
            if value = state_manager.get_state(key)
              push_lua_value(state, value)
            else
              state.push(nil)
            end
          else
            state.push(nil)
          end
        end

        @registry.register_value_function("_engine_has_game_state", 1) do |state|
          if state.size >= 1
            key = state.to_string(1)
            state.push(state_manager.has_state?(key))
          else
            state.push(false)
          end
        end

        @registry.register_void_function("_engine_remove_game_state") do |state|
          if state.size >= 1
            key = state.to_string(1)
            state_manager.remove_state(key)
          end
        end

        # Quest system callbacks
        @registry.register_void_function("_engine_start_quest") do |state|
          if state.size >= 1
            quest_id = state.to_string(1)
            engine = Core::Engine.instance
            if (qm = engine.quest_manager) && (gsm = engine.game_state_manager)
              qm.start_quest(quest_id, gsm)
            end
          end
        end

        @registry.register_void_function("_engine_complete_quest") do |state|
          if state.size >= 1
            quest_id = state.to_string(1)
            engine = Core::Engine.instance
            if (qm = engine.quest_manager) && (gsm = engine.game_state_manager)
              if quest = qm.get_quest(quest_id)
                quest.complete(gsm)
              end
            end
          end
        end

        @registry.register_void_function("_engine_complete_quest_objective") do |state|
          if state.size >= 2
            quest_id = state.to_string(1)
            objective_id = state.to_string(2)
            if qm = Core::Engine.instance.quest_manager
              if quest = qm.get_quest(quest_id)
                quest.objectives.each do |obj|
                  if obj.id == objective_id
                    obj.completed = true
                  end
                end
              end
            end
          end
        end

        @registry.register_value_function("_engine_is_quest_active", 1) do |state|
          if state.size >= 1
            quest_id = state.to_string(1)
            if qm = Core::Engine.instance.quest_manager
              if quest = qm.get_quest(quest_id)
                state.push(quest.active)
              else
                state.push(false)
              end
            else
              state.push(false)
            end
          else
            state.push(false)
          end
        end

        @registry.register_value_function("_engine_is_quest_complete", 1) do |state|
          if state.size >= 1
            quest_id = state.to_string(1)
            if qm = Core::Engine.instance.quest_manager
              if quest = qm.get_quest(quest_id)
                state.push(quest.completed)
              else
                state.push(false)
              end
            else
              state.push(false)
            end
          else
            state.push(false)
          end
        end

        # Timer callback - uses TimerManager with EventBus
        @registry.register_value_function("_engine_add_timer", 1) do |state|
          if state.size >= 1
            delay = state.to_f64(1).to_f32

            # Get callback code if provided as string (arg 2)
            callback_code = state.size >= 2 ? state.to_string(2) : nil
            callback_code = nil if callback_code && callback_code.empty?

            if engine = Core::Engine.instance
              timer_id = engine.timer_manager.add_timer(delay, callback_code)
              state.push(timer_id)
            else
              state.push(nil)
            end
          else
            state.push(nil)
          end
        end

        # Cancel timer callback
        @registry.register_value_function("_engine_cancel_timer", 1) do |state|
          if state.size >= 1
            timer_id = state.to_string(1)

            if engine = Core::Engine.instance
              result = engine.timer_manager.cancel_timer(timer_id)
              state.push(result)
            else
              state.push(false)
            end
          else
            state.push(false)
          end
        end

        # Achievement callback
        @registry.register_void_function("_engine_trigger_achievement") do |state|
          if state.size >= 1
            achievement_id = state.to_string(1)
            if am = Core::Engine.instance.system_manager.achievement_manager
              am.unlock(achievement_id)
            end
          end
        end

        # Sequence callback - uses scene's action runner
        @registry.register_value_function("_engine_start_sequence", 1) do |state|
          if state.size >= 1
            sequence_id = state.to_string(1)

            if engine = Core::Engine.instance
              if runner = engine.scene_manager.get_sequence(sequence_id)
                runner.play
                state.push(true)
                # Publish event
                engine.event_bus.publish(Core::Events::SequenceStartedEvent.new(sequence_id))
              else
                state.push(false)
              end
            else
              state.push(false)
            end
          else
            state.push(false)
          end
        end

        # Check if sequence is playing
        @registry.register_value_function("_engine_is_sequence_playing", 1) do |state|
          if engine = Core::Engine.instance
            if scene = engine.current_scene
              state.push(scene.script_running?)
            else
              state.push(false)
            end
          else
            state.push(false)
          end
        end

        # Skip current sequence
        @registry.register_void_function("_engine_skip_sequence") do |state|
          if engine = Core::Engine.instance
            if scene = engine.current_scene
              if runner = scene.script_runner
                if runner.running
                  sequence_id = runner.name
                  scene.skip_script
                  engine.event_bus.publish(Core::Events::SequenceEndedEvent.new(sequence_id, skipped: true))
                end
              end
            end
          end
        end

        # Player position callback
        @registry.register_value_function("_engine_get_player_position", 1) do |state|
          if scene = Core::Engine.instance.current_scene
            if player = scene.player
              pos = player.position
              state.new_table
              state.push("x")
              state.push(pos.x)
              state.set_table(-3)
              state.push("y")
              state.push(pos.y)
              state.set_table(-3)
            else
              state.push(nil)
            end
          else
            state.push(nil)
          end
        end
      end

      # Helper to push LuaAny values back to Lua
      private def push_lua_value(state : Luajit::LuaState, value : Luajit::LuaAny)
        case value
        when String
          state.push(value.as(String))
        when Float64
          state.push(value.as(Float64))
        when Bool
          state.push(value.as(Bool))
        when Int32
          state.push(value.as(Int32))
        when Int64
          state.push(value.as(Int64))
        when Nil
          state.push(nil)
        else
          state.push(nil)
        end
      end
    end
  end
end
