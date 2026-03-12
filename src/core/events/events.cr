# Events module - Unified event system for the engine
#
# This module provides a type-safe event bus system for decoupled communication
# between engine components.
#
# Usage:
# ```
# require "./events/events"
#
# bus = Core::Events::EventBus.new
#
# # Subscribe to events
# bus.subscribe(Events::SceneEnteredEvent) do |event|
#   puts "Entered scene: #{event.scene_name}"
# end
#
# # Publish events
# bus.publish(Events::SceneEnteredEvent.new("forest"))
#
# # Process queued events
# bus.process
# ```

require "./game_event"
require "./event_bus"
require "./game_events"

module PointClickEngine
  module Core
    module Events
      VERSION = "1.0.0"
    end
  end
end
