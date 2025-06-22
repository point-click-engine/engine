# Enhanced floating text system with dialog choices support
# Displays text above characters with clickable choices

module PointClickEngine
  module UI
    # Floating text that follows a character
    class FloatingText
      property text : String
      property character_name : String
      property target_position : RL::Vector2
      property choices : Array(DialogChoice) = [] of DialogChoice
      property visible : Bool = true
      property fade_alpha : Float32 = 255.0f32

      # Visual properties
      property font_size : Int32 = 16
      property max_width : Int32 = 300
      property text_color : RL::Color
      property background_color : RL::Color
      property choice_color : RL::Color = RL::WHITE
      property choice_hover_color : RL::Color = RL::YELLOW
      property padding : Int32 = 12
      property line_spacing : Int32 = 4
      property choice_spacing : Int32 = 8

      # Animation properties
      property fade_in_duration : Float32 = 0.3f32
      property fade_out_duration : Float32 = 0.3f32
      property float_amplitude : Float32 = 5.0f32
      property float_speed : Float32 = 2.0f32

      # State
      property elapsed_time : Float32 = 0.0f32
      property is_fading_in : Bool = true
      property is_fading_out : Bool = false
      property selected_choice : Int32? = nil
      property on_choice_selected : Proc(Int32, Nil)?
      property on_text_completed : Proc(Nil)?

      # Cached values
      @wrapped_lines : Array(String)?
      @text_bounds : RL::Rectangle?
      @choice_rects : Array(RL::Rectangle)?
      @total_height : Float32 = 0.0f32

      def initialize(@text : String, @character_name : String, @target_position : RL::Vector2)
        @text_color = determine_character_color(@character_name)
        @background_color = RL::Color.new(r: 0, g: 0, b: 0, a: 200)
      end

      # Add a dialog choice
      def add_choice(text : String, &action : -> Nil)
        @choices << DialogChoice.new(text, action)
        invalidate_cache
      end

      # Update position to follow character
      def update_position(new_position : RL::Vector2)
        if @target_position.x != new_position.x || @target_position.y != new_position.y
          @target_position = new_position
          invalidate_cache
        end
      end

      # Update the floating text
      def update(dt : Float32) : Bool
        @elapsed_time += dt

        # Handle fade in
        if @is_fading_in
          fade_progress = @elapsed_time / @fade_in_duration
          if fade_progress >= 1.0f32
            @is_fading_in = false
            @fade_alpha = 255.0f32
          else
            @fade_alpha = 255.0f32 * fade_progress
          end
        end

        # Handle fade out
        if @is_fading_out
          fade_progress = (@elapsed_time - @fade_out_start_time) / @fade_out_duration
          if fade_progress >= 1.0f32
            @visible = false
            return false # Remove this floating text
          else
            @fade_alpha = 255.0f32 * (1.0f32 - fade_progress)
          end
        end

        # Handle mouse input for choices
        if !@choices.empty? && !@is_fading_out
          handle_choice_input
        end

        @visible
      end

      # Start fade out animation
      def start_fade_out
        unless @is_fading_out
          @is_fading_out = true
          @fade_out_start_time = @elapsed_time
        end
      end

      # Draw the floating text
      def draw
        return unless @visible && @fade_alpha > 0

        # Calculate position with floating animation
        float_offset = Math.sin(@elapsed_time * @float_speed) * @float_amplitude
        screen_pos = calculate_screen_position(float_offset)

        # Apply alpha to colors
        bg_color = apply_alpha(@background_color, @fade_alpha)
        text_color = apply_alpha(@text_color, @fade_alpha)

        # Draw background
        bounds = get_text_bounds
        adjusted_bounds = RL::Rectangle.new(
          x: screen_pos.x,
          y: screen_pos.y,
          width: bounds.width,
          height: bounds.height
        )

        # Draw rounded rectangle background
        RL.draw_rectangle_rounded(adjusted_bounds, 0.3f32, 8, bg_color)
        RL.draw_rectangle_rounded_lines(adjusted_bounds, 0.3f32, 8, 2.0f32, text_color)

        # Draw speech bubble tail
        if !@choices.empty? || @text.size > 20
          draw_bubble_tail(adjusted_bounds, text_color, bg_color)
        end

        # Draw text lines
        lines = get_wrapped_lines
        text_y = screen_pos.y + @padding

        lines.each do |line|
          RL.draw_text(line, (screen_pos.x + @padding).to_i, text_y.to_i, @font_size, text_color)
          text_y += @font_size + @line_spacing
        end

        # Draw choices if any
        if !@choices.empty?
          draw_choices(screen_pos, text_color)
        end
      end

      private def handle_choice_input
        return if @choices.empty?

        mouse_pos = RL.get_mouse_position
        choice_rects = get_choice_rects

        # Check for hover
        hovered_choice = nil
        choice_rects.each_with_index do |rect, index|
          if RL.check_collision_point_rec?(mouse_pos, rect)
            hovered_choice = index
            break
          end
        end

        # Handle click
        if RL::MouseButton::Left.pressed? && hovered_choice
          @selected_choice = hovered_choice
          choice = @choices[hovered_choice]
          choice.action.call
          @on_choice_selected.try &.call(hovered_choice)
          start_fade_out
        end
      end

      private def draw_choices(base_pos : RL::Vector2, text_color : RL::Color)
        choice_rects = get_choice_rects
        mouse_pos = RL.get_mouse_position

        @choices.each_with_index do |choice, index|
          rect = choice_rects[index]

          # Check if mouse is hovering
          is_hovering = RL.check_collision_point_rec?(mouse_pos, rect)
          color = is_hovering ? apply_alpha(@choice_hover_color, @fade_alpha) : apply_alpha(@choice_color, @fade_alpha)

          # Draw choice background if hovering
          if is_hovering
            hover_bg = apply_alpha(RL::Color.new(r: 255, g: 255, b: 255, a: 30), @fade_alpha)
            RL.draw_rectangle_rounded(rect, 0.2f32, 4, hover_bg)
          end

          # Draw choice text
          choice_text = "• #{choice.text}"
          RL.draw_text(choice_text, rect.x.to_i, rect.y.to_i, @font_size, color)
        end
      end

      private def draw_bubble_tail(bubble_rect : RL::Rectangle, line_color : RL::Color, fill_color : RL::Color)
        tail_size = 12
        tail_x = bubble_rect.x + bubble_rect.width / 2
        tail_y = bubble_rect.y + bubble_rect.height

        # Triangle pointing down to character
        RL.draw_triangle(
          RL::Vector2.new(x: tail_x - tail_size, y: tail_y),
          RL::Vector2.new(x: tail_x + tail_size, y: tail_y),
          RL::Vector2.new(x: @target_position.x, y: @target_position.y - 20),
          fill_color
        )
      end

      private def calculate_screen_position(float_offset : Float32) : RL::Vector2
        bounds = get_text_bounds

        # Position above character's head
        x = @target_position.x - (bounds.width / 2)
        y = @target_position.y - 80 - bounds.height + float_offset

        # Keep on screen
        margin = 10
        screen_width = RL.get_screen_width
        screen_height = RL.get_screen_height

        x = Math.max(margin, Math.min(x, screen_width - bounds.width - margin))
        y = Math.max(margin, Math.min(y, screen_height - bounds.height - margin))

        RL::Vector2.new(x: x, y: y)
      end

      private def get_wrapped_lines : Array(String)
        return @wrapped_lines.not_nil! if @wrapped_lines

        words = @text.split(' ')
        lines = [] of String
        current_line = ""

        words.each do |word|
          test_line = current_line.empty? ? word : "#{current_line} #{word}"
          test_width = RL.measure_text(test_line, @font_size)

          if test_width <= @max_width
            current_line = test_line
          else
            lines << current_line unless current_line.empty?
            current_line = word
          end
        end

        lines << current_line unless current_line.empty?
        @wrapped_lines = lines
        lines
      end

      private def get_text_bounds : RL::Rectangle
        return @text_bounds.not_nil! if @text_bounds

        lines = get_wrapped_lines

        # Calculate text dimensions
        max_width = lines.map { |line| RL.measure_text(line, @font_size) }.max? || 0
        text_height = lines.size * (@font_size + @line_spacing)

        # Add space for choices
        choice_height = 0
        if !@choices.empty?
          choice_height = @choice_spacing + (@choices.size * (@font_size + @choice_spacing))
        end

        total_width = max_width + (@padding * 2)
        total_height = text_height + choice_height + (@padding * 2)

        @total_height = total_height
        @text_bounds = RL::Rectangle.new(x: 0, y: 0, width: total_width, height: total_height)
        @text_bounds.not_nil!
      end

      private def get_choice_rects : Array(RL::Rectangle)
        return @choice_rects.not_nil! if @choice_rects

        lines = get_wrapped_lines
        text_height = lines.size * (@font_size + @line_spacing)

        rects = [] of RL::Rectangle
        screen_pos = calculate_screen_position(0)

        choice_y = screen_pos.y + @padding + text_height + @choice_spacing

        @choices.each_with_index do |choice, index|
          choice_text = "• #{choice.text}"
          choice_width = RL.measure_text(choice_text, @font_size)

          rect = RL::Rectangle.new(
            x: screen_pos.x + @padding,
            y: choice_y,
            width: choice_width.to_f32,
            height: @font_size.to_f32
          )

          rects << rect
          choice_y += @font_size + @choice_spacing
        end

        @choice_rects = rects
        rects
      end

      private def invalidate_cache
        @wrapped_lines = nil
        @text_bounds = nil
        @choice_rects = nil
      end

      private def apply_alpha(color : RL::Color, alpha : Float32) : RL::Color
        RL::Color.new(
          r: color.r,
          g: color.g,
          b: color.b,
          a: (alpha * (color.a / 255.0f32)).to_u8
        )
      end

      private def determine_character_color(name : String) : RL::Color
        case name.downcase
        when "player", "hero", "simon", "detective"
          RL::Color.new(r: 255, g: 255, b: 255, a: 255) # White
        when "wizard", "mage", "sorcerer"
          RL::Color.new(r: 138, g: 43, b: 226, a: 255) # Purple
        when "butler", "servant"
          RL::Color.new(r: 139, g: 69, b: 19, a: 255) # Brown
        when "scientist", "doctor", "professor"
          RL::Color.new(r: 0, g: 191, b: 255, a: 255) # Light blue
        when "guard", "soldier"
          RL::Color.new(r: 255, g: 0, b: 0, a: 255) # Red
        when "merchant", "shopkeeper"
          RL::Color.new(r: 255, g: 215, b: 0, a: 255) # Gold
        else
          RL::Color.new(r: 200, g: 200, b: 200, a: 255) # Light gray
        end
      end

      @fade_out_start_time : Float32 = 0.0f32
    end

    # Manager for floating text instances
    class FloatingTextManager
      property active_texts : Array(FloatingText) = [] of FloatingText
      property default_duration : Float32 = 4.0f32
      property auto_dismiss : Bool = true

      def initialize
      end

      # Show floating text for a character
      def show_text(character_name : String, text : String, position : RL::Vector2, duration : Float32? = nil) : FloatingText
        floating_text = FloatingText.new(text, character_name, position)

        if @auto_dismiss && duration
          # Set up auto-dismiss timer
          dismiss_time = duration
          floating_text.on_text_completed = -> {
            schedule_fade_out(floating_text, dismiss_time)
          }
        end

        @active_texts << floating_text
        floating_text
      end

      # Show floating text with choices
      def show_choice(character_name : String, prompt : String, choices : Array(String),
                      position : RL::Vector2, callback : Proc(Int32, Nil)) : FloatingText
        floating_text = FloatingText.new(prompt, character_name, position)

        choices.each_with_index do |choice_text, index|
          floating_text.add_choice(choice_text) do
            callback.call(index)
          end
        end

        floating_text.on_choice_selected = ->(choice : Int32) {
          # Choice was selected, text will fade out automatically
        }

        @active_texts << floating_text
        floating_text
      end

      # Update all floating texts
      def update(dt : Float32)
        @active_texts.reject! do |text|
          !text.update(dt)
        end
      end

      # Draw all floating texts
      def draw
        # Draw in reverse order so newer texts appear on top
        @active_texts.reverse_each(&.draw)
      end

      # Update character position for all their floating texts
      def update_character_position(character_name : String, new_position : RL::Vector2)
        @active_texts.each do |text|
          if text.character_name == character_name
            text.update_position(new_position)
          end
        end
      end

      # Clear all floating texts
      def clear_all
        @active_texts.clear
      end

      # Clear texts for specific character
      def clear_character_texts(character_name : String)
        @active_texts.reject! { |text| text.character_name == character_name }
      end

      # Check if character has active text
      def has_active_text?(character_name : String) : Bool
        @active_texts.any? { |text| text.character_name == character_name && text.visible }
      end

      private def schedule_fade_out(text : FloatingText, delay : Float32)
        # This would need a proper timer system in a real implementation
        # For now, we'll use a simple approach
        text.start_fade_out
      end
    end
  end
end
