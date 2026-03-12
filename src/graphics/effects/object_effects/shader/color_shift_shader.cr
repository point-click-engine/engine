# Shader-based color shift effect for objects
#
# Provides various color manipulation modes including tint, grayscale,
# sepia, rainbow, and flash effects using GPU shaders.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Color modes for the shader effect
        enum ColorShiftMode
          Tint
          Grayscale
          Sepia
          Negative
          Rainbow
          Flash
        end
        
        # Shader-based color shift effect
        class ColorShiftShader < ShaderEffect
          property mode : ColorShiftMode = ColorShiftMode::Tint
          property target_color : RL::Color = RL::WHITE
          property flash_speed : Float32 = 4.0f32
          
          def initialize(@mode : ColorShiftMode, 
                         @target_color : RL::Color = RL::WHITE,
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
            uniform float progress;
            uniform float time;
            uniform int colorMode;
            uniform vec4 targetColor;
            uniform float intensity;
            
            #{ShaderLibrary.color_functions}
            #{ShaderLibrary.easing_functions}
            
            void main()
            {
                vec4 texColor = texture(texture0, fragTexCoord);
                vec3 color = texColor.rgb;
                float alpha = texColor.a;
                
                // Apply color effect based on mode
                switch(colorMode) {
                    case 0: // Tint
                        color = mix(color, targetColor.rgb, intensity * targetColor.a);
                        break;
                        
                    case 1: // Grayscale
                        float gray = toGrayscale(color);
                        color = mix(color, vec3(gray), intensity);
                        break;
                        
                    case 2: // Sepia
                        vec3 sepia = toSepia(color);
                        color = mix(color, sepia, intensity);
                        break;
                        
                    case 3: // Negative
                        vec3 inverted = invertColor(color);
                        color = mix(color, inverted, intensity);
                        break;
                        
                    case 4: // Rainbow
                        vec3 hsv = rgb2hsv(color);
                        hsv.x = mod(hsv.x + time * 0.2 + fragTexCoord.x, 1.0);
                        vec3 rainbow = hsv2rgb(hsv);
                        color = mix(color, rainbow, intensity);
                        break;
                        
                    case 5: // Flash
                        float flash = sin(time * 4.0) * 0.5 + 0.5;
                        color = mix(color, targetColor.rgb, flash * intensity);
                        break;
                }
                
                // Apply fragColor tint
                color *= fragColor.rgb;
                alpha *= fragColor.a;
                
                finalColor = vec4(color, alpha);
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
            set_shader_value("colorMode", @mode.value.to_f32)
            set_shader_value("targetColor", @target_color)
            set_shader_value("intensity", @intensity)
            
            # The actual sprite drawing will happen after this
            # The shader will be applied during the draw call
            
            # Store shader in context for the renderer to use
            context.active_shader = shader
          end
          
          def clone : Effect
            ColorShiftShader.new(@mode, @target_color, @duration)
          end
          
          # Helper to create specific color effects
          def self.tint(color : RL::Color, intensity : Float32 = 1.0f32, duration : Float32 = 0.0f32)
            effect = ColorShiftShader.new(ColorShiftMode::Tint, color, duration)
            effect.intensity = intensity
            effect
          end
          
          def self.grayscale(intensity : Float32 = 1.0f32, duration : Float32 = 0.0f32)
            effect = ColorShiftShader.new(ColorShiftMode::Grayscale, RL::WHITE, duration)
            effect.intensity = intensity
            effect
          end
          
          def self.sepia(intensity : Float32 = 1.0f32, duration : Float32 = 0.0f32)
            effect = ColorShiftShader.new(ColorShiftMode::Sepia, RL::WHITE, duration)
            effect.intensity = intensity
            effect
          end
          
          def self.rainbow(intensity : Float32 = 1.0f32, duration : Float32 = 0.0f32)
            effect = ColorShiftShader.new(ColorShiftMode::Rainbow, RL::WHITE, duration)
            effect.intensity = intensity
            effect
          end
          
          def self.flash(color : RL::Color, speed : Float32 = 4.0f32, duration : Float32 = 0.0f32)
            effect = ColorShiftShader.new(ColorShiftMode::Flash, color, duration)
            effect.flash_speed = speed
            effect.intensity = 1.0f32
            effect
          end
        end
      end
    end
  end
end