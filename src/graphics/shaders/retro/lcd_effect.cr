# LCD/Game Boy style effect shader

require "../shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      module Retro
        # LCD display effect like Game Boy
        class LCDEffect < ShaderEffect
          property grid_intensity : Float32 = 0.3f32
          property color_reduction : Float32 = 4.0f32

          def setup_uniforms
            get_uniform_location("resolution")
            get_uniform_location("gridIntensity")
            get_uniform_location("colorLevels")
          end

          def update_uniforms(time : Float32)
            resolution = RL::Vector2.new(
              x: RL.get_screen_width.to_f32,
              y: RL.get_screen_height.to_f32
            )

            set_uniform("resolution", resolution)
            set_uniform("gridIntensity", @grid_intensity * @intensity)
            set_uniform("colorLevels", @color_reduction)
          end

          def self.create : LCDEffect
            fragment_shader = <<-GLSL
            #version 330
            
            in vec2 fragTexCoord;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform vec2 resolution;
            uniform float gridIntensity;
            uniform float colorLevels;
            
            void main() {
                vec4 color = texture(texture0, fragTexCoord);
                
                // Reduce color levels
                color.rgb = floor(color.rgb * colorLevels) / colorLevels;
                
                // LCD grid effect
                vec2 pixel = fragTexCoord * resolution;
                float grid = 1.0;
                
                // Horizontal lines
                if (mod(pixel.y, 3.0) < 1.0) {
                    grid *= 1.0 - gridIntensity;
                }
                
                // Vertical lines
                if (mod(pixel.x, 3.0) < 1.0) {
                    grid *= 1.0 - gridIntensity * 0.5;
                }
                
                // Sub-pixel pattern
                float subpixel = 1.0;
                if (mod(pixel.x, 3.0) < 1.0) {
                    subpixel = vec3(1.2, 0.9, 0.9).r;
                } else if (mod(pixel.x, 3.0) < 2.0) {
                    subpixel = vec3(0.9, 1.2, 0.9).g;
                } else {
                    subpixel = vec3(0.9, 0.9, 1.2).b;
                }
                
                color.rgb *= grid * subpixel;
                finalColor = color;
            }
            GLSL

            shader = ShaderManager.manager.load_from_memory("lcd", nil, fragment_shader)
            new(shader)
          end
        end
      end
    end
  end
end
