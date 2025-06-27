# Camera rotation effect for smooth rotation transitions
#
# This effect interpolates the camera rotation over time,
# allowing for smooth rotation effects.

require "./camera_effect"

module PointClickEngine
  module Core
    # Camera rotation effect implementation
    class RotationEffect < CameraEffect
      def initialize(
        target : Float32 = 0.0f32,
        duration : Float32 = 1.0f32,
      )
        parameters = {} of String => Float32 | Characters::Character | Bool
        parameters["target"] = target

        super(CameraEffectType::Rotation, duration, parameters)
        @easing = CameraEasing::EaseInOut
      end

      # Calculate rotation amount - exact logic from original camera_manager
      # Returns the rotation to be applied
      def calculate_rotation : Float32
        target = @parameters["target"]?.as?(Float32) || 0.0f32

        # Interpolate rotation
        t = progress
        eased_t = apply_easing(t)

        target * eased_t
      end

      private def apply_easing(t : Float32) : Float32
        # EaseInOut implementation
        if t < 0.5f32
          2.0f32 * t * t
        else
          1.0f32 - 2.0f32 * (1.0f32 - t) * (1.0f32 - t)
        end
      end
    end
  end
end
