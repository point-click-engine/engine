# Nine-patch (9-slice) rendering for scalable UI elements

require "raylib-cr"

module PointClickEngine
  module Graphics
    module UI
      # Nine-patch sprite for scalable UI elements
      #
      # A nine-patch divides an image into 9 sections:
      # ```
      # +---+-------+---+
      # | 1 |   2   | 3 |
      # +---+-------+---+
      # | 4 |   5   | 6 |
      # +---+-------+---+
      # | 7 |   8   | 9 |
      # +---+-------+---+
      # ```
      # Corners (1,3,7,9) are drawn at original size
      # Edges (2,4,6,8) are stretched in one dimension
      # Center (5) is stretched in both dimensions
      class NinePatch
        # Source texture
        getter texture : RL::Texture2D?
        getter texture_path : String?

        # Border sizes (distance from edge to stretchable area)
        property border_left : Int32 = 8
        property border_right : Int32 = 8
        property border_top : Int32 = 8
        property border_bottom : Int32 = 8

        # Minimum size (must be at least border_left + border_right, etc)
        getter min_width : Int32 = 16
        getter min_height : Int32 = 16

        # Tint color
        property tint : RL::Color = RL::WHITE

        def initialize(@texture_path : String? = nil)
          load_texture(@texture_path) if @texture_path
        end

        def initialize(texture : RL::Texture2D,
                       left : Int32 = 8, right : Int32 = 8,
                       top : Int32 = 8, bottom : Int32 = 8)
          @texture = texture
          set_borders(left, right, top, bottom)
        end

        # Load texture from file
        def load_texture(path : String)
          @texture_path = path
          @texture = RL.load_texture(path)
          update_min_size
        end

        # Set all borders at once
        def set_borders(left : Int32, right : Int32, top : Int32, bottom : Int32)
          @border_left = left
          @border_right = right
          @border_top = top
          @border_bottom = bottom
          update_min_size
        end

        # Set uniform border size
        def border=(size : Int32)
          set_borders(size, size, size, size)
        end

        # Draw the nine-patch at specified position and size
        def draw(x : Float32, y : Float32, width : Float32, height : Float32)
          return unless tex = @texture

          # Ensure minimum size
          actual_width = Math.max(width, @min_width)
          actual_height = Math.max(height, @min_height)

          # Calculate the 9 source rectangles
          tex_width = tex.width.to_f32
          tex_height = tex.height.to_f32

          # Source rectangles
          src_rects = calculate_source_rects(tex_width, tex_height)

          # Destination rectangles
          dst_rects = calculate_dest_rects(x, y, actual_width, actual_height)

          # Draw all 9 sections
          9.times do |i|
            RL.draw_texture_pro(
              tex,
              src_rects[i],
              dst_rects[i],
              RL::Vector2.new(x: 0, y: 0),
              0.0f32,
              @tint
            )
          end
        end

        # Draw with render context
        def draw_with_context(context : PointClickEngine::Graphics::RenderContext, x : Float32, y : Float32,
                              width : Float32, height : Float32)
          return unless tex = @texture
          return unless context.visible?(x + width/2, y + height/2, Math.max(width, height))

          draw(x, y, width, height)
        end

        # Draw centered at position
        def draw_centered(center_x : Float32, center_y : Float32, width : Float32, height : Float32)
          draw(center_x - width/2, center_y - height/2, width, height)
        end

        # Create a render target with nine-patch at specific size (for caching)
        def create_scaled_texture(width : Int32, height : Int32) : RL::RenderTexture2D?
          return nil unless @texture

          render_texture = RL.load_render_texture(width, height)

          RL.begin_texture_mode(render_texture)
          RL.clear_background(RL::BLANK)
          draw(0, 0, width.to_f32, height.to_f32)
          RL.end_texture_mode

          render_texture
        end

        # Cleanup
        def cleanup
          if tex = @texture
            RL.unload_texture(tex)
            @texture = nil
          end
        end

        private def update_min_size
          @min_width = @border_left + @border_right + 1
          @min_height = @border_top + @border_bottom + 1
        end

        private def calculate_source_rects(tex_width : Float32, tex_height : Float32) : Array(RL::Rectangle)
          rects = [] of RL::Rectangle

          # Calculate center dimensions
          center_width = tex_width - @border_left - @border_right
          center_height = tex_height - @border_top - @border_bottom

          # Row 1 (top)
          rects << RL::Rectangle.new(x: 0, y: 0, width: @border_left, height: @border_top)                          # Top-left
          rects << RL::Rectangle.new(x: @border_left, y: 0, width: center_width, height: @border_top)               # Top
          rects << RL::Rectangle.new(x: tex_width - @border_right, y: 0, width: @border_right, height: @border_top) # Top-right

          # Row 2 (middle)
          rects << RL::Rectangle.new(x: 0, y: @border_top, width: @border_left, height: center_height)                          # Left
          rects << RL::Rectangle.new(x: @border_left, y: @border_top, width: center_width, height: center_height)               # Center
          rects << RL::Rectangle.new(x: tex_width - @border_right, y: @border_top, width: @border_right, height: center_height) # Right

          # Row 3 (bottom)
          rects << RL::Rectangle.new(x: 0, y: tex_height - @border_bottom, width: @border_left, height: @border_bottom)                          # Bottom-left
          rects << RL::Rectangle.new(x: @border_left, y: tex_height - @border_bottom, width: center_width, height: @border_bottom)               # Bottom
          rects << RL::Rectangle.new(x: tex_width - @border_right, y: tex_height - @border_bottom, width: @border_right, height: @border_bottom) # Bottom-right

          rects
        end

        private def calculate_dest_rects(x : Float32, y : Float32, width : Float32, height : Float32) : Array(RL::Rectangle)
          rects = [] of RL::Rectangle

          # Calculate center dimensions
          center_width = width - @border_left - @border_right
          center_height = height - @border_top - @border_bottom

          # Row 1 (top)
          rects << RL::Rectangle.new(x: x, y: y, width: @border_left, height: @border_top)                          # Top-left
          rects << RL::Rectangle.new(x: x + @border_left, y: y, width: center_width, height: @border_top)           # Top
          rects << RL::Rectangle.new(x: x + width - @border_right, y: y, width: @border_right, height: @border_top) # Top-right

          # Row 2 (middle)
          rects << RL::Rectangle.new(x: x, y: y + @border_top, width: @border_left, height: center_height)                          # Left
          rects << RL::Rectangle.new(x: x + @border_left, y: y + @border_top, width: center_width, height: center_height)           # Center
          rects << RL::Rectangle.new(x: x + width - @border_right, y: y + @border_top, width: @border_right, height: center_height) # Right

          # Row 3 (bottom)
          rects << RL::Rectangle.new(x: x, y: y + height - @border_bottom, width: @border_left, height: @border_bottom)                          # Bottom-left
          rects << RL::Rectangle.new(x: x + @border_left, y: y + height - @border_bottom, width: center_width, height: @border_bottom)           # Bottom
          rects << RL::Rectangle.new(x: x + width - @border_right, y: y + height - @border_bottom, width: @border_right, height: @border_bottom) # Bottom-right

          rects
        end
      end

      # Preset nine-patch configurations
      module NinePatchPresets
        # Create a button nine-patch
        def self.button(texture_path : String) : NinePatch
          patch = NinePatch.new(texture_path)
          patch.set_borders(8, 8, 8, 8)
          patch
        end

        # Create a panel nine-patch
        def self.panel(texture_path : String) : NinePatch
          patch = NinePatch.new(texture_path)
          patch.set_borders(16, 16, 16, 16)
          patch
        end

        # Create a dialog box nine-patch
        def self.dialog(texture_path : String) : NinePatch
          patch = NinePatch.new(texture_path)
          patch.set_borders(24, 24, 24, 24)
          patch
        end

        # Create a thin border nine-patch
        def self.border(texture_path : String) : NinePatch
          patch = NinePatch.new(texture_path)
          patch.set_borders(2, 2, 2, 2)
          patch
        end
      end
    end
  end
end
