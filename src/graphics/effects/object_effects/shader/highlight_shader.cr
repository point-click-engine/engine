# Shader-based highlight effect for objects
#
# Creates outline, glow, and rim light effects using shader techniques
# for highlighting interactive objects or important elements.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Highlight styles
        enum HighlightStyle
          Outline     # Solid outline around object
          Glow        # Soft glow effect
          RimLight    # Rim lighting effect
          Pulse       # Pulsing outline
          Rainbow     # Rainbow colored outline
        end
        
        # Shader-based highlight effect
        class HighlightShader < ShaderEffect
          property style : HighlightStyle = HighlightStyle::Outline
          property color : RL::Color = RL::Color.new(r: 255, g: 255, b: 0, a: 255)  # Yellow
          property thickness : Float32 = 2.0f32
          property glow_intensity : Float32 = 2.0f32
          property pulse_speed : Float32 = 2.0f32
          
          def initialize(@style : HighlightStyle = HighlightStyle::Outline,
                         @color : RL::Color = RL::Color.new(r: 255, g: 255, b: 0, a: 255),
                         @thickness : Float32 = 2.0f32,
                         duration : Float32 = 0.0f32)
            super(duration)
            
            # Need render texture for outline detection
            @render_texture = RL.load_render_texture(256, 256)  # Reasonable size for sprites
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
            uniform int highlightStyle;
            uniform vec4 highlightColor;
            uniform float thickness;
            uniform float glowIntensity;
            uniform float pulseSpeed;
            uniform vec2 textureSize;
            
            #{ShaderLibrary.color_functions}
            #{ShaderLibrary.easing_functions}
            
            float getAlphaSample(vec2 uv) {
                if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
                    return 0.0;
                }
                return texture(texture0, uv).a;
            }
            
            float getOutlineAlpha(vec2 uv, float thick) {
                vec2 texelSize = 1.0 / textureSize;
                float alpha = 0.0;
                
                // Sample surrounding pixels
                for (float x = -thick; x <= thick; x += 1.0) {
                    for (float y = -thick; y <= thick; y += 1.0) {
                        if (x * x + y * y <= thick * thick) {
                            alpha = max(alpha, getAlphaSample(uv + vec2(x, y) * texelSize));
                        }
                    }
                }
                
                return alpha;
            }
            
            void main()
            {
                vec4 texColor = texture(texture0, fragTexCoord);
                vec4 outColor = texColor;
                
                switch(highlightStyle) {
                    case 0: // Outline
                        if (texColor.a < 0.5) {
                            float outline = getOutlineAlpha(fragTexCoord, thickness);
                            if (outline > 0.5) {
                                outColor = highlightColor;
                                outColor.a = outline;
                            }
                        }
                        break;
                        
                    case 1: // Glow
                        if (texColor.a < 0.5) {
                            float maxDist = thickness * 3.0;
                            float glow = 0.0;
                            
                            vec2 texelSize = 1.0 / textureSize;
                            for (float d = 1.0; d <= maxDist; d += 1.0) {
                                float outline = getOutlineAlpha(fragTexCoord, d);
                                if (outline > 0.5) {
                                    glow = 1.0 - (d / maxDist);
                                    break;
                                }
                            }
                            
                            if (glow > 0.0) {
                                glow = pow(glow, 1.0 / glowIntensity);
                                outColor = highlightColor;
                                outColor.a = glow * highlightColor.a;
                            }
                        }
                        break;
                        
                    case 2: // RimLight
                        if (texColor.a > 0.5) {
                            // Check if pixel is on edge
                            float edgeAlpha = 1.0 - getOutlineAlpha(fragTexCoord, 1.0);
                            if (edgeAlpha < 0.9) {
                                vec3 mixed = mix(texColor.rgb, highlightColor.rgb, 0.5);
                                outColor.rgb = mixed * glowIntensity;
                            }
                        }
                        break;
                        
                    case 3: // Pulse
                        if (texColor.a < 0.5) {
                            float outline = getOutlineAlpha(fragTexCoord, thickness);
                            if (outline > 0.5) {
                                float pulse = sin(time * pulseSpeed) * 0.5 + 0.5;
                                outColor = highlightColor;
                                outColor.a = outline * pulse;
                            }
                        }
                        break;
                        
                    case 4: // Rainbow
                        if (texColor.a < 0.5) {
                            float outline = getOutlineAlpha(fragTexCoord, thickness);
                            if (outline > 0.5) {
                                vec3 rainbow = hsv2rgb(vec3(mod(time * 0.2 + fragTexCoord.x, 1.0), 1.0, 1.0));
                                outColor = vec4(rainbow, outline);
                            }
                        }
                        break;
                }
                
                // Apply fragColor
                outColor *= fragColor;
                
                finalColor = outColor;
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            return unless sprite = context.sprite
            
            # Begin shader mode
            RL.begin_shader_mode(shader)
            
            # Update shader uniforms
            update_common_uniforms(shader)
            
            # Set specific uniforms
            set_shader_value("highlightStyle", @style.value.to_f32)
            set_shader_value("highlightColor", @color)
            set_shader_value("thickness", @thickness)
            set_shader_value("glowIntensity", @glow_intensity)
            set_shader_value("pulseSpeed", @pulse_speed)
            
            # Set texture size (assuming sprite has bounds)
            if bounds = sprite.bounds
              texture_size = RL::Vector2.new(x: bounds.width, y: bounds.height)
              set_shader_value("textureSize", texture_size)
            end
            
            # Store shader in context
            context.active_shader = shader
          end
          
          def clone : Effect
            effect = HighlightShader.new(@style, @color, @thickness, @duration)
            effect.glow_intensity = @glow_intensity
            effect.pulse_speed = @pulse_speed
            effect
          end
          
          # Helper factory methods
          def self.outline(color : RL::Color = RL::YELLOW, thickness : Float32 = 2.0f32)
            HighlightShader.new(HighlightStyle::Outline, color, thickness)
          end
          
          def self.glow(color : RL::Color = RL::WHITE, intensity : Float32 = 2.0f32)
            effect = HighlightShader.new(HighlightStyle::Glow, color, 3.0f32)
            effect.glow_intensity = intensity
            effect
          end
          
          def self.rim_light(color : RL::Color = RL::WHITE, intensity : Float32 = 1.5f32)
            effect = HighlightShader.new(HighlightStyle::RimLight, color, 1.0f32)
            effect.glow_intensity = intensity
            effect
          end
          
          def self.pulse(color : RL::Color = RL::RED, speed : Float32 = 2.0f32)
            effect = HighlightShader.new(HighlightStyle::Pulse, color, 2.0f32)
            effect.pulse_speed = speed
            effect
          end
          
          def self.rainbow(thickness : Float32 = 2.0f32)
            HighlightShader.new(HighlightStyle::Rainbow, RL::WHITE, thickness)
          end
        end
      end
    end
  end
end