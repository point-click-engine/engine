# Shader-based dissolve effect for objects
#
# Creates various dissolve patterns using noise and geometric shapes
# for smooth, visually appealing fade in/out effects.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Dissolve patterns
        enum DissolvePattern
          Noise      # Organic noise-based dissolve
          Circular   # Dissolve from center outward
          Linear     # Linear wipe (horizontal/vertical)
          Diamond    # Diamond-shaped dissolve
          Spiral     # Spiral pattern dissolve
        end
        
        # Dissolve direction modes
        enum DissolveMode
          In   # Fade in (appear)
          Out  # Fade out (disappear)
        end
        
        # Shader-based dissolve effect
        class DissolveShader < ShaderEffect
          property pattern : DissolvePattern = DissolvePattern::Noise
          property mode : DissolveMode = DissolveMode::Out
          property edge_color : RL::Color = RL::Color.new(r: 255, g: 200, b: 0, a: 255)  # Golden edge
          property edge_width : Float32 = 0.02f32
          property noise_scale : Float32 = 5.0f32
          
          def initialize(@pattern : DissolvePattern = DissolvePattern::Noise,
                         @mode : DissolveMode = DissolveMode::Out,
                         duration : Float32 = 1.0f32)
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
            uniform float progress;
            uniform int dissolvePattern;
            uniform int dissolveMode;
            uniform vec4 edgeColor;
            uniform float edgeWidth;
            uniform float noiseScale;
            
            #{ShaderLibrary.noise_functions}
            #{ShaderLibrary.shape_functions}
            #{ShaderLibrary.easing_functions}
            
            float getDissolveValue(vec2 uv) {
                float value = 0.0;
                
                switch(dissolvePattern) {
                    case 0: // Noise
                        value = fbm(uv * noiseScale, 4);
                        break;
                        
                    case 1: // Circular
                        vec2 center = vec2(0.5, 0.5);
                        value = 1.0 - length(uv - center) * 1.4142;
                        break;
                        
                    case 2: // Linear
                        value = uv.x;
                        break;
                        
                    case 3: // Diamond
                        vec2 center = vec2(0.5, 0.5);
                        vec2 d = abs(uv - center);
                        value = 1.0 - (d.x + d.y);
                        break;
                        
                    case 4: // Spiral
                        vec2 center = vec2(0.5, 0.5);
                        vec2 tc = uv - center;
                        float angle = atan(tc.y, tc.x);
                        float radius = length(tc);
                        value = mod(angle / (2.0 * 3.14159) + radius * 3.0, 1.0);
                        break;
                }
                
                return value;
            }
            
            void main()
            {
                vec4 texColor = texture(texture0, fragTexCoord);
                
                // Get dissolve value for this pixel
                float dissolveValue = getDissolveValue(fragTexCoord);
                
                // Adjust threshold based on mode
                float threshold = (dissolveMode == 0) ? 1.0 - progress : progress;
                
                // Apply easing
                threshold = easeInOutCubic(threshold);
                
                // Calculate alpha
                float alpha = texColor.a;
                
                if (dissolveValue < threshold - edgeWidth) {
                    // Fully dissolved
                    alpha = 0.0;
                } else if (dissolveValue < threshold) {
                    // Edge region
                    float edgeFactor = (dissolveValue - (threshold - edgeWidth)) / edgeWidth;
                    alpha *= edgeFactor;
                    
                    // Add edge glow color
                    vec3 color = mix(edgeColor.rgb, texColor.rgb, edgeFactor);
                    texColor.rgb = color;
                }
                // else: Fully visible
                
                // Apply fragColor
                texColor *= fragColor;
                
                finalColor = vec4(texColor.rgb, alpha);
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
            set_shader_value("dissolvePattern", @pattern.value.to_f32)
            set_shader_value("dissolveMode", @mode.value.to_f32)
            set_shader_value("edgeColor", @edge_color)
            set_shader_value("edgeWidth", @edge_width)
            set_shader_value("noiseScale", @noise_scale)
            
            # Store shader in context
            context.active_shader = shader
          end
          
          def clone : Effect
            effect = DissolveShader.new(@pattern, @mode, @duration)
            effect.edge_color = @edge_color
            effect.edge_width = @edge_width
            effect.noise_scale = @noise_scale
            effect
          end
          
          # Helper factory methods
          def self.fade_in(pattern : DissolvePattern = DissolvePattern::Noise, duration : Float32 = 1.0f32)
            DissolveShader.new(pattern, DissolveMode::In, duration)
          end
          
          def self.fade_out(pattern : DissolvePattern = DissolvePattern::Noise, duration : Float32 = 1.0f32)
            DissolveShader.new(pattern, DissolveMode::Out, duration)
          end
        end
      end
    end
  end
end