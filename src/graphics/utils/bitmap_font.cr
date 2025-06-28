# Bitmap font loading and rendering utilities

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Utils
      # Bitmap font loader and manager
      class BitmapFont
        # Character information
        struct Glyph
          property source_rect : RL::Rectangle
          property offset : RL::Vector2
          property advance : Float32

          def initialize(@source_rect : RL::Rectangle, @offset : RL::Vector2, @advance : Float32)
          end
        end

        # Font metadata
        property texture : RL::Texture2D
        property base_size : Int32
        property line_height : Int32
        property glyphs : Hash(Char, Glyph)

        # Common spacing
        property spacing : Float32 = 1.0f32
        property line_spacing : Float32 = 1.0f32

        def initialize(@texture : RL::Texture2D, @base_size : Int32, @line_height : Int32)
          @glyphs = {} of Char => Glyph
        end

        # Load font from Raylib font file
        def self.load(font_path : String) : BitmapFont
          font = RL.load_font(font_path)

          bitmap_font = new(font.texture, font.base_size, font.base_size)

          # Copy glyph data
          font.chars.each_with_index do |char_info, i|
            next if char_info.value == 0

            glyph = Glyph.new(
              source_rect: RL::Rectangle.new(
                x: char_info.rec.x,
                y: char_info.rec.y,
                width: char_info.rec.width,
                height: char_info.rec.height
              ),
              offset: RL::Vector2.new(
                x: char_info.offset_x,
                y: char_info.offset_y
              ),
              advance: char_info.advance_x
            )

            bitmap_font.glyphs[char_info.value.chr] = glyph
          end

          bitmap_font
        end

        # Load font from sprite sheet with fixed grid
        def self.load_grid(texture_path : String, char_width : Int32, char_height : Int32,
                           first_char : Char = ' ', chars_per_row : Int32 = 16) : BitmapFont
          texture = RL.load_texture(texture_path)
          bitmap_font = new(texture, char_height, char_height)

          # Calculate grid positions
          rows = (texture.height / char_height).to_i
          total_chars = rows * chars_per_row

          total_chars.times do |i|
            char_code = first_char.ord + i
            break if char_code > 255 # ASCII limit

            col = i % chars_per_row
            row = i // chars_per_row

            glyph = Glyph.new(
              source_rect: RL::Rectangle.new(
                x: col * char_width,
                y: row * char_height,
                width: char_width,
                height: char_height
              ),
              offset: RL::Vector2.new(x: 0, y: 0),
              advance: char_width.to_f32
            )

            bitmap_font.glyphs[char_code.chr] = glyph
          end

          bitmap_font
        end

        # Load font from custom format (JSON-like)
        def self.load_custom(texture_path : String, data_path : String) : BitmapFont
          texture = RL.load_texture(texture_path)

          # Read font data file
          data = File.read(data_path)
          lines = data.lines

          # Parse header
          base_size = 16
          line_height = 20

          lines.each do |line|
            if line.starts_with?("base_size:")
              base_size = line.split(':')[1].strip.to_i
            elsif line.starts_with?("line_height:")
              line_height = line.split(':')[1].strip.to_i
            end
          end

          bitmap_font = new(texture, base_size, line_height)

          # Parse glyph data
          lines.each do |line|
            next unless line.starts_with?("char:")

            parts = line.split(' ')
            next if parts.size < 7

            char_code = parts[1].to_i
            x = parts[2].to_i
            y = parts[3].to_i
            width = parts[4].to_i
            height = parts[5].to_i
            advance = parts[6].to_f32

            glyph = Glyph.new(
              source_rect: RL::Rectangle.new(x: x, y: y, width: width, height: height),
              offset: RL::Vector2.new(x: 0, y: 0),
              advance: advance
            )

            bitmap_font.glyphs[char_code.chr] = glyph
          end

          bitmap_font
        end

        # Draw text
        def draw(text : String, x : Float32, y : Float32, color : RL::Color = RL::WHITE)
          current_x = x
          current_y = y

          text.each_char do |char|
            if char == '\n'
              current_x = x
              current_y += @line_height * @line_spacing
              next
            end

            if glyph = @glyphs[char]?
              dest_rect = RL::Rectangle.new(
                x: current_x + glyph.offset.x,
                y: current_y + glyph.offset.y,
                width: glyph.source_rect.width,
                height: glyph.source_rect.height
              )

              RL.draw_texture_pro(
                @texture,
                glyph.source_rect,
                dest_rect,
                RL::Vector2.zero,
                0.0f32,
                color
              )

              current_x += glyph.advance * @spacing
            else
              # Unknown character, advance by base size
              current_x += @base_size * 0.6f32 * @spacing
            end
          end
        end

        # Draw text with scale
        def draw_scaled(text : String, x : Float32, y : Float32, scale : Float32, color : RL::Color = RL::WHITE)
          current_x = x
          current_y = y

          text.each_char do |char|
            if char == '\n'
              current_x = x
              current_y += @line_height * scale * @line_spacing
              next
            end

            if glyph = @glyphs[char]?
              dest_rect = RL::Rectangle.new(
                x: current_x + glyph.offset.x * scale,
                y: current_y + glyph.offset.y * scale,
                width: glyph.source_rect.width * scale,
                height: glyph.source_rect.height * scale
              )

              RL.draw_texture_pro(
                @texture,
                glyph.source_rect,
                dest_rect,
                RL::Vector2.zero,
                0.0f32,
                color
              )

              current_x += glyph.advance * scale * @spacing
            else
              current_x += @base_size * 0.6f32 * scale * @spacing
            end
          end
        end

        # Measure text dimensions
        def measure(text : String) : RL::Vector2
          max_width = 0.0f32
          current_width = 0.0f32
          line_count = 1

          text.each_char do |char|
            if char == '\n'
              max_width = current_width if current_width > max_width
              current_width = 0.0f32
              line_count += 1
            elsif glyph = @glyphs[char]?
              current_width += glyph.advance * @spacing
            else
              current_width += @base_size * 0.6f32 * @spacing
            end
          end

          max_width = current_width if current_width > max_width

          RL::Vector2.new(
            x: max_width,
            y: line_count * @line_height * @line_spacing
          )
        end

        # Check if font has a specific character
        def has_char?(char : Char) : Bool
          @glyphs.has_key?(char)
        end

        # Get character width
        def char_width(char : Char) : Float32
          if glyph = @glyphs[char]?
            glyph.advance * @spacing
          else
            @base_size * 0.6f32 * @spacing
          end
        end

        # Add custom character mapping
        def add_glyph(char : Char, x : Int32, y : Int32, width : Int32, height : Int32, advance : Float32)
          glyph = Glyph.new(
            source_rect: RL::Rectangle.new(
              x: x.to_f32,
              y: y.to_f32,
              width: width.to_f32,
              height: height.to_f32
            ),
            offset: RL::Vector2.zero,
            advance: advance
          )

          @glyphs[char] = glyph
        end

        # Clone font with different settings
        def clone : BitmapFont
          font = BitmapFont.new(@texture, @base_size, @line_height)
          font.spacing = @spacing
          font.line_spacing = @line_spacing

          @glyphs.each do |char, glyph|
            font.glyphs[char] = glyph
          end

          font
        end

        # Cleanup
        def cleanup
          # Texture cleanup handled by owner
        end
      end

      # Bitmap font manager
      module BitmapFontManager
        extend self

        @@fonts = {} of String => BitmapFont
        @@default_font : BitmapFont?

        # Load and cache a font
        def load(name : String, font_path : String) : BitmapFont
          return @@fonts[name] if @@fonts.has_key?(name)

          font = BitmapFont.load(font_path)
          @@fonts[name] = font
          @@default_font ||= font
          font
        end

        # Load grid font
        def load_grid(name : String, texture_path : String, char_width : Int32, char_height : Int32) : BitmapFont
          return @@fonts[name] if @@fonts.has_key?(name)

          font = BitmapFont.load_grid(texture_path, char_width, char_height)
          @@fonts[name] = font
          @@default_font ||= font
          font
        end

        # Get cached font
        def get(name : String) : BitmapFont?
          @@fonts[name]?
        end

        # Get default font
        def default : BitmapFont?
          @@default_font
        end

        # Set default font
        def default=(name : String)
          if font = @@fonts[name]?
            @@default_font = font
          end
        end

        # Clear all fonts
        def clear
          @@fonts.clear
          @@default_font = nil
        end
      end
    end
  end
end
