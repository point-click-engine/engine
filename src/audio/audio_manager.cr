# Audio manager for adventure games - Refactored with components

require "raylib-cr/audio"

require "./sound_effect_manager"
require "./music_manager"
require "./volume_controller"
require "./audio_resource_cache"
require "../core/events/events"

module PointClickEngine
  module Audio
    # Check if audio is available
    # Always returns true since raylib audio is always available
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

      # Explicit cleanup - do NOT use finalizer as it causes GC deadlocks with Raylib
      def cleanup
        if sound = @sound
          if sound.frame_count > 0
            RAudio.unload_sound(sound)
          end
          @sound = nil
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

      # Explicit cleanup - do NOT use finalizer as it causes GC deadlocks with Raylib
      def cleanup
        if music = @music
          if music.frame_count > 0
            RAudio.unload_music_stream(music)
          end
          @music = nil
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

      # Optional EventBus for publishing audio events
      property event_bus : Core::Events::EventBus?

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

        # Publish event
        if bus = @event_bus
          bus.publish(Core::Events::SoundPlayedEvent.new(name, @volume_controller.effective_sfx_volume))
        end
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

        # Publish event
        if bus = @event_bus
          bus.publish(Core::Events::MusicStartedEvent.new(name, loop))
        end
      end

      def crossfade_to(name : String, duration : Float32 = 2.0, loop : Bool = true)
        return if @volume_controller.muted || @volume_controller.music_muted

        @resource_cache.access_resource("music_#{name}")
        @music_manager.crossfade_to(name, duration, loop)
      end

      def stop_music
        # Get current music name before stopping
        current_name = @music_manager.current_music.try(&.name)
        @music_manager.stop_music

        # Publish event
        if current_name && (bus = @event_bus)
          bus.publish(Core::Events::MusicStoppedEvent.new(current_name))
        end
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
        # Update internal components
        @music_manager.set_volume(@volume_controller.effective_music_volume)
        @sound_effect_manager.update_volume(@volume_controller.effective_sfx_volume)
      end

      def set_music_volume(volume : Float32)
        @volume_controller.set_music_volume(volume)
        @music_manager.set_volume(@volume_controller.effective_music_volume)
      end

      def set_sfx_volume(volume : Float32)
        @volume_controller.set_sfx_volume(volume)
        @sound_effect_manager.update_volume(@volume_controller.effective_sfx_volume)
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
        @music_manager.cleanup
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

      # Explicit cleanup - do NOT use finalizer as it causes GC deadlocks with Raylib
      def cleanup
        @sound_effect_manager.cleanup
        @music_manager.cleanup
        RAudio.close_audio_device
      end

      private def setup_volume_callbacks
        # Volume controller now uses EventBus for notifications
        # We subscribe to volume changes via our own event_bus if set
        # For internal component updates, we handle this in update() or when volumes are set
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
