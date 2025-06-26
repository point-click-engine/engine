# Volume control and audio settings component

{% if flag?(:with_audio) %}
  require "raylib-cr/audio"
{% end %}

module PointClickEngine
  module Audio
    # Manages global volume settings and audio preferences
    class VolumeController
      # Volume levels (0.0 to 1.0)
      property master_volume : Float32 = 1.0
      property music_volume : Float32 = 0.5
      property sfx_volume : Float32 = 1.0
      property ambient_volume : Float32 = 0.7
      property voice_volume : Float32 = 0.9
      
      # Mute states
      property muted : Bool = false
      property music_muted : Bool = false
      property sfx_muted : Bool = false
      
      # Volume change callbacks
      @on_volume_change = [] of Proc(Symbol, Float32, Nil)

      # Initialize volume controller
      def initialize
        apply_master_volume
      end

      # Set master volume
      def set_master_volume(volume : Float32) : Nil
        @master_volume = volume.clamp(0.0f32, 1.0f32)
        apply_master_volume
        notify_change(:master, @master_volume)
      end

      # Set music volume
      def set_music_volume(volume : Float32) : Nil
        @music_volume = volume.clamp(0.0f32, 1.0f32)
        notify_change(:music, effective_music_volume)
      end

      # Set sound effects volume
      def set_sfx_volume(volume : Float32) : Nil
        @sfx_volume = volume.clamp(0.0f32, 1.0f32)
        notify_change(:sfx, effective_sfx_volume)
      end

      # Set ambient sounds volume
      def set_ambient_volume(volume : Float32) : Nil
        @ambient_volume = volume.clamp(0.0f32, 1.0f32)
        notify_change(:ambient, effective_ambient_volume)
      end

      # Set voice/dialogue volume
      def set_voice_volume(volume : Float32) : Nil
        @voice_volume = volume.clamp(0.0f32, 1.0f32)
        notify_change(:voice, effective_voice_volume)
      end

      # Toggle global mute
      def toggle_mute : Bool
        @muted = !@muted
        apply_master_volume
        notify_change(:mute, @muted ? 0.0f32 : @master_volume)
        @muted
      end

      # Toggle music mute
      def toggle_music_mute : Bool
        @music_muted = !@music_muted
        notify_change(:music, effective_music_volume)
        @music_muted
      end

      # Toggle sound effects mute
      def toggle_sfx_mute : Bool
        @sfx_muted = !@sfx_muted
        notify_change(:sfx, effective_sfx_volume)
        @sfx_muted
      end

      # Get effective volumes (considering mute states)
      def effective_music_volume : Float32
        return 0.0f32 if @muted || @music_muted
        @music_volume * @master_volume
      end

      def effective_sfx_volume : Float32
        return 0.0f32 if @muted || @sfx_muted
        @sfx_volume * @master_volume
      end

      def effective_ambient_volume : Float32
        return 0.0f32 if @muted
        @ambient_volume * @master_volume
      end

      def effective_voice_volume : Float32
        return 0.0f32 if @muted
        @voice_volume * @master_volume
      end

      # Register volume change callback
      def on_volume_change(&block : Symbol, Float32 -> Nil) : Nil
        @on_volume_change << block
      end

      # Save volume settings
      def to_settings : NamedTuple(
        master: Float32,
        music: Float32,
        sfx: Float32,
        ambient: Float32,
        voice: Float32,
        muted: Bool,
        music_muted: Bool,
        sfx_muted: Bool
      )
        {
          master: @master_volume,
          music: @music_volume,
          sfx: @sfx_volume,
          ambient: @ambient_volume,
          voice: @voice_volume,
          muted: @muted,
          music_muted: @music_muted,
          sfx_muted: @sfx_muted
        }
      end

      # Load volume settings
      def from_settings(settings) : Nil
        @master_volume = settings[:master]? || 1.0f32
        @music_volume = settings[:music]? || 0.5f32
        @sfx_volume = settings[:sfx]? || 1.0f32
        @ambient_volume = settings[:ambient]? || 0.7f32
        @voice_volume = settings[:voice]? || 0.9f32
        @muted = settings[:muted]? || false
        @music_muted = settings[:music_muted]? || false
        @sfx_muted = settings[:sfx_muted]? || false
        
        apply_master_volume
      end

      private def apply_master_volume : Nil
        {% if flag?(:with_audio) %}
          volume = @muted ? 0.0f32 : @master_volume
          RAudio.set_master_volume(volume)
        {% end %}
      end

      private def notify_change(type : Symbol, volume : Float32) : Nil
        @on_volume_change.each do |callback|
          callback.call(type, volume)
        end
      end
    end
  end
end