# Sound and Music system for adventure games - Refactored with components

require "raylib-cr/audio"

require "./sound_effect_manager"
require "./music_manager"
require "./volume_controller"
require "./audio_resource_cache"

module PointClickEngine
  module Audio
    # Check if audio is available
    def self.available?
      true
    end

    # Sound effect class for individual sound playback
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
          begin
            if sound.frame_count > 0
              RAudio.unload_sound(sound)
            end
          rescue ex
            # Ignore errors during finalization
          end
        end
      end
    end

    # Background music class for streaming audio
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
          begin
            if music.frame_count > 0
              RAudio.unload_music_stream(music)
            end
          rescue ex
            # Ignore errors during finalization
          end
        end
      end
    end

    # Main audio manager using component-based architecture
    class AudioManager
      # Component managers
      getter sound_effect_manager : SoundEffectManager
      getter music_manager : MusicManager
      getter volume_controller : VolumeController
      getter resource_cache : AudioResourceCache

      # Legacy property mappings for compatibility
      delegate master_volume, to: @volume_controller
      delegate muted, to: @volume_controller
      delegate current_music, to: @music_manager

      # Manual delegation for setters and nested properties
      def master_volume=(value : Float32)
        @volume_controller.master_volume = value
      end

      def music_volume
        @volume_controller.music_volume
      end

      def music_volume=(value : Float32)
        @volume_controller.music_volume = value
      end

      def sfx_volume
        @volume_controller.sfx_volume
      end

      def sfx_volume=(value : Float32)
        @volume_controller.sfx_volume = value
      end

      def muted=(value : Bool)
        @volume_controller.muted = value
      end

      def self.available?
        Audio.available?
      end

      def initialize
        RAudio.init_audio_device

        # Initialize components
        @sound_effect_manager = SoundEffectManager.new
        @music_manager = MusicManager.new
        @volume_controller = VolumeController.new
        @resource_cache = AudioResourceCache.new

        # Wire up volume changes
        setup_volume_callbacks
      end

      # Sound effect methods (delegate to manager)
      def load_sound_effect(name : String, file_path : String)
        sound = @sound_effect_manager.load_sound(name, file_path)

        # Track in resource cache (estimate size - could be improved)
        estimated_size = 1_000_000_u64 # 1MB estimate per sound
        @resource_cache.register_resource(name, estimated_size)

        sound
      end

      def play_sound_effect(name : String)
        return if @volume_controller.muted

        @resource_cache.access_resource(name)
        @sound_effect_manager.play_sound(name, @volume_controller.effective_sfx_volume)
      end

      def play_sound_at(name : String, position : RL::Vector2, listener_pos : RL::Vector2, max_distance : Float32 = 500.0)
        return if @volume_controller.muted

        @resource_cache.access_resource(name)
        @sound_effect_manager.play_sound_at(name, position, listener_pos, max_distance)
      end

      # Music methods (delegate to manager)
      def load_music(name : String, file_path : String)
        music = @music_manager.load_music(name, file_path)

        # Track in resource cache
        estimated_size = 5_000_000_u64 # 5MB estimate per music track
        @resource_cache.register_resource("music_#{name}", estimated_size)

        music
      end

      def play_music(name : String, loop : Bool = true)
        return if @volume_controller.muted || @volume_controller.music_muted

        @resource_cache.access_resource("music_#{name}")
        @music_manager.play_music(name, loop)
      end

      def crossfade_to(name : String, duration : Float32 = 2.0, loop : Bool = true)
        return if @volume_controller.muted || @volume_controller.music_muted

        @resource_cache.access_resource("music_#{name}")
        @music_manager.crossfade_to(name, duration, loop)
      end

      def stop_music
        @music_manager.stop_music
      end

      def pause_music
        @music_manager.pause_music
      end

      def resume_music
        @music_manager.resume_music unless @volume_controller.muted || @volume_controller.music_muted
      end

      # Volume control methods
      def set_master_volume(volume : Float32)
        @volume_controller.set_master_volume(volume)
      end

      def set_music_volume(volume : Float32)
        @volume_controller.set_music_volume(volume)
      end

      def set_sfx_volume(volume : Float32)
        @volume_controller.set_sfx_volume(volume)
      end

      def toggle_mute
        @volume_controller.toggle_mute
      end

      # Batch operations
      def preload_sounds(sounds : Array(Tuple(String, String)))
        @sound_effect_manager.preload_sounds(sounds)

        sounds.each do |name, _|
          @resource_cache.register_resource(name, 1_000_000_u64)
        end
      end

      def preload_music(tracks : Array(Tuple(String, String)))
        @music_manager.preload_tracks(tracks)

        tracks.each do |name, _|
          @resource_cache.register_resource("music_#{name}", 5_000_000_u64)
        end
      end

      # Resource management
      def unload_sound(name : String)
        @sound_effect_manager.unload_sound(name)
        @resource_cache.remove_resource(name)
      end

      def unload_music(name : String)
        @music_manager.unload_music(name)
        @resource_cache.remove_resource("music_#{name}")
      end

      def clear_cache
        @sound_effect_manager.clear_cache
        @music_manager.finalize
        @resource_cache = AudioResourceCache.new
      end

      def get_cache_stats
        @resource_cache.get_stats
      end

      # Update method (must be called each frame)
      def update(dt : Float32 = 0.016f32)
        @music_manager.update(dt)

        # Handle cache eviction if needed
        if @resource_cache.needs_eviction?
          evict_least_used_resources
        end
      end

      # Settings persistence
      def save_settings
        @volume_controller.to_settings
      end

      def load_settings(settings)
        @volume_controller.from_settings(settings)
      end

      def finalize
        begin
          @sound_effect_manager.finalize
          @music_manager.finalize

          RAudio.close_audio_device
        rescue ex
          # Ignore errors during finalization
        end
      end

      private def setup_volume_callbacks
        @volume_controller.on_volume_change do |type, volume|
          case type
          when :music
            @music_manager.set_volume(volume)
          when :sfx
            @sound_effect_manager.update_volume(volume)
          end
        end
      end

      private def evict_least_used_resources
        lru_resources = @resource_cache.get_lru_resources(5)

        lru_resources.each do |resource_name|
          if resource_name.starts_with?("music_")
            music_name = resource_name.lchop("music_")
            @music_manager.unload_music(music_name)
          else
            @sound_effect_manager.unload_sound(resource_name)
          end

          @resource_cache.remove_resource(resource_name)
        end
      end
    end
  end
end
