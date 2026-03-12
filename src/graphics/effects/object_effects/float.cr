# Floating motion effect for objects

require "../effect"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Makes objects float gently up and down
        class FloatEffect < Effect
          property amplitude : Float32 = 10.0f32      # Pixels to move
          property speed : Float32 = 1.0f32           # Oscillations per second
          property phase : Float32 = 0.0f32           # Starting phase (0-1)
          property rotation : Bool = false            # Add slight rotation
          property rotation_amount : Float32 = 5.0f32 # Degrees

          @original_position : RL::Vector2?
          @original_rotation : Float32?
          @float_time : Float32 = 0.0f32

          def initialize(@amplitude : Float32 = 10.0f32,
                         @speed : Float32 = 1.0f32,
                         duration : Float32 = 0.0f32)
            super(duration)
            @float_time = @phase * Math::PI * 2
          end

          def update(dt : Float32)
            super
            @float_time += dt * @speed * Math::PI * 2
          end

          def apply(context : EffectContext)
            return unless sprite = context.sprite

            # Store original values on first apply
            @original_position ||= sprite.position.dup
            @original_rotation ||= sprite.rotation

            # Calculate float offset using sine wave
            offset_y = Math.sin(@float_time) * @amplitude * @intensity

            # Apply position offset
            sprite.position = RL::Vector2.new(
              x: @original_position.not_nil!.x,
              y: @original_position.not_nil!.y + offset_y
            )

            # Apply rotation if enabled
            if @rotation
              # Slight rotation that follows the float motion
              rotation_offset = Math.sin(@float_time + Math::PI / 4) * @rotation_amount * @intensity
              sprite.rotation = @original_rotation.not_nil! + rotation_offset
            end

            # Draw the sprite
            sprite.draw

            # Restore values if effect is ending
            if finished?
              sprite.position = @original_position.not_nil!
              sprite.rotation = @original_rotation.not_nil! if @rotation
            end
          end

          def reset
            super
            @original_position = nil
            @original_rotation = nil
            @float_time = @phase * Math::PI * 2
          end
        end

        # More complex floating with horizontal sway
        class SwayFloatEffect < FloatEffect
          property sway_amplitude : Float32 = 5.0f32
          property sway_speed : Float32 = 0.7f32

          def apply(context : EffectContext)
            return unless sprite = context.sprite

            # Store original values on first apply
            @original_position ||= sprite.position.dup
            @original_rotation ||= sprite.rotation

            # Calculate float offset using sine wave
            offset_y = Math.sin(@float_time) * @amplitude * @intensity

            # Add horizontal sway
            offset_x = Math.sin(@float_time * @sway_speed) * @sway_amplitude * @intensity

            # Apply position offset
            sprite.position = RL::Vector2.new(
              x: @original_position.not_nil!.x + offset_x,
              y: @original_position.not_nil!.y + offset_y
            )

            # Apply rotation based on sway
            if @rotation
              rotation_offset = offset_x / @sway_amplitude * @rotation_amount * 0.5
              sprite.rotation = @original_rotation.not_nil! + rotation_offset
            end

            # Draw the sprite
            sprite.draw

            # Restore values if effect is ending
            if finished?
              sprite.position = @original_position.not_nil!
              sprite.rotation = @original_rotation.not_nil! if @rotation
            end
          end
        end
      end
    end
  end
end
