# Display management for adaptive resolution scaling and window handling
# Replaces the old DisplayManager with a cleaner, more focused implementation

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Core
      # Manages display resolution, scaling, and window properties
      #
      # The Display class handles all aspects of window management and coordinate
      # system scaling, ensuring games look correct at any resolution while
      # maintaining the intended aspect ratio.
      #
      # ## Scaling Modes
      #
      # - **FitWithBars**: Maintains aspect ratio, adds letterbox/pillarbox
      # - **Stretch**: Fills screen, may distort
      # - **PixelPerfect**: Integer scaling only for crisp pixels
      #
      # ## Example
      #
      # ```
      # display = Display.new(1920, 1080)
      # display.scaling_mode = ScalingMode::FitWithBars
      #
      # # Convert mouse position to game coordinates
      # game_pos = display.screen_to_game(mouse_pos)
      # ```
      class Display
        # Reference resolution (design/logical resolution)
        DEFAULT_REFERENCE_WIDTH  = 1024
        DEFAULT_REFERENCE_HEIGHT =  768

        @@reference_width = DEFAULT_REFERENCE_WIDTH
        @@reference_height = DEFAULT_REFERENCE_HEIGHT

        # Display properties
        getter window_width : Int32
        getter window_height : Int32
        getter reference_width : Int32
        getter reference_height : Int32
        getter scale_factor : Float32 = 1.0f32
        getter offset_x : Float32 = 0.0f32
        getter offset_y : Float32 = 0.0f32
        getter scaling_mode : ScalingMode = ScalingMode::FitWithBars

        # Fullscreen state
        getter? fullscreen : Bool = false
        @windowed_width : Int32
        @windowed_height : Int32

        enum ScalingMode
          FitWithBars  # Maintains aspect ratio with black bars
          Stretch      # Stretches to fill screen (may distort)
          PixelPerfect # Integer scaling only for pixel art
        end

        def self.reference_width : Int32
          @@reference_width
        end

        def self.reference_height : Int32
          @@reference_height
        end

        def self.reference_aspect_ratio : Float64
          @@reference_width.to_f / @@reference_height
        end

        def self.configure_reference_resolution(width : Int32, height : Int32)
          return if width <= 0 || height <= 0

          @@reference_width = width
          @@reference_height = height
        end

        def self.reset_reference_resolution
          @@reference_width = DEFAULT_REFERENCE_WIDTH
          @@reference_height = DEFAULT_REFERENCE_HEIGHT
        end

        def initialize(@window_width : Int32, @window_height : Int32,
                       @reference_width : Int32 = self.class.reference_width,
                       @reference_height : Int32 = self.class.reference_height)
          self.class.configure_reference_resolution(@reference_width, @reference_height)
          @windowed_width = @window_width
          @windowed_height = @window_height
          calculate_scaling
        end

        def reference_aspect_ratio : Float64
          @reference_width.to_f / @reference_height
        end

        def refresh_from_window
          if RL.window_ready?
            RL.poll_input_events
            @fullscreen = RL.window_fullscreen?
            @window_width = RL.get_screen_width
            @window_height = RL.get_screen_height
            calculate_scaling
          end
        end

        # Update window dimensions (e.g., after resize)
        def resize(new_width : Int32, new_height : Int32)
          @window_width = new_width
          @window_height = new_height
          calculate_scaling
        end

        # Change scaling mode
        def scaling_mode=(mode : ScalingMode)
          @scaling_mode = mode
          calculate_scaling
        end

        # Toggle fullscreen mode
        def toggle_fullscreen
          set_fullscreen(!@fullscreen)
        end

        def set_fullscreen(value : Bool)
          return if @fullscreen == value

          if value
            @windowed_width = @window_width
            @windowed_height = @window_height
            RL.toggle_fullscreen
            refresh_from_window
          else
            RL.toggle_fullscreen
            RL.set_window_size(@windowed_width, @windowed_height)
            refresh_from_window
          end
        end

        # Convert screen coordinates to game coordinates
        def screen_to_game(screen_x : Number, screen_y : Number) : RL::Vector2
          game_x = (screen_x - @offset_x) / @scale_factor
          game_y = (screen_y - @offset_y) / @scale_factor
          RL::Vector2.new(x: game_x.to_f32, y: game_y.to_f32)
        end

        # Convert screen vector to game coordinates
        def screen_to_game(screen_pos : RL::Vector2) : RL::Vector2
          screen_to_game(screen_pos.x, screen_pos.y)
        end

        # Convert game coordinates to screen coordinates
        def game_to_screen(game_x : Number, game_y : Number) : RL::Vector2
          screen_x = game_x * @scale_factor + @offset_x
          screen_y = game_y * @scale_factor + @offset_y
          RL::Vector2.new(x: screen_x.to_f32, y: screen_y.to_f32)
        end

        # Convert game vector to screen coordinates
        def game_to_screen(game_pos : RL::Vector2) : RL::Vector2
          game_to_screen(game_pos.x, game_pos.y)
        end

        # Check if screen position is within game area
        def in_game_area?(screen_x : Number, screen_y : Number) : Bool
          game_pos = screen_to_game(screen_x, screen_y)
          game_pos.x >= 0 && game_pos.x <= @reference_width &&
            game_pos.y >= 0 && game_pos.y <= @reference_height
        end

        # Check if screen vector is within game area
        def in_game_area?(screen_pos : RL::Vector2) : Bool
          in_game_area?(screen_pos.x, screen_pos.y)
        end

        # Get the game area rectangle in screen coordinates
        def game_area_screen_rect : RL::Rectangle
          RL::Rectangle.new(
            x: @offset_x,
            y: @offset_y,
            width: @reference_width * @scale_factor,
            height: @reference_height * @scale_factor
          )
        end

        def logical_rect : RL::Rectangle
          RL::Rectangle.new(
            x: 0.0f32,
            y: 0.0f32,
            width: @reference_width.to_f32,
            height: @reference_height.to_f32
          )
        end

        def active_game_area_rect : RL::Rectangle
          game_area_screen_rect
        end

        # Clear the screen with letterbox/pillarbox bars
        def clear_screen(clear_color : RL::Color = RL::BLACK)
          RL.clear_background(clear_color)

          # Draw black bars if using FitWithBars mode
          if @scaling_mode.fit_with_bars? && (@offset_x > 0 || @offset_y > 0)
            if @offset_x > 0
              # Vertical bars (pillarbox)
              RL.draw_rectangle(0, 0, @offset_x.to_i, @window_height, RL::BLACK)
              RL.draw_rectangle((@window_width - @offset_x).to_i, 0, @offset_x.to_i, @window_height, RL::BLACK)
            end

            if @offset_y > 0
              # Horizontal bars (letterbox)
              RL.draw_rectangle(0, 0, @window_width, @offset_y.to_i, RL::BLACK)
              RL.draw_rectangle(0, (@window_height - @offset_y).to_i, @window_width, @offset_y.to_i, RL::BLACK)
            end
          end
        end

        # Apply display transformation for rendering
        def with_game_coordinates(&block)
          # Create a Camera2D for display scaling and offset
          display_camera = RL::Camera2D.new(
            offset: RL::Vector2.new(x: @offset_x, y: @offset_y),
            target: RL::Vector2.new(x: 0, y: 0),
            rotation: 0.0f32,
            zoom: @scale_factor
          )

          RL.begin_mode_2d(display_camera)
          yield
          RL.end_mode_2d
        end

        def draw_logical_texture(texture : RL::Texture2D, source_width : Int32? = nil, source_height : Int32? = nil, tint : RL::Color = RL::WHITE)
          src_width = (source_width || texture.width).to_f32
          src_height = (source_height || texture.height).to_f32
          source_rect = RL::Rectangle.new(
            x: 0.0f32,
            y: 0.0f32,
            width: src_width,
            height: -src_height
          )

          RL.draw_texture_pro(
            texture,
            source_rect,
            game_area_screen_rect,
            RL::Vector2.new(x: 0.0f32, y: 0.0f32),
            0.0f32,
            tint
          )
        end

        # Draw debug information
        def draw_debug_info
          info = "Display: #{@window_width}x#{@window_height} | " \
                 "Scale: #{@scale_factor.round(2)} | " \
                 "Mode: #{@scaling_mode} | " \
                 "Offset: (#{@offset_x.to_i}, #{@offset_y.to_i})"

          RL.draw_text(info, 10, 10, 16, RL::GREEN)

          # Draw game area outline
          game_rect = game_area_screen_rect
          RL.draw_rectangle_lines_ex(game_rect, 2, RL::RED)
        end

        private def calculate_scaling
          window_aspect = @window_width.to_f / @window_height

          case @scaling_mode
          when .fit_with_bars?
            calculate_fit_scaling(window_aspect)
          when .stretch?
            calculate_stretch_scaling
          when .pixel_perfect?
            calculate_pixel_perfect_scaling
          end
        end


        private def calculate_fit_scaling(window_aspect : Float64)
          if window_aspect > reference_aspect_ratio
            # Window is wider than game - add vertical bars
            @scale_factor = (@window_height.to_f / @reference_height).to_f32
            scaled_width = @reference_width * @scale_factor
            @offset_x = ((@window_width - scaled_width) / 2.0).to_f32
            @offset_y = 0.0f32
          else
            # Window is taller than game - add horizontal bars
            @scale_factor = (@window_width.to_f / @reference_width).to_f32
            scaled_height = @reference_height * @scale_factor
            @offset_x = 0.0f32
            @offset_y = ((@window_height - scaled_height) / 2.0).to_f32
          end
        end

        private def calculate_stretch_scaling
          @scale_factor = (@window_width.to_f / @reference_width).to_f32
          @offset_x = 0.0f32
          @offset_y = 0.0f32
          # Note: This will distort if aspect ratios don't match
        end

        private def calculate_pixel_perfect_scaling
          scale_x = (@window_width / @reference_width).to_i
          scale_y = (@window_height / @reference_height).to_i

          @scale_factor = Math.max(1, Math.min(scale_x, scale_y)).to_f32

          scaled_width = @reference_width * @scale_factor
          scaled_height = @reference_height * @scale_factor

          @offset_x = ((@window_width - scaled_width) / 2.0).to_f32
          @offset_y = ((@window_height - scaled_height) / 2.0).to_f32
        end

      end
    end
  end
end
