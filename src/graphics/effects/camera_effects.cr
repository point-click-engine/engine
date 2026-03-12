# Camera effects module aggregator

require "./camera_effects/base_camera_effect"
require "./camera_effects/movement_effects"

module PointClickEngine
  module Graphics
    module Effects
      module CameraEffects
        # Convenience method to create camera effects
        def self.create(effect_name : String, **params) : BaseCameraEffect?
          CameraEffectFactory.create(effect_name, **params)
        end
      end
    end
  end
end
