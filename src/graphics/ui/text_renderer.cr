# Text rendering with bitmap fonts and effects

require "raylib-cr"

module PointClickEngine
  module Graphics
    module UI
      # Text alignment options
      enum TextAlign
        Left
        Center
        Right
      end

      # Vertical alignment options
      enum VerticalAlign
        Top
        Middle
        Bottom
      end

      # Text rendering with advanced features
      class TextRenderer
        # Default font size
        DEFAULT_FONT_SIZE = 20

        # Font data
        property font : RL::Font?
        property font_size : Int32 = DEFAULT_FONT_SIZE
        property spacing : Float32 = 1.0f32

        # Text properties
        property color : RL::Color = RL::WHITE
        property outline_color : RL::Color = RL::BLACK
        property outline_thickness : Int32 = 0
        property shadow_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 128)
        property shadow_offset : RL::Vector2 = RL::Vector2.new(x: 2, y: 2)
        property enable_shadow : Bool = false

        # Word wrap
        property word_wrap : Bool = false
        property max_width : Float32 = 0.0f32

        def initialize(@font : RL::Font? = nil, @font_size : Int32 = DEFAULT_FONT_SIZE)
        end

        # Load font from file
        def load_font(path : String, size : Int32 = DEFAULT_FONT_SIZE)
          @font = RL.load_font_ex(path, size, nil, 0)
          @font_size = size
        end

        # Draw text at position
        def draw(text : String, x : Float32, y : Float32,
                 align : TextAlign = TextAlign::Left,
                 v_align : VerticalAlign = VerticalAlign::Top)
          font_to_use = @font || RL.get_font_default

          # Calculate text dimensions
          text_size = measure_text(text)

          # Apply horizontal alignment
          draw_x = case align
                   when .center?
                     x - text_size.x / 2
                   when .right?
                     x - text_size.x
                   else
                     x
                   end

          # Apply vertical alignment
          draw_y = case v_align
                   when .middle?
                     y - text_size.y / 2
                   when .bottom?
                     y - text_size.y
                   else
                     y
                   end

          # Draw shadow if enabled
          if @enable_shadow
            draw_text_internal(text, draw_x + @shadow_offset.x, draw_y + @shadow_offset.y,
              @shadow_color, font_to_use)
          end

          # Draw outline if enabled
          if @outline_thickness > 0
            # Draw outline in 8 directions
            (-@outline_thickness..@outline_thickness).each do |ox|
              (-@outline_thickness..@outline_thickness).each do |oy|
                next if ox == 0 && oy == 0
                draw_text_internal(text, draw_x + ox, draw_y + oy,
                  @outline_color, font_to_use)
              end
            end
          end

          # Draw main text
          draw_text_internal(text, draw_x, draw_y, @color, font_to_use)
        end

        # Draw text with word wrap
        def draw_wrapped(text : String, x : Float32, y : Float32, max_width : Float32,
                         align : TextAlign = TextAlign::Left,
                         line_spacing : Float32 = 1.2f32)
          return draw(text, x, y, align) if max_width <= 0

          lines = wrap_text(text, max_width)
          line_height = @font_size * line_spacing

          lines.each_with_index do |line, i|
            draw(line, x, y + i * line_height, align)
          end
        end

        # Draw text in a box
        def draw_in_box(text : String, box : RL::Rectangle,
                        h_align : TextAlign = TextAlign::Center,
                        v_align : VerticalAlign = VerticalAlign::Middle,
                        clip : Bool = true)
          # Calculate position based on alignment
          text_size = measure_text(text)

          x = case h_align
              when .center?
                box.x + box.width / 2
              when .right?
                box.x + box.width
              else
                box.x
              end

          y = case v_align
              when .middle?
                box.y + box.height / 2
              when .bottom?
                box.y + box.height
              else
                box.y
              end

          if clip
            # Set up scissor mode for clipping
            RL.begin_scissor_mode(box.x.to_i, box.y.to_i, box.width.to_i, box.height.to_i)
          end

          if @word_wrap && box.width > 0
            draw_wrapped(text, x, y, box.width, h_align)
          else
            draw(text, x, y, h_align, v_align)
          end

          if clip
            RL.end_scissor_mode
          end
        end

        # Measure text dimensions
        def measure_text(text : String) : RL::Vector2
          font_to_use = @font || RL.get_font_default

          if @font
            RL.measure_text_ex(font_to_use, text, @font_size.to_f32, @spacing)
          else
            # Use simple measurement for default font
            width = RL.measure_text(text, @font_size)
            RL::Vector2.new(x: width.to_f32, y: @font_size.to_f32)
          end
        end

        # Wrap text to fit within max width
        def wrap_text(text : String, max_width : Float32) : Array(String)
          return [text] if max_width <= 0

          lines = [] of String
          words = text.split(/\s+/)
          current_line = ""

          words.each do |word|
            test_line = current_line.empty? ? word : "#{current_line} #{word}"
            line_width = measure_text(test_line).x

            if line_width > max_width && !current_line.empty?
              lines << current_line
              current_line = word
            else
              current_line = test_line
            end
          end

          lines << current_line unless current_line.empty?
          lines
        end

        # Draw typewriter effect
        def draw_typewriter(text : String, x : Float32, y : Float32,
                            progress : Float32, # 0.0 to 1.0
                            align : TextAlign = TextAlign::Left)
          chars_to_show = (text.size * progress).to_i
          visible_text = text[0...chars_to_show]
          draw(visible_text, x, y, align)
        end

        # Draw text with wave effect
        def draw_wave(text : String, x : Float32, y : Float32,
                      amplitude : Float32 = 5.0f32,
                      frequency : Float32 = 0.1f32,
                      time : Float32 = 0.0f32)
          font_to_use = @font || RL.get_font_default
          current_x = x

          text.each_char_with_index do |char, i|
            # Calculate wave offset
            wave_offset = Math.sin((i * frequency + time) * Math::PI * 2) * amplitude

            # Draw character
            draw_text_internal(char.to_s, current_x, y + wave_offset, @color, font_to_use)

            # Advance position
            char_width = measure_text(char.to_s).x
            current_x += char_width + @spacing
          end
        end

        # Draw text with shake effect
        def draw_shake(text : String, x : Float32, y : Float32,
                       intensity : Float32 = 2.0f32)
          offset_x = Random.rand(-intensity.to_i..intensity.to_i)
          offset_y = Random.rand(-intensity.to_i..intensity.to_i)
          draw(text, x + offset_x, y + offset_y)
        end

        # Draw text with fade gradient
        def draw_gradient(text : String, x : Float32, y : Float32,
                          start_color : RL::Color, end_color : RL::Color,
                          vertical : Bool = false)
          font_to_use = @font || RL.get_font_default

          if vertical
            # Character by character for vertical gradient
            current_x = x
            text.each_char_with_index do |char, i|
              t = i.to_f / (text.size - 1)
              char_color = interpolate_color(start_color, end_color, t)

              draw_text_internal(char.to_s, current_x, y, char_color, font_to_use)

              char_width = measure_text(char.to_s).x
              current_x += char_width + @spacing
            end
          else
            # Simple horizontal gradient (would need shader for smooth gradient)
            draw(text, x, y)
          end
        end

        # Cleanup
        def cleanup
          if font = @font
            RL.unload_font(font)
            @font = nil
          end
        end

        private def draw_text_internal(text : String, x : Float32, y : Float32,
                                       color : RL::Color, font : RL::Font)
          if @font
            RL.draw_text_ex(font, text, RL::Vector2.new(x: x, y: y),
              @font_size.to_f32, @spacing, color)
          else
            RL.draw_text(text, x.to_i, y.to_i, @font_size, color)
          end
        end

        private def interpolate_color(start : RL::Color, end_color : RL::Color, t : Float32) : RL::Color
          RL::Color.new(
            r: (start.r + (end_color.r - start.r) * t).to_u8,
            g: (start.g + (end_color.g - start.g) * t).to_u8,
            b: (start.b + (end_color.b - start.b) * t).to_u8,
            a: (start.a + (end_color.a - start.a) * t).to_u8
          )
        end
      end

      # Global text renderer instance
      class_property default_text_renderer : TextRenderer { TextRenderer.new }
    end
  end
end
