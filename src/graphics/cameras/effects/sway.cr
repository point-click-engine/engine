# Camera sway effect for simulating boat/water motion
#
# This effect creates a wave-like motion by applying sinusoidal movement
# to both horizontal and vertical axes, with optional rotation.

require "raylib-cr"
require "./effect"

module PointClickEngine
  module Graphics
    module Cameras
      # Camera sway effect implementation
      class Sway < Effect
        def initialize(
          amplitude : Float32 = 20.0f32,
          frequency : Float32 = 0.5f32,
          vertical_factor : Float32 = 0.5f32,
          rotation_amplitude : Float32 = 2.0f32,
          duration : Float32 = 0.0f32, # 0 means continuous
        )
          parameters = {} of String => Float32 | Characters::Character | Bool
          parameters["amplitude"] = amplitude
          parameters["frequency"] = frequency
          parameters["vertical_factor"] = vertical_factor
          parameters["rotation_amplitude"] = rotation_amplitude

          super(EffectType::Sway, duration, parameters)
        end

        # Calculate sway offset and rotation - exact logic from original camera_manager
        def calculate_sway : Tuple(RL::Vector2, Float32)
          amplitude = @parameters["amplitude"]?.as?(Float32) || 20.0f32
          frequency = @parameters["frequency"]?.as?(Float32) || 0.5f32
          vertical_factor = @parameters["vertical_factor"]?.as?(Float32) || 0.5f32
          rotation_amplitude = @parameters["rotation_amplitude"]?.as?(Float32) || 2.0f32

          # Create wave motion
          time = @elapsed * frequency

          # Horizontal sway (main motion)
          sway_x = Math.sin(time) * amplitude

          # Vertical sway (secondary motion, like boat rocking)
          sway_y = Math.sin(time * 2.1f32) * amplitude * vertical_factor

          # Slight rotation for more realistic boat effect
          rotation = (Math.sin(time * 0.7f32) * rotation_amplitude).to_f32

          offset = RL::Vector2.new(x: sway_x.to_f32, y: sway_y.to_f32)
          {offset, rotation}
        end
      end
    end
  end
end
