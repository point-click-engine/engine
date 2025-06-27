# Camera management system for the Point & Click Engine
#
# Centralizes camera handling, effects, and transitions.
# Provides a unified interface for all camera operations and supports
# advanced effects like shake, zoom, pan, sway, and smooth following.

require "raylib-cr"
require "./error_handling"
require "./interfaces"
require "../graphics/camera"
require "../characters/character"
require "./camera_effects/camera_enums"
require "./camera_effects/camera_state"
require "./camera_effects/camera_effect"
require "./camera_effects/shake_effect"
require "./camera_effects/zoom_effect"
require "./camera_effects/sway_effect"
require "./camera_effects/rotation_effect"
require "./camera_effects/pan_effect"
require "./camera_effects/follow_effect"

module PointClickEngine
  module Core
    # Manages all camera operations including multiple cameras and effects
    #
    # The CameraManager provides a centralized system for camera control,
    # supporting multiple named cameras, smooth transitions, and stackable effects.
    #
    # ## Features
    # - Multiple named cameras
    # - Smooth transitions between cameras
    # - Stackable effects (shake, zoom, pan, follow, sway)
    # - Camera state persistence
    # - Scene bounds management
    # - Coordinate transformation
    #
    # ## Usage
    # ```
    # manager = CameraManager.new(1024, 768)
    # manager.apply_effect(:shake, intensity: 10.0f32, duration: 1.0f32)
    # manager.apply_effect(:zoom, target: 2.0f32, duration: 2.0f32)
    # manager.update(dt, mouse_x, mouse_y)
    # ```
    class CameraManager
      include ErrorHelpers
      include GameConstants
      include ICameraManager

      # Viewport dimensions
      getter viewport_width : Int32
      getter viewport_height : Int32

      # Currently active camera
      getter current_camera : Graphics::Camera

      # Name of the active camera
      getter active_camera_name : String = "main"

      # All available cameras
      getter cameras : Hash(String, Graphics::Camera) = {} of String => Graphics::Camera

      # Active effects
      getter active_effects : Array(CameraEffect) = [] of CameraEffect

      # Camera transition state
      getter transition_start_camera : Graphics::Camera?
      getter transition_target_camera : Graphics::Camera?
      getter transition_duration : Float32 = 0.0f32
      getter transition_elapsed : Float32 = 0.0f32
      getter transition_easing : CameraEasing = CameraEasing::EaseInOut

      # Effect-specific state
      @base_position : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      @base_zoom : Float32 = 1.0f32
      @base_rotation : Float32 = 0.0f32
      @effect_offset : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      @effect_zoom : Float32 = 1.0f32
      @effect_rotation : Float32 = 0.0f32

      def initialize(@viewport_width : Int32, @viewport_height : Int32)
        # Create default main camera
        @current_camera = Graphics::Camera.new(@viewport_width, @viewport_height)
        @cameras["main"] = @current_camera
      end

      # Add a new camera
      def add_camera(name : String, camera : Graphics::Camera) : Result(Nil, CameraError)
        if @cameras.has_key?(name)
          return Result(Nil, CameraError).failure(
            CameraError.new("Camera '#{name}' already exists")
          )
        end

        @cameras[name] = camera
        Result(Nil, CameraError).success(nil)
      end

      # Switch to a different camera
      def switch_camera(name : String, transition_duration : Float32 = 0.0f32, easing : CameraEasing = CameraEasing::EaseInOut) : Result(Nil, CameraError)
        unless @cameras.has_key?(name)
          return Result(Nil, CameraError).failure(
            CameraError.new("Camera '#{name}' not found")
          )
        end

        target_camera = @cameras[name]

        if transition_duration > 0
          # Set up smooth transition
          @transition_start_camera = @current_camera
          @transition_target_camera = target_camera
          @transition_duration = transition_duration
          @transition_elapsed = 0.0f32
          @transition_easing = easing
        else
          # Instant switch
          @current_camera = target_camera
          @active_camera_name = name
        end

        Result(Nil, CameraError).success(nil)
      end

      # Get a camera by name
      def get_camera(name : String) : Graphics::Camera?
        @cameras[name]?
      end

      # Remove a camera (cannot remove active camera)
      def remove_camera(name : String) : Result(Nil, CameraError)
        if name == @active_camera_name
          return Result(Nil, CameraError).failure(
            CameraError.new("Cannot remove active camera")
          )
        end

        if name == "main"
          return Result(Nil, CameraError).failure(
            CameraError.new("Cannot remove main camera")
          )
        end

        @cameras.delete(name)
        Result(Nil, CameraError).success(nil)
      end

      # Apply a camera effect
      def apply_effect(type : Symbol, **params)
        effect_type = case type
                      when :shake    then CameraEffectType::Shake
                      when :zoom     then CameraEffectType::Zoom
                      when :pan      then CameraEffectType::Pan
                      when :follow   then CameraEffectType::Follow
                      when :sway     then CameraEffectType::Sway
                      when :rotation then CameraEffectType::Rotation
                      else
                        # Unknown effect type, ignore
                        return
                      end

        # Convert params to proper hash
        effect_params = {} of String => Float32 | Characters::Character | Bool
        params.each do |key, value|
          case value
          when Float32
            effect_params[key.to_s] = value
          when Characters::Character
            effect_params[key.to_s] = value
          when Bool
            effect_params[key.to_s] = value
          when Number
            effect_params[key.to_s] = value.to_f32
          end
        end

        # Handle single-instance effects (zoom, follow, pan)
        case effect_type
        when .zoom?, .follow?, .pan?
          remove_effect(type)
        end

        duration = effect_params["duration"]?.as?(Float32) || 0.0f32
        
        # Create specific effect instances
        effect = case type
        when :shake
          intensity = effect_params["intensity"]?.as?(Float32) || 10.0f32
          frequency = effect_params["frequency"]?.as?(Float32) || 10.0f32
          ShakeEffect.new(intensity, frequency, duration)
        when :zoom
          target = effect_params["target"]?.as?(Float32) || effect_params["factor"]?.as?(Float32) || 1.0f32
          ZoomEffect.new(target, duration)
        when :sway
          amplitude = effect_params["amplitude"]?.as?(Float32) || 20.0f32
          frequency = effect_params["frequency"]?.as?(Float32) || 0.5f32
          vertical_factor = effect_params["vertical_factor"]?.as?(Float32) || 0.5f32
          rotation_amplitude = effect_params["rotation_amplitude"]?.as?(Float32) || 2.0f32
          SwayEffect.new(amplitude, frequency, vertical_factor, rotation_amplitude, duration)
        when :rotation
          target = effect_params["target"]?.as?(Float32) || 0.0f32
          RotationEffect.new(target, duration)
        when :pan
          target_x = effect_params["target_x"]?.as?(Float32) || @current_camera.position.x
          target_y = effect_params["target_y"]?.as?(Float32) || @current_camera.position.y
          PanEffect.new(target_x, target_y, duration)
        when :follow
          target = effect_params["target"]?.as?(Characters::Character)
          return unless target  # Can't create follow effect without target
          smooth = effect_params["smooth"]?.as?(Bool) || true
          deadzone = effect_params["deadzone"]?.as?(Float32) || 50.0f32
          speed = effect_params["speed"]?.as?(Float32) || 5.0f32
          FollowEffect.new(target, smooth, deadzone, speed, duration)
        else
          CameraEffect.new(effect_type, duration, effect_params)
        end
        
        @active_effects << effect
      end

      # Remove effects of a specific type
      def remove_effect(type : Symbol)
        effect_type = case type
                      when :shake    then CameraEffectType::Shake
                      when :zoom     then CameraEffectType::Zoom
                      when :pan      then CameraEffectType::Pan
                      when :follow   then CameraEffectType::Follow
                      when :sway     then CameraEffectType::Sway
                      when :rotation then CameraEffectType::Rotation
                      else                return
                      end

        @active_effects.reject! { |effect| effect.type == effect_type }
      end

      # Remove all active effects
      def remove_all_effects
        @active_effects.clear
        @effect_offset = RL::Vector2.new(x: 0, y: 0)
        @effect_zoom = 1.0f32
        @effect_rotation = 0.0f32
      end

      # Reset all effects with smooth transition
      def reset_effects(duration : Float32 = 1.0f32)
        # Check if we need to transition zoom back
        needs_zoom_reset = @effect_zoom != 1.0f32 || has_effect?(:zoom)

        # Remove all current effects
        @active_effects.clear

        # If we had zoom effect, smoothly transition back
        if needs_zoom_reset
          apply_effect(:zoom, factor: 1.0f32, duration: duration)
        end

        # Note: Other effects like shake, sway naturally fade out when removed
        # Pan and follow effects are also removed by clearing active_effects
      end

      # Check if a specific effect is active
      def has_effect?(type : Symbol) : Bool
        effect_type = case type
                      when :shake    then CameraEffectType::Shake
                      when :zoom     then CameraEffectType::Zoom
                      when :pan      then CameraEffectType::Pan
                      when :follow   then CameraEffectType::Follow
                      when :sway     then CameraEffectType::Sway
                      when :rotation then CameraEffectType::Rotation
                      else                return false
                      end

        @active_effects.any? { |effect| effect.type == effect_type }
      end

      # Check if transitioning between cameras
      def is_transitioning? : Bool
        !@transition_target_camera.nil? && @transition_elapsed < @transition_duration
      end

      # Update camera and effects
      def update(dt : Float32, mouse_x : Int32, mouse_y : Int32)
        # Update camera transition
        update_transition(dt)

        # Store base camera state only when we don't have active effects
        # This ensures the base position is the "resting" position without effects
        if @active_effects.empty?
          @base_position = @current_camera.position.dup
          @base_zoom = @current_camera.zoom
          @base_rotation = @current_camera.rotation
        end

        # Reset effect accumulation
        @effect_offset = RL::Vector2.new(x: 0, y: 0)
        @effect_zoom = 1.0f32
        @effect_rotation = 0.0f32

        # Update and apply effects
        update_effects(dt)

        # Apply accumulated effects to camera
        apply_effects_to_camera

        # Don't update the underlying camera - we're managing everything here
        # @current_camera.update(dt, mouse_x, mouse_y)
      end

      # Set scene bounds for all cameras
      def set_scene_bounds(width : Int32, height : Int32)
        @cameras.each_value do |camera|
          camera.set_scene_size(width, height)
        end
      end

      # Transform world position to screen position (with effects)
      def transform_position(world_pos : RL::Vector2) : RL::Vector2
        # Apply camera position offset
        screen_x = world_pos.x - @current_camera.position.x - @effect_offset.x
        screen_y = world_pos.y - @current_camera.position.y - @effect_offset.y

        # Apply zoom if available
        total_zoom = @current_camera.zoom * @effect_zoom
        if total_zoom != 1.0f32
          # Center of screen for zoom
          center_x = @viewport_width / 2.0f32
          center_y = @viewport_height / 2.0f32

          # Apply zoom relative to center
          screen_x = center_x + (screen_x - center_x) * total_zoom
          screen_y = center_y + (screen_y - center_y) * total_zoom
        end

        # Apply rotation if needed (future enhancement)

        RL::Vector2.new(x: screen_x, y: screen_y)
      end

      # Convert screen coordinates to world coordinates
      def screen_to_world(screen_pos : RL::Vector2) : RL::Vector2
        total_zoom = @base_zoom * @effect_zoom

        world_x = screen_pos.x
        world_y = screen_pos.y

        # Reverse zoom transformation
        if total_zoom != 1.0f32
          center_x = @viewport_width / 2.0f32
          center_y = @viewport_height / 2.0f32

          world_x = center_x + (screen_pos.x - center_x) / total_zoom
          world_y = center_y + (screen_pos.y - center_y) / total_zoom
        end

        # Add camera offset
        world_x += @current_camera.position.x + @effect_offset.x
        world_y += @current_camera.position.y + @effect_offset.y

        RL::Vector2.new(x: world_x, y: world_y)
      end

      # Check if a world position is visible
      def is_visible?(world_pos : RL::Vector2, margin : Float32 = 0.0f32) : Bool
        screen_pos = transform_position(world_pos)
        screen_pos.x >= -margin && screen_pos.x <= @viewport_width + margin &&
          screen_pos.y >= -margin && screen_pos.y <= @viewport_height + margin
      end

      # Center camera on a position
      def center_on(x : Float32, y : Float32)
        @current_camera.center_on(x, y)
      end

      # Get the visible area in world coordinates
      def get_visible_area : RL::Rectangle
        # Account for zoom in visible area calculation
        total_zoom = @base_zoom * @effect_zoom
        width = @viewport_width / total_zoom
        height = @viewport_height / total_zoom

        RL::Rectangle.new(
          x: @current_camera.position.x + @effect_offset.x,
          y: @current_camera.position.y + @effect_offset.y,
          width: width,
          height: height
        )
      end

      # Save current camera state
      def save_state : CameraState
        CameraState.new(
          position: @current_camera.position.dup,
          zoom: @base_zoom,
          rotation: @base_rotation,
          active_camera: @active_camera_name
        )
      end

      # Restore camera state
      def restore_state(state : CameraState)
        if camera = @cameras[state.active_camera]?
          @current_camera = camera
          @active_camera_name = state.active_camera
        end

        @current_camera.position = state.position.dup
        @current_camera.zoom = state.zoom
        @current_camera.rotation = state.rotation
        @base_zoom = state.zoom
        @base_rotation = state.rotation
      end

      # Get current total zoom (base + effects)
      def total_zoom : Float32
        @current_camera.zoom * @effect_zoom
      end

      # Get current total rotation (base + effects)
      def total_rotation : Float32
        @base_rotation + @effect_rotation
      end

      private def update_transition(dt : Float32)
        return unless target = @transition_target_camera
        return unless start = @transition_start_camera

        @transition_elapsed += dt

        if @transition_elapsed >= @transition_duration
          # Transition complete
          @current_camera = target
          @active_camera_name = @cameras.key_for(target).not_nil!
          @transition_target_camera = nil
          @transition_start_camera = nil
        else
          # Interpolate camera properties
          t = @transition_elapsed / @transition_duration
          eased_t = apply_easing(t, @transition_easing)

          # Interpolate position
          @current_camera.position = RL::Vector2.new(
            x: start.position.x + (target.position.x - start.position.x) * eased_t,
            y: start.position.y + (target.position.y - start.position.y) * eased_t
          )
        end
      end

      private def update_effects(dt : Float32)
        # Update all effects and remove expired ones
        @active_effects.reject! do |effect|
          effect.update(dt)
          should_remove = !effect.active?
          if should_remove
            puts "[CameraManager] Removing expired effect: #{effect.type}"
          end
          should_remove
        end

        # Apply each active effect
        @active_effects.each do |effect|
          apply_effect(effect)
        end
      end

      private def apply_effect(effect : CameraEffect)
        case effect.type
        when .shake?
          apply_shake_effect(effect)
        when .zoom?
          apply_zoom_effect(effect)
        when .pan?
          apply_pan_effect(effect)
        when .follow?
          apply_follow_effect(effect)
        when .sway?
          apply_sway_effect(effect)
        when .rotation?
          apply_rotation_effect(effect)
        end
      end

      private def apply_shake_effect(effect : CameraEffect)
        # If it's a ShakeEffect instance, use its method
        if effect.is_a?(ShakeEffect)
          shake_offset = effect.calculate_shake_offset
          @effect_offset.x += shake_offset.x
          @effect_offset.y += shake_offset.y
        else
          # Fallback to original logic for backward compatibility
          intensity = effect.parameters["intensity"]?.as?(Float32) || 10.0f32
          frequency = effect.parameters["frequency"]?.as?(Float32) || 10.0f32

          # Decay intensity over time
          current_intensity = intensity * (1.0f32 - effect.progress)

          # Generate shake offset
          time_factor = effect.elapsed * frequency
          offset_x = Math.sin(time_factor * 2.1f32) * current_intensity * (Random.rand - 0.5f32) * 2
          offset_y = Math.cos(time_factor * 1.7f32) * current_intensity * (Random.rand - 0.5f32) * 2

          @effect_offset.x += offset_x.to_f32
          @effect_offset.y += offset_y.to_f32
        end
      end

      private def apply_zoom_effect(effect : CameraEffect)
        if effect.is_a?(ZoomEffect)
          @effect_zoom = effect.calculate_zoom_factor
        else
          # Fallback to original logic for backward compatibility
          # Support both "target" and "factor" parameter names
          target = effect.parameters["target"]?.as?(Float32) ||
                   effect.parameters["factor"]?.as?(Float32) || 1.0f32

          # Interpolate zoom
          t = effect.progress
          eased_t = apply_easing(t, CameraEasing::EaseInOut)

          @effect_zoom = 1.0f32 + (target - 1.0f32) * eased_t
        end
      end

      private def apply_pan_effect(effect : CameraEffect)
        if effect.is_a?(PanEffect)
          @current_camera.position = effect.calculate_position(@current_camera.position)
        else
          # Fallback to original logic for backward compatibility
          target_x = effect.parameters["target_x"]?.as?(Float32) || @current_camera.position.x
          target_y = effect.parameters["target_y"]?.as?(Float32) || @current_camera.position.y

          # Store starting position on first application
          unless effect.parameters.has_key?("start_x")
            effect.parameters["start_x"] = @current_camera.position.x
            effect.parameters["start_y"] = @current_camera.position.y
          end

          start_x = effect.parameters["start_x"]?.as?(Float32) || @current_camera.position.x
          start_y = effect.parameters["start_y"]?.as?(Float32) || @current_camera.position.y

          # Interpolate position
          t = effect.progress
          eased_t = apply_easing(t, CameraEasing::EaseInOut)

          new_x = start_x + (target_x - start_x) * eased_t
          new_y = start_y + (target_y - start_y) * eased_t

          @current_camera.position = RL::Vector2.new(x: new_x, y: new_y)
        end
      end

      private def apply_follow_effect(effect : CameraEffect)
        if effect.is_a?(FollowEffect)
          delta = effect.calculate_follow_delta(@current_camera.position, @viewport_width, @viewport_height)
          @current_camera.position.x += delta.x
          @current_camera.position.y += delta.y
        else
          # Fallback to original logic for backward compatibility
          return unless target = effect.parameters["target"]?.as?(Characters::Character)

          smooth = effect.parameters["smooth"]?.as?(Bool) || true
          deadzone = effect.parameters["deadzone"]?.as?(Float32) || 50.0f32
          speed = effect.parameters["speed"]?.as?(Float32) || 5.0f32

          target_pos = target.position
          center_x = target_pos.x - @viewport_width / 2
          center_y = target_pos.y - @viewport_height / 2

          if smooth
            # Smooth following with deadzone
            distance = Math.sqrt(
              (center_x - @current_camera.position.x)**2 +
              (center_y - @current_camera.position.y)**2
            )

            if distance > deadzone
              # Move towards target
              direction_x = (center_x - @current_camera.position.x) / distance
              direction_y = (center_y - @current_camera.position.y) / distance

              move_distance = speed * 0.016f32 * (distance - deadzone)

              @current_camera.position.x += direction_x * move_distance
              @current_camera.position.y += direction_y * move_distance
            end
          else
            # Instant following
            @current_camera.position = RL::Vector2.new(x: center_x, y: center_y)
          end
        end
      end

      private def apply_sway_effect(effect : CameraEffect)
        if effect.is_a?(SwayEffect)
          offset, rotation = effect.calculate_sway
          @effect_offset.x += offset.x
          @effect_offset.y += offset.y
          @effect_rotation += rotation
        else
          # Fallback to original logic for backward compatibility
          amplitude = effect.parameters["amplitude"]?.as?(Float32) || 20.0f32
          frequency = effect.parameters["frequency"]?.as?(Float32) || 0.5f32
          vertical_factor = effect.parameters["vertical_factor"]?.as?(Float32) || 0.5f32

          # Create wave motion
          time = effect.elapsed * frequency

          # Horizontal sway (main motion)
          sway_x = Math.sin(time) * amplitude

          # Vertical sway (secondary motion, like boat rocking)
          sway_y = Math.sin(time * 2.1f32) * amplitude * vertical_factor

          @effect_offset.x += sway_x.to_f32
          @effect_offset.y += sway_y.to_f32

          # Optional: Add slight rotation for more realistic boat effect
          rotation_amplitude = effect.parameters["rotation_amplitude"]?.as?(Float32) || 2.0f32
          @effect_rotation += (Math.sin(time * 0.7f32) * rotation_amplitude).to_f32
        end
      end

      private def apply_rotation_effect(effect : CameraEffect)
        if effect.is_a?(RotationEffect)
          @effect_rotation = effect.calculate_rotation
        else
          # Fallback to original logic for backward compatibility
          target = effect.parameters["target"]?.as?(Float32) || 0.0f32

          # Interpolate rotation
          t = effect.progress
          eased_t = apply_easing(t, CameraEasing::EaseInOut)

          @effect_rotation = target * eased_t
        end
      end

      private def apply_effects_to_camera
        # Apply position offset
        @current_camera.position.x = @base_position.x + @effect_offset.x
        @current_camera.position.y = @base_position.y + @effect_offset.y

        # Apply constraints when no effects are active
        if @active_effects.empty?
          # Ensure we reset to base position when no effects
          max_x = Math.max(0.0f32, (@current_camera.scene_width - @current_camera.viewport_width).to_f32)
          max_y = Math.max(0.0f32, (@current_camera.scene_height - @current_camera.viewport_height).to_f32)
          @current_camera.position.x = @base_position.x.clamp(0.0f32, max_x)
          @current_camera.position.y = @base_position.y.clamp(0.0f32, max_y)
        end

        # Note: zoom and rotation would need to be added to Camera class
        # For now, we store them internally and use them in transform_position
      end

      private def apply_easing(t : Float32, easing : CameraEasing) : Float32
        case easing
        when .linear?
          t
        when .ease_in?
          t * t
        when .ease_out?
          1.0f32 - (1.0f32 - t) * (1.0f32 - t)
        when .ease_in_out?
          if t < 0.5f32
            2.0f32 * t * t
          else
            1.0f32 - 2.0f32 * (1.0f32 - t) * (1.0f32 - t)
          end
        when .bounce?
          if t < 1.0f32 / 2.75f32
            7.5625f32 * t * t
          elsif t < 2.0f32 / 2.75f32
            t -= 1.5f32 / 2.75f32
            7.5625f32 * t * t + 0.75f32
          elsif t < 2.5f32 / 2.75f32
            t -= 2.25f32 / 2.75f32
            7.5625f32 * t * t + 0.9375f32
          else
            t -= 2.625f32 / 2.75f32
            7.5625f32 * t * t + 0.984375f32
          end
        when .elastic?
          if t == 0.0f32 || t == 1.0f32
            t
          else
            p = 0.3f32
            s = p / 4.0f32
            (Math.sin((t - s) * 2.0f32 * Math::PI / p) * 2.0f32**(10.0f32 * (t - 1.0f32))).to_f32
          end
        else
          t
        end
      end
    end

    # Camera-related error
    class CameraError < LoadingError
      def initialize(message : String, cause : Exception? = nil)
        super("Camera error: #{message}")
      end
    end
  end
end
