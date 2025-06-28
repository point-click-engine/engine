# Common shader functions and utilities
#
# This module provides reusable GLSL code snippets and helper functions
# that can be included in various shader effects.

module PointClickEngine
  module Graphics
    module Effects
      module ShaderLibrary
        # Noise functions for various effects
        def self.noise_functions : String
          <<-GLSL
          // Simple pseudo-random function
          float rand(vec2 co) {
              return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
          }
          
          // 2D noise function
          float noise(vec2 p) {
              vec2 i = floor(p);
              vec2 f = fract(p);
              
              float a = rand(i);
              float b = rand(i + vec2(1.0, 0.0));
              float c = rand(i + vec2(0.0, 1.0));
              float d = rand(i + vec2(1.0, 1.0));
              
              vec2 u = f * f * (3.0 - 2.0 * f);
              
              return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
          }
          
          // Fractal noise (FBM)
          float fbm(vec2 p, int octaves) {
              float value = 0.0;
              float amplitude = 0.5;
              float frequency = 1.0;
              
              for (int i = 0; i < octaves; i++) {
                  value += amplitude * noise(p * frequency);
                  amplitude *= 0.5;
                  frequency *= 2.0;
              }
              
              return value;
          }
          GLSL
        end
        
        # Easing functions for smooth transitions
        def self.easing_functions : String
          <<-GLSL
          // Linear (no easing)
          float easeLinear(float t) {
              return t;
          }
          
          // Quadratic easing
          float easeInQuad(float t) {
              return t * t;
          }
          
          float easeOutQuad(float t) {
              return t * (2.0 - t);
          }
          
          float easeInOutQuad(float t) {
              return t < 0.5 ? 2.0 * t * t : -1.0 + (4.0 - 2.0 * t) * t;
          }
          
          // Cubic easing
          float easeInCubic(float t) {
              return t * t * t;
          }
          
          float easeOutCubic(float t) {
              float t1 = t - 1.0;
              return t1 * t1 * t1 + 1.0;
          }
          
          float easeInOutCubic(float t) {
              return t < 0.5 ? 4.0 * t * t * t : (t - 1.0) * (2.0 * t - 2.0) * (2.0 * t - 2.0) + 1.0;
          }
          
          // Sine easing
          float easeInSine(float t) {
              return 1.0 - cos(t * 3.14159265359 / 2.0);
          }
          
          float easeOutSine(float t) {
              return sin(t * 3.14159265359 / 2.0);
          }
          
          float easeInOutSine(float t) {
              return -(cos(3.14159265359 * t) - 1.0) / 2.0;
          }
          
          // Elastic easing
          float easeOutElastic(float t) {
              if (t == 0.0) return 0.0;
              if (t == 1.0) return 1.0;
              float p = 0.3;
              return pow(2.0, -10.0 * t) * sin((t - p / 4.0) * (2.0 * 3.14159265359) / p) + 1.0;
          }
          
          // Bounce easing
          float easeOutBounce(float t) {
              if (t < 1.0 / 2.75) {
                  return 7.5625 * t * t;
              } else if (t < 2.0 / 2.75) {
                  t -= 1.5 / 2.75;
                  return 7.5625 * t * t + 0.75;
              } else if (t < 2.5 / 2.75) {
                  t -= 2.25 / 2.75;
                  return 7.5625 * t * t + 0.9375;
              } else {
                  t -= 2.625 / 2.75;
                  return 7.5625 * t * t + 0.984375;
              }
          }
          GLSL
        end
        
        # Color manipulation functions
        def self.color_functions : String
          <<-GLSL
          // RGB to HSV conversion
          vec3 rgb2hsv(vec3 c) {
              vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
              vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
              vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
              
              float d = q.x - min(q.w, q.y);
              float e = 1.0e-10;
              return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
          }
          
          // HSV to RGB conversion
          vec3 hsv2rgb(vec3 c) {
              vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
              vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
              return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
          }
          
          // Grayscale conversion
          float toGrayscale(vec3 color) {
              return dot(color, vec3(0.299, 0.587, 0.114));
          }
          
          // Sepia tone
          vec3 toSepia(vec3 color) {
              vec3 sepia;
              sepia.r = dot(color, vec3(0.393, 0.769, 0.189));
              sepia.g = dot(color, vec3(0.349, 0.686, 0.168));
              sepia.b = dot(color, vec3(0.272, 0.534, 0.131));
              return clamp(sepia, 0.0, 1.0);
          }
          
          // Color inversion
          vec3 invertColor(vec3 color) {
              return vec3(1.0) - color;
          }
          
          // Contrast adjustment
          vec3 adjustContrast(vec3 color, float contrast) {
              return (color - 0.5) * contrast + 0.5;
          }
          
          // Brightness adjustment
          vec3 adjustBrightness(vec3 color, float brightness) {
              return color + brightness;
          }
          
          // Saturation adjustment
          vec3 adjustSaturation(vec3 color, float saturation) {
              float gray = toGrayscale(color);
              return mix(vec3(gray), color, saturation);
          }
          GLSL
        end
        
        # Geometric shape functions
        def self.shape_functions : String
          <<-GLSL
          // Circle SDF (Signed Distance Function)
          float sdCircle(vec2 p, float r) {
              return length(p) - r;
          }
          
          // Box SDF
          float sdBox(vec2 p, vec2 b) {
              vec2 d = abs(p) - b;
              return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
          }
          
          // Heart SDF
          float sdHeart(vec2 p) {
              p.x = abs(p.x);
              if (p.y + p.x > 1.0)
                  return sqrt(dot(p - vec2(0.25, 0.75), p - vec2(0.25, 0.75))) - sqrt(2.0) / 4.0;
              return sqrt(min(dot(p - vec2(0.0, 1.0), p - vec2(0.0, 1.0)),
                              dot(p - 0.5 * max(p.x + p.y, 0.0), p - 0.5 * max(p.x + p.y, 0.0)))) * 
                     sign(p.x - p.y);
          }
          
          // Star SDF (5-pointed)
          float sdStar(vec2 p, float r, float n) {
              float an = 3.141593 / n;
              float en = 3.141593 / n;
              vec2 acs = vec2(cos(an), sin(an));
              vec2 ecs = vec2(cos(en), sin(en));
              float bn = mod(atan(p.x, p.y), 2.0 * an) - an;
              p = length(p) * vec2(cos(bn), abs(sin(bn)));
              p -= r * acs;
              p += ecs * clamp(-dot(p, ecs), 0.0, r * acs.y / ecs.y);
              return length(p) * sign(p.x);
          }
          
          // Hexagon SDF
          float sdHexagon(vec2 p, float r) {
              const vec3 k = vec3(-0.866025404, 0.5, 0.577350269);
              p = abs(p);
              p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
              p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
              return length(p) * sign(p.y);
          }
          GLSL
        end
        
        # Distortion functions
        def self.distortion_functions : String
          <<-GLSL
          // Wave distortion
          vec2 waveDistortion(vec2 uv, float amplitude, float frequency, float time) {
              float x = sin(uv.y * frequency + time) * amplitude;
              float y = sin(uv.x * frequency + time) * amplitude;
              return uv + vec2(x, y);
          }
          
          // Ripple distortion
          vec2 rippleDistortion(vec2 uv, vec2 center, float time, float amplitude) {
              vec2 toCenter = uv - center;
              float dist = length(toCenter);
              float ripple = sin(dist * 20.0 - time * 5.0) * amplitude / (dist * 10.0 + 1.0);
              return uv + normalize(toCenter) * ripple;
          }
          
          // Swirl distortion
          vec2 swirlDistortion(vec2 uv, vec2 center, float angle) {
              vec2 tc = uv - center;
              float dist = length(tc);
              float theta = atan(tc.y, tc.x);
              theta += angle * (1.0 - dist);
              return center + dist * vec2(cos(theta), sin(theta));
          }
          
          // Lens distortion (barrel/pincushion)
          vec2 lensDistortion(vec2 uv, float k) {
              vec2 center = vec2(0.5);
              vec2 tc = uv - center;
              float r2 = dot(tc, tc);
              float f = 1.0 + r2 * k;
              return center + tc * f;
          }
          
          // Pixelation
          vec2 pixelate(vec2 uv, float pixelSize) {
              return floor(uv / pixelSize) * pixelSize + pixelSize * 0.5;
          }
          GLSL
        end
        
        # Common includes for different effect types
        def self.for_color_effects : String
          "#{noise_functions}\n#{color_functions}\n#{easing_functions}"
        end
        
        def self.for_distortion_effects : String
          "#{distortion_functions}\n#{easing_functions}"
        end
        
        def self.for_transition_effects : String
          "#{shape_functions}\n#{easing_functions}\n#{noise_functions}"
        end
        
        def self.for_particle_effects : String
          "#{noise_functions}\n#{easing_functions}"
        end
      end
    end
  end
end