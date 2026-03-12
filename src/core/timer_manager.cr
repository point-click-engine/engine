# Timer manager for scheduling delayed callbacks via EventBus
#
# Timers use EventBus pattern: when a timer fires, it publishes TimerFiredEvent
# The ScriptEngine subscribes and executes the associated Lua callback

require "./events/events"

module PointClickEngine
  module Core
    # Individual timer instance
    class Timer
      property id : String
      property delay : Float32
      property elapsed : Float32 = 0.0f32
      property callback_code : String?
      property repeating : Bool
      property fired : Bool = false

      def initialize(@id : String, @delay : Float32, @callback_code : String? = nil, @repeating : Bool = false)
      end

      # Update timer, returns true if timer fired
      def update(dt : Float32) : Bool
        return false if @fired && !@repeating

        @elapsed += dt

        if @elapsed >= @delay
          if @repeating
            @elapsed -= @delay
          else
            @fired = true
          end
          return true
        end

        false
      end

      def completed? : Bool
        @fired && !@repeating
      end
    end

    # Manager for all game timers
    class TimerManager
      property timers : Array(Timer) = [] of Timer
      property event_bus : Events::EventBus?
      @next_timer_id : Int32 = 0

      def initialize(@event_bus : Events::EventBus? = nil)
      end

      # Add a one-shot timer
      def add_timer(delay : Float32, callback_code : String? = nil) : String
        id = generate_id
        timer = Timer.new(id, delay, callback_code, repeating: false)
        @timers << timer
        id
      end

      # Add a repeating timer
      def add_repeating_timer(delay : Float32, callback_code : String? = nil) : String
        id = generate_id
        timer = Timer.new(id, delay, callback_code, repeating: true)
        @timers << timer
        id
      end

      # Cancel a timer by id
      def cancel_timer(id : String) : Bool
        if timer = @timers.find { |t| t.id == id }
          @timers.delete(timer)
          return true
        end
        false
      end

      # Cancel all timers
      def cancel_all
        @timers.clear
      end

      # Update all timers
      def update(dt : Float32)
        @timers.each do |timer|
          if timer.update(dt)
            # Timer fired - publish event
            if bus = @event_bus
              bus.publish(Events::TimerFiredEvent.new(timer.id, timer.callback_code))
            end
          end
        end

        # Remove completed one-shot timers
        @timers.reject!(&.completed?)
      end

      # Check if any timers are active
      def has_active_timers? : Bool
        !@timers.empty?
      end

      # Get number of active timers
      def active_timer_count : Int32
        @timers.size
      end

      private def generate_id : String
        @next_timer_id += 1
        "timer_#{@next_timer_id}"
      end
    end
  end
end
