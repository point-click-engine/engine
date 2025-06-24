# Cinematic transition effects - warp, wave, film burn, static, matrix rain

require "../transition_effect"
require "../shader_loader"

module PointClickEngine
  module Graphics
    module Transitions
      # Space warp distortion effect
      class WarpEffect < BaseTransitionEffect
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
              
              // Warp effect - stretch towards center
              float warpFactor = 1.0 + progress * 3.0;
              tc = tc * (1.0 + dist * warpFactor);
              vec2 warpCoord = tc + center;
              
              if (warpCoord.x < 0.0 || warpCoord.x > 1.0 || warpCoord.y < 0.0 || warpCoord.y > 1.0) {
                  finalColor = vec4(0.0, 0.0, 0.0, 1.0);
              } else {
                  vec4 color = texture(texture0, warpCoord);
                  float alpha = 1.0 - smoothstep(0.7, 1.0, progress);
                  finalColor = vec4(color.rgb, color.a * alpha);
              }
          }
          SHADER
        end
      end

      # Ocean wave transition effect
      class WaveEffect < BaseTransitionEffect
        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)
          ShaderLoader.set_time(shader, progress * 3.0)
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
              vec2 tc = fragTexCoord;
              
              // Create wave distortion
              float wave = sin(tc.x * 10.0 + time * 2.0) * 0.05 * progress;
              tc.y += wave;
              
              vec4 color = texture(texture0, tc);
              
              // Wave sweeps from bottom to top
              float waveHeight = progress * 1.2 - 0.1;
              float alpha = step(waveHeight, tc.y);
              
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Old film burn transition effect
      class FilmBurnEffect < BaseTransitionEffect
        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)
          ShaderLoader.set_time(shader, progress * 5.0)
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
              vec4 color = texture(texture0, fragTexCoord);
              
              // Create burn pattern
              float burnNoise = random(fragTexCoord + time * 0.1);
              float burnEdge = smoothstep(progress - 0.1, progress + 0.1, burnNoise);
              
              // Add orange/red burn color
              vec3 burnColor = mix(vec3(1.0, 0.5, 0.0), vec3(0.8, 0.2, 0.0), random(fragTexCoord));
              
              if (burnNoise < progress) {
                  finalColor = vec4(0.0, 0.0, 0.0, 1.0); // Burned away
              } else if (burnEdge < 0.9) {
                  finalColor = vec4(burnColor, 1.0); // Burn edge
              } else {
                  finalColor = color; // Original image
              }
          }
          SHADER
        end
      end

      # TV static noise transition effect
      class StaticEffect < BaseTransitionEffect
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
              vec4 color = texture(texture0, fragTexCoord);
              
              // Generate static noise
              float noise = random(fragTexCoord + time * 0.1);
              vec3 staticColor = vec3(noise);
              
              // Mix original image with static based on progress
              float staticAmount = progress * 2.0;
              vec3 finalRGB = mix(color.rgb, staticColor, min(staticAmount, 1.0));
              
              float alpha = max(0.0, 1.0 - (staticAmount - 1.0));
              finalColor = vec4(finalRGB, color.a * alpha);
          }
          SHADER
        end
      end

      # Matrix-style digital rain effect
      class MatrixRainEffect < BaseTransitionEffect
        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)
          ShaderLoader.set_time(shader, progress * 8.0)
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
              vec4 color = texture(texture0, fragTexCoord);
              
              // Create vertical rain columns
              float column = floor(fragTexCoord.x * 40.0);
              float rain = fract(fragTexCoord.y * 20.0 - time + random(vec2(column, 0.0)) * 10.0);
              
              // Make some drops brighter
              float dropIntensity = smoothstep(0.9, 1.0, rain) * random(vec2(column, floor(time)));
              
              // Green matrix color
              vec3 matrixColor = vec3(0.0, 1.0, 0.2) * dropIntensity;
              
              // Fade effect
              float fade = smoothstep(0.0, 0.5, progress);
              vec3 finalRGB = mix(color.rgb, matrixColor, fade * dropIntensity);
              
              float alpha = 1.0 - smoothstep(0.5, 1.0, progress);
              finalColor = vec4(finalRGB, color.a * alpha);
          }
          SHADER
        end
      end
    end
  end
end
