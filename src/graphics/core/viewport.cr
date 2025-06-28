# Viewport defines a rendering region on the screen

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Core
      # Defines a rectangular rendering region on the screen
      #
      # Viewports allow rendering to specific areas of the screen, enabling
      # features like split-screen, minimaps, or picture-in-picture effects.
      # Most games will use a single fullscreen viewport.
      #
      # ## Example
      #
      # ```
      # # Create a minimap viewport in top-right corner
      # minimap = Viewport.new(824, 0, 200, 150)
      # minimap.scale = 0.25 # Show 4x area
      # ```
      class Viewport
        # Position on screen (in screen coordinates)
        property screen_x : Float32
        property screen_y : Float32

        # Size of viewport
        property width : Float32
        property height : Float32

        # Scale factor for content (1.0 = normal, 0.5 = show 2x area)
        property scale : Float32 = 1.0f32

        # Background color (for clearing)
        property clear_color : RL::Color = RL::BLANK

        def initialize(@screen_x : Float32, @screen_y : Float32,
                       @width : Float32, @height : Float32)
        end

        # Create a fullscreen viewport
        def self.fullscreen : Viewport
          new(0, 0, Display::REFERENCE_WIDTH.to_f32, Display::REFERENCE_HEIGHT.to_f32)
        end

        # Create viewport from rectangle
        def self.from_rect(rect : RL::Rectangle) : Viewport
          new(rect.x, rect.y, rect.width, rect.height)
        end

        # Get viewport as rectangle
        def to_rect : RL::Rectangle
          RL::Rectangle.new(
            x: @screen_x,
            y: @screen_y,
            width: @width,
            height: @height
          )
        end

        # Check if screen point is within viewport
        def contains?(screen_x : Float32, screen_y : Float32) : Bool
          screen_x >= @screen_x &&
            screen_x <= @screen_x + @width &&
            screen_y >= @screen_y &&
            screen_y <= @screen_y + @height
        end

        # Check if screen vector is within viewport
        def contains?(point : RL::Vector2) : Bool
          contains?(point.x, point.y)
        end

        # Convert viewport coordinates to world coordinates
        def viewport_to_world(viewport_x : Float32, viewport_y : Float32, camera : Camera) : RL::Vector2
          world_x = camera.position.x + viewport_x / @scale
          world_y = camera.position.y + viewport_y / @scale
          RL::Vector2.new(x: world_x, y: world_y)
        end

        # Convert world coordinates to viewport coordinates
        def world_to_viewport(world_x : Float32, world_y : Float32, camera : Camera) : RL::Vector2
          viewport_x = (world_x - camera.position.x) * @scale
          viewport_y = (world_y - camera.position.y) * @scale
          RL::Vector2.new(x: viewport_x, y: viewport_y)
        end

        # Get the world area visible through this viewport
        def world_bounds(camera : Camera) : RL::Rectangle
          RL::Rectangle.new(
            x: camera.position.x,
            y: camera.position.y,
            width: @width / @scale,
            height: @height / @scale
          )
        end

        # Set up rendering to this viewport
        def begin_mode
          # Set scissor test to clip to viewport bounds
          RL.begin_scissor_mode(
            @screen_x.to_i,
            @screen_y.to_i,
            @width.to_i,
            @height.to_i
          )

          # Clear viewport area if color is set
          unless @clear_color.a == 0
            RL.draw_rectangle(
              @screen_x.to_i,
              @screen_y.to_i,
              @width.to_i,
              @height.to_i,
              @clear_color
            )
          end
        end

        # End viewport rendering mode
        def end_mode
          RL.end_scissor_mode
        end

        # Apply viewport transformation matrix
        def apply_transform
          RL.push_matrix
          RL.translatef(@screen_x, @screen_y, 0)
          RL.scalef(@scale, @scale, 1.0f32)
        end

        # Remove viewport transformation
        def reset_transform
          RL.pop_matrix
        end

        # Draw a border around the viewport (useful for debugging)
        def draw_border(color : RL::Color = RL::WHITE, thickness : Int32 = 1)
          RL.draw_rectangle_lines_ex(to_rect, thickness, color)
        end

        # Create split-screen viewports
        def self.split_horizontal(count : Int32) : Array(Viewport)
          height = Display::REFERENCE_HEIGHT.to_f32 / count

          Array(Viewport).new(count) do |i|
            new(0, i * height, Display::REFERENCE_WIDTH.to_f32, height)
          end
        end

        # Create split-screen viewports (vertical split)
        def self.split_vertical(count : Int32) : Array(Viewport)
          width = Display::REFERENCE_WIDTH.to_f32 / count

          Array(Viewport).new(count) do |i|
            new(i * width, 0, width, Display::REFERENCE_HEIGHT.to_f32)
          end
        end

        # Create 4-way split (2x2 grid)
        def self.split_quad : Array(Viewport)
          half_width = Display::REFERENCE_WIDTH.to_f32 / 2
          half_height = Display::REFERENCE_HEIGHT.to_f32 / 2

          [
            new(0, 0, half_width, half_height),                    # Top-left
            new(half_width, 0, half_width, half_height),           # Top-right
            new(0, half_height, half_width, half_height),          # Bottom-left
            new(half_width, half_height, half_width, half_height), # Bottom-right
          ]
        end
      end
    end
  end
end
