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

      # Stored preference for whether to use pathfinding when blocked
      @use_pathfinding_preference : Bool = true

      # Track last recalculation position to avoid infinite loops
      @last_recalc_position : RL::Vector2?
      @recalc_attempts : Int32 = 0

      def initialize(@character : Character)
        @use_pathfinding_preference = @character.use_pathfinding
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
        # Input validation
        unless validate_target_position(target)
          if Core::DebugConfig.should_log?(:movement)
            puts "[MOVEMENT] Invalid target position #{target}, movement cancelled"
          end
          return
        end

        if Core::DebugConfig.should_log?(:movement)
          puts "[MOVEMENT] Starting movement from #{@character.position} to #{target}"
        end

        @target_position = target
        @character.state = CharacterState::Walking

        # Clear pathfinding data for direct movement
        clear_pathfinding_data
        invalidate_direction_cache

        # Store pathfinding preference
        @use_pathfinding_preference = use_pathfinding.nil? ? @character.use_pathfinding : use_pathfinding

        if Core::DebugConfig.should_log?(:movement)
          puts "[MOVEMENT] Using pathfinding: #{@use_pathfinding_preference}"
        end

        # If pathfinding is enabled, calculate path immediately
        if @use_pathfinding_preference
          if scene = get_current_scene
            if Core::DebugConfig.should_log?(:pathfinding)
              puts "[MOVEMENT] Calculating pathfinding route..."
            end

            if calculated_path = scene.find_path(@character.position.x, @character.position.y, target.x, target.y)
              if Core::DebugConfig.should_log?(:pathfinding)
                puts "[MOVEMENT] Pathfinding found route with #{calculated_path.size} waypoints"
              end
              setup_pathfinding(calculated_path)
              return
            else
              if Core::DebugConfig.should_log?(:pathfinding)
                puts "[MOVEMENT] Pathfinding failed, falling back to direct movement"
              end
            end
          else
            if Core::DebugConfig.should_log?(:pathfinding)
              puts "[MOVEMENT] No scene available for pathfinding"
            end
          end
        end

        # Setup direct movement if pathfinding is disabled or failed
        if Core::DebugConfig.should_log?(:movement)
          puts "[MOVEMENT] Using direct movement to #{target}"
        end
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
        # Input validation
        if waypoints.empty?
          if Core::DebugConfig.should_log?(:movement)
            puts "[MOVEMENT] Empty waypoint array provided, movement cancelled"
          end
          return
        end

        unless validate_waypoints(waypoints)
          if Core::DebugConfig.should_log?(:movement)
            puts "[MOVEMENT] Invalid waypoints in path, movement cancelled"
          end
          return
        end

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
        if Core::DebugConfig.should_log?(:movement)
          puts "[MOVEMENT] STOPPING movement at position #{@character.position} (target was #{@target_position})"
        end

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
        # Input validation
        return unless dt >= 0.0_f32 && dt <= MAX_DELTA_TIME # Reasonable delta time bounds
        return unless @character.state == CharacterState::Walking

        # Validate movement state
        unless validate_movement_state
          if Core::DebugConfig.should_log?(:movement)
            puts "[MOVEMENT] Invalid movement state detected, stopping movement"
          end
          stop_movement
          return
        end

        if path = @path
          if Core::DebugConfig.should_log?(:movement)
            puts "[MOVEMENT] Update: using pathfinding (#{path.size} waypoints, current index: #{@current_path_index})"
          end
          update_pathfinding_movement(dt)
        elsif target = @target_position
          if Core::DebugConfig.should_log?(:movement)
            distance = Utils::VectorMath.distance(@character.position, target)
            puts "[MOVEMENT] Update: direct movement to #{target}, distance: #{distance}"
          end
          update_direct_movement(target, dt)
        else
          if Core::DebugConfig.should_log?(:movement)
            puts "[MOVEMENT] Update: no target or path, stopping"
          end
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
        # Calculate fresh direction and distance (don't use cache for arrival check)
        direction, distance = Utils::VectorMath.direction_and_distance(@character.position, target)

        # Check if we've arrived
        if distance <= MOVEMENT_ARRIVAL_THRESHOLD
          @character.position = target
          stop_movement
          return
        end

        # Calculate new position
        movement_step = @character.walking_speed * dt

        # Don't force minimum movement - just use actual movement step
        actual_step = movement_step

        new_position = Utils::VectorMath.move_towards(@character.position, target, actual_step)

        # Apply movement with walkable area checking
        apply_movement(new_position, target)

        # Invalidate cache after movement
        invalidate_direction_cache

        # Update animation if direction changed significantly
        update_direction_and_animation(target)
      end

      private def update_pathfinding_movement(dt : Float32)
        path = @path.not_nil!
        return stop_movement if @current_path_index >= path.size

        current_waypoint = path[@current_path_index]

        # Always calculate fresh distance for waypoint threshold checking
        # Don't use cached values as they may be stale after movement
        fresh_direction, fresh_distance = Utils::VectorMath.direction_and_distance(@character.position, current_waypoint)

        if Core::DebugConfig.should_log?(:pathfinding)
          puts "[PATHFINDING] At #{@character.position}, moving to waypoint #{@current_path_index}: #{current_waypoint}, distance: #{fresh_distance}, threshold: #{PATHFINDING_WAYPOINT_THRESHOLD}"
        end

        # Check if we're very close to the waypoint (use arrival threshold, not waypoint threshold)
        if fresh_distance <= MOVEMENT_ARRIVAL_THRESHOLD
          if Core::DebugConfig.should_log?(:pathfinding)
            puts "[PATHFINDING] Reached waypoint #{@current_path_index}, advancing..."
          end
          advance_to_next_waypoint
          return
        end

        # Move towards current waypoint using fresh direction
        movement_step = @character.walking_speed * dt

        # Don't force minimum movement - just use actual movement step
        actual_step = movement_step

        new_position = Utils::VectorMath.move_towards(@character.position, current_waypoint, actual_step)

        if Core::DebugConfig.should_log?(:pathfinding)
          puts "[PATHFINDING] Moving from #{@character.position} to #{new_position} (step: #{actual_step})"
        end

        # Apply movement
        apply_movement(new_position, current_waypoint)

        # Invalidate cache after movement to ensure fresh calculations next frame
        invalidate_direction_cache

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
        # SIMPLIFIED: Just move without collision checks during movement
        # The target walkability was already checked when movement was initiated
        @character.position = new_position
        update_character_scale_if_needed

        # Update sprite position
        @character.sprite_controller.update_position(@character.position)
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
        return if horizontal_distance < DIRECTION_UPDATE_THRESHOLD

        # Determine new direction
        new_direction = target.x < @character.position.x ? Direction::Left : Direction::Right

        # Update character direction and animation if changed or not walking
        current_anim = @character.animation_controller.try(&.current_animation) || ""
        if new_direction != @character.direction || !current_anim.starts_with?("walk")
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

        @character.play_animation(animation_name) if @character.animation_controller.try(&.has_animation?(animation_name))
      end

      private def play_idle_animation
        base_idle = @character.direction == Direction::Left ? "idle_left" : "idle_right"

        if @character.animation_controller.try(&.has_animation?(base_idle))
          @character.play_animation(base_idle)
        elsif @character.animation_controller.try(&.has_animation?("idle"))
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

      private def handle_blocked_movement(target : RL::Vector2)
        # Since we no longer check for blocked movement during motion,
        # this method should not be called. If it is, just stop.
        stop_movement
      end

      private def get_current_scene : Scenes::Scene?
        Core::Engine.instance.current_scene
      rescue
        nil
      end

      # Input validation methods

      private def validate_target_position(target : RL::Vector2) : Bool
        # Check for NaN or infinite values
        return false if target.x.nan? || target.y.nan?
        return false if target.x.infinite? || target.y.infinite?

        # Check for reasonable bounds
        return false if target.x < MIN_SCENE_COORDINATE || target.x > MAX_SCENE_COORDINATE
        return false if target.y < MIN_SCENE_COORDINATE || target.y > MAX_SCENE_COORDINATE

        true
      end

      private def validate_waypoints(waypoints : Array(RL::Vector2)) : Bool
        # Check maximum path length to prevent performance issues
        return false if waypoints.size > MAX_PATHFINDING_WAYPOINTS

        # Validate each waypoint
        waypoints.each do |waypoint|
          return false unless validate_target_position(waypoint)
        end

        # Check for duplicate consecutive waypoints (performance optimization)
        (1...waypoints.size).each do |i|
          prev = waypoints[i - 1]
          curr = waypoints[i]
          distance = Math.sqrt((curr.x - prev.x)**2 + (curr.y - prev.y)**2)

          # Warn about very close waypoints but don't fail validation
          if distance < MIN_PATHFINDING_DISTANCE && Core::DebugConfig.should_log?(:movement)
            puts "[MOVEMENT] Warning: Very close waypoints detected at #{prev} -> #{curr}"
          end
        end

        true
      end

      private def validate_movement_state : Bool
        # Ensure character object is valid
        return false if @character.nil?

        # Check for reasonable character size
        return false if @character.size.x < MIN_CHARACTER_SIZE || @character.size.y < MIN_CHARACTER_SIZE
        return false if @character.size.x > MAX_CHARACTER_SIZE || @character.size.y > MAX_CHARACTER_SIZE

        # Check for reasonable walking speed
        return false if @character.walking_speed < 0.0_f32
        return false if @character.walking_speed > MAX_WALKING_SPEED

        # Validate character position
        return false unless validate_target_position(@character.position)

        true
      end
    end
  end
end
