# Simple 2D camera for scrolling and view management

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Core
      # 2D camera for managing the view into the game world
      #
      # The Camera class provides basic 2D view management including position,
      # bounds checking, and smooth movement. It integrates with the effects
      # system for advanced camera behaviors.
      #
      # ## Example
      #
      # ```
      # camera = Camera.new
      # camera.set_bounds(0, 0, 2048, 1536)     # Large scrollable area
      # camera.position = Vector2.new(512, 384) # Look at specific position
      # ```
      class Camera
        # Camera position in world coordinates
        property position : RL::Vector2

        # Camera bounds (to keep camera within scene limits)
        property min_x : Float32 = 0.0f32
        property max_x : Float32 = 0.0f32
        property min_y : Float32 = 0.0f32
        property max_y : Float32 = 0.0f32

        # Smooth movement properties
        property smooth_enabled : Bool = true
        property smooth_speed : Float32 = 5.0f32

        # Target for smooth following
        @target_position : RL::Vector2?

        def initialize
          @position = RL::Vector2.new(x: 0, y: 0)
        end

        def initialize(x : Float32, y : Float32)
          @position = RL::Vector2.new(x: x, y: y)
        end

        # Set camera bounds based on scene size
        def set_bounds(scene_width : Int32, scene_height : Int32,
                       viewport_width : Int32 = Display::REFERENCE_WIDTH,
                       viewport_height : Int32 = Display::REFERENCE_HEIGHT)
          @max_x = Math.max(0.0f32, (scene_width - viewport_width).to_f32)
          @max_y = Math.max(0.0f32, (scene_height - viewport_height).to_f32)
          @min_x = 0.0f32
          @min_y = 0.0f32

          constrain_position
        end

        # Convenience method for setting scene size (calls set_bounds)
        def set_scene_size(scene_width : Int32, scene_height : Int32)
          set_bounds(scene_width, scene_height)
        end

        # Set camera bounds explicitly
        def set_bounds(min_x : Float32, min_y : Float32, max_x : Float32, max_y : Float32)
          @min_x = min_x
          @min_y = min_y
          @max_x = max_x
          @max_y = max_y

          constrain_position
        end

        # Move camera to position (instant or smooth based on settings)
        def move_to(x : Float32, y : Float32)
          if @smooth_enabled
            @target_position = RL::Vector2.new(x: x, y: y)
          else
            @position.x = x
            @position.y = y
            constrain_position
          end
        end

        # Move camera to position vector
        def move_to(target : RL::Vector2)
          move_to(target.x, target.y)
        end

        # Center camera on a world position
        def center_on(x : Float32, y : Float32,
                      viewport_width : Int32 = Display::REFERENCE_WIDTH,
                      viewport_height : Int32 = Display::REFERENCE_HEIGHT)
          move_to(
            x - viewport_width / 2,
            y - viewport_height / 2
          )
        end

        # Center camera on position vector
        def center_on(position : RL::Vector2)
          center_on(position.x, position.y)
        end

        # Update camera (for smooth movement)
        def update(dt : Float32)
          if target = @target_position
            # Smooth interpolation to target
            diff_x = target.x - @position.x
            diff_y = target.y - @position.y

            # If close enough, snap to target
            if Math.sqrt(diff_x * diff_x + diff_y * diff_y) < 1.0
              @position = target
              @target_position = nil
            else
              # Smooth movement
              @position.x += diff_x * @smooth_speed * dt
              @position.y += diff_y * @smooth_speed * dt
            end

            constrain_position
          end
        end

        # Get the visible area in world coordinates
        def visible_area(viewport_width : Int32 = Display::REFERENCE_WIDTH,
                         viewport_height : Int32 = Display::REFERENCE_HEIGHT) : RL::Rectangle
          RL::Rectangle.new(
            x: @position.x,
            y: @position.y,
            width: viewport_width.to_f32,
            height: viewport_height.to_f32
          )
        end

        # Check if a world position is visible
        def visible?(world_x : Float32, world_y : Float32, margin : Float32 = 0.0f32,
                     viewport_width : Int32 = Display::REFERENCE_WIDTH,
                     viewport_height : Int32 = Display::REFERENCE_HEIGHT) : Bool
          world_x >= @position.x - margin &&
            world_x <= @position.x + viewport_width + margin &&
            world_y >= @position.y - margin &&
            world_y <= @position.y + viewport_height + margin
        end

        # Check if a rectangle is visible
        def visible?(rect : RL::Rectangle, margin : Float32 = 0.0f32) : Bool
          view = visible_area

          rect.x + rect.width >= view.x - margin &&
            rect.x <= view.x + view.width + margin &&
            rect.y + rect.height >= view.y - margin &&
            rect.y <= view.y + view.height + margin
        end

        # Apply camera offset (utility for manual calculations)
        def apply_offset(world_x : Float32, world_y : Float32) : RL::Vector2
          RL::Vector2.new(
            x: world_x - @position.x,
            y: world_y - @position.y
          )
        end

        # Convert screen coordinates to world coordinates
        def screen_to_world(screen_x : Int32, screen_y : Int32) : RL::Vector2
          RL::Vector2.new(
            x: screen_x.to_f32 + @position.x,
            y: screen_y.to_f32 + @position.y
          )
        end

        # Convert world coordinates to screen coordinates
        def world_to_screen(world_x : Float32, world_y : Float32) : RL::Vector2
          RL::Vector2.new(
            x: world_x - @position.x,
            y: world_y - @position.y
          )
        end

        # Reset camera to origin
        def reset
          @position = RL::Vector2.new(x: 0, y: 0)
          @target_position = nil
        end

        # Shake the camera (trigger effect through effect system)
        # This is a convenience method that should integrate with effects
        def shake(intensity : Float32, duration : Float32)
          # This will be implemented when we create the effects system
          # For now, it's a placeholder for the API
        end

        private def constrain_position
          @position.x = @position.x.clamp(@min_x, @max_x)
          @position.y = @position.y.clamp(@min_y, @max_y)
        end
      end
    end
  end
end
