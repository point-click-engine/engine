require "yaml"
require "../core/game_constants"
require "../graphics/animated_sprite"

module PointClickEngine
  module Characters
    # Contains animation configuration data for character sprites
    struct AnimationData
      include YAML::Serializable

      # First frame index in the animation sequence
      property start_frame : Int32

      # Number of frames in the animation
      property frame_count : Int32

      # Time between frames in seconds (lower = faster)
      property frame_speed : Float32

      # Whether the animation should loop continuously
      property loop : Bool

      def initialize(@start_frame : Int32 = 0, @frame_count : Int32 = 1,
                     @frame_speed : Float32 = 0.1, @loop : Bool = true)
      end
    end

    # Manages animation playback and state for character sprites
    #
    # The AnimationController handles all aspects of character animation including:
    # - Animation definition and storage
    # - Playback control and state management
    # - Mood-based animation selection
    # - Frame timing and looping
    class AnimationController
      # Name of the currently playing animation
      property current_animation : String = "idle"

      # Collection of defined animations by name
      property animations : Hash(String, AnimationData) = {} of String => AnimationData

      # Reference to the sprite being animated
      property sprite : Graphics::AnimatedSprite?

      # Current character mood for mood-based animations
      property mood : CharacterMood = CharacterMood::Neutral

      # Current character state for state-based animation selection
      property state : CharacterState = CharacterState::Idle

      # Current facing direction for directional animations
      property direction : Direction = Direction::Right

      def initialize(@sprite : Graphics::AnimatedSprite? = nil)
        @animations = {} of String => AnimationData
      end

      # Defines a named animation for the character
      def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                        frame_speed : Float32 = Core::GameConstants::DEFAULT_ANIMATION_SPEED,
                        loop : Bool = true)
        @animations[name] = AnimationData.new(start_frame, frame_count, frame_speed, loop)
      end

      # Plays a named animation
      def play_animation(name : String, force_restart : Bool = true)
        return unless @animations.has_key?(name)
        return if !force_restart && @current_animation == name && @sprite.try(&.playing)

        @current_animation = name
        anim_data = @animations[name]

        if sprite = @sprite
          sprite.current_frame = anim_data.start_frame
          sprite.frame_count = anim_data.frame_count
          sprite.frame_speed = anim_data.frame_speed
          sprite.loop = anim_data.loop
          sprite.play
        end
      end

      # Updates animation playback based on delta time
      def update(dt : Float32)
        return unless sprite = @sprite
        return unless @animations.has_key?(@current_animation)

        anim_data = @animations[@current_animation]

        if sprite.playing
          sprite.frame_timer += dt
          if sprite.frame_timer >= sprite.frame_speed
            sprite.frame_timer = 0.0
            sprite.current_frame += 1

            if sprite.current_frame >= anim_data.start_frame + anim_data.frame_count
              if anim_data.loop
                sprite.current_frame = anim_data.start_frame
              else
                sprite.current_frame = anim_data.start_frame + anim_data.frame_count - 1
                sprite.stop
                # Notify about animation completion
                on_animation_complete.try &.call(@current_animation)
              end
            end
          end
        end
      end

      # Updates character animation based on current mood
      def update_mood_animation
        mood_anim = case @mood
                    when CharacterMood::Happy    then "happy"
                    when CharacterMood::Sad      then "sad"
                    when CharacterMood::Angry    then "angry"
                    when CharacterMood::Wise     then "wise"
                    when CharacterMood::Curious  then "curious"
                    when CharacterMood::Confused then "confused"
                    when CharacterMood::Friendly then "friendly"
                    when CharacterMood::Hostile  then "hostile"
                    else                              "idle"
                    end

        # Only play mood animation if it exists and character is idle
        if @animations.has_key?(mood_anim) && @state == CharacterState::Idle
          play_animation(mood_anim, force_restart: false)
        end
      end

      # Updates animation based on movement direction
      def update_directional_animation
        return unless @state == CharacterState::Walking

        direction_anim = case @direction
                         when Direction::Left  then "walk_left"
                         when Direction::Right then "walk_right"
                         when Direction::Up    then "walk_up"
                         when Direction::Down  then "walk_down"
                         else                       "walk_right"
                         end

        if @animations.has_key?(direction_anim)
          play_animation(direction_anim, force_restart: false)
        elsif @animations.has_key?("walk")
          play_animation("walk", force_restart: false)
        end
      end

      # Updates animation based on character state
      def update_state_animation
        state_anim = case @state
                     when CharacterState::Idle        then "idle"
                     when CharacterState::Walking     then update_directional_animation; return
                     when CharacterState::Talking     then "talk"
                     when CharacterState::Interacting then "interact"
                     when CharacterState::Thinking    then "think"
                     end

        if @animations.has_key?(state_anim)
          play_animation(state_anim, force_restart: false)
        elsif state_anim != "idle" && @animations.has_key?("idle")
          play_animation("idle", force_restart: false)
        end
      end

      # Sets character mood and updates animations
      def set_mood(new_mood : CharacterMood)
        @mood = new_mood
        update_mood_animation
      end

      # Sets character state and updates animations
      def set_state(new_state : CharacterState)
        @state = new_state
        update_state_animation
      end

      # Sets character direction and updates animations
      def set_direction(new_direction : Direction)
        @direction = new_direction
        update_directional_animation if @state == CharacterState::Walking
      end

      # Callback for when animations complete
      property on_animation_complete : Proc(String, Nil)?

      # Checks if an animation exists
      def has_animation?(name : String) : Bool
        @animations.has_key?(name)
      end

      # Gets animation data for a specific animation
      def get_animation(name : String) : AnimationData?
        @animations[name]?
      end

      # Checks if any animation is currently playing
      def playing? : Bool
        @sprite.try(&.playing) || false
      end

      # Stops current animation
      def stop
        @sprite.try(&.stop)
      end

      # Pauses current animation
      def pause
        @sprite.try(&.pause)
      end

      # Resumes paused animation
      def resume
        @sprite.try(&.resume)
      end

      # Gets list of all available animation names
      def animation_names : Array(String)
        @animations.keys
      end

      # Removes an animation
      def remove_animation(name : String)
        @animations.delete(name)
      end

      # Clears all animations
      def clear_animations
        @animations.clear
      end

      # Sets the sprite to animate
      def sprite=(sprite : Graphics::AnimatedSprite)
        @sprite = sprite
      end
    end
  end
end
