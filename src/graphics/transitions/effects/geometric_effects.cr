# Geometric transition effects - iris, star, heart wipes, checkerboard

require "../transition_effect"
require "../shader_loader"

module PointClickEngine
  module Graphics
    module Transitions
      # Iris wipe transition effect (circle closing)
      class IrisEffect < BaseTransitionEffect
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
              float dist = distance(fragTexCoord, center);
              float radius = 0.7 * (1.0 - progress);
              float alpha = step(dist, radius);
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Star wipe transition effect
      class StarWipeEffect < BaseTransitionEffect
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

          float star(vec2 p, float r, float n) {
              float an = 3.141593/n;
              float en = 3.141593/n;
              vec2 acs = vec2(cos(an),sin(an));
              vec2 ecs = vec2(cos(en),sin(en));
              float bn = mod(atan(p.x,p.y),2.0*an) - an;
              p = length(p)*vec2(cos(bn),abs(sin(bn)));
              p -= r*acs;
              p += ecs*clamp(-dot(p,ecs), 0.0, r*acs.y/ecs.y);
              return length(p)*sign(p.x);
          }

          void main()
          {
              vec4 color = texture(texture0, fragTexCoord);
              vec2 center = fragTexCoord - vec2(0.5, 0.5);
              float starDist = star(center, 0.3, 5.0);
              float threshold = (progress - 0.5) * 0.8;
              float alpha = step(threshold, starDist);
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Heart wipe transition effect
      class HeartWipeEffect < BaseTransitionEffect
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

          float heart(vec2 p) {
              p.x = abs(p.x);
              if(p.y + p.x > 1.0)
                  return sqrt(dot2(p-vec2(0.25,0.75))) - sqrt(2.0)/4.0;
              return sqrt(min(dot2(p-vec2(0.00,1.00)),
                              dot2(p-0.5*max(p.x+p.y,0.0)))) * sign(p.x-p.y);
          }

          float dot2(vec2 v) { return dot(v,v); }

          void main()
          {
              vec4 color = texture(texture0, fragTexCoord);
              vec2 center = (fragTexCoord - vec2(0.5, 0.5)) * 2.0;
              center.y = -center.y; // Flip Y for proper heart orientation
              float heartDist = heart(center);
              float threshold = (progress - 0.5) * 1.5;
              float alpha = step(threshold, heartDist);
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Checkerboard wipe transition effect
      class CheckerboardEffect < BaseTransitionEffect
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
              
              // Create checkerboard pattern
              vec2 checker = floor(fragTexCoord * 8.0);
              float checkerPattern = mod(checker.x + checker.y, 2.0);
              
              // Different timing for each checker square
              float timing = checkerPattern * 0.5 + 0.5;
              float alpha = step(progress, timing);
              
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Pixelate transition effect
      class PixelateEffect < BaseTransitionEffect
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
              float pixelSize = 1.0 + progress * 50.0;
              vec2 pixelCoord = floor(fragTexCoord * pixelSize) / pixelSize;
              vec4 color = texture(texture0, pixelCoord);
              float alpha = 1.0 - progress;
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end
    end
  end
end
