# Basic transition effects - fade, dissolve, cross-fade, slides

require "../transition_effect"
require "../shader_loader"

module PointClickEngine
  module Graphics
    module Transitions
      # Fade transition effect
      class FadeEffect < BaseTransitionEffect
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
              finalColor = vec4(color.rgb, color.a * (1.0 - progress));
          }
          SHADER
        end
      end

      # Dissolve transition effect
      class DissolveEffect < BaseTransitionEffect
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
              vec4 color = texture(texture0, fragTexCoord);
              float noise = random(fragTexCoord);
              float alpha = step(progress, noise);
              finalColor = vec4(color.rgb, color.a * alpha);
          }
          SHADER
        end
      end

      # Cross-fade transition effect
      class CrossFadeEffect < BaseTransitionEffect
        property second_texture : RL::Texture2D?

        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)

          if texture = @second_texture
            ShaderLoader.set_shader_texture_uniform(shader, "texture1", texture, 1)
          end
        end

        def fragment_shader_source : String
          <<-SHADER
          #version 330 core
          in vec2 fragTexCoord;
          in vec4 fragColor;
          out vec4 finalColor;

          uniform sampler2D texture0;
          uniform sampler2D texture1;
          uniform float progress;

          void main()
          {
              vec4 color1 = texture(texture0, fragTexCoord);
              vec4 color2 = texture(texture1, fragTexCoord);
              finalColor = mix(color1, color2, progress);
          }
          SHADER
        end
      end

      # Slide transition effect
      class SlideEffect < BaseTransitionEffect
        property direction : SlideDirection

        def initialize(duration : Float32, @direction : SlideDirection)
          super(duration)
        end

        def load_shader : RL::Shader?
          @shader = ShaderLoader.create_basic_shader(fragment_shader_source)
        end

        def update_shader_params(progress : Float32)
          return unless shader = @shader
          ShaderLoader.set_progress(shader, progress)

          # Set direction vector based on slide direction
          dir_vector = case @direction
                       when .left?  then RL::Vector2.new(x: -1.0f32, y: 0.0f32)
                       when .right? then RL::Vector2.new(x: 1.0f32, y: 0.0f32)
                       when .up?    then RL::Vector2.new(x: 0.0f32, y: -1.0f32)
                       when .down?  then RL::Vector2.new(x: 0.0f32, y: 1.0f32)
                       else              RL::Vector2.new(x: 0.0f32, y: 0.0f32)
                       end

          ShaderLoader.set_direction(shader, dir_vector)
        end

        def fragment_shader_source : String
          <<-SHADER
          #version 330 core
          in vec2 fragTexCoord;
          in vec4 fragColor;
          out vec4 finalColor;

          uniform sampler2D texture0;
          uniform float progress;
          uniform vec2 direction;

          void main()
          {
              vec2 offset = direction * progress;
              vec2 newCoord = fragTexCoord + offset;
              
              if (newCoord.x < 0.0 || newCoord.x > 1.0 || newCoord.y < 0.0 || newCoord.y > 1.0) {
                  finalColor = vec4(0.0, 0.0, 0.0, 1.0);
              } else {
                  vec4 color = texture(texture0, newCoord);
                  finalColor = color;
              }
          }
          SHADER
        end
      end
    end
  end
end
