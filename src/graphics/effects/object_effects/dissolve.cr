# Dissolve effect for objects appearing/disappearing

require "../effect"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Makes objects dissolve in/out with optional particle effects
        class DissolveEffect < Effect
          enum DissolveMode
            In  # Fade in
            Out # Fade out
          end

          property mode : DissolveMode
          property pattern : DissolvePattern = DissolvePattern::Alpha
          property particle_color : RL::Color?
          property particle_count : Int32 = 20

          enum DissolvePattern
            Alpha     # Simple alpha fade
            Noise     # Noise-based dissolve
            Pixelate  # Pixelated dissolve
            Particles # Dissolve into particles
          end

          @particles : Array(DissolveParticle) = [] of DissolveParticle

          def initialize(@mode : DissolveMode, duration : Float32 = 1.0f32)
            super(duration)
          end

          def update(dt : Float32)
            super

            # Update particles
            @particles.each(&.update(dt))
            @particles.reject! { |p| !p.alive? }
          end

          def apply(context : EffectContext)
            return unless sprite = context.sprite

            # Calculate dissolve alpha
            alpha = case @mode
                    when .in?
                      Easing.ease_in_out_quad(progress)
                    when .out?
                      1.0f32 - Easing.ease_in_out_quad(progress)
                    else
                      1.0f32
                    end

            case @pattern
            when .alpha?
              apply_alpha_dissolve(sprite, alpha)
            when .noise?
              apply_noise_dissolve(context, sprite, alpha)
            when .pixelate?
              apply_pixelate_dissolve(context, sprite, alpha)
            when .particles?
              apply_particle_dissolve(context, sprite, alpha)
            end

            # Draw particles
            @particles.each(&.draw)
          end

          private def apply_alpha_dissolve(sprite : Sprites::Sprite, alpha : Float32)
            original_tint = sprite.tint
            sprite.tint = RL::Color.new(
              r: original_tint.r,
              g: original_tint.g,
              b: original_tint.b,
              a: (original_tint.a * alpha).to_u8
            )

            sprite.draw
            sprite.tint = original_tint
          end

          private def apply_noise_dissolve(context : EffectContext, sprite : Sprites::Sprite, alpha : Float32)
            # For now, fall back to alpha (shader implementation needed)
            apply_alpha_dissolve(sprite, alpha)

            # Add some particles at dissolve edge
            if @mode.out? && progress > 0.3 && progress < 0.7
              spawn_edge_particles(sprite)
            end
          end

          private def apply_pixelate_dissolve(context : EffectContext, sprite : Sprites::Sprite, alpha : Float32)
            # Increase pixelation as dissolve progresses
            if @mode.out?
              pixelation = (progress * 8).to_i + 1
              # Would need shader support for true pixelation
              # For now, just alpha with particle spawn
              apply_alpha_dissolve(sprite, alpha)

              if progress > 0.5 && @particles.size < 50
                spawn_pixel_particles(sprite, pixelation)
              end
            else
              apply_alpha_dissolve(sprite, alpha)
            end
          end

          private def apply_particle_dissolve(context : EffectContext, sprite : Sprites::Sprite, alpha : Float32)
            apply_alpha_dissolve(sprite, alpha)

            # Continuously spawn particles during dissolve
            if @mode.out? && progress < 0.8
              spawn_rate = (@particle_count * 2 * context.delta_time).to_i
              spawn_rate.times { spawn_particle(sprite) }
            end
          end

          private def spawn_particle(sprite : Sprites::Sprite)
            bounds = sprite.bounds

            # Random position within sprite bounds
            x = bounds.x + Random.rand.to_f32 * bounds.width
            y = bounds.y + Random.rand.to_f32 * bounds.height

            # Color from sprite or parameter
            color = @particle_color || sprite.tint

            # Random velocity
            vel_x = (Random.rand - 0.5).to_f32 * 100
            vel_y = -Random.rand.to_f32 * 150 - 50

            @particles << DissolveParticle.new(
              RL::Vector2.new(x: x, y: y),
              RL::Vector2.new(x: vel_x, y: vel_y),
              color,
              (Random.rand * 3 + 2).to_f32,    # Size
              (Random.rand * 0.5 + 0.5).to_f32 # Lifetime
            )
          end

          private def spawn_edge_particles(sprite : Sprites::Sprite)
            return if Random.rand > 0.3 # Don't spawn every frame

            bounds = sprite.bounds
            edge = Random.rand(4).to_i

            pos = case edge
                  when 0 # Top
                    RL::Vector2.new(
                      x: bounds.x + Random.rand * bounds.width,
                      y: bounds.y
                    )
                  when 1 # Right
                    RL::Vector2.new(
                      x: bounds.x + bounds.width,
                      y: bounds.y + Random.rand * bounds.height
                    )
                  when 2 # Bottom
                    RL::Vector2.new(
                      x: bounds.x + Random.rand * bounds.width,
                      y: bounds.y + bounds.height
                    )
                  else # Left
                    RL::Vector2.new(
                      x: bounds.x,
                      y: bounds.y + Random.rand * bounds.height
                    )
                  end

            color = @particle_color || sprite.tint
            @particles << DissolveParticle.new(
              pos,
              RL::Vector2.new(x: Random.rand(-50..50).to_f32, y: Random.rand(-50..50).to_f32),
              color,
              (Random.rand * 2 + 1).to_f32,
              (Random.rand * 0.3 + 0.2).to_f32
            )
          end

          private def spawn_pixel_particles(sprite : Sprites::Sprite, pixel_size : Int32)
            return if Random.rand > 0.1

            bounds = sprite.bounds

            # Spawn from random "pixel" position
            grid_x = (Random.rand * bounds.width / pixel_size).to_i
            grid_y = (Random.rand * bounds.height / pixel_size).to_i

            x = bounds.x + grid_x * pixel_size + pixel_size / 2
            y = bounds.y + grid_y * pixel_size + pixel_size / 2

            color = @particle_color || sprite.tint

            @particles << DissolveParticle.new(
              RL::Vector2.new(x: x, y: y),
              RL::Vector2.new(
                x: Random.rand(-30..30).to_f32,
                y: Random.rand(-80..-40).to_f32
              ),
              color,
              pixel_size.to_f32,
              (Random.rand * 0.5 + 0.5).to_f32
            )
          end
        end

        # Simple particle for dissolve effects
        class DissolveParticle
          property position : RL::Vector2
          property velocity : RL::Vector2
          property color : RL::Color
          property size : Float32
          property lifetime : Float32
          property age : Float32 = 0.0f32

          def initialize(@position, @velocity, @color, @size, @lifetime)
          end

          def update(dt : Float32)
            @age += dt
            @position.x += @velocity.x * dt
            @position.y += @velocity.y * dt

            # Apply gravity
            @velocity.y += 200 * dt

            # Fade out
            progress = @age / @lifetime
            @color.a = ((1.0 - progress) * 255).to_u8
          end

          def draw
            RL.draw_circle(@position.x.to_i, @position.y.to_i, @size, @color)
          end

          def alive? : Bool
            @age < @lifetime
          end
        end
      end
    end
  end
end
