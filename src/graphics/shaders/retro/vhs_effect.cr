# VHS tape effect shader

require "../shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      module Retro
        # VHS tape distortion effect
        class VHSEffect < ShaderEffect
          property distortion : Float32 = 0.1f32
          property noise_amount : Float32 = 0.05f32
          property scan_distort : Float32 = 0.03f32

          def setup_uniforms
            get_uniform_location("time")
            get_uniform_location("distortion")
            get_uniform_location("noiseAmount")
            get_uniform_location("scanDistort")
          end

          def update_uniforms(time : Float32)
            set_uniform("time", time)
            set_uniform("distortion", @distortion * @intensity)
            set_uniform("noiseAmount", @noise_amount * @intensity)
            set_uniform("scanDistort", @scan_distort * @intensity)
          end

          def self.create : VHSEffect
            fragment_shader = <<-GLSL
            #version 330
            
            in vec2 fragTexCoord;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform float time;
            uniform float distortion;
            uniform float noiseAmount;
            uniform float scanDistort;
            
            float random(vec2 st) {
                return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
            }
            
            float noise(vec2 st) {
                vec2 i = floor(st);
                vec2 f = fract(st);
                
                float a = random(i);
                float b = random(i + vec2(1.0, 0.0));
                float c = random(i + vec2(0.0, 1.0));
                float d = random(i + vec2(1.0, 1.0));
                
                vec2 u = f * f * (3.0 - 2.0 * f);
                
                return mix(a, b, u.x) + (c - a)* u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
            }
            
            void main() {
                vec2 uv = fragTexCoord;
                
                // Scan line distortion
                float scanLine = sin(uv.y * 800.0 + time * 10.0);
                uv.x += scanLine * scanDistort;
                
                // Wave distortion
                uv.x += sin(uv.y * 10.0 + time * 5.0) * distortion;
                
                // Color separation
                float r = texture(texture0, uv + vec2(0.002, 0.0)).r;
                float g = texture(texture0, uv).g;
                float b = texture(texture0, uv - vec2(0.002, 0.0)).b;
                
                vec3 color = vec3(r, g, b);
                
                // Add noise
                float n = noise(uv * 200.0 + vec2(time * 100.0, 0.0));
                color += n * noiseAmount;
                
                // Tracking lines
                if (random(vec2(time * 0.1, 0.0)) > 0.95) {
                    color = vec3(1.0);
                }
                
                // Output
                finalColor = vec4(color, 1.0);
            }
            GLSL

            shader = ShaderManager.manager.load_from_memory("vhs", nil, fragment_shader)
            new(shader)
          end
        end
      end
    end
  end
end
