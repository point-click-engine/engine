# Enhanced cutscene actions for cinematic sequences
# Provides advanced camera movements, particle effects, and synchronized actions

require "./cutscene_action"
require "./cutscene_camera"
require "../graphics/particles"

module PointClickEngine
  module Cutscenes
    # Camera pan action using enhanced camera system
    class CameraPanAction < CutsceneAction
      def initialize(@camera : CutsceneCamera, @target_position : RL::Vector2, 
                     duration : Float32, @transition : CameraTransition = CameraTransition::EaseInOut)
        super(duration)
      end
      
      def start
        @camera.pan_to(@target_position, @duration, @transition)
      end
      
      def update_action(progress : Float32)
        # Camera handles its own animation
        @completed = !@camera.pan_active
      end
      
      def finish
        # Camera animation should be complete
      end
    end
    
    # Camera zoom action
    class CameraZoomAction < CutsceneAction
      def initialize(@camera : CutsceneCamera, @target_zoom : Float32, 
                     duration : Float32, @transition : CameraTransition = CameraTransition::EaseInOut)
        super(duration)
      end
      
      def start
        @camera.zoom_to(@target_zoom, @duration, @transition)
      end
      
      def update_action(progress : Float32)
        @completed = !@camera.zoom_active
      end
      
      def finish
      end
    end
    
    # Camera shake action for impact effects
    class CameraShakeAction < CutsceneAction
      def initialize(@camera : CutsceneCamera, @intensity : Float32, 
                     duration : Float32, @frequency : Float32 = 10.0f32)
        super(duration)
      end
      
      def start
        @camera.shake(@intensity, @duration, @frequency)
      end
      
      def update_action(progress : Float32)
        @completed = !@camera.shake_active
      end
      
      def finish
      end
    end
    
    # Camera follow character action
    class CameraFollowAction < CutsceneAction
      def initialize(@camera : CutsceneCamera, @character : Characters::Character, 
                     @smooth : Bool = true, @deadzone : Float32 = 50.0f32)
        super(0.0f32)  # Instant action
      end
      
      def start
        @camera.follow(@character, @smooth, @deadzone)
      end
      
      def update_action(progress : Float32)
        # Following continues until stopped
      end
      
      def finish
      end
    end
    
    # Stop camera following action
    class CameraStopFollowAction < CutsceneAction
      def initialize(@camera : CutsceneCamera)
        super(0.0f32)  # Instant action
      end
      
      def start
        @camera.stop_following
      end
      
      def update_action(progress : Float32)
      end
      
      def finish
      end
    end
    
    # Particle effect action
    class ParticleEffectAction < CutsceneAction
      def initialize(@particle_system : Graphics::ParticleSystem, @position : RL::Vector2, 
                     @effect_type : String, duration : Float32 = 0.0f32)
        super(duration)
      end
      
      def start
        # Trigger particle effect at position
        case @effect_type.downcase
        when "explosion"
          create_explosion_effect
        when "magic"
          create_magic_effect
        when "smoke"
          create_smoke_effect
        when "sparkles"
          create_sparkle_effect
        when "fire"
          create_fire_effect
        end
      end
      
      def update_action(progress : Float32)
        # Update particle system
        @particle_system.update(0.016f32)  # Assume 60 FPS
        
        # Check if effect is complete
        if @duration > 0.0f32 && progress >= 1.0f32
          @completed = true
        elsif @duration == 0.0f32 && @particle_system.particles.empty?
          @completed = true
        end
      end
      
      def finish
        # Clean up particles if needed
      end
      
      private def create_explosion_effect
        # Create explosion particles
        30.times do
          velocity = RL::Vector2.new(
            x: (Random.rand - 0.5f32) * 400,
            y: (Random.rand - 0.5f32) * 400
          )
          
          particle = Graphics::Particle.new(
            @position,
            velocity,
            RL::Color.new(r: 255, g: (100 + Random.rand * 155).to_u8, b: 0, a: 255),
            4.0f32,  # size
            1.5f32 + Random.rand  # lifetime
          )
          
          @particle_system.particles << particle
        end
      end
      
      private def create_magic_effect
        # Create magical sparkle particles
        20.times do
          angle = Random.rand * Math::PI * 2
          speed = 50 + Random.rand * 100
          velocity = RL::Vector2.new(
            x: Math.cos(angle) * speed,
            y: Math.sin(angle) * speed
          )
          
          particle = Graphics::Particle.new(
            @position,
            velocity,
            RL::Color.new(r: 138, g: 43, b: 226, a: 255),  # Purple
            3.0f32,  # size
            2.0f32 + Random.rand  # lifetime
          )
          
          @particle_system.particles << particle
        end
      end
      
      private def create_smoke_effect
        # Create smoke particles
        15.times do
          velocity = RL::Vector2.new(
            x: (Random.rand - 0.5f32) * 50,
            y: -50 - Random.rand * 100
          )
          
          gray_value = (100 + Random.rand * 100).to_u8
          particle = Graphics::Particle.new(
            @position,
            velocity,
            RL::Color.new(r: gray_value, g: gray_value, b: gray_value, a: 150),
            6.0f32,  # size
            3.0f32 + Random.rand * 2  # lifetime
          )
          
          @particle_system.particles << particle
        end
      end
      
      private def create_sparkle_effect
        # Create sparkle particles
        25.times do
          velocity = RL::Vector2.new(
            x: (Random.rand - 0.5f32) * 200,
            y: (Random.rand - 0.5f32) * 200
          )
          
          particle = Graphics::Particle.new(
            @position,
            velocity,
            RL::Color.new(r: 255, g: 255, b: 255, a: 255),  # White sparkles
            2.0f32,  # size
            1.0f32 + Random.rand * 0.5f32  # lifetime
          )
          
          @particle_system.particles << particle
        end
      end
      
      private def create_fire_effect
        # Create fire particles
        20.times do
          velocity = RL::Vector2.new(
            x: (Random.rand - 0.5f32) * 30,
            y: -80 - Random.rand * 40
          )
          
          # Fire colors: red to yellow
          red = 255
          green = (Random.rand * 255).to_u8
          blue = 0
          
          particle = Graphics::Particle.new(
            @position,
            velocity,
            RL::Color.new(r: red, g: green, b: blue, a: 200),
            3.0f32,  # size
            1.5f32 + Random.rand * 0.5f32  # lifetime
          )
          
          @particle_system.particles << particle
        end
      end
    end
    
    # Multi-character synchronized action
    class SynchronizedAction(T, U) < CutsceneAction
      @character_actions : Hash(T, U)
      
      def initialize(@character_actions : Hash(T, U)) forall T, U
        # Duration is the longest action
        max_duration = @character_actions.values.map(&.duration).max? || 0.0f32
        super(max_duration)
      end
      
      def start
        @character_actions.values.each(&.reset)
      end
      
      def update_action(progress : Float32)
        all_completed = true
        
        @character_actions.values.each do |action|
          unless action.completed
            action.update(@elapsed_time)
            all_completed = false if !action.completed
          end
        end
        
        if all_completed
          @completed = true
        end
      end
      
      def finish
        @character_actions.values.each do |action|
          action.finish unless action.completed
        end
      end
    end
    
    # Weather effect action
    class WeatherEffectAction < CutsceneAction
      def initialize(@effect_type : String, @intensity : Float32 = 1.0f32, 
                     duration : Float32 = 0.0f32)
        super(duration)
      end
      
      def start
        # Initialize weather effect
        case @effect_type.downcase
        when "rain"
          start_rain_effect
        when "snow"
          start_snow_effect
        when "lightning"
          start_lightning_effect
        when "fog"
          start_fog_effect
        end
      end
      
      def update_action(progress : Float32)
        # Update weather effect
        update_weather_effect(progress)
      end
      
      def finish
        # Clean up weather effect
        stop_weather_effect
      end
      
      private def start_rain_effect
        # Implementation would depend on weather system
        puts "Starting rain effect with intensity #{@intensity}"
      end
      
      private def start_snow_effect
        puts "Starting snow effect with intensity #{@intensity}"
      end
      
      private def start_lightning_effect
        puts "Starting lightning effect with intensity #{@intensity}"
      end
      
      private def start_fog_effect
        puts "Starting fog effect with intensity #{@intensity}"
      end
      
      private def update_weather_effect(progress : Float32)
        # Update weather particles, effects
      end
      
      private def stop_weather_effect
        puts "Stopping weather effect"
      end
    end
    
    # Sound effect action with timing
    class SoundEffectAction < CutsceneAction
      def initialize(@sound_name : String, @volume : Float32 = 1.0f32, 
                     @pitch : Float32 = 1.0f32)
        super(0.0f32)  # Instant action
      end
      
      def start
        # Play sound effect through audio manager
        # This would integrate with the existing audio system
        puts "Playing sound effect: #{@sound_name} (volume: #{@volume}, pitch: #{@pitch})"
      end
      
      def update_action(progress : Float32)
      end
      
      def finish
      end
    end
    
    # Music transition action
    class MusicTransitionAction < CutsceneAction
      def initialize(@new_track : String, @fade_duration : Float32 = 2.0f32)
        super(@fade_duration)
      end
      
      def start
        # Start music transition
        puts "Starting music transition to: #{@new_track}"
      end
      
      def update_action(progress : Float32)
        # Handle music crossfade
        old_volume = 1.0f32 - progress
        new_volume = progress
        
        # Apply volume changes to audio manager
        puts "Music transition progress: #{(progress * 100).to_i}%"
      end
      
      def finish
        puts "Music transition complete"
      end
    end
    
    # Conditional action that executes based on game state
    class ConditionalAction < CutsceneAction
      def initialize(@condition : String, @true_action : CutsceneAction, 
                     @false_action : CutsceneAction? = nil, 
                     @state_manager : Core::GameStateManager? = nil)
        super(0.0f32)  # Duration determined by chosen action
      end
      
      def start
        condition_met = if manager = @state_manager
          manager.check_condition(@condition)
        else
          false
        end
        
        @chosen_action = condition_met ? @true_action : @false_action
        
        if action = @chosen_action
          action.reset
          action.start
          @duration = action.duration
        end
      end
      
      def update_action(progress : Float32)
        if action = @chosen_action
          @completed = action.update(@elapsed_time)
        else
          @completed = true
        end
      end
      
      def finish
        @chosen_action.try(&.finish)
      end
      
      @chosen_action : CutsceneAction?
    end
  end
end