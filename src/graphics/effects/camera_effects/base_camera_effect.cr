# Base camera effect with adapter pattern for reusing object effects

require "../effect"
require "../object_effects"

module PointClickEngine
  module Graphics
    module Effects
      module CameraEffects
        # Base class for camera-specific effects
        abstract class BaseCameraEffect < Effect
          # Whether effect should be applied relative to world or screen
          property world_space : Bool = true

          # Smoothing factor for camera movements
          property smoothing : Float32 = 1.0f32

          def initialize(duration : Float32 = 0.0f32)
            super(duration)
          end

          # Apply effect to camera
          abstract def apply_to_camera(camera : PointClickEngine::Graphics::Camera, dt : Float32)

          # Default apply delegates to apply_to_camera
          def apply(context : EffectContext)
            if context.target_type.camera? && (camera = context.renderer.camera)
              apply_to_camera(camera, context.delta_time)
            end
          end
        end

        # Adapter to use object effects on camera
        class CameraEffectAdapter < BaseCameraEffect
          getter object_effect : Effect

          # Store original camera state
          @original_position : RL::Vector2?
          @original_zoom : Float32?

          def initialize(@object_effect : Effect, duration : Float32 = 0.0f32)
            super(duration)
            @duration = @object_effect.duration if @duration == 0
          end

          def update(dt : Float32)
            super
            @object_effect.update(dt)
          end

          def reset
            super
            @object_effect.reset
            @original_position = nil
            @original_zoom = nil
          end

          def apply_to_camera(camera : Core::Camera, dt : Float32)
            # Store original state on first application
            @original_position ||= camera.position.dup
            # @original_zoom ||= camera.zoom  # Core::Camera doesn't have zoom

            # For now, just apply position-based effects directly
            # without going through the object effect system

            # Map effects to camera
            case @object_effect
            when ObjectEffects::ShakeEffect
              # Simple shake implementation
              offset_x = (Random.rand - 0.5) * 10
              offset_y = (Random.rand - 0.5) * 10
              camera.position.x = @original_position.not_nil!.x + offset_x
              camera.position.y = @original_position.not_nil!.y + offset_y
            when ObjectEffects::FloatEffect
              # Simple float implementation
              time = dt * 2
              offset_y = Math.sin(time) * 5
              camera.position.y = @original_position.not_nil!.y + offset_y
            else
              # Other effects not supported on camera yet
            end
          end
        end
      end
    end
  end
end
