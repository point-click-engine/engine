module PointClickEngine
  module Characters
    # Manages character state transitions and state-dependent behavior
    #
    # The CharacterStateManager centralizes all state-related logic including:
    # - State transition validation and execution
    # - State-dependent behavior coordination
    # - State change notifications and callbacks
    # - State consistency enforcement
    class CharacterStateManager
      # Current character state
      property state : CharacterState = CharacterState::Idle

      # Current facing direction
      property direction : Direction = Direction::Right

      # Current emotional mood
      property mood : CharacterMood = CharacterMood::Neutral

      # Callbacks for state changes
      property on_state_changed : Proc(CharacterState, CharacterState, Nil)?
      property on_direction_changed : Proc(Direction, Direction, Nil)?
      property on_mood_changed : Proc(CharacterMood, CharacterMood, Nil)?

      # State transition rules
      private property valid_transitions : Hash(CharacterState, Array(CharacterState))

      def initialize
        @valid_transitions = {} of CharacterState => Array(CharacterState)
        setup_transition_rules
      end

      # Sets up valid state transition rules
      private def setup_transition_rules
        @valid_transitions = {
          CharacterState::Idle => [
            CharacterState::Walking,
            CharacterState::Talking,
            CharacterState::Interacting,
            CharacterState::Thinking,
          ],
          CharacterState::Walking => [
            CharacterState::Idle,
            CharacterState::Talking,
            CharacterState::Interacting,
          ],
          CharacterState::Talking => [
            CharacterState::Idle,
            CharacterState::Thinking,
            CharacterState::Interacting,
          ],
          CharacterState::Interacting => [
            CharacterState::Idle,
            CharacterState::Talking,
          ],
          CharacterState::Thinking => [
            CharacterState::Idle,
            CharacterState::Talking,
          ],
        }
      end

      # Changes character state with validation
      def set_state(new_state : CharacterState, force : Bool = false) : Bool
        return true if new_state == @state

        # Validate transition unless forced
        unless force || can_transition_to?(new_state)
          return false
        end

        old_state = @state
        @state = new_state

        # Notify about state change
        @on_state_changed.try(&.call(old_state, new_state))

        true
      end

      # Changes character direction
      def set_direction(new_direction : Direction)
        return if new_direction == @direction

        old_direction = @direction
        @direction = new_direction

        # Notify about direction change
        @on_direction_changed.try(&.call(old_direction, new_direction))
      end

      # Changes character mood
      def set_mood(new_mood : CharacterMood)
        return if new_mood == @mood

        old_mood = @mood
        @mood = new_mood

        # Notify about mood change
        @on_mood_changed.try(&.call(old_mood, new_mood))
      end

      # Checks if character can transition to a specific state
      def can_transition_to?(target_state : CharacterState) : Bool
        valid_transitions = @valid_transitions[@state]?
        return false unless valid_transitions

        valid_transitions.includes?(target_state)
      end

      # Forces character to idle state
      def force_idle
        set_state(CharacterState::Idle, force: true)
      end

      # Forces character to walking state
      def force_walking
        set_state(CharacterState::Walking, force: true)
      end

      # Forces character to talking state
      def force_talking
        set_state(CharacterState::Talking, force: true)
      end

      # Gets all valid transitions from current state
      def valid_transitions_from_current : Array(CharacterState)
        @valid_transitions[@state]? || [] of CharacterState
      end

      # Checks if character is in a movement-capable state
      def can_move? : Bool
        @state == CharacterState::Idle || @state == CharacterState::Walking
      end

      # Checks if character can talk
      def can_talk? : Bool
        can_transition_to?(CharacterState::Talking) || @state == CharacterState::Talking
      end

      # Checks if character can interact
      def can_interact? : Bool
        can_transition_to?(CharacterState::Interacting) || @state == CharacterState::Interacting
      end

      # Checks if character is busy (cannot be interrupted)
      def busy? : Bool
        @state == CharacterState::Interacting || @state == CharacterState::Thinking
      end

      # Checks if character is available for interaction
      def available? : Bool
        @state == CharacterState::Idle
      end

      # Checks if character is currently moving
      def moving? : Bool
        @state == CharacterState::Walking
      end

      # Checks if character is currently talking
      def talking? : Bool
        @state == CharacterState::Talking
      end

      # Gets state description for debugging
      def state_description : String
        case @state
        when CharacterState::Idle
          "idle and available"
        when CharacterState::Walking
          "walking to destination"
        when CharacterState::Talking
          "engaged in conversation"
        when CharacterState::Interacting
          "interacting with object"
        when CharacterState::Thinking
          "thinking or paused"
        else
          "unknown state"
        end
      end

      # Gets direction description
      def direction_description : String
        case @direction
        when Direction::Left
          "facing left"
        when Direction::Right
          "facing right"
        when Direction::Up
          "facing away"
        when Direction::Down
          "facing toward camera"
        else
          "unknown direction"
        end
      end

      # Gets mood description
      def mood_description : String
        case @mood
        when CharacterMood::Friendly
          "friendly and approachable"
        when CharacterMood::Hostile
          "aggressive and unwelcoming"
        when CharacterMood::Happy
          "joyful and upbeat"
        when CharacterMood::Sad
          "melancholy and depressed"
        when CharacterMood::Angry
          "irritated and furious"
        when CharacterMood::Wise
          "contemplative and knowledgeable"
        when CharacterMood::Curious
          "inquisitive and interested"
        when CharacterMood::Confused
          "uncertain and puzzled"
        when CharacterMood::Neutral
          "emotionally neutral"
        else
          "unknown mood"
        end
      end

      # Attempts to return to idle state from any state
      def try_return_to_idle : Bool
        set_state(CharacterState::Idle)
      end

      # Creates a state snapshot for saving/loading
      def create_snapshot : Hash(String, String)
        {
          "state"     => @state.to_s,
          "direction" => @direction.to_s,
          "mood"      => @mood.to_s,
        }
      end

      # Restores state from snapshot
      def restore_from_snapshot(snapshot : Hash(String, String))
        if state_str = snapshot["state"]?
          if parsed_state = CharacterState.parse?(state_str)
            @state = parsed_state
          end
        end

        if direction_str = snapshot["direction"]?
          if parsed_direction = Direction.parse?(direction_str)
            @direction = parsed_direction
          end
        end

        if mood_str = snapshot["mood"]?
          if parsed_mood = CharacterMood.parse?(mood_str)
            @mood = parsed_mood
          end
        end
      end

      # Validates current state consistency
      def validate_state : Bool
        # Ensure state is valid
        return false unless CharacterState.values.includes?(@state)
        return false unless Direction.values.includes?(@direction)
        return false unless CharacterMood.values.includes?(@mood)

        true
      end

      # Adds custom transition rule
      def add_transition_rule(from : CharacterState, to : CharacterState)
        @valid_transitions[from] ||= [] of CharacterState
        @valid_transitions[from] << to unless @valid_transitions[from].includes?(to)
      end

      # Removes custom transition rule
      def remove_transition_rule(from : CharacterState, to : CharacterState)
        @valid_transitions[from]?.try(&.delete(to))
      end

      # Resets to default transition rules
      def reset_transition_rules
        setup_transition_rules
      end
    end
  end
end
