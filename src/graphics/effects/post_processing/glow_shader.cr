# Advanced glow and bloom effects using shaders
#
# Implements multi-pass glow with proper HDR handling
# and various glow modes for different visual styles.

require "../shader_effect"
require "../shader_library"

module PointClickEngine
  module Graphics
    module Effects
      module PostProcessing
        # Glow modes
        enum GlowMode
          Simple     # Basic threshold glow
          Adaptive   # HDR adaptive glow
          Selective  # Color-based selection
          Lens       # Lens flare style glow
        end
        
        # Shader-based glow effect
        class GlowShader < ShaderEffect
          property glow_mode : GlowMode = GlowMode::Simple
          property threshold : Float32 = 0.8f32
          property intensity : Float32 = 1.0f32
          property blur_passes : Int32 = 3
          property blur_scale : Float32 = 1.0f32
          property tint_color : RL::Color = RL::WHITE
          
          # Selective glow properties
          property select_color : RL::Color = RL::WHITE
          property select_tolerance : Float32 = 0.1f32
          
          # Lens glow properties
          property lens_dispersion : Float32 = 0.3f32
          property lens_halo_width : Float32 = 0.5f32
          
          # Multi-resolution buffers for better performance
          @downsample_textures : Array(RL::RenderTexture2D) = [] of RL::RenderTexture2D
          @blur_texture : RL::RenderTexture2D?
          
          def initialize(@glow_mode : GlowMode = GlowMode::Simple,
                         @threshold : Float32 = 0.8f32,
                         duration : Float32 = 0.0f32)
            super(duration)
            
            @render_texture = RL.load_render_texture(Display::REFERENCE_WIDTH, Display::REFERENCE_HEIGHT)
            @blur_texture = RL.load_render_texture(Display::REFERENCE_WIDTH // 2, Display::REFERENCE_HEIGHT // 2)
            
            # Create downsample chain for efficient blur
            width = Display::REFERENCE_WIDTH // 2
            height = Display::REFERENCE_HEIGHT // 2
            
            3.times do
              @downsample_textures << RL.load_render_texture(width, height)
              width //= 2
              height //= 2
            end
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
            uniform sampler2D glowTexture;
            uniform float time;
            uniform int glowMode;
            uniform float threshold;
            uniform float intensity;
            uniform vec4 tintColor;
            uniform vec4 selectColor;
            uniform float selectTolerance;
            uniform float lensDispersion;
            uniform float lensHaloWidth;
            uniform int extractPass;  // 0 = extract bright, 1 = blur, 2 = combine
            uniform vec2 resolution;
            
            #{ShaderLibrary.color_functions}
            
            // Extract bright pixels based on luminance
            vec4 extractBright(vec4 color) {
                float luminance = getLuminance(color.rgb);
                
                if (luminance > threshold) {
                    float brightness = (luminance - threshold) / (1.0 - threshold);
                    return color * brightness;
                }
                
                return vec4(0.0);
            }
            
            // Extract based on HDR adaptive threshold
            vec4 extractAdaptive(vec4 color) {
                float luminance = getLuminance(color.rgb);
                
                // Simulate eye adaptation
                float adaptedThreshold = threshold * (1.0 + sin(time * 0.5) * 0.1);
                
                if (luminance > adaptedThreshold) {
                    // Tone mapping for HDR
                    float brightness = 1.0 - exp(-luminance * intensity);
                    return color * brightness;
                }
                
                return vec4(0.0);
            }
            
            // Extract based on color similarity
            vec4 extractSelective(vec4 color) {
                vec3 targetHSV = rgbToHsv(selectColor.rgb / 255.0);
                vec3 colorHSV = rgbToHsv(color.rgb);
                
                // Compare hue with tolerance
                float hueDiff = abs(targetHSV.x - colorHSV.x);
                hueDiff = min(hueDiff, 1.0 - hueDiff); // Handle hue wrap
                
                if (hueDiff < selectTolerance && colorHSV.y > 0.3) {
                    float match = 1.0 - (hueDiff / selectTolerance);
                    return color * match * intensity;
                }
                
                return vec4(0.0);
            }
            
            // Extract for lens flare style glow
            vec4 extractLens(vec4 color) {
                float luminance = getLuminance(color.rgb);
                
                if (luminance > threshold) {
                    // Create chromatic dispersion
                    vec4 result = color;
                    
                    // Boost different channels
                    result.r *= 1.0 + lensDispersion;
                    result.b *= 1.0 - lensDispersion;
                    
                    float brightness = pow((luminance - threshold) / (1.0 - threshold), 0.5);
                    return result * brightness;
                }
                
                return vec4(0.0);
            }
            
            // Simple box blur for glow
            vec4 blurGlow(vec2 uv, vec2 direction) {
                vec4 color = vec4(0.0);
                float total = 0.0;
                
                // 9-tap blur
                for (int i = -4; i <= 4; i++) {
                    vec2 offset = direction * float(i) / resolution;
                    color += texture(texture0, uv + offset);
                    total += 1.0;
                }
                
                return color / total;
            }
            
            void main()
            {
                if (extractPass == 0) {
                    // Extract bright pixels
                    vec4 color = texture(texture0, fragTexCoord);
                    vec4 bright;
                    
                    switch(glowMode) {
                        case 0: // Simple
                            bright = extractBright(color);
                            break;
                        case 1: // Adaptive
                            bright = extractAdaptive(color);
                            break;
                        case 2: // Selective
                            bright = extractSelective(color);
                            break;
                        case 3: // Lens
                            bright = extractLens(color);
                            break;
                        default:
                            bright = vec4(0.0);
                    }
                    
                    // Apply tint
                    bright.rgb *= tintColor.rgb / 255.0;
                    
                    finalColor = bright;
                    
                } else if (extractPass == 1) {
                    // Blur pass (called multiple times with different directions)
                    vec2 direction = vec2(1.0, 0.0); // Will be set by uniform
                    finalColor = blurGlow(fragTexCoord, direction);
                    
                } else {
                    // Combine pass
                    vec4 original = texture(texture0, fragTexCoord);
                    vec4 glow = texture(glowTexture, fragTexCoord);
                    
                    // Add lens halo for lens mode
                    if (glowMode == 3) {
                        vec2 center = vec2(0.5, 0.5);
                        float dist = distance(fragTexCoord, center);
                        float halo = 1.0 - smoothstep(0.0, lensHaloWidth, dist);
                        glow += glow * halo * 0.5;
                    }
                    
                    // Screen blend mode for glow
                    vec3 blended = 1.0 - (1.0 - original.rgb) * (1.0 - glow.rgb * intensity);
                    
                    finalColor = vec4(blended, original.a);
                }
            }
            SHADER
          end
          
          def apply(context : EffectContext)
            return unless shader = @shader
            context.active_shader = shader
          end
          
          def render_scene_with_glow(&block : -> Nil)
            return yield unless shader = @shader
            return yield unless render_texture = @render_texture
            return yield unless blur_texture = @blur_texture
            
            # 1. Render scene to main texture
            RL.begin_texture_mode(render_texture)
            RL.clear_background(RL::BLANK)
            yield
            RL.end_texture_mode
            
            # 2. Extract bright pixels to blur texture
            RL.begin_texture_mode(blur_texture)
            RL.clear_background(RL::BLANK)
            
            RL.begin_shader_mode(shader)
            update_glow_uniforms(shader, 0)  # Extract pass
            
            RL.draw_texture_pro(
              render_texture.texture,
              RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
              RL::Rectangle.new(x: 0, y: 0, width: blur_texture.texture.width.to_f32, height: blur_texture.texture.height.to_f32),
              RL::Vector2.new(x: 0, y: 0),
              0.0f32,
              RL::WHITE
            )
            
            RL.end_shader_mode
            RL.end_texture_mode
            
            # 3. Multi-pass blur
            @blur_passes.times do |pass|
              # Downsample for efficiency
              if pass < @downsample_textures.size
                downsample_texture = @downsample_textures[pass]
                
                RL.begin_texture_mode(downsample_texture)
                RL.clear_background(RL::BLANK)
                
                source = pass == 0 ? blur_texture : @downsample_textures[pass - 1]
                RL.draw_texture_pro(
                  source.texture,
                  RL::Rectangle.new(x: 0, y: 0, width: source.texture.width.to_f32, height: -source.texture.height.to_f32),
                  RL::Rectangle.new(x: 0, y: 0, width: downsample_texture.texture.width.to_f32, height: downsample_texture.texture.height.to_f32),
                  RL::Vector2.new(x: 0, y: 0),
                  0.0f32,
                  RL::WHITE
                )
                
                RL.end_texture_mode
              end
            end
            
            # 4. Combine original scene with glow
            RL.begin_shader_mode(shader)
            update_glow_uniforms(shader, 2)  # Combine pass
            
            # Set glow texture
            loc = RL.get_shader_location(shader, "glowTexture")
            RL.set_shader_value_texture(shader, loc, blur_texture.texture)
            
            # Draw combined result
            RL.draw_texture_rec(
              render_texture.texture,
              RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
              RL::Vector2.new(x: 0, y: 0),
              RL::WHITE
            )
            
            RL.end_shader_mode
          end
          
          private def update_glow_uniforms(shader : RL::Shader, pass : Int32)
            update_common_uniforms(shader)
            set_shader_value("glowMode", @glow_mode.value.to_f32)
            set_shader_value("threshold", @threshold)
            set_shader_value("intensity", @intensity)
            set_shader_value("tintColor", @tint_color)
            set_shader_value("selectColor", @select_color)
            set_shader_value("selectTolerance", @select_tolerance)
            set_shader_value("lensDispersion", @lens_dispersion)
            set_shader_value("lensHaloWidth", @lens_halo_width)
            set_shader_value("extractPass", pass.to_f32)
          end
          
          def clone : Effect
            effect = GlowShader.new(@glow_mode, @threshold, @duration)
            effect.intensity = @intensity
            effect.blur_passes = @blur_passes
            effect.blur_scale = @blur_scale
            effect.tint_color = @tint_color
            effect.select_color = @select_color
            effect.select_tolerance = @select_tolerance
            effect.lens_dispersion = @lens_dispersion
            effect.lens_halo_width = @lens_halo_width
            effect
          end
        end
      end
    end
  end
end