module PointClickEngine
  module Graphics
    module Shaders
      module ShaderHelpers
        # Pixelation effect shader
        PIXELATE_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float pixelSize;
        out vec4 finalColor;
        
        void main() {
            vec2 size = vec2(pixelSize, pixelSize);
            vec2 pos = floor(fragTexCoord / size) * size;
            finalColor = texture(texture0, pos) * fragColor;
        }
        GLSL

        # Grayscale shader
        GRAYSCALE_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float intensity;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord) * fragColor;
            float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
            finalColor = mix(color, vec4(gray, gray, gray, color.a), intensity);
        }
        GLSL

        # Sepia tone shader
        SEPIA_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float intensity;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord) * fragColor;
            vec3 sepia;
            sepia.r = dot(color.rgb, vec3(0.393, 0.769, 0.189));
            sepia.g = dot(color.rgb, vec3(0.349, 0.686, 0.168));
            sepia.b = dot(color.rgb, vec3(0.272, 0.534, 0.131));
            finalColor = vec4(mix(color.rgb, sepia, intensity), color.a);
        }
        GLSL

        # Vignette shader
        VIGNETTE_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float radius;
        uniform float softness;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord) * fragColor;
            vec2 center = vec2(0.5, 0.5);
            float dist = distance(fragTexCoord, center);
            float vignette = smoothstep(radius, radius - softness, dist);
            finalColor = vec4(color.rgb * vignette, color.a);
        }
        GLSL

        # Chromatic aberration shader
        CHROMATIC_ABERRATION_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float offset;
        out vec4 finalColor;
        
        void main() {
            vec2 direction = fragTexCoord - vec2(0.5, 0.5);
            float r = texture(texture0, fragTexCoord + direction * offset).r;
            float g = texture(texture0, fragTexCoord).g;
            float b = texture(texture0, fragTexCoord - direction * offset).b;
            float a = texture(texture0, fragTexCoord).a;
            finalColor = vec4(r, g, b, a) * fragColor;
        }
        GLSL

        # Bloom shader (simplified)
        BLOOM_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float threshold;
        uniform float intensity;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord) * fragColor;
            float brightness = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
            if (brightness > threshold) {
                finalColor = color * (1.0 + intensity);
            } else {
                finalColor = color;
            }
        }
        GLSL

        # CRT/Scanline effect shader
        CRT_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float scanlineIntensity;
        uniform float pixelHeight;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord) * fragColor;
            float scanline = sin(fragTexCoord.y * pixelHeight * 3.14159) * scanlineIntensity;
            color.rgb -= scanline;
            finalColor = color;
        }
        GLSL

        # Wave distortion shader
        WAVE_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform float time;
        uniform float amplitude;
        uniform float frequency;
        out vec4 finalColor;
        
        void main() {
            vec2 uv = fragTexCoord;
            uv.x += sin(uv.y * frequency + time) * amplitude;
            finalColor = texture(texture0, uv) * fragColor;
        }
        GLSL

        # Outline shader (for highlighting objects)
        OUTLINE_FRAGMENT = <<-GLSL
        #version 330
        in vec2 fragTexCoord;
        in vec4 fragColor;
        uniform sampler2D texture0;
        uniform vec4 outlineColor;
        uniform float outlineSize;
        out vec4 finalColor;
        
        void main() {
            vec4 color = texture(texture0, fragTexCoord);
            if (color.a == 0.0) {
                vec2 size = vec2(outlineSize) / vec2(textureSize(texture0, 0));
                for (int x = -1; x <= 1; x++) {
                    for (int y = -1; y <= 1; y++) {
                        if (x == 0 && y == 0) continue;
                        vec2 offset = vec2(float(x), float(y)) * size;
                        if (texture(texture0, fragTexCoord + offset).a > 0.0) {
                            finalColor = outlineColor;
                            return;
                        }
                    }
                }
            }
            finalColor = color * fragColor;
        }
        GLSL

        # Default vertex shader for all effects
        DEFAULT_VERTEX = <<-GLSL
        #version 330
        in vec3 vertexPosition;
        in vec2 vertexTexCoord;
        in vec4 vertexColor;
        uniform mat4 mvp;
        out vec2 fragTexCoord;
        out vec4 fragColor;
        
        void main() {
            fragTexCoord = vertexTexCoord;
            fragColor = vertexColor;
            gl_Position = mvp * vec4(vertexPosition, 1.0);
        }
        GLSL

        def self.create_pixelate_shader(shader_system : ShaderSystem, pixel_size : Float32 = 4.0f32)
          shader_system.load_shader_from_memory(:pixelate, PIXELATE_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:pixelate, "pixelSize", pixel_size)
        end

        def self.create_grayscale_shader(shader_system : ShaderSystem, intensity : Float32 = 1.0f32)
          shader_system.load_shader_from_memory(:grayscale, GRAYSCALE_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:grayscale, "intensity", intensity)
        end

        def self.create_sepia_shader(shader_system : ShaderSystem, intensity : Float32 = 0.8f32)
          shader_system.load_shader_from_memory(:sepia, SEPIA_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:sepia, "intensity", intensity)
        end

        def self.create_vignette_shader(shader_system : ShaderSystem, radius : Float32 = 0.8f32, softness : Float32 = 0.5f32)
          shader_system.load_shader_from_memory(:vignette, VIGNETTE_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:vignette, "radius", radius)
          shader_system.set_value(:vignette, "softness", softness)
        end

        def self.create_chromatic_aberration_shader(shader_system : ShaderSystem, offset : Float32 = 0.005f32)
          shader_system.load_shader_from_memory(:chromatic_aberration, CHROMATIC_ABERRATION_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:chromatic_aberration, "offset", offset)
        end

        def self.create_bloom_shader(shader_system : ShaderSystem, threshold : Float32 = 0.8f32, intensity : Float32 = 0.5f32)
          shader_system.load_shader_from_memory(:bloom, BLOOM_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:bloom, "threshold", threshold)
          shader_system.set_value(:bloom, "intensity", intensity)
        end

        def self.create_crt_shader(shader_system : ShaderSystem, scanline_intensity : Float32 = 0.1f32, pixel_height : Float32 = 480.0f32)
          shader_system.load_shader_from_memory(:crt, CRT_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:crt, "scanlineIntensity", scanline_intensity)
          shader_system.set_value(:crt, "pixelHeight", pixel_height)
        end

        def self.create_wave_shader(shader_system : ShaderSystem, amplitude : Float32 = 0.01f32, frequency : Float32 = 10.0f32)
          shader_system.load_shader_from_memory(:wave, WAVE_FRAGMENT, DEFAULT_VERTEX)
          shader_system.set_value(:wave, "amplitude", amplitude)
          shader_system.set_value(:wave, "frequency", frequency)
        end

        def self.create_outline_shader(shader_system : ShaderSystem, color : Raylib::Color = Raylib::WHITE, size : Float32 = 2.0f32)
          shader_system.load_shader_from_memory(:outline, OUTLINE_FRAGMENT, DEFAULT_VERTEX)
          color_array = [
            color.r.to_f32 / 255.0f32,
            color.g.to_f32 / 255.0f32,
            color.b.to_f32 / 255.0f32,
            color.a.to_f32 / 255.0f32,
          ]
          shader_system.set_value(:outline, "outlineColor", color_array)
          shader_system.set_value(:outline, "outlineSize", size)
        end
      end
    end
  end
end
