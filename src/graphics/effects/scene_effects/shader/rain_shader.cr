# Shader-based rain effect for scenes
#
# Creates realistic rain with wind, splashes, and depth layers
# all rendered efficiently on the GPU.

require "../shader_scene_effect"
require "../../shader_library"
module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Rain intensity levels
        enum RainIntensity
          Light
          Medium
          Heavy
          Storm
        end
        
        # Shader-based rain effect
        class RainShader < ShaderSceneEffect
          property rain_intensity : RainIntensity = RainIntensity::Medium
          property wind_strength : Float32 = 0.2f32
          property rain_color : RL::Color = RL::Color.new(r: 200, g: 200, b: 255, a: 100)
          property splash_enabled : Bool = true
          property depth_layers : Int32 = 3
          
          def initialize(@rain_intensity : RainIntensity = RainIntensity::Medium,
                         @wind_strength : Float32 = 0.2f32,
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
            uniform float rainIntensity;
            uniform float windStrength;
            uniform vec4 rainColor;
            uniform float splashEnabled;
            uniform float depthLayers;
            
            #{ShaderLibrary.noise_functions}
            
            // Create a single raindrop
            float rainDrop(vec2 uv, float t, float seed) {
                // Add wind effect
                uv.x += windStrength * sin(t * 2.0 + seed);
                
                // Create falling motion
                float speed = 3.0 + rand(vec2(seed, 0.0)) * 2.0;
                float y = fract(uv.y - t * speed + seed);
                
                // Raindrop shape (thin vertical line)
                float x = abs(uv.x - floor(uv.x) - 0.5);
                float drop = 1.0 - smoothstep(0.0, 0.02, x);
                drop *= smoothstep(0.0, 0.1, y) * smoothstep(0.3, 0.1, y);
                
                // Add streak
                float streak = 1.0 - smoothstep(0.0, 0.01, x);
                streak *= smoothstep(0.1, 0.3, y) * smoothstep(0.6, 0.3, y);
                
                return max(drop, streak * 0.5);
            }
            
            // Create splash effect at bottom
            float rainSplash(vec2 uv, float t, float seed) {
                if (uv.y > 0.1) return 0.0;
                
                float splashTime = fract(t * 2.0 + seed);
                float x = uv.x + rand(vec2(seed, 1.0)) - 0.5;
                
                // Splash ring
                float dist = length(vec2(x, uv.y) * vec2(1.0, 3.0));
                float splash = smoothstep(0.1, 0.05, abs(dist - splashTime * 0.2));
                splash *= 1.0 - splashTime;
                
                return splash;
            }
            
            // Get rain density based on intensity
            // rainIntensity is passed as enum value: 0=Light, 1=Medium, 2=Heavy, 3=Storm
            float getRainDensity() {
                int intensity = int(rainIntensity);
                if (intensity == 0) return 10.0;       // Light
                else if (intensity == 1) return 25.0;  // Medium
                else if (intensity == 2) return 50.0;  // Heavy
                else return 80.0;                      // Storm
            }
            
            void main()
            {
                vec4 sceneColor = texture(texture0, fragTexCoord);
                
                float rainEffect = 0.0;
                float density = getRainDensity();
                
                // Create rain drops as vertical streaks
                for (float i = 0.0; i < density; i++) {
                    float seed = i * 1.337;
                    float x = rand(vec2(seed, 0.0));
                    float speed = 3.0 + rand(vec2(seed, 1.0)) * 2.0;
                    
                    // Add wind effect
                    x += sin(time * 2.0 + seed) * windStrength * 0.05;
                    
                    // Multiple drops per column for continuous effect
                    for (float j = 0.0; j < 3.0; j++) {
                        // Animate falling (subtract time for downward motion)
                        float y = fract(-time * speed + j * 0.33 + rand(vec2(seed, 2.0)));
                        
                        // Make drops accelerate
                        y = pow(y, 0.8);
                        
                        // Check if we're near this drop
                        float xDist = abs(fragTexCoord.x - x);
                        float yDist = abs(fragTexCoord.y - y);
                        
                        // Create streak shape
                        if (xDist < 0.003) {
                            // Vertical streak
                            if (yDist < 0.08) {
                                float streak = 1.0 - (yDist / 0.08);
                                streak *= 1.0 - (xDist / 0.003);
                                
                                // Fade at screen edges
                                streak *= smoothstep(0.0, 0.05, y);
                                streak *= smoothstep(1.0, 0.95, y);
                                
                                // Layer effect
                                float layerBrightness = (i < density * 0.5) ? 0.3 : 0.6;
                                rainEffect += streak * layerBrightness;
                            }
                        }
                    }
                }
                
                // Layer 3: Splashes at the bottom
                if (splashEnabled > 0.5) {
                    for (float i = 0.0; i < density * 0.3; i++) {
                        float seed = i * 3.579;
                        float splashX = rand(vec2(seed, 7.0));
                        float splashTime = fract(time * 2.5 + seed);
                        
                        // Check if we're at the bottom of screen
                        if (fragTexCoord.y < 0.08) {
                            float distX = abs(fragTexCoord.x - splashX);
                            if (distX < 0.03) {
                                // Create expanding ring splash
                                float splashRadius = splashTime * 0.05;
                                float ringDist = abs(length(vec2(distX * 2.0, fragTexCoord.y)) - splashRadius);
                                float splash = smoothstep(0.01, 0.0, ringDist);
                                splash *= (1.0 - splashTime); // Fade out over time
                                rainEffect += splash * 0.3;
                            }
                        }
                    }
                }
                
                // Atmospheric effects
                vec3 darkening = vec3(0.7, 0.7, 0.75);
                sceneColor.rgb *= darkening;
                
                // Add subtle blue tint to simulate wet atmosphere
                sceneColor.rgb = mix(sceneColor.rgb, vec3(0.7, 0.8, 0.9), 0.1);
                
                // Apply rain with proper alpha blending
                rainEffect = clamp(rainEffect, 0.0, 0.9);
                vec3 finalRGB = mix(sceneColor.rgb, rainColor.rgb, rainEffect * rainColor.a);
                
                // Add very subtle screen distortion for rain on lens effect
                if (rainEffect > 0.1) {
                    vec2 distortion = vec2(
                        sin(fragTexCoord.y * 100.0 + time * 20.0) * 0.0005,
                        0.0
                    );
                    vec4 distortedScene = texture(texture0, fragTexCoord + distortion);
                    finalRGB = mix(finalRGB, distortedScene.rgb, 0.2);
                }
                
                finalColor = vec4(finalRGB, sceneColor.a);
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            context.active_shader = shader
          end
          
          protected def update_effect_uniforms(shader : RL::Shader, logical_width : Int32, logical_height : Int32)
            set_shader_value("rainIntensity", @rain_intensity.value.to_f32)
            set_shader_value("windStrength", @wind_strength)
            set_shader_value("rainColor", @rain_color)
            set_shader_value("splashEnabled", @splash_enabled ? 1.0f32 : 0.0f32)
            set_shader_value("depthLayers", @depth_layers.to_f32)
          end
          
          def clone : Effect
            effect = RainShader.new(@rain_intensity, @wind_strength, @duration)
            effect.rain_color = @rain_color
            effect.splash_enabled = @splash_enabled
            effect.depth_layers = @depth_layers
            effect
          end
          
        end
      end
    end
  end
end
