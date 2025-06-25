require "raylib-cr"

module PointClickEngine
  module UI
    # Handles visual rendering for menu systems
    #
    # The MenuRenderer centralizes all rendering logic for menus including:
    # - Background and border rendering
    # - Text rendering with positioning
    # - Highlight effects and animations
    # - Layout calculations and positioning
    class MenuRenderer
      # Visual theme configuration
      struct MenuTheme
        property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 180)
        property border_color : RL::Color = RL::WHITE
        property text_color : RL::Color = RL::WHITE
        property highlight_color : RL::Color = RL::YELLOW
        property disabled_color : RL::Color = RL::GRAY
        property title_color : RL::Color = RL::YELLOW

        property border_width : Int32 = 2
        property padding : Int32 = 20
        property item_spacing : Int32 = 10
        property title_spacing : Int32 = 20

        property font_size : Int32 = 20
        property title_font_size : Int32 = 24

        def initialize
        end
      end

      # Animation state for menu effects
      struct AnimationState
        property highlight_pulse : Float32 = 0.0
        property fade_alpha : Float32 = 1.0
        property slide_offset : Float32 = 0.0
        property animation_time : Float64 = 0.0

        def initialize
        end
      end

      # Current theme and animation state
      property theme : MenuTheme = MenuTheme.new
      property animation : AnimationState = AnimationState.new

      # Layout configuration
      property center_horizontally : Bool = true
      property center_vertically : Bool = true
      property auto_size : Bool = true

      # Animation settings
      property enable_animations : Bool = true
      property pulse_speed : Float32 = 3.0
      property fade_speed : Float32 = 2.0

      def initialize
      end

      # Renders a complete menu with background, title, and items
      #
      # - *bounds* : Rectangle defining the menu area
      # - *title* : Menu title text
      # - *items* : Array of menu item texts
      # - *selected_index* : Currently selected item index
      # - *enabled_items* : Array indicating which items are enabled
      def draw_menu(bounds : RL::Rectangle, title : String, items : Array(String),
                    selected_index : Int32, enabled_items : Array(Bool)? = nil)
        # Update animations
        update_animations

        # Draw background
        draw_background(bounds)

        # Draw border
        draw_border(bounds)

        # Calculate content area
        content_bounds = calculate_content_bounds(bounds)

        # Draw title
        title_height = draw_title(content_bounds, title)

        # Draw menu items
        items_start_y = content_bounds.y + title_height + @theme.title_spacing
        draw_menu_items(content_bounds, items_start_y, items, selected_index, enabled_items)
      end

      # Draws menu background with theme styling
      def draw_background(bounds : RL::Rectangle)
        background_color = apply_fade(@theme.background_color)
        RL.draw_rectangle_rec(bounds, background_color)
      end

      # Draws menu border with theme styling
      def draw_border(bounds : RL::Rectangle)
        border_color = apply_fade(@theme.border_color)
        RL.draw_rectangle_lines_ex(bounds, @theme.border_width.to_f32, border_color)
      end

      # Draws menu title with proper positioning
      #
      # Returns: Height of the drawn title
      def draw_title(content_bounds : RL::Rectangle, title : String) : Int32
        return 0 if title.empty?

        title_color = apply_fade(@theme.title_color)
        title_width = RL.measure_text(title, @theme.title_font_size)

        title_x = if @center_horizontally
                    content_bounds.x + (content_bounds.width - title_width) / 2
                  else
                    content_bounds.x
                  end

        RL.draw_text(title, title_x.to_i, content_bounds.y.to_i, @theme.title_font_size, title_color)

        @theme.title_font_size
      end

      # Draws menu items with selection highlighting
      def draw_menu_items(content_bounds : RL::Rectangle, start_y : Float32, items : Array(String),
                          selected_index : Int32, enabled_items : Array(Bool)? = nil)
        items.each_with_index do |item, index|
          item_enabled = enabled_items.nil? || enabled_items[index]? || false
          item_y = start_y + index * (@theme.font_size + @theme.item_spacing)

          draw_menu_item(content_bounds, item, item_y, index == selected_index, item_enabled)
        end
      end

      # Draws individual menu item with proper styling
      def draw_menu_item(content_bounds : RL::Rectangle, text : String, y : Float32,
                         is_selected : Bool, is_enabled : Bool)
        # Calculate color based on state
        color = if !is_enabled
                  apply_fade(@theme.disabled_color)
                elsif is_selected
                  apply_highlight(@theme.highlight_color)
                else
                  apply_fade(@theme.text_color)
                end

        # Calculate position
        text_width = RL.measure_text(text, @theme.font_size)
        text_x = if @center_horizontally
                   content_bounds.x + (content_bounds.width - text_width) / 2
                 else
                   content_bounds.x
                 end

        # Add slide animation if enabled
        if @enable_animations && is_selected
          text_x += @animation.slide_offset
        end

        # Draw selection background if selected
        if is_selected && is_enabled
          draw_selection_background(text_x, y, text_width.to_f32, @theme.font_size.to_f32)
        end

        # Draw text
        RL.draw_text(text, text_x.to_i, y.to_i, @theme.font_size, color)
      end

      # Draws background highlight for selected items
      def draw_selection_background(x : Float32, y : Float32, width : Float32, height : Float32)
        padding = 5.0_f32
        bg_rect = RL::Rectangle.new(
          x: x - padding,
          y: y - padding / 2,
          width: width + padding * 2,
          height: height + padding
        )

        highlight_bg = RL::Color.new(
          r: @theme.highlight_color.r,
          g: @theme.highlight_color.g,
          b: @theme.highlight_color.b,
          a: 30
        )

        RL.draw_rectangle_rec(bg_rect, apply_fade(highlight_bg))
      end

      # Calculates content area within menu bounds
      def calculate_content_bounds(bounds : RL::Rectangle) : RL::Rectangle
        RL::Rectangle.new(
          x: bounds.x + @theme.padding,
          y: bounds.y + @theme.padding,
          width: bounds.width - @theme.padding * 2,
          height: bounds.height - @theme.padding * 2
        )
      end

      # Calculates required size for menu content
      def calculate_menu_size(title : String, items : Array(String)) : RL::Vector2
        # Calculate width needed
        title_width = title.empty? ? 0 : RL.measure_text(title, @theme.title_font_size)
        max_item_width = items.map { |item| RL.measure_text(item, @theme.font_size) }.max? || 0

        content_width = Math.max(title_width, max_item_width)
        total_width = content_width + @theme.padding * 2

        # Calculate height needed
        title_height = title.empty? ? 0 : @theme.title_font_size
        title_spacing = title.empty? ? 0 : @theme.title_spacing
        items_height = items.size * @theme.font_size + (items.size - 1) * @theme.item_spacing
        total_height = title_height + title_spacing + items_height + @theme.padding * 2

        RL::Vector2.new(x: total_width.to_f32, y: total_height.to_f32)
      end

      # Gets menu item bounds for interaction detection
      def get_item_bounds(menu_bounds : RL::Rectangle, title : String, item_index : Int32) : RL::Rectangle
        content_bounds = calculate_content_bounds(menu_bounds)
        title_height = title.empty? ? 0 : @theme.title_font_size
        title_spacing = title.empty? ? 0 : @theme.title_spacing

        item_y = content_bounds.y + title_height + title_spacing +
                 item_index * (@theme.font_size + @theme.item_spacing)

        RL::Rectangle.new(
          x: content_bounds.x,
          y: item_y - @theme.item_spacing / 2,
          width: content_bounds.width,
          height: @theme.font_size + @theme.item_spacing
        )
      end

      # Updates animation states
      def update_animations
        return unless @enable_animations

        @animation.animation_time = Time.monotonic.total_seconds

        # Update highlight pulse
        @animation.highlight_pulse = (Math.sin(@animation.animation_time * @pulse_speed) + 1.0) / 2.0

        # Update slide offset (subtle breathing effect)
        @animation.slide_offset = Math.sin(@animation.animation_time * 1.5) * 2.0
      end

      # Applies fade effect to color
      def apply_fade(color : RL::Color) : RL::Color
        fade_alpha = (@animation.fade_alpha * 255).to_u8
        RL::Color.new(r: color.r, g: color.g, b: color.b, a: fade_alpha)
      end

      # Applies highlight pulse effect to color
      def apply_highlight(color : RL::Color) : RL::Color
        return color unless @enable_animations

        pulse_intensity = @animation.highlight_pulse
        enhanced_brightness = (255 * (0.7 + 0.3 * pulse_intensity)).to_u8

        RL::Color.new(
          r: Math.min(255, (color.r * (0.8 + 0.4 * pulse_intensity)).to_u8),
          g: Math.min(255, (color.g * (0.8 + 0.4 * pulse_intensity)).to_u8),
          b: Math.min(255, (color.b * (0.8 + 0.4 * pulse_intensity)).to_u8),
          a: color.a
        )
      end

      # Sets fade animation state
      def set_fade_alpha(alpha : Float32)
        @animation.fade_alpha = alpha.clamp(0.0, 1.0)
      end

      # Animates fade in effect
      def animate_fade_in(duration : Float32 = 0.3)
        # This would be called externally to control fade timing
        @animation.fade_alpha = 0.0
      end

      # Animates fade out effect
      def animate_fade_out(duration : Float32 = 0.3)
        # This would be called externally to control fade timing
        @animation.fade_alpha = 1.0
      end

      # Updates theme from configuration
      def update_theme_from_config(config : Hash(String, String))
        if bg_color = config["background_color"]?
          @theme.background_color = parse_color(bg_color)
        end

        if text_color = config["text_color"]?
          @theme.text_color = parse_color(text_color)
        end

        if highlight_color = config["highlight_color"]?
          @theme.highlight_color = parse_color(highlight_color)
        end

        if font_size = config["font_size"]?
          @theme.font_size = font_size.to_i
        end

        if padding = config["padding"]?
          @theme.padding = padding.to_i
        end
      end

      # Parses color from string representation
      private def parse_color(color_string : String) : RL::Color
        # Simple color parsing - could be enhanced
        case color_string.downcase
        when "white"  then RL::WHITE
        when "black"  then RL::BLACK
        when "yellow" then RL::YELLOW
        when "gray"   then RL::GRAY
        when "red"    then RL::RED
        when "green"  then RL::GREEN
        when "blue"   then RL::BLUE
        else               RL::WHITE
        end
      end

      # Gets current theme as configuration hash
      def get_theme_config : Hash(String, String)
        {
          "background_color"   => color_to_string(@theme.background_color),
          "text_color"         => color_to_string(@theme.text_color),
          "highlight_color"    => color_to_string(@theme.highlight_color),
          "font_size"          => @theme.font_size.to_s,
          "padding"            => @theme.padding.to_s,
          "animations_enabled" => @enable_animations.to_s,
        }
      end

      # Converts color to string representation
      private def color_to_string(color : RL::Color) : String
        "#{color.r},#{color.g},#{color.b},#{color.a}"
      end

      # Validates theme configuration
      def validate_theme : Array(String)
        issues = [] of String

        if @theme.font_size <= 0
          issues << "Font size must be positive"
        end

        if @theme.padding < 0
          issues << "Padding cannot be negative"
        end

        if @theme.item_spacing < 0
          issues << "Item spacing cannot be negative"
        end

        issues
      end
    end
  end
end
