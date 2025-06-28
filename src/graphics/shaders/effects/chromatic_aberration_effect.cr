# Chromatic aberration effect shader

require "../shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      module Effects
        # Chromatic aberration (color fringing) effect
        class ChromaticAberrationEffect < ShaderEffect
          property red_offset : Float32 = 0.005f32
          property green_offset : Float32 = 0.0f32
          property blue_offset : Float32 = -0.005f32

          def setup_uniforms
            get_uniform_location("redOffset")
            get_uniform_location("greenOffset")
            get_uniform_location("blueOffset")
          end

          def update_uniforms(time : Float32)
            set_uniform("redOffset", @red_offset * @intensity)
            set_uniform("greenOffset", @green_offset * @intensity)
            set_uniform("blueOffset", @blue_offset * @intensity)
          end

          def self.create : ChromaticAberrationEffect
            fragment_shader = <<-GLSL
            #version 330
            
            in vec2 fragTexCoord;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform float redOffset;
            uniform float greenOffset;
            uniform float blueOffset;
            
            void main() {
                float r = texture(texture0, fragTexCoord + vec2(redOffset, 0.0)).r;
                float g = texture(texture0, fragTexCoord + vec2(greenOffset, 0.0)).g;
                float b = texture(texture0, fragTexCoord + vec2(blueOffset, 0.0)).b;
                float a = texture(texture0, fragTexCoord).a;
                
                finalColor = vec4(r, g, b, a);
            }
            GLSL

            shader = ShaderManager.manager.load_from_memory("chromatic_aberration", nil, fragment_shader)
            new(shader)
          end
        end
      end
    end
  end
end
