# Animated Sprite system for characters and objects

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Graphics
    # Sprite animation for characters and objects
    class AnimatedSprite < Core::GameObject
      property texture_path : String?
      @[YAML::Field(ignore: true)]
      property texture : RL::Texture2D?

      property frame_width : Int32
      property frame_height : Int32
      property current_frame : Int32 = 0
      property frame_count : Int32
      property frame_speed : Float32 = 0.1
      property frame_timer : Float32 = 0.0
      property loop : Bool = true
      property playing : Bool = true
      property scale : Float32 = 1.0

      def initialize
        super(RL::Vector2.new, RL::Vector2.new)
        @frame_width = 0
        @frame_height = 0
        @frame_count = 0
      end

      def initialize(position : RL::Vector2, @frame_width : Int32, @frame_height : Int32, @frame_count : Int32)
        scaled_width = @frame_width * @scale
        scaled_height = @frame_height * @scale
        super(position, RL::Vector2.new(x: scaled_width, y: scaled_height))
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        if path = @texture_path
          if RL.window_ready?
            load_texture(path)
          end
        end
        @size = RL::Vector2.new(x: @frame_width * @scale, y: @frame_height * @scale)
      end

      def load_texture(path : String)
        @texture_path = path
        @texture = RL.load_texture(path)
      end

      def play
        @playing = true
        @frame_timer = 0.0
      end

      def stop
        @playing = false
      end

      def update(dt : Float32)
        return unless @playing && @active
        @frame_timer += dt
        if @frame_timer >= @frame_speed
          @frame_timer = 0.0
          @current_frame += 1
          if @current_frame >= @frame_count
            if @loop
              @current_frame = 0
            else
              @current_frame = @frame_count - 1
              @playing = false
            end
          end
        end
      end

      def draw
        return unless @visible
        return unless tex = @texture
        source_rect = RL::Rectangle.new(
          x: (@current_frame * @frame_width).to_f,
          y: 0.0,
          width: @frame_width.to_f,
          height: @frame_height.to_f
        )
        dest_rect = RL::Rectangle.new(
          x: @position.x,
          y: @position.y,
          width: @frame_width * @scale,
          height: @frame_height * @scale
        )
        RL.draw_texture_pro(tex, source_rect, dest_rect, RL::Vector2.new(x: 0, y: 0), 0.0, RL::WHITE)
      end
    end
  end
end