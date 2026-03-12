# Shader-based shake effect for objects
#
# Creates various shake patterns using vertex displacement,
# perfect for damage feedback, earthquakes, or emphasis.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Shake patterns
        enum ShakePattern
          Random     # Pure random shake
          Directional # Shake in specific direction
          Rotational  # Rotational shake
          Vibrate     # High frequency vibration
          Impact      # Single impact with decay
        end
        
        # Shader-based shake effect
        class ShakeShader < ShaderEffect
          property pattern : ShakePattern = ShakePattern::Random
          property amplitude : RL::Vector2 = RL::Vector2.new(x: 5.0f32, y: 5.0f32)
          property frequency : Float32 = 30.0f32
          property decay_rate : Float32 = 2.0f32  # How fast shake decays
          property direction : RL::Vector2 = RL::Vector2.new(x: 1.0f32, y: 0.0f32)  # For directional shake
          
          def initialize(@pattern : ShakePattern = ShakePattern::Random,
                         amplitude : Float32 = 5.0f32,
                         @frequency : Float32 = 30.0f32,
                         duration : Float32 = 0.5f32)
            super(duration)
            @amplitude = RL::Vector2.new(x: amplitude, y: amplitude)
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
            uniform float progress;
            uniform int shakePattern;
            uniform vec2 amplitude;
            uniform float frequency;
            uniform float decayRate;
            uniform vec2 direction;
            
            #{ShaderLibrary.noise_functions}
            #{ShaderLibrary.easing_functions}
            
            vec2 getShakeOffset() {
                vec2 offset = vec2(0.0);
                
                // Calculate decay based on progress (if duration > 0)
                float decay = 1.0;
                if (progress > 0.0) {
                    decay = pow(1.0 - progress, decayRate);
                }
                
                float t = time * frequency;
                
                switch(shakePattern) {
                    case 0: // Random
                        offset.x = (noise(vec2(t, 0.0)) - 0.5) * 2.0 * amplitude.x;
                        offset.y = (noise(vec2(t, 1.0)) - 0.5) * 2.0 * amplitude.y;
                        break;
                        
                    case 1: // Directional
                        float shake = sin(t) * (noise(vec2(t * 0.5, 0.0)) - 0.5) * 2.0;
                        offset = direction * shake * amplitude.x;
                        break;
                        
                    case 2: // Rotational
                        float angle = sin(t) * 0.1;
                        // Apply rotation around center (simplified)
                        offset.x = sin(angle) * amplitude.x;
                        offset.y = cos(angle) * amplitude.y * 0.5;
                        break;
                        
                    case 3: // Vibrate
                        offset.x = sin(t * 3.0) * amplitude.x * 0.3;
                        offset.y = cos(t * 3.0) * amplitude.y * 0.3;
                        break;
                        
                    case 4: // Impact
                        float impact = sin(progress * 3.14159) * (1.0 - progress);
                        offset = direction * impact * amplitude.x;
                        break;
                }
                
                return offset * decay;
            }
            
            void main()
            {
                vec2 shakeOffset = getShakeOffset();
                vec3 position = vertexPosition + vec3(shakeOffset, 0.0);
                
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
            uniform float progress;
            uniform vec2 amplitude;
            
            #{ShaderLibrary.noise_functions}
            
            void main()
            {
                vec4 texColor = texture(texture0, fragTexCoord);
                
                // Optional: Add chromatic aberration for intense shakes
                if (length(amplitude) > 10.0 && progress > 0.0) {
                    float aberration = (1.0 - progress) * 0.01;
                    vec2 rOffset = vec2(aberration, 0.0);
                    vec2 bOffset = vec2(-aberration, 0.0);
                    
                    float r = texture(texture0, fragTexCoord + rOffset).r;
                    float g = texColor.g;
                    float b = texture(texture0, fragTexCoord + bOffset).b;
                    
                    texColor.rgb = vec3(r, g, b);
                }
                
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
            set_shader_value("shakePattern", @pattern.value.to_f32)
            set_shader_value("amplitude", @amplitude)
            set_shader_value("frequency", @frequency)
            set_shader_value("decayRate", @decay_rate)
            set_shader_value("direction", @direction.normalize)
            
            # Store shader in context
            context.active_shader = shader
          end
          
          def clone : Effect
            effect = ShakeShader.new(@pattern, @amplitude.x, @frequency, @duration)
            effect.amplitude = @amplitude
            effect.decay_rate = @decay_rate
            effect.direction = @direction
            effect
          end
          
          # Helper factory methods
          def self.damage(intensity : Float32 = 10.0f32, duration : Float32 = 0.3f32)
            ShakeShader.new(ShakePattern::Random, intensity, 30.0f32, duration)
          end
          
          def self.earthquake(intensity : Float32 = 20.0f32, duration : Float32 = 2.0f32)
            effect = ShakeShader.new(ShakePattern::Random, intensity, 15.0f32, duration)
            effect.decay_rate = 1.0f32  # Slower decay
            effect
          end
          
          def self.impact(direction : RL::Vector2, force : Float32 = 15.0f32)
            effect = ShakeShader.new(ShakePattern::Impact, force, 1.0f32, 0.5f32)
            effect.direction = direction
            effect
          end
          
          def self.vibrate(intensity : Float32 = 3.0f32)
            ShakeShader.new(ShakePattern::Vibrate, intensity, 60.0f32, 0.0f32)
          end
        end
      end
    end
  end
end