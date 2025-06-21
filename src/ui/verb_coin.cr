# Verb coin interface for Simon the Sorcerer 1 style interactions
# Displays verbs in a circular pattern when right-clicking

require "./cursor_manager"

module PointClickEngine
  module UI
    # Verb coin for circular verb selection
    class VerbCoin
      property verbs : Array(VerbType)
      property active : Bool = false
      property selected_verb : VerbType?
      property position : RL::Vector2
      property radius : Float32 = 60.0f32
      property icon_radius : Float32 = 40.0f32
      property fade_alpha : Float32 = 0.0f32
      property animation_speed : Float32 = 5.0f32

      # Visual settings
      property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 180)
      property border_color : RL::Color = RL::Color.new(r: 100, g: 100, b: 100, a: 255)
      property text_color : RL::Color = RL::Color.new(r: 255, g: 255, b: 255, a: 255)
      property highlight_color : RL::Color = RL::Color.new(r: 255, g: 215, b: 0, a: 255)

      # Verb icon mappings
      @verb_icons : Hash(VerbType, String)
      @verb_descriptions : Hash(VerbType, String)

      def initialize
        @verbs = [] of VerbType
        @position = RL::Vector2.new(x: 0, y: 0)
        @verb_icons = {
          VerbType::Walk  => "👣",
          VerbType::Look  => "👁",
          VerbType::Talk  => "💬",
          VerbType::Use   => "👆",
          VerbType::Take  => "✋",
          VerbType::Open  => "🔓",
          VerbType::Close => "🔒",
          VerbType::Push  => "👊",
          VerbType::Pull  => "🤏",
          VerbType::Give  => "🤝",
        }

        @verb_descriptions = {
          VerbType::Walk  => "Walk to",
          VerbType::Look  => "Look at",
          VerbType::Talk  => "Talk to",
          VerbType::Use   => "Use",
          VerbType::Take  => "Take",
          VerbType::Open  => "Open",
          VerbType::Close => "Close",
          VerbType::Push  => "Push",
          VerbType::Pull  => "Pull",
          VerbType::Give  => "Give",
        }
      end

      # Show verb coin at position with applicable verbs
      def show(pos : RL::Vector2, applicable_verbs : Array(VerbType))
        @position = pos
        @verbs = applicable_verbs.empty? ? all_verbs : applicable_verbs
        @active = true
        @fade_alpha = 0.0f32
        @selected_verb = @verbs.first if !@verbs.empty?
      end

      # Hide verb coin
      def hide
        @active = false
        @fade_alpha = 0.0f32
        @selected_verb = nil
      end

      # Update verb coin state
      def update(dt : Float32)
        return unless @active

        # Update fade animation
        target_alpha = @active ? 255.0f32 : 0.0f32
        @fade_alpha += (target_alpha - @fade_alpha) * @animation_speed * dt

        # Update selected verb based on mouse position
        mouse_pos = Raylib.get_mouse_position
        update_selection(mouse_pos)

        # Check for left click to select verb
        if Raylib.mouse_button_pressed?(Raylib::MouseButton::Left.to_i)
          hide
        end

        # Check for right click or escape to cancel
        if Raylib.mouse_button_pressed?(Raylib::MouseButton::Right.to_i) || Raylib.key_pressed?(Raylib::KeyboardKey::Escape)
          hide
        end
      end

      # Update verb selection based on mouse position
      private def update_selection(mouse_pos : RL::Vector2)
        return if @verbs.empty?

        # Calculate angle from center to mouse
        dx = mouse_pos.x - @position.x
        dy = mouse_pos.y - @position.y
        distance = Math.sqrt(dx*dx + dy*dy)

        # Only update selection if mouse is within reasonable distance
        if distance > 20 && distance < @radius * 2
          angle = Math.atan2(dy, dx)

          # Normalize angle to 0-2π range
          angle += 2 * Math::PI if angle < 0

          # Calculate verb index based on angle
          # Start from top (90 degrees) and go clockwise
          normalized_angle = (angle + Math::PI/2) % (2 * Math::PI)
          verb_index = (normalized_angle / (2 * Math::PI) * @verbs.size).to_i

          @selected_verb = @verbs[verb_index % @verbs.size]
        end
      end

      # Draw the verb coin
      def draw
        return unless @active && @fade_alpha > 0

        alpha_factor = @fade_alpha / 255.0f32

        # Draw background circle
        bg_color = apply_alpha(@background_color, alpha_factor)
        RL.draw_circle(@position.x.to_i, @position.y.to_i, @radius, bg_color)

        # Draw border
        border_color = apply_alpha(@border_color, alpha_factor)
        RL.draw_circle_lines(@position.x.to_i, @position.y.to_i, @radius.to_i, border_color)

        # Draw verb icons and text
        draw_verb_icons(alpha_factor)

        # Draw selection indicator
        if selected = @selected_verb
          draw_selection_indicator(selected, alpha_factor)
        end
      end

      # Draw verb icons arranged in circle
      private def draw_verb_icons(alpha_factor : Float32)
        return if @verbs.empty?

        @verbs.each_with_index do |verb, i|
          # Calculate position for this verb
          angle = (i.to_f / @verbs.size) * 2 * Math::PI - Math::PI/2
          x = @position.x + Math.cos(angle) * @icon_radius
          y = @position.y + Math.sin(angle) * @icon_radius

          # Determine color (highlight if selected)
          is_selected = verb == @selected_verb
          color = is_selected ? @highlight_color : @text_color
          color = apply_alpha(color, alpha_factor)

          # Draw icon (using text for now, could be replaced with actual icons)
          icon = @verb_icons[verb]? || verb.to_s[0].to_s.upcase
          draw_centered_text(icon, x, y, 24, color)

          # Draw verb name below icon
          verb_name = verb.to_s.capitalize
          text_y = y + 20
          draw_centered_text(verb_name, x, text_y, 12, color)
        end
      end

      # Draw selection indicator around selected verb
      private def draw_selection_indicator(selected_verb : VerbType, alpha_factor : Float32)
        verb_index = @verbs.index(selected_verb)
        return unless verb_index

        # Calculate position
        angle = (verb_index.to_f / @verbs.size) * 2 * Math::PI - Math::PI/2
        x = @position.x + Math.cos(angle) * @icon_radius
        y = @position.y + Math.sin(angle) * @icon_radius

        # Draw highlight circle
        highlight_color = apply_alpha(@highlight_color, alpha_factor)
        RL.draw_circle_lines(x.to_i, y.to_i, 25, highlight_color)

        # Draw selection arrow or indicator
        arrow_x = @position.x + Math.cos(angle) * (@icon_radius - 15)
        arrow_y = @position.y + Math.sin(angle) * (@icon_radius - 15)
        RL.draw_circle(arrow_x.to_i, arrow_y.to_i, 3, highlight_color)
      end

      # Get all available verbs
      private def all_verbs : Array(VerbType)
        [
          VerbType::Walk,
          VerbType::Look,
          VerbType::Talk,
          VerbType::Use,
          VerbType::Take,
          VerbType::Open,
        ]
      end

      # Apply alpha to color
      private def apply_alpha(color : RL::Color, alpha_factor : Float32) : RL::Color
        RL::Color.new(
          r: color.r,
          g: color.g,
          b: color.b,
          a: (color.a * alpha_factor).to_u8
        )
      end

      # Draw text centered at position
      private def draw_centered_text(text : String, x : Float32, y : Float32, font_size : Int32, color : RL::Color)
        text_width = RL.measure_text(text, font_size)
        text_x = x - text_width / 2
        text_y = y - font_size / 2
        RL.draw_text(text, text_x.to_i, text_y.to_i, font_size, color)
      end

      # Get currently selected verb
      def get_selected_verb : VerbType?
        @selected_verb
      end

      # Check if verb coin is currently active
      def is_active? : Bool
        @active
      end

      # Get verb description for status display
      def get_verb_description(verb : VerbType) : String
        @verb_descriptions[verb]? || verb.to_s.capitalize
      end
    end
  end
end
