# Shader-based fog effect for scenes
#
# Creates atmospheric fog with distance-based density, color gradients,
# and support for multiple fog layers.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Fog types
        enum FogType
          Linear      # Linear distance fog
          Exponential # Exponential density fog
          Layered     # Multiple fog layers
          Volumetric  # Volumetric fog with noise
        end
        
        # Shader-based fog effect
        class FogShader < ShaderEffect
          property fog_type : FogType = FogType::Linear
          property fog_color : RL::Color = RL::Color.new(r: 128, g: 128, b: 150, a: 200)
          property fog_density : Float32 = 0.02f32
          property fog_start : Float32 = 100.0f32
          property fog_end : Float32 = 500.0f32
          property height_falloff : Float32 = 0.5f32  # For layered fog
          
          def initialize(@fog_type : FogType = FogType::Linear,
                         @fog_color : RL::Color = RL::Color.new(r: 128, g: 128, b: 150, a: 200),
                         @fog_density : Float32 = 0.02f32,
                         duration : Float32 = 0.0f32)
            super(duration)
            
            # Scene effects need a fullscreen render texture
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
            uniform sampler2D depthTexture;  // If depth is available
            uniform float time;
            uniform int fogType;
            uniform vec4 fogColor;
            uniform float fogDensity;
            uniform float fogStart;
            uniform float fogEnd;
            uniform float heightFalloff;
            uniform vec2 resolution;
            
            #{ShaderLibrary.noise_functions}
            #{ShaderLibrary.easing_functions}
            
            float getLinearFog(float distance) {
                return clamp((distance - fogStart) / (fogEnd - fogStart), 0.0, 1.0);
            }
            
            float getExponentialFog(float distance) {
                return 1.0 - exp(-fogDensity * distance);
            }
            
            float getExponentialSquaredFog(float distance) {
                float d = fogDensity * distance;
                return 1.0 - exp(-d * d);
            }
            
            float getLayeredFog(vec2 uv, float distance) {
                // Height-based fog that's denser at the bottom
                float height = 1.0 - uv.y;
                float heightFactor = pow(height, heightFalloff);
                
                // Combine with distance fog
                float distFog = getExponentialFog(distance);
                return distFog * heightFactor;
            }
            
            float getVolumetricFog(vec2 uv, float distance) {
                // Add noise for volumetric appearance
                vec2 noiseCoord = uv * 3.0 + vec2(time * 0.02, 0.0);
                float noise1 = noise(noiseCoord) * 0.5 + 0.5;
                float noise2 = noise(noiseCoord * 2.0 + 10.0) * 0.3;
                
                float baseFog = getExponentialFog(distance);
                float volumetric = baseFog * (0.7 + noise1 * 0.3 + noise2);
                
                return clamp(volumetric, 0.0, 1.0);
            }
            
            void main()
            {
                vec4 sceneColor = texture(texture0, fragTexCoord);
                
                // Simulate distance based on vertical position (further away = higher up)
                float distance = (1.0 - fragTexCoord.y) * 500.0;
                
                // Add some horizontal variation
                distance += sin(fragTexCoord.x * 10.0) * 20.0;
                
                float fogFactor = 0.0;
                
                switch(fogType) {
                    case 0: // Linear
                        fogFactor = getLinearFog(distance);
                        break;
                        
                    case 1: // Exponential
                        fogFactor = getExponentialFog(distance);
                        break;
                        
                    case 2: // Layered
                        fogFactor = getLayeredFog(fragTexCoord, distance);
                        break;
                        
                    case 3: // Volumetric
                        fogFactor = getVolumetricFog(fragTexCoord, distance);
                        break;
                }
                
                // Apply fog
                vec3 finalRGB = mix(sceneColor.rgb, fogColor.rgb, fogFactor * fogColor.a);
                
                finalColor = vec4(finalRGB, sceneColor.a);
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            
            # Store shader for scene rendering
            context.active_shader = shader
          end
          
          def render_scene_with_fog(&block : -> Nil)
            return yield unless shader = @shader
            return yield unless render_texture = @render_texture
            
            # Render scene to texture
            RL.begin_texture_mode(render_texture)
            RL.clear_background(RL::BLANK)
            yield
            RL.end_texture_mode
            
            # Apply fog shader
            RL.begin_shader_mode(shader)
            
            # Update uniforms
            update_common_uniforms(shader)
            set_shader_value("fogType", @fog_type.value.to_f32)
            set_shader_value("fogColor", @fog_color)
            set_shader_value("fogDensity", @fog_density)
            set_shader_value("fogStart", @fog_start)
            set_shader_value("fogEnd", @fog_end)
            set_shader_value("heightFalloff", @height_falloff)
            
            # Draw the scene with fog
            RL.draw_texture_rec(
              render_texture.texture,
              RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
              RL::Vector2.new(x: 0, y: 0),
              RL::WHITE
            )
            
            RL.end_shader_mode
          end
          
          def clone : Effect
            effect = FogShader.new(@fog_type, @fog_color, @fog_density, @duration)
            effect.fog_start = @fog_start
            effect.fog_end = @fog_end
            effect.height_falloff = @height_falloff
            effect
          end
        end
      end
    end
  end
end