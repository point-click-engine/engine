# Ambient sound management for atmospheric audio
# Handles environmental sounds, room ambience, and contextual audio

require "raylib-cr"
require "../core/game_object"

# Only require audio if explicitly enabled
{% if flag?(:with_audio) %}
  require "raylib-cr/audio"
{% end %}

module PointClickEngine
  module Audio
    # Ambient sound configuration
    struct AmbientSoundConfig
      property name : String
      property file_path : String
      property volume : Float32 = 1.0f32
      property loop : Bool = true
      property fade_in_duration : Float32 = 2.0f32
      property fade_out_duration : Float32 = 2.0f32
      property spatial : Bool = false
      property max_distance : Float32 = 500.0f32
      property position : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      
      def initialize(@name : String, @file_path : String)
      end
    end
    
    {% if flag?(:with_audio) %}
      # Individual ambient sound instance (full implementation)
      class AmbientSound
        property config : AmbientSoundConfig
        property sound : RAudio::Sound?
      property playing : Bool = false
      property current_volume : Float32 = 0.0f32
      property target_volume : Float32 = 1.0f32
      property fade_timer : Float32 = 0.0f32
      property fade_duration : Float32 = 0.0f32
      property fading_in : Bool = false
      property fading_out : Bool = false
      
      def initialize(@config : AmbientSoundConfig)
        load_sound
      end
      
      def load_sound
        begin
          @sound = RAudio.load_sound(@config.file_path)
        rescue
          puts "Warning: Could not load ambient sound #{@config.name} from #{@config.file_path}"
          @sound = nil
        end
      end
      
      def play
        return unless sound = @sound
        return if @playing
        
        RAudio.play_sound(sound)
        @playing = true
        @current_volume = 0.0f32
        @target_volume = @config.volume
        start_fade_in
      end
      
      def stop(immediate : Bool = false)
        return unless sound = @sound
        return unless @playing
        
        if immediate
          RAudio.stop_sound(sound)
          @playing = false
          @current_volume = 0.0f32
        else
          start_fade_out
        end
      end
      
      def update(dt : Float32, listener_position : RL::Vector2? = nil)
        return unless sound = @sound
        return unless @playing
        
        # Update fading
        update_fade(dt)
        
        # Update spatial audio if enabled
        if @config.spatial && listener_position
          update_spatial_audio(listener_position)
        end
        
        # Set volume
        RAudio.set_sound_volume(sound, @current_volume)
        
        # Check if sound finished (for non-looping sounds)
        unless @config.loop
          if !RAudio.is_sound_playing(sound)
            @playing = false
          end
        end
      end
      
      def set_volume(volume : Float32, fade_duration : Float32 = 0.0f32)
        @target_volume = volume.clamp(0.0f32, 1.0f32)
        
        if fade_duration > 0.0f32
          @fade_duration = fade_duration
          @fade_timer = 0.0f32
          @fading_in = @target_volume > @current_volume
          @fading_out = @target_volume < @current_volume
        else
          @current_volume = @target_volume
        end
      end
      
      private def start_fade_in
        @fade_duration = @config.fade_in_duration
        @fade_timer = 0.0f32
        @fading_in = true
        @fading_out = false
      end
      
      private def start_fade_out
        @target_volume = 0.0f32
        @fade_duration = @config.fade_out_duration
        @fade_timer = 0.0f32
        @fading_in = false
        @fading_out = true
      end
      
      private def update_fade(dt : Float32)
        return unless @fading_in || @fading_out
        
        @fade_timer += dt
        progress = (@fade_timer / @fade_duration).clamp(0.0f32, 1.0f32)
        
        if @fading_in
          @current_volume = progress * @target_volume
        elsif @fading_out
          start_volume = @current_volume
          @current_volume = start_volume * (1.0f32 - progress)
        end
        
        # Check if fade complete
        if progress >= 1.0f32
          @current_volume = @target_volume
          @fading_in = false
          
          if @fading_out
            @fading_out = false
            if sound = @sound
              RAudio.stop_sound(sound)
              @playing = false
            end
          end
        end
      end
      
      private def update_spatial_audio(listener_position : RL::Vector2)
        # Calculate distance-based volume
        distance = Math.sqrt(
          (listener_position.x - @config.position.x) ** 2 +
          (listener_position.y - @config.position.y) ** 2
        )
        
        # Apply distance attenuation
        if distance <= @config.max_distance
          distance_factor = 1.0f32 - (distance / @config.max_distance)
          spatial_volume = @target_volume * distance_factor
          @current_volume = [@current_volume, spatial_volume].min
        else
          @current_volume = 0.0f32
        end
      end
      
      def cleanup
        if sound = @sound
          RAudio.unload_sound(sound)
          @sound = nil
        end
      end
    end
    
    # Manager for all ambient sounds
    class AmbientSoundManager
      property sounds : Hash(String, AmbientSound) = {} of String => AmbientSound
      property current_room_ambience : String?
      property global_volume : Float32 = 1.0f32
      property listener_position : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      
      def initialize
      end
      
      # Register a new ambient sound
      def register_sound(config : AmbientSoundConfig)
        @sounds[config.name] = AmbientSound.new(config)
      end
      
      # Play an ambient sound
      def play_sound(name : String, volume : Float32? = nil)
        return unless sound = @sounds[name]?
        
        if volume
          sound.config.volume = volume
        end
        
        sound.play
      end
      
      # Stop an ambient sound
      def stop_sound(name : String, immediate : Bool = false)
        return unless sound = @sounds[name]?
        sound.stop(immediate)
      end
      
      # Set room ambience (stops previous and starts new)
      def set_room_ambience(ambience_name : String, fade_duration : Float32 = 2.0f32)
        # Fade out current ambience
        if current = @current_room_ambience
          if current != ambience_name
            stop_sound(current, false)
          else
            return  # Already playing this ambience
          end
        end
        
        # Fade in new ambience
        @current_room_ambience = ambience_name
        play_sound(ambience_name)
      end
      
      # Stop room ambience
      def stop_room_ambience(fade_duration : Float32 = 2.0f32)
        if current = @current_room_ambience
          stop_sound(current, false)
          @current_room_ambience = nil
        end
      end
      
      # Set global volume for all ambient sounds
      def set_global_volume(volume : Float32)
        @global_volume = volume.clamp(0.0f32, 1.0f32)
      end
      
      # Update listener position for spatial audio
      def set_listener_position(position : RL::Vector2)
        @listener_position = position
      end
      
      # Update all ambient sounds
      def update(dt : Float32)
        @sounds.each_value do |sound|
          sound.update(dt, @listener_position)
        end
      end
      
      # Stop all ambient sounds
      def stop_all(immediate : Bool = false)
        @sounds.each_value do |sound|
          sound.stop(immediate)
        end
        @current_room_ambience = nil
      end
      
      # Cleanup resources
      def cleanup
        @sounds.each_value(&.cleanup)
        @sounds.clear
      end
      
      # Get playing sounds
      def get_playing_sounds : Array(String)
        playing = [] of String
        @sounds.each do |name, sound|
          playing << name if sound.playing
        end
        playing
      end
      
      # Check if specific sound is playing
      def is_playing?(name : String) : Bool
        return false unless sound = @sounds[name]?
        sound.playing
      end
    end
    {% else %}
      # Stub ambient sound implementation (no audio)
      class AmbientSound
        property config : AmbientSoundConfig
        property playing : Bool = false
        property current_volume : Float32 = 0.0f32
        property target_volume : Float32 = 1.0f32
        property fade_timer : Float32 = 0.0f32
        property fade_duration : Float32 = 0.0f32
        property fading_in : Bool = false
        property fading_out : Bool = false
        
        def initialize(@config : AmbientSoundConfig)
        end
        
        def load_sound
        end
        
        def play
          @playing = true
        end
        
        def stop(immediate : Bool = false)
          @playing = false
        end
        
        def update(dt : Float32, listener_position : RL::Vector2? = nil)
          return unless @fading_in || @fading_out
          
          @fade_timer += dt
          progress = (@fade_timer / @fade_duration).clamp(0.0f32, 1.0f32)
          
          if @fading_in
            start_volume = @current_volume
            @current_volume = start_volume + (@target_volume - start_volume) * progress
          elsif @fading_out
            start_volume = @current_volume
            @current_volume = start_volume * (1.0f32 - progress)
          end
          
          if progress >= 1.0f32
            @current_volume = @target_volume
            @fading_in = false
            @fading_out = false
            @playing = false if @fading_out && @target_volume == 0.0f32
          end
        end
        
        def set_volume(volume : Float32, fade_duration : Float32 = 0.0f32)
          @target_volume = volume.clamp(0.0f32, 1.0f32)
          @fade_duration = fade_duration
          if fade_duration > 0.0f32
            @fade_timer = 0.0f32
            @fading_in = @target_volume > @current_volume
            @fading_out = @target_volume < @current_volume
          else
            @current_volume = @target_volume
          end
        end
        
        def cleanup
        end
      end
      
      # Stub ambient sound manager (no audio)
      class AmbientSoundManager
        property sounds : Hash(String, AmbientSound) = {} of String => AmbientSound
        property current_room_ambience : String?
        property global_volume : Float32 = 1.0f32
        property listener_position : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
        
        def initialize
        end
        
        def register_sound(config : AmbientSoundConfig)
          @sounds[config.name] = AmbientSound.new(config)
        end
        
        def play_sound(name : String, volume : Float32? = nil)
          return unless sound = @sounds[name]?
          sound.play
        end
        
        def stop_sound(name : String, immediate : Bool = false)
          return unless sound = @sounds[name]?
          sound.stop(immediate)
        end
        
        def set_room_ambience(ambience_name : String, fade_duration : Float32 = 2.0f32)
          if current = @current_room_ambience
            stop_sound(current, false) if current != ambience_name
          end
          @current_room_ambience = ambience_name
          play_sound(ambience_name)
        end
        
        def stop_room_ambience(fade_duration : Float32 = 2.0f32)
          if current = @current_room_ambience
            stop_sound(current, false)
            @current_room_ambience = nil
          end
        end
        
        def set_global_volume(volume : Float32)
          @global_volume = volume.clamp(0.0f32, 1.0f32)
        end
        
        def set_listener_position(position : RL::Vector2)
          @listener_position = position
        end
        
        def update(dt : Float32)
          @sounds.each_value(&.update(dt, @listener_position))
        end
        
        def stop_all(immediate : Bool = false)
          @sounds.each_value(&.stop(immediate))
          @current_room_ambience = nil
        end
        
        def cleanup
          @sounds.clear
        end
        
        def get_playing_sounds : Array(String)
          playing = [] of String
          @sounds.each { |name, sound| playing << name if sound.playing }
          playing
        end
        
        def is_playing?(name : String) : Bool
          return false unless sound = @sounds[name]?
          sound.playing
        end
      end
    {% end %}
  end
end