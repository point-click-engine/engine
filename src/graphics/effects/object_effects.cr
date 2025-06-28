# Object effects module - visual effects for game objects

require "./object_effects/highlight"
require "./object_effects/dissolve"
require "./object_effects/shake"
require "./object_effects/pulse"
require "./object_effects/color_shift"
require "./object_effects/float"
require "./particle_effect"
require "./object_effects/shader_object_factory"

module PointClickEngine
  module Graphics
    module Effects
      # Object effects for sprites and game objects
      module ObjectEffects
        # Factory method to create effects by name
        def self.create(effect_name : String, **params) : Effect?
          # Try shader version first for better performance
          if shader_effect = ShaderObjectFactory.create(effect_name, **params)
            return shader_effect
          end
          
          # Fall back to CPU-based effects
          case effect_name.downcase
          when "highlight", "glow"
            type = params[:type]?.try(&.to_s) || "glow"
            highlight_type = case type
                             when "outline" then HighlightEffect::HighlightType::Outline
                             when "overlay" then HighlightEffect::HighlightType::ColorOverlay
                             when "pulse"   then HighlightEffect::HighlightType::Pulse
                             else                HighlightEffect::HighlightType::Glow
                             end

            color = parse_color(params[:color]?) || RL::YELLOW
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

            effect = HighlightEffect.new(highlight_type, color, duration)
            effect.thickness = params[:thickness]?.try(&.as(Number).to_f32) || 2.0f32
            effect.radius = params[:radius]?.try(&.as(Number).to_f32) || 10.0f32
            effect
          when "dissolve"
            mode = params[:mode]?.try(&.to_s) == "in" ? DissolveEffect::DissolveMode::In : DissolveEffect::DissolveMode::Out
            duration = params[:duration]?.try(&.as(Number).to_f32) || 1.0f32

            effect = DissolveEffect.new(mode, duration)
            if pattern = params[:pattern]?.try(&.to_s)
              effect.pattern = case pattern
                               when "noise"     then DissolveEffect::DissolvePattern::Noise
                               when "pixelate"  then DissolveEffect::DissolvePattern::Pixelate
                               when "particles" then DissolveEffect::DissolvePattern::Particles
                               else                  DissolveEffect::DissolvePattern::Alpha
                               end
            end
            effect.particle_count = params[:particle_count]?.try(&.as(Number).to_i) || 20
            effect.particle_color = parse_color(params[:particle_color]?)
            effect
          when "shake"
            amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 5.0f32
            frequency = params[:frequency]?.try(&.as(Number).to_f32) || 10.0f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.5f32

            effect = ShakeEffect.new(amplitude, frequency, duration)
            effect.decay = params[:decay]? != false
            if direction = params[:direction]?.try(&.to_s)
              effect.direction = case direction
                                 when "horizontal" then ShakeEffect::ShakeDirection::Horizontal
                                 when "vertical"   then ShakeEffect::ShakeDirection::Vertical
                                 else                   ShakeEffect::ShakeDirection::Both
                                 end
            end
            effect
          when "pulse", "breathe"
            scale_amount = params[:scale_amount]?.try(&.as(Number).to_f32) || 0.1f32
            speed = params[:speed]?.try(&.as(Number).to_f32) || 2.0f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

            effect = PulseEffect.new(scale_amount, speed, duration)
            if easing = params[:easing]?.try(&.to_s)
              effect.easing = case easing
                              when "linear" then PulseEffect::EasingType::Linear
                              when "quad"   then PulseEffect::EasingType::Quad
                              when "bounce" then PulseEffect::EasingType::Bounce
                              else               PulseEffect::EasingType::Sine
                              end
            end
            effect
          when "tint", "flash", "color", "color_shift"
            mode = case params[:mode]?.try(&.to_s) || effect_name
                   when "flash"              then ColorShiftEffect::ColorMode::Flash
                   when "rainbow"            then ColorShiftEffect::ColorMode::Rainbow
                   when "grayscale", "gray"  then ColorShiftEffect::ColorMode::Grayscale
                   when "sepia"              then ColorShiftEffect::ColorMode::Sepia
                   when "negative", "invert" then ColorShiftEffect::ColorMode::Negative
                   else                           ColorShiftEffect::ColorMode::Tint
                   end

            color = parse_color(params[:color]?)
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

            effect = ColorShiftEffect.new(mode, color, duration)
            effect.speed = params[:speed]?.try(&.as(Number).to_f32) || 1.0f32
            effect
          when "float", "hover"
            amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 10.0f32
            speed = params[:speed]?.try(&.as(Number).to_f32) || 1.0f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

            # Use sway variant if sway parameters present
            if params[:sway_amplitude]? || params[:sway]?
              effect = SwayFloatEffect.new(amplitude, speed, duration)
              effect.sway_amplitude = params[:sway_amplitude]?.try(&.as(Number).to_f32) || 5.0f32
              effect.sway_speed = params[:sway_speed]?.try(&.as(Number).to_f32) || 0.7f32
            else
              effect = FloatEffect.new(amplitude, speed, duration)
            end

            effect.phase = params[:phase]?.try(&.as(Number).to_f32) || 0.0f32
            effect.rotation = params[:rotation]? == true
            effect.rotation_amount = params[:rotation_amount]?.try(&.as(Number).to_f32) || 5.0f32
            effect
          when "particle", "particles"
            # Delegate to particle effect factory
            create_particle(params[:type]?.try(&.to_s) || "sparkles", **params)
          else
            nil
          end
        end

        # Helper to parse color from various formats
        def self.parse_color(color_value) : RL::Color?
          case color_value
          when RL::Color
            color_value
          when Array
            # Array of [r, g, b] or [r, g, b, a]
            if color_value.size >= 3
              RL::Color.new(
                r: color_value[0].as(Number).to_u8,
                g: color_value[1].as(Number).to_u8,
                b: color_value[2].as(Number).to_u8,
                a: color_value[3]?.try(&.as(Number).to_u8) || 255_u8
              )
            end
          when String
            # Named colors
            case color_value.downcase
            when "white"        then RL::WHITE
            when "black"        then RL::BLACK
            when "red"          then RL::RED
            when "green"        then RL::GREEN
            when "blue"         then RL::BLUE
            when "yellow"       then RL::YELLOW
            when "orange"       then RL::ORANGE
            when "purple"       then RL::PURPLE
            when "pink"         then RL::PINK
            when "gray", "grey" then RL::GRAY
            else
              # Try hex color (#RRGGBB or #RRGGBBAA)
              if color_value.starts_with?("#")
                hex = color_value[1..]
                if hex.size >= 6
                  r = hex[0..1].to_i(16).to_u8
                  g = hex[2..3].to_i(16).to_u8
                  b = hex[4..5].to_i(16).to_u8
                  a = hex.size >= 8 ? hex[6..7].to_i(16).to_u8 : 255_u8
                  RL::Color.new(r: r, g: g, b: b, a: a)
                end
              end
            end
          else
            nil
          end
        end
      end
    end
  end
end
