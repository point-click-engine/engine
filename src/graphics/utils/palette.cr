# Color palette management utilities

require "raylib-cr"
require "./color"

module PointClickEngine
  module Graphics
    module Utils
      # Color palette for retro-style graphics
      class Palette
        # Palette entry with name and color
        struct Entry
          property name : String
          property color : RL::Color

          def initialize(@name : String, @color : RL::Color)
          end
        end

        property name : String
        property colors : Array(Entry)
        property color_map : Hash(String, Int32)

        def initialize(@name : String)
          @colors = [] of Entry
          @color_map = {} of String => Int32
        end

        # Add a color to the palette
        def add_color(name : String, color : RL::Color) : Int32
          index = @colors.size
          @colors << Entry.new(name, color)
          @color_map[name] = index
          index
        end

        # Add color from hex string
        def add_hex(name : String, hex : String) : Int32?
          if color = Color.from_hex(hex)
            add_color(name, color)
          end
        end

        # Get color by index
        def [](index : Int32) : RL::Color?
          @colors[index]?.try(&.color)
        end

        # Get color by name
        def [](name : String) : RL::Color?
          if index = @color_map[name]?
            @colors[index].color
          end
        end

        # Get color index by name
        def index_of(name : String) : Int32?
          @color_map[name]?
        end

        # Find closest color in palette
        def find_closest(color : RL::Color) : Int32
          best_index = 0
          best_distance = Float32::MAX

          @colors.each_with_index do |entry, i|
            distance = color_distance(color, entry.color)
            if distance < best_distance
              best_distance = distance
              best_index = i
            end
          end

          best_index
        end

        # Map image to palette colors
        def remap_image(image : RL::Image) : RL::Image
          result = RL.image_copy(image)

          # Process each pixel
          image.height.times do |y|
            image.width.times do |x|
              pixel = RL.get_image_color(image, x, y)
              closest_index = find_closest(pixel)
              if new_color = self[closest_index]
                RL.image_draw_pixel(result, x, y, new_color)
              end
            end
          end

          result
        end

        # Create gradient between two palette colors
        def gradient(from_name : String, to_name : String, steps : Int32) : Array(RL::Color)?
          from_color = self[from_name]
          to_color = self[to_name]

          if from_color && to_color
            Color.gradient(from_color, to_color, steps)
          end
        end

        # Size of palette
        def size : Int32
          @colors.size
        end

        # Iterate over colors
        def each(&)
          @colors.each do |entry|
            yield entry
          end
        end

        # Export to array
        def to_a : Array(RL::Color)
          @colors.map(&.color)
        end

        # Clone palette
        def clone : Palette
          palette = Palette.new(@name)
          @colors.each do |entry|
            palette.add_color(entry.name, entry.color)
          end
          palette
        end

        private def color_distance(c1 : RL::Color, c2 : RL::Color) : Float32
          # Simple RGB distance, could use better color space
          dr = (c1.r - c2.r).to_f32
          dg = (c1.g - c2.g).to_f32
          db = (c1.b - c2.b).to_f32
          Math.sqrt(dr * dr + dg * dg + db * db)
        end
      end

      # Predefined palettes
      module Palettes
        extend self

        # CGA 16-color palette
        def cga : Palette
          palette = Palette.new("CGA")
          palette.add_hex("black", "000000")
          palette.add_hex("blue", "0000AA")
          palette.add_hex("green", "00AA00")
          palette.add_hex("cyan", "00AAAA")
          palette.add_hex("red", "AA0000")
          palette.add_hex("magenta", "AA00AA")
          palette.add_hex("brown", "AA5500")
          palette.add_hex("light_gray", "AAAAAA")
          palette.add_hex("dark_gray", "555555")
          palette.add_hex("light_blue", "5555FF")
          palette.add_hex("light_green", "55FF55")
          palette.add_hex("light_cyan", "55FFFF")
          palette.add_hex("light_red", "FF5555")
          palette.add_hex("light_magenta", "FF55FF")
          palette.add_hex("yellow", "FFFF55")
          palette.add_hex("white", "FFFFFF")
          palette
        end

        # EGA 64-color palette (subset shown)
        def ega : Palette
          palette = Palette.new("EGA")
          # Add standard 16 colors
          palette.add_hex("black", "000000")
          palette.add_hex("blue", "0000AA")
          palette.add_hex("green", "00AA00")
          palette.add_hex("cyan", "00AAAA")
          palette.add_hex("red", "AA0000")
          palette.add_hex("magenta", "AA00AA")
          palette.add_hex("brown", "AA5500")
          palette.add_hex("light_gray", "AAAAAA")
          palette.add_hex("dark_gray", "555555")
          palette.add_hex("light_blue", "5555FF")
          palette.add_hex("light_green", "55FF55")
          palette.add_hex("light_cyan", "55FFFF")
          palette.add_hex("light_red", "FF5555")
          palette.add_hex("light_magenta", "FF55FF")
          palette.add_hex("yellow", "FFFF55")
          palette.add_hex("white", "FFFFFF")
          palette
        end

        # Game Boy palette
        def gameboy : Palette
          palette = Palette.new("GameBoy")
          palette.add_hex("darkest", "0F380F")
          palette.add_hex("dark", "306230")
          palette.add_hex("light", "8BAC0F")
          palette.add_hex("lightest", "9BBD0F")
          palette
        end

        # NES palette (subset)
        def nes : Palette
          palette = Palette.new("NES")
          palette.add_hex("black", "000000")
          palette.add_hex("white", "FFFFFF")
          palette.add_hex("gray", "9D9D9D")
          palette.add_hex("red", "FF0000")
          palette.add_hex("orange", "FF8000")
          palette.add_hex("yellow", "FFFF00")
          palette.add_hex("green", "00FF00")
          palette.add_hex("blue", "0000FF")
          palette.add_hex("purple", "8000FF")
          palette.add_hex("pink", "FF00FF")
          palette
        end

        # Sepia palette for old photo effect
        def sepia : Palette
          palette = Palette.new("Sepia")
          palette.add_hex("darkest", "2B1B0F")
          palette.add_hex("dark", "4A2F1F")
          palette.add_hex("medium_dark", "6B4A30")
          palette.add_hex("medium", "8B6542")
          palette.add_hex("medium_light", "AA8054")
          palette.add_hex("light", "C99B66")
          palette.add_hex("lighter", "E8B677")
          palette.add_hex("lightest", "FFD089")
          palette
        end

        # Night vision palette
        def night_vision : Palette
          palette = Palette.new("NightVision")
          palette.add_hex("black", "000000")
          palette.add_hex("darkest", "001100")
          palette.add_hex("darker", "002200")
          palette.add_hex("dark", "003300")
          palette.add_hex("medium_dark", "005500")
          palette.add_hex("medium", "007700")
          palette.add_hex("medium_light", "009900")
          palette.add_hex("light", "00BB00")
          palette.add_hex("lighter", "00DD00")
          palette.add_hex("lightest", "00FF00")
          palette
        end

        # Create custom palette from image
        def from_image(image : RL::Image, max_colors : Int32 = 256, name : String = "Custom") : Palette
          palette = Palette.new(name)
          color_counts = {} of UInt32 => Int32

          # Count unique colors
          image.height.times do |y|
            image.width.times do |x|
              color = RL.get_image_color(image, x, y)
              # Pack color into single value for hashing
              packed = (color.r.to_u32 << 24) | (color.g.to_u32 << 16) | (color.b.to_u32 << 8) | color.a.to_u32
              color_counts[packed] = color_counts.fetch(packed, 0) + 1
            end
          end

          # Sort by frequency and take top colors
          sorted_colors = color_counts.to_a.sort_by { |_, count| -count }

          sorted_colors.first(max_colors).each_with_index do |(packed, _), i|
            r = ((packed >> 24) & 0xFF).to_u8
            g = ((packed >> 16) & 0xFF).to_u8
            b = ((packed >> 8) & 0xFF).to_u8
            a = (packed & 0xFF).to_u8

            color = RL::Color.new(r: r, g: g, b: b, a: a)
            palette.add_color("color_#{i}", color)
          end

          palette
        end
      end

      # Palette cycling for animation effects
      class PaletteCycler
        property palette : Palette
        property cycle_indices : Array(Int32)
        property cycle_speed : Float32
        property current_offset : Float32

        def initialize(@palette : Palette, @cycle_indices : Array(Int32), @cycle_speed : Float32 = 1.0f32)
          @current_offset = 0.0f32
          @temp_colors = [] of RL::Color
        end

        # Update cycle animation
        def update(delta_time : Float32)
          @current_offset += @cycle_speed * delta_time

          while @current_offset >= 1.0f32
            @current_offset -= 1.0f32
            cycle_colors
          end
        end

        # Get current palette state
        def current_palette : Palette
          @palette
        end

        # Reset cycling
        def reset
          @current_offset = 0.0f32
        end

        private def cycle_colors
          return if @cycle_indices.size < 2

          # Save colors to cycle
          @temp_colors.clear
          @cycle_indices.each do |i|
            if color = @palette[i]
              @temp_colors << color
            end
          end

          # Rotate colors
          return if @temp_colors.empty?

          last_color = @temp_colors.last
          (@temp_colors.size - 1).downto(1) do |i|
            @temp_colors[i] = @temp_colors[i - 1]
          end
          @temp_colors[0] = last_color

          # Apply back to palette
          @cycle_indices.each_with_index do |palette_index, i|
            if i < @temp_colors.size && palette_index < @palette.colors.size
              @palette.colors[palette_index] = Palette::Entry.new(
                @palette.colors[palette_index].name,
                @temp_colors[i]
              )
            end
          end
        end
      end
    end
  end
end
