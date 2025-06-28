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
          # Create a shader-based object effect by name
          def self.create(effect_name : String, **params) : Effect?
            case effect_name.downcase
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
          end
          
          # Create highlight effect
          private def self.create_highlight(**params) : HighlightShader
            type = case params[:type]?.try(&.to_s)
                   when "outline" then HighlightMode::Outline
                   when "glow"    then HighlightMode::Glow
                   when "rim"     then HighlightMode::RimLight
                   else HighlightMode::Glow
                   end
            
            color = ObjectEffects.parse_color(params[:color]?) || RL::YELLOW
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = HighlightShader.new(type, color, duration)
            effect.thickness = params[:thickness]?.try(&.as(Number).to_f32) || 2.0f32
            effect.intensity = params[:intensity]?.try(&.as(Number).to_f32) || 1.0f32
            effect.softness = params[:softness]?.try(&.as(Number).to_f32) || 0.5f32
            
            effect
          end
          
          # Create dissolve effect
          private def self.create_dissolve(**params) : DissolveShader
            mode = params[:mode]?.try(&.to_s) == "in" ? DissolveMode::In : DissolveMode::Out
            duration = params[:duration]?.try(&.as(Number).to_f32) || 1.0f32
            
            effect = DissolveShader.new(mode, duration)
            
            if edge_color = ObjectEffects.parse_color(params[:edge_color]?)
              effect.edge_color = edge_color
            end
            
            effect.edge_thickness = params[:edge_thickness]?.try(&.as(Number).to_f32) || 0.05f32
            effect.noise_scale = params[:noise_scale]?.try(&.as(Number).to_f32) || 10.0f32
            
            effect
          end
          
          # Create shake effect
          private def self.create_shake(**params) : ShakeShader
            amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 5.0f32
            frequency = params[:frequency]?.try(&.as(Number).to_f32) || 10.0f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.5f32
            
            effect = ShakeShader.new(amplitude, frequency, duration)
            
            effect.shake_mode = case params[:direction]?.try(&.to_s)
                                when "horizontal" then ShakeMode::Horizontal
                                when "vertical"   then ShakeMode::Vertical
                                when "rotation"   then ShakeMode::Rotation
                                else ShakeMode::Both
                                end
            
            effect.decay_enabled = params[:decay]? != false
            effect.chromatic_aberration = params[:chromatic]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect
          end
          
          # Create pulse effect
          private def self.create_pulse(**params) : PulseShader
            scale_amount = params[:scale_amount]?.try(&.as(Number).to_f32) || 0.1f32
            speed = params[:speed]?.try(&.as(Number).to_f32) || 2.0f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = PulseShader.new(scale_amount, speed, duration)
            
            effect.pulse_mode = case params[:mode]?.try(&.to_s)
                                when "heartbeat" then PulseMode::Heartbeat
                                when "bounce"    then PulseMode::Bounce
                                else PulseMode::Breathe
                                end
            
            effect.glow_enabled = params[:glow]? == true
            effect.glow_intensity = params[:glow_intensity]?.try(&.as(Number).to_f32) || 0.5f32
            
            effect
          end
          
          # Create color shift effect
          private def self.create_color_shift(effect_name : String, **params) : ColorShiftShader
            mode = case params[:mode]?.try(&.to_s) || effect_name
                   when "flash"              then ColorMode::Flash
                   when "rainbow"            then ColorMode::Rainbow
                   when "grayscale", "gray"  then ColorMode::Grayscale
                   when "sepia"              then ColorMode::Sepia
                   else ColorMode::Tint
                   end
            
            color = ObjectEffects.parse_color(params[:color]?)
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = ColorShiftShader.new(mode, color, duration)
            effect.speed = params[:speed]?.try(&.as(Number).to_f32) || 1.0f32
            effect.intensity = params[:intensity]?.try(&.as(Number).to_f32) || 1.0f32
            
            effect
          end
          
          # Create float effect
          private def self.create_float(**params) : FloatShader
            amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 10.0f32
            speed = params[:speed]?.try(&.as(Number).to_f32) || 1.0f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = FloatShader.new(amplitude, speed, duration)
            
            # Configure float mode
            effect.float_mode = if params[:sway_amplitude]? || params[:sway]?
                                  FloatMode::Sway
                                elsif params[:orbit]?
                                  FloatMode::Orbit
                                elsif params[:figure8]?
                                  FloatMode::Figure8
                                else
                                  FloatMode::Simple
                                end
            
            effect.phase_offset = params[:phase]?.try(&.as(Number).to_f32) || 0.0f32
            effect.rotation_enabled = params[:rotation]? == true
            effect.rotation_speed = params[:rotation_speed]?.try(&.as(Number).to_f32) || 1.0f32
            
            if effect.float_mode.sway?
              effect.horizontal_amplitude = params[:sway_amplitude]?.try(&.as(Number).to_f32) || 5.0f32
              effect.horizontal_speed = params[:sway_speed]?.try(&.as(Number).to_f32) || 0.7f32
            end
            
            effect
          end
        end
      end
    end
  end
end