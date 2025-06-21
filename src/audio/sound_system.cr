# Sound and Music system for adventure games

require "raylib-cr"

# Only require audio if explicitly enabled
{% if flag?(:with_audio) %}
  require "raylib-cr/audio"
{% end %}

module PointClickEngine
  module Audio
    # Check if audio is available
    def self.available?
      {% if flag?(:with_audio) %}
        true
      {% else %}
        false
      {% end %}
    end

    {% if flag?(:with_audio) %}
      # Sound effect manager (full implementation)
      class SoundEffect
        property name : String
        property sound : RAudio::Sound?
        property volume : Float32 = 1.0

        def initialize(@name : String, file_path : String)
          @sound = RAudio.load_sound(file_path)
        end

        def play
          if sound = @sound
            RAudio.set_sound_volume(sound, @volume)
            RAudio.play_sound(sound)
          end
        end

        def stop
          if sound = @sound
            RAudio.stop_sound(sound)
          end
        end

        def finalize
          if sound = @sound
            RAudio.unload_sound(sound)
          end
        end
      end
    {% else %}
      # Stub sound effect implementation (no audio)
      class SoundEffect
        property name : String
        property volume : Float32 = 1.0

        def initialize(@name : String, file_path : String)
        end

        def play
        end

        def stop
        end

        def finalize
        end
      end
    {% end %}

    {% if flag?(:with_audio) %}
      # Background music manager (full implementation)
      class Music
        property name : String
        property music : RAudio::Music?
        property volume : Float32 = 0.5
        property playing : Bool = false

        def initialize(@name : String, file_path : String)
          @music = RAudio.load_music_stream(file_path)
        end

        def play(loop : Bool = true)
          if music = @music
            RAudio.set_music_volume(music, @volume)
            RAudio.play_music_stream(music)
            @playing = true
          end
        end

        def pause
          if music = @music
            RAudio.pause_music_stream(music)
            @playing = false
          end
        end

        def resume
          if music = @music
            RAudio.resume_music_stream(music)
            @playing = true
          end
        end

        def stop
          if music = @music
            RAudio.stop_music_stream(music)
            @playing = false
          end
        end

        def update
          if @playing && (music = @music)
            RAudio.update_music_stream(music)
          end
        end

        def finalize
          if music = @music
            RAudio.unload_music_stream(music)
          end
        end
      end
    {% else %}
      # Stub music manager (no audio)
      class Music
        property name : String
        property volume : Float32 = 0.5
        property playing : Bool = false

        def initialize(@name : String, file_path : String)
        end

        def play(loop : Bool = true)
          @playing = true
        end

        def pause
          @playing = false
        end

        def resume
          @playing = true
        end

        def stop
          @playing = false
        end

        def update
        end

        def finalize
        end
      end
    {% end %}

    # Audio manager for the entire game
    class AudioManager
      property sound_effects : Hash(String, SoundEffect) = {} of String => SoundEffect
      property music_tracks : Hash(String, Music) = {} of String => Music
      property current_music : Music?
      property master_volume : Float32 = 1.0
      property music_volume : Float32 = 0.5
      property sfx_volume : Float32 = 1.0
      property muted : Bool = false

      def self.available?
        Audio.available?
      end

      def initialize
        {% if flag?(:with_audio) %}
          RAudio.init_audio_device
        {% end %}
      end

      def load_sound_effect(name : String, file_path : String)
        @sound_effects[name] = SoundEffect.new(name, file_path)
      end

      def load_music(name : String, file_path : String)
        @music_tracks[name] = Music.new(name, file_path)
      end

      def play_sound_effect(name : String)
        return if @muted
        if sfx = @sound_effects[name]?
          sfx.volume = @sfx_volume * @master_volume
          sfx.play
        end
      end

      def play_music(name : String, loop : Bool = true)
        return if @muted

        # Stop current music if playing
        @current_music.try(&.stop)

        if music = @music_tracks[name]?
          music.volume = @music_volume * @master_volume
          music.play(loop)
          @current_music = music
        end
      end

      def stop_music
        @current_music.try(&.stop)
        @current_music = nil
      end

      def pause_music
        @current_music.try(&.pause)
      end

      def resume_music
        @current_music.try(&.resume)
      end

      def set_master_volume(volume : Float32)
        @master_volume = volume.clamp(0.0f32, 1.0f32)
        {% if flag?(:with_audio) %}
          RAudio.set_master_volume(@master_volume)
        {% end %}
      end

      def set_music_volume(volume : Float32)
        @music_volume = volume.clamp(0.0f32, 1.0f32)
        @current_music.try do |music|
          music.volume = @music_volume * @master_volume
          {% if flag?(:with_audio) %}
            if actual_music = music.music
              RAudio.set_music_volume(actual_music, music.volume)
            end
          {% end %}
        end
      end

      def set_sfx_volume(volume : Float32)
        @sfx_volume = volume.clamp(0.0f32, 1.0f32)
      end

      def toggle_mute
        @muted = !@muted
        {% if flag?(:with_audio) %}
          if @muted
            RAudio.set_master_volume(0.0)
          else
            RAudio.set_master_volume(@master_volume)
          end
        {% end %}
      end

      def update
        @current_music.try(&.update)
      end

      def finalize
        @sound_effects.each_value(&.finalize)
        @music_tracks.each_value(&.finalize)
        {% if flag?(:with_audio) %}
          RAudio.close_audio_device
        {% end %}
      end
    end
  end
end
