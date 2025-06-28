# Pulse/breathing effect for objects

require "../effect"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Makes objects pulse/breathe by scaling them rhythmically
        class PulseEffect < Effect
          property scale_amount : Float32 = 0.1f32 # How much to scale (0.1 = 10%)
          property speed : Float32 = 2.0f32        # Pulses per second
          property easing : EasingType = EasingType::Sine

          enum EasingType
            Linear
            Sine
            Quad
            Bounce
          end

          @original_scale : Float32?
          @pulse_time : Float32 = 0.0f32

          def initialize(@scale_amount : Float32 = 0.1f32,
                         @speed : Float32 = 2.0f32,
                         duration : Float32 = 0.0f32)
            super(duration)
          end

          def update(dt : Float32)
            super
            @pulse_time += dt * @speed
          end

          def apply(context : EffectContext)
            return unless sprite = context.sprite

            # Store original scale on first apply
            @original_scale ||= sprite.scale

            # Calculate pulse value (0 to 1)
            pulse_value = case @easing
                          when .linear?
                            ((@pulse_time % 1.0) * 2.0 - 1.0).abs
                          when .sine?
                            (Math.sin(@pulse_time * Math::PI * 2) + 1.0) * 0.5
                          when .quad?
                            t = (@pulse_time % 1.0) * 2.0
                            if t < 1.0
                              t * t
                            else
                              t = 2.0 - t
                              1.0 - t * t
                            end
                          when .bounce?
                            t = (@pulse_time % 1.0)
                            if t < 0.5
                              # Scale up with bounce
                              Easing.ease_out_bounce(t * 2)
                            else
                              # Scale down with bounce
                              1.0 - Easing.ease_out_bounce((t - 0.5) * 2)
                            end
                          else
                            0.0
                          end

            # Apply scale with intensity
            scale_offset = @scale_amount * pulse_value.to_f32 * @intensity
            sprite.scale = @original_scale.not_nil! * (1.0f32 + scale_offset)

            # Draw the sprite
            sprite.draw

            # Restore scale if effect is ending
            if finished?
              sprite.scale = @original_scale.not_nil!
            end
          end

          def reset
            super
            @original_scale = nil
            @pulse_time = 0.0f32
          end
        end
      end
    end
  end
end
