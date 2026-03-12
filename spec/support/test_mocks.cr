# Testing Mocks for Unit Tests
#
# Provides mock implementations for testing purposes.
# These are simplified mocks for unit testing.
#
# Example usage:
# ```
# event_bus = MockEventBus.new
# event_bus.publish(PointClickEngine::Core::Events::SceneEnteredEvent.new("test_scene"))
# event_bus.was_published?(PointClickEngine::Core::Events::SceneEnteredEvent).should be_true
# ```

module PointClickEngine
  module Core
    module Testing
      # Mock resource loader that tracks loaded resources without file I/O
      class MockResourceLoader
        @loaded_resources : Hash(String, String) = {} of String => String
        @load_calls : Array(String) = [] of String

        def load_resource(path : String, type : String) : Bool
          @load_calls << path
          @loaded_resources[path] = type
          true
        end

        def unload_resource(path : String) : Bool
          @loaded_resources.delete(path)
          true
        end

        def resource_loaded?(path : String) : Bool
          @loaded_resources.has_key?(path)
        end

        def loaded_resources : Hash(String, String)
          @loaded_resources
        end

        def load_calls : Array(String)
          @load_calls
        end

        def clear
          @loaded_resources.clear
          @load_calls.clear
        end

        def was_loaded?(path : String) : Bool
          @load_calls.includes?(path)
        end
      end

      # Mock input manager that allows simulating inputs
      class MockInputManager
        @simulated_mouse_pos : Tuple(Float32, Float32) = {0f32, 0f32}
        @simulated_clicks : Array(Tuple(Int32, Int32)) = [] of Tuple(Int32, Int32)
        @simulated_keys : Set(Int32) = Set(Int32).new

        def get_mouse_position : Tuple(Float32, Float32)
          @simulated_mouse_pos
        end

        def is_mouse_button_pressed?(button : Int32) : Bool
          @simulated_clicks.any? { |c| c[0] == button }
        end

        def is_key_pressed?(key : Int32) : Bool
          @simulated_keys.includes?(key)
        end

        def process_input(dt : Float32)
        end

        def simulate_mouse_position(x : Float32, y : Float32)
          @simulated_mouse_pos = {x, y}
        end

        def simulate_click(button : Int32 = 0)
          @simulated_clicks << {button, 1}
        end

        def simulate_key(key : Int32)
          @simulated_keys << key
        end

        def clear_simulated_inputs
          @simulated_clicks.clear
          @simulated_keys.clear
        end
      end

      # Mock render manager that tracks render calls
      class MockRenderManager
        @render_calls : Array(String) = [] of String
        @rendering : Bool = false

        def begin_frame
          @rendering = true
          @render_calls << "begin_frame"
        end

        def end_frame
          @rendering = false
          @render_calls << "end_frame"
        end

        def render_scene(scene)
          @render_calls << "render_scene:#{scene}"
        end

        def render_ui
          @render_calls << "render_ui"
        end

        def render_calls : Array(String)
          @render_calls
        end

        def rendering? : Bool
          @rendering
        end

        def clear
          @render_calls.clear
        end

        def was_rendered?(pattern : String) : Bool
          @render_calls.any? { |call| call.includes?(pattern) }
        end
      end

      # Mock EventBus that tracks all published events
      class MockEventBus < Events::EventBus
        @published_events : Array(Events::GameEvent) = [] of Events::GameEvent

        def publish(event : Events::GameEvent)
          @published_events << event
          super(event)
        end

        def publish_sync(event : Events::GameEvent)
          @published_events << event
          super(event)
        end

        def published_events : Array(Events::GameEvent)
          @published_events
        end

        def clear_published_events
          @published_events.clear
        end

        def was_published?(event_type : T.class) : Bool forall T
          @published_events.any? { |e| e.is_a?(T) }
        end

        def get_events(event_type : T.class) : Array(T) forall T
          @published_events.select { |e| e.is_a?(T) }.map { |e| e.as(T) }
        end

        def event_count(event_type : T.class) : Int32 forall T
          get_events(event_type).size
        end
      end

      # Mock GameStateManager for isolated state testing
      class MockGameStateManager < GameStateManager
        @state_changes : Array(Tuple(String, GameValue)) = [] of Tuple(String, GameValue)

        def set_flag(name : String, value : Bool)
          @state_changes << {name, value}
          super(name, value)
        end

        def set_variable(name : String, value : GameValue)
          @state_changes << {name, value}
          super(name, value)
        end

        def state_changes : Array(Tuple(String, GameValue))
          @state_changes
        end

        def clear_changes
          @state_changes.clear
        end

        def was_set?(name : String) : Bool
          @state_changes.any? { |c| c[0] == name }
        end

        def get_change(name : String) : GameValue?
          change = @state_changes.reverse.find { |c| c[0] == name }
          change.try(&.[](1))
        end
      end

      # Factory for creating test mocks
      module TestFactory
        def self.create_test_state : Tuple(MockEventBus, MockGameStateManager)
          event_bus = MockEventBus.new
          game_state = MockGameStateManager.new(event_bus)
          {event_bus, game_state}
        end

        def self.create_event_bus : MockEventBus
          MockEventBus.new
        end

        def self.create_state_manager : MockGameStateManager
          MockGameStateManager.new
        end
      end
    end
  end
end
