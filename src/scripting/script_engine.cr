# Lua scripting engine for runtime game scripting

require "luajit"

module PointClickEngine
  module Scripting
    # Main script engine that manages Lua state and script execution
    class ScriptEngine
      getter lua : Luajit::LuaState

      def initialize
        @lua = Luajit.new_with_defaults
        setup_lua_environment
        register_engine_api
      end

      def execute_script(script_content : String) : Bool
        begin
          @lua.eval(script_content)
          true
        rescue ex
          puts "Script error: #{ex.message}"
          false
        end
      end

      def execute_script_file(file_path : String) : Bool
        begin
          content = File.read(file_path)
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
        @lua.eval <<-LUA
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
      end

      private def register_scene_api
        @lua.eval <<-LUA
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
        @lua.register("_engine_change_scene", Luajit::LuaState::Function.new do |state|
          if state.size >= 1
            scene_name = state.to_string(1)
            Core::Engine.instance.change_scene(scene_name)
          end
          0
        end)

        @lua.register("_engine_get_current_scene", Luajit::LuaState::Function.new do |state|
          scene_name = Core::Engine.instance.current_scene.try(&.name) || ""
          state.push(scene_name)
          1
        end)

        @lua.register("_engine_add_hotspot", Luajit::LuaState::Function.new do |state|
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
        end)
      end

      private def register_character_api
        @lua.eval <<-LUA
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

        @lua.register("_engine_character_say", Luajit::LuaState::Function.new do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            text = state.to_string(2)
            
            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.say(text) {}
              end
            end
          end
          0
        end)

        @lua.register("_engine_character_move_to", Luajit::LuaState::Function.new do |state|
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
        end)

        @lua.register("_engine_character_get_position", Luajit::LuaState::Function.new do |state|
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
                return 1
              end
            end
          end
          0
        end)

        @lua.register("_engine_character_set_animation", Luajit::LuaState::Function.new do |state|
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
        end)
      end

      private def register_inventory_api
        @lua.eval <<-LUA
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

        @lua.register("_engine_inventory_add_item", Luajit::LuaState::Function.new do |state|
          if state.size >= 2
            name = state.to_string(1)
            desc = state.to_string(2)
            
            item = Inventory::InventoryItem.new(name, desc)
            Core::Engine.instance.inventory.add_item(item)
          end
          0
        end)

        @lua.register("_engine_inventory_remove_item", Luajit::LuaState::Function.new do |state|
          if state.size >= 1
            name = state.to_string(1)
            Core::Engine.instance.inventory.remove_item(name)
          end
          0
        end)

        @lua.register("_engine_inventory_has_item", Luajit::LuaState::Function.new do |state|
          if state.size >= 1
            name = state.to_string(1)
            has_item = Core::Engine.instance.inventory.has_item?(name)
            state.push(has_item)
            1
          else
            state.push(false)
            1
          end
        end)

        @lua.register("_engine_inventory_get_selected", Luajit::LuaState::Function.new do |state|
          selected_name = Core::Engine.instance.inventory.selected_item.try(&.name) || ""
          state.push(selected_name)
          1
        end)
      end

      private def register_dialog_api
        @lua.eval <<-LUA
          -- Dialog system API
          dialog = {}
          
          function dialog.show(text, character_name)
            _engine_dialog_show(text, character_name or "")
          end
          
          function dialog.show_choices(question, choices, character_name)
            _engine_dialog_show_choices(question, choices, character_name or "")
          end
        LUA

        @lua.register("_engine_dialog_show", Luajit::LuaState::Function.new do |state|
          if state.size >= 1
            text = state.to_string(1)
            char_name = state.size >= 2 ? state.to_string(2) : ""
            
            # Create and show dialog
            pos = RL::Vector2.new(x: 100, y: 100)
            size = RL::Vector2.new(x: 400, y: 150)
            dialog = UI::Dialog.new(text, pos, size)
            dialog.character_name = char_name unless char_name.empty?
            Core::Engine.instance.show_dialog(dialog)
          end
          0
        end)

        @lua.register("_engine_dialog_show_choices", Luajit::LuaState::Function.new do |state|
          if state.size >= 2
            question = state.to_string(1)
            # choices_table = state.to_table(2) # TODO: Implement table parsing
            char_name = state.size >= 3 ? state.to_string(3) : ""
            
            # TODO: Parse choices table and create dialog with choices
            # This would require more complex Lua table parsing
          end
          0
        end)
      end

      private def register_utility_api
        @lua.eval <<-LUA
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
        LUA

        @lua.register("_engine_save_game", Luajit::LuaState::Function.new do |state|
          if state.size >= 1
            filename = state.to_string(1)
            Core::Engine.instance.save_game(filename)
          end
          0
        end)

        @lua.register("_engine_load_game", Luajit::LuaState::Function.new do |state|
          if state.size >= 1
            filename = state.to_string(1)
            # Note: Loading would require special handling since it replaces the engine state
            puts "Load game requested: #{filename}"
          end
          0
        end)

        @lua.register("_engine_debug_log", Luajit::LuaState::Function.new do |state|
          if state.size >= 1
            message = state.to_string(1)
            puts "[Script Debug] #{message}"
          end
          0
        end)

        @lua.register("_engine_get_time", Luajit::LuaState::Function.new do |state|
          current_time = Time.utc.to_unix_f
          state.push(current_time)
          1
        end)
      end
    end
  end
end