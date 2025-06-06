# Display Manager for adaptive resolution scaling

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Graphics
    # Manages resolution scaling and rendering
    class DisplayManager
      # Reference resolution (design resolution)
      REFERENCE_WIDTH = 1024
      REFERENCE_HEIGHT = 768
      REFERENCE_ASPECT_RATIO = REFERENCE_WIDTH.to_f / REFERENCE_HEIGHT.to_f

      property target_width : Int32
      property target_height : Int32
      property scale_factor : Float32 = 1.0
      property offset_x : Float32 = 0.0
      property offset_y : Float32 = 0.0
      property scaling_mode : ScalingMode = ScalingMode::FitWithBars
      property render_texture : RL::RenderTexture2D?

      enum ScalingMode
        FitWithBars    # Maintains aspect ratio with black bars
        Stretch        # Stretches to fill screen (may distort)
        Fill          # Fills screen by cropping if necessary
        PixelPerfect  # Integer multiples only
        FixedZoom     # Fixed zoom level
      end

      def initialize(@target_width : Int32, @target_height : Int32)
        calculate_scaling
        setup_render_texture
      end

      def calculate_scaling
        target_aspect = (@target_width.to_f / @target_height.to_f).to_f32

        case @scaling_mode
        when ScalingMode::FitWithBars
          calculate_fit_scaling(target_aspect)
        when ScalingMode::Stretch
          calculate_stretch_scaling
        when ScalingMode::Fill
          calculate_fill_scaling(target_aspect)
        when ScalingMode::PixelPerfect
          calculate_pixel_perfect_scaling
        when ScalingMode::FixedZoom
          calculate_fixed_zoom_scaling
        end
      end

      def resize(new_width : Int32, new_height : Int32)
        @target_width = new_width
        @target_height = new_height
        calculate_scaling
      end

      def set_scaling_mode(mode : ScalingMode)
        @scaling_mode = mode
        calculate_scaling
      end

      def screen_to_game(screen_pos : RL::Vector2) : RL::Vector2
        game_x = (screen_pos.x - @offset_x) / @scale_factor
        game_y = (screen_pos.y - @offset_y) / @scale_factor
        RL::Vector2.new(x: game_x, y: game_y)
      end

      def game_to_screen(game_pos : RL::Vector2) : RL::Vector2
        screen_x = game_pos.x * @scale_factor + @offset_x
        screen_y = game_pos.y * @scale_factor + @offset_y
        RL::Vector2.new(x: screen_x, y: screen_y)
      end

      def is_in_game_area(screen_pos : RL::Vector2) : Bool
        game_pos = screen_to_game(screen_pos)
        game_pos.x >= 0 && game_pos.x <= REFERENCE_WIDTH &&
        game_pos.y >= 0 && game_pos.y <= REFERENCE_HEIGHT
      end

      def begin_game_rendering
        if rt = @render_texture
          RL.begin_texture_mode(rt)
          RL.clear_background(RL::BLACK)
        end
      end

      def end_game_rendering
        if rt = @render_texture
          RL.end_texture_mode

          RL.begin_drawing
          RL.clear_background(RL::BLACK)

          source_rect = RL::Rectangle.new(
            x: 0, y: 0,
            width: REFERENCE_WIDTH,
            height: -REFERENCE_HEIGHT
          )

          dest_rect = RL::Rectangle.new(
            x: @offset_x, y: @offset_y,
            width: REFERENCE_WIDTH * @scale_factor,
            height: REFERENCE_HEIGHT * @scale_factor
          )

          RL.draw_texture_pro(rt.texture, source_rect, dest_rect,
                             RL::Vector2.new(x: 0, y: 0), 0.0, RL::WHITE)

          if Core::Engine.debug_mode
            draw_debug_info
          end

          RL.end_drawing
        end
      end

      def cleanup
        if rt = @render_texture
          RL.unload_render_texture(rt)
        end
      end

      private def calculate_fit_scaling(target_aspect : Float32)
        if target_aspect > REFERENCE_ASPECT_RATIO
          @scale_factor = (@target_height.to_f / REFERENCE_HEIGHT).to_f32
          scaled_width = REFERENCE_WIDTH * @scale_factor
          @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
          @offset_y = 0.0_f32
        else
          @scale_factor = (@target_width.to_f / REFERENCE_WIDTH).to_f32
          scaled_height = REFERENCE_HEIGHT * @scale_factor
          @offset_x = 0.0_f32
          @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
        end
      end

      private def calculate_stretch_scaling
        scale_x = (@target_width.to_f / REFERENCE_WIDTH).to_f32
        scale_y = (@target_height.to_f / REFERENCE_HEIGHT).to_f32
        @scale_factor = scale_x
        @offset_x = 0.0_f32
        @offset_y = 0.0_f32
      end

      private def calculate_fill_scaling(target_aspect : Float32)
        if target_aspect > REFERENCE_ASPECT_RATIO
          @scale_factor = (@target_width.to_f / REFERENCE_WIDTH).to_f32
          scaled_height = REFERENCE_HEIGHT * @scale_factor
          @offset_x = 0.0_f32
          @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
        else
          @scale_factor = (@target_height.to_f / REFERENCE_HEIGHT).to_f32
          scaled_width = REFERENCE_WIDTH * @scale_factor
          @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
          @offset_y = 0.0_f32
        end
      end

      private def calculate_pixel_perfect_scaling
        scale_x = (@target_width / REFERENCE_WIDTH).to_i
        scale_y = (@target_height / REFERENCE_HEIGHT).to_i
        @scale_factor = Math.min(scale_x, scale_y).to_f32
        @scale_factor = Math.max(1.0_f32, @scale_factor)

        scaled_width = REFERENCE_WIDTH * @scale_factor
        scaled_height = REFERENCE_HEIGHT * @scale_factor
        @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
        @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
      end

      private def calculate_fixed_zoom_scaling
        @scale_factor = 2.0_f32
        scaled_width = REFERENCE_WIDTH * @scale_factor
        scaled_height = REFERENCE_HEIGHT * @scale_factor
        @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
        @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
      end

      private def setup_render_texture
        @render_texture = RL.load_render_texture(REFERENCE_WIDTH, REFERENCE_HEIGHT)
      end

      private def draw_debug_info
        info_text = "Target: #{@target_width}x#{@target_height} | " \
                   "Scale: #{@scale_factor.round(2)} | " \
                   "Mode: #{@scaling_mode} | " \
                   "Offset: (#{@offset_x.to_i}, #{@offset_y.to_i})"

        RL.draw_text(info_text, 10, 10, 16, RL::GREEN)

        game_rect = RL::Rectangle.new(
          x: @offset_x, y: @offset_y,
          width: REFERENCE_WIDTH * @scale_factor,
          height: REFERENCE_HEIGHT * @scale_factor
        )
        RL.draw_rectangle_lines_ex(game_rect, 2, RL::RED)
      end
    end
  end
end