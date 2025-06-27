# Camera shake effect for simulating earthquakes, impacts, and other disturbances
#
# This effect adds random offset to the camera position to create a shaking motion.
# The intensity decays over time for a natural feel.

require "raylib-cr"
require "./camera_effect"

module PointClickEngine
  module Graphics
    module Cameras
      # Camera shake effect implementation
      class ShakeEffect < CameraEffect
        def initialize(
          intensity : Float32 = 10.0f32,
          frequency : Float32 = 10.0f32,
          duration : Float32 = 1.0f32,
        )
          parameters = {} of String => Float32 | Characters::Character | Bool
          parameters["intensity"] = intensity
          parameters["frequency"] = frequency

          super(CameraEffectType::Shake, duration, parameters)
        end

        # Calculate shake offset - exact logic from original camera_manager
        # Returns the offset to be added to the camera position
        def calculate_shake_offset : RL::Vector2
          intensity = @parameters["intensity"]?.as?(Float32) || 10.0f32
          frequency = @parameters["frequency"]?.as?(Float32) || 10.0f32

          # Decay intensity over time
          current_intensity = intensity * (1.0f32 - progress)

          # Generate shake offset
          time_factor = @elapsed * frequency
          offset_x = Math.sin(time_factor * 2.1f32) * current_intensity * (Random.rand - 0.5f32) * 2
          offset_y = Math.cos(time_factor * 1.7f32) * current_intensity * (Random.rand - 0.5f32) * 2

          RL::Vector2.new(x: offset_x.to_f32, y: offset_y.to_f32)
        end
      end
      end
  end
end
