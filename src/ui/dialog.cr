# Dialog system for character conversations

require "raylib-cr"
require "yaml"

module PointClickEngine
  module UI
    # Dialog choice structure
    struct DialogChoice
      include YAML::Serializable
      
      property text : String
      @[YAML::Field(ignore: true)]
      property action : Proc(Nil)

      def initialize
        @text = ""
        @action = ->{}
      end

      def initialize(@text : String, @action : Proc(Nil))
      end
    end

    # Main dialog class for conversations
    class Dialog
      include YAML::Serializable
      include Core::Drawable

      property text : String
      property character_name : String?
      property choices : Array(DialogChoice) = [] of DialogChoice
      @[YAML::Field(ignore: true)]
      property on_complete : Proc(Nil)?
      property padding : Float32 = 20.0
      property font_size : Int32 = 20
      
      @[YAML::Field(converter: Utils::YAMLConverters::ColorConverter)]
      property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 220)
      
      @[YAML::Field(converter: Utils::YAMLConverters::ColorConverter)]
      property text_color : RL::Color = RL::WHITE
      
      property ready_to_process_input : Bool = false

      def initialize
        @text = ""
        @position = RL::Vector2.new
        @size = RL::Vector2.new(x: 300, y: 100)
        @visible = false
        @choices = [] of DialogChoice
      end

      def initialize(@text : String, @position : RL::Vector2, @size : RL::Vector2)
        @visible = false
        @choices = [] of DialogChoice
      end

      def add_choice(text : String, &action : -> Nil)
        @choices << DialogChoice.new(text, action)
      end

      def show
        @visible = true
        @ready_to_process_input = false
      end

      def hide
        @visible = false
        @on_complete.try &.call
      end

      def update(dt : Float32)
        return unless @visible
        unless @ready_to_process_input
          @ready_to_process_input = true
          return
        end

        if @choices.empty?
          if RL::MouseButton::Left.pressed? || RL::KeyboardKey::Space.pressed?
            hide
          end
        else
          mouse_pos = RL.get_mouse_position
          if RL::MouseButton::Left.pressed?
            @choices.each_with_index do |choice, index|
              choice_rect = get_choice_rect(index)
              if RL.check_collision_point_rec?(mouse_pos, choice_rect)
                choice.action.call
                hide
                break
              end
            end
          end
        end
      end

      def draw
        return unless @visible
        bg_rect = RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y)
        RL.draw_rectangle_rec(bg_rect, @background_color)
        RL.draw_rectangle_lines_ex(bg_rect, 2, RL::WHITE)

        y_offset = @padding
        if char_name = @character_name
          RL.draw_text(char_name, @position.x.to_i + @padding.to_i,
            @position.y.to_i + y_offset.to_i, @font_size + 4, RL::YELLOW)
          y_offset += @font_size + 10
        end

        RL.draw_text(@text, @position.x.to_i + @padding.to_i,
          @position.y.to_i + y_offset.to_i, @font_size, @text_color)

        if !@choices.empty?
          base_choice_y = @position.y + @size.y - (@choices.size * 30) - @padding
          @choices.each_with_index do |choice, index|
            choice_rect = get_choice_rect(index, base_choice_y)
            mouse_pos = RL.get_mouse_position
            color = RL.check_collision_point_rec?(mouse_pos, choice_rect) ? RL::YELLOW : RL::WHITE
            RL.draw_text("> #{choice.text}", choice_rect.x.to_i, choice_rect.y.to_i, @font_size, color)
          end
        end
      end

      private def get_choice_rect(index : Int32, base_y_offset : Float32? = nil) : RL::Rectangle
        y = base_y_offset.nil? ? (@position.y + @size.y - ((@choices.size - index) * 30) - @padding) : (base_y_offset + index * 30)
        RL::Rectangle.new(x: @position.x + @padding, y: y, width: @size.x - @padding * 2, height: 25)
      end
    end
  end
end