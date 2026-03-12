# Color manipulation utilities

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Utils
      # Color utility functions
      module Color
        extend self

        # Interpolate between two colors
        def lerp(start : RL::Color, end_color : RL::Color, t : Float32) : RL::Color
          t = t.clamp(0.0f32, 1.0f32)

          RL::Color.new(
            r: (start.r + (end_color.r - start.r) * t).to_u8,
            g: (start.g + (end_color.g - start.g) * t).to_u8,
            b: (start.b + (end_color.b - start.b) * t).to_u8,
            a: (start.a + (end_color.a - start.a) * t).to_u8
          )
        end

        # Convert HSV to RGB
        def hsv_to_rgb(h : Float32, s : Float32, v : Float32) : RL::Color
          h = h % 360.0f32
          s = s.clamp(0.0f32, 1.0f32)
          v = v.clamp(0.0f32, 1.0f32)

          c = v * s
          x = c * (1.0f32 - ((h / 60.0f32) % 2.0f32 - 1.0f32).abs)
          m = v - c

          r, g, b = case (h / 60.0f32).to_i
                    when 0 then {c, x, 0.0f32}
                    when 1 then {x, c, 0.0f32}
                    when 2 then {0.0f32, c, x}
                    when 3 then {0.0f32, x, c}
                    when 4 then {x, 0.0f32, c}
                    else        {c, 0.0f32, x}
                    end

          RL::Color.new(
            r: ((r + m) * 255).to_u8,
            g: ((g + m) * 255).to_u8,
            b: ((b + m) * 255).to_u8,
            a: 255
          )
        end

        # Convert RGB to HSV
        def rgb_to_hsv(color : RL::Color) : Tuple(Float32, Float32, Float32)
          r = color.r / 255.0f32
          g = color.g / 255.0f32
          b = color.b / 255.0f32

          max = Math.max(r, Math.max(g, b))
          min = Math.min(r, Math.min(g, b))
          delta = max - min

          # Hue
          h = if delta == 0
                0.0f32
              elsif max == r
                60.0f32 * (((g - b) / delta) % 6)
              elsif max == g
                60.0f32 * ((b - r) / delta + 2)
              else
                60.0f32 * ((r - g) / delta + 4)
              end

          # Saturation
          s = max == 0 ? 0.0f32 : delta / max

          # Value
          v = max

          {h, s, v}
        end

        # Brighten a color
        def brighten(color : RL::Color, amount : Float32) : RL::Color
          h, s, v = rgb_to_hsv(color)
          v = (v + amount).clamp(0.0f32, 1.0f32)
          result = hsv_to_rgb(h, s, v)
          result.a = color.a
          result
        end

        # Darken a color
        def darken(color : RL::Color, amount : Float32) : RL::Color
          brighten(color, -amount)
        end

        # Saturate a color
        def saturate(color : RL::Color, amount : Float32) : RL::Color
          h, s, v = rgb_to_hsv(color)
          s = (s + amount).clamp(0.0f32, 1.0f32)
          result = hsv_to_rgb(h, s, v)
          result.a = color.a
          result
        end

        # Desaturate a color
        def desaturate(color : RL::Color, amount : Float32) : RL::Color
          saturate(color, -amount)
        end

        # Convert to grayscale
        def grayscale(color : RL::Color) : RL::Color
          # Use luminance formula
          gray = (0.299f32 * color.r + 0.587f32 * color.g + 0.114f32 * color.b).to_u8
          RL::Color.new(r: gray, g: gray, b: gray, a: color.a)
        end

        # Invert a color
        def invert(color : RL::Color) : RL::Color
          RL::Color.new(
            r: (255 - color.r).to_u8,
            g: (255 - color.g).to_u8,
            b: (255 - color.b).to_u8,
            a: color.a
          )
        end

        # Mix two colors
        def mix(color1 : RL::Color, color2 : RL::Color, weight : Float32 = 0.5f32) : RL::Color
          lerp(color1, color2, weight)
        end

        # Apply opacity
        def with_alpha(color : RL::Color, alpha : Float32) : RL::Color
          RL::Color.new(
            r: color.r,
            g: color.g,
            b: color.b,
            a: (alpha * 255).clamp(0, 255).to_u8
          )
        end

        # Parse color from string
        def from_string(str : String) : RL::Color?
          case str.downcase
          when "white"                  then RL::WHITE
          when "black"                  then RL::BLACK
          when "red"                    then RL::RED
          when "green"                  then RL::GREEN
          when "blue"                   then RL::BLUE
          when "yellow"                 then RL::YELLOW
          when "orange"                 then RL::ORANGE
          when "purple"                 then RL::PURPLE
          when "pink"                   then RL::PINK
          when "gray", "grey"           then RL::GRAY
          when "lightgray", "lightgrey" then RL::LIGHTGRAY
          when "darkgray", "darkgrey"   then RL::DARKGRAY
          when "brown"                  then RL::BROWN
          when "gold"                   then RL::GOLD
          when "lime"                   then RL::LIME
          when "skyblue"                then RL::SKYBLUE
          when "darkblue"               then RL::DARKBLUE
          when "darkgreen"              then RL::DARKGREEN
          when "maroon"                 then RL::MAROON
          when "violet"                 then RL::VIOLET
          when "magenta"                then RL::MAGENTA
          when "beige"                  then RL::BEIGE
          else
            from_hex(str)
          end
        end

        # Parse color from hex string
        def from_hex(hex : String) : RL::Color?
          # Remove # if present
          hex = hex.lstrip('#')

          return nil unless hex.size == 6 || hex.size == 8

          begin
            r = hex[0..1].to_i(16).to_u8
            g = hex[2..3].to_i(16).to_u8
            b = hex[4..5].to_i(16).to_u8
            a = hex.size == 8 ? hex[6..7].to_i(16).to_u8 : 255_u8

            RL::Color.new(r: r, g: g, b: b, a: a)
          rescue
            nil
          end
        end

        # Convert color to hex string
        def to_hex(color : RL::Color, include_alpha : Bool = false) : String
          if include_alpha
            "#%02X%02X%02X%02X" % [color.r, color.g, color.b, color.a]
          else
            "#%02X%02X%02X" % [color.r, color.g, color.b]
          end
        end

        # Create gradient array
        def gradient(start_color : RL::Color, end_color : RL::Color, steps : Int32) : Array(RL::Color)
          return [start_color] if steps <= 1

          colors = [] of RL::Color
          steps.times do |i|
            t = i.to_f32 / (steps - 1)
            colors << lerp(start_color, end_color, t)
          end
          colors
        end

        # Create rainbow gradient
        def rainbow(steps : Int32, saturation : Float32 = 1.0f32, value : Float32 = 1.0f32) : Array(RL::Color)
          colors = [] of RL::Color
          steps.times do |i|
            hue = (i.to_f32 / steps) * 360.0f32
            colors << hsv_to_rgb(hue, saturation, value)
          end
          colors
        end

        # Apply sepia tone
        def sepia(color : RL::Color) : RL::Color
          r = (0.393f32 * color.r + 0.769f32 * color.g + 0.189f32 * color.b).clamp(0, 255).to_u8
          g = (0.349f32 * color.r + 0.686f32 * color.g + 0.168f32 * color.b).clamp(0, 255).to_u8
          b = (0.272f32 * color.r + 0.534f32 * color.g + 0.131f32 * color.b).clamp(0, 255).to_u8

          RL::Color.new(r: r, g: g, b: b, a: color.a)
        end

        # Calculate contrast ratio between two colors
        def contrast_ratio(color1 : RL::Color, color2 : RL::Color) : Float32
          l1 = luminance(color1)
          l2 = luminance(color2)

          lighter = Math.max(l1, l2)
          darker = Math.min(l1, l2)

          (lighter + 0.05f32) / (darker + 0.05f32)
        end

        # Calculate relative luminance
        def luminance(color : RL::Color) : Float32
          r = color.r / 255.0f32
          g = color.g / 255.0f32
          b = color.b / 255.0f32

          # Apply gamma correction
          r = r <= 0.03928f32 ? r / 12.92f32 : ((r + 0.055f32) / 1.055f32) ** 2.4f32
          g = g <= 0.03928f32 ? g / 12.92f32 : ((g + 0.055f32) / 1.055f32) ** 2.4f32
          b = b <= 0.03928f32 ? b / 12.92f32 : ((b + 0.055f32) / 1.055f32) ** 2.4f32

          0.2126f32 * r + 0.7152f32 * g + 0.0722f32 * b
        end
      end
    end
  end
end
