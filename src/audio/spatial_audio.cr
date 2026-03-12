# Spatial Audio Utilities
#
# Common calculations for 3D/2D positional audio effects.
# Consolidates distance-based volume and panning calculations.

require "raylib-cr"

module PointClickEngine
  module Audio
    # Utility module for spatial audio calculations
    module SpatialAudio
      # Calculate distance between two 2D points
      def self.calculate_distance(pos1 : RL::Vector2, pos2 : RL::Vector2) : Float32
        dx = pos1.x - pos2.x
        dy = pos1.y - pos2.y
        Math.sqrt(dx * dx + dy * dy).to_f32
      end

      # Calculate volume factor based on distance
      # Returns a value between 0.0 (out of range) and 1.0 (at listener position)
      #
      # - *source_pos*: Position of the sound source
      # - *listener_pos*: Position of the listener (usually player/camera)
      # - *max_distance*: Maximum distance at which sound is audible
      # - *falloff*: How quickly sound fades (1.0 = linear, >1 = faster falloff)
      def self.calculate_volume_factor(
        source_pos : RL::Vector2,
        listener_pos : RL::Vector2,
        max_distance : Float32,
        falloff : Float32 = 1.0f32
      ) : Float32
        distance = calculate_distance(source_pos, listener_pos)

        return 1.0f32 if distance <= 0.0f32
        return 0.0f32 if distance >= max_distance

        # Linear falloff
        factor = 1.0f32 - (distance / max_distance)

        # Apply falloff curve if not linear
        if falloff != 1.0f32
          factor = factor ** falloff
        end

        factor.clamp(0.0f32, 1.0f32)
      end

      # Calculate stereo panning based on horizontal position
      # Returns a value between -1.0 (full left) and 1.0 (full right)
      #
      # - *source_pos*: Position of the sound source
      # - *listener_pos*: Position of the listener
      # - *pan_width*: Horizontal distance at which full panning occurs
      def self.calculate_pan(
        source_pos : RL::Vector2,
        listener_pos : RL::Vector2,
        pan_width : Float32 = 400.0f32
      ) : Float32
        horizontal_offset = source_pos.x - listener_pos.x
        (horizontal_offset / pan_width).clamp(-1.0f32, 1.0f32)
      end

      # Calculate both volume and pan for a sound source
      # Returns a named tuple with :volume and :pan
      def self.calculate_spatial_params(
        source_pos : RL::Vector2,
        listener_pos : RL::Vector2,
        max_distance : Float32 = 500.0f32,
        pan_width : Float32 = 400.0f32,
        falloff : Float32 = 1.0f32
      ) : NamedTuple(volume: Float32, pan: Float32)
        {
          volume: calculate_volume_factor(source_pos, listener_pos, max_distance, falloff),
          pan:    calculate_pan(source_pos, listener_pos, pan_width),
        }
      end

      # Check if a position is within audible range
      def self.in_range?(
        source_pos : RL::Vector2,
        listener_pos : RL::Vector2,
        max_distance : Float32
      ) : Bool
        calculate_distance(source_pos, listener_pos) < max_distance
      end
    end
  end
end
