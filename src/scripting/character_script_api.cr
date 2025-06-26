# Character-related Lua API component

require "luajit"
require "../core/engine"

module PointClickEngine
  module Scripting
    # Provides character management functions to Lua scripts
    class CharacterScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry)
      end

      # Register all character-related API functions
      def register
        # Create character module
        @registry.create_module("character")

        # Add Lua functions
        @lua.execute! <<-LUA
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

          function character.set_walking_speed(character_name, speed)
            _engine_character_set_walking_speed(character_name, speed)
          end

          function character.face_direction(character_name, direction)
            _engine_character_face_direction(character_name, direction)
          end

          function character.set_visible(character_name, visible)
            _engine_character_set_visible(character_name, visible)
          end

          function character.is_walking(character_name)
            return _engine_character_is_walking(character_name)
          end

          function character.stop_walking(character_name)
            _engine_character_stop_walking(character_name)
          end
        LUA

        # Register Crystal callbacks
        register_say
        register_move_to
        register_get_position
        register_set_animation
        register_set_walking_speed
        register_face_direction
        register_set_visible
        register_is_walking
        register_stop_walking
      end

      private def register_say
        @registry.register_void_function("_engine_character_say") do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            text = state.to_string(2)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.say(text) { }
              end
            end
          end
        end
      end

      private def register_move_to
        @registry.register_void_function("_engine_character_move_to") do |state|
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
        end
      end

      private def register_get_position
        @registry.register_value_function("_engine_character_get_position", 1) do |state|
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

      private def register_set_animation
        @registry.register_void_function("_engine_character_set_animation") do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            anim_name = state.to_string(2)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.play_animation(anim_name)
              end
            end
          end
        end
      end

      private def register_set_walking_speed
        @registry.register_void_function("_engine_character_set_walking_speed") do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            speed = state.to_f32(2)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.walking_speed = speed
              end
            end
          end
        end
      end

      private def register_face_direction
        @registry.register_void_function("_engine_character_face_direction") do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            direction = state.to_string(2)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                # Convert direction string to animation
                case direction.downcase
                when "left"
                  char.play_animation("idle_left")
                when "right"
                  char.play_animation("idle_right")
                when "up"
                  char.play_animation("idle_up")
                when "down"
                  char.play_animation("idle_down")
                else
                  char.play_animation("idle")
                end
              end
            end
          end
        end
      end

      private def register_set_visible
        @registry.register_void_function("_engine_character_set_visible") do |state|
          if state.size >= 2
            char_name = state.to_string(1)
            visible = state.to_boolean(2)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.visible = visible
              end
            end
          end
        end
      end

      private def register_is_walking
        @registry.register_value_function("_engine_character_is_walking", 1) do |state|
          if state.size >= 1
            char_name = state.to_string(1)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                state.push(char.state == Characters::CharacterState::Walking)
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
      end

      private def register_stop_walking
        @registry.register_void_function("_engine_character_stop_walking") do |state|
          if state.size >= 1
            char_name = state.to_string(1)

            if scene = Core::Engine.instance.current_scene
              if char = scene.get_character(char_name)
                char.stop_walking
              end
            end
          end
        end
      end
    end
  end
end