# Audio-related Lua API component
#
# Provides audio control functions to Lua scripts:
# - Sound effects
# - Music playback
# - Ambient audio
# - Volume control
# - Pause/resume

require "luajit"
require "../core/engine"

module PointClickEngine
  module Scripting
    # Provides audio control functions to Lua scripts
    class AudioScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry)
      end

      # Register all audio-related API functions
      def register
        @registry.create_module("audio")

        @lua.execute! <<-LUA
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

        register_callbacks
      end

      private def register_callbacks
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
    end
  end
end
