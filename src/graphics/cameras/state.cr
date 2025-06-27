# Camera state for saving/restoring
#
# Stores the current state of a camera including position, zoom, rotation
# and the name of the active camera

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Cameras
      # Camera state for saving/restoring
      struct State
        property position : RL::Vector2
        property zoom : Float32
        property rotation : Float32
        property active_camera : String

        def initialize(@position : RL::Vector2, @zoom : Float32, @rotation : Float32, @active_camera : String)
        end
      end
    end
  end
end
