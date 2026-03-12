# Base class for all game events
# Provides common functionality for event handling and propagation

module PointClickEngine
  module Core
    module Events
      # Base class for all game events
      #
      # Events are immutable data objects that carry information about
      # something that happened in the game. They can be consumed to
      # prevent further propagation.
      #
      # Example:
      # ```
      # class PlayerMovedEvent < GameEvent
      #   define_event_type "player:moved"
      #   getter position : RL::Vector2
      #   getter old_position : RL::Vector2
      #
      #   def initialize(@position, @old_position)
      #     super()
      #   end
      # end
      # ```
      abstract class GameEvent
        # Unique event type identifier
        class_getter event_type : String = "game_event"

        # Timestamp when the event was created
        getter timestamp : Time

        # Whether this event has been consumed (stops propagation)
        getter? consumed : Bool = false

        # Optional source identifier (who/what raised this event)
        property source : String?

        def initialize
          @timestamp = Time.utc
          @consumed = false
        end

        # Mark event as consumed to stop propagation
        def consume!
          @consumed = true
        end

        # Macro to define event type for subclasses
        macro define_event_type(type_name)
          class_getter event_type : String = {{type_name}}
        end

        # Get the event type for this instance
        def type : String
          self.class.event_type
        end
      end

      # Priority levels for event handlers
      enum HandlerPriority
        Lowest  = 0
        Low     = 25
        Normal  = 50
        High    = 75
        Highest = 100
        System  = 200 # Reserved for engine internals
      end

      # Wrapper for event handlers with priority
      struct EventHandler(T)
        getter handler : Proc(T, Nil)
        getter priority : Int32
        getter id : UInt64

        @@next_id : UInt64 = 0_u64

        def initialize(@handler : Proc(T, Nil), @priority : Int32 = HandlerPriority::Normal.value)
          @id = @@next_id
          @@next_id += 1
        end

        def call(event : T)
          @handler.call(event)
        end

        # Sort by priority (higher first), then by id (older first)
        def <=>(other : EventHandler(T)) : Int32
          cmp = other.priority <=> @priority
          cmp == 0 ? @id <=> other.id : cmp
        end
      end
    end
  end
end
