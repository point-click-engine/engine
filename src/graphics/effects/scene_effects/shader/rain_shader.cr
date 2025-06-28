# Shader-based rain effect for scenes
#
# Creates realistic rain with wind, splashes, and depth layers
# all rendered efficiently on the GPU.

require "../../shader_effect"
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
        class RainShader < ShaderEffect
          property intensity : RainIntensity = RainIntensity::Medium
          property wind_strength : Float32 = 0.2f32
          property rain_color : RL::Color = RL::Color.new(r: 200, g: 200, b: 255, a: 100)
          property splash_enabled : Bool = true
          property depth_layers : Int32 = 3
          
          def initialize(@intensity : RainIntensity = RainIntensity::Medium,
                         @wind_strength : Float32 = 0.2f32,
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
            uniform float time;
            uniform int rainIntensity;
            uniform float windStrength;
            uniform vec4 rainColor;
            uniform int splashEnabled;
            uniform int depthLayers;
            
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
            float getRainDensity() {
                switch(rainIntensity) {
                    case 0: return 10.0;  // Light
                    case 1: return 25.0;  // Medium  
                    case 2: return 50.0;  // Heavy
                    case 3: return 80.0;  // Storm
                }
                return 25.0;
            }
            
            void main()
            {
                vec4 sceneColor = texture(texture0, fragTexCoord);
                vec4 rainEffect = vec4(0.0);
                
                float density = getRainDensity();
                
                // Multiple depth layers for parallax effect
                for (int layer = 0; layer < depthLayers; layer++) {
                    float layerDepth = float(layer) / float(depthLayers);
                    float layerSpeed = 1.0 - layerDepth * 0.5;
                    float layerAlpha = 1.0 - layerDepth * 0.6;
                    
                    // Scale UV for this layer
                    vec2 layerUV = fragTexCoord * vec2(density, 20.0);
                    layerUV.x += float(layer) * 7.3;
                    
                    // Add rain drops
                    float rain = 0.0;
                    for (int i = 0; i < 3; i++) {
                        float seed = float(i * 137 + layer * 31);
                        rain += rainDrop(layerUV + vec2(float(i), 0.0), time * layerSpeed, seed);
                    }
                    
                    // Add splashes if enabled
                    if (splashEnabled != 0) {
                        for (int i = 0; i < 5; i++) {
                            float seed = float(i * 73 + layer * 17);
                            rain += rainSplash(fragTexCoord, time * layerSpeed, seed) * 0.5;
                        }
                    }
                    
                    rainEffect += vec4(rainColor.rgb, rain * rainColor.a * layerAlpha);
                }
                
                // Composite rain over scene
                vec3 finalRGB = mix(sceneColor.rgb, rainEffect.rgb, rainEffect.a);
                
                // Add slight darkening for storm intensity
                if (rainIntensity == 3) {
                    finalRGB *= 0.8;
                }
                
                finalColor = vec4(finalRGB, sceneColor.a);
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            context.active_shader = shader
          end
          
          def render_scene_with_rain(&block : -> Nil)
            return yield unless shader = @shader
            return yield unless render_texture = @render_texture
            
            # Render scene to texture
            RL.begin_texture_mode(render_texture)
            RL.clear_background(RL::BLANK)
            yield
            RL.end_texture_mode
            
            # Apply rain shader
            RL.begin_shader_mode(shader)
            
            # Update uniforms
            update_common_uniforms(shader)
            set_shader_value("rainIntensity", @intensity.value.to_f32)
            set_shader_value("windStrength", @wind_strength)
            set_shader_value("rainColor", @rain_color)
            set_shader_value("splashEnabled", @splash_enabled ? 1.0f32 : 0.0f32)
            set_shader_value("depthLayers", @depth_layers.to_f32)
            
            # Draw the scene with rain
            RL.draw_texture_rec(
              render_texture.texture,
              RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
              RL::Vector2.new(x: 0, y: 0),
              RL::WHITE
            )
            
            RL.end_shader_mode
          end
          
          def clone : Effect
            effect = RainShader.new(@intensity, @wind_strength, @duration)
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