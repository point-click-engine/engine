# Base Character class and related types

require "raylib-cr"
require "yaml"
require "../utils/yaml_converters"

module PointClickEngine
  module Characters
    # Character states
    enum CharacterState
      Idle
      Walking
      Talking
      Interacting
      Thinking
    end

    # Character directions
    enum Direction
      Left
      Right
      Up
      Down
    end

    # Marker module for objects that can be talked to
    module Talkable
    end

    # Animation data structure
    struct AnimationData
      include YAML::Serializable
      property start_frame : Int32
      property frame_count : Int32
      property frame_speed : Float32
      property loop : Bool

      def initialize(@start_frame : Int32 = 0, @frame_count : Int32 = 1,
                     @frame_speed : Float32 = 0.1, @loop : Bool = true)
      end
    end

    # Base class for all characters
    abstract class Character < Core::GameObject
      property name : String
      property description : String
      property state : CharacterState = CharacterState::Idle
      property direction : Direction = Direction::Right
      property walking_speed : Float32 = 100.0

      @[YAML::Field(converter: PointClickEngine::Utils::YAMLConverters::Vector2Converter, nilable: true)]
      property target_position : RL::Vector2?

      property dialogue_system_data : Dialogue::CharacterDialogue?
      @[YAML::Field(ignore: true)]
      delegate dialogue_system, to: @dialogue_system_data

      property sprite_data : Graphics::AnimatedSprite?
      @[YAML::Field(ignore: true)]
      delegate sprite, to: @sprite_data

      property current_animation : String = "idle"
      property animations : Hash(String, AnimationData) = {} of String => AnimationData

      property conversation_partner_name : String?
      @[YAML::Field(ignore: true)]
      property conversation_partner : Character?

      def initialize
        super(RL::Vector2.new, RL::Vector2.new)
        @name = ""
        @description = ""
        @animations = {} of String => AnimationData
        @dialogue_system_data = Dialogue::CharacterDialogue.new(self)
      end

      def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
        super(position, size)
        @description = "A character named #{@name}"
        @dialogue_system_data = Dialogue::CharacterDialogue.new(self)
        @animations = {} of String => AnimationData
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        @sprite_data.try &.after_yaml_deserialize(ctx)
        @dialogue_system_data.try &.character = self
        play_animation(@current_animation, force_restart: false)
      end

      def load_spritesheet(path : String, frame_width : Int32, frame_height : Int32)
        @sprite_data = Graphics::AnimatedSprite.new(@position, frame_width, frame_height, 1)
        @sprite_data.not_nil!.load_texture(path)
        @sprite_data.not_nil!.scale = calculate_scale(frame_width, frame_height)
        @size = RL::Vector2.new(x: frame_width * @sprite_data.not_nil!.scale, y: frame_height * @sprite_data.not_nil!.scale)
        @sprite_data.not_nil!.size = @size
      end

      def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                        frame_speed : Float32 = 0.1, loop : Bool = true)
        @animations[name] = AnimationData.new(start_frame, frame_count, frame_speed, loop)
      end

      def play_animation(name : String, force_restart : Bool = true)
        return unless @animations.has_key?(name)
        return if !force_restart && @current_animation == name && @sprite_data.try(&.playing)

        @current_animation = name
        anim_data = @animations[name]

        if sprite = @sprite_data
          sprite.current_frame = anim_data.start_frame
          sprite.frame_count = anim_data.frame_count
          sprite.frame_speed = anim_data.frame_speed
          sprite.loop = anim_data.loop
          sprite.play
        end
      end

      def walk_to(target : RL::Vector2)
        @target_position = target
        @state = CharacterState::Walking
        if target.x < @position.x
          @direction = Direction::Left
          play_animation("walk_left") if @animations.has_key?("walk_left")
        else
          @direction = Direction::Right
          play_animation("walk_right") if @animations.has_key?("walk_right")
        end
      end

      def stop_walking
        @target_position = nil
        @state = CharacterState::Idle
        base_idle_anim = @direction == Direction::Left ? "idle_left" : "idle_right"
        play_animation(base_idle_anim) if @animations.has_key?(base_idle_anim)
        play_animation("idle") if !@animations.has_key?(base_idle_anim) && @animations.has_key?("idle")
      end

      def say(text : String, &block : -> Nil)
        @state = CharacterState::Talking
        play_animation("talk") if @animations.has_key?("talk")

        if dialogue = @dialogue_system_data
          dialogue.say(text) do
            @state = CharacterState::Idle
            stop_walking
            block.call
          end
        else
          block.call
        end
      end

      def ask(question : String, choices : Array(Tuple(String, Proc(Nil))))
        @state = CharacterState::Talking
        play_animation("talk") if @animations.has_key?("talk")

        if dialogue = @dialogue_system_data
          dialogue.ask(question, choices) do
            @state = CharacterState::Idle
            stop_walking
          end
        end
      end

      def update(dt : Float32)
        return unless @active
        update_movement(dt)
        update_animation(dt)
        @dialogue_system_data.try &.update(dt)
      end

      def draw
        return unless @visible
        @sprite_data.try &.draw
        @dialogue_system_data.try &.draw

        if Core::Engine.debug_mode
          RL.draw_text(@name, @position.x.to_i, (@position.y - 25).to_i, 16, RL::WHITE)
          if @target_position
            RL.draw_line_v(@position, @target_position.not_nil!, RL::GREEN)
            RL.draw_circle_v(@target_position.not_nil!, 5.0, RL::GREEN)
          end
        end
      end

      abstract def on_interact(interactor : Character)
      abstract def on_look
      abstract def on_talk

      private def update_movement(dt : Float32)
        return unless @state == CharacterState::Walking
        return unless target = @target_position

        direction_vec = RL::Vector2.new(x: target.x - @position.x, y: target.y - @position.y)
        distance = Math.sqrt(direction_vec.x ** 2 + direction_vec.y ** 2).to_f

        if distance < 5.0
          @position = target
          stop_walking
          return
        end

        normalized_dir_x = direction_vec.x / distance
        normalized_dir_y = direction_vec.y / distance

        @position.x += normalized_dir_x * @walking_speed * dt
        @position.y += normalized_dir_y * @walking_speed * dt

        @sprite_data.try &.position = @position
      end

      private def update_animation(dt : Float32)
        if @sprite_data && @animations.has_key?(@current_animation)
          anim_data = @animations[@current_animation]
          current_sprite = @sprite_data.not_nil!

          if current_sprite.playing
            current_sprite.frame_timer += dt
            if current_sprite.frame_timer >= current_sprite.frame_speed
              current_sprite.frame_timer = 0.0

              current_sprite.current_frame += 1

              if current_sprite.current_frame >= anim_data.start_frame + anim_data.frame_count
                if anim_data.loop
                  current_sprite.current_frame = anim_data.start_frame
                else
                  current_sprite.current_frame = anim_data.start_frame + anim_data.frame_count - 1
                  current_sprite.stop
                  if @state != CharacterState::Talking
                    stop_walking
                  end
                end
              end
            end
          end
        end
      end

      private def calculate_scale(frame_width : Int32, frame_height : Int32) : Float32
        return 1.0_f32 if frame_width == 0 || frame_height == 0
        scale_x = @size.x / frame_width
        scale_y = @size.y / frame_height
        Math.min(scale_x, scale_y).to_f32
      end
    end
  end
end
