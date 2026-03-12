# Color shifting effects for objects

require "../effect"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Applies color transformations to objects
        class ColorShiftEffect < Effect
          property mode : ColorMode
          property target_color : RL::Color?
          property speed : Float32 = 1.0f32

          enum ColorMode
            Tint      # Blend with color
            Flash     # Brief flash
            Rainbow   # Cycle through colors
            Grayscale # Convert to grayscale
            Sepia     # Sepia tone
            Negative  # Invert colors
          end

          @original_tint : RL::Color?
          @flash_time : Float32 = 0.0f32
          @rainbow_time : Float32 = 0.0f32

          def initialize(@mode : ColorMode,
                         @target_color : RL::Color? = nil,
                         duration : Float32 = 0.0f32)
            super(duration)

            # Set default target colors for certain modes
            case @mode
            when .flash?
              @target_color ||= RL::WHITE
              @duration = 0.2f32 if @duration == 0 # Default flash duration
            when .sepia?
              @target_color = RL::Color.new(r: 210, g: 180, b: 140, a: 255)
            end
          end

          def update(dt : Float32)
            super

            case @mode
            when .flash?
              @flash_time += dt
            when .rainbow?
              @rainbow_time += dt * @speed
            end
          end

          def apply(context : EffectContext)
            return unless sprite = context.sprite

            # Store original tint on first apply
            @original_tint ||= sprite.tint

            case @mode
            when .tint?
              apply_tint(sprite)
            when .flash?
              apply_flash(sprite)
            when .rainbow?
              apply_rainbow(sprite)
            when .grayscale?
              apply_grayscale(sprite)
            when .sepia?
              apply_sepia(sprite)
            when .negative?
              apply_negative(sprite)
            end

            # Draw the sprite
            sprite.draw

            # Restore tint if effect is ending
            if finished?
              sprite.tint = @original_tint.not_nil!
            end
          end

          private def apply_tint(sprite : Sprites::Sprite)
            return unless target = @target_color
            original = @original_tint.not_nil!

            # Blend original with target based on intensity
            sprite.tint = RL::Color.new(
              r: (original.r * (1 - @intensity) + target.r * @intensity).to_u8,
              g: (original.g * (1 - @intensity) + target.g * @intensity).to_u8,
              b: (original.b * (1 - @intensity) + target.b * @intensity).to_u8,
              a: original.a
            )
          end

          private def apply_flash(sprite : Sprites::Sprite)
            return unless target = @target_color
            original = @original_tint.not_nil!

            # Flash intensity based on time
            flash_intensity = if @duration > 0
                                (1.0 - progress) * @intensity
                              else
                                # Strobe effect for continuous flash
                                ((Math.sin(@flash_time * 10) + 1) * 0.5 * @intensity).to_f32
                              end

            sprite.tint = RL::Color.new(
              r: (original.r * (1 - flash_intensity) + target.r * flash_intensity).to_u8,
              g: (original.g * (1 - flash_intensity) + target.g * flash_intensity).to_u8,
              b: (original.b * (1 - flash_intensity) + target.b * flash_intensity).to_u8,
              a: original.a
            )
          end

          private def apply_rainbow(sprite : Sprites::Sprite)
            # Cycle through hue
            hue = (@rainbow_time % 1.0) * 360.0

            # Convert HSV to RGB (simplified)
            h = hue / 60.0
            c = 1.0
            x = c * (1.0 - ((h % 2.0) - 1.0).abs)

            r, g, b = case h.to_i
                      when 0 then {c, x, 0.0}
                      when 1 then {x, c, 0.0}
                      when 2 then {0.0, c, x}
                      when 3 then {0.0, x, c}
                      when 4 then {x, 0.0, c}
                      else        {c, 0.0, x}
                      end

            sprite.tint = RL::Color.new(
              r: (r * 255 * @intensity + @original_tint.not_nil!.r * (1 - @intensity)).to_u8,
              g: (g * 255 * @intensity + @original_tint.not_nil!.g * (1 - @intensity)).to_u8,
              b: (b * 255 * @intensity + @original_tint.not_nil!.b * (1 - @intensity)).to_u8,
              a: @original_tint.not_nil!.a
            )
          end

          private def apply_grayscale(sprite : Sprites::Sprite)
            original = @original_tint.not_nil!

            # Calculate grayscale value
            gray = (original.r * 0.299 + original.g * 0.587 + original.b * 0.114).to_u8

            sprite.tint = RL::Color.new(
              r: (original.r * (1 - @intensity) + gray * @intensity).to_u8,
              g: (original.g * (1 - @intensity) + gray * @intensity).to_u8,
              b: (original.b * (1 - @intensity) + gray * @intensity).to_u8,
              a: original.a
            )
          end

          private def apply_sepia(sprite : Sprites::Sprite)
            original = @original_tint.not_nil!

            # Sepia tone matrix
            tr = (original.r * 0.393 + original.g * 0.769 + original.b * 0.189).clamp(0, 255)
            tg = (original.r * 0.349 + original.g * 0.686 + original.b * 0.168).clamp(0, 255)
            tb = (original.r * 0.272 + original.g * 0.534 + original.b * 0.131).clamp(0, 255)

            sprite.tint = RL::Color.new(
              r: (original.r * (1 - @intensity) + tr * @intensity).to_u8,
              g: (original.g * (1 - @intensity) + tg * @intensity).to_u8,
              b: (original.b * (1 - @intensity) + tb * @intensity).to_u8,
              a: original.a
            )
          end

          private def apply_negative(sprite : Sprites::Sprite)
            original = @original_tint.not_nil!

            sprite.tint = RL::Color.new(
              r: (original.r * (1 - @intensity) + (255 - original.r) * @intensity).to_u8,
              g: (original.g * (1 - @intensity) + (255 - original.g) * @intensity).to_u8,
              b: (original.b * (1 - @intensity) + (255 - original.b) * @intensity).to_u8,
              a: original.a
            )
          end

          def reset
            super
            @original_tint = nil
            @flash_time = 0.0f32
            @rainbow_time = 0.0f32
          end
        end
      end
    end
  end
end
