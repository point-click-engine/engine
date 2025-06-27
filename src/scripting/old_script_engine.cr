# Lua scripting engine for runtime game scripting

require "luajit"

module PointClickEngine
  module Scripting
    # Main script engine that manages Lua state and script execution
    class ScriptEngine
      getter lua : Luajit::LuaState
      getter game_state : Hash(String, Luajit::LuaAny) = {} of String => Luajit::LuaAny

      def initialize
        @lua = Luajit.new_with_defaults
        setup_lua_environment
        register_engine_api
      end

      def execute_script(script_content : String) : Bool
        begin
          @lua.execute!(script_content)
          true
        rescue ex
          puts "Script error: #{ex.message}"
          false
        end
      end

      def execute_script_file(file_path : String) : Bool
        begin
          content = AssetLoader.read_script(file_path)
          execute_script(content)
        rescue ex
          puts "Script file error: #{ex.message}"
          false
        end
      end

      def call_function(function_name : String, *args) : Luajit::LuaAny?
        begin
          @lua.get_global(function_name)
          args.each { |arg| @lua.push(arg) }
          @lua.pcall(args.size, 1, 0)
          @lua.to_any?(-1).tap { @lua.pop(1) }
        rescue ex
          puts "Script function error: #{ex.message}"
          nil
        end
      end

      def set_global(name : String, value)
        @lua.push(value)
        @lua.set_global(name)
      end

      def get_global(name : String) : Luajit::LuaAny?
        @lua.get_global(name)
        @lua.to_any?(-1).tap { @lua.pop(1) }
      end

      def cleanup
        Luajit.close(@lua)
      end

      private def setup_lua_environment
        # Set up basic Lua environment
        @lua.execute! <<-LUA
          -- Utility functions for scripts
          function log(message)
            print("[Script] " .. tostring(message))
          end

          function table_contains(table, element)
            for _, value in pairs(table) do
              if value == element then
                return true
              end
            end
            return false
          end

          -- Game event system
          _event_handlers = {}
          
          function register_event_handler(event_type, handler)
            if not _event_handlers[event_type] then
              _event_handlers[event_type] = {}
            end
            table.insert(_event_handlers[event_type], handler)
          end

          function trigger_event(event_type, data)
            if _event_handlers[event_type] then
              for _, handler in ipairs(_event_handlers[event_type]) do
                handler(data)
              end
            end
          end
        LUA
      end

      private def register_engine_api
        # Register Crystal engine functions to be callable from Lua
        register_scene_api
        register_character_api
        register_inventory_api
        register_dialog_api
        register_utility_api
        # Enhanced API features are now integrated into main API
      end

      private def register_scene_api
        @lua.execute! <<-LUA
          -- Scene management API
          scene = {}
          
          function scene.change(scene_name)
            _engine_change_scene(scene_name)
          end
          
          function scene.get_current()
            return _engine_get_current_scene()
          end
          
          function scene.add_hotspot(name, x, y, width, height)
            return _engine_add_hotspot(name, x, y, width, height)
          end
        LUA

        # Register Crystal callbacks
        @lua.register_fn_global("_engine_change_scene") do |state|
          if state.size >= 1
            scene_name = state.to_string(1)
            Core::Engine.instance.change_scene(scene_name)
          end
          0
        end

        @lua.register_fn_global("_engine_get_current_scene") do |state|
          scene_name = Core::Engine.instance.current_scene.try(&.name) || ""
          state.push(scene_name)
          1
        end

        @lua.register_fn_global("_engine_add_hotspot") do |state|
          if state.size >= 5
            name = state.to_string(1)
            x = state.to_f32(2)
            y = state.to_f32(3)
            width = state.to_f32(4)
            height = state.to_f32(5)

            hotspot = Scenes::Hotspot.new(name, RL::Vector2.new(x: x, y: y), RL::Vector2.new(x: width, y: height))
            Core::Engine.instance.current_scene.try(&.add_hotspot(hotspot))
            state.push(name)
            1
          else
            0
          end
        end
      end

      private def register_character_api
        @lua.execute! <<-LUA
          -- Character management API
          character = {}
          
          function character.say(character_name, text)
            _engine_character_say(character_name, text)
          end
          
          function character.move_to(character_name, x, y)
            _engine_character_move_to(character_name, x, y)
          end
          
          function character.get_position(character_name)
            return _engine_character_get_position(character_name)
          end
          
          function character.set_animation(character_name, animation_name)
            _engine_character_set_animation(character_name, animation_name)
          end
        LUA

        @lua.register_fn_global("_engine_character_say") do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            text = state.to_string(2)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.say(text) { }
              end
            end
          end
          0
        end

        @lua.register_fn_global("_engine_character_move_to") do |state|
          if state.size >= 3
            char_name = state.to_string(1)
            x = state.to_f32(2)
            y = state.to_f32(3)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.walk_to(RL::Vector2.new(x: x, y: y))
              end
            end
          end
          0
        end

        @lua.register_fn_global("_engine_character_get_position") do |state|
          if state.size >= 1
            char_name = state.to_string(1)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                pos = char.position
                state.new_table
                state.push("x")
                state.push(pos.x)
                state.set_table(-3)
                state.push("y")
                state.push(pos.y)
                state.set_table(-3)
                next 1
              end
            end
          end
          0
        end

        @lua.register_fn_global("_engine_character_set_animation") do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            anim_name = state.to_string(2)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.play_animation(anim_name)
              end
            end
          end
          0
        end
      end

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
        LUA

        @lua.register_fn_global("_engine_inventory_add_item") do |state|
          if state.size >= 2
            name = state.to_string(1)
            desc = state.to_string(2)

            item = Inventory::InventoryItem.new(name, desc)
            Core::Engine.instance.inventory.add_item(item)
          end
          0
        end

        @lua.register_fn_global("_engine_inventory_remove_item") do |state|
          if state.size >= 1
            name = state.to_string(1)
            Core::Engine.instance.inventory.remove_item(name)
          end
          0
        end

        @lua.register_fn_global("_engine_inventory_has_item") do |state|
          if state.size >= 1
            name = state.to_string(1)
            has_item = Core::Engine.instance.inventory.has_item?(name)
            state.push(has_item)
            1
          else
            state.push(false)
            1
          end
        end

        @lua.register_fn_global("_engine_inventory_get_selected") do |state|
          selected_name = Core::Engine.instance.inventory.selected_item.try(&.name) || ""
          state.push(selected_name)
          1
        end
      end

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
        LUA

        @lua.register_fn_global("_engine_dialog_show") do |state|
          if state.size >= 1
            text = state.to_string(1)
            char_name = state.size >= 2 ? state.to_string(2) : ""

            # Create and show dialog
            pos = RL::Vector2.new(x: 100, y: 100)
            size = RL::Vector2.new(x: 400, y: 150)
            dialog = UI::Dialog.new(text, pos, size)
            dialog.character_name = char_name unless char_name.empty?
            if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
              dialog_manager.show_dialog(char_name.empty? ? "Character" : char_name, text)
            end
          end
          0
        end

        @lua.register_fn_global("_engine_dialog_show_choices") do |state|
          if state.size >= 2
            question = state.to_string(1)
            char_name = state.size >= 3 ? state.to_string(3) : ""

            # Parse choices table
            choices = [] of {text: String, action: String?}

            if state.is_table?(2)
              # Push the table onto the stack
              state.push_value(2)

              # Iterate through table entries
              state.push(nil)
              while state.next(-2)
                # Stack: ... table key value
                if state.is_table?(-1)
                  # Each choice is a table with text and optional action
                  choice_text = ""
                  choice_action = nil

                  # Get "text" field
                  state.get_field(-1, "text")
                  if state.is_string?(-1)
                    choice_text = state.to_string(-1)
                  end
                  state.pop(1)

                  # Get optional "action" field
                  state.get_field(-1, "action")
                  if state.is_string?(-1)
                    choice_action = state.to_string(-1)
                  end
                  state.pop(1)

                  choices << {text: choice_text, action: choice_action}
                elsif state.is_string?(-1)
                  # Simple string choice
                  choices << {text: state.to_string(-1), action: nil}
                end

                state.pop(1) # Remove value, keep key for next iteration
              end
              state.pop(1) # Remove table
            end

            # Create dialog with choices
            if engine = Core::Engine.instance
              if dialog_manager = engine.system_manager.dialog_manager
                # Convert choices to the format expected by dialog manager
                choice_texts = choices.map { |c| c[:text] }

                # Create callback to handle choice selection
                callback = ->(choice_index : Int32) {
                  # Dialog manager uses 1-based indexing
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
          0
        end
      end

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
          
          -- Game state management
          function set_game_state(key, value)
            _engine_set_game_state(key, value)
          end
          
          function get_game_state(key)
            return _engine_get_game_state(key)
          end
        LUA

        @lua.register_fn_global("_engine_save_game") do |state|
          if state.size >= 1
            filename = state.to_string(1)
            Core::Engine.instance.save_game(filename)
          end
          0
        end

        @lua.register_fn_global("_engine_load_game") do |state|
          if state.size >= 1
            filename = state.to_string(1)
            # Note: Loading would require special handling since it replaces the engine state
            puts "Load game requested: #{filename}"
          end
          0
        end

        @lua.register_fn_global("_engine_debug_log") do |state|
          if state.size >= 1
            message = state.to_string(1)
            puts "[Script Debug] #{message}"
          end
          0
        end

        @lua.register_fn_global("_engine_get_time") do |state|
          current_time = Time.utc.to_unix_f
          state.push(current_time)
          1
        end

        @lua.register_fn_global("_engine_set_game_state") do |state|
          if state.size >= 2
            key = state.to_string(1)
            value = state.to_any?(2)
            @game_state[key] = value if value
          end
          0
        end

        @lua.register_fn_global("_engine_get_game_state") do |state|
          if state.size >= 1
            key = state.to_string(1)
            if value = @game_state[key]?
              # Convert LuaAny back to appropriate type for pushing
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
              1
            else
              state.push(nil)
              1
            end
          else
            0
          end
        end
      end
    end
  end
end
