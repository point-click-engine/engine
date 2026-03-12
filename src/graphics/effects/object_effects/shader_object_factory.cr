# Factory for creating shader-based object effects
#
# This factory creates shader-based versions of object effects
# for better performance and visual quality.

require "./shader/color_shift_shader"
require "./shader/dissolve_shader"
require "./shader/float_shader"
require "./shader/highlight_shader"
require "./shader/pulse_shader"
require "./shader/shake_shader"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Factory for shader-based object effects
        module ShaderObjectFactory
          # Helper to safely extract Float32 from parameter
          private def self.to_float(value, default : Float32) : Float32
            case value
            when Float32 then value
            when Float64 then value.to_f32
            when Int32   then value.to_f32
            when Int64   then value.to_f32
            else default
            end
          end

          # Check if OpenGL context is available for shader effects
          def self.available? : Bool
            ShaderEffect.gl_context_available?
          end

          # Create a shader-based object effect by name
          # Returns nil if GL context not available (allows fallback to CPU effects)
          def self.create(effect_name : String, **params) : Effect?
            # Skip shader effects if no GL context
            return nil unless available?

            effect = case effect_name.downcase
            when "highlight", "glow"
              create_highlight(**params)
            when "dissolve"
              create_dissolve(**params)
            when "shake"
              create_shake(**params)
            when "pulse", "breathe"
              create_pulse(**params)
            when "tint", "flash", "color", "color_shift"
              create_color_shift(effect_name, **params)
            when "float", "hover"
              create_float(**params)
            else
              # Fall back to non-shader version if no shader implementation
              nil
            end

            # Return nil if shader failed to load (allows CPU fallback)
            if effect.is_a?(ShaderEffect) && !effect.shader_available
              return nil
            end

            effect
          end
          
          # Create highlight effect
          private def self.create_highlight(**params) : HighlightShader
            type = case params[:type]?.try(&.to_s)
                   when "outline" then HighlightStyle::Outline
                   when "glow"    then HighlightStyle::Glow
                   when "rim"     then HighlightStyle::RimLight
                   else HighlightStyle::Glow
                   end

            color = ObjectEffects.parse_color(params[:color]?) || RL::YELLOW
            duration = to_float(params[:duration]?, 0.0f32)

            effect = HighlightShader.new(type, color, duration)
            effect.thickness = to_float(params[:thickness]?, 2.0f32)
            effect.glow_intensity = to_float(params[:intensity]?, 1.0f32)

            effect
          end
          
          # Create dissolve effect
          private def self.create_dissolve(**params) : DissolveShader
            pattern = case params[:pattern]?.try(&.to_s)
                      when "circular" then DissolvePattern::Circular
                      when "linear"   then DissolvePattern::Linear
                      when "diamond"  then DissolvePattern::Diamond
                      when "spiral"   then DissolvePattern::Spiral
                      else DissolvePattern::Noise
                      end
            mode = params[:mode]?.try(&.to_s) == "in" ? DissolveMode::In : DissolveMode::Out
            duration = to_float(params[:duration]?, 1.0f32)

            effect = DissolveShader.new(pattern, mode, duration)

            if edge_color = ObjectEffects.parse_color(params[:edge_color]?)
              effect.edge_color = edge_color
            end

            effect.edge_width = to_float(params[:edge_thickness]?, 0.05f32)
            effect.noise_scale = to_float(params[:noise_scale]?, 10.0f32)

            effect
          end
          
          # Create shake effect
          private def self.create_shake(**params) : ShakeShader
            pattern = case params[:direction]?.try(&.to_s)
                      when "directional" then ShakePattern::Directional
                      when "rotational"  then ShakePattern::Rotational
                      when "vibrate"     then ShakePattern::Vibrate
                      when "impact"      then ShakePattern::Impact
                      else ShakePattern::Random
                      end
            amplitude = to_float(params[:amplitude]?, 5.0f32)
            frequency = to_float(params[:frequency]?, 30.0f32)
            duration = to_float(params[:duration]?, 0.5f32)

            effect = ShakeShader.new(pattern, amplitude, frequency, duration)
            effect.decay_rate = to_float(params[:decay_rate]?, 2.0f32)

            effect
          end

          # Create pulse effect
          private def self.create_pulse(**params) : PulseShader
            pattern = case params[:mode]?.try(&.to_s)
                      when "heartbeat" then PulsePattern::Heartbeat
                      when "bounce"    then PulsePattern::Bounce
                      when "breathe"   then PulsePattern::Breathe
                      when "alert"     then PulsePattern::Alert
                      else PulsePattern::Sine
                      end
            scale_amount = to_float(params[:scale_amount]?, 0.1f32)
            speed = to_float(params[:speed]?, 2.0f32)
            duration = to_float(params[:duration]?, 0.0f32)

            PulseShader.new(pattern, scale_amount, speed, duration)
          end

          # Create color shift effect
          private def self.create_color_shift(effect_name : String, **params) : ColorShiftShader
            mode = case params[:mode]?.try(&.to_s) || effect_name
                   when "flash"              then ColorShiftMode::Flash
                   when "rainbow"            then ColorShiftMode::Rainbow
                   when "grayscale", "gray"  then ColorShiftMode::Grayscale
                   when "sepia"              then ColorShiftMode::Sepia
                   when "negative"           then ColorShiftMode::Negative
                   else ColorShiftMode::Tint
                   end

            color = ObjectEffects.parse_color(params[:color]?) || RL::WHITE
            duration = to_float(params[:duration]?, 0.0f32)

            effect = ColorShiftShader.new(mode, color, duration)
            effect.flash_speed = to_float(params[:speed]?, 4.0f32)

            effect
          end

          # Create float effect
          private def self.create_float(**params) : FloatShader
            pattern = case params[:pattern]?.try(&.to_s)
                      when "circular" then FloatPattern::Circular
                      when "figure8"  then FloatPattern::Figure8
                      when "random"   then FloatPattern::Random
                      when "hover"    then FloatPattern::Hover
                      else FloatPattern::Sine
                      end
            amplitude_x = to_float(params[:amplitude_x]?, 0.0f32)
            amplitude_y = to_float(params[:amplitude]?, 10.0f32)
            frequency = to_float(params[:speed]?, 2.0f32)
            duration = to_float(params[:duration]?, 0.0f32)

            effect = FloatShader.new(pattern, amplitude_x, amplitude_y, frequency, duration)
            effect.phase_offset = to_float(params[:phase]?, 0.0f32)

            effect
          end
        end
      end
    end
  end
end