# Non-Player Character (NPC) implementation

require "raylib-cr"
require "yaml"

module PointClickEngine
  module Characters
    # NPC moods
    enum NPCMood
      Friendly
      Neutral
      Hostile
      Sad
      Happy
      Angry
    end

    # Non-Player Character class
    class NPC < Character
      property dialogues : Array(String) = [] of String
      property current_dialogue_index : Int32 = 0
      property can_repeat_dialogues : Bool = true
      property interaction_distance : Float32 = 50.0

      property ai_behavior_data : AI::NPCBehavior?
      @[YAML::Field(ignore: true)]
      delegate ai_behavior, to: @ai_behavior_data

      property mood : NPCMood = NPCMood::Neutral

      def initialize
        super()
        @dialogues = [] of String
      end

      def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
        @dialogues = [] of String
        setup_default_animations
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        setup_default_animations
        @ai_behavior_data.try &.after_yaml_deserialize(ctx, self)
        update_mood_animation
      end

      def add_dialogue(text : String)
        @dialogues << text
      end

      def set_dialogues(dialogues : Array(String))
        @dialogues = dialogues
      end

      def on_interact(interactor : Character)
        return if @state == CharacterState::Talking
        face_character(interactor)
        start_conversation(interactor)
      end

      def on_look
        say(@description) { }
      end

      def on_talk
        return if @state == CharacterState::Talking
        start_conversation(nil)
      end

      def set_ai_behavior(behavior : AI::NPCBehavior)
        @ai_behavior_data = behavior
      end

      def set_mood(mood : NPCMood)
        @mood = mood
        update_mood_animation
      end

      def update(dt : Float32)
        super(dt)
        @ai_behavior_data.try &.update(self, dt)
      end

      private def face_character(character : Character)
        if character.position.x < @position.x
          @direction = Direction::Left
          play_animation("idle_left", force_restart: false) if @animations.has_key?("idle_left")
        else
          @direction = Direction::Right
          play_animation("idle_right", force_restart: false) if @animations.has_key?("idle_right")
        end
      end

      private def start_conversation(interactor : Character?)
        return if @dialogues.empty?
        dialogue_text = @dialogues[@current_dialogue_index]
        @conversation_partner = interactor
        @conversation_partner_name = interactor.try(&.name)

        say(dialogue_text) { advance_dialogue }
      end

      private def advance_dialogue
        @current_dialogue_index += 1
        if @current_dialogue_index >= @dialogues.size
          @current_dialogue_index = @can_repeat_dialogues ? 0 : (@dialogues.size - 1)
        end
        @conversation_partner = nil
        @conversation_partner_name = nil
      end

      private def update_mood_animation
        mood_anim = case @mood
                    when NPCMood::Happy then "happy"
                    when NPCMood::Sad   then "sad"
                    when NPCMood::Angry then "angry"
                    else                     "idle"
                    end

        directional_idle = if mood_anim == "idle"
                             @direction == Direction::Left ? "idle_left" : "idle_right"
                           else
                             nil
                           end

        if directional_idle && @animations.has_key?(directional_idle)
          play_animation(directional_idle, force_restart: false)
        elsif @animations.has_key?(mood_anim)
          play_animation(mood_anim, force_restart: false)
        end
      end

      private def setup_default_animations
        unless @animations.has_key?("idle_right")
          add_animation("idle_right", 0, 1, 1.0, true)
        end
        unless @animations.has_key?("idle_left")
          add_animation("idle_left", 1, 1, 1.0, true)
        end
        unless @animations.has_key?("walk_right")
          add_animation("walk_right", 2, 2, 0.25, true)
        end
        unless @animations.has_key?("walk_left")
          add_animation("walk_left", 4, 2, 0.25, true)
        end
        unless @animations.has_key?("talk")
          add_animation("talk", 6, 2, 0.3, true)
        end
        unless @animations.has_key?("happy")
          add_animation("happy", 8, 2, 0.5, true)
        end
        play_animation("idle_right")
      end
    end
  end
end
