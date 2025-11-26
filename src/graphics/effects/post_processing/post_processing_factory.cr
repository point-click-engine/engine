# Factory for creating post-processing effects
#
# Provides a unified interface for creating advanced
# shader-based post-processing effects.

require "./blur_shader"
require "./distortion_shader"
require "./glow_shader"

module PointClickEngine
  module Graphics
    module Effects
      module PostProcessing
        # Factory for creating post-processing effects
        module PostProcessingFactory
          # Check if OpenGL context is available for post-processing effects
          def self.available? : Bool
            ShaderEffect.gl_context_available?
          end

          # Create a post-processing effect by name
          # Returns nil if GL context not available
          def self.create(effect_name : String, **params) : ShaderEffect?
            # Skip if no GL context
            return nil unless available?

            effect = case effect_name.downcase
            # Blur effects
            when "blur", "gaussian_blur"
              create_blur(BlurType::Gaussian, **params)
            when "box_blur"
              create_blur(BlurType::Box, **params)
            when "motion_blur"
              create_blur(BlurType::Motion, **params)
            when "radial_blur", "zoom_blur"
              create_blur(BlurType::Radial, **params)

            # Distortion effects
            when "heat_haze", "heat"
              create_distortion(DistortionType::HeatHaze, **params)
            when "shock_wave", "shockwave"
              create_distortion(DistortionType::ShockWave, **params)
            when "lens_distortion", "barrel", "pincushion"
              create_distortion(DistortionType::Lens, **params)
            when "ripple", "water_ripple"
              create_distortion(DistortionType::Ripple, **params)

            # Glow effects
            when "glow", "bloom"
              create_glow(GlowMode::Simple, **params)
            when "adaptive_glow", "hdr_glow"
              create_glow(GlowMode::Adaptive, **params)
            when "selective_glow", "color_glow"
              create_glow(GlowMode::Selective, **params)
            when "lens_glow", "lens_flare"
              create_glow(GlowMode::Lens, **params)

            else
              nil
            end

            # Return nil if shader failed to load
            if effect && !effect.shader_available
              return nil
            end

            effect
          end
          
          # Create blur effect
          private def self.create_blur(blur_type : BlurType, **params) : BlurShader
            radius = Effects.to_float(params[:radius]?, 5.0f32)
            duration = Effects.to_float(params[:duration]?, 0.0f32)
            
            effect = BlurShader.new(blur_type, radius, duration)
            
            # Common blur parameters
            effect.blur_quality = params[:quality]?.try(&.as(Number).to_i32) || 4
            
            # Motion blur specific
            if blur_type.motion?
              effect.motion_angle = Effects.to_float(params[:angle]?, 0.0f32)
              effect.motion_strength = Effects.to_float(params[:strength]?, 0.02f32)
            end
            
            # Radial blur specific
            if blur_type.radial?
              if center = parse_vector2(params[:center]?)
                effect.radial_center = normalize_vector2(center)
              end
              effect.radial_zoom = params[:zoom]? != false
            end
            
            effect
          end
          
          # Create distortion effect
          private def self.create_distortion(distortion_type : DistortionType, **params) : DistortionShader
            strength = Effects.to_float(params[:strength]?, 0.01f32)
            duration = Effects.to_float(params[:duration]?, 0.0f32)
            
            effect = DistortionShader.new(distortion_type, strength, duration)
            
            # Common distortion parameters
            effect.frequency = Effects.to_float(params[:frequency]?, 10.0f32)
            effect.speed = Effects.to_float(params[:speed]?, 1.0f32)
            
            # Heat haze specific
            if distortion_type.heat_haze?
              effect.heat_layers = params[:layers]?.try(&.as(Number).to_i32) || 3
              effect.heat_vertical_speed = Effects.to_float(params[:vertical_speed]?, 2.0f32)
            end
            
            # Shock wave specific
            if distortion_type.shock_wave?
              if center = parse_vector2(params[:center]?)
                effect.shock_center = normalize_vector2(center)
              end
              effect.shock_radius = Effects.to_float(params[:radius]?, 0.0f32)
              effect.shock_thickness = Effects.to_float(params[:thickness]?, 0.1f32)
              effect.shock_force = Effects.to_float(params[:force]?, 0.05f32)
            end
            
            # Lens distortion specific
            if distortion_type.lens?
              effect.lens_k1 = params[:k1]?.try(&.as(Number).to_f32) || 0.2f32
              effect.lens_k2 = params[:k2]?.try(&.as(Number).to_f32) || 0.0f32
              if center = parse_vector2(params[:center]?)
                effect.lens_center = normalize_vector2(center)
              end
            end
            
            # Ripple specific
            if distortion_type.ripple?
              if center = parse_vector2(params[:center]?)
                effect.ripple_center = normalize_vector2(center)
              end
              effect.ripple_wavelength = Effects.to_float(params[:wavelength]?, 0.05f32)
              effect.ripple_amplitude = Effects.to_float(params[:amplitude]?, 0.01f32)
              effect.ripple_decay = Effects.to_float(params[:decay]?, 0.5f32)
            end
            
            effect
          end
          
          # Create glow effect
          private def self.create_glow(glow_mode : GlowMode, **params) : GlowShader
            threshold = Effects.to_float(params[:threshold]?, 0.8f32)
            duration = Effects.to_float(params[:duration]?, 0.0f32)
            
            effect = GlowShader.new(glow_mode, threshold, duration)
            
            # Common glow parameters
            effect.intensity = Effects.to_float(params[:intensity]?, 1.0f32)
            effect.blur_passes = params[:blur_passes]?.try(&.as(Number).to_i32) || 3
            effect.blur_scale = Effects.to_float(params[:blur_scale]?, 1.0f32)
            
            if color = parse_color(params[:tint]?)
              effect.tint_color = color
            end
            
            # Selective glow specific
            if glow_mode.selective?
              if color = parse_color(params[:select_color]?)
                effect.select_color = color
              end
              effect.select_tolerance = Effects.to_float(params[:tolerance]?, 0.1f32)
            end
            
            # Lens glow specific
            if glow_mode.lens?
              effect.lens_dispersion = Effects.to_float(params[:dispersion]?, 0.3f32)
              effect.lens_halo_width = Effects.to_float(params[:halo_width]?, 0.5f32)
            end
            
            effect
          end
          
          # Helper to parse vector2 from various formats
          private def self.parse_vector2(value) : RL::Vector2?
            case value
            when Array
              if value.size >= 2
                RL::Vector2.new(
                  x: value[0].as(Number).to_f32,
                  y: value[1].as(Number).to_f32
                )
              else
                nil
              end
            when Hash
              x = value["x"]?.try(&.as(Number).to_f32) || 0.0f32
              y = value["y"]?.try(&.as(Number).to_f32) || 0.0f32
              RL::Vector2.new(x: x, y: y)
            when String
              case value.downcase
              when "center" then RL::Vector2.new(x: 0.5f32, y: 0.5f32)
              when "mouse"  then nil # Would need mouse position
              else nil
              end
            else
              nil
            end
          end
          
          # Normalize pixel coordinates to UV coordinates
          private def self.normalize_vector2(vec : RL::Vector2) : RL::Vector2
            if vec.x > 1.0f32 || vec.y > 1.0f32
              # Assume pixel coordinates, normalize
              RL::Vector2.new(
                x: vec.x / Display::REFERENCE_WIDTH.to_f32,
                y: vec.y / Display::REFERENCE_HEIGHT.to_f32
              )
            else
              # Already normalized
              vec
            end
          end
          
          # Helper to parse color
          private def self.parse_color(color_value) : RL::Color?
            case color_value
            when RL::Color
              color_value
            when String
              case color_value.downcase
              when "white"  then RL::WHITE
              when "black"  then RL::BLACK
              when "red"    then RL::RED
              when "green"  then RL::GREEN
              when "blue"   then RL::BLUE
              when "yellow" then RL::YELLOW
              when "purple" then RL::PURPLE
              when "orange" then RL::ORANGE
              else
                # Try to parse hex color
                if color_value.starts_with?("#")
                  parse_hex_color(color_value)
                else
                  nil
                end
              end
            when Array
              if color_value.size >= 3
                RL::Color.new(
                  r: color_value[0].to_i.to_u8,
                  g: color_value[1].to_i.to_u8,
                  b: color_value[2].to_i.to_u8,
                  a: (color_value[3]?.try(&.to_i) || 255).to_u8
                )
              else
                nil
              end
            else
              nil
            end
          end
          
          private def self.parse_hex_color(hex : String) : RL::Color?
            hex = hex.lstrip('#')
            
            return nil unless hex.size == 6 || hex.size == 8
            
            r = hex[0..1].to_i(16).to_u8
            g = hex[2..3].to_i(16).to_u8
            b = hex[4..5].to_i(16).to_u8
            a = hex.size == 8 ? hex[6..7].to_i(16).to_u8 : 255_u8
            
            RL::Color.new(r: r, g: g, b: b, a: a)
          rescue
            nil
          end
        end
      end
    end
  end
end