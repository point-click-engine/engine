# Enhanced particle for the effects system

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Particles
      # Individual particle with advanced properties
      class Particle
        # Position and movement
        property position : RL::Vector2
        property velocity : RL::Vector2
        property acceleration : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)

        # Appearance
        property size : Float32
        property start_size : Float32
        property end_size : Float32
        property color : RL::Color
        property start_color : RL::Color
        property end_color : RL::Color
        property rotation : Float32 = 0.0f32
        property rotation_speed : Float32 = 0.0f32

        # Lifetime
        property lifetime : Float32
        property age : Float32 = 0.0f32
        property fade_in_time : Float32 = 0.0f32
        property fade_out_time : Float32 = 0.1f32

        # Behavior flags
        property gravity_affected : Bool = false
        property collision_enabled : Bool = false
        property bounce_factor : Float32 = 0.8f32

        # Texture support
        property texture : RL::Texture2D?
        property texture_rect : RL::Rectangle?

        def initialize(@position : RL::Vector2, @velocity : RL::Vector2,
                       @size : Float32, @color : RL::Color, @lifetime : Float32)
          @start_size = @size
          @end_size = @size
          @start_color = @color
          @end_color = @color
        end

        # Update particle state
        def update(dt : Float32, gravity : RL::Vector2? = nil)
          @age += dt
          return unless alive?

          # Apply acceleration
          @velocity.x += @acceleration.x * dt
          @velocity.y += @acceleration.y * dt

          # Apply gravity if enabled
          if @gravity_affected && gravity
            @velocity.x += gravity.x * dt
            @velocity.y += gravity.y * dt
          end

          # Update position
          @position.x += @velocity.x * dt
          @position.y += @velocity.y * dt

          # Update rotation
          @rotation += @rotation_speed * dt

          # Interpolate size
          progress = @age / @lifetime
          @size = @start_size + (@end_size - @start_size) * progress

          # Interpolate color
          @color = interpolate_color(@start_color, @end_color, progress)

          # Apply fade in/out
          apply_fading
        end

        # Draw the particle
        def draw
          return unless alive?

          if texture = @texture
            draw_textured_particle(texture)
          else
            draw_shape_particle
          end
        end

        # Draw with render context (for culling)
        def draw_with_context(context : PointClickEngine::Graphics::RenderContext)
          return unless alive?
          return unless context.visible?(@position.x, @position.y, @size * 2)

          draw
        end

        # Check if particle is still alive
        def alive? : Bool
          @age < @lifetime
        end

        # Get current alpha
        def alpha : UInt8
          base_alpha = @color.a

          # Apply fading
          if @age < @fade_in_time && @fade_in_time > 0
            fade_progress = @age / @fade_in_time
            base_alpha = (base_alpha * fade_progress).to_u8
          elsif @lifetime - @age < @fade_out_time && @fade_out_time > 0
            fade_progress = (@lifetime - @age) / @fade_out_time
            base_alpha = (base_alpha * fade_progress).to_u8
          end

          base_alpha.clamp(0, 255).to_u8
        end

        # Reset particle for pooling
        def reset(position : RL::Vector2, velocity : RL::Vector2,
                  size : Float32, color : RL::Color, lifetime : Float32)
          @position = position
          @velocity = velocity
          @acceleration = RL::Vector2.new(x: 0, y: 0)
          @size = size
          @start_size = size
          @end_size = size
          @color = color
          @start_color = color
          @end_color = color
          @lifetime = lifetime
          @age = 0.0f32
          @rotation = 0.0f32
          @rotation_speed = 0.0f32
        end

        private def draw_textured_particle(texture : RL::Texture2D)
          source = @texture_rect || RL::Rectangle.new(
            x: 0, y: 0,
            width: texture.width,
            height: texture.height
          )

          dest = RL::Rectangle.new(
            x: @position.x,
            y: @position.y,
            width: @size * 2,
            height: @size * 2
          )

          origin = RL::Vector2.new(x: @size, y: @size)

          tint = RL::Color.new(
            r: @color.r,
            g: @color.g,
            b: @color.b,
            a: alpha
          )

          RL.draw_texture_pro(texture, source, dest, origin, @rotation, tint)
        end

        private def draw_shape_particle
          tint = RL::Color.new(
            r: @color.r,
            g: @color.g,
            b: @color.b,
            a: alpha
          )

          if @rotation != 0
            # Draw rotated rectangle
            rect = RL::Rectangle.new(
              x: @position.x,
              y: @position.y,
              width: @size * 2,
              height: @size * 2
            )
            origin = RL::Vector2.new(x: @size, y: @size)
            RL.draw_rectangle_pro(rect, origin, @rotation, tint)
          else
            # Draw circle (most common)
            RL.draw_circle(@position.x.to_i, @position.y.to_i, @size, tint)
          end
        end

        private def interpolate_color(start : RL::Color, end_color : RL::Color, t : Float32) : RL::Color
          # Ensure t is clamped between 0 and 1
          t_clamped = t.clamp(0.0f32, 1.0f32)

          RL::Color.new(
            r: (start.r.to_f32 + (end_color.r.to_f32 - start.r.to_f32) * t_clamped).clamp(0.0f32, 255.0f32).to_u8,
            g: (start.g.to_f32 + (end_color.g.to_f32 - start.g.to_f32) * t_clamped).clamp(0.0f32, 255.0f32).to_u8,
            b: (start.b.to_f32 + (end_color.b.to_f32 - start.b.to_f32) * t_clamped).clamp(0.0f32, 255.0f32).to_u8,
            a: (start.a.to_f32 + (end_color.a.to_f32 - start.a.to_f32) * t_clamped).clamp(0.0f32, 255.0f32).to_u8
          )
        end

        private def apply_fading
          # Fading is handled in the alpha getter
        end
      end
    end
  end
end
