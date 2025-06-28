# Pixelate effect shader

require "../shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      module Retro
        # Pixelation effect for retro look
        class PixelateEffect < ShaderEffect
          property pixel_size : Float32 = 4.0f32

          def setup_uniforms
            get_uniform_location("resolution")
            get_uniform_location("pixelSize")
          end

          def update_uniforms(time : Float32)
            resolution = RL::Vector2.new(
              x: RL.get_screen_width.to_f32,
              y: RL.get_screen_height.to_f32
            )

            set_uniform("resolution", resolution)
            set_uniform("pixelSize", @pixel_size * @intensity)
          end

          def self.create : PixelateEffect
            fragment_shader = <<-GLSL
            #version 330
            
            in vec2 fragTexCoord;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform vec2 resolution;
            uniform float pixelSize;
            
            void main() {
                vec2 size = pixelSize / resolution;
                vec2 uv = floor(fragTexCoord / size) * size;
                finalColor = texture(texture0, uv);
            }
            GLSL

            shader = ShaderManager.manager.load_from_memory("pixelate", nil, fragment_shader)
            new(shader)
          end
        end
      end
    end
  end
end
