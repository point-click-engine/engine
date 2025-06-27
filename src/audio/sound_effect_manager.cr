# Sound effect management component

require "raylib-cr/audio"

module PointClickEngine
  module Audio
    # Manages sound effects loading, caching, and playback
    class SoundEffectManager
      # Cache of loaded sound effects
      getter sound_effects : Hash(String, SoundEffect) = {} of String => SoundEffect

      # Global sound effects volume multiplier
      property sfx_volume : Float32 = 1.0

      # Load a sound effect from file and cache it
      def load_sound(name : String, file_path : String) : SoundEffect
        sound = SoundEffect.new(name, file_path)
        @sound_effects[name] = sound
        sound
      end

      # Play a sound effect by name
      def play_sound(name : String, volume : Float32 = 1.0) : Nil
        if sound = @sound_effects[name]?
          sound.volume = volume * @sfx_volume
          sound.play
        end
      end

      # Play a sound effect at a specific position (3D audio)
      def play_sound_at(name : String, position : RL::Vector2, listener_pos : RL::Vector2, max_distance : Float32 = 500.0) : Nil
        if sound = @sound_effects[name]?
          # Calculate distance-based volume
          distance = Math.sqrt((position.x - listener_pos.x)**2 + (position.y - listener_pos.y)**2)
          volume_factor = 1.0 - (distance / max_distance).clamp(0.0, 1.0)

          sound.volume = (volume_factor * @sfx_volume).to_f32
          sound.play
        end
      end

      # Stop a specific sound effect
      def stop_sound(name : String) : Nil
        @sound_effects[name]?.try(&.stop)
      end

      # Preload multiple sound effects
      def preload_sounds(sound_files : Array(Tuple(String, String))) : Nil
        sound_files.each do |name, path|
          load_sound(name, path) unless @sound_effects.has_key?(name)
        end
      end

      # Unload a specific sound effect
      def unload_sound(name : String) : Nil
        if sound = @sound_effects.delete(name)
          sound.finalize
        end
      end

      # Clear all cached sound effects
      def clear_cache : Nil
        @sound_effects.each_value(&.finalize)
        @sound_effects.clear
      end

      # Get a sound effect by name
      def get_sound(name : String) : SoundEffect?
        @sound_effects[name]?
      end

      # Check if a sound is loaded
      def has_sound?(name : String) : Bool
        @sound_effects.has_key?(name)
      end

      # Update volume for all loaded sounds
      def update_volume(volume : Float32) : Nil
        @sfx_volume = volume.clamp(0.0f32, 1.0f32)
      end

      # Clean up all resources
      def finalize
        clear_cache
      end
    end
  end
end
