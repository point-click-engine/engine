# Camera pan effect for smooth camera movement to a target position
#
# This effect interpolates the camera position from its current location
# to a target position over a specified duration.

require "raylib-cr"
require "./camera_effect"

module PointClickEngine
  module Core
    # Camera pan effect implementation
    class PanEffect < CameraEffect
      # Pan state
      @start_position : RL::Vector2?
      @target_position : RL::Vector2
      
      def initialize(
        target_x : Float32,
        target_y : Float32,
        duration : Float32 = 1.0f32
      )
        parameters = {} of String => Float32 | Characters::Character | Bool
        parameters["target_x"] = target_x
        parameters["target_y"] = target_y
        
        @target_position = RL::Vector2.new(x: target_x, y: target_y)
        
        super(CameraEffectType::Pan, duration, parameters)
        @easing = CameraEasing::EaseInOut
      end
      
      # Set the starting position when first applied
      def set_start_position(position : RL::Vector2)
        @start_position = position.dup
        @parameters["start_x"] = position.x
        @parameters["start_y"] = position.y
      end
      
      # Calculate interpolated position - exact logic from original camera_manager
      # Returns the new camera position
      def calculate_position(current_position : RL::Vector2) : RL::Vector2
        # Initialize start position if not set
        unless @start_position
          @start_position = current_position.dup
          @parameters["start_x"] = current_position.x
          @parameters["start_y"] = current_position.y
        end
        
        start_pos = @start_position.not_nil!
        
        # Interpolate position
        t = progress
        eased_t = apply_easing(t)
        
        new_x = start_pos.x + (@target_position.x - start_pos.x) * eased_t
        new_y = start_pos.y + (@target_position.y - start_pos.y) * eased_t
        
        RL::Vector2.new(x: new_x, y: new_y)
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