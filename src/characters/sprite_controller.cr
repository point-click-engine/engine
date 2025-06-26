require "../graphics/animated_sprite"
require "../core/game_object"

module PointClickEngine
  module Characters
    # Manages sprite loading, scaling, and rendering for characters
    #
    # The SpriteController handles all sprite-related operations including:
    # - Sprite loading and initialization
    # - Scale calculation and management
    # - Position synchronization
    # - Rendering coordination
    class SpriteController
      # The animated sprite data
      property sprite : Graphics::AnimatedSprite?

      # Path to the sprite/spritesheet file
      property sprite_path : String?

      # Manual scale override (nil for automatic scaling)
      property manual_scale : Float32?

      # Reference to the character's position
      property position : RL::Vector2

      # Reference to the character's size
      property size : RL::Vector2

      # Character's current scale factor
      property scale : Float32 = 1.0_f32

      # Visibility state (independent of sprite)
      property visible : Bool = true

      def initialize(@position : RL::Vector2, @size : RL::Vector2)
      end

      # Loads a spritesheet for character animation
      def load_spritesheet(path : String, frame_width : Int32, frame_height : Int32)
        @sprite_path = path
        @sprite = Graphics::AnimatedSprite.new(@position, frame_width, frame_height, 1)

        if sprite = @sprite
          sprite.load_texture(path)
          sprite.scale = calculate_scale(frame_width, frame_height)
          sprite.visible = @visible

          # Update character size based on sprite dimensions
          @size = RL::Vector2.new(
            x: frame_width * sprite.scale,
            y: frame_height * sprite.scale
          )
          sprite.size = @size
        end
      end

      # Updates sprite position to match character position
      def update_position(new_position : RL::Vector2)
        @position = new_position
        @sprite.try(&.position = new_position)
      end

      # Updates sprite scale
      def update_scale(new_scale : Float32)
        @scale = new_scale
        if sprite = @sprite
          # Store original scale for restoration
          original_scale = sprite.scale
          # Apply character scale for rendering
          sprite.scale = @manual_scale || new_scale
        end
      end

      # Renders the sprite with current settings
      def draw
        return unless @visible
        return unless sprite = @sprite

        # Apply character scale temporarily for rendering
        old_scale = sprite.scale
        sprite.scale = @manual_scale || @scale
        sprite.draw
        sprite.scale = old_scale
      end

      # Calculates appropriate scale for sprite based on frame dimensions
      private def calculate_scale(frame_width : Int32, frame_height : Int32) : Float32
        return 1.0_f32 if frame_width == 0 || frame_height == 0

        scale_x = @size.x / frame_width
        scale_y = @size.y / frame_height
        Math.min(scale_x, scale_y).to_f32
      end

      # Gets the frame width of the sprite
      def frame_width : Int32
        @sprite.try(&.frame_width) || 0
      end

      # Gets the frame height of the sprite
      def frame_height : Int32
        @sprite.try(&.frame_height) || 0
      end

      # Checks if sprite is loaded
      def loaded? : Bool
        @sprite != nil
      end

      # Gets sprite bounds for collision detection
      def get_bounds : RL::Rectangle
        if sprite = @sprite
          base_width = sprite.frame_width.to_f32
          base_height = sprite.frame_height.to_f32

          # Apply character scale
          scaled_width = base_width * @scale
          scaled_height = base_height * @scale

          RL::Rectangle.new(
            x: @position.x - scaled_width.abs / 2,
            y: @position.y - scaled_height.abs,
            width: scaled_width.abs,
            height: scaled_height.abs
          )
        else
          # Fallback bounds based on size
          RL::Rectangle.new(
            x: @position.x - @size.x / 2,
            y: @position.y - @size.y,
            width: @size.x,
            height: @size.y
          )
        end
      end

      # Checks if a point is within the sprite bounds
      def contains_point?(point : RL::Vector2) : Bool
        RL.check_collision_point_rec?(point, get_bounds)
      end

      # Sets manual scale override
      def set_manual_scale(scale : Float32?)
        @manual_scale = scale
      end

      # Clears manual scale override
      def clear_manual_scale
        @manual_scale = nil
      end

      # Gets effective scale (manual override or calculated)
      def effective_scale : Float32
        @manual_scale || @scale
      end

      # Reloads the sprite texture
      def reload_texture
        return unless path = @sprite_path
        return unless sprite = @sprite

        sprite.load_texture(path)
      end

      # Called after YAML deserialization to restore sprite state
      def after_yaml_deserialize(ctx : YAML::ParseContext)
        @sprite.try(&.after_yaml_deserialize(ctx))

        # Restore sprite position
        @sprite.try(&.position = @position)
      end

      # Updates size based on sprite dimensions and scale
      def update_size_from_sprite
        return unless sprite = @sprite

        @size = RL::Vector2.new(
          x: sprite.frame_width * effective_scale,
          y: sprite.frame_height * effective_scale
        )
        sprite.size = @size
      end

      # Gets sprite visibility
      def visible? : Bool
        @visible && @sprite != nil
      end

      # Unloads sprite resources
      def unload
        # AnimatedSprite doesn't have an unload method
        @sprite = nil
        @sprite_path = nil
      end

      # Creates a copy of this sprite controller
      def clone
        new_controller = SpriteController.new(@position, @size)
        new_controller.manual_scale = @manual_scale
        new_controller.scale = @scale

        # Recreate sprite if it exists
        if sprite = @sprite
          if path = @sprite_path
            new_controller.load_spritesheet(path, sprite.frame_width, sprite.frame_height)
          end
        end

        new_controller
      end
    end
  end
end
