# CRT monitor effect shader

require "../shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      module Retro
        # CRT monitor effect with scanlines and curvature
        class CRTEffect < ShaderEffect
          property scanline_intensity : Float32 = 0.3f32
          property curvature : Float32 = 0.25f32
          property vignette : Float32 = 0.5f32
          property aberration : Float32 = 0.002f32

          def setup_uniforms
            # Cache uniform locations
            get_uniform_location("resolution")
            get_uniform_location("time")
            get_uniform_location("scanlineIntensity")
            get_uniform_location("curvature")
            get_uniform_location("vignette")
            get_uniform_location("aberration")
          end

          def update_uniforms(time : Float32)
            resolution = RL::Vector2.new(
              x: @shader.id > 0 ? RL.get_screen_width.to_f32 : 800.0f32,
              y: @shader.id > 0 ? RL.get_screen_height.to_f32 : 600.0f32
            )

            set_uniform("resolution", resolution)
            set_uniform("time", time)
            set_uniform("scanlineIntensity", @scanline_intensity * @intensity)
            set_uniform("curvature", @curvature)
            set_uniform("vignette", @vignette)
            set_uniform("aberration", @aberration * @intensity)
          end

          # Create CRT shader from code
          def self.create : CRTEffect
            fragment_shader = <<-GLSL
            #version 330
            
            in vec2 fragTexCoord;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform vec2 resolution;
            uniform float time;
            uniform float scanlineIntensity;
            uniform float curvature;
            uniform float vignette;
            uniform float aberration;
            
            vec2 curve(vec2 uv) {
                uv = (uv - 0.5) * 2.0;
                uv *= 1.1;
                uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0) * curvature;
                uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0) * curvature;
                uv = (uv / 2.0) + 0.5;
                uv = uv * 0.92 + 0.04;
                return uv;
            }
            
            void main() {
                vec2 uv = curve(fragTexCoord);
                
                // Outside screen bounds
                if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                    finalColor = vec4(0.0, 0.0, 0.0, 1.0);
                    return;
                }
                
                // Chromatic aberration
                float r = texture(texture0, uv + vec2(aberration, 0.0)).r;
                float g = texture(texture0, uv).g;
                float b = texture(texture0, uv - vec2(aberration, 0.0)).b;
                
                vec3 color = vec3(r, g, b);
                
                // Scanlines
                float scanline = sin(uv.y * resolution.y * 3.14159) * scanlineIntensity;
                color -= scanline;
                
                // Moving scanline
                float movingScanline = sin((uv.y + time * 0.05) * resolution.y * 0.5) * 0.02;
                color -= movingScanline;
                
                // Vignette
                float vig = 16.0 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
                vig = pow(vig, vignette);
                color *= vig;
                
                finalColor = vec4(color, 1.0);
            }
            GLSL

            shader = ShaderManager.manager.load_from_memory("crt", nil, fragment_shader)
            new(shader)
          end
        end
      end
    end
  end
end
