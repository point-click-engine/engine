# Main game camera system for scrolling scenes
# Provides viewport management, character following, and edge scrolling

require "../characters/character"

module PointClickEngine
  module Graphics
    # Main camera for game scenes with scrolling support
    class Camera
      property position : RL::Vector2
      property viewport_width : Int32
      property viewport_height : Int32
      property scene_width : Int32
      property scene_height : Int32
      property target_character : Characters::Character?
      property follow_speed : Float32 = 5.0f32
      property edge_scroll_margin : Int32 = 50
      property edge_scroll_speed : Float32 = 300.0f32
      property edge_scroll_enabled : Bool = true

      # Camera bounds (calculated from scene and viewport)
      property min_x : Float32 = 0.0f32
      property max_x : Float32 = 0.0f32
      property min_y : Float32 = 0.0f32
      property max_y : Float32 = 0.0f32

      def initialize(@viewport_width : Int32, @viewport_height : Int32)
        @position = RL::Vector2.new(x: 0, y: 0)
        @scene_width = @viewport_width
        @scene_height = @viewport_height
        update_bounds
      end

      # Set the scene dimensions (for scrolling bounds)
      def set_scene_size(width : Int32, height : Int32)
        @scene_width = width
        @scene_height = height
        update_bounds
        constrain_position
      end

      # Follow a character
      def follow(character : Characters::Character)
        @target_character = character
      end

      # Stop following
      def stop_following
        @target_character = nil
      end

      # Update camera position
      def update(dt : Float32, mouse_x : Int32, mouse_y : Int32)
        # Update character following
        if character = @target_character
          update_character_follow(character, dt)
        end

        # Update edge scrolling (only if not following a character)
        if @edge_scroll_enabled && !@target_character
          update_edge_scroll(mouse_x, mouse_y, dt)
        end

        # Constrain camera to scene bounds
        constrain_position
      end

      # Convert screen coordinates to world coordinates
      def screen_to_world(screen_x : Int32, screen_y : Int32) : RL::Vector2
        RL::Vector2.new(
          x: screen_x + @position.x,
          y: screen_y + @position.y
        )
      end

      # Convert world coordinates to screen coordinates
      def world_to_screen(world_x : Float32, world_y : Float32) : RL::Vector2
        RL::Vector2.new(
          x: world_x - @position.x,
          y: world_y - @position.y
        )
      end

      # Check if a world position is visible on screen
      def is_visible?(world_x : Float32, world_y : Float32, margin : Float32 = 0.0f32) : Bool
        screen_pos = world_to_screen(world_x, world_y)
        screen_pos.x >= -margin && screen_pos.x <= @viewport_width + margin &&
          screen_pos.y >= -margin && screen_pos.y <= @viewport_height + margin
      end

      # Center camera on a position
      def center_on(x : Float32, y : Float32)
        @position = RL::Vector2.new(
          x: x - @viewport_width / 2,
          y: y - @viewport_height / 2
        )
        constrain_position
      end

      # Get the visible area in world coordinates
      def get_visible_area : RL::Rectangle
        RL::Rectangle.new(
          x: @position.x,
          y: @position.y,
          width: @viewport_width.to_f32,
          height: @viewport_height.to_f32
        )
      end

      private def update_character_follow(character : Characters::Character, dt : Float32)
        # Calculate desired camera position to center on character
        target_x = character.position.x - @viewport_width / 2
        target_y = character.position.y - @viewport_height / 2

        # Smooth interpolation to target position
        @position = RL::Vector2.new(
          x: @position.x + (target_x - @position.x) * @follow_speed * dt,
          y: @position.y + (target_y - @position.y) * @follow_speed * dt
        )
      end

      private def update_edge_scroll(mouse_x : Int32, mouse_y : Int32, dt : Float32)
        scroll_x = 0.0f32
        scroll_y = 0.0f32

        # Check horizontal edges
        if mouse_x < @edge_scroll_margin
          scroll_x = -@edge_scroll_speed * dt
        elsif mouse_x > @viewport_width - @edge_scroll_margin
          scroll_x = @edge_scroll_speed * dt
        end

        # Check vertical edges
        if mouse_y < @edge_scroll_margin
          scroll_y = -@edge_scroll_speed * dt
        elsif mouse_y > @viewport_height - @edge_scroll_margin
          scroll_y = @edge_scroll_speed * dt
        end

        # Apply scrolling
        @position = RL::Vector2.new(
          x: @position.x + scroll_x,
          y: @position.y + scroll_y
        )
      end

      private def update_bounds
        # Calculate camera movement bounds
        @max_x = Math.max(0.0f32, (@scene_width - @viewport_width).to_f32)
        @max_y = Math.max(0.0f32, (@scene_height - @viewport_height).to_f32)
        @min_x = 0.0f32
        @min_y = 0.0f32
      end

      private def constrain_position
        # Keep camera within scene bounds
        @position = RL::Vector2.new(
          x: @position.x.clamp(@min_x, @max_x),
          y: @position.y.clamp(@min_y, @max_y)
        )
      end
    end
  end
end
