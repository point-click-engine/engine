# Camera zoom effect for smooth zoom transitions
#
# This effect interpolates the camera zoom factor over time,
# allowing for smooth zoom in/out effects.

require "./effect"

module PointClickEngine
  module Graphics
    module Cameras
      # Camera zoom effect implementation
      class Zoom < Effect
        def initialize(
          target : Float32 = 1.0f32,
          duration : Float32 = 1.0f32,
        )
          parameters = {} of String => Float32 | Characters::Character | Bool
          parameters["target"] = target
          parameters["factor"] = target # Support both names

          super(EffectType::Zoom, duration, parameters)
          @easing = Easing::EaseInOut
        end

        # Calculate zoom factor - exact logic from original camera_manager
        # Returns the zoom multiplier to be applied
        def calculate_zoom_factor : Float32
          # Support both "target" and "factor" parameter names
          target = @parameters["target"]?.as?(Float32) ||
                   @parameters["factor"]?.as?(Float32) || 1.0f32

          # Interpolate zoom
          t = progress
          eased_t = apply_easing(t)

          1.0f32 + (target - 1.0f32) * eased_t
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
end
