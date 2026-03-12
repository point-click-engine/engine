# Dialog rendering for speech bubbles and dialog boxes

require "./nine_patch"
require "./text_renderer"

module PointClickEngine
  module Graphics
    module UI
      # Dialog box style
      enum DialogStyle
        SpeechBubble
        ThoughtBubble
        Narration
        SystemMessage
        Custom
      end

      # Dialog box anchor position
      enum DialogAnchor
        TopLeft
        TopCenter
        TopRight
        MiddleLeft
        MiddleCenter
        MiddleRight
        BottomLeft
        BottomCenter
        BottomRight
        AboveTarget # Above a character/object
        BelowTarget # Below a character/object
      end

      # Dialog renderer for various dialog types
      class DialogRenderer
        # Dialog box properties
        property nine_patch : NinePatch?
        property padding : Float32 = 16.0f32
        property min_width : Float32 = 100.0f32
        property max_width : Float32 = 400.0f32
        property min_height : Float32 = 50.0f32

        # Text properties
        property text_renderer : TextRenderer
        property text_color : RL::Color = RL::BLACK
        property line_spacing : Float32 = 1.2f32

        # Speech bubble tail
        property show_tail : Bool = true
        property tail_width : Float32 = 20.0f32
        property tail_height : Float32 = 15.0f32
        property tail_offset : Float32 = 0.0f32 # Offset from center

        # Animation
        property typewriter_speed : Float32 = 30.0f32 # Characters per second
        property fade_speed : Float32 = 3.0f32        # Fade in/out speed

        # Current state
        getter current_text : String = ""
        getter typewriter_progress : Float32 = 0.0f32
        getter opacity : Float32 = 1.0f32
        getter visible : Bool = false

        def initialize(@nine_patch : NinePatch? = nil)
          @text_renderer = TextRenderer.new
          @text_renderer.color = @text_color
          @text_renderer.word_wrap = true
        end

        # Show dialog with text
        def show(text : String, instant : Bool = false)
          @current_text = text
          @visible = true
          @typewriter_progress = instant ? 1.0f32 : 0.0f32
          @opacity = instant ? 1.0f32 : 0.0f32
        end

        # Hide dialog
        def hide(instant : Bool = false)
          if instant
            @visible = false
            @opacity = 0.0f32
          else
            # Will fade out
          end
        end

        # Skip typewriter animation
        def skip_typewriter
          @typewriter_progress = 1.0f32
        end

        # Update animation
        def update(dt : Float32)
          return unless @visible

          # Update fade
          if @opacity < 1.0f32
            @opacity = Math.min(@opacity + @fade_speed * dt, 1.0f32)
          end

          # Update typewriter
          if @typewriter_progress < 1.0f32
            chars_total = @current_text.size
            progress_per_second = 1.0f32 / chars_total * @typewriter_speed
            @typewriter_progress = Math.min(@typewriter_progress + progress_per_second * dt, 1.0f32)
          end

          # Handle fade out
          if !@visible && @opacity > 0.0f32
            @opacity = Math.max(@opacity - @fade_speed * dt, 0.0f32)
          end
        end

        # Draw dialog at position
        def draw(x : Float32, y : Float32, width : Float32? = nil,
                 anchor : DialogAnchor = DialogAnchor::TopLeft,
                 target_pos : RL::Vector2? = nil)
          return if @opacity <= 0.0f32 || @current_text.empty?

          # Calculate dialog dimensions
          actual_width = width || calculate_width
          wrapped_text = @text_renderer.wrap_text(@current_text, actual_width - @padding * 2)
          text_height = wrapped_text.size * @text_renderer.font_size * @line_spacing
          dialog_height = text_height + @padding * 2

          # Apply anchor positioning
          pos = calculate_position(x, y, actual_width, dialog_height, anchor, target_pos)

          # Draw with opacity
          alpha = (@opacity * 255).to_u8

          # Draw nine-patch background
          if patch = @nine_patch
            original_tint = patch.tint
            patch.tint = RL::Color.new(
              r: original_tint.r,
              g: original_tint.g,
              b: original_tint.b,
              a: alpha
            )
            patch.draw(pos.x, pos.y, actual_width, dialog_height)
            patch.tint = original_tint
          else
            # Fallback to simple rectangle
            bg_color = RL::Color.new(r: 240, g: 240, b: 240, a: alpha)
            RL.draw_rectangle(pos.x.to_i, pos.y.to_i, actual_width.to_i, dialog_height.to_i, bg_color)
            border_color = RL::Color.new(r: 0, g: 0, b: 0, a: alpha)
            RL.draw_rectangle_lines(pos.x.to_i, pos.y.to_i, actual_width.to_i, dialog_height.to_i, border_color)
          end

          # Draw tail for speech bubble
          if @show_tail && target_pos
            draw_tail(pos.x + actual_width/2 + @tail_offset, pos.y + dialog_height,
              target_pos, alpha)
          end

          # Draw text with typewriter effect
          visible_chars = (@current_text.size * @typewriter_progress).to_i
          visible_text = @current_text[0...visible_chars]

          # Apply opacity to text
          original_color = @text_renderer.color
          @text_renderer.color = RL::Color.new(
            r: original_color.r,
            g: original_color.g,
            b: original_color.b,
            a: alpha
          )

          @text_renderer.draw_wrapped(
            visible_text,
            pos.x + @padding,
            pos.y + @padding,
            actual_width - @padding * 2,
            TextAlign::Left,
            @line_spacing
          )

          @text_renderer.color = original_color
        end

        # Draw dialog following a target
        def draw_at_target(target_pos : RL::Vector2, anchor : DialogAnchor = DialogAnchor::AboveTarget)
          case anchor
          when .above_target?
            draw(target_pos.x, target_pos.y - 50, nil, DialogAnchor::BottomCenter, target_pos)
          when .below_target?
            draw(target_pos.x, target_pos.y + 50, nil, DialogAnchor::TopCenter, target_pos)
          else
            draw(target_pos.x, target_pos.y, nil, anchor, target_pos)
          end
        end

        # Check if dialog is fully visible
        def fully_visible? : Bool
          @visible && @opacity >= 1.0f32 && @typewriter_progress >= 1.0f32
        end

        # Check if dialog is animating
        def animating? : Bool
          @opacity < 1.0f32 || @typewriter_progress < 1.0f32
        end

        private def calculate_width : Float32
          text_width = @text_renderer.measure_text(@current_text).x + @padding * 2
          text_width.clamp(@min_width, @max_width)
        end

        private def calculate_position(x : Float32, y : Float32,
                                       width : Float32, height : Float32,
                                       anchor : DialogAnchor,
                                       target_pos : RL::Vector2?) : RL::Vector2
          case anchor
          when .top_left?
            RL::Vector2.new(x: x, y: y)
          when .top_center?
            RL::Vector2.new(x: x - width/2, y: y)
          when .top_right?
            RL::Vector2.new(x: x - width, y: y)
          when .middle_left?
            RL::Vector2.new(x: x, y: y - height/2)
          when .middle_center?
            RL::Vector2.new(x: x - width/2, y: y - height/2)
          when .middle_right?
            RL::Vector2.new(x: x - width, y: y - height/2)
          when .bottom_left?
            RL::Vector2.new(x: x, y: y - height)
          when .bottom_center?
            RL::Vector2.new(x: x - width/2, y: y - height)
          when .bottom_right?
            RL::Vector2.new(x: x - width, y: y - height)
          when .above_target?
            if target = target_pos
              RL::Vector2.new(x: target.x - width/2, y: y - height - @tail_height)
            else
              RL::Vector2.new(x: x - width/2, y: y - height)
            end
          when .below_target?
            if target = target_pos
              RL::Vector2.new(x: target.x - width/2, y: y + @tail_height)
            else
              RL::Vector2.new(x: x - width/2, y: y)
            end
          else
            RL::Vector2.new(x: x, y: y)
          end
        end

        private def draw_tail(box_x : Float32, box_y : Float32,
                              target : RL::Vector2, alpha : UInt8)
          # Draw a simple triangle tail pointing to target
          tail_color = RL::Color.new(r: 240, g: 240, b: 240, a: alpha)

          # Calculate tail points
          p1 = RL::Vector2.new(x: box_x - @tail_width/2, y: box_y)
          p2 = RL::Vector2.new(x: box_x + @tail_width/2, y: box_y)
          p3 = target

          # Draw filled triangle
          RL.draw_triangle(p1, p2, p3, tail_color)

          # Draw outline
          outline_color = RL::Color.new(r: 0, g: 0, b: 0, a: alpha)
          RL.draw_line_v(p1, p3, outline_color)
          RL.draw_line_v(p2, p3, outline_color)
        end
      end

      # Dialog manager for multiple dialogs
      class DialogManager
        @dialogs : Hash(String, DialogRenderer) = {} of String => DialogRenderer
        @active_dialog : String?

        def initialize
        end

        # Add a dialog renderer
        def add_dialog(name : String, dialog : DialogRenderer)
          @dialogs[name] = dialog
        end

        # Create and add a dialog with nine-patch
        def create_dialog(name : String, nine_patch_path : String) : DialogRenderer
          nine_patch = NinePatch.new(nine_patch_path)
          dialog = DialogRenderer.new(nine_patch)
          add_dialog(name, dialog)
          dialog
        end

        # Show dialog
        def show_dialog(name : String, text : String, instant : Bool = false)
          if dialog = @dialogs[name]?
            @active_dialog = name
            dialog.show(text, instant)
          end
        end

        # Hide active dialog
        def hide_dialog(instant : Bool = false)
          if name = @active_dialog
            if dialog = @dialogs[name]?
              dialog.hide(instant)
            end
          end
        end

        # Update all dialogs
        def update(dt : Float32)
          @dialogs.each_value(&.update(dt))
        end

        # Draw active dialog
        def draw_active(x : Float32, y : Float32,
                        anchor : DialogAnchor = DialogAnchor::BottomCenter,
                        target : RL::Vector2? = nil)
          if name = @active_dialog
            if dialog = @dialogs[name]?
              dialog.draw(x, y, nil, anchor, target)
            end
          end
        end

        # Get active dialog
        def active_dialog : DialogRenderer?
          if name = @active_dialog
            @dialogs[name]?
          end
        end
      end
    end
  end
end
