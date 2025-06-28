# Post-processing effects module aggregator
#
# Provides advanced shader-based post-processing effects
# for visual enhancement and special effects.

require "./post_processing/blur_shader"
require "./post_processing/distortion_shader"
require "./post_processing/glow_shader"
require "./post_processing/post_processing_factory"

module PointClickEngine
  module Graphics
    module Effects
      module PostProcessing
        # Convenience method to create post-processing effects
        def self.create(effect_name : String, **params) : ShaderEffect?
          PostProcessingFactory.create(effect_name, **params)
        end
      end
    end
  end
end