# Vector mathematics utilities
#
# Provides optimized vector operations and utilities commonly used
# throughout the Point & Click Engine. Centralizes math operations
# to reduce code duplication and improve performance.

require "raylib-cr"

module PointClickEngine
  module Utils
    # Mathematical utilities for 2D vector operations
    module VectorMath
      extend self

      # Calculate distance between two points
      #
      # Simple distance calculation using Raylib's optimized function.
      #
      # - *from* : First point
      # - *to* : Second point
      #
      # ```
      # dist = VectorMath.distance(player_pos, target_pos)
      # ```
      def distance(from : RL::Vector2, to : RL::Vector2) : Float32
        Raymath.vector2_distance(from, to)
      end

      # Calculate squared distance between two points
      #
      # More efficient than distance() when you only need to compare distances
      # or when the exact distance value isn't needed.
      #
      # - *from* : First point
      # - *to* : Second point
      #
      # ```
      # if VectorMath.distance_squared(pos1, pos2) < threshold_squared
      #   # Points are close enough
      # end
      # ```
      def distance_squared(from : RL::Vector2, to : RL::Vector2) : Float32
        Raymath.vector2_distance_sqr(from, to)
      end

      # Calculate direction vector and distance between two points
      #
      # Returns a tuple of {direction_vector, distance}. The direction vector
      # is not normalized to preserve the original delta values.
      #
      # - *from* : Starting position
      # - *to* : Target position
      #
      # ```
      # direction, distance = VectorMath.direction_and_distance(start, target)
      # ```
      def direction_and_distance(from : RL::Vector2, to : RL::Vector2) : {RL::Vector2, Float32}
        direction = Raymath.vector2_subtract(to, from)
        distance = Raymath.vector2_length(direction)
        {direction, distance}
      end

      # Calculate normalized direction vector between two points
      #
      # Returns a unit vector pointing from 'from' to 'to'. If the points
      # are the same (distance is zero), returns a zero vector.
      #
      # - *from* : Starting position
      # - *to* : Target position
      #
      # ```
      # normalized = VectorMath.normalized_direction(start, target)
      # ```
      def normalized_direction(from : RL::Vector2, to : RL::Vector2) : RL::Vector2
        direction = Raymath.vector2_subtract(to, from)
        Raymath.vector2_normalize(direction)
      end

      # Normalize a vector
      #
      # Returns a unit vector in the same direction. If the vector is zero,
      # returns a zero vector.
      #
      # - *vector* : The vector to normalize
      #
      # ```
      # unit_vector = VectorMath.normalize(velocity)
      # ```
      def normalize(vector : RL::Vector2) : RL::Vector2
        Raymath.vector2_normalize(vector)
      end

      # Normalize a vector given its length
      #
      # More efficient than recalculating the length when it's already known.
      # Returns a zero vector if the distance is zero or very small.
      #
      # - *vector* : The vector to normalize
      # - *length* : The known length of the vector
      #
      # ```
      # direction, distance = VectorMath.direction_and_distance(start, target)
      # normalized = VectorMath.normalize_vector(direction, distance)
      # ```
      def normalize_vector(vector : RL::Vector2, length : Float32) : RL::Vector2
        return RL::Vector2.new if length < 0.001_f32 # Avoid division by zero
        Raymath.vector2_scale(vector, 1.0_f32 / length)
      end

      # Move a point towards a target by a specified distance
      #
      # Moves 'from' towards 'to' by 'step' units. If the step is larger
      # than the distance to target, returns the target position.
      #
      # - *from* : Starting position
      # - *to* : Target position
      # - *step* : Maximum distance to move
      #
      # ```
      # new_pos = VectorMath.move_towards(current_pos, target_pos, speed * dt)
      # ```
      def move_towards(from : RL::Vector2, to : RL::Vector2, step : Float32) : RL::Vector2
        Raymath.vector2_move_towards(from, to, step)
      end

      # Interpolate between two points
      #
      # Linear interpolation between 'from' and 'to' by factor 't'.
      # When t=0, returns 'from'. When t=1, returns 'to'.
      #
      # - *from* : Starting position
      # - *to* : Target position
      # - *t* : Interpolation factor (0.0 to 1.0)
      #
      # ```
      # interpolated = VectorMath.lerp(start_pos, end_pos, 0.5) # Halfway point
      # ```
      def lerp(from : RL::Vector2, to : RL::Vector2, t : Float32) : RL::Vector2
        # Clamp t to [0, 1] range
        clamped_t = t.clamp(0.0_f32, 1.0_f32)
        Raymath.vector2_lerp(from, to, clamped_t)
      end

      # Add two vectors
      #
      # - *a* : First vector
      # - *b* : Second vector
      #
      # ```
      # total = VectorMath.add(position, offset)
      # ```
      def add(a : RL::Vector2, b : RL::Vector2) : RL::Vector2
        Raymath.vector2_add(a, b)
      end

      # Subtract two vectors
      #
      # - *a* : First vector
      # - *b* : Second vector to subtract
      #
      # ```
      # difference = VectorMath.subtract(target, position)
      # ```
      def subtract(a : RL::Vector2, b : RL::Vector2) : RL::Vector2
        Raymath.vector2_subtract(a, b)
      end

      # Scale a vector by a scalar
      #
      # - *vector* : Vector to scale
      # - *scale* : Scaling factor
      #
      # ```
      # scaled = VectorMath.scale(direction, speed)
      # ```
      def scale(vector : RL::Vector2, scale : Float32) : RL::Vector2
        Raymath.vector2_scale(vector, scale)
      end

      # Calculate dot product of two vectors
      #
      # Useful for determining the angle between vectors or projections.
      #
      # - *a* : First vector
      # - *b* : Second vector
      #
      # ```
      # dot = VectorMath.dot_product(forward, direction)
      # ```
      def dot_product(a : RL::Vector2, b : RL::Vector2) : Float32
        Raymath.vector2_dot_product(a, b)
      end

      # Clamp a vector to maximum magnitude
      #
      # If the vector's length exceeds max_length, it's scaled down to that length.
      # Otherwise, the vector is returned unchanged.
      #
      # - *vector* : Vector to clamp
      # - *max_length* : Maximum allowed length
      #
      # ```
      # velocity = VectorMath.clamp_magnitude(velocity, max_speed)
      # ```
      def clamp_magnitude(vector : RL::Vector2, max_length : Float32) : RL::Vector2
        Raymath.vector2_clamp_value(vector, 0.0_f32, max_length)
      end

      # Check if a point is within a rectangular area
      #
      # - *point* : Point to test
      # - *rect_pos* : Top-left corner of rectangle
      # - *rect_size* : Width and height of rectangle
      #
      # ```
      # if VectorMath.point_in_rect?(mouse_pos, button_pos, button_size)
      #   # Handle button click
      # end
      # ```
      def point_in_rect?(point : RL::Vector2, rect_pos : RL::Vector2, rect_size : RL::Vector2) : Bool
        point.x >= rect_pos.x &&
          point.x <= rect_pos.x + rect_size.x &&
          point.y >= rect_pos.y &&
          point.y <= rect_pos.y + rect_size.y
      end

      # Check if a point is within a circle
      #
      # - *point* : Point to test
      # - *center* : Center of the circle
      # - *radius* : Radius of the circle
      #
      # ```
      # if VectorMath.point_in_circle?(click_pos, character_pos, interaction_radius)
      #   # Handle character interaction
      # end
      # ```
      def point_in_circle?(point : RL::Vector2, center : RL::Vector2, radius : Float32) : Bool
        distance_squared(point, center) <= radius ** 2
      end

      # Calculate the angle between two points in radians
      #
      # Returns the angle from 'from' to 'to' in radians.
      # Uses atan2 for proper quadrant handling.
      #
      # - *from* : Starting position
      # - *to* : Target position
      #
      # ```
      # angle = VectorMath.angle_between(character_pos, target_pos)
      # character.rotation = angle
      # ```
      def angle_between(from : RL::Vector2, to : RL::Vector2) : Float32
        # Calculate the angle using atan2 for consistent behavior
        diff = Raymath.vector2_subtract(to, from)
        Math.atan2(diff.y, diff.x).to_f32
      end

      # Convert angle to direction vector
      #
      # Creates a unit vector pointing in the direction of the given angle.
      #
      # - *angle* : Angle in radians
      #
      # ```
      # direction = VectorMath.angle_to_vector(Math::PI / 2) # Points up
      # ```
      def angle_to_vector(angle : Float32) : RL::Vector2
        RL::Vector2.new(
          x: Math.cos(angle).to_f32,
          y: Math.sin(angle).to_f32
        )
      end

      # Rotate a vector by an angle
      #
      # - *vector* : Vector to rotate
      # - *angle* : Angle in radians
      #
      # ```
      # rotated = VectorMath.rotate(direction, Math::PI / 4)
      # ```
      def rotate(vector : RL::Vector2, angle : Float32) : RL::Vector2
        Raymath.vector2_rotate(vector, angle)
      end

      # Get the length/magnitude of a vector
      #
      # - *vector* : Vector to measure
      #
      # ```
      # speed = VectorMath.length(velocity)
      # ```
      def length(vector : RL::Vector2) : Float32
        Raymath.vector2_length(vector)
      end

      # Get the squared length of a vector
      #
      # More efficient than length() when comparing magnitudes.
      #
      # - *vector* : Vector to measure
      #
      # ```
      # if VectorMath.length_squared(velocity) > max_speed_squared
      #   # Velocity is too high
      # end
      # ```
      def length_squared(vector : RL::Vector2) : Float32
        Raymath.vector2_length_sqr(vector)
      end

      # Negate a vector (reverse direction)
      #
      # - *vector* : Vector to negate
      #
      # ```
      # opposite = VectorMath.negate(direction)
      # ```
      def negate(vector : RL::Vector2) : RL::Vector2
        Raymath.vector2_negate(vector)
      end

      # Get zero vector
      #
      # ```
      # velocity = VectorMath.zero
      # ```
      def zero : RL::Vector2
        Raymath.vector2_zero
      end

      # Get one vector (1, 1)
      #
      # ```
      # scale = VectorMath.one
      # ```
      def one : RL::Vector2
        Raymath.vector2_one
      end

      # Reflect a vector off a normal
      #
      # - *vector* : Incoming vector
      # - *normal* : Surface normal (should be normalized)
      #
      # ```
      # bounce_dir = VectorMath.reflect(velocity, wall_normal)
      # ```
      def reflect(vector : RL::Vector2, normal : RL::Vector2) : RL::Vector2
        Raymath.vector2_reflect(vector, normal)
      end

      # Check if two vectors are equal
      #
      # - *a* : First vector
      # - *b* : Second vector
      #
      # ```
      # if VectorMath.equals?(pos1, pos2)
      #   # Positions are the same
      # end
      # ```
      def equals?(a : RL::Vector2, b : RL::Vector2) : Bool
        Raymath.vector2_equals(a, b)
      end
    end
  end
end
