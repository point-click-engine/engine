# Film grain effect shader

require "../shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      module Effects
        # Film grain noise effect
        class FilmGrainEffect < ShaderEffect
          property grain_amount : Float32 = 0.1f32
          property grain_size : Float32 = 1.5f32

          def setup_uniforms
            get_uniform_location("time")
            get_uniform_location("grainAmount")
            get_uniform_location("grainSize")
          end

          def update_uniforms(time : Float32)
            set_uniform("time", time)
            set_uniform("grainAmount", @grain_amount * @intensity)
            set_uniform("grainSize", @grain_size)
          end

          def self.create : FilmGrainEffect
            fragment_shader = <<-GLSL
            #version 330
            
            in vec2 fragTexCoord;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform float time;
            uniform float grainAmount;
            uniform float grainSize;
            
            float random(vec2 st) {
                return fract(sin(dot(st.xy + vec2(time), vec2(12.9898,78.233))) * 43758.5453123);
            }
            
            void main() {
                vec4 color = texture(texture0, fragTexCoord);
                
                // Generate grain
                vec2 grainCoord = fragTexCoord * grainSize;
                float grain = random(floor(grainCoord));
                grain = (grain - 0.5) * grainAmount;
                
                // Apply grain
                color.rgb += grain;
                
                finalColor = color;
            }
            GLSL

            shader = ShaderManager.manager.load_from_memory("film_grain", nil, fragment_shader)
            new(shader)
          end
        end
      end
    end
  end
end
