# Camera effect enums
#
# Defines the types of camera effects and easing functions available

module PointClickEngine
  module Graphics
    module Cameras
      # Camera effect types
      enum EffectType
        Shake
        Zoom
        Pan
        Follow
        Sway
        Rotation
      end

      # Camera transition easing types
      enum Easing
        Linear
        EaseIn
        EaseOut
        EaseInOut
        Bounce
        Elastic
      end
    end
  end
end
