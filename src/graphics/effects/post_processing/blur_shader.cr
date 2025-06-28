# Advanced blur effects using shaders
#
# Implements various blur algorithms for post-processing:
# - Gaussian blur (high quality)
# - Box blur (fast)
# - Motion blur (directional)
# - Radial blur (zoom/spin)

require "../shader_effect"
require "../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module PostProcessing
        # Blur types
        enum BlurType
          Gaussian  # High quality smooth blur
          Box       # Fast simple blur
          Motion    # Directional motion blur
          Radial    # Zoom/spin blur from center
        end
        
        # Shader-based blur effect
        class BlurShader < ShaderEffect
          property blur_type : BlurType = BlurType::Gaussian
          property blur_radius : Float32 = 5.0f32
          property blur_quality : Int32 = 4  # Number of samples
          property motion_angle : Float32 = 0.0f32  # For motion blur
          property motion_strength : Float32 = 0.02f32
          property radial_center : RL::Vector2 = RL::Vector2.new(x: 0.5f32, y: 0.5f32)
          property radial_zoom : Bool = true  # true = zoom blur, false = spin blur
          
          # Two-pass blur requires intermediate texture
          @horizontal_texture : RL::RenderTexture2D?
          
          def initialize(@blur_type : BlurType = BlurType::Gaussian,
                         @blur_radius : Float32 = 5.0f32,
                         duration : Float32 = 0.0f32)
            super(duration)
            
            @render_texture = RL.load_render_texture(Display::REFERENCE_WIDTH, Display::REFERENCE_HEIGHT)
            @horizontal_texture = RL.load_render_texture(Display::REFERENCE_WIDTH, Display::REFERENCE_HEIGHT)
          end
          
          def vertex_shader_source : String
            default_vertex_shader
          end
          
          def fragment_shader_source : String
            <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            uniform float time;
            uniform int blurType;
            uniform float blurRadius;
            uniform int blurQuality;
            uniform float motionAngle;
            uniform float motionStrength;
            uniform vec2 radialCenter;
            uniform int radialZoom;
            uniform vec2 resolution;
            uniform int passDirection; // 0 = horizontal, 1 = vertical
            
            #{ShaderLibrary.noise_functions}
            
            // Gaussian weight calculation
            float gaussian(float x, float sigma) {
                return exp(-(x * x) / (2.0 * sigma * sigma));
            }
            
            // Box blur
            vec4 boxBlur(vec2 uv) {
                vec4 color = vec4(0.0);
                float total = 0.0;
                
                float radius = blurRadius;
                int samples = blurQuality * 2 + 1;
                
                for (int i = -blurQuality; i <= blurQuality; i++) {
                    vec2 offset;
                    if (passDirection == 0) {
                        offset = vec2(float(i) * radius / resolution.x, 0.0);
                    } else {
                        offset = vec2(0.0, float(i) * radius / resolution.y);
                    }
                    
                    color += texture(texture0, uv + offset);
                    total += 1.0;
                }
                
                return color / total;
            }
            
            // Gaussian blur
            vec4 gaussianBlur(vec2 uv) {
                vec4 color = vec4(0.0);
                float total = 0.0;
                
                float sigma = blurRadius / 3.0;
                
                for (int i = -blurQuality; i <= blurQuality; i++) {
                    float weight = gaussian(float(i), sigma);
                    vec2 offset;
                    
                    if (passDirection == 0) {
                        offset = vec2(float(i) * blurRadius / resolution.x, 0.0);
                    } else {
                        offset = vec2(0.0, float(i) * blurRadius / resolution.y);
                    }
                    
                    color += texture(texture0, uv + offset) * weight;
                    total += weight;
                }
                
                return color / total;
            }
            
            // Motion blur
            vec4 motionBlur(vec2 uv) {
                vec4 color = vec4(0.0);
                vec2 velocity = vec2(cos(motionAngle), sin(motionAngle)) * motionStrength;
                
                int samples = blurQuality * 4;
                for (int i = 0; i < samples; i++) {
                    float t = float(i) / float(samples - 1) - 0.5;
                    vec2 offset = velocity * t;
                    color += texture(texture0, uv + offset);
                }
                
                return color / float(samples);
            }
            
            // Radial blur
            vec4 radialBlur(vec2 uv) {
                vec4 color = vec4(0.0);
                vec2 toCenter = radialCenter - uv;
                
                int samples = blurQuality * 4;
                for (int i = 0; i < samples; i++) {
                    float scale = 1.0 - blurRadius * float(i) / float(samples) * 0.1;
                    vec2 sampleUV;
                    
                    if (radialZoom != 0) {
                        // Zoom blur
                        sampleUV = radialCenter + toCenter * scale;
                    } else {
                        // Spin blur
                        float angle = blurRadius * float(i) / float(samples) * 0.1;
                        float cosA = cos(angle);
                        float sinA = sin(angle);
                        vec2 rotated = vec2(
                            toCenter.x * cosA - toCenter.y * sinA,
                            toCenter.x * sinA + toCenter.y * cosA
                        );
                        sampleUV = radialCenter - rotated;
                    }
                    
                    color += texture(texture0, sampleUV);
                }
                
                return color / float(samples);
            }
            
            void main()
            {
                vec4 result;
                
                switch(blurType) {
                    case 0: // Gaussian
                        result = gaussianBlur(fragTexCoord);
                        break;
                    case 1: // Box
                        result = boxBlur(fragTexCoord);
                        break;
                    case 2: // Motion
                        result = motionBlur(fragTexCoord);
                        break;
                    case 3: // Radial
                        result = radialBlur(fragTexCoord);
                        break;
                    default:
                        result = texture(texture0, fragTexCoord);
                }
                
                finalColor = result * fragColor;
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            context.active_shader = shader
          end
          
          def render_scene_with_blur(&block : -> Nil)
            return yield unless shader = @shader
            return yield unless render_texture = @render_texture
            
            # Render scene to texture
            RL.begin_texture_mode(render_texture)
            RL.clear_background(RL::BLANK)
            yield
            RL.end_texture_mode
            
            # For separable blurs (Gaussian, Box), do two passes
            if @blur_type.gaussian? || @blur_type.box?
              return yield unless horizontal_texture = @horizontal_texture
              
              # First pass - horizontal
              RL.begin_texture_mode(horizontal_texture)
              RL.clear_background(RL::BLANK)
              
              RL.begin_shader_mode(shader)
              update_blur_uniforms(shader, 0)  # Horizontal pass
              
              RL.draw_texture_rec(
                render_texture.texture,
                RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
                RL::Vector2.new(x: 0, y: 0),
                RL::WHITE
              )
              
              RL.end_shader_mode
              RL.end_texture_mode
              
              # Second pass - vertical, draw to screen
              RL.begin_shader_mode(shader)
              update_blur_uniforms(shader, 1)  # Vertical pass
              
              RL.draw_texture_rec(
                horizontal_texture.texture,
                RL::Rectangle.new(x: 0, y: 0, width: horizontal_texture.texture.width.to_f32, height: -horizontal_texture.texture.height.to_f32),
                RL::Vector2.new(x: 0, y: 0),
                RL::WHITE
              )
              
              RL.end_shader_mode
            else
              # Single pass for motion and radial blur
              RL.begin_shader_mode(shader)
              update_blur_uniforms(shader, -1)  # No pass direction
              
              RL.draw_texture_rec(
                render_texture.texture,
                RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
                RL::Vector2.new(x: 0, y: 0),
                RL::WHITE
              )
              
              RL.end_shader_mode
            end
          end
          
          private def update_blur_uniforms(shader : RL::Shader, pass_direction : Int32)
            update_common_uniforms(shader)
            set_shader_value("blurType", @blur_type.value.to_f32)
            set_shader_value("blurRadius", @blur_radius)
            set_shader_value("blurQuality", @blur_quality.to_f32)
            set_shader_value("motionAngle", @motion_angle)
            set_shader_value("motionStrength", @motion_strength)
            set_shader_value("radialCenter", @radial_center)
            set_shader_value("radialZoom", @radial_zoom ? 1.0f32 : 0.0f32)
            set_shader_value("passDirection", pass_direction.to_f32)
          end
          
          def clone : Effect
            effect = BlurShader.new(@blur_type, @blur_radius, @duration)
            effect.blur_quality = @blur_quality
            effect.motion_angle = @motion_angle
            effect.motion_strength = @motion_strength
            effect.radial_center = @radial_center
            effect.radial_zoom = @radial_zoom
            effect
          end
        end
      end
    end
  end
end