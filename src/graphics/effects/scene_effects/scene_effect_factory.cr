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
        # Factory for creating shader-based scene effects
        module ShaderSceneEffectFactory
          # Check if OpenGL context is available for shader effects
          def self.available? : Bool
            ShaderEffect.gl_context_available?
          end

          # Create effect from YAML parameters (consolidates all effect creation logic)
          def self.create_from_yaml(effect_type : String, params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : BaseSceneEffect?
            # Map fog_type to type for fog effects
            if effect_type == "fog" && params.has_key?("fog_type") && !params.has_key?("type")
              params["type"] = params["fog_type"]
            end

            # Let each create method handle its own parameters
            effect = case effect_type.downcase
            when "fog"
              create_fog_from_hash(params)
            when "rain"
              create_rain_from_hash(params)
            when "darkness", "vignette"
              create_darkness_from_hash(params)
            when "underwater"
              create_underwater_from_hash(params)
            when "simple_rain"
              create_simple_rain_from_hash(params)
            when "test_overlay"
              create_test_overlay_from_hash(params)
            else
              nil
            end

            # Return nil if shader effect failed to load
            if effect.is_a?(ShaderSceneEffect) && !effect.shader_available
              return nil
            end

            effect
          end

          # Create a scene effect by name
          def self.create(effect_name : String, **params) : BaseSceneEffect?
            effect = case effect_name.downcase
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

            # Return nil if shader effect failed to load
            if effect.is_a?(ShaderSceneEffect) && !effect.shader_available
              return nil
            end

            effect
          end
          
          # Create transition effect (already implemented)
          private def self.create_transition(**params) : TransitionEffect?
            type_name = params[:type]?.try(&.to_s) || "fade"
            transition_type = parse_transition_type(type_name)
            
            duration = Effects.to_float(params[:duration]?, 1.0f32)
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
            density = Effects.to_float(params[:density]?, 0.02f32)
            duration = Effects.to_float(params[:duration]?, 0.0f32)
            
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
            
            wind = Effects.to_float(params[:wind]?, 0.2f32)
            duration = Effects.to_float(params[:duration]?, 0.0f32)
            
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
            
            intensity = Effects.to_float(params[:intensity]?, 0.8f32)
            duration = Effects.to_float(params[:duration]?, 0.0f32)
            
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
            duration = Effects.to_float(params[:duration]?, 0.0f32)
            
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
            # Heat haze is available as a post-processing effect
            # Use: PostProcessing.create("heat_haze", strength: 0.02, frequency: 8.0)
            nil
          end
          
          private def self.create_wind(**params) : BaseSceneEffect?
            # TODO: Implement wind particle shader
            nil
          end
          
          private def self.create_screen_shake(**params) : BaseSceneEffect?
            # This might reuse the existing SceneShakeEffect
            amplitude = Effects.to_float(params[:amplitude]?, 10.0f32)
            frequency = Effects.to_float(params[:frequency]?, 10.0f32)
            duration = Effects.to_float(params[:duration]?, 0.5f32)
            
            SceneShakeEffect.new(amplitude, frequency, duration)
          end
          
          private def self.create_flash(**params) : BaseSceneEffect?
            # Create a color overlay effect
            color = parse_color(params[:color]?) || RL::WHITE
            duration = Effects.to_float(params[:duration]?, 0.2f32)
            
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
          
          # Create fog from hash (for YAML loading)
          private def self.create_fog_from_hash(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : FogShader?
            fog_type = case params["type"]?.try(&.to_s) || params["fog_type"]?.try(&.to_s)
            when "linear"      then FogType::Linear
            when "exponential" then FogType::Exponential
            when "layered"     then FogType::Layered
            when "volumetric"  then FogType::Volumetric
            else FogType::Linear
            end
            
            color = if color_array = params["color"]?.as?(Array(Int32))
              RL::Color.new(
                r: color_array[0].to_u8,
                g: color_array[1].to_u8,
                b: color_array[2].to_u8,
                a: (color_array[3]? || 255).to_u8
              )
            else
              RL::Color.new(r: 128, g: 128, b: 150, a: 200)
            end
            
            density = params["density"]?.as?(Float32) || 0.02f32
            duration = params["duration"]?.as?(Float32) || 0.0f32
            
            effect = FogShader.new(fog_type, color, density, duration)
            
            if fog_start = params["start"]?.as?(Float32)
              effect.fog_start = fog_start
            end
            if fog_end = params["end"]?.as?(Float32)
              effect.fog_end = fog_end
            end
            if height_falloff = params["height_falloff"]?.as?(Float32)
              effect.height_falloff = height_falloff
            end
            
            effect
          end
          
          # Create rain from hash
          private def self.create_rain_from_hash(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : RainShader?
            intensity = case params["intensity"]?.try(&.to_s)
            when "light"  then RainIntensity::Light
            when "medium" then RainIntensity::Medium
            when "heavy"  then RainIntensity::Heavy
            when "storm"  then RainIntensity::Storm
            else RainIntensity::Medium
            end
            
            wind = params["wind"]?.as?(Float32) || 0.2f32
            duration = params["duration"]?.as?(Float32) || 0.0f32
            
            effect = RainShader.new(intensity, wind, duration)
            
            if color_array = params["color"]?.as?(Array(Int32))
              effect.rain_color = RL::Color.new(
                r: color_array[0].to_u8,
                g: color_array[1].to_u8,
                b: color_array[2].to_u8,
                a: (color_array[3]? || 255).to_u8
              )
            end
            
            effect.splash_enabled = params["splashes"]?.as?(Bool) != false
            
            effect
          end
          
          # Create darkness from hash
          private def self.create_darkness_from_hash(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : DarknessShader?
            darkness_type = case params["type"]?.try(&.to_s) || params["darkness_type"]?.try(&.to_s)
            when "vignette"   then DarknessType::Vignette
            when "gradient"   then DarknessType::Gradient
            when "spotlight"  then DarknessType::Spotlight
            when "multilight" then DarknessType::MultiLight
            else DarknessType::Vignette
            end
            
            intensity = params["intensity"]?.as?(Float32) || 0.8f32
            duration = params["duration"]?.as?(Float32) || 0.0f32
            
            effect = DarknessShader.new(darkness_type, intensity, duration)
            
            if color_array = params["color"]?.as?(Array(Int32))
              effect.darkness_color = RL::Color.new(
                r: color_array[0].to_u8,
                g: color_array[1].to_u8,
                b: color_array[2].to_u8,
                a: (color_array[3]? || 255).to_u8
              )
            end
            
            if inner = params["inner_radius"]?.as?(Float32)
              effect.inner_radius = inner
            end
            if outer = params["outer_radius"]?.as?(Float32)
              effect.outer_radius = outer
            end
            if angle = params["gradient_angle"]?.as?(Float32)
              effect.gradient_angle = angle
            end
            
            effect
          end
          
          # Create underwater from hash
          private def self.create_underwater_from_hash(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : UnderwaterShader?
            quality = case params["quality"]?.try(&.to_s)
            when "low"    then UnderwaterQuality::Low
            when "medium" then UnderwaterQuality::Medium
            when "high"   then UnderwaterQuality::High
            else UnderwaterQuality::Medium
            end
            
            color = if color_array = params["color"]?.as?(Array(Int32))
              RL::Color.new(
                r: color_array[0].to_u8,
                g: color_array[1].to_u8,
                b: color_array[2].to_u8,
                a: (color_array[3]? || 255).to_u8
              )
            else
              RL::Color.new(r: 0, g: 80, b: 120, a: 100)
            end
            
            duration = params["duration"]?.as?(Float32) || 0.0f32
            
            effect = UnderwaterShader.new(quality, color, duration)
            
            if amplitude = params["wave_amplitude"]?.as?(Float32)
              effect.wave_amplitude = amplitude
            end
            if frequency = params["wave_frequency"]?.as?(Float32)
              effect.wave_frequency = frequency
            end
            if speed = params["wave_speed"]?.as?(Float32)
              effect.wave_speed = speed
            end
            if caustics = params["caustics_intensity"]?.as?(Float32)
              effect.caustics_intensity = caustics
            end
            if blur = params["blur_amount"]?.as?(Float32)
              effect.blur_amount = blur
            end
            if bubbles = params["bubble_density"]?.as?(Float32)
              effect.bubble_density = bubbles
            end
            
            effect
          end
          
          # Create simple rain from hash (placeholder)
          private def self.create_simple_rain_from_hash(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : BaseSceneEffect?
            # For now, just use regular rain
            create_rain_from_hash(params)
          end
          
          # Create test overlay from hash (placeholder)
          private def self.create_test_overlay_from_hash(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : BaseSceneEffect?
            # For now, just use fog
            create_fog_from_hash(params)
          end
        end
      end
    end
  end
end