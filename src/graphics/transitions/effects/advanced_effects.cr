# Advanced transition effects - zoom blur, clock wipe, barn door, page turn, shatter, vortex, fire

require "../transition_effect"
require "../shader_loader"

module PointClickEngine
  module Graphics
    module Transitions
      # Zoom with motion blur effect
      class ZoomBlurEffect < BaseTransitionEffect
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
              vec4 color = vec4(0.0);
              
              // Sample multiple points for blur effect
              int samples = 10;
              for (int i = 0; i < samples; i++) {
                  float scale = 1.0 + progress * float(i) * 0.02;
                  vec2 offset = (fragTexCoord - center) * scale + center;
                  color += texture(texture0, offset);
              }
              
              color /= float(samples);
              float alpha = 1.0 - progress;
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Clock hand sweep transition
      class ClockWipeEffect < BaseTransitionEffect
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
              vec2 center = vec2(0.5, 0.5);
              vec2 tc = fragTexCoord - center;
              
              // Calculate angle from center (0 = top, increases clockwise)
              float angle = atan(tc.x, tc.y) + 3.14159;
              angle = angle / (2.0 * 3.14159); // Normalize to 0-1
              
              // Clock hand sweep
              float threshold = progress;
              float alpha = step(threshold, angle);
              
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Barn doors closing effect
      class BarnDoorEffect < BaseTransitionEffect
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
              
              // Barn doors close from center outward
              float center = 0.5;
              float doorWidth = progress * 0.5;
              
              float alpha = 1.0;
              if (fragTexCoord.x > center - doorWidth && fragTexCoord.x < center + doorWidth) {
                  alpha = 0.0;
              }
              
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Page turning effect
      class PageTurnEffect < BaseTransitionEffect
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
              
              // Page turn from right to left
              float turnLine = 1.0 - progress * 1.2;
              
              if (fragTexCoord.x > turnLine) {
                  // Create slight curve for the page
                  float curve = sin((fragTexCoord.x - turnLine) * 10.0) * 0.02;
                  vec2 turnCoord = vec2(2.0 * turnLine - fragTexCoord.x, fragTexCoord.y + curve);
                  
                  if (turnCoord.x >= 0.0 && turnCoord.x <= 1.0) {
                      color = texture(texture0, turnCoord);
                      // Add shadow effect
                      float shadow = 1.0 - (fragTexCoord.x - turnLine) * 2.0;
                      color.rgb *= max(0.3, shadow);
                  } else {
                      color = vec4(0.0, 0.0, 0.0, 1.0);
                  }
              }
              
              finalColor = color;
          }
          SHADER
        end
      end

      # Glass shatter effect
      class ShatterEffect < BaseTransitionEffect
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

          float random(vec2 st) {
              return fract(sin(dot(st.xy, vec2(12.9898,78.233))) * 43758.5453123);
          }

          void main()
          {
              vec2 tc = fragTexCoord;
              
              // Create shatter pattern
              vec2 shatterCell = floor(tc * 20.0);
              float shatterTime = random(shatterCell);
              
              if (progress > shatterTime) {
                  // Offset broken pieces
                  float offsetAmount = (random(shatterCell + vec2(1.0, 0.0)) - 0.5) * progress * 0.2;
                  vec2 offset = vec2(offsetAmount, offsetAmount * 0.5);
                  tc += offset;
                  
                  // Add cracks (dark lines)
                  vec2 cellEdge = fract(tc * 20.0);
                  float crack = min(
                      min(cellEdge.x, 1.0 - cellEdge.x),
                      min(cellEdge.y, 1.0 - cellEdge.y)
                  );
                  crack = 1.0 - smoothstep(0.0, 0.05, crack);
                  
                  vec4 color = texture(texture0, tc);
                  color.rgb *= (1.0 - crack * 0.8);
                  
                  float alpha = 1.0 - smoothstep(shatterTime, shatterTime + 0.3, progress);
                  finalColor = vec4(color.rgb, color.a * alpha);
              } else {
                  finalColor = texture(texture0, tc);
              }
          }
          SHADER
        end
      end

      # Spiral vortex effect
      class VortexEffect < BaseTransitionEffect
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
              
              // Create vortex spiral
              float vortex = progress * 15.0 * (1.0 - dist);
              angle += vortex;
              
              // Scale inward as progress increases
              float scale = 1.0 - progress * 0.8;
              tc = tc * scale;
              
              vec2 vortexCoord = center + dist * vec2(cos(angle), sin(angle)) * scale;
              
              if (vortexCoord.x < 0.0 || vortexCoord.x > 1.0 || vortexCoord.y < 0.0 || vortexCoord.y > 1.0) {
                  finalColor = vec4(0.0, 0.0, 0.0, 1.0);
              } else {
                  vec4 color = texture(texture0, vortexCoord);
                  float alpha = 1.0 - smoothstep(0.7, 1.0, progress);
                  finalColor = vec4(color.rgb, color.a * alpha);
              }
          }
          SHADER
        end
      end

      # Fire transition effect
      class FireEffect < BaseTransitionEffect
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
              return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
          }

          void main()
          {
              vec4 color = texture(texture0, fragTexCoord);
              
              // Create fire pattern rising from bottom
              float fireNoise = noise(fragTexCoord * 10.0 + vec2(0.0, time * 2.0));
              fireNoise += noise(fragTexCoord * 20.0 + vec2(0.0, time * 4.0)) * 0.5;
              
              float fireHeight = progress + fireNoise * 0.2;
              float burnLine = 1.0 - fireHeight;
              
              if (fragTexCoord.y > burnLine) {
                  // Fire colors
                  float flame = smoothstep(burnLine, burnLine + 0.1, fragTexCoord.y);
                  vec3 fireColor = mix(
                      vec3(1.0, 0.8, 0.0),  // Yellow
                      vec3(1.0, 0.2, 0.0),  // Red
                      flame
                  );
                  finalColor = vec4(fireColor, 1.0);
              } else {
                  finalColor = color;
              }
          }
          SHADER
        end
      end
    end
  end
end
