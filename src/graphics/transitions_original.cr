# Scene transition effects using shaders

require "raylib-cr"

module PointClickEngine
  module Graphics
    # Scene transition manager with shader effects
    class TransitionManager
      property active : Bool = false
      property progress : Float32 = 0.0f32
      property duration : Float32 = 1.0f32
      property current_effect : TransitionEffect?
      property on_complete : Proc(Nil)?
      
      @render_texture : RL::RenderTexture2D?
      @shader : RL::Shader?
      
      def initialize(width : Int32, height : Int32)
        @render_texture = RL.load_render_texture(width, height)
      end
      
      # Start a transition effect
      def start_transition(effect : TransitionEffect, duration : Float32 = 1.0f32, &on_complete : -> Nil)
        @active = true
        @progress = 0.0f32
        @duration = duration
        @current_effect = effect
        @on_complete = on_complete
        
        # Load appropriate shader
        @shader = case effect
        when .fade? then load_fade_shader
        when .iris? then load_iris_shader
        when .pixelate? then load_pixelate_shader
        when .swirl? then load_swirl_shader
        when .checkerboard? then load_checkerboard_shader
        when .star_wipe? then load_star_wipe_shader
        when .heart_wipe? then load_heart_wipe_shader
        when .dissolve? then load_dissolve_shader
        when .slide_left? then load_slide_shader(:left)
        when .slide_right? then load_slide_shader(:right)
        when .slide_up? then load_slide_shader(:up)
        when .slide_down? then load_slide_shader(:down)
        when .curtain? then load_curtain_shader
        when .ripple? then load_ripple_shader
        when .warp? then load_warp_shader
        when .wave? then load_wave_shader
        when .film_burn? then load_film_burn_shader
        when .static? then load_static_shader
        when .matrix_rain? then load_matrix_rain_shader
        when .zoom_blur? then load_zoom_blur_shader
        when .clock_wipe? then load_clock_wipe_shader
        when .barn_door? then load_barn_door_shader
        when .page_turn? then load_page_turn_shader
        when .shatter? then load_shatter_shader
        when .glitch? then load_glitch_shader
        when .film_strip? then load_film_strip_shader
        when .lens_flare? then load_lens_flare_shader
        when .vortex? then load_vortex_shader
        when .blinds? then load_blinds_shader
        when .mosaic? then load_mosaic_shader
        when .dream? then load_dream_shader
        when .fire? then load_fire_shader
        when .cross_fade? then load_cross_fade_shader
        else
          nil
        end
      end
      
      # Update transition progress
      def update(dt : Float32)
        return unless @active
        
        @progress += dt / @duration
        
        if @progress >= 1.0f32
          @progress = 1.0f32
          @active = false
          @on_complete.try(&.call)
        end
        
        # Update shader uniforms
        if shader = @shader
          if effect = @current_effect
            case effect
            when .fade?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "alpha"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .iris?, .star_wipe?, .heart_wipe?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "radius"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .pixelate?
              pixel_size = (1.0f32 - @progress) * 50.0f32 + 1.0f32
              RL.set_shader_value(shader, RL.get_shader_location(shader, "pixelSize"), 
                pointerof(pixel_size), RL::ShaderUniformDataType::Float)
            when .swirl?
              swirl_amount = @progress * 10.0f32
              RL.set_shader_value(shader, RL.get_shader_location(shader, "swirlAmount"), 
                pointerof(swirl_amount), RL::ShaderUniformDataType::Float)
            when .checkerboard?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "progress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .dissolve?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "dissolveAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .slide_left?, .slide_right?, .slide_up?, .slide_down?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "slideAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .curtain?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "curtainProgress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .ripple?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "rippleAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .warp?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "warpAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .wave?
              wave_time = @progress * 10.0f32
              RL.set_shader_value(shader, RL.get_shader_location(shader, "waveTime"), 
                pointerof(wave_time), RL::ShaderUniformDataType::Float)
              RL.set_shader_value(shader, RL.get_shader_location(shader, "waveProgress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .film_burn?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "burnAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .static?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "staticAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .matrix_rain?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "rainAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .zoom_blur?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "zoomAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .clock_wipe?
              angle = @progress * 360.0f32
              RL.set_shader_value(shader, RL.get_shader_location(shader, "angle"), 
                pointerof(angle), RL::ShaderUniformDataType::Float)
            when .barn_door?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "doorProgress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .page_turn?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "turnProgress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .shatter?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "shatterTime"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .glitch?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "glitchAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .film_strip?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "stripProgress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .lens_flare?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "flareIntensity"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .vortex?
              spin = @progress * 20.0f32
              RL.set_shader_value(shader, RL.get_shader_location(shader, "spinAmount"), 
                pointerof(spin), RL::ShaderUniformDataType::Float)
            when .blinds?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "blindsProgress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .mosaic?
              tiles = (1.0f32 - @progress) * 50.0f32 + 1.0f32
              RL.set_shader_value(shader, RL.get_shader_location(shader, "tileCount"), 
                pointerof(tiles), RL::ShaderUniformDataType::Float)
            when .dream?
              blur = @progress * 0.02f32
              RL.set_shader_value(shader, RL.get_shader_location(shader, "blurAmount"), 
                pointerof(blur), RL::ShaderUniformDataType::Float)
            when .fire?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "fireProgress"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            when .cross_fade?
              RL.set_shader_value(shader, RL.get_shader_location(shader, "fadeAmount"), 
                pointerof(@progress), RL::ShaderUniformDataType::Float)
            end
          end
        end
      end
      
      # Begin capturing the scene
      def begin_capture
        return unless rt = @render_texture
        RL.begin_texture_mode(rt)
      end
      
      # End capturing and draw with transition effect
      def end_capture_and_draw
        return unless rt = @render_texture
        RL.end_texture_mode
        
        # Draw captured scene with transition shader
        if shader = @shader
          RL.begin_shader_mode(shader)
        end
        
        RL.draw_texture_pro(
          rt.texture,
          RL::Rectangle.new(x: 0, y: 0, width: rt.texture.width, height: -rt.texture.height),
          RL::Rectangle.new(x: 0, y: 0, width: RL.get_screen_width, height: RL.get_screen_height),
          RL::Vector2.new(x: 0, y: 0),
          0.0,
          RL::WHITE
        )
        
        if shader
          RL.end_shader_mode
        end
      end
      
      # Cleanup resources
      def cleanup
        @render_texture.try { |rt| RL.unload_render_texture(rt) }
        @shader.try { |s| RL.unload_shader(s) }
      end
      
      # Load shader implementations
      private def load_fade_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float alpha;
        out vec4 finalColor;
        
        void main() {
            vec4 texelColor = texture(texture0, fragTexCoord);
            finalColor = vec4(texelColor.rgb, texelColor.a * (1.0 - alpha));
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_iris_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float radius;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            float dist = distance(fragTexCoord, center);
            vec4 texelColor = texture(texture0, fragTexCoord);
            
            if (dist > 1.0 - radius) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                finalColor = texelColor;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_pixelate_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float pixelSize;
        out vec4 finalColor;
        
        void main() {
            vec2 size = vec2(pixelSize) / vec2(textureSize(texture0, 0));
            vec2 coord = floor(fragTexCoord / size) * size;
            finalColor = texture(texture0, coord);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_swirl_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float swirlAmount;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 tc = fragTexCoord - center;
            float dist = length(tc);
            float angle = atan(tc.y, tc.x);
            angle += swirlAmount * smoothstep(0.0, 1.0, 1.0 - dist);
            tc = vec2(cos(angle), sin(angle)) * dist;
            finalColor = texture(texture0, tc + center);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_checkerboard_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float progress;
        out vec4 finalColor;
        
        void main() {
            vec2 size = vec2(8.0, 8.0);
            vec2 checkerPos = floor(fragTexCoord * size);
            float checker = mod(checkerPos.x + checkerPos.y, 2.0);
            
            vec4 texelColor = texture(texture0, fragTexCoord);
            
            if (checker < progress * 2.0) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                finalColor = texelColor;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_star_wipe_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float radius;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 pos = fragTexCoord - center;
            float angle = atan(pos.y, pos.x);
            float dist = length(pos);
            
            // Create star shape
            float star = 0.5 + 0.5 * cos(5.0 * angle);
            star = star * 0.3 + 0.7;
            
            vec4 texelColor = texture(texture0, fragTexCoord);
            
            if (dist > star * (1.0 - radius)) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                finalColor = texelColor;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_heart_wipe_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float radius;
        out vec4 finalColor;
        
        void main() {
            vec2 p = fragTexCoord - vec2(0.5, 0.4);
            p *= 2.0;
            
            // Heart shape equation
            float a = atan(p.y, p.x) / 3.14159;
            float r = length(p);
            float h = abs(a);
            float d = (13.0 * h - 22.0 * h * h + 10.0 * h * h * h) / (6.0 - 5.0 * h);
            
            vec4 texelColor = texture(texture0, fragTexCoord);
            
            if (r > d * (1.0 - radius)) {
                finalColor = vec4(1.0, 0.4, 0.6, 1.0); // Pink background
            } else {
                finalColor = texelColor;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_dissolve_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float dissolveAmount;
        out vec4 finalColor;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
        }
        
        void main() {
            vec4 texelColor = texture(texture0, fragTexCoord);
            float noise = random(fragTexCoord);
            
            if (noise < dissolveAmount) {
                finalColor = vec4(0.0, 0.0, 0.0, 0.0);
            } else {
                finalColor = texelColor;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_slide_shader(direction : Symbol) : RL::Shader
        dir_x, dir_y = case direction
        when :left then {-1.0, 0.0}
        when :right then {1.0, 0.0}
        when :up then {0.0, -1.0}
        when :down then {0.0, 1.0}
        else {0.0, 0.0}
        end
        
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float slideAmount;
        out vec4 finalColor;
        
        void main() {
            vec2 offset = vec2(#{dir_x}, #{dir_y}) * slideAmount;
            vec2 tc = fragTexCoord + offset;
            
            if (tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0 || tc.y > 1.0) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                finalColor = texture(texture0, tc);
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_curtain_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float curtainProgress;
        out vec4 finalColor;
        
        void main() {
            vec4 texelColor = texture(texture0, fragTexCoord);
            float leftCurtain = fragTexCoord.x < curtainProgress * 0.5;
            float rightCurtain = fragTexCoord.x > 1.0 - curtainProgress * 0.5;
            
            if (leftCurtain || rightCurtain) {
                finalColor = vec4(0.5, 0.0, 0.0, 1.0); // Dark red curtain
            } else {
                finalColor = texelColor;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      private def load_ripple_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float rippleAmount;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 tc = fragTexCoord;
            float dist = distance(tc, center);
            
            float ripple = sin(dist * 50.0 - rippleAmount * 20.0) * 0.02;
            ripple *= (1.0 - rippleAmount) * smoothstep(0.0, 0.5, dist);
            
            tc += normalize(tc - center) * ripple;
            
            vec4 texelColor = texture(texture0, tc);
            finalColor = mix(texelColor, vec4(0.0, 0.0, 0.0, 1.0), rippleAmount);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Space warp distortion
      private def load_warp_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float warpAmount;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 tc = fragTexCoord - center;
            float dist = length(tc);
            
            // Warp space-time!
            float warp = 1.0 + warpAmount * 3.0 * (1.0 - dist);
            tc *= warp;
            tc += center;
            
            if (tc.x < 0.0 || tc.x > 1.0 || tc.y < 0.0 || tc.y > 1.0) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                vec4 color = texture(texture0, tc);
                // Add some chromatic aberration for sci-fi effect
                vec2 offset = (tc - center) * warpAmount * 0.01;
                color.r = texture(texture0, tc + offset).r;
                color.b = texture(texture0, tc - offset).b;
                finalColor = color;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Ocean wave effect
      private def load_wave_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float waveTime;
        uniform float waveProgress;
        out vec4 finalColor;
        
        void main() {
            vec2 tc = fragTexCoord;
            float wave = sin(tc.y * 20.0 + waveTime) * 0.03 * waveProgress;
            tc.x += wave;
            
            vec4 color = texture(texture0, tc);
            
            // Add water caustics effect
            float caustic = sin(tc.x * 30.0 + waveTime * 0.5) * sin(tc.y * 30.0 - waveTime * 0.7);
            color.rgb += vec3(0.0, 0.1, 0.2) * caustic * 0.2 * waveProgress;
            
            finalColor = mix(color, vec4(0.0, 0.3, 0.5, 1.0), waveProgress);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Film burn effect
      private def load_film_burn_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float burnAmount;
        out vec4 finalColor;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
        }
        
        void main() {
            vec2 tc = fragTexCoord;
            vec4 color = texture(texture0, tc);
            
            // Create burn holes
            float noise = random(tc * 5.0);
            float burn = smoothstep(0.3, 0.7, noise + burnAmount - 0.5);
            
            // Orange/red burn edge
            vec3 burnColor = vec3(1.0, 0.3, 0.0);
            
            if (burn > 0.8) {
                finalColor = vec4(0.0, 0.0, 0.0, 0.0); // Burned through
            } else if (burn > 0.5) {
                finalColor = vec4(mix(color.rgb, burnColor, (burn - 0.5) * 2.0), 1.0);
            } else {
                // Add sepia tone for old film look
                vec3 sepia = vec3(
                    dot(color.rgb, vec3(0.393, 0.769, 0.189)),
                    dot(color.rgb, vec3(0.349, 0.686, 0.168)),
                    dot(color.rgb, vec3(0.272, 0.534, 0.131))
                );
                finalColor = vec4(mix(color.rgb, sepia, burnAmount * 0.5), color.a);
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # TV static noise
      private def load_static_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float staticAmount;
        out vec4 finalColor;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
        }
        
        void main() {
            vec2 tc = fragTexCoord;
            vec4 color = texture(texture0, tc);
            
            // Horizontal distortion
            float distortion = random(vec2(0.0, tc.y * 100.0 + staticAmount * 1000.0)) * 0.03;
            tc.x += distortion * staticAmount;
            
            // Sample with distortion
            color = texture(texture0, tc);
            
            // Add noise
            float noise = random(tc + vec2(staticAmount * 100.0));
            vec3 static = vec3(noise);
            
            finalColor = vec4(mix(color.rgb, static, staticAmount), 1.0);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Matrix digital rain
      private def load_matrix_rain_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float rainAmount;
        out vec4 finalColor;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
        }
        
        void main() {
            vec2 tc = fragTexCoord;
            vec4 color = texture(texture0, tc);
            
            // Create vertical strips
            float strip = floor(tc.x * 40.0) / 40.0;
            float stripRandom = random(vec2(strip, 0.0));
            float fall = mod(rainAmount * (2.0 + stripRandom * 3.0), 1.5);
            
            // Create falling effect
            float brightness = 0.0;
            if (tc.y < fall && tc.y > fall - 0.2) {
                brightness = 1.0 - (fall - tc.y) * 5.0;
            }
            
            // Matrix green color
            vec3 matrixColor = vec3(0.0, 1.0, 0.2) * brightness;
            
            // Mix with darkened original
            finalColor = vec4(mix(color.rgb * (1.0 - rainAmount * 0.7), matrixColor, brightness), 1.0);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Zoom blur effect
      private def load_zoom_blur_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float zoomAmount;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 tc = fragTexCoord;
            vec2 dir = tc - center;
            
            vec4 color = vec4(0.0);
            float total = 0.0;
            
            // Radial blur
            for (float i = 0.0; i < 10.0; i++) {
                float scale = 1.0 - zoomAmount * i * 0.02;
                vec2 samplePos = center + dir * scale;
                color += texture(texture0, samplePos);
                total += 1.0;
            }
            
            finalColor = color / total;
            finalColor.a = 1.0 - zoomAmount;
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Clock wipe
      private def load_clock_wipe_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float angle;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 tc = fragTexCoord - center;
            
            float currentAngle = degrees(atan(tc.y, tc.x)) + 180.0;
            
            vec4 color = texture(texture0, fragTexCoord);
            
            if (currentAngle < angle) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                finalColor = color;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Barn door effect
      private def load_barn_door_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float doorProgress;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord);
            
            float leftDoor = fragTexCoord.x < doorProgress * 0.5;
            float rightDoor = fragTexCoord.x > 1.0 - doorProgress * 0.5;
            
            if (leftDoor || rightDoor) {
                // Wood texture for doors
                float wood = sin(fragTexCoord.y * 50.0) * 0.1 + 0.3;
                finalColor = vec4(wood, wood * 0.7, wood * 0.4, 1.0);
            } else {
                finalColor = color;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Glitch effect
      private def load_glitch_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float glitchAmount;
        out vec4 finalColor;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
        }
        
        void main() {
            vec2 tc = fragTexCoord;
            
            // Random block displacement
            float blockSize = 0.05;
            vec2 block = floor(tc / blockSize) * blockSize;
            float displaceX = (random(block + glitchAmount) - 0.5) * 0.1 * glitchAmount;
            float displaceY = (random(block + glitchAmount * 2.0) - 0.5) * 0.05 * glitchAmount;
            
            tc += vec2(displaceX, displaceY);
            
            // Color channel separation
            vec4 color;
            color.r = texture(texture0, tc + vec2(0.01 * glitchAmount, 0.0)).r;
            color.g = texture(texture0, tc).g;
            color.b = texture(texture0, tc - vec2(0.01 * glitchAmount, 0.0)).b;
            color.a = 1.0;
            
            // Random color corruption
            if (random(tc + glitchAmount * 3.0) < glitchAmount * 0.1) {
                color = vec4(
                    random(tc + glitchAmount * 4.0),
                    random(tc + glitchAmount * 5.0),
                    random(tc + glitchAmount * 6.0),
                    1.0
                );
            }
            
            finalColor = color;
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Vortex spiral
      private def load_vortex_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float spinAmount;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 tc = fragTexCoord - center;
            float dist = length(tc);
            float angle = atan(tc.y, tc.x);
            
            // Spiral inward
            angle += spinAmount * (1.0 - dist);
            dist *= 1.0 - spinAmount * 0.5;
            
            tc = vec2(cos(angle), sin(angle)) * dist + center;
            
            if (dist < 0.01) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                finalColor = texture(texture0, tc);
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Venetian blinds
      private def load_blinds_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float blindsProgress;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord);
            
            float blindHeight = 0.05;
            float y = mod(fragTexCoord.y, blindHeight) / blindHeight;
            
            if (y < blindsProgress) {
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else {
                finalColor = color;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Mosaic tiles
      private def load_mosaic_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float tileCount;
        out vec4 finalColor;
        
        void main() {
            vec2 tileSize = vec2(1.0) / tileCount;
            vec2 tile = floor(fragTexCoord / tileSize) * tileSize + tileSize * 0.5;
            
            finalColor = texture(texture0, tile);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Dream blur effect
      private def load_dream_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float blurAmount;
        out vec4 finalColor;
        
        void main() {
            vec4 color = vec4(0.0);
            float total = 0.0;
            
            // Gaussian blur
            for (float x = -4.0; x <= 4.0; x += 1.0) {
                for (float y = -4.0; y <= 4.0; y += 1.0) {
                    vec2 offset = vec2(x, y) * blurAmount;
                    float weight = exp(-(x*x + y*y) / 16.0);
                    color += texture(texture0, fragTexCoord + offset) * weight;
                    total += weight;
                }
            }
            
            color /= total;
            
            // Add dreamy glow
            color.rgb += vec3(0.1, 0.05, 0.15) * blurAmount * 10.0;
            
            finalColor = color;
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Simple cross fade
      private def load_cross_fade_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float fadeAmount;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord);
            finalColor = vec4(color.rgb, color.a * (1.0 - fadeAmount));
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Page turn effect (simplified)
      private def load_page_turn_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float turnProgress;
        out vec4 finalColor;
        
        void main() {
            float curl = 1.0 - turnProgress;
            float x = fragTexCoord.x;
            
            if (x > curl) {
                // Page is turned
                finalColor = vec4(0.9, 0.9, 0.8, 1.0); // Paper color
            } else {
                vec4 color = texture(texture0, fragTexCoord);
                // Darken near the curl
                float shadow = smoothstep(curl - 0.1, curl, x);
                color.rgb *= 1.0 - shadow * 0.5;
                finalColor = color;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Shatter effect (simplified)
      private def load_shatter_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float shatterTime;
        out vec4 finalColor;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
        }
        
        void main() {
            vec2 cell = floor(fragTexCoord * 10.0) / 10.0;
            float cellRandom = random(cell);
            
            // Each cell falls at different speed
            float fallTime = shatterTime * (1.0 + cellRandom);
            
            if (fallTime > cellRandom * 0.5) {
                // Cell has shattered
                finalColor = vec4(0.0, 0.0, 0.0, 0.0);
            } else {
                // Add cracks
                vec2 localCoord = fract(fragTexCoord * 10.0);
                float crack = step(0.95, max(localCoord.x, localCoord.y));
                vec4 color = texture(texture0, fragTexCoord);
                finalColor = mix(color, vec4(0.0, 0.0, 0.0, 1.0), crack * shatterTime);
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Film strip slide
      private def load_film_strip_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float stripProgress;
        out vec4 finalColor;
        
        void main() {
            vec2 tc = fragTexCoord;
            tc.x -= stripProgress;
            
            // Film strip holes on sides
            float holeSize = 0.02;
            float holeSpacing = 0.1;
            float edge = 0.05;
            
            bool inHole = false;
            if (tc.x < edge || tc.x > 1.0 - edge) {
                float y = mod(tc.y, holeSpacing);
                if (y < holeSize) {
                    inHole = true;
                }
            }
            
            if (tc.x < 0.0 || tc.x > 1.0 || inHole) {
                finalColor = vec4(0.1, 0.1, 0.1, 1.0); // Dark film color
            } else {
                vec4 color = texture(texture0, tc);
                // Add film grain
                float grain = random(tc + stripProgress) * 0.1;
                color.rgb = mix(color.rgb, vec3(grain), 0.2);
                finalColor = color;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Lens flare
      private def load_lens_flare_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float flareIntensity;
        out vec4 finalColor;
        
        void main() {
            vec2 center = vec2(0.5, 0.5);
            vec2 tc = fragTexCoord;
            float dist = distance(tc, center);
            
            vec4 color = texture(texture0, tc);
            
            // Lens flare rays
            vec2 dir = normalize(tc - center);
            float ray = pow(max(0.0, dot(dir, vec2(1.0, 0.0))), 8.0);
            ray += pow(max(0.0, dot(dir, vec2(0.0, 1.0))), 8.0);
            ray += pow(max(0.0, dot(dir, vec2(0.707, 0.707))), 8.0);
            ray += pow(max(0.0, dot(dir, vec2(-0.707, 0.707))), 8.0);
            
            // Bright center
            float flare = 1.0 / (dist * 10.0 + 1.0);
            
            vec3 flareColor = vec3(1.0, 0.9, 0.7) * (flare + ray * 0.5) * flareIntensity;
            
            finalColor = vec4(color.rgb + flareColor, 1.0);
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
      
      # Fire wipe effect
      private def load_fire_shader : RL::Shader
        fragment = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float fireProgress;
        out vec4 finalColor;
        
        float random(vec2 st) {
            return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
        }
        
        float noise(vec2 st) {
            vec2 i = floor(st);
            vec2 f = fract(st);
            float a = random(i);
            float b = random(i + vec2(1.0, 0.0));
            float c = random(i + vec2(0.0, 1.0));
            float d = random(i + vec2(1.0, 1.0));
            vec2 u = f * f * (3.0 - 2.0 * f);
            return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
        }
        
        void main() {
            vec2 tc = fragTexCoord;
            vec4 color = texture(texture0, tc);
            
            // Fire line position with noise
            float fireLine = 1.0 - fireProgress;
            float n = noise(vec2(tc.x * 5.0, fireProgress * 10.0)) * 0.1;
            float fireY = fireLine + n;
            
            if (tc.y > fireY) {
                // Burned area
                finalColor = vec4(0.0, 0.0, 0.0, 1.0);
            } else if (tc.y > fireY - 0.1) {
                // Fire edge
                float t = (tc.y - (fireY - 0.1)) / 0.1;
                vec3 fireColor = mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 0.0, 0.0), t);
                finalColor = vec4(mix(color.rgb, fireColor, t), 1.0);
            } else {
                finalColor = color;
            }
        }
        GLSL
        
        RL.load_shader_from_memory(nil, fragment)
      end
    end
    
    # Available transition effects
    enum TransitionEffect
      # Elegant transitions
      Fade          # Classic fade to black
      Dissolve      # Random pixel dissolve
      SlideLeft     # Slide out to the left
      SlideRight    # Slide out to the right
      SlideUp       # Slide out upward
      SlideDown     # Slide out downward
      CrossFade     # Smooth cross-fade between scenes
      
      # Cheesy/retro transitions
      Iris          # Classic iris wipe (circle closing)
      Pixelate      # Pixelate and fade
      Swirl         # Swirl/spiral effect
      Checkerboard  # Checkerboard wipe
      StarWipe      # Star-shaped wipe
      HeartWipe     # Heart-shaped wipe (very cheesy!)
      Curtain       # Theater curtain closing
      Ripple        # Water ripple effect
      
      # Movie-like transitions
      Warp          # Space warp distortion
      Wave          # Ocean wave effect
      FilmBurn      # Old film burn transition
      Static        # TV static noise
      MatrixRain    # Digital rain effect
      ZoomBlur      # Zoom with motion blur
      ClockWipe     # Clock hand sweep
      BarnDoor      # Barn doors closing
      PageTurn      # Page turning effect
      Shatter       # Glass shatter effect
      Glitch        # Digital glitch effect
      FilmStrip     # Film strip sliding
      LensFlare     # Bright lens flare
      Vortex        # Spinning vortex
      Blinds        # Venetian blinds
      Mosaic        # Mosaic tiles
      Dream         # Dreamy blur effect
      Fire          # Fire wipe effect
    end
  end
end