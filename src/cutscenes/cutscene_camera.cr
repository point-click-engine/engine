# Enhanced camera system for cinematic cutscenes
# Provides smooth camera movements, shaking, zooming, and target following

require "raylib-cr"
require "../characters/character"

module PointClickEngine
  module Cutscenes
    # Easing functions for smooth camera animations
    module EasingFunctions
      def self.ease_in_out_cubic(t : Float32) : Float32
        return 4 * t * t * t if t < 0.5f32
        p = 2 * t - 2
        1 + p * p * p / 2
      end
      
      def self.ease_out_quad(t : Float32) : Float32
        1 - (1 - t) * (1 - t)
      end
      
      def self.ease_in_quad(t : Float32) : Float32
        t * t
      end
      
      def self.ease_in_out_sine(t : Float32) : Float32
        (-(Math.cos(Math::PI * t) - 1) / 2).to_f32
      end
      
      def self.ease_out_bounce(t : Float32) : Float32
        if t < 1 / 2.75f32
          7.5625f32 * t * t
        elsif t < 2 / 2.75f32
          7.5625f32 * (t -= 1.5f32 / 2.75f32) * t + 0.75f32
        elsif t < 2.5f32 / 2.75f32
          7.5625f32 * (t -= 2.25f32 / 2.75f32) * t + 0.9375f32
        else
          7.5625f32 * (t -= 2.625f32 / 2.75f32) * t + 0.984375f32
        end
      end
    end
    
    # Camera transition modes
    enum CameraTransition
      Linear
      EaseInOut
      EaseIn
      EaseOut
      Bounce
      Sine
    end
    
    # Cinematic camera for cutscenes
    class CutsceneCamera
      property position : RL::Vector2
      property zoom : Float32 = 1.0f32
      property rotation : Float32 = 0.0f32
      property shake_intensity : Float32 = 0.0f32
      property target_character : Characters::Character?
      property offset : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      
      # Pan animation
      property pan_start : RL::Vector2?
      property pan_target : RL::Vector2?
      property pan_duration : Float32 = 0.0f32
      property pan_elapsed : Float32 = 0.0f32
      property pan_transition : CameraTransition = CameraTransition::EaseInOut
      property pan_active : Bool = false
      
      # Zoom animation
      property zoom_start : Float32?
      property zoom_target : Float32?
      property zoom_duration : Float32 = 0.0f32
      property zoom_elapsed : Float32 = 0.0f32
      property zoom_transition : CameraTransition = CameraTransition::EaseInOut
      property zoom_active : Bool = false
      
      # Shake effect
      property shake_duration : Float32 = 0.0f32
      property shake_elapsed : Float32 = 0.0f32
      property shake_offset : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      property shake_frequency : Float32 = 10.0f32
      property shake_active : Bool = false
      
      # Follow settings
      property follow_speed : Float32 = 2.0f32
      property follow_deadzone : Float32 = 50.0f32
      property follow_smooth : Bool = true
      
      # Screen bounds
      property screen_bounds : RL::Rectangle?
      property constrain_to_bounds : Bool = false
      
      def initialize(@position : RL::Vector2)
      end
      
      # Pan camera to target position with easing
      def pan_to(target_pos : RL::Vector2, duration : Float32, transition : CameraTransition = CameraTransition::EaseInOut)
        @pan_start = @position
        @pan_target = target_pos
        @pan_duration = duration
        @pan_elapsed = 0.0f32
        @pan_transition = transition
        @pan_active = true
        
        # Stop following character during pan
        @target_character = nil
      end
      
      # Zoom camera to target zoom level
      def zoom_to(target_zoom : Float32, duration : Float32, transition : CameraTransition = CameraTransition::EaseInOut)
        @zoom_start = @zoom
        @zoom_target = target_zoom
        @zoom_duration = duration
        @zoom_elapsed = 0.0f32
        @zoom_transition = transition
        @zoom_active = true
      end
      
      # Shake camera for impact effects
      def shake(intensity : Float32, duration : Float32, frequency : Float32 = 10.0f32)
        @shake_intensity = intensity
        @shake_duration = duration
        @shake_elapsed = 0.0f32
        @shake_frequency = frequency
        @shake_active = true
      end
      
      # Follow a character smoothly
      def follow(character : Characters::Character, smooth : Bool = true, deadzone : Float32 = 50.0f32)
        @target_character = character
        @follow_smooth = smooth
        @follow_deadzone = deadzone
        
        # Stop pan animation if following
        @pan_active = false
      end
      
      # Stop following character
      def stop_following
        @target_character = nil
      end
      
      # Set camera bounds to constrain movement
      def set_bounds(bounds : RL::Rectangle)
        @screen_bounds = bounds
        @constrain_to_bounds = true
      end
      
      # Remove camera bounds
      def remove_bounds
        @constrain_to_bounds = false
        @screen_bounds = nil
      end
      
      # Update camera animations and following
      def update(dt : Float32)
        # Update pan animation
        update_pan(dt)
        
        # Update zoom animation
        update_zoom(dt)
        
        # Update shake effect
        update_shake(dt)
        
        # Update character following
        update_follow(dt)
        
        # Apply bounds constraints
        apply_bounds_constraints
      end
      
      # Get final camera position (including shake)
      def get_final_position : RL::Vector2
        RL::Vector2.new(
          x: @position.x + @shake_offset.x + @offset.x,
          y: @position.y + @shake_offset.y + @offset.y
        )
      end
      
      # Get camera matrix for rendering
      def get_camera_matrix : RL::Matrix
        final_pos = get_final_position
        
        # Create camera transformation matrix
        RL.matrix_identity
          .matrix_translate(-final_pos.x, -final_pos.y, 0.0f32)
          .matrix_rotate_z(@rotation)
          .matrix_scale(@zoom, @zoom, 1.0f32)
      end
      
      # Convert screen coordinates to world coordinates
      def screen_to_world(screen_pos : RL::Vector2) : RL::Vector2
        final_pos = get_final_position
        
        # Apply inverse camera transformation
        world_x = (screen_pos.x / @zoom) + final_pos.x
        world_y = (screen_pos.y / @zoom) + final_pos.y
        
        RL::Vector2.new(x: world_x, y: world_y)
      end
      
      # Convert world coordinates to screen coordinates
      def world_to_screen(world_pos : RL::Vector2) : RL::Vector2
        final_pos = get_final_position
        
        # Apply camera transformation
        screen_x = (world_pos.x - final_pos.x) * @zoom
        screen_y = (world_pos.y - final_pos.y) * @zoom
        
        RL::Vector2.new(x: screen_x, y: screen_y)
      end
      
      # Check if camera is animating
      def is_animating? : Bool
        @pan_active || @zoom_active || @shake_active
      end
      
      # Stop all animations
      def stop_all_animations
        @pan_active = false
        @zoom_active = false
        @shake_active = false
        @shake_offset = RL::Vector2.new(x: 0, y: 0)
      end
      
      # Reset camera to default state
      def reset
        stop_all_animations
        @target_character = nil
        @zoom = 1.0f32
        @rotation = 0.0f32
        @offset = RL::Vector2.new(x: 0, y: 0)
      end
      
      private def update_pan(dt : Float32)
        return unless @pan_active
        return unless @pan_start && @pan_target
        
        @pan_elapsed += dt
        
        if @pan_elapsed >= @pan_duration
          # Pan complete
          @position = @pan_target.not_nil!
          @pan_active = false
        else
          # Interpolate position
          t = @pan_elapsed / @pan_duration
          eased_t = apply_easing(t, @pan_transition)
          
          start_pos = @pan_start.not_nil!
          target_pos = @pan_target.not_nil!
          
          @position = RL::Vector2.new(
            x: start_pos.x + (target_pos.x - start_pos.x) * eased_t,
            y: start_pos.y + (target_pos.y - start_pos.y) * eased_t
          )
        end
      end
      
      private def update_zoom(dt : Float32)
        return unless @zoom_active
        return unless @zoom_start && @zoom_target
        
        @zoom_elapsed += dt
        
        if @zoom_elapsed >= @zoom_duration
          # Zoom complete
          @zoom = @zoom_target.not_nil!
          @zoom_active = false
        else
          # Interpolate zoom
          t = @zoom_elapsed / @zoom_duration
          eased_t = apply_easing(t, @zoom_transition)
          
          start_zoom = @zoom_start.not_nil!
          target_zoom = @zoom_target.not_nil!
          
          @zoom = start_zoom + (target_zoom - start_zoom) * eased_t
        end
      end
      
      private def update_shake(dt : Float32)
        return unless @shake_active
        
        @shake_elapsed += dt
        
        if @shake_elapsed >= @shake_duration
          # Shake complete
          @shake_active = false
          @shake_offset = RL::Vector2.new(x: 0, y: 0)
        else
          # Generate shake offset
          intensity = @shake_intensity * (1.0f32 - @shake_elapsed / @shake_duration)
          time_factor = @shake_elapsed * @shake_frequency
          
          offset_x = Math.sin(time_factor * 2.1f32) * intensity * (Random.rand - 0.5f32) * 2
          offset_y = Math.cos(time_factor * 1.7f32) * intensity * (Random.rand - 0.5f32) * 2
          
          @shake_offset = RL::Vector2.new(x: offset_x.to_f32, y: offset_y.to_f32)
        end
      end
      
      private def update_follow(dt : Float32)
        return unless character = @target_character
        return if @pan_active  # Don't follow during manual pan
        
        target_pos = character.position
        
        if @follow_smooth
          # Smooth following with deadzone
          distance = Math.sqrt((target_pos.x - @position.x)**2 + (target_pos.y - @position.y)**2)
          
          if distance > @follow_deadzone
            # Move towards character
            direction_x = (target_pos.x - @position.x) / distance
            direction_y = (target_pos.y - @position.y) / distance
            
            move_speed = @follow_speed * dt * (distance - @follow_deadzone)
            
            @position = RL::Vector2.new(
              x: @position.x + direction_x * move_speed,
              y: @position.y + direction_y * move_speed
            )
          end
        else
          # Instant following
          @position = target_pos
        end
      end
      
      private def apply_bounds_constraints
        return unless @constrain_to_bounds
        return unless bounds = @screen_bounds
        
        # Keep camera position within bounds
        @position = RL::Vector2.new(
          x: @position.x.clamp(bounds.x, bounds.x + bounds.width),
          y: @position.y.clamp(bounds.y, bounds.y + bounds.height)
        )
      end
      
      private def apply_easing(t : Float32, transition : CameraTransition) : Float32
        case transition
        when .linear?
          t
        when .ease_in_out?
          EasingFunctions.ease_in_out_cubic(t)
        when .ease_in?
          EasingFunctions.ease_in_quad(t)
        when .ease_out?
          EasingFunctions.ease_out_quad(t)
        when .bounce?
          EasingFunctions.ease_out_bounce(t)
        when .sine?
          EasingFunctions.ease_in_out_sine(t)
        else
          t
        end
      end
    end
  end
end