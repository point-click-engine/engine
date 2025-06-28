# Advanced distortion effects using shaders
#
# Implements various distortion algorithms:
# - Heat haze (heat shimmer)
# - Shock wave (radial pulse)
# - Lens distortion (barrel/pincushion)
# - Displacement mapping

require "../shader_effect"
require "../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module PostProcessing
        # Distortion types
        enum DistortionType
          HeatHaze      # Heat shimmer effect
          ShockWave     # Radial distortion pulse
          Lens          # Barrel/pincushion distortion
          Displacement  # Texture-based distortion
          Ripple        # Water ripple effect
        end
        
        # Shader-based distortion effect
        class DistortionShader < ShaderEffect
          property distortion_type : DistortionType = DistortionType::HeatHaze
          property strength : Float32 = 0.01f32
          property frequency : Float32 = 10.0f32
          property speed : Float32 = 1.0f32
          
          # Heat haze properties
          property heat_layers : Int32 = 3
          property heat_vertical_speed : Float32 = 2.0f32
          
          # Shock wave properties
          property shock_center : RL::Vector2 = RL::Vector2.new(x: 0.5f32, y: 0.5f32)
          property shock_radius : Float32 = 0.0f32
          property shock_thickness : Float32 = 0.1f32
          property shock_force : Float32 = 0.05f32
          
          # Lens distortion properties
          property lens_k1 : Float32 = 0.2f32  # Primary distortion coefficient
          property lens_k2 : Float32 = 0.0f32  # Secondary distortion coefficient
          property lens_center : RL::Vector2 = RL::Vector2.new(x: 0.5f32, y: 0.5f32)
          
          # Ripple properties
          property ripple_center : RL::Vector2 = RL::Vector2.new(x: 0.5f32, y: 0.5f32)
          property ripple_wavelength : Float32 = 0.05f32
          property ripple_amplitude : Float32 = 0.01f32
          property ripple_decay : Float32 = 0.5f32
          
          # Displacement map texture
          @displacement_map : RL::Texture2D?
          
          def initialize(@distortion_type : DistortionType = DistortionType::HeatHaze,
                         @strength : Float32 = 0.01f32,
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
            uniform sampler2D displacementMap;
            uniform float time;
            uniform int distortionType;
            uniform float strength;
            uniform float frequency;
            uniform float speed;
            uniform vec2 resolution;
            
            // Heat haze uniforms
            uniform int heatLayers;
            uniform float heatVerticalSpeed;
            
            // Shock wave uniforms
            uniform vec2 shockCenter;
            uniform float shockRadius;
            uniform float shockThickness;
            uniform float shockForce;
            
            // Lens distortion uniforms
            uniform float lensK1;
            uniform float lensK2;
            uniform vec2 lensCenter;
            
            // Ripple uniforms
            uniform vec2 rippleCenter;
            uniform float rippleWavelength;
            uniform float rippleAmplitude;
            uniform float rippleDecay;
            
            #{ShaderLibrary.noise_functions}
            
            // Heat haze distortion
            vec2 heatHazeDistortion(vec2 uv) {
                vec2 distortion = vec2(0.0);
                
                for (int i = 0; i < heatLayers; i++) {
                    float layer = float(i);
                    float layerSpeed = speed * (1.0 + layer * 0.5);
                    float layerFreq = frequency * (1.0 + layer * 0.3);
                    
                    // Horizontal waves
                    float waveX = sin(uv.y * layerFreq + time * layerSpeed) * strength;
                    
                    // Vertical flow
                    float flowY = time * heatVerticalSpeed * (1.0 + layer * 0.2);
                    float noiseY = noise(vec2(uv.x * layerFreq, flowY)) - 0.5;
                    
                    distortion.x += waveX / float(heatLayers);
                    distortion.y += noiseY * strength * 0.5 / float(heatLayers);
                }
                
                return distortion;
            }
            
            // Shock wave distortion
            vec2 shockWaveDistortion(vec2 uv) {
                vec2 toCenter = uv - shockCenter;
                float dist = length(toCenter);
                
                // Check if within shock wave ring
                float ringDist = abs(dist - shockRadius);
                if (ringDist > shockThickness) {
                    return vec2(0.0);
                }
                
                // Calculate distortion strength
                float wave = 1.0 - (ringDist / shockThickness);
                wave = pow(wave, 2.0); // Smooth falloff
                
                // Radial distortion
                vec2 direction = normalize(toCenter);
                float distortAmount = wave * shockForce;
                
                // Add some turbulence
                float turbulence = sin(dist * 50.0) * 0.1;
                distortAmount *= (1.0 + turbulence);
                
                return direction * distortAmount;
            }
            
            // Lens distortion (barrel/pincushion)
            vec2 lensDistortion(vec2 uv) {
                vec2 centered = uv - lensCenter;
                float r2 = dot(centered, centered);
                float r4 = r2 * r2;
                
                // Radial distortion formula
                float distortionFactor = 1.0 + lensK1 * r2 + lensK2 * r4;
                
                vec2 distorted = centered * distortionFactor;
                return distorted + lensCenter - uv;
            }
            
            // Ripple distortion
            vec2 rippleDistortion(vec2 uv) {
                vec2 toCenter = uv - rippleCenter;
                float dist = length(toCenter);
                
                // Multiple ripples
                float ripple = sin(dist / rippleWavelength - time * speed) * rippleAmplitude;
                
                // Decay with distance
                ripple *= exp(-dist * rippleDecay);
                
                // Radial distortion
                vec2 direction = normalize(toCenter);
                return direction * ripple;
            }
            
            // Displacement map distortion
            vec2 displacementDistortion(vec2 uv) {
                vec2 displacement = texture(displacementMap, uv).rg - 0.5;
                return displacement * strength;
            }
            
            void main()
            {
                vec2 distortedUV = fragTexCoord;
                
                switch(distortionType) {
                    case 0: // HeatHaze
                        distortedUV += heatHazeDistortion(fragTexCoord);
                        break;
                    case 1: // ShockWave
                        distortedUV += shockWaveDistortion(fragTexCoord);
                        break;
                    case 2: // Lens
                        distortedUV += lensDistortion(fragTexCoord);
                        break;
                    case 3: // Displacement
                        distortedUV += displacementDistortion(fragTexCoord);
                        break;
                    case 4: // Ripple
                        distortedUV += rippleDistortion(fragTexCoord);
                        break;
                }
                
                // Clamp UV to avoid edge artifacts
                distortedUV = clamp(distortedUV, 0.001, 0.999);
                
                finalColor = texture(texture0, distortedUV) * fragColor;
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            context.active_shader = shader
          end
          
          def set_displacement_map(texture : RL::Texture2D)
            @displacement_map = texture
          end
          
          def update(dt : Float32)
            super
            
            # Auto-advance shock wave radius
            if @distortion_type.shock_wave? && @shock_radius < 2.0f32
              @shock_radius += dt * @speed
            end
          end
          
          def render_scene_with_distortion(&block : -> Nil)
            return yield unless shader = @shader
            return yield unless render_texture = @render_texture
            
            # Render scene to texture
            RL.begin_texture_mode(render_texture)
            RL.clear_background(RL::BLANK)
            yield
            RL.end_texture_mode
            
            # Apply distortion shader
            RL.begin_shader_mode(shader)
            
            # Update uniforms
            update_common_uniforms(shader)
            set_shader_value("distortionType", @distortion_type.value.to_f32)
            set_shader_value("strength", @strength)
            set_shader_value("frequency", @frequency)
            set_shader_value("speed", @speed)
            
            # Heat haze uniforms
            set_shader_value("heatLayers", @heat_layers.to_f32)
            set_shader_value("heatVerticalSpeed", @heat_vertical_speed)
            
            # Shock wave uniforms
            set_shader_value("shockCenter", @shock_center)
            set_shader_value("shockRadius", @shock_radius)
            set_shader_value("shockThickness", @shock_thickness)
            set_shader_value("shockForce", @shock_force)
            
            # Lens uniforms
            set_shader_value("lensK1", @lens_k1)
            set_shader_value("lensK2", @lens_k2)
            set_shader_value("lensCenter", @lens_center)
            
            # Ripple uniforms
            set_shader_value("rippleCenter", @ripple_center)
            set_shader_value("rippleWavelength", @ripple_wavelength)
            set_shader_value("rippleAmplitude", @ripple_amplitude)
            set_shader_value("rippleDecay", @ripple_decay)
            
            # Set displacement map if available
            if @distortion_type.displacement? && (disp_map = @displacement_map)
              loc = RL.get_shader_location(shader, "displacementMap")
              RL.set_shader_value_texture(shader, loc, disp_map)
            end
            
            # Draw the scene with distortion
            RL.draw_texture_rec(
              render_texture.texture,
              RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
              RL::Vector2.new(x: 0, y: 0),
              RL::WHITE
            )
            
            RL.end_shader_mode
          end
          
          def clone : Effect
            effect = DistortionShader.new(@distortion_type, @strength, @duration)
            effect.frequency = @frequency
            effect.speed = @speed
            effect.heat_layers = @heat_layers
            effect.heat_vertical_speed = @heat_vertical_speed
            effect.shock_center = @shock_center
            effect.shock_radius = @shock_radius
            effect.shock_thickness = @shock_thickness
            effect.shock_force = @shock_force
            effect.lens_k1 = @lens_k1
            effect.lens_k2 = @lens_k2
            effect.lens_center = @lens_center
            effect.ripple_center = @ripple_center
            effect.ripple_wavelength = @ripple_wavelength
            effect.ripple_amplitude = @ripple_amplitude
            effect.ripple_decay = @ripple_decay
            effect
          end
        end
      end
    end
  end
end