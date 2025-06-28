# Lua scripting engine for runtime game scripting - Refactored with components

require "luajit"
require "./lua_environment"
require "./script_api_registry"
require "./scene_script_api"
require "./character_script_api"
require "./game_state_manager"

module PointClickEngine
  module Scripting
    # Main script engine using component-based architecture
    #
    # This refactored ScriptEngine delegates responsibilities to specialized components:
    # - LuaEnvironment: Lua setup and utility functions
    # - ScriptAPIRegistry: Crystal function registration
    # - SceneScriptAPI: Scene-related Lua API
    # - CharacterScriptAPI: Character-related Lua API
    # - GameStateManager: Script-accessible game state
    class ScriptEngine
      getter lua : Luajit::LuaState

      # Component managers
      @environment : LuaEnvironment
      @registry : ScriptAPIRegistry
      @scene_api : SceneScriptAPI
      @character_api : CharacterScriptAPI
      @state_manager : GameStateManager

      # Legacy property for compatibility
      def game_state : Hash(String, Luajit::LuaAny)
        @state_manager.to_hash
      end

      def initialize
        @lua = Luajit.new_with_defaults

        # Initialize components
        @environment = LuaEnvironment.new(@lua)
        @registry = ScriptAPIRegistry.new(@lua)
        @scene_api = SceneScriptAPI.new(@lua, @registry)
        @character_api = CharacterScriptAPI.new(@lua, @registry)
        @state_manager = GameStateManager.new

        # Setup environment and register APIs
        setup_engine
      end

      # Execute a script string
      def execute_script(script_content : String) : Bool
        @environment.execute(script_content)
      end

      # Execute a script file
      def execute_script_file(file_path : String) : Bool
        begin
          content = AssetLoader.read_script(file_path)
          execute_script(content)
        rescue ex
          puts "Script file error: #{ex.message}"
          false
        end
      end

      # Call a Lua function
      def call_function(function_name : String, *args) : Luajit::LuaAny?
        @environment.call_function(function_name, *args)
      end

      # Set a global variable
      def set_global(name : String, value)
        @environment.set_global(name, value)
      end

      # Get a global variable
      def get_global(name : String) : Luajit::LuaAny?
        @environment.get_global(name)
      end

      # Clean up Lua state
      def cleanup
        Luajit.close(@lua)
      end

      private def setup_engine
        # Setup Lua environment
        @environment.setup

        # Register all API modules
        @scene_api.register
        @character_api.register
        register_inventory_api
        register_dialog_api
        register_utility_api
        register_camera_api
      end

      # Inventory API (keeping in main class for now as it's smaller)
      private def register_inventory_api
        @lua.execute! <<-LUA
          -- Inventory management API
          inventory = {}
          
          function inventory.add_item(item_name, description)
            _engine_inventory_add_item(item_name, description)
          end
          
          function inventory.remove_item(item_name)
            _engine_inventory_remove_item(item_name)
          end
          
          function inventory.has_item(item_name)
            return _engine_inventory_has_item(item_name)
          end
          
          function inventory.get_selected()
            return _engine_inventory_get_selected()
          end

          function inventory.select_item(item_name)
            _engine_inventory_select_item(item_name)
          end

          function inventory.clear_selection()
            _engine_inventory_clear_selection()
          end

          function inventory.get_all_items()
            return _engine_inventory_get_all_items()
          end
        LUA

        register_inventory_callbacks
      end

      private def register_inventory_callbacks
        @registry.register_void_function("_engine_inventory_add_item") do |state|
          if state.size >= 2
            name = state.to_string(1)
            desc = state.to_string(2)

            item = Inventory::InventoryItem.new(name, desc)
            Core::Engine.instance.inventory.add_item(item)
          end
        end

        @registry.register_void_function("_engine_inventory_remove_item") do |state|
          if state.size >= 1
            name = state.to_string(1)
            Core::Engine.instance.inventory.remove_item(name)
          end
        end

        @registry.register_value_function("_engine_inventory_has_item", 1) do |state|
          if state.size >= 1
            name = state.to_string(1)
            has_item = Core::Engine.instance.inventory.has_item?(name)
            state.push(has_item)
          else
            state.push(false)
          end
        end

        @registry.register_value_function("_engine_inventory_get_selected", 1) do |state|
          selected_name = Core::Engine.instance.inventory.selected_item.try(&.name) || ""
          state.push(selected_name)
        end

        @registry.register_void_function("_engine_inventory_select_item") do |state|
          if state.size >= 1
            name = state.to_string(1)
            Core::Engine.instance.inventory.select_item(name)
          end
        end

        @registry.register_void_function("_engine_inventory_clear_selection") do |state|
          Core::Engine.instance.inventory.deselect_item
        end

        @registry.register_value_function("_engine_inventory_get_all_items", 1) do |state|
          items = Core::Engine.instance.inventory.items

          state.new_table
          items.each_with_index do |item, i|
            state.push(i + 1) # Lua arrays are 1-indexed

            state.new_table
            state.push("name")
            state.push(item.name)
            state.set_table(-3)

            state.push("description")
            state.push(item.description)
            state.set_table(-3)

            state.set_table(-3)
          end
        end
      end

      # Dialog API (keeping in main class due to complexity)
      private def register_dialog_api
        @lua.execute! <<-LUA
          -- Dialog system API
          dialog = {}
          
          function dialog.show(text, character_name)
            _engine_dialog_show(text, character_name or "")
          end
          
          function dialog.show_choices(question, choices, character_name)
            _engine_dialog_show_choices(question, choices, character_name or "")
          end

          function dialog.hide()
            _engine_dialog_hide()
          end

          function dialog.is_showing()
            return _engine_dialog_is_showing()
          end
          
          -- Start a dialog tree conversation
          function start_dialog(tree_name, starting_node)
            _engine_start_dialog_tree(tree_name, starting_node or "greeting")
          end
        LUA

        register_dialog_callbacks
      end

      private def register_dialog_callbacks
        @registry.register_void_function("_engine_dialog_show") do |state|
          if state.size >= 1
            text = state.to_string(1)
            char_name = state.size >= 2 ? state.to_string(2) : ""

            if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
              dialog_manager.show_dialog(char_name.empty? ? "Character" : char_name, text)
            end
          end
        end

        @registry.register_void_function("_engine_dialog_show_choices") do |state|
          if state.size >= 2
            question = state.to_string(1)
            char_name = state.size >= 3 ? state.to_string(3) : ""

            # Parse choices table
            choices = [] of {text: String, action: String?}

            if state.is_table?(2)
              state.push_value(2)
              state.push(nil)

              while state.next(-2)
                if state.is_table?(-1)
                  choice_text = ""
                  choice_action = nil

                  state.get_field(-1, "text")
                  if state.is_string?(-1)
                    choice_text = state.to_string(-1)
                  end
                  state.pop(1)

                  state.get_field(-1, "action")
                  if state.is_string?(-1)
                    choice_action = state.to_string(-1)
                  end
                  state.pop(1)

                  choices << {text: choice_text, action: choice_action}
                elsif state.is_string?(-1)
                  choices << {text: state.to_string(-1), action: nil}
                end

                state.pop(1)
              end
              state.pop(1)
            end

            if engine = Core::Engine.instance
              if dialog_manager = engine.system_manager.dialog_manager
                choice_texts = choices.map { |c| c[:text] }

                callback = ->(choice_index : Int32) {
                  actual_index = choice_index - 1
                  if actual_index >= 0 && actual_index < choices.size
                    if action = choices[actual_index][:action]
                      engine.system_manager.script_engine.try(&.execute_script(action))
                    end
                  end
                }

                dialog_manager.show_choice(question, choice_texts, callback)
              end
            end
          end
        end

        @registry.register_void_function("_engine_dialog_hide") do |state|
          if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
            dialog_manager.close_current_dialog
          end
        end

        @registry.register_value_function("_engine_dialog_is_showing", 1) do |state|
          if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
            state.push(!!dialog_manager.current_dialog)
          else
            state.push(false)
          end
        end

        @registry.register_void_function("_engine_start_dialog_tree") do |state|
          if state.size >= 1
            tree_name = state.to_string(1)
            starting_node = state.size >= 2 ? state.to_string(2) : "greeting"

            if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
              dialog_manager.start_dialog_tree(tree_name, starting_node)
            end
          end
        end
      end

      # Utility API
      private def register_utility_api
        @lua.execute! <<-LUA
          -- Utility functions API
          game = {}
          
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
        LUA

        register_utility_callbacks
      end

      private def register_utility_callbacks
        @registry.register_void_function("_engine_save_game") do |state|
          if state.size >= 1
            filename = state.to_string(1)
            Core::Engine.instance.save_game(filename)
          end
        end

        @registry.register_void_function("_engine_load_game") do |state|
          if state.size >= 1
            filename = state.to_string(1)
            puts "Load game requested: #{filename}"
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
            @state_manager.set_state(key, value)
          end
        end

        @registry.register_value_function("_engine_get_game_state", 1) do |state|
          if state.size >= 1
            key = state.to_string(1)
            if value = @state_manager.get_state(key)
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
            state.push(@state_manager.has_state?(key))
          else
            state.push(false)
          end
        end

        @registry.register_void_function("_engine_remove_game_state") do |state|
          if state.size >= 1
            key = state.to_string(1)
            @state_manager.remove_state(key)
          end
        end
      end

      # Camera API
      private def register_camera_api
        @lua.execute! <<-LUA
          -- Camera system API
          camera = {}
          
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

        register_camera_callbacks
      end

      private def register_camera_callbacks
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
