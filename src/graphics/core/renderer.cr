# Main 2D rendering pipeline for the Point & Click Engine

require "raylib-cr"
require "./display"
require "./camera"
require "./viewport"

module PointClickEngine
  module Graphics
    module Core
      # Main rendering pipeline coordinator
      #
      # The Renderer manages the entire rendering process, coordinating between
      # the display, camera, layers, and effects. It provides the main entry
      # point for all rendering operations.
      #
      # ## Rendering Pipeline
      #
      # 1. Clear screen and letterbox
      # 2. Apply camera transformation
      # 3. Render each layer in order
      # 4. Apply post-processing effects
      # 5. Render UI overlay
      #
      # ## Example
      #
      # ```
      # renderer = Renderer.new(display)
      # renderer.render do |context|
      #   # Render game objects using context
      #   context.draw_sprite(sprite, position)
      # end
      # ```
      class Renderer
        # Components
        getter display : Display
        getter camera : Camera
        getter viewport : Viewport

        # Rendering state
        getter render_calls : Int32 = 0
        getter? debug_mode : Bool = false

        # Effects and post-processing
        property post_processing_enabled : Bool = false

        # Render targets for effects
        @game_render_texture : RL::RenderTexture2D?
        @effect_render_texture : RL::RenderTexture2D?

        def initialize(@display : Display)
          @camera = Camera.new
          @viewport = Viewport.new(0.0f32, 0.0f32, Display::REFERENCE_WIDTH.to_f32, Display::REFERENCE_HEIGHT.to_f32)
          setup_render_textures
        end

        # Main render method with context
        def render(&block : RenderContext ->)
          @render_calls = 0

          # Start rendering to game texture if post-processing is enabled
          if @post_processing_enabled && (game_texture = @game_render_texture)
            RL.begin_texture_mode(game_texture)
            RL.clear_background(RL::BLANK)
          end

          # Apply display scaling and camera transformation
          @display.with_game_coordinates do
            # Apply camera transformation using Camera2D
            camera2d = RL::Camera2D.new(
              offset: RL::Vector2.new(x: 0, y: 0),
              target: RL::Vector2.new(x: -@camera.position.x, y: -@camera.position.y),
              rotation: 0.0f32,
              zoom: 1.0f32
            )

            RL.begin_mode_2d(camera2d)

            # Create render context and yield to caller
            context = RenderContext.new(self, @camera, @viewport)
            yield context

            RL.end_mode_2d
          end

          # End texture mode and apply post-processing
          if @post_processing_enabled && (game_texture = @game_render_texture)
            RL.end_texture_mode
            apply_post_processing(game_texture)
          end

          # Draw debug info if enabled
          draw_debug_info if @debug_mode
        end

        # Render with multiple viewports (for split-screen, minimap, etc.)
        def render_multi_viewport(viewports : Array(Tuple(Viewport, Camera)), &block : RenderContext, Int32 ->)
          viewports.each_with_index do |(viewport, camera), index|
            # Set up scissor test for viewport clipping
            RL.begin_scissor_mode(
              viewport.screen_x.to_i,
              viewport.screen_y.to_i,
              viewport.width.to_i,
              viewport.height.to_i
            )

            # Apply viewport and camera transformation using Camera2D
            camera2d = RL::Camera2D.new(
              offset: RL::Vector2.new(x: viewport.screen_x, y: viewport.screen_y),
              target: RL::Vector2.new(
                x: -camera.position.x * viewport.scale,
                y: -camera.position.y * viewport.scale
              ),
              rotation: 0.0f32,
              zoom: viewport.scale
            )

            RL.begin_mode_2d(camera2d)

            # Create context and render
            context = RenderContext.new(self, camera, viewport)
            yield context, index

            RL.end_mode_2d
            RL.end_scissor_mode
          end
        end

        # Enable debug rendering mode
        def debug_mode=(enabled : Bool)
          @debug_mode = enabled
        end

        # Track render calls for performance monitoring
        def increment_render_calls
          @render_calls += 1
        end

        # Enable/disable post-processing
        def enable_post_processing
          @post_processing_enabled = true
          setup_render_textures if @game_render_texture.nil?
        end

        def disable_post_processing
          @post_processing_enabled = false
        end

        # Check if a world position is visible
        def visible?(world_x : Float32, world_y : Float32, margin : Float32 = 50.0f32) : Bool
          screen_x = world_x - @camera.position.x
          screen_y = world_y - @camera.position.y

          screen_x >= -margin &&
            screen_x <= Display::REFERENCE_WIDTH + margin &&
            screen_y >= -margin &&
            screen_y <= Display::REFERENCE_HEIGHT + margin
        end

        # Cleanup render textures
        def cleanup
          if texture = @game_render_texture
            RL.unload_render_texture(texture)
            @game_render_texture = nil
          end

          if texture = @effect_render_texture
            RL.unload_render_texture(texture)
            @effect_render_texture = nil
          end
        end

        private def setup_render_textures
          @game_render_texture = RL.load_render_texture(
            Display::REFERENCE_WIDTH,
            Display::REFERENCE_HEIGHT
          )

          @effect_render_texture = RL.load_render_texture(
            Display::REFERENCE_WIDTH,
            Display::REFERENCE_HEIGHT
          )
        end

        private def apply_post_processing(source_texture : RL::RenderTexture2D)
          # For now, just draw the texture without effects
          # This will be expanded when we implement the effects system
          source_rect = RL::Rectangle.new(
            x: 0,
            y: 0,
            width: Display::REFERENCE_WIDTH.to_f32,
            height: -Display::REFERENCE_HEIGHT.to_f32 # Flip Y
          )

          dest_rect = RL::Rectangle.new(
            x: 0,
            y: 0,
            width: Display::REFERENCE_WIDTH.to_f32,
            height: Display::REFERENCE_HEIGHT.to_f32
          )

          RL.draw_texture_pro(
            source_texture.texture,
            source_rect,
            dest_rect,
            RL::Vector2.new(x: 0, y: 0),
            0.0f32,
            RL::WHITE
          )
        end

        private def draw_debug_info
          debug_text = "Render Calls: #{@render_calls} | " \
                       "Camera: (#{@camera.position.x.to_i}, #{@camera.position.y.to_i}) | " \
                       "FPS: #{RL.get_fps}"

          RL.draw_text(debug_text, 10, 30, 16, RL::YELLOW)
        end
      end

      # Rendering context passed to draw operations
      #
      # Provides camera-aware drawing methods that automatically handle
      # coordinate transformations and culling.
      class RenderContext
        getter renderer : Renderer
        getter camera : Camera
        getter viewport : Viewport

        def initialize(@renderer : Renderer, @camera : Camera, @viewport : Viewport)
        end

        # Draw texture at world position
        def draw_texture(texture : RL::Texture2D, world_x : Float32, world_y : Float32, tint : RL::Color = RL::WHITE)
          return unless @renderer.visible?(world_x, world_y, texture.width.to_f32)

          screen_x = world_x - texture.width / 2
          screen_y = world_y - texture.height / 2

          RL.draw_texture(texture, screen_x.to_i, screen_y.to_i, tint)
          @renderer.increment_render_calls
        end

        # Draw texture with extended parameters
        def draw_texture_ex(texture : RL::Texture2D, position : RL::Vector2,
                            rotation : Float32, scale : Float32, tint : RL::Color)
          return unless @renderer.visible?(position.x, position.y, texture.width * scale)

          RL.draw_texture_ex(texture, position, rotation, scale, tint)
          @renderer.increment_render_calls
        end

        # Draw texture region
        def draw_texture_rect(texture : RL::Texture2D, source : RL::Rectangle,
                              position : RL::Vector2, tint : RL::Color = RL::WHITE)
          return unless @renderer.visible?(position.x, position.y, source.width)

          RL.draw_texture_rec(texture, source, position, tint)
          @renderer.increment_render_calls
        end

        # Draw texture with full transform options
        def draw_texture_pro(texture : RL::Texture2D, source : RL::Rectangle,
                             dest : RL::Rectangle, origin : RL::Vector2,
                             rotation : Float32, tint : RL::Color)
          # Check visibility using destination rectangle
          return unless @renderer.visible?(dest.x + dest.width/2, dest.y + dest.height/2,
                          Math.max(dest.width, dest.height))

          RL.draw_texture_pro(texture, source, dest, origin, rotation, tint)
          @renderer.increment_render_calls
        end

        # Draw a sprite (convenience method)
        def draw_sprite(sprite : Sprite, position : RL::Vector2, tint : RL::Color = RL::WHITE)
          sprite.draw_with_context(self, position, tint)
        end

        # Draw rectangle
        def draw_rectangle(x : Float32, y : Float32, width : Float32, height : Float32, color : RL::Color)
          return unless @renderer.visible?(x + width/2, y + height/2, Math.max(width, height))

          RL.draw_rectangle(x.to_i, y.to_i, width.to_i, height.to_i, color)
          @renderer.increment_render_calls
        end

        # Draw rectangle lines
        def draw_rectangle_lines(x : Float32, y : Float32, width : Float32, height : Float32, color : RL::Color)
          return unless @renderer.visible?(x + width/2, y + height/2, Math.max(width, height))

          RL.draw_rectangle_lines(x.to_i, y.to_i, width.to_i, height.to_i, color)
          @renderer.increment_render_calls
        end

        # Draw text
        def draw_text(text : String, x : Float32, y : Float32, font_size : Int32, color : RL::Color)
          # Simple visibility check
          return unless @renderer.visible?(x, y, 200.0f32) # Assume max text width of 200

          RL.draw_text(text, x.to_i, y.to_i, font_size, color)
          @renderer.increment_render_calls
        end

        # Draw line
        def draw_line(start_pos : RL::Vector2, end_pos : RL::Vector2, color : RL::Color)
          RL.draw_line_v(start_pos, end_pos, color)
          @renderer.increment_render_calls
        end

        # Draw circle
        def draw_circle(center : RL::Vector2, radius : Float32, color : RL::Color)
          return unless @renderer.visible?(center.x, center.y, radius * 2)

          RL.draw_circle_v(center, radius, color)
          @renderer.increment_render_calls
        end

        # Draw in screen space (ignoring camera)
        def draw_screen_space(&block)
          # TODO: Implement proper screen space drawing
          # For now, just yield directly
          yield
        end

        # Check if world position is visible
        def visible?(world_x : Float32, world_y : Float32, margin : Float32 = 0.0f32) : Bool
          @renderer.visible?(world_x, world_y, margin)
        end

        # Get camera position (for calculations)
        def camera_position : RL::Vector2
          @camera.position
        end

        # Get viewport info
        def viewport_bounds : RL::Rectangle
          @viewport.world_bounds(@camera)
        end
      end
    end
  end
end
