# Sound and Music system for adventure games

# Only require audio if explicitly enabled
{% if flag?(:with_audio) %}
  require "raylib-cr/audio"
{% end %}

module PointClickEngine
  # # Audio system for sound effects, music, and ambient sounds.
  ##
  # # The `Audio` module provides comprehensive audio management for adventure games,
  # # including background music, sound effects, 3D positional audio, and ambient
  # # soundscapes. The module gracefully handles systems without audio support.
  ##
  # # ## Features
  ##
  # # - Sound effects with volume control
  # # - Looping background music with crossfading
  # # - 3D positional audio for spatial effects
  # # - Ambient sound layers
  # # - Audio caching and resource management
  # # - Graceful fallback when audio unavailable
  ##
  # # ## Compilation Flags
  ##
  # # Audio requires the `:with_audio` flag during compilation:
  # # ```bash
  # # crystal build main.cr -D with_audio
  # # ```
  ##
  # # Without this flag, all audio calls become no-ops for compatibility.
  ##
  # # ## Basic Usage
  ##
  # # ```crystal
  # # # Check if audio is available
  # # if Audio.available?
  # #   AudioManager.init
  # # end
  ##
  # # # Play sound effect
  # # AudioManager.play_sound("door_open.wav")
  ##
  # # # Play background music
  # # AudioManager.play_music("theme.ogg", loop: true)
  ##
  # # # 3D positional sound
  # # AudioManager.play_sound_at("footstep.wav", Vector2.new(400, 300))
  # # ```
  ##
  # # ## Sound Effects
  ##
  # # ```crystal
  # # # Load and cache sound effect
  # # effect = SoundEffect.new("explosion", "assets/sounds/explosion.wav")
  # # effect.volume = 0.8
  # # effect.play
  ##
  # # # One-shot playback
  # # AudioManager.play_sound("click.wav", volume: 0.5)
  # # ```
  ##
  # # ## Background Music
  ##
  # # ```crystal
  # # # Play looping music
  # # music = Music.new("main_theme", "assets/music/theme.ogg")
  # # music.volume = 0.6
  # # music.play(loop: true)
  ##
  # # # Crossfade between tracks
  # # AudioManager.crossfade_to("battle_theme.ogg", duration: 2.0)
  # # ```
  ##
  # # ## 3D Positional Audio
  ##
  # # ```crystal
  # # # Sound gets quieter with distance
  # # explosion_pos = Vector2.new(600, 400)
  # # player_pos = Vector2.new(100, 300)
  ##
  # # AudioManager.play_sound_at("explosion.wav", explosion_pos)
  # # # Volume automatically adjusted based on distance from player
  # # ```
  ##
  # # ## Ambient Soundscapes
  ##
  # # ```crystal
  # # # Layer multiple ambient sounds
  # # ambient = AmbientSoundManager.new
  # # ambient.add_layer("wind.ogg", volume: 0.3)
  # # ambient.add_layer("birds.ogg", volume: 0.2)
  # # ambient.add_layer("water.ogg", volume: 0.4)
  ##
  # # # Fade layers in/out based on location
  # # ambient.set_layer_volume("water", 0.0)  # Fade out water sounds
  # # ```
  ##
  # # ## Audio Configuration
  ##
  # # ```crystal
  # # # Global audio settings
  # # AudioManager.master_volume = 0.8
  # # AudioManager.sound_volume = 1.0
  # # AudioManager.music_volume = 0.7
  ##
  # # # Save/load audio preferences
  # # settings = {
  # #   master: AudioManager.master_volume,
  # #   sound: AudioManager.sound_volume,
  # #   music: AudioManager.music_volume
  # # }
  # # ```
  ##
  # # ## Resource Management
  ##
  # # ```crystal
  # # # Preload sounds for performance
  # # AudioManager.preload_sounds([
  # #   "footstep.wav",
  # #   "door_open.wav",
  # #   "item_pickup.wav"
  # # ])
  ##
  # # # Unload unused sounds
  # # AudioManager.unload_sound("explosion.wav")
  ##
  # # # Clear all audio cache
  # # AudioManager.clear_cache
  # # ```
  ##
  # # ## Common Gotchas
  ##
  # # 1. **Audio flag required**: Must compile with `-D with_audio`
  # #    ```crystal
  # #    # Always check availability
  # #    if Audio.available?
  # #      AudioManager.play_sound("beep.wav")
  # #    end
  # #    ```
  ##
  # # 2. **File formats**: Supports WAV, OGG, MP3 (OGG recommended)
  # #    ```crystal
  # #    # OGG for music (smaller files)
  # #    play_music("theme.ogg")
  ##
  # #    # WAV for short effects (lower latency)
  # #    play_sound("click.wav")
  # #    ```
  ##
  # # 3. **Resource limits**: Limited simultaneous sounds
  # #    ```crystal
  # #    # Reuse sound instances when possible
  # #    @footstep_sound ||= AudioManager.get_sound("footstep.wav")
  # #    @footstep_sound.play
  # #    ```
  ##
  # # 4. **Music updates**: Must update music streams each frame
  # #    ```crystal
  # #    def update(dt)
  # #      AudioManager.update_music_stream  # Required!
  # #    end
  # #    ```
  ##
  # # ## Performance Tips
  ##
  # # - Preload frequently used sounds
  # # - Use OGG for music, WAV for effects
  # # - Limit simultaneous sounds to ~32
  # # - Disable 3D audio calculations when not needed
  # # - Stream music, don't load entirely into memory
  ##
  # # ## Platform Notes
  ##
  # # - **Windows**: Requires OpenAL installation
  # # - **macOS**: Audio works out of the box
  # # - **Linux**: May need PulseAudio/ALSA setup
  ##
  # # ## See Also
  ##
  # # - `AudioManager` - High-level audio interface
  # # - `AmbientSoundManager` - Environmental audio
  # # - `FootstepSystem` - Automatic footstep sounds
  # # - `Engine#audio_manager` - Global audio access
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
      # # Represents a loaded sound effect for playback.
      ##
      # # `SoundEffect` manages individual sound files, providing volume control
      # # and playback management. Sounds are loaded into memory for low-latency
      # # playback, making them ideal for UI feedback, impacts, and short effects.
      ##
      # # ## Usage
      ##
      # # ```crystal
      # # # Load a sound effect
      # # door_sound = SoundEffect.new("door", "assets/sounds/door_creak.wav")
      # # door_sound.volume = 0.7
      ##
      # # # Play the sound
      # # door_sound.play
      ##
      # # # Stop if needed (for longer sounds)
      # # door_sound.stop
      # # ```
      ##
      # # ## Volume Control
      ##
      # # ```crystal
      # # # Individual sound volume (0.0 to 1.0)
      # # explosion.volume = 0.8
      ##
      # # # Affected by global sound volume
      # # # Final volume = sound.volume * AudioManager.sound_volume * AudioManager.master_volume
      # # ```
      ##
      # # ## Resource Management
      ##
      # # ```crystal
      # # # Sounds are automatically cleaned up when garbage collected
      # # # For manual cleanup:
      # # sound.finalize  # Unloads from memory
      # # ```
      ##
      # # NOTE: For music or long audio, use `Music` class instead
      ##
      # # PERFORMANCE: Keep sound files under 10 seconds for optimal memory usage
      class SoundEffect
        # # Identifier for this sound effect
        property name : String

        # # Internal Raylib sound resource
        property sound : RAudio::Sound?

        # # Volume level (0.0 = silent, 1.0 = full volume)
        property volume : Float32 = 1.0

        # # Creates a new sound effect from a file.
        ##
        # # - *name* : Identifier for this sound
        # # - *file_path* : Path to WAV, OGG, or MP3 file
        ##
        # # RAISES: `AudioError` if file cannot be loaded
        def initialize(@name : String, file_path : String)
          @sound = RAudio.load_sound(file_path)
        end

        # # Plays the sound effect.
        ##
        # # Multiple overlapping playbacks are supported. Each call
        # # starts a new instance of the sound.
        ##
        # # ```crystal
        # # # Rapid fire sounds
        # # 3.times { gunshot.play }  # Three overlapping gunshots
        # # ```
        def play
          if sound = @sound
            RAudio.set_sound_volume(sound, @volume)
            RAudio.play_sound(sound)
          end
        end

        # # Stops all instances of this sound effect.
        ##
        # # Useful for interrupting longer sound effects.
        def stop
          if sound = @sound
            RAudio.stop_sound(sound)
          end
        end

        # # Releases audio resources.
        ##
        # # Called automatically by garbage collector, but can be
        # # called manually for immediate cleanup.
        def finalize
          if sound = @sound
            RAudio.unload_sound(sound)
          end
        end
      end
    {% else %}
      # # Stub implementation when audio is disabled.
      ##
      # # Provides the same interface as the real SoundEffect class
      # # but all methods are no-ops for compatibility.
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
