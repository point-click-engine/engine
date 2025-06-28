# Factory for creating scene effects
#
# Provides a unified interface for creating both shader-based
# and traditional scene effects.

require "./base_scene_effect"
require "./transition_effect"
require "./shader/fog_shader"
require "./shader/rain_shader"
require "./shader/darkness_shader"
require "./shader/underwater_shader"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Factory for creating scene effects
        module SceneEffectFactory
          # Create a scene effect by name
          def self.create(effect_name : String, **params) : BaseSceneEffect?
            case effect_name.downcase
            when "transition"
              create_transition(**params)
              
            # Atmospheric effects (shader-based)
            when "fog"
              create_fog(**params)
            when "rain"
              create_rain(**params)
            when "snow"
              create_snow(**params)
            when "darkness", "vignette"
              create_darkness(**params)
            when "underwater"
              create_underwater(**params)
              
            # Environmental effects
            when "heat_haze"
              create_heat_haze(**params)
            when "wind"
              create_wind(**params)
              
            # Camera-style effects
            when "shake", "screen_shake"
              create_screen_shake(**params)
            when "flash"
              create_flash(**params)
              
            else
              nil
            end
          end
          
          # Create transition effect (already implemented)
          private def self.create_transition(**params) : TransitionEffect?
            type_name = params[:type]?.try(&.to_s) || "fade"
            transition_type = parse_transition_type(type_name)
            
            duration = params[:duration]?.try(&.as(Number).to_f32) || 1.0f32
            reverse = params[:reverse]?.try(&.as(Bool)) || false
            
            TransitionEffect.new(transition_type, duration, reverse)
          end
          
          # Create fog effect
          private def self.create_fog(**params) : FogShader?
            fog_type = case params[:type]?.try(&.to_s)
            when "linear"      then FogType::Linear
            when "exponential" then FogType::Exponential
            when "layered"     then FogType::Layered
            when "volumetric"  then FogType::Volumetric
            else FogType::Linear
            end
            
            color = parse_color(params[:color]?) || RL::Color.new(r: 128, g: 128, b: 150, a: 200)
            density = params[:density]?.try(&.as(Number).to_f32) || 0.02f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = FogShader.new(fog_type, color, density, duration)
            
            # Set additional parameters if provided
            if fog_start = params[:start]?.try(&.as(Number).to_f32)
              effect.fog_start = fog_start
            end
            if fog_end = params[:end]?.try(&.as(Number).to_f32)
              effect.fog_end = fog_end
            end
            
            effect
          end
          
          # Create rain effect
          private def self.create_rain(**params) : RainShader?
            intensity = case params[:intensity]?.try(&.to_s)
            when "light"  then RainIntensity::Light
            when "medium" then RainIntensity::Medium
            when "heavy"  then RainIntensity::Heavy
            when "storm"  then RainIntensity::Storm
            else RainIntensity::Medium
            end
            
            wind = params[:wind]?.try(&.as(Number).to_f32) || 0.2f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = RainShader.new(intensity, wind, duration)
            
            if color = parse_color(params[:color]?)
              effect.rain_color = color
            end
            
            effect.splash_enabled = params[:splashes]?.try(&.as(Bool)) != false
            
            effect
          end
          
          # Create darkness/vignette effect
          private def self.create_darkness(**params) : DarknessShader?
            darkness_type = case params[:type]?.try(&.to_s)
            when "vignette"   then DarknessType::Vignette
            when "gradient"   then DarknessType::Gradient
            when "spotlight"  then DarknessType::Spotlight
            when "multilight" then DarknessType::MultiLight
            else DarknessType::Vignette
            end
            
            intensity = params[:intensity]?.try(&.as(Number).to_f32) || 0.8f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = DarknessShader.new(darkness_type, intensity, duration)
            
            if color = parse_color(params[:color]?)
              effect.darkness_color = color
            end
            
            # Set radii for vignette/spotlight
            if inner = params[:inner_radius]?.try(&.as(Number).to_f32)
              effect.inner_radius = inner
            end
            if outer = params[:outer_radius]?.try(&.as(Number).to_f32)
              effect.outer_radius = outer
            end
            
            effect
          end
          
          # Create underwater effect
          private def self.create_underwater(**params) : UnderwaterShader?
            quality = case params[:quality]?.try(&.to_s)
            when "low"    then UnderwaterQuality::Low
            when "medium" then UnderwaterQuality::Medium
            when "high"   then UnderwaterQuality::High
            else UnderwaterQuality::Medium
            end
            
            color = parse_color(params[:color]?) || RL::Color.new(r: 0, g: 80, b: 120, a: 100)
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
            
            effect = UnderwaterShader.new(quality, color, duration)
            
            # Set wave parameters
            if amplitude = params[:wave_amplitude]?.try(&.as(Number).to_f32)
              effect.wave_amplitude = amplitude
            end
            if frequency = params[:wave_frequency]?.try(&.as(Number).to_f32)
              effect.wave_frequency = frequency
            end
            if speed = params[:wave_speed]?.try(&.as(Number).to_f32)
              effect.wave_speed = speed
            end
            
            effect
          end
          
          # Placeholder implementations for effects not yet migrated
          private def self.create_snow(**params) : BaseSceneEffect?
            # TODO: Implement snow shader
            nil
          end
          
          private def self.create_heat_haze(**params) : BaseSceneEffect?
            # TODO: Implement heat haze shader
            nil
          end
          
          private def self.create_wind(**params) : BaseSceneEffect?
            # TODO: Implement wind particle shader
            nil
          end
          
          private def self.create_screen_shake(**params) : BaseSceneEffect?
            # This might reuse the existing SceneShakeEffect
            amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 10.0f32
            frequency = params[:frequency]?.try(&.as(Number).to_f32) || 10.0f32
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.5f32
            
            SceneShakeEffect.new(amplitude, frequency, duration)
          end
          
          private def self.create_flash(**params) : BaseSceneEffect?
            # Create a color overlay effect
            color = parse_color(params[:color]?) || RL::WHITE
            duration = params[:duration]?.try(&.as(Number).to_f32) || 0.2f32
            
            SceneColorEffect.new(
              ObjectEffects::ColorShiftEffect::ColorMode::Flash,
              color,
              duration
            )
          end
          
          # Helper to parse transition type
          private def self.parse_transition_type(type_name : String) : TransitionType
            case type_name.downcase
            when "fade"         then TransitionType::Fade
            when "dissolve"     then TransitionType::Dissolve
            when "slide_left"   then TransitionType::SlideLeft
            when "slide_right"  then TransitionType::SlideRight
            when "slide_up"     then TransitionType::SlideUp
            when "slide_down"   then TransitionType::SlideDown
            when "iris"         then TransitionType::Iris
            when "swirl"        then TransitionType::Swirl
            when "star_wipe"    then TransitionType::StarWipe
            when "heart_wipe"   then TransitionType::HeartWipe
            when "curtain"      then TransitionType::Curtain
            when "checkerboard" then TransitionType::Checkerboard
            when "clock_wipe"   then TransitionType::ClockWipe
            when "barn_door"    then TransitionType::BarnDoor
            else TransitionType::Fade
            end
          end
          
          # Helper to parse color
          private def self.parse_color(color_value) : RL::Color?
            case color_value
            when RL::Color
              color_value
            when String
              case color_value.downcase
              when "black"  then RL::BLACK
              when "white"  then RL::WHITE
              when "red"    then RL::RED
              when "green"  then RL::GREEN
              when "blue"   then RL::BLUE
              when "yellow" then RL::YELLOW
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