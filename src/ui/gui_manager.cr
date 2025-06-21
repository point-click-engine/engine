require "raylib-cr"

module PointClickEngine
  module UI
    class GUIManager
      class Label
        property text : String
        property position : Raylib::Vector2
        property font_size : Int32
        property color : Raylib::Color
        property visible : Bool = true

        def initialize(@text : String, @position : Raylib::Vector2, @font_size : Int32, @color : Raylib::Color)
        end

        def draw
          return unless @visible
          Raylib.draw_text(@text, @position.x.to_i, @position.y.to_i, @font_size, @color)
        end
      end

      class Button
        property text : String
        property position : Raylib::Vector2
        property size : Raylib::Vector2
        property callback : Proc(Nil)
        property visible : Bool = true
        property hovered : Bool = false
        property pressed : Bool = false

        def initialize(@text : String, @position : Raylib::Vector2, @size : Raylib::Vector2, &@callback : -> Nil)
        end

        def bounds : Raylib::Rectangle
          Raylib::Rectangle.new(
            x: @position.x,
            y: @position.y,
            width: @size.x,
            height: @size.y
          )
        end

        def update(dt : Float32)
          return unless @visible

          mouse_pos = Raylib.get_mouse_position
          @hovered = Raylib.check_collision_point_rec?(mouse_pos, bounds)

          if @hovered && Raylib.mouse_button_pressed?(Raylib::MouseButton::Left.to_i)
            @pressed = true
            @callback.call
          elsif Raylib.mouse_button_released?(Raylib::MouseButton::Left.to_i)
            @pressed = false
          end
        end

        def draw
          return unless @visible

          # Button background
          bg_color = if @pressed
                       Raylib::Color.new(r: 60, g: 60, b: 100, a: 255)
                     elsif @hovered
                       Raylib::Color.new(r: 100, g: 100, b: 140, a: 255)
                     else
                       Raylib::Color.new(r: 80, g: 80, b: 120, a: 255)
                     end

          Raylib.draw_rectangle_rec(bounds, bg_color)

          # Button border
          border_color = Raylib::Color.new(r: 120, g: 120, b: 180, a: 255)
          Raylib.draw_rectangle_lines_ex(bounds, 2, border_color)

          # Button text
          text_width = Raylib.measure_text(@text, 20)
          text_x = @position.x + (@size.x - text_width) / 2
          text_y = @position.y + (@size.y - 20) / 2

          Raylib.draw_text(@text, text_x.to_i, text_y.to_i, 20, Raylib::WHITE)
        end
      end

      property labels : Hash(String, Label) = {} of String => Label
      property buttons : Hash(String, Button) = {} of String => Button
      property visible : Bool = true

      def initialize
      end

      def add_label(id : String, text : String, position : Raylib::Vector2, font_size : Int32 = 20, color : Raylib::Color = Raylib::WHITE)
        @labels[id] = Label.new(text, position, font_size, color)
      end

      def add_button(id : String, text : String, position : Raylib::Vector2, size : Raylib::Vector2, &callback : -> Nil)
        @buttons[id] = Button.new(text, position, size, &callback)
      end

      def remove_label(id : String)
        @labels.delete(id)
      end

      def remove_button(id : String)
        @buttons.delete(id)
      end

      def clear
        @labels.clear
        @buttons.clear
      end

      def update(dt : Float32)
        return unless @visible

        @buttons.each_value do |button|
          button.update(dt)
        end
      end

      def draw
        return unless @visible

        @labels.each_value do |label|
          label.draw
        end

        @buttons.each_value do |button|
          button.draw
        end
      end

      def show
        @visible = true
      end

      def hide
        @visible = false
      end
    end
  end
end
