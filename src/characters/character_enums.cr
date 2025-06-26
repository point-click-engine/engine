module PointClickEngine
  module Characters
    # Character states for adventure game characters
    enum CharacterState
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
      Interacting
      Looking
      Thinking

      def to_s(io)
        io << case self
        when .idle?        then "idle"
        when .walking?     then "walking"
        when .talking?     then "talking"
        when .picking_up?  then "picking_up"
        when .using?       then "using"
        when .pushing?     then "pushing"
        when .pulling?     then "pulling"
        when .climbing?    then "climbing"
        when .sitting?     then "sitting"
        when .standing?    then "standing"
        when .dying?       then "dying"
        when .interacting? then "interacting"
        when .looking?     then "looking"
        when .thinking?    then "thinking"
        else
          raise "Unknown state: #{self}"
        end
      end
    end

    # Basic directional movement for 2D adventure games
    enum Direction
      Left
      Right
      Up
      Down

      def to_s(io)
        io << case self
        when .left?  then "left"
        when .right? then "right"
        when .up?    then "up"
        when .down?  then "down"
        else
          raise "Unknown direction: #{self}"
        end
      end

      # Get opposite direction
      def opposite : Direction
        case self
        when .left?  then Direction::Right
        when .right? then Direction::Left
        when .up?    then Direction::Down
        when .down?  then Direction::Up
        else
          raise "Unknown direction: #{self}"
        end
      end

      # Convert from velocity vector to direction
      def self.from_velocity(velocity : RL::Vector2) : Direction
        if velocity.x.abs > velocity.y.abs
          velocity.x > 0 ? Direction::Right : Direction::Left
        else
          velocity.y > 0 ? Direction::Down : Direction::Up
        end
      end
    end

    # Character emotional states and moods
    enum CharacterMood
      Neutral
      Happy
      Sad
      Angry
      Friendly
      Hostile
      Wise
      Curious
      Confused
      Grateful
      Suspicious

      def to_s(io)
        io << case self
        when .neutral?    then "neutral"
        when .happy?      then "happy"
        when .sad?        then "sad"
        when .angry?      then "angry"
        when .friendly?   then "friendly"
        when .hostile?    then "hostile"
        when .wise?       then "wise"
        when .curious?    then "curious"
        when .confused?   then "confused"
        when .grateful?   then "grateful"
        when .suspicious? then "suspicious"
        else
          raise "Unknown mood: #{self}"
        end
      end

      # Get mood intensity (for animation/behavior systems)
      def intensity : Float32
        case self
        when .neutral?    then 0.0f32
        when .happy?      then 0.8f32
        when .sad?        then 0.6f32
        when .angry?      then 1.0f32
        when .friendly?   then 0.7f32
        when .hostile?    then 0.9f32
        when .wise?       then 0.4f32
        when .curious?    then 0.6f32
        when .confused?   then 0.5f32
        when .grateful?   then 0.7f32
        when .suspicious? then 0.8f32
        else
          raise "Unknown mood: #{self}"
        end
      end

      # Check if mood is positive/negative for behavior systems
      def positive? : Bool
        case self
        when .happy?, .friendly?, .wise?, .curious?, .grateful?
          true
        else
          false
        end
      end

      def negative? : Bool
        case self
        when .sad?, .angry?, .hostile?, .suspicious?
          true
        else
          false
        end
      end
    end
  end
end