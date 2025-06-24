# Movement controller for character navigation
#
# Centralizes all character movement logic including direct movement,
# pathfinding, and animation coordination. Eliminates code duplication
# and provides optimized movement calculations.

require "raylib-cr"
require "../core/game_constants"
require "../utils/vector_math"

module PointClickEngine
  module Characters
    # Handles all aspects of character movement and navigation
    #
    # This class centralizes movement logic that was previously duplicated
    # across the Character class. It provides both direct movement and
    # pathfinding capabilities with optimized calculations.
    #
    # ## Features
    # - Direct movement to target positions
    # - Pathfinding with waypoint navigation
    # - Automatic animation selection based on movement direction
    # - Walkable area constraint checking
    # - Performance optimized vector calculations
    #
    # ## Usage
    # ```
    # controller = MovementController.new(character)
    # controller.move_to(target_position)
    # controller.update(dt)
    # ```
    class MovementController
      include Core::GameConstants

      # The character this controller manages
      getter character : Character

      # Current movement target (nil if not moving)
      property target_position : RL::Vector2?

      # Pathfinding waypoints (nil if using direct movement)
      property path : Array(RL::Vector2)?

      # Current index in the pathfinding waypoints
      property current_path_index : Int32 = 0

      # Callback to execute when movement completes
      property on_movement_complete : Proc(Nil)?

      # Cached normalized direction vector (performance optimization)
      @cached_direction : RL::Vector2?
      @cached_distance : Float32?
      @direction_cache_valid : Bool = false

      def initialize(@character : Character)
      end

      # Initiate direct movement to a target position
      #
      # Sets up direct movement (no pathfinding) to the specified target.
      # Automatically selects appropriate walking animation and clears any
      # existing pathfinding data.
      #
      # - *target* : World position to move to
      # - *use_pathfinding* : Whether to use pathfinding (default: character setting)
      #
      # ```
      # controller.move_to(Vector2.new(200, 300))
      # controller.move_to(target, use_pathfinding: true)
      # ```
      def move_to(target : RL::Vector2, use_pathfinding : Bool? = nil)
        @target_position = target
        @character.state = CharacterState::Walking

        # Clear pathfinding data for direct movement
        clear_pathfinding_data
        invalidate_direction_cache

        # Use pathfinding if requested and available
        should_use_pathfinding = use_pathfinding || @character.use_pathfinding
        if should_use_pathfinding && (scene = get_current_scene)
          if calculated_path = scene.find_path(@character.position.x, @character.position.y, target.x, target.y)
            setup_pathfinding(calculated_path)
            return
          end
        end

        # Setup direct movement
        update_direction_and_animation(target)
      end

      # Initiate movement along a predefined path
      #
      # Sets up pathfinding movement through a series of waypoints.
      # The character will navigate through each waypoint in sequence.
      #
      # - *waypoints* : Array of waypoints to follow
      #
      # ```
      # path = scene.find_path(start, destination)
      # controller.move_along_path(path) if path
      # ```
      def move_along_path(waypoints : Array(RL::Vector2))
        return if waypoints.empty?

        @path = waypoints
        @current_path_index = 0
        @target_position = waypoints.last
        @character.state = CharacterState::Walking

        invalidate_direction_cache
        update_direction_and_animation(waypoints[0])
      end

      # Stop all movement immediately
      #
      # Clears movement target, pathfinding data, and returns character
      # to idle state. Executes completion callback if one was set.
      def stop_movement
        @target_position = nil
        clear_pathfinding_data
        invalidate_direction_cache

        @character.state = CharacterState::Idle
        play_idle_animation

        # Execute completion callback
        callback = @on_movement_complete
        @on_movement_complete = nil
        callback.try(&.call)
      end

      # Update movement state and position
      #
      # Called every frame to process movement calculations and update
      # character position. Handles both direct movement and pathfinding.
      #
      # - *dt* : Delta time in seconds since last update
      def update(dt : Float32)
        return unless @character.state == CharacterState::Walking

        if path = @path
          update_pathfinding_movement(dt)
        elsif target = @target_position
          update_direct_movement(target, dt)
        else
          stop_movement
        end
      end

      # Check if character is currently moving
      def moving? : Bool
        @character.state == CharacterState::Walking
      end

      # Check if character is following a path
      def following_path? : Bool
        !@path.nil?
      end

      # Get remaining distance to target
      def distance_to_target : Float32
        return 0.0_f32 unless target = @target_position
        Utils::VectorMath.distance(@character.position, target)
      end

      # Get current movement speed
      def current_speed : Float32
        @character.walking_speed
      end

      # Set movement speed
      def set_speed(speed : Float32)
        @character.walking_speed = speed
      end

      private def update_direct_movement(target : RL::Vector2, dt : Float32)
        # Use cached direction if available, otherwise calculate
        direction, distance = get_direction_and_distance(target)

        # Check if we've arrived
        if distance <= MOVEMENT_ARRIVAL_THRESHOLD
          @character.position = target
          stop_movement
          return
        end

        # Calculate new position
        movement_step = @character.walking_speed * dt
        new_position = Utils::VectorMath.move_towards(@character.position, target, movement_step)

        # Apply movement with walkable area checking
        apply_movement(new_position, target)

        # Update animation if direction changed significantly
        update_direction_and_animation(target)
      end

      private def update_pathfinding_movement(dt : Float32)
        path = @path.not_nil!
        return stop_movement if @current_path_index >= path.size

        current_waypoint = path[@current_path_index]
        direction, distance = get_direction_and_distance(current_waypoint)

        # Check if we reached the current waypoint
        if distance <= PATHFINDING_WAYPOINT_THRESHOLD
          advance_to_next_waypoint
          return
        end

        # Move towards current waypoint
        movement_step = @character.walking_speed * dt
        new_position = Utils::VectorMath.move_towards(@character.position, current_waypoint, movement_step)

        # Apply movement
        apply_movement(new_position, current_waypoint)

        # Update animation for current direction
        update_direction_and_animation(current_waypoint)
      end

      private def advance_to_next_waypoint
        @current_path_index += 1
        path = @path.not_nil!

        # Check if we completed the path
        if @current_path_index >= path.size
          # Move to final target if it's different from last waypoint
          if final_target = @target_position
            final_distance = Utils::VectorMath.distance(@character.position, final_target)
            if final_distance > MOVEMENT_ARRIVAL_THRESHOLD
              @character.position = final_target
            end
          end
          stop_movement
          return
        end

        # Update for next waypoint
        invalidate_direction_cache
        next_waypoint = path[@current_path_index]
        update_direction_and_animation(next_waypoint)
      end

      private def apply_movement(new_position : RL::Vector2, target : RL::Vector2)
        # Check walkable area constraints
        if scene = get_current_scene
          if scene.is_walkable?(new_position)
            @character.position = new_position
            update_character_scale_if_needed
          else
            # Try to constrain movement to walkable area
            constrained_pos = scene.walkable_area.try(&.constrain_to_walkable(@character.position, new_position))
            if constrained_pos
              @character.position = constrained_pos
              update_character_scale_if_needed
            end
          end
        else
          # No scene constraints, move freely
          @character.position = new_position
        end

        # Update sprite position
        @character.sprite_data.try(&.position = @character.position)
      end

      private def update_character_scale_if_needed
        # Only update scale if no manual scale is set
        return unless @character.manual_scale.nil?

        if scene = get_current_scene
          @character.scale = scene.get_character_scale(@character.position.y)
        end
      end

      private def get_direction_and_distance(target : RL::Vector2) : {RL::Vector2, Float32}
        # Use cached values if still valid
        if @direction_cache_valid && (cached_dir = @cached_direction) && (cached_dist = @cached_distance)
          return {cached_dir, cached_dist}
        end

        # Calculate and cache new values
        direction, distance = Utils::VectorMath.direction_and_distance(@character.position, target)
        @cached_direction = direction
        @cached_distance = distance
        @direction_cache_valid = true

        {direction, distance}
      end

      private def invalidate_direction_cache
        @direction_cache_valid = false
        @cached_direction = nil
        @cached_distance = nil
      end

      private def update_direction_and_animation(target : RL::Vector2)
        # Only update if we're moving a significant distance horizontally
        horizontal_distance = (target.x - @character.position.x).abs
        return if horizontal_distance < 5.0

        # Determine new direction
        new_direction = target.x < @character.position.x ? Direction::Left : Direction::Right

        # Update character direction and animation if changed or not walking
        if new_direction != @character.direction || !@character.current_animation.starts_with?("walk")
          @character.direction = new_direction
          play_walking_animation(new_direction)
        end
      end

      private def play_walking_animation(direction : Direction)
        animation_name = case direction
                         when .left?  then "walk_left"
                         when .right? then "walk_right"
                         when .up?    then "walk_up"
                         when .down?  then "walk_down"
                         else              "walk_right" # Default fallback
                         end

        @character.play_animation(animation_name) if @character.animations.has_key?(animation_name)
      end

      private def play_idle_animation
        base_idle = @character.direction == Direction::Left ? "idle_left" : "idle_right"

        if @character.animations.has_key?(base_idle)
          @character.play_animation(base_idle)
        elsif @character.animations.has_key?("idle")
          @character.play_animation("idle")
        end
      end

      private def setup_pathfinding(waypoints : Array(RL::Vector2))
        @path = waypoints
        @current_path_index = 0
        invalidate_direction_cache

        # Set initial direction based on first waypoint
        if waypoints.size > 0
          update_direction_and_animation(waypoints[0])
        end
      end

      private def clear_pathfinding_data
        @path = nil
        @current_path_index = 0
      end

      private def get_current_scene : Scenes::Scene?
        Core::Engine.instance.current_scene
      rescue
        nil
      end
    end
  end
end
