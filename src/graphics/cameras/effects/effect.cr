# Base camera effect class
#
# Represents an active camera effect with common properties like duration,
# elapsed time, and parameters.

require "./enums"
require "../../../characters/character"

module PointClickEngine
  module Graphics
    module Cameras
      # Represents an active camera effect
      class Effect
        property type : EffectType
        property duration : Float32
        property elapsed : Float32 = 0.0f32
        property parameters : Hash(String, Float32 | Characters::Character | Bool)
        property easing : Easing = Easing::Linear

        def initialize(@type : EffectType, @duration : Float32, @parameters : Hash(String, Float32 | Characters::Character | Bool))
        end

        def active?
          @duration <= 0 || @elapsed < @duration
        end

        def progress
          return 1.0f32 if @duration <= 0
          (@elapsed / @duration).clamp(0.0f32, 1.0f32)
        end

        def update(dt : Float32)
          @elapsed += dt
        end
      end
    end
  end
end
