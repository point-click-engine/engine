# Highlight effect for interactive objects

require "../effect"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Adds a highlight effect to objects (glow, outline, or color overlay)
        class HighlightEffect < Effect
          enum HighlightType
            Glow
            Outline
            ColorOverlay
            Pulse
          end

          property highlight_type : HighlightType
          property color : RL::Color
          property thickness : Float32 = 2.0f32 # For outline
          property radius : Float32 = 10.0f32   # For glow
          property pulse_speed : Float32 = 2.0f32

          @pulse_time : Float32 = 0.0f32

          def initialize(@highlight_type : HighlightType = HighlightType::Glow,
                         @color : RL::Color = RL::YELLOW,
                         duration : Float32 = 0.0f32)
            super(duration)
          end

          def update(dt : Float32)
            super
            @pulse_time += dt * @pulse_speed
          end

          def apply(context : EffectContext)
            return unless sprite = context.sprite
            return unless texture = sprite.texture

            case @highlight_type
            when .glow?
              apply_glow(context, sprite)
            when .outline?
              apply_outline(context, sprite)
            when .color_overlay?
              apply_color_overlay(context, sprite)
            when .pulse?
              apply_pulse(context, sprite)
            end
          end

          private def apply_glow(context : EffectContext, sprite : Sprites::Sprite)
            # Draw multiple scaled versions with decreasing alpha
            glow_color = @color
            layers = 5

            (1..layers).reverse_each do |i|
              scale_factor = 1.0f32 + (i * 0.02f32 * @radius / 10.0f32)
              alpha = (20 * @intensity / i).to_u8

              glow_color.a = alpha

              # Draw scaled sprite with glow color
              original_scale = sprite.scale
              original_tint = sprite.tint

              sprite.scale = original_scale * scale_factor
              sprite.tint = glow_color
              sprite.draw

              sprite.scale = original_scale
              sprite.tint = original_tint
            end

            # Draw original sprite on top
            sprite.draw
          end

          private def apply_outline(context : EffectContext, sprite : Sprites::Sprite)
            return unless texture = sprite.texture

            # Draw sprite in outline color at offset positions
            original_tint = sprite.tint
            sprite.tint = @color

            offsets = [
              {-@thickness, 0},
              {@thickness, 0},
              {0, -@thickness},
              {0, @thickness},
              {-@thickness, -@thickness},
              {@thickness, -@thickness},
              {-@thickness, @thickness},
              {@thickness, @thickness},
            ]

            original_pos = sprite.position

            offsets.each do |x_off, y_off|
              sprite.position = RL::Vector2.new(
                x: original_pos.x + x_off,
                y: original_pos.y + y_off
              )
              sprite.draw
            end

            # Restore and draw original
            sprite.position = original_pos
            sprite.tint = original_tint
            sprite.draw
          end

          private def apply_color_overlay(context : EffectContext, sprite : Sprites::Sprite)
            # Blend sprite color with highlight color
            original_tint = sprite.tint

            blend_factor = @intensity
            sprite.tint = RL::Color.new(
              r: (original_tint.r * (1 - blend_factor) + @color.r * blend_factor).to_u8,
              g: (original_tint.g * (1 - blend_factor) + @color.g * blend_factor).to_u8,
              b: (original_tint.b * (1 - blend_factor) + @color.b * blend_factor).to_u8,
              a: original_tint.a
            )

            sprite.draw
            sprite.tint = original_tint
          end

          private def apply_pulse(context : EffectContext, sprite : Sprites::Sprite)
            # Pulsing highlight using sine wave
            pulse_intensity = (Math.sin(@pulse_time) + 1.0) * 0.5

            # Temporarily adjust intensity
            original_intensity = @intensity
            @intensity *= pulse_intensity

            # Apply glow with pulsing intensity
            apply_glow(context, sprite)

            @intensity = original_intensity
          end
        end
      end
    end
  end
end
