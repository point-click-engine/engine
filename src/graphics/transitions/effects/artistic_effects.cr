# Artistic transition effects - swirl, curtain, ripple, glitch

require "../transition_effect"
require "../shader_loader"

module PointClickEngine
  module Graphics
    module Transitions
      # Swirl/spiral transition effect
      class SwirlEffect < BaseTransitionEffect
        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)
        end

        def fragment_shader_source : String
          <<-SHADER
          #version 330 core
          in vec2 fragTexCoord;
          in vec4 fragColor;
          out vec4 finalColor;

          uniform sampler2D texture0;
          uniform float progress;

          void main()
          {
              vec2 center = vec2(0.5, 0.5);
              vec2 tc = fragTexCoord - center;
              float dist = length(tc);
              float angle = atan(tc.y, tc.x);
              
              // Create swirl effect based on distance and progress
              float swirl = progress * 10.0 * (1.0 - dist);
              angle += swirl;
              
              vec2 swirlCoord = center + dist * vec2(cos(angle), sin(angle));
              
              if (swirlCoord.x < 0.0 || swirlCoord.x > 1.0 || swirlCoord.y < 0.0 || swirlCoord.y > 1.0) {
                  finalColor = vec4(0.0, 0.0, 0.0, 1.0);
              } else {
                  vec4 color = texture(texture0, swirlCoord);
                  float alpha = 1.0 - progress;
                  finalColor = vec4(color.rgb, color.a * alpha);
              }
          }
          SHADER
        end
      end

      # Theater curtain closing effect
      class CurtainEffect < BaseTransitionEffect
        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)
        end

        def fragment_shader_source : String
          <<-SHADER
          #version 330 core
          in vec2 fragTexCoord;
          in vec4 fragColor;
          out vec4 finalColor;

          uniform sampler2D texture0;
          uniform float progress;

          void main()
          {
              vec4 color = texture(texture0, fragTexCoord);
              
              // Curtains close from left and right
              float leftCurtain = progress * 0.5;
              float rightCurtain = 1.0 - progress * 0.5;
              
              float alpha = 1.0;
              if (fragTexCoord.x < leftCurtain || fragTexCoord.x > rightCurtain) {
                  alpha = 0.0;
              }
              
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Water ripple transition effect
      class RippleEffect < BaseTransitionEffect
        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)
          ShaderLoader.set_time(shader, progress * 5.0) # Speed up the ripple
        end

        def fragment_shader_source : String
          <<-SHADER
          #version 330 core
          in vec2 fragTexCoord;
          in vec4 fragColor;
          out vec4 finalColor;

          uniform sampler2D texture0;
          uniform float progress;
          uniform float time;

          void main()
          {
              vec2 center = vec2(0.5, 0.5);
              float dist = distance(fragTexCoord, center);
              
              // Create ripple waves
              float ripple = sin(dist * 30.0 - time * 5.0) * 0.02;
              vec2 rippleCoord = fragTexCoord + ripple * normalize(fragTexCoord - center);
              
              vec4 color = texture(texture0, rippleCoord);
              
              // Fade based on ripple progress
              float fadeRadius = progress * 1.2;
              float alpha = step(dist, fadeRadius);
              
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Digital glitch transition effect
      class GlitchEffect < BaseTransitionEffect
        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)
          ShaderLoader.set_time(shader, progress * 10.0)
        end

        def fragment_shader_source : String
          <<-SHADER
          #version 330 core
          in vec2 fragTexCoord;
          in vec4 fragColor;
          out vec4 finalColor;

          uniform sampler2D texture0;
          uniform float progress;
          uniform float time;

          float random(vec2 st) {
              return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
          }

          void main()
          {
              vec2 tc = fragTexCoord;
              
              // Horizontal glitch lines
              float glitchLine = floor(tc.y * 20.0);
              float glitchNoise = random(vec2(glitchLine, time));
              
              if (glitchNoise > 0.95 && progress > 0.2) {
                  tc.x += (random(vec2(glitchLine, time * 2.0)) - 0.5) * 0.1 * progress;
              }
              
              // RGB shift
              vec4 color;
              if (progress > 0.5) {
                  float shift = (progress - 0.5) * 0.02;
                  color.r = texture(texture0, tc + vec2(shift, 0.0)).r;
                  color.g = texture(texture0, tc).g;
                  color.b = texture(texture0, tc - vec2(shift, 0.0)).b;
                  color.a = texture(texture0, tc).a;
              } else {
                  color = texture(texture0, tc);
              }
              
              // Add digital noise
              float noise = random(tc + time);
              if (noise > 0.98 && progress > 0.3) {
                  color = vec4(1.0, 1.0, 1.0, color.a);
              }
              
              float alpha = 1.0 - progress;
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end
    end
  end
end
