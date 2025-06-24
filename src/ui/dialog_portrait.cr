# Dialog portrait system for character conversations
# Displays animated character portraits during dialog with expressions and animations

require "yaml"

module PointClickEngine
  module UI
    # Portrait display position options
    enum PortraitPosition
      BottomLeft
      BottomRight
      TopLeft
      TopRight
      Center
      Dynamic # Position based on character location
    end

    # Portrait animation states
    enum PortraitExpression
      Neutral
      Happy
      Sad
      Angry
      Surprised
      Thinking
      Worried
      Excited
      Disgusted
      Fear
    end

    # Portrait frame data for animation
    struct PortraitFrame
      include YAML::Serializable

      property expression : PortraitExpression
      property frame_rect : RL::Rectangle
      property duration : Float32 = 0.1f32

      def initialize(@expression : PortraitExpression, @frame_rect : RL::Rectangle, @duration : Float32 = 0.1f32)
      end
    end

    # Animated character portrait for dialog scenes
    class DialogPortrait
      property character_name : String
      property portrait_texture : RL::Texture2D?
      property frames : Hash(PortraitExpression, Array(PortraitFrame))
      property current_expression : PortraitExpression = PortraitExpression::Neutral
      property position : PortraitPosition = PortraitPosition::BottomLeft
      property size : RL::Vector2 = RL::Vector2.new(x: 128, y: 128)
      property visible : Bool = false
      property talking : Bool = false

      # Animation state
      property current_frame : Int32 = 0
      property frame_timer : Float32 = 0.0f32
      property animation_speed : Float32 = 0.3f32

      # Blinking animation
      property blink_timer : Float32 = 0.0f32
      property blink_interval : Float32 = 3.0f32
      property blink_duration : Float32 = 0.15f32
      property is_blinking : Bool = false

      # Mouth animation for talking
      property mouth_frames : Array(RL::Rectangle) = [] of RL::Rectangle
      property mouth_frame_index : Int32 = 0
      property mouth_timer : Float32 = 0.0f32
      property mouth_speed : Float32 = 0.2f32

      # Visual effects
      property fade_alpha : Float32 = 255.0f32
      property scale : Float32 = 1.0f32
      property tint : RL::Color = RL::WHITE

      def initialize(@character_name : String)
        @frames = {} of PortraitExpression => Array(PortraitFrame)
        setup_default_frames
      end

      # Load portrait texture from file
      def load_texture(path : String) : Bool
        return false unless File.exists?(path)

        @portrait_texture = RL.load_texture(path)
        true
      end

      # Add animation frames for a specific expression
      def add_expression_frames(expression : PortraitExpression, frame_rects : Array(RL::Rectangle), frame_duration : Float32 = 0.1f32)
        frames_array = frame_rects.map { |rect| PortraitFrame.new(expression, rect, frame_duration) }
        @frames[expression] = frames_array
      end

      # Add mouth animation frames for talking
      def add_mouth_frames(mouth_rects : Array(RL::Rectangle))
        @mouth_frames = mouth_rects
      end

      # Set current expression with smooth transition
      def set_expression(expression : PortraitExpression, immediate : Bool = false)
        return if @current_expression == expression && !immediate

        @current_expression = expression
        @current_frame = 0
        @frame_timer = 0.0f32
      end

      # Start talking animation
      def start_talking
        @talking = true
        @mouth_frame_index = 0
        @mouth_timer = 0.0f32
      end

      # Stop talking animation
      def stop_talking
        @talking = false
        @mouth_frame_index = 0
      end

      # Show portrait with fade-in effect
      def show(fade_in : Bool = true)
        @visible = true
        if fade_in
          @fade_alpha = 0.0f32
        else
          @fade_alpha = 255.0f32
        end
      end

      # Hide portrait with fade-out effect
      def hide(fade_out : Bool = true)
        if fade_out
          # Fade out will be handled in update
          @visible = false
        else
          @visible = false
          @fade_alpha = 0.0f32
        end
      end

      # Update portrait animations
      def update(dt : Float32)
        return unless @visible

        # Update fade animation
        if @visible && @fade_alpha < 255.0f32
          @fade_alpha = Math.min(255.0f32, @fade_alpha + (255.0f32 * dt * 3.0f32))
        elsif !@visible && @fade_alpha > 0.0f32
          @fade_alpha = Math.max(0.0f32, @fade_alpha - (255.0f32 * dt * 3.0f32))
        end

        # Update expression animation
        update_expression_animation(dt)

        # Update blinking
        update_blinking(dt)

        # Update mouth animation if talking
        if @talking
          update_mouth_animation(dt)
        end
      end

      # Draw the portrait at the specified screen position
      def draw(screen_pos : RL::Vector2)
        return unless @visible && @fade_alpha > 0.0f32
        return unless texture = @portrait_texture

        # Calculate drawing parameters
        current_tint = RL::Color.new(r: @tint.r, g: @tint.g, b: @tint.b, a: @fade_alpha.to_u8)
        dest_rect = RL::Rectangle.new(x: screen_pos.x, y: screen_pos.y, width: @size.x * @scale, height: @size.y * @scale)

        # Get current frame for expression
        current_frame_rect = get_current_frame_rect

        # Draw portrait background/frame
        draw_portrait_frame(dest_rect)

        # Draw main portrait
        RL.draw_texture_pro(texture, current_frame_rect, dest_rect, RL::Vector2.new(x: 0, y: 0), 0.0f32, current_tint)

        # Draw mouth animation if talking
        if @talking && !@mouth_frames.empty?
          mouth_rect = @mouth_frames[@mouth_frame_index % @mouth_frames.size]
          RL.draw_texture_pro(texture, mouth_rect, dest_rect, RL::Vector2.new(x: 0, y: 0), 0.0f32, current_tint)
        end

        # Draw blink overlay if blinking
        if @is_blinking
          draw_blink_overlay(dest_rect, current_tint)
        end
      end

      # Get screen position based on portrait position setting
      def get_screen_position(screen_width : Int32, screen_height : Int32, character_pos : RL::Vector2? = nil) : RL::Vector2
        margin = 20.0f32

        case @position
        when .bottom_left?
          RL::Vector2.new(x: margin, y: screen_height - @size.y - margin)
        when .bottom_right?
          RL::Vector2.new(x: screen_width - @size.x - margin, y: screen_height - @size.y - margin)
        when .top_left?
          RL::Vector2.new(x: margin, y: margin)
        when .top_right?
          RL::Vector2.new(x: screen_width - @size.x - margin, y: margin)
        when .center?
          RL::Vector2.new(x: (screen_width - @size.x) / 2, y: (screen_height - @size.y) / 2)
        when .dynamic?
          if char_pos = character_pos
            # Position portrait based on character location
            if char_pos.x < screen_width / 2
              RL::Vector2.new(x: screen_width - @size.x - margin, y: screen_height - @size.y - margin)
            else
              RL::Vector2.new(x: margin, y: screen_height - @size.y - margin)
            end
          else
            # Fallback to bottom left
            RL::Vector2.new(x: margin, y: screen_height - @size.y - margin)
          end
        else
          RL::Vector2.new(x: margin, y: screen_height - @size.y - margin)
        end
      end

      # Cleanup resources
      def cleanup
        if texture = @portrait_texture
          RL.unload_texture(texture)
          @portrait_texture = nil
        end
      end

      # Setup default frame rectangles (assuming single portrait image)
      private def setup_default_frames
        # Default frame covers entire texture (will be updated when texture is loaded)
        default_rect = RL::Rectangle.new(x: 0, y: 0, width: 128, height: 128)

        PortraitExpression.each do |expression|
          @frames[expression] = [PortraitFrame.new(expression, default_rect)]
        end
      end

      # Update expression animation frames
      private def update_expression_animation(dt : Float32)
        frames_for_expression = @frames[@current_expression]?
        return unless frames_for_expression && frames_for_expression.size > 1

        @frame_timer += dt
        current_frame_data = frames_for_expression[@current_frame]

        if @frame_timer >= current_frame_data.duration
          @frame_timer = 0.0f32
          @current_frame = (@current_frame + 1) % frames_for_expression.size
        end
      end

      # Update blinking animation
      private def update_blinking(dt : Float32)
        @blink_timer += dt

        if @is_blinking
          if @blink_timer >= @blink_duration
            @is_blinking = false
            @blink_timer = 0.0f32
          end
        else
          if @blink_timer >= @blink_interval
            @is_blinking = true
            @blink_timer = 0.0f32
          end
        end
      end

      # Update mouth animation for talking
      private def update_mouth_animation(dt : Float32)
        return if @mouth_frames.empty?

        @mouth_timer += dt

        if @mouth_timer >= @mouth_speed
          @mouth_timer = 0.0f32
          @mouth_frame_index = (@mouth_frame_index + 1) % @mouth_frames.size
        end
      end

      # Get current frame rectangle for the active expression
      private def get_current_frame_rect : RL::Rectangle
        frames_for_expression = @frames[@current_expression]?
        return RL::Rectangle.new(x: 0, y: 0, width: 128, height: 128) unless frames_for_expression

        frame_index = Math.min(@current_frame, frames_for_expression.size - 1)
        frames_for_expression[frame_index].frame_rect
      end

      # Draw decorative frame around portrait
      private def draw_portrait_frame(dest_rect : RL::Rectangle)
        frame_thickness = 4
        frame_color = RL::Color.new(r: 139, g: 69, b: 19, a: @fade_alpha.to_u8) # Brown frame

        # Draw frame border
        RL.draw_rectangle_lines_ex(dest_rect, frame_thickness.to_f32, frame_color)

        # Draw inner shadow
        shadow_rect = RL::Rectangle.new(
          x: dest_rect.x + 2,
          y: dest_rect.y + 2,
          width: dest_rect.width - 4,
          height: dest_rect.height - 4
        )
        shadow_color = RL::Color.new(r: 0, g: 0, b: 0, a: (50 * (@fade_alpha / 255.0f32)).to_u8)
        RL.draw_rectangle_lines_ex(shadow_rect, 1.0f32, shadow_color)
      end

      # Draw blink overlay
      private def draw_blink_overlay(dest_rect : RL::Rectangle, tint : RL::Color)
        # Simple blink effect - darken the eye area
        eye_height = dest_rect.height * 0.15f32
        eye_y = dest_rect.y + (dest_rect.height * 0.35f32)

        blink_rect = RL::Rectangle.new(
          x: dest_rect.x,
          y: eye_y,
          width: dest_rect.width,
          height: eye_height
        )

        blink_color = RL::Color.new(r: 0, g: 0, b: 0, a: (tint.a * 0.8f32).to_u8)
        RL.draw_rectangle_rec(blink_rect, blink_color)
      end
    end

    # Manager for multiple character portraits
    class PortraitManager
      property portraits : Hash(String, DialogPortrait)
      property active_portrait : String?
      property default_position : PortraitPosition = PortraitPosition::BottomLeft

      def initialize
        @portraits = {} of String => DialogPortrait
      end

      # Add a character portrait
      def add_portrait(character_name : String, texture_path : String) : DialogPortrait
        portrait = DialogPortrait.new(character_name)
        portrait.load_texture(texture_path)
        portrait.position = @default_position
        @portraits[character_name] = portrait
        portrait
      end

      # Show portrait for character
      def show_portrait(character_name : String, expression : PortraitExpression = PortraitExpression::Neutral)
        # Hide current portrait
        if current_name = @active_portrait
          @portraits[current_name]?.try(&.hide)
        end

        # Show new portrait
        if portrait = @portraits[character_name]?
          portrait.set_expression(expression)
          portrait.show
          @active_portrait = character_name
        end
      end

      # Hide current portrait
      def hide_portrait
        if current_name = @active_portrait
          @portraits[current_name]?.try(&.hide)
          @active_portrait = nil
        end
      end

      # Start talking animation for current portrait
      def start_talking
        if current_name = @active_portrait
          @portraits[current_name]?.try(&.start_talking)
        end
      end

      # Stop talking animation for current portrait
      def stop_talking
        if current_name = @active_portrait
          @portraits[current_name]?.try(&.stop_talking)
        end
      end

      # Set expression for current portrait
      def set_expression(expression : PortraitExpression)
        if current_name = @active_portrait
          @portraits[current_name]?.try(&.set_expression(expression))
        end
      end

      # Update all portraits
      def update(dt : Float32)
        @portraits.values.each(&.update(dt))
      end

      # Draw active portrait
      def draw
        return unless current_name = @active_portrait
        return unless portrait = @portraits[current_name]?

        # Use game dimensions for portrait positioning
        game_width = 1024
        game_height = 768
        screen_pos = portrait.get_screen_position(game_width, game_height)
        portrait.draw(screen_pos)
      end

      # Cleanup all portraits
      def cleanup
        @portraits.values.each(&.cleanup)
        @portraits.clear
      end
    end
  end
end
