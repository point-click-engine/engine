# Shader-based float effect for objects
#
# Creates smooth floating motion using vertex displacement,
# perfect for UI elements, pickups, or ambient animations.

require "../../shader_effect"
require "../../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Float motion patterns
        enum FloatPattern
          Sine       # Simple sine wave
          Circular   # Circular motion
          Figure8    # Figure-8 pattern
          Random     # Perlin noise based
          Hover      # Gentle hovering
        end
        
        # Shader-based float effect
        class FloatShader < ShaderEffect
          property pattern : FloatPattern = FloatPattern::Sine
          property amplitude : RL::Vector2 = RL::Vector2.new(x: 0.0f32, y: 10.0f32)
          property frequency : Float32 = 2.0f32
          property phase_offset : Float32 = 0.0f32
          
          def initialize(@pattern : FloatPattern = FloatPattern::Sine,
                         amplitude_x : Float32 = 0.0f32,
                         amplitude_y : Float32 = 10.0f32,
                         @frequency : Float32 = 2.0f32,
                         duration : Float32 = 0.0f32)
            super(duration)
            @amplitude = RL::Vector2.new(x: amplitude_x, y: amplitude_y)
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
            uniform int floatPattern;
            uniform vec2 amplitude;
            uniform float frequency;
            uniform float phaseOffset;
            
            #{ShaderLibrary.noise_functions}
            #{ShaderLibrary.easing_functions}
            
            vec2 getFloatOffset() {
                vec2 offset = vec2(0.0);
                float t = time * frequency + phaseOffset;
                
                switch(floatPattern) {
                    case 0: // Sine
                        offset.x = sin(t) * amplitude.x;
                        offset.y = sin(t) * amplitude.y;
                        break;
                        
                    case 1: // Circular
                        offset.x = cos(t) * amplitude.x;
                        offset.y = sin(t) * amplitude.y;
                        break;
                        
                    case 2: // Figure8
                        offset.x = sin(t) * amplitude.x;
                        offset.y = sin(t * 2.0) * amplitude.y;
                        break;
                        
                    case 3: // Random
                        offset.x = (noise(vec2(t * 0.7, 0.0)) - 0.5) * 2.0 * amplitude.x;
                        offset.y = (noise(vec2(t * 0.7, 1.0)) - 0.5) * 2.0 * amplitude.y;
                        break;
                        
                    case 4: // Hover
                        float hover = sin(t) * 0.5 + sin(t * 2.1) * 0.3 + sin(t * 5.3) * 0.2;
                        offset.x = hover * amplitude.x * 0.3;
                        offset.y = hover * amplitude.y;
                        break;
                }
                
                return offset;
            }
            
            void main()
            {
                vec2 offset = getFloatOffset();
                vec3 position = vertexPosition + vec3(offset, 0.0);
                
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
            set_shader_value("floatPattern", @pattern.value.to_f32)
            set_shader_value("amplitude", @amplitude)
            set_shader_value("frequency", @frequency)
            set_shader_value("phaseOffset", @phase_offset)
            
            # Store shader in context
            context.active_shader = shader
          end
          
          def clone : Effect
            effect = FloatShader.new(@pattern, @amplitude.x, @amplitude.y, @frequency, @duration)
            effect.phase_offset = @phase_offset
            effect
          end
          
          # Helper factory methods
          def self.vertical(amplitude : Float32 = 10.0f32, frequency : Float32 = 2.0f32)
            FloatShader.new(FloatPattern::Sine, 0.0f32, amplitude, frequency)
          end
          
          def self.horizontal(amplitude : Float32 = 10.0f32, frequency : Float32 = 2.0f32)
            FloatShader.new(FloatPattern::Sine, amplitude, 0.0f32, frequency)
          end
          
          def self.circular(radius : Float32 = 10.0f32, frequency : Float32 = 1.0f32)
            FloatShader.new(FloatPattern::Circular, radius, radius, frequency)
          end
          
          def self.hover(amplitude : Float32 = 5.0f32)
            FloatShader.new(FloatPattern::Hover, amplitude * 0.3f32, amplitude, 1.0f32)
          end
        end
      end
    end
  end
end