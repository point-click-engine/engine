# Bloom effect shader

require "../shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      module Effects
        # Bloom/glow effect
        class BloomEffect < ShaderEffect
          property threshold : Float32 = 0.8f32
          property blur_amount : Float32 = 4.0f32

          def setup_uniforms
            get_uniform_location("threshold")
            get_uniform_location("blurSize")
          end

          def update_uniforms(time : Float32)
            set_uniform("threshold", @threshold)
            set_uniform("blurSize", @blur_amount * @intensity)
          end

          def self.create : BloomEffect
            fragment_shader = <<-GLSL
            #version 330
            
            in vec2 fragTexCoord;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform float threshold;
            uniform float blurSize;
            
            vec3 sampleBox(vec2 uv, float size) {
                vec3 color = vec3(0.0);
                float total = 0.0;
                
                for (float x = -size; x <= size; x += 1.0) {
                    for (float y = -size; y <= size; y += 1.0) {
                        vec2 offset = vec2(x, y) / vec2(800.0, 600.0);
                        color += texture(texture0, uv + offset).rgb;
                        total += 1.0;
                    }
                }
                
                return color / total;
            }
            
            void main() {
                vec3 color = texture(texture0, fragTexCoord).rgb;
                
                // Extract bright areas
                vec3 bright = max(color - threshold, 0.0);
                
                // Blur bright areas
                vec3 bloom = sampleBox(fragTexCoord, blurSize);
                bloom = max(bloom - threshold, 0.0);
                
                // Combine
                finalColor = vec4(color + bloom * 0.5, 1.0);
            }
            GLSL

            shader = ShaderManager.manager.load_from_memory("bloom", nil, fragment_shader)
            new(shader)
          end
        end
      end
    end
  end
end
