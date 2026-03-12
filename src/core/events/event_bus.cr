# Unified Event Bus for type-safe event handling
#
# This provides a centralized, type-safe event system that supports:
# - Priority-based handler execution
# - Event consumption (stop propagation)
# - Deferred event processing
# - Both sync and async-style event handling

require "./game_event"

module PointClickEngine
  module Core
    module Events
      # Central event bus for the entire engine
      #
      # Example usage:
      # ```
      # bus = EventBus.new
      #
      # # Subscribe to specific event type
      # bus.subscribe(PlayerMovedEvent) do |event|
      #   puts "Player moved to #{event.position}"
      # end
      #
      # # Publish an event
      # bus.publish(PlayerMovedEvent.new(position, old_position))
      #
      # # Process queued events
      # bus.process
      # ```
      class EventBus
        # Handler storage - maps event type string to array of handlers
        @handlers : Hash(String, Array(HandlerEntry)) = {} of String => Array(HandlerEntry)

        # Event queue for deferred processing
        @event_queue : Array(GameEvent) = [] of GameEvent

        # Prevent recursive event processing
        @processing : Bool = false

        # Statistics for debugging
        @events_published : UInt64 = 0_u64
        @events_processed : UInt64 = 0_u64

        # Internal handler entry that wraps the typed handler
        private struct HandlerEntry
          getter id : UInt64
          getter priority : Int32
          getter handler : Proc(GameEvent, Nil)
          getter owner : String?

          @@next_id : UInt64 = 0_u64

          def initialize(@handler : Proc(GameEvent, Nil), @priority : Int32 = HandlerPriority::Normal.value, @owner : String? = nil)
            @id = @@next_id
            @@next_id += 1
          end

          def <=>(other : HandlerEntry) : Int32
            cmp = other.priority <=> @priority
            cmp == 0 ? @id <=> other.id : cmp
          end
        end

        # Subscribe to a specific event type with a typed handler
        #
        # Returns a subscription ID that can be used to unsubscribe
        def subscribe(event_class : T.class, priority : HandlerPriority = HandlerPriority::Normal, owner : String? = nil, &handler : T -> Nil) : UInt64 forall T
          event_type = event_class.event_type
          @handlers[event_type] ||= [] of HandlerEntry

          # Wrap the typed handler in an untyped one
          wrapped = ->(event : GameEvent) do
            if typed_event = event.as?(T)
              handler.call(typed_event)
            end
            nil
          end

          entry = HandlerEntry.new(wrapped, priority.value, owner)
          @handlers[event_type] << entry
          @handlers[event_type].sort!

          entry.id
        end

        # Subscribe with explicit priority value
        def subscribe(event_class : T.class, priority : Int32, owner : String? = nil, &handler : T -> Nil) : UInt64 forall T
          event_type = event_class.event_type
          @handlers[event_type] ||= [] of HandlerEntry

          wrapped = ->(event : GameEvent) do
            if typed_event = event.as?(T)
              handler.call(typed_event)
            end
            nil
          end

          entry = HandlerEntry.new(wrapped, priority, owner)
          @handlers[event_type] << entry
          @handlers[event_type].sort!

          entry.id
        end

        # Unsubscribe a handler by its ID
        def unsubscribe(subscription_id : UInt64) : Bool
          @handlers.each do |event_type, handlers|
            if idx = handlers.index { |h| h.id == subscription_id }
              handlers.delete_at(idx)
              return true
            end
          end
          false
        end

        # Unsubscribe all handlers for a specific owner
        def unsubscribe_all(owner : String)
          @handlers.each do |event_type, handlers|
            handlers.reject! { |h| h.owner == owner }
          end
        end

        # Unsubscribe all handlers for a specific event type
        def unsubscribe_all_for(event_class : T.class) forall T
          @handlers.delete(event_class.event_type)
        end

        # Publish an event immediately (synchronous)
        def publish_sync(event : GameEvent)
          @events_published += 1
          dispatch(event)
        end

        # Queue an event for deferred processing
        def publish(event : GameEvent)
          @events_published += 1
          @event_queue << event
        end

        # Alias for publish
        def emit(event : GameEvent)
          publish(event)
        end

        # Process all queued events
        def process
          return if @processing
          @processing = true

          while !@event_queue.empty?
            event = @event_queue.shift
            dispatch(event)
            @events_processed += 1
          end

          @processing = false
        end

        # Process a single event from the queue
        def process_one : Bool
          return false if @event_queue.empty?

          event = @event_queue.shift
          dispatch(event)
          @events_processed += 1
          true
        end

        # Check if there are pending events
        def pending? : Bool
          !@event_queue.empty?
        end

        # Get number of pending events
        def pending_count : Int32
          @event_queue.size
        end

        # Clear all pending events
        def clear_queue
          @event_queue.clear
        end

        # Clear all handlers
        def clear_handlers
          @handlers.clear
        end

        # Clear everything
        def clear
          clear_queue
          clear_handlers
        end

        # Get statistics
        def stats : NamedTuple(published: UInt64, processed: UInt64, pending: Int32, handlers: Int32)
          total_handlers = @handlers.values.sum(&.size)
          {
            published: @events_published,
            processed: @events_processed,
            pending:   @event_queue.size,
            handlers:  total_handlers,
          }
        end

        # Check if any handlers exist for an event type
        def has_handlers?(event_class : T.class) : Bool forall T
          handlers = @handlers[event_class.event_type]?
          !!(handlers && !handlers.empty?)
        end

        # Get handler count for an event type
        def handler_count(event_class : T.class) : Int32 forall T
          @handlers[event_class.event_type]?.try(&.size) || 0
        end

        private def dispatch(event : GameEvent)
          handlers = @handlers[event.type]?
          return unless handlers

          handlers.each do |entry|
            break if event.consumed?

            begin
              entry.handler.call(event)
            rescue ex
              ErrorLogger.error("[EventBus] Handler error for '#{event.type}': #{ex.message}")
            end
          end
        end
      end

      # Global event bus instance (available through ServiceRegistry later)
      @@global_bus : EventBus?

      def self.global_bus : EventBus
        @@global_bus ||= EventBus.new
      end

      def self.global_bus=(bus : EventBus)
        @@global_bus = bus
      end
    end
  end
end
