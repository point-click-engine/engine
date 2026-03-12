# Shader-based pulse effect for objects
#
# Creates smooth scaling animations for breathing, heartbeat,
# and attention-grabbing effects using vertex shaders.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Pulse patterns
        enum PulsePattern
          Sine       # Smooth sine wave
          Heartbeat  # Double-beat pattern
          Bounce     # Elastic bounce
          Breathe    # Natural breathing rhythm
          Alert      # Quick attention pulse
        end
        
        # Shader-based pulse effect
        class PulseShader < ShaderEffect
          property pattern : PulsePattern = PulsePattern::Sine
          property scale_amount : Float32 = 0.1f32  # 10% scale by default
          property speed : Float32 = 2.0f32
          property anchor : RL::Vector2 = RL::Vector2.new(x: 0.5f32, y: 0.5f32)  # Center anchor
          
          def initialize(@pattern : PulsePattern = PulsePattern::Sine,
                         @scale_amount : Float32 = 0.1f32,
                         @speed : Float32 = 2.0f32,
                         duration : Float32 = 0.0f32)
            super(duration)
          end
          
          def vertex_shader_source : String
            <<-SHADER
            #version 330 core
            in vec3 vertexPosition;
            in vec2 vertexTexCoord;
            in vec4 vertexColor;
            
            out vec2 fragTexCoord;
            out vec4 fragColor;
            
            uniform mat4 mvp;
            uniform float time;
            uniform int pulsePattern;
            uniform float scaleAmount;
            uniform float speed;
            uniform vec2 anchor;
            uniform vec2 spriteSize;
            
            #{ShaderLibrary.easing_functions}
            
            float getPulseScale() {
                float t = time * speed;
                float scale = 0.0;
                
                switch(pulsePattern) {
                    case 0: // Sine
                        scale = sin(t) * 0.5 + 0.5;
                        break;
                        
                    case 1: // Heartbeat
                        float beat = mod(t, 3.0);
                        if (beat < 0.3) {
                            scale = sin(beat * 10.47) * 0.5 + 0.5;
                        } else if (beat < 0.6) {
                            scale = sin((beat - 0.3) * 10.47) * 0.3 + 0.5;
                        } else {
                            scale = 0.5;
                        }
                        break;
                        
                    case 2: // Bounce
                        float bounce = abs(sin(t));
                        scale = easeOutElastic(bounce);
                        break;
                        
                    case 3: // Breathe
                        float breathe = sin(t * 0.5) * 0.3 + sin(t * 1.3) * 0.2 + sin(t * 2.1) * 0.1;
                        scale = breathe * 0.5 + 0.5;
                        break;
                        
                    case 4: // Alert
                        float alert = mod(t, 1.0);
                        if (alert < 0.2) {
                            scale = 1.0;
                        } else if (alert < 0.4) {
                            scale = 0.0;
                        } else {
                            scale = 0.5;
                        }
                        break;
                }
                
                return scale;
            }
            
            void main()
            {
                // Calculate pulse scale
                float pulseScale = getPulseScale();
                float finalScale = 1.0 + (pulseScale * scaleAmount);
                
                // Apply scaling around anchor point
                vec3 anchorPos = vec3(anchor * spriteSize, 0.0);
                vec3 relativePos = vertexPosition - anchorPos;
                vec3 scaledPos = relativePos * finalScale;
                vec3 position = scaledPos + anchorPos;
                
                gl_Position = mvp * vec4(position, 1.0);
                fragTexCoord = vertexTexCoord;
                fragColor = vertexColor;
            }
            SHADER
          end
          
          def fragment_shader_source : String
            <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;
            
            uniform sampler2D texture0;
            
            void main()
            {
                vec4 texColor = texture(texture0, fragTexCoord);
                finalColor = texColor * fragColor;
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
            set_shader_value("pulsePattern", @pattern.value.to_f32)
            set_shader_value("scaleAmount", @scale_amount)
            set_shader_value("speed", @speed)
            set_shader_value("anchor", @anchor)
            
            # Set sprite size
            if bounds = sprite.bounds
              sprite_size = RL::Vector2.new(x: bounds.width, y: bounds.height)
              set_shader_value("spriteSize", sprite_size)
            end
            
            # Store shader in context
            context.active_shader = shader
          end
          
          def clone : Effect
            effect = PulseShader.new(@pattern, @scale_amount, @speed, @duration)
            effect.anchor = @anchor
            effect
          end
          
          # Helper factory methods
          def self.breathe(amount : Float32 = 0.05f32, speed : Float32 = 1.0f32)
            PulseShader.new(PulsePattern::Breathe, amount, speed)
          end
          
          def self.heartbeat(amount : Float32 = 0.1f32)
            PulseShader.new(PulsePattern::Heartbeat, amount, 2.0f32)
          end
          
          def self.bounce(amount : Float32 = 0.15f32, speed : Float32 = 1.5f32)
            PulseShader.new(PulsePattern::Bounce, amount, speed)
          end
          
          def self.alert(amount : Float32 = 0.2f32, speed : Float32 = 4.0f32)
            PulseShader.new(PulsePattern::Alert, amount, speed)
          end
        end
      end
    end
  end
end