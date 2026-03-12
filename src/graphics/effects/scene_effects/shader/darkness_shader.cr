# Shader-based darkness effect for scenes
#
# Creates vignette, darkness overlays, and light source support
# for atmospheric lighting and mood effects.

require "../shader_scene_effect"
require "../../shader_library"
module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Darkness types
        enum DarknessType
          Vignette    # Edge darkening
          Gradient    # Top-down or directional gradient
          Spotlight   # Circular light area
          MultiLight  # Multiple light sources
        end
        
        # Light source for multi-light mode
        class ShaderLightSource
          property position : RL::Vector2
          property radius : Float32
          property intensity : Float32
          property color : RL::Color
          
          def initialize(@position, @radius = 100.0f32, @intensity = 1.0f32, @color = RL::WHITE)
          end
        end
        
        # Shader-based darkness effect
        class DarknessShader < ShaderSceneEffect
          property darkness_type : DarknessType = DarknessType::Vignette
          property darkness_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 200)
          property darkness_intensity : Float32 = 0.8f32
          property inner_radius : Float32 = 0.5f32  # For vignette
          property outer_radius : Float32 = 1.2f32  # For vignette
          property gradient_angle : Float32 = 0.0f32  # For gradient
          property light_sources : Array(ShaderLightSource) = [] of ShaderLightSource
          
          # Maximum lights the shader can handle
          MAX_LIGHTS = 8
          
          def initialize(@darkness_type : DarknessType = DarknessType::Vignette,
                         @darkness_intensity : Float32 = 0.8f32,
                         duration : Float32 = 0.0f32)
            super(duration)
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
            uniform float darknessType;
            uniform vec4 darknessColor;
            uniform float intensity;
            uniform float innerRadius;
            uniform float outerRadius;
            uniform float gradientAngle;
            uniform vec2 resolution;
            
            // Light sources
            uniform float numLights;
            uniform vec2 lightPositions[#{MAX_LIGHTS}];
            uniform float lightRadii[#{MAX_LIGHTS}];
            uniform float lightIntensities[#{MAX_LIGHTS}];
            uniform vec4 lightColors[#{MAX_LIGHTS}];
            
            #{ShaderLibrary.easing_functions}
            #{ShaderLibrary.noise_functions}
            
            float getVignette(vec2 uv) {
                vec2 center = vec2(0.5, 0.5);
                float dist = distance(uv, center);
                return smoothstep(innerRadius, outerRadius, dist);
            }
            
            float getGradient(vec2 uv) {
                // Rotate UV based on angle
                float s = sin(gradientAngle);
                float c = cos(gradientAngle);
                vec2 rotatedUV = vec2(
                    uv.x * c - uv.y * s,
                    uv.x * s + uv.y * c
                );
                
                // Create gradient
                return smoothstep(0.3, 0.7, rotatedUV.y);
            }
            
            float getSpotlight(vec2 uv) {
                vec2 center = vec2(0.5, 0.5);
                float dist = distance(uv, center);
                return smoothstep(innerRadius, outerRadius, dist);
            }
            
            vec4 getMultiLight(vec2 uv) {
                vec4 lightAccum = vec4(0.0);
                
                int lightCount = int(numLights);
                for (int i = 0; i < lightCount && i < #{MAX_LIGHTS}; i++) {
                    vec2 lightUV = lightPositions[i] / resolution;
                    float dist = distance(uv, lightUV);
                    float radius = lightRadii[i] / resolution.x;
                    
                    float attenuation = 1.0 - smoothstep(0.0, radius, dist);
                    attenuation = pow(attenuation, 2.0) * lightIntensities[i];
                    
                    lightAccum += lightColors[i] * attenuation;
                }
                
                // Invert to create darkness
                return vec4(1.0) - clamp(lightAccum, 0.0, 1.0);
            }
            
            void main()
            {
                vec4 sceneColor = texture(texture0, fragTexCoord);
                float darknessFactor = 0.0;
                vec3 lightContribution = vec3(0.0);

                int dType = int(darknessType);

                if (dType == 0) {
                    // Vignette - darken edges
                    darknessFactor = getVignette(fragTexCoord);
                } else if (dType == 1) {
                    // Gradient - directional darkness
                    darknessFactor = getGradient(fragTexCoord);
                } else if (dType == 2) {
                    // Spotlight - circular light area
                    darknessFactor = getSpotlight(fragTexCoord);
                } else if (dType == 3) {
                    // MultiLight - multiple light sources
                    vec4 multiLightDarkness = getMultiLight(fragTexCoord);
                    darknessFactor = multiLightDarkness.r;
                    lightContribution = (vec4(1.0) - multiLightDarkness).rgb * 0.3;
                }

                // Apply darkness with intensity control
                darknessFactor = clamp(darknessFactor * intensity, 0.0, 1.0);

                // Blend scene with darkness color
                vec3 finalRGB = mix(sceneColor.rgb, darknessColor.rgb, darknessFactor);

                // Add light contribution for multi-light mode
                finalRGB += lightContribution;

                finalColor = vec4(finalRGB, sceneColor.a);
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            context.active_shader = shader
          end
          
          def add_light(position : RL::Vector2, radius : Float32 = 100.0f32, 
                       intensity : Float32 = 1.0f32, color : RL::Color = RL::WHITE)
            if @light_sources.size < MAX_LIGHTS
              @light_sources << ShaderLightSource.new(position, radius, intensity, color)
            end
          end
          
          def clear_lights
            @light_sources.clear
          end
          
          protected def update_effect_uniforms(shader : RL::Shader, logical_width : Int32, logical_height : Int32)
            set_shader_value("darknessType", @darkness_type.value.to_f32)
            set_shader_value("darknessColor", @darkness_color)
            set_shader_value("intensity", @darkness_intensity)
            set_shader_value("innerRadius", @inner_radius)
            set_shader_value("outerRadius", @outer_radius)
            set_shader_value("gradientAngle", @gradient_angle)
            set_shader_value("resolution", RL::Vector2.new(
              x: logical_width.to_f32,
              y: logical_height.to_f32
            ))
            
            # Set light sources for multi-light mode
            if @darkness_type.multi_light?
              set_shader_value("numLights", @light_sources.size.to_f32)
              
              # Set light arrays
              @light_sources.each_with_index do |light, i|
                break if i >= MAX_LIGHTS
                
                loc = RL.get_shader_location(shader, "lightPositions[#{i}]")
                light_position = light.position
                RL.set_shader_value(shader, loc, pointerof(light_position), RL::ShaderUniformDataType::Vec2)
                
                loc = RL.get_shader_location(shader, "lightRadii[#{i}]")
                light_radius = light.radius
                RL.set_shader_value(shader, loc, pointerof(light_radius), RL::ShaderUniformDataType::Float)
                
                loc = RL.get_shader_location(shader, "lightIntensities[#{i}]")
                light_intensity = light.intensity
                RL.set_shader_value(shader, loc, pointerof(light_intensity), RL::ShaderUniformDataType::Float)
                
                loc = RL.get_shader_location(shader, "lightColors[#{i}]")
                color_vec = RL::Vector4.new(
                  x: light.color.r / 255.0f32,
                  y: light.color.g / 255.0f32,
                  z: light.color.b / 255.0f32,
                  w: light.color.a / 255.0f32
                )
                RL.set_shader_value(shader, loc, pointerof(color_vec), RL::ShaderUniformDataType::Vec4)
              end
            end
          end
          
          def clone : Effect
            effect = DarknessShader.new(@darkness_type, @darkness_intensity, @duration)
            effect.darkness_color = @darkness_color
            effect.inner_radius = @inner_radius
            effect.outer_radius = @outer_radius
            effect.gradient_angle = @gradient_angle
            effect.light_sources = @light_sources.dup
            effect
          end
          
        end
      end
    end
  end
end
