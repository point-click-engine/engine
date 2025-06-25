require "raylib-cr"

module PointClickEngine
  module Scenes
    # Manages background rendering and scaling for scenes
    #
    # The BackgroundRenderer handles all background-related functionality including:
    # - Background texture loading and management
    # - Automatic scaling calculations
    # - Camera-aware background positioning
    # - Background rendering optimization
    class BackgroundRenderer
      # Background texture
      property background_texture : RL::Texture2D?

      # Path to the background image file
      property background_path : String?

      # Scene dimensions
      property scene_width : Int32
      property scene_height : Int32

      # Calculated background scale factor
      property background_scale : Float32 = 1.0_f32

      # Background offset for centering
      property background_offset : RL::Vector2 = RL::Vector2.new(0, 0)

      # Whether to maintain aspect ratio when scaling
      property maintain_aspect_ratio : Bool = true

      # Scaling mode for background
      enum ScalingMode
        Stretch # Stretch to fill scene dimensions exactly
        Fit     # Scale to fit within scene while maintaining aspect ratio
        Fill    # Scale to fill scene while maintaining aspect ratio (may crop)
        None    # No scaling, use original size
      end

      property scaling_mode : ScalingMode = ScalingMode::Fit

      def initialize(@scene_width : Int32, @scene_height : Int32)
      end

      # Loads a background image from file
      #
      # Loads the texture and calculates appropriate scaling and positioning
      # based on scene dimensions and scaling mode.
      #
      # - *path* : File path to the background image
      def load_background(path : String)
        @background_path = path

        # Load texture
        @background_texture = RL.load_texture(path)

        if texture = @background_texture
          calculate_background_transform(texture)
        end
      rescue ex
        puts "Failed to load background: #{ex.message}"
        @background_texture = nil
        @background_path = nil
      end

      # Loads background from texture data
      #
      # - *texture* : Pre-loaded texture to use as background
      def load_background_from_texture(texture : RL::Texture2D)
        @background_texture = texture
        calculate_background_transform(texture)
      end

      # Renders the background with camera offset
      #
      # Draws the background texture with proper scaling and positioning,
      # accounting for camera movement for parallax effects.
      #
      # - *camera_offset* : Current camera offset for scene scrolling
      # - *parallax_factor* : Parallax factor (0.0 = no parallax, 1.0 = full parallax)
      def draw(camera_offset : RL::Vector2, parallax_factor : Float32 = 1.0_f32)
        return unless texture = @background_texture

        # Calculate parallax offset
        parallax_offset = RL::Vector2.new(
          x: camera_offset.x * parallax_factor,
          y: camera_offset.y * parallax_factor
        )

        # Final position with parallax and background offset
        final_position = RL::Vector2.new(
          x: @background_offset.x - parallax_offset.x,
          y: @background_offset.y - parallax_offset.y
        )

        # Draw background with scaling
        draw_texture_scaled(texture, final_position, @background_scale)
      end

      # Draws background without camera effects (for UI backgrounds)
      def draw_static
        return unless texture = @background_texture
        draw_texture_scaled(texture, @background_offset, @background_scale)
      end

      # Updates scene dimensions and recalculates scaling
      def update_scene_size(width : Int32, height : Int32)
        @scene_width = width
        @scene_height = height

        if texture = @background_texture
          calculate_background_transform(texture)
        end
      end

      # Sets scaling mode and recalculates transform
      def set_scaling_mode(mode : ScalingMode)
        @scaling_mode = mode

        if texture = @background_texture
          calculate_background_transform(texture)
        end
      end

      # Gets background texture dimensions
      def get_texture_size : RL::Vector2
        if texture = @background_texture
          RL::Vector2.new(x: texture.width.to_f32, y: texture.height.to_f32)
        else
          RL::Vector2.new(0, 0)
        end
      end

      # Gets scaled background dimensions
      def get_scaled_size : RL::Vector2
        texture_size = get_texture_size
        RL::Vector2.new(
          x: texture_size.x * @background_scale,
          y: texture_size.y * @background_scale
        )
      end

      # Checks if background covers the entire scene
      def covers_scene? : Bool
        return false unless @background_texture

        scaled_size = get_scaled_size
        scaled_size.x >= @scene_width && scaled_size.y >= @scene_height
      end

      # Gets the visible area of the background for the given camera position
      def get_visible_area(camera_offset : RL::Vector2, viewport_width : Int32, viewport_height : Int32) : RL::Rectangle
        scaled_size = get_scaled_size

        RL::Rectangle.new(
          x: camera_offset.x - @background_offset.x,
          y: camera_offset.y - @background_offset.y,
          width: Math.min(viewport_width, scaled_size.x).to_f32,
          height: Math.min(viewport_height, scaled_size.y).to_f32
        )
      end

      # Unloads background texture and frees memory
      def unload
        if texture = @background_texture
          RL.unload_texture(texture)
        end
        @background_texture = nil
        @background_path = nil
      end

      # Reloads background from the stored path
      def reload
        return unless path = @background_path
        load_background(path)
      end

      # Checks if background is loaded
      def loaded? : Bool
        @background_texture != nil
      end

      # Creates a tiled background pattern
      def create_tiled_background(tile_texture : RL::Texture2D, tile_width : Int32, tile_height : Int32)
        # Create a render texture for the tiled background
        render_texture = RL.load_render_texture(@scene_width, @scene_height)

        RL.begin_texture_mode(render_texture)
        RL.clear_background(RL::BLANK)

        # Draw tiles to fill the scene
        tiles_x = (@scene_width / tile_width.to_f32).ceil.to_i
        tiles_y = (@scene_height / tile_height.to_f32).ceil.to_i

        (0...tiles_y).each do |y|
          (0...tiles_x).each do |x|
            RL.draw_texture(tile_texture, x * tile_width, y * tile_height, RL::WHITE)
          end
        end

        RL.end_texture_mode

        # Use the tiled texture as background
        @background_texture = render_texture.texture
        @background_scale = 1.0_f32
        @background_offset = RL::Vector2.new(0, 0)
      end

      # Applies a color tint to the background
      def draw_with_tint(camera_offset : RL::Vector2, tint : RL::Color, parallax_factor : Float32 = 1.0_f32)
        return unless texture = @background_texture

        # Calculate parallax offset
        parallax_offset = RL::Vector2.new(
          x: camera_offset.x * parallax_factor,
          y: camera_offset.y * parallax_factor
        )

        # Final position
        final_position = RL::Vector2.new(
          x: @background_offset.x - parallax_offset.x,
          y: @background_offset.y - parallax_offset.y
        )

        # Draw with tint
        draw_texture_scaled_tinted(texture, final_position, @background_scale, tint)
      end

      # Calculates background scaling and positioning
      private def calculate_background_transform(texture : RL::Texture2D)
        texture_width = texture.width.to_f32
        texture_height = texture.height.to_f32

        case @scaling_mode
        when ScalingMode::Stretch
          # Stretch to exactly fit scene dimensions
          scale_x = @scene_width / texture_width
          scale_y = @scene_height / texture_height
          @background_scale = Math.max(scale_x, scale_y)
        when ScalingMode::Fit
          # Scale to fit within scene while maintaining aspect ratio
          scale_x = @scene_width / texture_width
          scale_y = @scene_height / texture_height
          @background_scale = Math.min(scale_x, scale_y)
        when ScalingMode::Fill
          # Scale to fill scene while maintaining aspect ratio (may crop)
          scale_x = @scene_width / texture_width
          scale_y = @scene_height / texture_height
          @background_scale = Math.max(scale_x, scale_y)
        when ScalingMode::None
          # No scaling
          @background_scale = 1.0_f32
        end

        # Calculate centering offset
        scaled_width = texture_width * @background_scale
        scaled_height = texture_height * @background_scale

        @background_offset = RL::Vector2.new(
          x: (@scene_width - scaled_width) / 2,
          y: (@scene_height - scaled_height) / 2
        )
      end

      # Draws texture with scaling
      private def draw_texture_scaled(texture : RL::Texture2D, position : RL::Vector2, scale : Float32)
        source_rect = RL::Rectangle.new(
          x: 0, y: 0,
          width: texture.width.to_f32,
          height: texture.height.to_f32
        )

        dest_rect = RL::Rectangle.new(
          x: position.x, y: position.y,
          width: texture.width * scale,
          height: texture.height * scale
        )

        RL.draw_texture_pro(texture, source_rect, dest_rect, RL::Vector2.new(0, 0), 0.0, RL::WHITE)
      end

      # Draws texture with scaling and tint
      private def draw_texture_scaled_tinted(texture : RL::Texture2D, position : RL::Vector2, scale : Float32, tint : RL::Color)
        source_rect = RL::Rectangle.new(
          x: 0, y: 0,
          width: texture.width.to_f32,
          height: texture.height.to_f32
        )

        dest_rect = RL::Rectangle.new(
          x: position.x, y: position.y,
          width: texture.width * scale,
          height: texture.height * scale
        )

        RL.draw_texture_pro(texture, source_rect, dest_rect, RL::Vector2.new(0, 0), 0.0, tint)
      end
    end
  end
end
