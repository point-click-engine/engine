require "yaml"
require "../core/game_constants"
require "../graphics/animated_sprite"

module PointClickEngine
  module Characters
    # 8-directional movement for adventure games
    enum Direction8
      North
      NorthEast
      East
      SouthEast
      South
      SouthWest
      West
      NorthWest

      # Convert from velocity vector to direction
      def self.from_velocity(velocity : RL::Vector2) : Direction8
        return Direction8::South if velocity.x == 0 && velocity.y == 0

        angle = Math.atan2(velocity.y, velocity.x)
        # Normalize angle to 0-2π
        angle = angle + 2 * Math::PI if angle < 0

        # Convert to 8 directions (each direction covers 45 degrees)
        direction_index = ((angle + Math::PI / 8) / (Math::PI / 4)).to_i % 8

        case direction_index
        when 0 then Direction8::East
        when 1 then Direction8::SouthEast
        when 2 then Direction8::South
        when 3 then Direction8::SouthWest
        when 4 then Direction8::West
        when 5 then Direction8::NorthWest
        when 6 then Direction8::North
        when 7 then Direction8::NorthEast
        else        Direction8::South
        end
      end

      # Get opposite direction for turn animations
      def opposite : Direction8
        case self
        when .north?      then Direction8::South
        when .north_east? then Direction8::SouthWest
        when .east?       then Direction8::West
        when .south_east? then Direction8::NorthWest
        when .south?      then Direction8::North
        when .south_west? then Direction8::NorthEast
        when .west?       then Direction8::East
        when .north_west? then Direction8::SouthEast
        else                   Direction8::South # Default fallback
        end
      end

      # Calculate angle difference for turn animations
      def angle_difference(other : Direction8) : Float32
        angles = {
          Direction8::North     => 0.0f32,
          Direction8::NorthEast => 45.0f32,
          Direction8::East      => 90.0f32,
          Direction8::SouthEast => 135.0f32,
          Direction8::South     => 180.0f32,
          Direction8::SouthWest => 225.0f32,
          Direction8::West      => 270.0f32,
          Direction8::NorthWest => 315.0f32,
        }

        diff = (angles[other] - angles[self]).abs
        Math.min(diff, 360.0f32 - diff)
      end
    end

    # Animation states for adventure games
    enum AnimationState
      Idle
      Walking
      Talking
      PickingUp
      Using
      Pushing
      Pulling
      Climbing
      Sitting
      Standing
      Dying
      Custom

      # Get the animation name for a specific direction
      def with_direction(direction : Direction8) : String
        case self
        when .walking?
          "walk_#{direction.to_s.downcase}"
        when .talking?
          "talk_#{direction.to_s.downcase}"
        else
          self.to_s.downcase
        end
      end
    end

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

      # Priority for animation interruption (higher = harder to interrupt)
      property priority : Int32 = 0

      # Whether this animation can be interrupted by lower priority animations
      property interruptible : Bool = true

      # Whether to automatically return to idle when animation completes
      property auto_return_to_idle : Bool = true

      # Optional sound effect to play when animation starts
      property sound_effect : String?

      def initialize(@start_frame : Int32 = 0, @frame_count : Int32 = 1,
                     @frame_speed : Float32 = 0.1, @loop : Bool = true,
                     @priority : Int32 = 0, @interruptible : Bool = true,
                     @auto_return_to_idle : Bool = true, @sound_effect : String? = nil)
      end
    end

    # Manages animation playback and state for character sprites
    #
    # The AnimationController handles all aspects of character animation including:
    # - Animation definition and storage
    # - Playback control and state management
    # - Mood-based animation selection
    # - Frame timing and looping
    # - 8-directional animations
    # - Idle variations
    # - Animation priorities and interruption
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

      # Current facing direction for directional animations (2D)
      property direction : Direction = Direction::Right

      # Current 8-directional facing for enhanced animations
      property current_direction : Direction8 = Direction8::South
      property last_direction : Direction8 = Direction8::South

      # Idle animation system
      property idle_timer : Float32 = 0.0
      property idle_variations : Array(String) = [] of String

      # Turn animation threshold in degrees
      property turn_threshold : Float32 = 45.0f32

      # Constants
      IDLE_TRIGGER_TIME    = 8.0f32
      TURN_ANIMATION_SPEED = 2.0f32

      def initialize(@sprite : Graphics::AnimatedSprite? = nil)
        @animations = {} of String => AnimationData
      end

      # Sets up default animations
      private def setup_default_animations
        # Basic idle animation
        add_animation("idle", 0, 1, 0.1f32)

        # Basic walk animation for each direction
        add_animation("walk_south", 0, 4, 0.1f32)
        add_animation("walk_north", 4, 4, 0.1f32)
        add_animation("walk_east", 8, 4, 0.1f32)
        add_animation("walk_west", 12, 4, 0.1f32)

        # Legacy 2D direction support
        add_animation("walk_down", 0, 4, 0.1f32)
        add_animation("walk_up", 4, 4, 0.1f32)
        add_animation("walk_right", 8, 4, 0.1f32)
        add_animation("walk_left", 12, 4, 0.1f32)
      end

      # Defines a named animation for the character
      def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                        frame_speed : Float32 = Core::GameConstants::DEFAULT_ANIMATION_SPEED,
                        loop : Bool = true, priority : Int32 = 0, interruptible : Bool = true,
                        auto_return_to_idle : Bool = true, sound_effect : String? = nil)
        @animations[name] = AnimationData.new(
          start_frame, frame_count, frame_speed, loop,
          priority, interruptible, auto_return_to_idle, sound_effect
        )
      end

      # Add directional animations (8 directions for one animation type)
      def add_directional_animation(base_name : String, start_frame : Int32,
                                    frames_per_direction : Int32, frame_speed : Float32 = 0.1)
        directions = [
          Direction8::North, Direction8::NorthEast, Direction8::East, Direction8::SouthEast,
          Direction8::South, Direction8::SouthWest, Direction8::West, Direction8::NorthWest,
        ]

        directions.each_with_index do |direction, i|
          animation_name = "#{base_name}_#{direction.to_s.downcase}"
          animation_start = start_frame + (i * frames_per_direction)
          add_animation(animation_name, animation_start, frames_per_direction, frame_speed)
        end
      end

      # Add idle variations
      def add_idle_variation(name : String, start_frame : Int32, frame_count : Int32,
                             frame_speed : Float32 = 0.2)
        full_name = "idle_#{name}"
        add_animation(full_name, start_frame, frame_count, frame_speed, loop: false)
        @idle_variations << full_name
      end

      # Plays a named animation with priority checking
      def play_animation(name : String, force_restart : Bool = true) : Bool
        # Check if animation exists
        return false unless @animations.has_key?(name)

        # Skip if already playing and not forcing restart
        return true if !force_restart && @current_animation == name && @sprite.try(&.playing)

        current_anim = @animations[@current_animation]?
        new_anim = @animations[name]

        # Check if current animation can be interrupted
        if current_anim && !force_restart
          return false if !current_anim.interruptible && new_anim.priority <= current_anim.priority
        end

        @current_animation = name
        @idle_timer = 0.0
        anim_data = @animations[name]

        if sprite = @sprite
          sprite.current_frame = anim_data.start_frame
          sprite.frame_count = anim_data.frame_count
          sprite.frame_speed = anim_data.frame_speed
          sprite.loop = anim_data.loop
          sprite.play

          # TODO: Play sound effect if defined
          # if sound = anim_data.sound_effect
          #   Audio::SoundManager.play(sound)
          # end
        end

        true
      end

      # Updates animation playback based on delta time
      def update(dt : Float32)
        return unless sprite = @sprite

        # Update idle timer
        update_idle(dt)

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

                # Check if should return to idle
                if anim_data.auto_return_to_idle && @current_animation != "idle"
                  play_animation("idle", force_restart: true)
                end

                # Notify about animation completion
                on_animation_complete.try &.call(@current_animation)
              end
            end
          end
        end
      end

      # Update with sprite reference (for compatibility)
      def update(dt : Float32, sprite : Graphics::AnimatedSprite?)
        @sprite = sprite if sprite
        update(dt)
      end

      # Update idle system
      def update_idle(dt : Float32)
        return unless @current_animation == "idle"

        @idle_timer += dt

        if @idle_timer > IDLE_TRIGGER_TIME && !@idle_variations.empty?
          # Play random idle variation
          variation = @idle_variations.sample
          if play_animation(variation)
            @idle_timer = 0.0
          end
        end
      end

      # Update direction-based animation (8-directional)
      def update_directional_animation(state : AnimationState, direction : Direction8, force : Bool = false)
        # Calculate if we need a turn animation
        angle_diff = @last_direction.angle_difference(direction)

        if angle_diff > @turn_threshold && !force
          # Play turn animation first
          play_turn_animation(@last_direction, direction)
        else
          # Direct animation
          animation_name = state.with_direction(direction)
          play_animation(animation_name, force_restart: force)
          @current_direction = direction
          @last_direction = direction
        end
      end

      # Play turn animation between directions
      private def play_turn_animation(from : Direction8, to : Direction8)
        # Simple turn - just update direction
        # Could be enhanced with actual turn animations
        @current_direction = to
        @last_direction = to
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

        if state_anim && @animations.has_key?(state_anim)
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

      # Gets current animation data
      def current_animation_data : AnimationData?
        @animations[@current_animation]?
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
        @sprite.try(&.stop)
      end

      # Resumes paused animation
      def resume
        @sprite.try(&.play)
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
