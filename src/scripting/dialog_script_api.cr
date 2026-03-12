# Dialog-related Lua API component
#
# Provides dialog system functions to Lua scripts:
# - Showing dialogs and messages
# - Dialog choices
# - Input dialogs for text entry
# - Floating dialog bubbles
# - Dialog tree conversations

require "luajit"
require "../core/engine"
require "../ui/floating_dialog"

module PointClickEngine
  module Scripting
    # Provides dialog system functions to Lua scripts
    class DialogScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry)
      end

      # Register all dialog-related API functions
      def register
        @registry.create_module("dialog")

        @lua.execute! <<-LUA
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
          -- prompt: Text to display above input field
          -- callback: Function called with entered text (or empty string if cancelled)
          -- max_length: Optional max characters (default 32)
          function show_input_dialog(prompt, callback, max_length)
            -- Store callback for later invocation
            _input_dialog_callback = callback
            _engine_show_input_dialog(prompt, max_length or 32)
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

        register_callbacks
      end

      private def register_callbacks
        lua_ref = @lua # Capture for closures

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
                      begin
                        lua_ref.execute!(action)
                      rescue ex
                        puts "[Script] Dialog choice action error: #{ex.message}"
                      end
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

        # Input dialog callback - shows a text input prompt with proper input handling
        @registry.register_void_function("_engine_show_input_dialog") do |state|
          if state.size >= 1
            prompt = state.to_string(1)
            max_length = state.size >= 2 ? state.to_i32(2) : 32

            if dialog_manager = Core::Engine.instance.system_manager.dialog_manager
              # Use the proper InputDialog system
              dialog_manager.show_input_dialog(prompt, max_length) do |result|
                # Call the stored Lua callback if any
                # Escape single quotes in result for Lua string
                escaped_result = result.gsub("\\", "\\\\").gsub("'", "\\'")
                begin
                  lua_ref.execute!("if _input_dialog_callback then _input_dialog_callback('#{escaped_result}') end")
                rescue ex
                  puts "[Script] Input dialog callback error: #{ex.message}"
                end
              end
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
    end
  end
end
