# Camera follow effect for smooth character following
#
# This effect makes the camera follow a character with optional smooth
# movement and deadzone support.

require "raylib-cr"
require "./camera_effect"
require "../../characters/character"

module PointClickEngine
  module Core
    # Camera follow effect implementation
    class FollowEffect < CameraEffect
      @target : Characters::Character?

      def initialize(
        target : Characters::Character,
        smooth : Bool = true,
        deadzone : Float32 = 50.0f32,
        speed : Float32 = 5.0f32,
        duration : Float32 = 0.0f32, # 0 means continuous
      )
        parameters = {} of String => Float32 | Characters::Character | Bool
        parameters["target"] = target
        parameters["smooth"] = smooth
        parameters["deadzone"] = deadzone
        parameters["speed"] = speed

        @target = target

        super(CameraEffectType::Follow, duration, parameters)
      end

      # Calculate follow movement - exact logic from original camera_manager
      # Returns the position delta to apply
      def calculate_follow_delta(current_camera_pos : RL::Vector2, viewport_width : Int32, viewport_height : Int32) : RL::Vector2
        return RL::Vector2.new(x: 0, y: 0) unless target = @target

        smooth = @parameters["smooth"]?.as?(Bool) || true
        deadzone = @parameters["deadzone"]?.as?(Float32) || 50.0f32
        speed = @parameters["speed"]?.as?(Float32) || 5.0f32

        target_pos = target.position
        center_x = target_pos.x - viewport_width / 2
        center_y = target_pos.y - viewport_height / 2

        if smooth
          # Smooth following with deadzone
          distance = Math.sqrt(
            (center_x - current_camera_pos.x)**2 +
            (center_y - current_camera_pos.y)**2
          )

          if distance > deadzone
            # Move towards target
            direction_x = (center_x - current_camera_pos.x) / distance
            direction_y = (center_y - current_camera_pos.y) / distance

            move_distance = speed * 0.016f32 * (distance - deadzone)

            return RL::Vector2.new(
              x: direction_x * move_distance,
              y: direction_y * move_distance
            )
          else
            return RL::Vector2.new(x: 0, y: 0)
          end
        else
          # Instant following - return the difference to the target
          return RL::Vector2.new(
            x: center_x - current_camera_pos.x,
            y: center_y - current_camera_pos.y
          )
        end
      end
    end
  end
end
