# Event system for game scripting

module PointClickEngine
  module Scripting
    # Event data container
    struct Event
      # include YAML::Serializable

      property type : String
      property data : Hash(String, String) = {} of String => String
      property timestamp : Float64

      def initialize(@type : String, @data = {} of String => String)
        @timestamp = Time.utc.to_unix_f
      end

      def get_string(key : String) : String
        @data[key]? || ""
      end

      def get_float(key : String) : Float32
        @data[key]?.try(&.to_f32) || 0.0_f32
      end

      def get_int(key : String) : Int32
        @data[key]?.try(&.to_i32) || 0
      end

      def get_bool(key : String) : Bool
        @data[key]? == "true"
      end

      def set_data(key : String, value)
        @data[key] = value.to_s
      end
    end

    # Event handler that can be attached to game objects
    abstract class EventHandler
      abstract def handle_event(event : Event) : Bool
      abstract def get_handled_events : Array(String)
    end

    # Script-based event handler
    class ScriptEventHandler < EventHandler
      getter script_engine : ScriptEngine
      getter function_name : String
      getter handled_events : Array(String)

      def initialize(@script_engine : ScriptEngine, @function_name : String, @handled_events : Array(String) = [] of String)
      end

      def handle_event(event : Event) : Bool
        return false unless @handled_events.empty? || @handled_events.includes?(event.type)

        # Set event data in Lua environment
        @script_engine.set_global("current_event_type", event.type)
        @script_engine.set_global("current_event_data", event.data.to_s)
        @script_engine.set_global("current_event_timestamp", event.timestamp)

        # Call the specific Lua function
        @script_engine.call_function(@function_name, event.data)

        true
      end

      def get_handled_events : Array(String)
        @handled_events
      end
    end

    # Function-based event handler for Crystal code
    class FunctionEventHandler < EventHandler
      getter handler_proc : Proc(Event, Bool)
      getter handled_events : Array(String)

      def initialize(@handler_proc : Proc(Event, Bool), @handled_events : Array(String))
      end

      def handle_event(event : Event) : Bool
        return false unless @handled_events.includes?(event.type)
        @handler_proc.call(event)
      end

      def get_handled_events : Array(String)
        @handled_events
      end
    end

    # Main event system manager
    class EventSystem
      @handlers = Array(EventHandler).new
      @event_queue = Array(Event).new
      @processing = false

      def add_handler(handler : EventHandler)
        @handlers << handler
      end

      def remove_handler(handler : EventHandler)
        @handlers.delete(handler)
      end

      def trigger_event(event : Event)
        @event_queue << event
      end

      def trigger_event(type : String, data = {} of String => String)
        event = Event.new(type, data)
        trigger_event(event)
      end

      def process_events
        return if @processing
        @processing = true

        while !@event_queue.empty?
          event = @event_queue.shift
          process_event(event)
        end

        @processing = false
      end

      def clear_handlers
        @handlers.clear
      end

      def clear_events
        @event_queue.clear
      end

      private def process_event(event : Event)
        @handlers.each do |handler|
          begin
            handler.handle_event(event)
          rescue ex
            puts "Event handler error: #{ex.message}"
          end
        end
      end
      
      # Convenience method alias
      def trigger(type : String, data = {} of String => String)
        trigger_event(type, data)
      end
      
      # Convenience method for registering simple event handlers
      def on(event_type : String, &handler : ->)
        handler_proc = ->(event : Event) do
          handler.call
          true
        end
        add_handler(FunctionEventHandler.new(handler_proc, [event_type]))
      end
    end

    # Common game events
    module Events
      # Player events
      PLAYER_MOVED    = "player_moved"
      PLAYER_INTERACT = "player_interact"
      PLAYER_CLICK    = "player_click"

      # Character events
      CHARACTER_SPEAK              = "character_speak"
      CHARACTER_ANIMATION_COMPLETE = "character_animation_complete"
      CHARACTER_REACHED_TARGET     = "character_reached_target"

      # Scene events
      SCENE_ENTERED   = "scene_entered"
      SCENE_EXITED    = "scene_exited"
      HOTSPOT_CLICKED = "hotspot_clicked"
      HOTSPOT_HOVERED = "hotspot_hovered"

      # Inventory events
      ITEM_ADDED    = "item_added"
      ITEM_REMOVED  = "item_removed"
      ITEM_SELECTED = "item_selected"
      ITEM_USED     = "item_used"

      # Dialog events
      DIALOG_STARTED         = "dialog_started"
      DIALOG_ENDED           = "dialog_ended"
      DIALOG_CHOICE_SELECTED = "dialog_choice_selected"

      # Game events
      GAME_STARTED = "game_started"
      GAME_SAVED   = "game_saved"
      GAME_LOADED  = "game_loaded"
      GAME_PAUSED  = "game_paused"
      GAME_RESUMED = "game_resumed"

      # Custom events (for user scripts)
      CUSTOM_EVENT = "custom_event"
    end
  end
end
