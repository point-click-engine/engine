# Shader effects module

require "./shaders/shader_effect"
require "./shaders/shader_manager"
require "./shaders/shader_system"
require "./shaders/shader_helpers"
require "./shaders/post_processor"

# Retro effects
require "./shaders/retro/crt_effect"
require "./shaders/retro/pixelate_effect"
require "./shaders/retro/lcd_effect"
require "./shaders/retro/vhs_effect"

# General effects
require "./shaders/effects/bloom_effect"
require "./shaders/effects/chromatic_aberration_effect"
require "./shaders/effects/film_grain_effect"

module PointClickEngine
  module Graphics
    # Shader-based post-processing effects
    module Shaders
      # Convenience method to create post-processor
      def self.create_post_processor(width : Int32, height : Int32) : PostProcessor
        PostProcessor.new(width, height)
      end
    end
  end
end
