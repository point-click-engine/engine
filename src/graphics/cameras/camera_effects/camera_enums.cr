# Camera effect enums
#
# Defines the types of camera effects and easing functions available

module PointClickEngine
  module Graphics
    module Cameras
      # Camera effect types
      enum CameraEffectType
        Shake
        Zoom
        Pan
        Follow
        Sway
        Rotation
      end

      # Camera transition easing types
      enum CameraEasing
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
