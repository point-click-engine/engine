# Particle effect that integrates with the effects system

require "./effect"
require "../particles/emitter"
require "../particles/presets"

module PointClickEngine
  module Graphics
    module Effects
      # Particle effect that can be attached to objects or scenes
      class ParticleEffect < Effect
        enum ParticleType
          Fire
          Smoke
          Explosion
          Sparkles
          Rain
          Snow
          HitSpark
          Dust
          Bubbles
          Trail
          Custom
        end

        getter particle_type : ParticleType
        getter emitter : Particles::Emitter?
        property follow_target : Bool = true
        property offset : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)

        # Custom emitter config
        property custom_config : Particles::EmitterConfig?

        def initialize(@particle_type : ParticleType,
                       duration : Float32 = 0.0f32,
                       @follow_target : Bool = true)
          super(duration)
          @custom_config = nil
        end

        # Constructor for custom particle effects
        def self.custom(config : Particles::EmitterConfig,
                        duration : Float32 = 0.0f32,
                        follow_target : Bool = true) : ParticleEffect
          effect = new(ParticleType::Custom, duration, follow_target)
          effect.custom_config = config
          effect
        end

        # Set custom emitter configuration
        def custom_config=(@custom_config : Particles::EmitterConfig?)
        end

        def update(dt : Float32)
          super

          # Update emitter
          @emitter.try(&.update(dt))

          # Stop emitting when effect is ending
          if @duration > 0 && progress > 0.8f32
            @emitter.try(&.stop)
          end

          # Mark as finished when duration expires and no particles remain
          if @duration > 0 && progress >= 1.0f32
            if emitter = @emitter
              @finished = true if !emitter.has_particles?
            else
              @finished = true
            end
          end
        end

        def apply(context : EffectContext)
          # Create emitter on first application
          unless @emitter
            position = context.position || RL::Vector2.new(x: 0, y: 0)
            @emitter = create_emitter(position)
          end

          # Update emitter position if following target
          if @follow_target && (emitter = @emitter)
            if pos = context.position
              emitter.position = RL::Vector2.new(
                x: pos.x + @offset.x,
                y: pos.y + @offset.y
              )
            elsif sprite = context.sprite
              emitter.position = RL::Vector2.new(
                x: sprite.position.x + @offset.x,
                y: sprite.position.y + @offset.y
              )
            end
          end

          # Draw particles
          if emitter = @emitter
            if renderer = context.renderer
              # Use render context for culling
              render_context = PointClickEngine::Graphics::RenderContext.new(
                renderer,
                renderer.camera,
                renderer.viewport
              )
              emitter.draw_with_context(render_context)
            else
              # Fallback to direct draw
              emitter.draw
            end
          end
        end

        def reset
          super
          @emitter.try(&.clear)
          @emitter = nil
        end

        # Stop emitting new particles (existing ones continue)
        def stop_emitting
          @emitter.try(&.stop)
        end

        # Clear all particles immediately
        def clear_particles
          @emitter.try(&.clear)
        end

        # Trigger a burst emission
        def burst(count : Int32? = nil)
          @emitter.try(&.burst(count))
        end

        private def create_emitter(position : RL::Vector2) : Particles::Emitter
          case @particle_type
          when .fire?
            Particles::Presets.fire(position, @intensity)
          when .smoke?
            Particles::Presets.smoke(position, @intensity)
          when .explosion?
            emitter = Particles::Presets.explosion(position, @intensity)
            # For explosion, duration should match particle lifetime
            @duration = 1.0f32 if @duration == 0
            emitter
          when .sparkles?
            Particles::Presets.sparkles(position, 50.0f32 * @intensity)
          when .rain?
            Particles::Presets.rain(position, 800.0f32, @intensity)
          when .snow?
            Particles::Presets.snow(position, 800.0f32, @intensity)
          when .hit_spark?
            emitter = Particles::Presets.hit_spark(position)
            @duration = 0.5f32 if @duration == 0
            emitter
          when .dust?
            emitter = Particles::Presets.dust(position, 30.0f32 * @intensity)
            @duration = 2.0f32 if @duration == 0
            emitter
          when .bubbles?
            Particles::Presets.bubbles(position, 50.0f32 * @intensity)
          when .trail?
            # Trail color can be customized via tint
            color = @custom_config.try(&.start_color) || RL::WHITE
            Particles::Presets.trail(position, color)
          when .custom?
            if config = @custom_config
              Particles::Emitter.new(position, config)
            else
              # Fallback to sparkles if no config
              Particles::Presets.sparkles(position)
            end
          else
            Particles::Presets.sparkles(position)
          end
        end
      end

      # Convenience factory methods
      module ObjectEffects
        # Add particle effect creation
        def self.create_particle(particle_type : String, **params) : ParticleEffect?
          type = case particle_type.downcase
                 when "fire"                         then ParticleEffect::ParticleType::Fire
                 when "smoke"                        then ParticleEffect::ParticleType::Smoke
                 when "explosion", "explode"         then ParticleEffect::ParticleType::Explosion
                 when "sparkles", "sparkle", "magic" then ParticleEffect::ParticleType::Sparkles
                 when "rain"                         then ParticleEffect::ParticleType::Rain
                 when "snow"                         then ParticleEffect::ParticleType::Snow
                 when "hit", "impact", "spark"       then ParticleEffect::ParticleType::HitSpark
                 when "dust", "debris"               then ParticleEffect::ParticleType::Dust
                 when "bubbles", "bubble"            then ParticleEffect::ParticleType::Bubbles
                 when "trail"                        then ParticleEffect::ParticleType::Trail
                 else
                   return nil
                 end

          duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
          follow = params[:follow]? != false

          effect = ParticleEffect.new(type, duration, follow)

          # Set offset if provided
          if offset = params[:offset]?
            case offset
            when Array
              if offset.size >= 2
                effect.offset = RL::Vector2.new(
                  x: offset[0].as(Number).to_f32,
                  y: offset[1].as(Number).to_f32
                )
              end
            when Hash
              x = offset["x"]?.try(&.as(Number).to_f32) || 0.0f32
              y = offset["y"]?.try(&.as(Number).to_f32) || 0.0f32
              effect.offset = RL::Vector2.new(x: x, y: y)
            end
          end

          # Set intensity
          effect.intensity = params[:intensity]?.try(&.as(Number).to_f32) || 1.0f32

          effect
        end
      end
    end
  end
end
