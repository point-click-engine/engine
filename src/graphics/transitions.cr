# Scene transition effects using modular shader system
# This file maintains the original API while using the new modular structure

require "./transitions/transition_effect"
require "./transitions/shader_loader"
require "./transitions/transition_manager"

module PointClickEngine
  module Graphics
    # Re-export the transition types and manager for backwards compatibility
    alias TransitionEffect = Transitions::TransitionEffect
    alias TransitionManager = Transitions::TransitionManager
  end
end
