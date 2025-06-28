# Shake effect for objects

require "../effect"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Makes objects shake/vibrate
        class ShakeEffect < Effect
          property amplitude : Float32 = 5.0f32
          property frequency : Float32 = 10.0f32
          property decay : Bool = true
          property direction : ShakeDirection = ShakeDirection::Both

          enum ShakeDirection
            Horizontal
            Vertical
            Both
          end

          @original_position : RL::Vector2?
          @shake_offset : RL::Vector2

          def initialize(@amplitude : Float32 = 5.0f32,
                         @frequency : Float32 = 10.0f32,
                         duration : Float32 = 0.5f32)
            super(duration)
            @shake_offset = RL::Vector2.new(x: 0, y: 0)
          end

          def update(dt : Float32)
            super

            # Calculate shake intensity (with optional decay)
            intensity = if @decay && @duration > 0
                          @amplitude * (1.0f32 - progress)
                        else
                          @amplitude
                        end

            # Generate shake offset using multiple sine waves for more chaotic movement
            time = @elapsed * @frequency

            case @direction
            when .horizontal?
              @shake_offset.x = (Math.sin(time * 2.1) * intensity).to_f32
              @shake_offset.y = 0
            when .vertical?
              @shake_offset.x = 0
              @shake_offset.y = (Math.sin(time * 1.7) * intensity).to_f32
            when .both?
              @shake_offset.x = (Math.sin(time * 2.1) * intensity).to_f32
              @shake_offset.y = (Math.cos(time * 1.7) * intensity).to_f32
            end
          end

          def apply(context : EffectContext)
            return unless sprite = context.sprite

            # Store original position on first apply
            @original_position ||= sprite.position.dup

            # Apply shake offset
            sprite.position = RL::Vector2.new(
              x: @original_position.not_nil!.x + @shake_offset.x,
              y: @original_position.not_nil!.y + @shake_offset.y
            )

            # Draw the sprite
            sprite.draw

            # Restore position if effect is ending
            if finished?
              sprite.position = @original_position.not_nil!
            end
          end

          def reset
            super
            @original_position = nil
            @shake_offset = RL::Vector2.new(x: 0, y: 0)
          end
        end
      end
    end
  end
end
