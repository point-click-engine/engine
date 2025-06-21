# Floating dialog text system for Simon the Sorcerer 1 style conversations
# Displays colored text above character heads during dialog

require "raylib-cr"

module PointClickEngine
  module UI
    # Style options for floating dialog text
    enum DialogStyle
      Bubble    # Speech bubble with tail
      Rectangle # Simple rounded rectangle background
      Thought   # Thought bubble (cloud-like)
      Shout     # Emphasized text with special effects
      Whisper   # Small, subtle text
      Narrator  # Centered text for narration
    end

    # Word wrapping helper
    struct WrappedText
      property lines : Array(String)
      property total_width : Int32
      property total_height : Int32

      def initialize(@lines : Array(String), @total_width : Int32, @total_height : Int32)
      end
    end

    # Individual floating dialog instance
    class FloatingDialog
      property text : String
      property character_name : String
      property character_position : RL::Vector2
      property color : RL::Color
      property background_color : RL::Color
      property duration : Float32
      property elapsed : Float32 = 0.0f32
      property style : DialogStyle = DialogStyle::Bubble
      property font_size : Int32 = 16
      property max_width : Int32 = 300
      property visible : Bool = true

      # Animation properties
      property float_offset : Float32 = 0.0f32
      property float_speed : Float32 = 30.0f32
      property float_amplitude : Float32 = 8.0f32
      property fade_alpha : Float32 = 255.0f32
      property scale : Float32 = 1.0f32

      # Typewriter effect
      property typewriter_enabled : Bool = false
      property typewriter_speed : Float32 = 30.0f32 # characters per second
      property visible_characters : Int32 = 0

      # Cached wrapped text
      @wrapped_text : WrappedText?
      @position_cache : RL::Vector2?

      def initialize(@text : String, @character_name : String, @character_position : RL::Vector2, @duration : Float32)
        @color = determine_character_color(@character_name)
        @background_color = RL::Color.new(r: 0, g: 0, b: 0, a: 180)

        # Enable typewriter for longer text
        @typewriter_enabled = @text.size > 20
        @visible_characters = @typewriter_enabled ? 0 : @text.size
      end

      # Update the floating dialog
      def update(dt : Float32) : Bool
        @elapsed += dt

        # Update floating animation
        @float_offset = Math.sin(@elapsed * @float_speed / 10.0f32) * @float_amplitude

        # Update typewriter effect
        if @typewriter_enabled && @visible_characters < @text.size
          @visible_characters = Math.min(@text.size, (@elapsed * @typewriter_speed).to_i)
        end

        # Update fade out near end of duration
        fade_start = @duration * 0.8f32
        if @elapsed > fade_start
          fade_progress = (@elapsed - fade_start) / (@duration - fade_start)
          @fade_alpha = 255.0f32 * (1.0f32 - fade_progress)
        end

        # Update scale animation for emphasis styles
        case @style
        when .shout?
          @scale = 1.0f32 + Math.sin(@elapsed * 10.0f32) * 0.1f32
        when .whisper?
          @scale = 0.8f32
        else
          @scale = 1.0f32
        end

        # Return false when dialog should be removed
        @elapsed >= @duration
      end

      # Draw the floating dialog
      def draw
        return unless @visible && @fade_alpha > 0

        position = calculate_position
        wrapped = get_wrapped_text

        # Apply alpha to colors
        text_color = apply_alpha(@color, @fade_alpha)
        bg_color = apply_alpha(@background_color, @fade_alpha)

        case @style
        when .bubble?
          draw_speech_bubble(position, wrapped, text_color, bg_color)
        when .thought?
          draw_thought_bubble(position, wrapped, text_color, bg_color)
        when .rectangle?
          draw_rectangle_background(position, wrapped, text_color, bg_color)
        when .shout?
          draw_shout_text(position, wrapped, text_color)
        when .whisper?
          draw_whisper_text(position, wrapped, text_color)
        when .narrator?
          draw_narrator_text(position, wrapped, text_color, bg_color)
        end
      end

      # Calculate screen position above character
      private def calculate_position : RL::Vector2
        # Cache position calculation for performance
        return @position_cache.not_nil! if @position_cache

        wrapped = get_wrapped_text

        # Position above character's head
        x = @character_position.x - (wrapped.total_width / 2)
        y = @character_position.y - 80 - wrapped.total_height + @float_offset

        # Keep on screen
        margin = 10
        x = Math.max(margin, Math.min(x, RL.get_screen_width - wrapped.total_width - margin))
        y = Math.max(margin, y)

        @position_cache = RL::Vector2.new(x: x, y: y)
        @position_cache.not_nil!
      end

      # Get wrapped text with caching
      private def get_wrapped_text : WrappedText
        return @wrapped_text.not_nil! if @wrapped_text

        display_text = @typewriter_enabled ? @text[0, @visible_characters] : @text
        @wrapped_text = wrap_text(display_text, @max_width, @font_size)
        @wrapped_text.not_nil!
      end

      # Wrap text to fit within max width
      private def wrap_text(text : String, max_width : Int32, font_size : Int32) : WrappedText
        words = text.split(' ')
        lines = [] of String
        current_line = ""

        words.each do |word|
          test_line = current_line.empty? ? word : "#{current_line} #{word}"
          test_width = RL.measure_text(test_line, font_size)

          if test_width <= max_width
            current_line = test_line
          else
            lines << current_line unless current_line.empty?
            current_line = word
          end
        end

        lines << current_line unless current_line.empty?

        # Calculate total dimensions
        total_width = lines.map { |line| RL.measure_text(line, font_size) }.max? || 0
        total_height = lines.size * (font_size + 4)

        WrappedText.new(lines, total_width, total_height)
      end

      # Apply alpha to color
      private def apply_alpha(color : RL::Color, alpha : Float32) : RL::Color
        RL::Color.new(r: color.r, g: color.g, b: color.b, a: (alpha * (color.a / 255.0f32)).to_u8)
      end

      # Determine character-specific color
      private def determine_character_color(name : String) : RL::Color
        case name.downcase
        when "player", "hero", "simon", "detective"
          RL::Color.new(r: 255, g: 255, b: 255, a: 255) # White
        when "wizard", "mage", "sorcerer"
          RL::Color.new(r: 138, g: 43, b: 226, a: 255) # Purple
        when "butler", "servant"
          RL::Color.new(r: 139, g: 69, b: 19, a: 255) # Brown
        when "scientist", "doctor"
          RL::Color.new(r: 0, g: 191, b: 255, a: 255) # Light blue
        when "guard", "soldier"
          RL::Color.new(r: 255, g: 0, b: 0, a: 255) # Red
        when "merchant", "shopkeeper"
          RL::Color.new(r: 255, g: 215, b: 0, a: 255) # Gold
        else
          RL::Color.new(r: 200, g: 200, b: 200, a: 255) # Light gray
        end
      end

      # Draw speech bubble style
      private def draw_speech_bubble(pos : RL::Vector2, wrapped : WrappedText, text_color : RL::Color, bg_color : RL::Color)
        padding = 12
        bubble_rect = RL::Rectangle.new(
          x: pos.x - padding,
          y: pos.y - padding,
          width: wrapped.total_width + padding * 2,
          height: wrapped.total_height + padding * 2
        )

        # Draw bubble background
        RL.draw_rectangle_rounded(bubble_rect, 0.3f32, 8, bg_color)
        RL.draw_rectangle_rounded_lines(bubble_rect, 0.3f32, 8, 2.0f32, text_color)

        # Draw tail pointing to character
        draw_bubble_tail(bubble_rect, text_color, bg_color)

        # Draw text
        draw_wrapped_text(pos, wrapped, text_color)
      end

      # Draw thought bubble style
      private def draw_thought_bubble(pos : RL::Vector2, wrapped : WrappedText, text_color : RL::Color, bg_color : RL::Color)
        padding = 12
        bubble_rect = RL::Rectangle.new(
          x: pos.x - padding,
          y: pos.y - padding,
          width: wrapped.total_width + padding * 2,
          height: wrapped.total_height + padding * 2
        )

        # Draw cloud-like background
        RL.draw_rectangle_rounded(bubble_rect, 0.5f32, 12, bg_color)

        # Draw small thought bubbles leading to character
        draw_thought_bubbles(bubble_rect, bg_color)

        # Draw text
        draw_wrapped_text(pos, wrapped, text_color)
      end

      # Draw simple rectangle background
      private def draw_rectangle_background(pos : RL::Vector2, wrapped : WrappedText, text_color : RL::Color, bg_color : RL::Color)
        padding = 8
        bg_rect = RL::Rectangle.new(
          x: pos.x - padding,
          y: pos.y - padding,
          width: wrapped.total_width + padding * 2,
          height: wrapped.total_height + padding * 2
        )

        RL.draw_rectangle_rounded(bg_rect, 0.2f32, 4, bg_color)
        draw_wrapped_text(pos, wrapped, text_color)
      end

      # Draw emphasized shout text
      private def draw_shout_text(pos : RL::Vector2, wrapped : WrappedText, text_color : RL::Color)
        # Draw with outline and larger size
        scaled_pos = RL::Vector2.new(x: pos.x * @scale, y: pos.y * @scale)
        outline_color = RL::Color.new(r: 0, g: 0, b: 0, a: text_color.a)

        # Draw outline
        (-1..1).each do |dx|
          (-1..1).each do |dy|
            next if dx == 0 && dy == 0
            offset_pos = RL::Vector2.new(x: scaled_pos.x + dx, y: scaled_pos.y + dy)
            draw_wrapped_text(offset_pos, wrapped, outline_color, (@font_size * @scale).to_i)
          end
        end

        # Draw main text
        draw_wrapped_text(scaled_pos, wrapped, text_color, (@font_size * @scale).to_i)
      end

      # Draw subtle whisper text
      private def draw_whisper_text(pos : RL::Vector2, wrapped : WrappedText, text_color : RL::Color)
        whisper_color = RL::Color.new(r: text_color.r, g: text_color.g, b: text_color.b, a: (text_color.a * 0.7f32).to_u8)
        draw_wrapped_text(pos, wrapped, whisper_color, (@font_size * @scale).to_i)
      end

      # Draw narrator text (centered)
      private def draw_narrator_text(pos : RL::Vector2, wrapped : WrappedText, text_color : RL::Color, bg_color : RL::Color)
        # Center on screen
        screen_center = RL::Vector2.new(x: RL.get_screen_width / 2, y: RL.get_screen_height / 4)
        centered_pos = RL::Vector2.new(x: screen_center.x - wrapped.total_width / 2, y: screen_center.y)

        draw_rectangle_background(centered_pos, wrapped, text_color, bg_color)
      end

      # Helper to draw wrapped text lines
      private def draw_wrapped_text(pos : RL::Vector2, wrapped : WrappedText, color : RL::Color, font_size : Int32 = @font_size)
        wrapped.lines.each_with_index do |line, i|
          line_y = pos.y + i * (font_size + 4)
          RL.draw_text(line, pos.x.to_i, line_y.to_i, font_size, color)
        end
      end

      # Draw speech bubble tail
      private def draw_bubble_tail(bubble_rect : RL::Rectangle, line_color : RL::Color, fill_color : RL::Color)
        tail_size = 15
        tail_x = bubble_rect.x + bubble_rect.width / 2
        tail_y = bubble_rect.y + bubble_rect.height

        # Triangle pointing down to character
        RL.draw_triangle(
          RL::Vector2.new(x: tail_x - tail_size, y: tail_y),
          RL::Vector2.new(x: tail_x + tail_size, y: tail_y),
          RL::Vector2.new(x: tail_x, y: tail_y + tail_size),
          fill_color
        )
      end

      # Draw thought bubble trail
      private def draw_thought_bubbles(bubble_rect : RL::Rectangle, color : RL::Color)
        base_x = bubble_rect.x + bubble_rect.width / 2
        base_y = bubble_rect.y + bubble_rect.height

        # Draw small circles leading to character
        (1..3).each do |i|
          radius = 8 - i * 2
          circle_y = base_y + i * 15
          RL.draw_circle(base_x.to_i, circle_y.to_i, radius.to_f32, color)
        end
      end
    end

    # Manager for multiple floating dialogs
    class FloatingDialogManager
      property active_dialogs : Array(FloatingDialog)
      property max_concurrent : Int32 = 3
      property default_duration : Float32 = 4.0f32
      property enable_floating : Bool = true

      def initialize
        @active_dialogs = [] of FloatingDialog
      end

      # Show floating dialog for character
      def show_dialog(character_name : String, text : String, character_pos : RL::Vector2,
                      duration : Float32? = nil, style : DialogStyle = DialogStyle::Bubble)
        return unless @enable_floating

        # Remove oldest dialog if at max capacity
        if @active_dialogs.size >= @max_concurrent
          @active_dialogs.shift
        end

        actual_duration = duration || calculate_duration(text)
        dialog = FloatingDialog.new(text, character_name, character_pos, actual_duration)
        dialog.style = style

        @active_dialogs << dialog
      end

      # Update all active dialogs
      def update(dt : Float32)
        # Update dialogs and remove expired ones
        @active_dialogs.reject! do |dialog|
          !dialog.update(dt)
        end
      end

      # Draw all active dialogs
      def draw
        return unless @enable_floating
        @active_dialogs.each(&.draw)
      end

      # Clear all dialogs
      def clear_all
        @active_dialogs.clear
      end

      # Check if any dialogs are active
      def has_active_dialogs? : Bool
        !@active_dialogs.empty?
      end

      # Calculate duration based on text length
      private def calculate_duration(text : String) : Float32
        base_duration = 2.0f32
        reading_speed = 15.0f32 # characters per second
        calculated = base_duration + (text.size / reading_speed)
        Math.min(calculated, 8.0f32) # Max 8 seconds
      end
    end
  end
end
