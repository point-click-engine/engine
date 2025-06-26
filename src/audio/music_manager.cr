# Music playback and management component

{% if flag?(:with_audio) %}
  require "raylib-cr/audio"
{% end %}

module PointClickEngine
  module Audio
    # Manages background music loading, playback, and transitions
    class MusicManager
      # Cache of loaded music tracks
      getter music_tracks : Hash(String, Music) = {} of String => Music

      # Currently playing music track
      property current_music : Music?

      # Global music volume multiplier
      property music_volume : Float32 = 0.5

      # Track for crossfading
      @crossfade_target : Music?
      @crossfade_duration : Float32 = 0.0
      @crossfade_elapsed : Float32 = 0.0
      @crossfading : Bool = false

      # Load a music track from file
      def load_music(name : String, file_path : String) : Music
        music = Music.new(name, file_path)
        @music_tracks[name] = music
        music
      end

      # Play a music track
      def play_music(name : String, loop : Bool = true, fade_in : Float32 = 0.0) : Nil
        # Stop current music if playing
        stop_current_music unless @crossfading

        if music = @music_tracks[name]?
          if fade_in > 0.0
            music.volume = 0.0
            @crossfade_target = music
            @crossfade_duration = fade_in
            @crossfade_elapsed = 0.0
            @crossfading = true
          else
            music.volume = @music_volume
          end

          music.play(loop)
          @current_music = music
        end
      end

      # Crossfade to a new music track
      def crossfade_to(name : String, duration : Float32 = 2.0, loop : Bool = true) : Nil
        return unless @music_tracks.has_key?(name)

        # If no current music, just play the new one with fade in
        unless @current_music
          play_music(name, loop, duration)
          return
        end

        # Set up crossfade
        if new_music = @music_tracks[name]?
          @crossfade_target = new_music
          @crossfade_duration = duration
          @crossfade_elapsed = 0.0
          @crossfading = true

          new_music.volume = 0.0
          new_music.play(loop)
        end
      end

      # Stop current music
      def stop_music : Nil
        stop_current_music
        @current_music = nil
      end

      # Pause current music
      def pause_music : Nil
        @current_music.try(&.pause)
      end

      # Resume current music
      def resume_music : Nil
        @current_music.try(&.resume)
      end

      # Update music streams and handle crossfading
      def update(dt : Float32) : Nil
        # Update all playing music streams
        @current_music.try(&.update)
        @crossfade_target.try(&.update) if @crossfading

        # Handle crossfading
        if @crossfading && @crossfade_target
          @crossfade_elapsed += dt
          progress = (@crossfade_elapsed / @crossfade_duration).clamp(0.0, 1.0)

          # Fade out current music
          if current = @current_music
            current.volume = @music_volume * (1.0 - progress)
            update_music_volume(current)
          end

          # Fade in new music
          if target = @crossfade_target
            target.volume = @music_volume * progress
            update_music_volume(target)
          end

          # Crossfade complete
          if progress >= 1.0
            @current_music.try(&.stop)
            @current_music = @crossfade_target
            @crossfade_target = nil
            @crossfading = false
          end
        end
      end

      # Set music volume
      def set_volume(volume : Float32) : Nil
        @music_volume = volume.clamp(0.0f32, 1.0f32)

        # Update current music volume if not crossfading
        if !@crossfading && (music = @current_music)
          music.volume = @music_volume
          update_music_volume(music)
        end
      end

      # Get currently playing track name
      def current_track_name : String?
        @current_music.try(&.name)
      end

      # Check if music is playing
      def playing? : Bool
        @current_music.try(&.playing) || false
      end

      # Preload multiple music tracks
      def preload_tracks(tracks : Array(Tuple(String, String))) : Nil
        tracks.each do |name, path|
          load_music(name, path) unless @music_tracks.has_key?(name)
        end
      end

      # Unload a specific music track
      def unload_music(name : String) : Nil
        if music = @music_tracks.delete(name)
          music.stop if music == @current_music
          music.finalize
        end
      end

      # Clean up all resources
      def finalize
        @music_tracks.each_value do |music|
          music.stop
          music.finalize
        end
        @music_tracks.clear
      end

      private def stop_current_music : Nil
        @current_music.try(&.stop)
      end

      private def update_music_volume(music : Music) : Nil
        {% if flag?(:with_audio) %}
          if actual_music = music.music
            RAudio.set_music_volume(actual_music, music.volume)
          end
        {% end %}
      end
    end
  end
end
