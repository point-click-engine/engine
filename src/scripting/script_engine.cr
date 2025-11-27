# Lua scripting engine for runtime game scripting - Refactored with components
#
# Uses EventBus pattern: Crystal publishes events, ScriptEngine subscribes and
# dispatches to Lua handlers registered via the Lua API.

require "luajit"
require "./lua_environment"
require "./script_api_registry"
require "./scene_script_api"
require "./character_script_api"
require "./lua_state_manager"
require "../core/events/event_bus"
require "../core/events/game_events"

module PointClickEngine
  module Scripting
    # Main script engine using component-based architecture
    #
    # This refactored ScriptEngine delegates responsibilities to specialized components:
    # - LuaEnvironment: Lua setup and utility functions
    # - ScriptAPIRegistry: Crystal function registration
    # - SceneScriptAPI: Scene-related Lua API
    # - CharacterScriptAPI: Character-related Lua API
    # - LuaStateManager: Script-accessible Lua state
    #
    # EventBus Integration:
    # Scripts register Lua handlers (e.g., scene.on_enter, hotspot.on_click)
    # ScriptEngine subscribes to EventBus events and calls the Lua handlers
    class ScriptEngine
      getter lua : Luajit::LuaState

      # Component managers
      @environment : LuaEnvironment
      @registry : ScriptAPIRegistry
      @scene_api : SceneScriptAPI
      @character_api : CharacterScriptAPI
      @state_manager : LuaStateManager

      # EventBus subscription IDs for cleanup
      @subscription_ids : Array(UInt64) = [] of UInt64

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
        @state_manager = LuaStateManager.new

        # Setup environment and register APIs
        setup_engine
      end

      # Subscribe to EventBus events - call this after engine is initialized
      def subscribe_to_events(event_bus : Core::Events::EventBus)
        # Scene events
        @subscription_ids << event_bus.subscribe(Core::Events::SceneEnteredEvent) do |event|
          dispatch_scene_event("enter", event.scene_name, event.previous_scene)
        end

        @subscription_ids << event_bus.subscribe(Core::Events::SceneExitedEvent) do |event|
          dispatch_scene_event("exit", event.scene_name)
        end

        # Hotspot events
        @subscription_ids << event_bus.subscribe(Core::Events::HotspotClickedEvent) do |event|
          dispatch_hotspot_event(event.hotspot_name, event.verb)
        end

        # Character interaction events
        @subscription_ids << event_bus.subscribe(Core::Events::CharacterInteractEvent) do |event|
          dispatch_character_event("interact", event.character_name, event.target, event.verb)
        end

        # Item use events (for scene.on_item_use)
        @subscription_ids << event_bus.subscribe(Core::Events::ItemUsedEvent) do |event|
          if target = event.target
            dispatch_scene_event("item_use", event.item_id, target)
          end
        end

        # Timer events - execute Lua callback when timer fires
        @subscription_ids << event_bus.subscribe(Core::Events::TimerFiredEvent) do |event|
          dispatch_timer_event(event.timer_id, event.callback_code)
        end

        # Cutscene events
        @subscription_ids << event_bus.subscribe(Core::Events::CutsceneEndedEvent) do |event|
          dispatch_cutscene_event("ended", event.cutscene_id, event.skipped)
        end

        puts "[ScriptEngine] Subscribed to EventBus events"
      end

      # Unsubscribe from all events
      def unsubscribe_from_events(event_bus : Core::Events::EventBus)
        @subscription_ids.each { |id| event_bus.unsubscribe(id) }
        @subscription_ids.clear
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
        register_hotspot_api
        register_audio_api
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

          -- Global convenience functions for common inventory operations
          function has_item(item_name)
            return inventory.has_item(item_name)
          end

          function add_item(item_name, description)
            inventory.add_item(item_name, description or "")
          end

          function remove_item(item_name)
            inventory.remove_item(item_name)
          end

          -- Aliases used by some scripts
          function add_to_inventory(item_name, description)
            add_item(item_name, description)
          end

          function remove_from_inventory(item_name)
            remove_item(item_name)
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

          -- Global convenience function for showing messages (narrator style)
          function show_message(text)
            dialog.show(text, "")
          end

          -- Standalone dialog choice function
          -- show_dialog_choices(prompt, options, callback)
          -- options can be: array of strings, or array of {text, action} tables
          function show_dialog_choices(prompt, options, callback)
            -- Convert options to the format dialog.show_choices expects
            local formatted_options = {}
            for i, opt in ipairs(options) do
              if type(opt) == "string" then
                formatted_options[i] = {text = opt}
              else
                formatted_options[i] = opt
              end
            end

            -- Store callback for later invocation
            if callback then
              _dialog_choice_callback = callback
              -- Add callback wrapper to each option
              for i, opt in ipairs(formatted_options) do
                if not opt.action then
                  opt.action = string.format("if _dialog_choice_callback then _dialog_choice_callback(%d) end", i)
                end
              end
            end

            dialog.show_choices(prompt, formatted_options, "")
          end

          -- Show input dialog (for text input like safe combinations)
          function show_input_dialog(prompt, callback)
            _engine_show_input_dialog(prompt, callback)
          end

          -- Show floating dialog bubble (speech/thought)
          function show_floating_dialog(character, text, position, duration, dialog_type)
            _engine_show_floating_dialog(character, text, position, duration or 3.0, dialog_type or "speech")
          end

          -- Show character dialog at position
          function show_character_dialog(character, text, position)
            show_floating_dialog(character, text, position, 3.0, "speech")
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

        # Input dialog callback - shows a text input prompt
        @registry.register_void_function("_engine_show_input_dialog") do |state|
          if state.size >= 1
            prompt = state.to_string(1)
            # Note: Input dialog functionality would need DialogManager support
            # For now, log the request
            puts "[Script] Input dialog requested: #{prompt}"

            if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
              # Show as regular dialog for now - full input support would need UI work
              dialog_manager.show_dialog("Input", prompt)
            end
          end
        end

        # Floating dialog callback - shows speech bubbles using FloatingDialogManager
        @registry.register_void_function("_engine_show_floating_dialog") do |state|
          if state.size >= 2
            character = state.to_string(1)
            text = state.to_string(2)

            # Position parsing (optional - can be table or nil)
            pos_x = 0.0f32
            pos_y = 0.0f32
            has_position = false

            if state.size >= 3 && state.is_table?(3)
              state.get_field(3, "x")
              if state.is_number?(-1)
                pos_x = state.to_f32(-1)
                has_position = true
              end
              state.pop(1)
              state.get_field(3, "y")
              if state.is_number?(-1)
                pos_y = state.to_f32(-1)
                has_position = true
              end
              state.pop(1)
            end

            duration = state.size >= 4 ? state.to_f64(4).to_f32 : 3.0f32
            dialog_type = state.size >= 5 ? state.to_string(5) : "speech"

            # Convert dialog type string to DialogStyle enum
            style = case dialog_type.downcase
                    when "bubble", "speech"
                      UI::DialogStyle::Bubble
                    when "thought"
                      UI::DialogStyle::Thought
                    when "shout"
                      UI::DialogStyle::Shout
                    when "whisper"
                      UI::DialogStyle::Whisper
                    when "narrator"
                      UI::DialogStyle::Narrator
                    else
                      UI::DialogStyle::Rectangle
                    end

            if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
              # If no position provided, try to get character position
              position = if has_position
                           RL::Vector2.new(x: pos_x, y: pos_y)
                         elsif scene = Core::Engine.instance.current_scene
                           if char = scene.get_character(character)
                             char.position
                           elsif player = scene.player
                             player.position
                           else
                             RL::Vector2.new(x: 512f32, y: 300f32) # Center fallback
                           end
                         else
                           RL::Vector2.new(x: 512f32, y: 300f32) # Center fallback
                         end

              dialog_manager.show_floating_dialog(character, text, position, duration, style)
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

          -- Cutscene functions with callback support
          _cutscene_callbacks = {}

          function start_cutscene(cutscene_id, on_complete)
            -- Store callback if provided
            if type(on_complete) == "function" then
              _cutscene_callbacks[cutscene_id] = on_complete
            end

            return _engine_start_cutscene(cutscene_id)
          end

          function is_cutscene_playing()
            return _engine_is_cutscene_playing()
          end

          function skip_cutscene()
            _engine_skip_cutscene()
          end

          -- Player functions
          function get_player_position()
            return _engine_get_player_position()
          end

          -- Hotspot helpers
          function set_hotspot_visible(hotspot_name, visible)
            scene.enable_hotspot(hotspot_name, visible)
          end

          function set_hotspot_enabled(hotspot_name, enabled)
            scene.enable_hotspot(hotspot_name, enabled)
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

        # Cutscene callback - uses CutsceneManager
        @registry.register_value_function("_engine_start_cutscene", 1) do |state|
          if state.size >= 1
            cutscene_id = state.to_string(1)

            if engine = Core::Engine.instance
              result = engine.cutscene_manager.play_cutscene(cutscene_id)
              state.push(result)

              # Publish event
              if result
                engine.event_bus.publish(Core::Events::CutsceneStartedEvent.new(cutscene_id))
              end
            else
              state.push(false)
            end
          else
            state.push(false)
          end
        end

        # Check if cutscene is playing
        @registry.register_value_function("_engine_is_cutscene_playing", 1) do |state|
          if engine = Core::Engine.instance
            state.push(engine.cutscene_manager.is_playing?)
          else
            state.push(false)
          end
        end

        # Skip current cutscene
        @registry.register_void_function("_engine_skip_cutscene") do |state|
          if engine = Core::Engine.instance
            if engine.cutscene_manager.is_playing?
              if cutscene = engine.cutscene_manager.current_cutscene
                cutscene_id = cutscene.name
                engine.cutscene_manager.skip_current
                engine.event_bus.publish(Core::Events::CutsceneEndedEvent.new(cutscene_id, skipped: true))
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

      # Hotspot API - allows scripts to register callbacks for hotspot interactions
      # Note: Actual hotspot actions are defined in YAML, this API allows scripts to
      # register additional handlers that are called when hotspots are interacted with
      #
      # EventBus Integration:
      # Scripts call hotspot.on_click() to register handlers
      # Engine publishes HotspotClickedEvent to EventBus
      # ScriptEngine subscribes and calls hotspot._handle_event()
      private def register_hotspot_api
        @lua.execute! <<-LUA
          -- Hotspot interaction API (EventBus pattern)
          hotspot = {}
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

      # Audio API
      private def register_audio_api
        @lua.execute! <<-LUA
          -- Audio system API
          audio = {}

          function audio.play_sound(sound_name, volume)
            _engine_play_sound(sound_name, volume or 1.0)
          end

          function audio.play_music(track_name, loop)
            if loop == nil then loop = true end
            _engine_play_music(track_name, loop)
          end

          function audio.stop_music()
            _engine_stop_music()
          end

          function audio.set_volume(channel, volume)
            _engine_set_volume(channel, volume)
          end

          -- Ambient audio functions
          function audio.play_ambient(ambient_name, volume, loop)
            if loop == nil then loop = true end
            _engine_play_ambient(ambient_name, volume or 1.0, loop)
          end

          function audio.stop_ambient(ambient_name)
            _engine_stop_ambient(ambient_name or "")
          end

          function audio.pause_music()
            _engine_pause_music()
          end

          function audio.resume_music()
            _engine_resume_music()
          end

          -- Global convenience functions
          function play_sound(sound_name, volume)
            audio.play_sound(sound_name, volume)
          end

          function play_music(track_name, loop)
            audio.play_music(track_name, loop)
          end

          function stop_music()
            audio.stop_music()
          end

          function play_ambient(ambient_name, volume, loop)
            audio.play_ambient(ambient_name, volume, loop)
          end

          function stop_ambient(ambient_name)
            audio.stop_ambient(ambient_name)
          end
        LUA

        register_audio_callbacks
      end

      private def register_audio_callbacks
        @registry.register_void_function("_engine_play_sound") do |state|
          if state.size >= 1
            sound_name = state.to_string(1)
            volume = state.size >= 2 ? state.to_f64(2).to_f32 : 1.0f32

            if engine = Core::Engine.instance
              if audio = engine.system_manager.audio_manager
                audio.play_sound_effect(sound_name)
              end
            end
          end
        end

        @registry.register_void_function("_engine_play_music") do |state|
          if state.size >= 1
            track_name = state.to_string(1)
            loop = state.size >= 2 ? state.to_boolean(2) : true

            if engine = Core::Engine.instance
              if audio = engine.system_manager.audio_manager
                audio.play_music(track_name, loop)
              end
            end
          end
        end

        @registry.register_void_function("_engine_stop_music") do |state|
          if engine = Core::Engine.instance
            if audio = engine.system_manager.audio_manager
              audio.stop_music
            end
          end
        end

        @registry.register_void_function("_engine_set_volume") do |state|
          if state.size >= 2
            channel = state.to_string(1)
            volume = state.to_f64(2).to_f32

            if engine = Core::Engine.instance
              if audio = engine.system_manager.audio_manager
                case channel
                when "master"
                  audio.master_volume = volume
                when "music"
                  audio.music_volume = volume
                when "sfx", "sound"
                  audio.sfx_volume = volume
                end
              end
            end
          end
        end

        # Ambient audio callbacks - uses music system for looping ambient sounds
        @registry.register_void_function("_engine_play_ambient") do |state|
          if state.size >= 1
            ambient_name = state.to_string(1)
            volume = state.size >= 2 ? state.to_f64(2).to_f32 : 1.0f32
            should_loop = state.size >= 3 ? state.to_boolean(3) : true

            if engine = Core::Engine.instance
              if audio = engine.system_manager.audio_manager
                # Use music system for ambient (looping audio)
                # First try to play as music (for looping ambient sounds)
                begin
                  audio.play_music(ambient_name, should_loop)
                  audio.set_music_volume(volume)
                rescue
                  # Fallback to sound effect for short ambient sounds
                  audio.play_sound_effect(ambient_name)
                end
              end
            end
          end
        end

        @registry.register_void_function("_engine_stop_ambient") do |state|
          ambient_name = state.size >= 1 ? state.to_string(1) : ""

          if engine = Core::Engine.instance
            if audio = engine.system_manager.audio_manager
              # Stop music (ambient)
              audio.stop_music
            end
          end
        end

        @registry.register_void_function("_engine_pause_music") do |state|
          if engine = Core::Engine.instance
            if audio = engine.system_manager.audio_manager
              audio.pause_music
            end
          end
        end

        @registry.register_void_function("_engine_resume_music") do |state|
          if engine = Core::Engine.instance
            if audio = engine.system_manager.audio_manager
              audio.resume_music
            end
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

      # ================================
      # EventBus Dispatch Methods
      # These call Lua handlers when events arrive from EventBus
      # ================================

      # Dispatch scene events to Lua handlers
      # event_type: "enter", "exit", "item_use"
      private def dispatch_scene_event(event_type : String, scene_name : String, extra : String? = nil)
        puts "[ScriptEngine] Dispatching scene event: #{event_type} (scene: #{scene_name})"

        # Call scene._handle_event(event_type, scene_name, extra)
        lua_code = if extra
                     "return scene._handle_event('#{event_type}', '#{scene_name}', '#{extra}')"
                   else
                     "return scene._handle_event('#{event_type}', '#{scene_name}')"
                   end

        begin
          @lua.execute!(lua_code)
        rescue ex
          puts "[ScriptEngine] Scene event dispatch error: #{ex.message}"
        end
      end

      # Dispatch hotspot events to Lua handlers
      private def dispatch_hotspot_event(hotspot_name : String, verb : String)
        puts "[ScriptEngine] Dispatching hotspot event: #{hotspot_name} (verb: #{verb})"

        # Call hotspot._handle_event(hotspot_name, verb)
        lua_code = "return hotspot._handle_event('#{hotspot_name}', '#{verb}')"

        begin
          @lua.execute!(lua_code)
        rescue ex
          puts "[ScriptEngine] Hotspot event dispatch error: #{ex.message}"
        end
      end

      # Dispatch character events to Lua handlers
      # event_type: "interact"
      private def dispatch_character_event(event_type : String, character_name : String, target : String, verb : String)
        puts "[ScriptEngine] Dispatching character event: #{event_type} (character: #{character_name}, target: #{target})"

        # Call character._handle_event(event_type, character_name, target, verb)
        lua_code = "return character._handle_event('#{event_type}', '#{character_name}', '#{target}', '#{verb}')"

        begin
          @lua.execute!(lua_code)
        rescue ex
          puts "[ScriptEngine] Character event dispatch error: #{ex.message}"
        end
      end

      # Dispatch timer events to execute Lua callback code
      private def dispatch_timer_event(timer_id : String, callback_code : String?)
        puts "[ScriptEngine] Timer fired: #{timer_id}"

        if code = callback_code
          begin
            @lua.execute!(code)
          rescue ex
            puts "[ScriptEngine] Timer callback error: #{ex.message}"
          end
        end

        # Also call any registered Lua handler
        lua_code = "if _timer_callbacks and _timer_callbacks['#{timer_id}'] then _timer_callbacks['#{timer_id}']() end"
        begin
          @lua.execute!(lua_code)
        rescue ex
          # Ignore if no handler registered
        end
      end

      # Dispatch cutscene events to Lua handlers
      private def dispatch_cutscene_event(event_type : String, cutscene_id : String, skipped : Bool)
        puts "[ScriptEngine] Cutscene event: #{event_type} (id: #{cutscene_id}, skipped: #{skipped})"

        lua_code = "if _cutscene_callbacks and _cutscene_callbacks['#{cutscene_id}'] then _cutscene_callbacks['#{cutscene_id}']('#{event_type}', #{skipped}) end"
        begin
          @lua.execute!(lua_code)
        rescue ex
          # Ignore if no handler registered
        end
      end
    end
  end
end
