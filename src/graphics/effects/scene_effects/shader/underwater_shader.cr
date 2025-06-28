# Shader-based underwater effect for scenes
#
# Creates underwater atmosphere with wave distortion, caustics,
# color tinting, and bubble particles.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Underwater quality levels
        enum UnderwaterQuality
          Low     # Basic tint and wave
          Medium  # Add caustics
          High    # Add bubbles and advanced effects
        end
        
        # Shader-based underwater effect
        class UnderwaterShader < ShaderEffect
          property quality : UnderwaterQuality = UnderwaterQuality::Medium
          property water_color : RL::Color = RL::Color.new(r: 0, g: 80, b: 120, a: 100)
          property wave_amplitude : Float32 = 0.01f32
          property wave_frequency : Float32 = 10.0f32
          property wave_speed : Float32 = 2.0f32
          property caustics_intensity : Float32 = 0.3f32
          property blur_amount : Float32 = 0.002f32
          property bubble_density : Float32 = 5.0f32
          
          def initialize(@quality : UnderwaterQuality = UnderwaterQuality::Medium,
                         @water_color : RL::Color = RL::Color.new(r: 0, g: 80, b: 120, a: 100),
                         duration : Float32 = 0.0f32)
            super(duration)
            
            @render_texture = RL.load_render_texture(Display::REFERENCE_WIDTH, Display::REFERENCE_HEIGHT)
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
            uniform int quality;
            uniform vec4 waterColor;
            uniform float waveAmplitude;
            uniform float waveFrequency;
            uniform float waveSpeed;
            uniform float causticsIntensity;
            uniform float blurAmount;
            uniform float bubbleDensity;
            
            #{ShaderLibrary.noise_functions}
            #{ShaderLibrary.distortion_functions}
            
            // Create caustics pattern
            float getCaustics(vec2 uv, float t) {
                vec2 p = uv * 5.0;
                
                float pattern1 = sin(p.x * 10.0 + t) * sin(p.y * 10.0 + t);
                float pattern2 = sin((p.x + p.y) * 5.0 - t * 0.5);
                float pattern3 = fbm(p + vec2(t * 0.1, 0.0), 2);
                
                float caustics = pattern1 * 0.3 + pattern2 * 0.3 + pattern3 * 0.4;
                caustics = smoothstep(-0.5, 0.5, caustics);
                
                return caustics;
            }
            
            // Create bubble effect
            float getBubble(vec2 uv, float seed) {
                // Bubble position
                float x = fract(sin(seed * 12.345) * 43758.5453);
                float speed = 0.5 + fract(seed * 1.337) * 0.5;
                float size = 0.005 + fract(seed * 7.89) * 0.01;
                
                vec2 bubblePos = vec2(x, fract(-time * speed + seed));
                
                // Add slight horizontal movement
                bubblePos.x += sin(time * 2.0 + seed * 10.0) * 0.02;
                
                float dist = distance(uv, bubblePos);
                
                // Bubble with highlight
                float bubble = smoothstep(size, size * 0.8, dist);
                float highlight = smoothstep(size * 0.5, size * 0.3, dist - size * 0.3);
                
                return bubble * 0.3 + highlight * 0.7;
            }
            
            // Apply chromatic aberration for underwater blur
            vec3 chromaticAberration(sampler2D tex, vec2 uv, float amount) {
                float r = texture(tex, uv + vec2(amount, 0.0)).r;
                float g = texture(tex, uv).g;
                float b = texture(tex, uv - vec2(amount, 0.0)).b;
                return vec3(r, g, b);
            }
            
            void main()
            {
                // Wave distortion
                vec2 waveOffset = vec2(
                    sin(fragTexCoord.y * waveFrequency + time * waveSpeed) * waveAmplitude,
                    cos(fragTexCoord.x * waveFrequency * 1.5 + time * waveSpeed * 0.8) * waveAmplitude * 0.5
                );
                
                vec2 distortedUV = fragTexCoord + waveOffset;
                
                // Sample scene with chromatic aberration
                vec3 sceneColor;
                if (quality >= 1) { // Medium and High
                    sceneColor = chromaticAberration(texture0, distortedUV, blurAmount);
                } else {
                    sceneColor = texture(texture0, distortedUV).rgb;
                }
                
                // Apply water tint
                sceneColor = mix(sceneColor, waterColor.rgb / 255.0, waterColor.a / 255.0);
                
                // Add caustics for Medium and High quality
                if (quality >= 1) {
                    float caustics = getCaustics(fragTexCoord, time);
                    sceneColor += caustics * causticsIntensity;
                }
                
                // Add bubbles for High quality
                if (quality >= 2) {
                    float bubbles = 0.0;
                    for (int i = 0; i < int(bubbleDensity); i++) {
                        bubbles += getBubble(fragTexCoord, float(i));
                    }
                    sceneColor = mix(sceneColor, vec3(1.0), bubbles * 0.5);
                }
                
                // Add depth fog
                float depthFog = 1.0 - fragTexCoord.y;
                depthFog = pow(depthFog, 2.0) * 0.3;
                sceneColor = mix(sceneColor, waterColor.rgb / 255.0, depthFog);
                
                // Reduce overall brightness underwater
                sceneColor *= 0.85;
                
                finalColor = vec4(sceneColor, 1.0);
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            context.active_shader = shader
          end
          
          def render_scene_underwater(&block : -> Nil)
            return yield unless shader = @shader
            return yield unless render_texture = @render_texture
            
            # Render scene to texture
            RL.begin_texture_mode(render_texture)
            RL.clear_background(RL::BLANK)
            yield
            RL.end_texture_mode
            
            # Apply underwater shader
            RL.begin_shader_mode(shader)
            
            # Update uniforms
            update_common_uniforms(shader)
            set_shader_value("quality", @quality.value.to_f32)
            set_shader_value("waterColor", @water_color)
            set_shader_value("waveAmplitude", @wave_amplitude)
            set_shader_value("waveFrequency", @wave_frequency)
            set_shader_value("waveSpeed", @wave_speed)
            set_shader_value("causticsIntensity", @caustics_intensity)
            set_shader_value("blurAmount", @blur_amount)
            set_shader_value("bubbleDensity", @bubble_density)
            
            # Draw the scene with underwater effect
            RL.draw_texture_rec(
              render_texture.texture,
              RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
              RL::Vector2.new(x: 0, y: 0),
              RL::WHITE
            )
            
            RL.end_shader_mode
          end
          
          def clone : Effect
            effect = UnderwaterShader.new(@quality, @water_color, @duration)
            effect.wave_amplitude = @wave_amplitude
            effect.wave_frequency = @wave_frequency
            effect.wave_speed = @wave_speed
            effect.caustics_intensity = @caustics_intensity
            effect.blur_amount = @blur_amount
            effect.bubble_density = @bubble_density
            effect
          end
        end
      end
    end
  end
end