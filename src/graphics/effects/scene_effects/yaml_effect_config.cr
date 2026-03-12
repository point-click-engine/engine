# YAML-serializable configuration for scene effects
#
# This allows scene effects to be created directly from YAML
# without the scene loader needing to know about specific effect types.

require "yaml"
require "./base_scene_effect"
require "./shader/fog_shader"
require "./shader/rain_shader"
require "./shader/darkness_shader"
require "./shader/underwater_shader"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Base config for all effects
        abstract class EffectConfig
          include YAML::Serializable
          
          # Type discriminator for polymorphic deserialization
          use_yaml_discriminator "type", {
            fog: FogEffectConfig,
            rain: RainEffectConfig,
            darkness: DarknessEffectConfig,
            vignette: DarknessEffectConfig,
            underwater: UnderwaterEffectConfig
          }
          
          # Common properties  
          property duration : Float32?
          
          # Abstract method to create the actual effect
          abstract def create_effect : BaseSceneEffect
        end
        
        # Fog effect configuration
        class FogEffectConfig < EffectConfig
          property fog_type : String?
          property color : Array(Int32)?
          property density : Float32?
          property start : Float32?
          property end : Float32?
          property height_falloff : Float32?
          
          def create_effect : BaseSceneEffect
            fog_type_enum = case fog_type || "linear"
            when "linear"      then FogType::Linear
            when "exponential" then FogType::Exponential
            when "layered"     then FogType::Layered
            when "volumetric"  then FogType::Volumetric
            else FogType::Linear
            end
            
            color_array = color || [128, 128, 150, 200]
            fog_color = RL::Color.new(
              r: color_array[0].to_u8,
              g: color_array[1].to_u8,
              b: color_array[2].to_u8,
              a: (color_array[3]? || 255).to_u8
            )
            
            effect = FogShader.new(fog_type_enum, fog_color, density || 0.02f32, @duration || 0.0f32)
            effect.fog_start = start || 100.0f32
            effect.fog_end = self.end || 500.0f32
            effect.height_falloff = height_falloff || 0.5f32
            effect
          end
        end
        
        # Rain effect configuration
        class RainEffectConfig < EffectConfig
          property intensity : String?
          property wind : Float32?
          property color : Array(Int32)?
          property splashes : Bool?
          
          def create_effect : BaseSceneEffect
            intensity_enum = case intensity || "medium"
            when "light"  then RainIntensity::Light
            when "medium" then RainIntensity::Medium
            when "heavy"  then RainIntensity::Heavy
            when "storm"  then RainIntensity::Storm
            else RainIntensity::Medium
            end
            
            color_array = color || [200, 200, 255, 100]
            rain_color = RL::Color.new(
              r: color_array[0].to_u8,
              g: color_array[1].to_u8,
              b: color_array[2].to_u8,
              a: (color_array[3]? || 255).to_u8
            )
            
            effect = RainShader.new(intensity_enum, wind || 0.2f32, @duration || 0.0f32)
            effect.rain_color = rain_color
            effect.splash_enabled = splashes != false
            effect
          end
        end
        
        # Darkness/Vignette effect configuration
        class DarknessEffectConfig < EffectConfig
          property darkness_type : String?
          property intensity : Float32?
          property color : Array(Int32)?
          property inner_radius : Float32?
          property outer_radius : Float32?
          property gradient_angle : Float32?
          
          def create_effect : BaseSceneEffect
            darkness_type_enum = case darkness_type || "vignette"
            when "vignette"   then DarknessType::Vignette
            when "gradient"   then DarknessType::Gradient
            when "spotlight"  then DarknessType::Spotlight
            when "multilight" then DarknessType::MultiLight
            else DarknessType::Vignette
            end
            
            color_array = color || [0, 0, 0, 200]
            darkness_color = RL::Color.new(
              r: color_array[0].to_u8,
              g: color_array[1].to_u8,
              b: color_array[2].to_u8,
              a: (color_array[3]? || 255).to_u8
            )
            
            effect = DarknessShader.new(darkness_type_enum, intensity || 0.8f32, @duration || 0.0f32)
            effect.darkness_color = darkness_color
            effect.inner_radius = inner_radius || 0.5f32
            effect.outer_radius = outer_radius || 1.2f32
            effect.gradient_angle = gradient_angle || 0.0f32
            effect
          end
        end
        
        # Underwater effect configuration
        class UnderwaterEffectConfig < EffectConfig
          property quality : String?
          property color : Array(Int32)?
          property wave_amplitude : Float32?
          property wave_frequency : Float32?
          property wave_speed : Float32?
          property caustics_intensity : Float32?
          property blur_amount : Float32?
          property bubble_density : Float32?
          
          def create_effect : BaseSceneEffect
            quality_enum = case quality || "medium"
            when "low"    then UnderwaterQuality::Low
            when "medium" then UnderwaterQuality::Medium
            when "high"   then UnderwaterQuality::High
            else UnderwaterQuality::Medium
            end
            
            color_array = color || [0, 80, 120, 100]
            water_color = RL::Color.new(
              r: color_array[0].to_u8,
              g: color_array[1].to_u8,
              b: color_array[2].to_u8,
              a: (color_array[3]? || 255).to_u8
            )
            
            effect = UnderwaterShader.new(quality_enum, water_color, @duration || 0.0f32)
            effect.wave_amplitude = wave_amplitude || 0.01f32
            effect.wave_frequency = wave_frequency || 10.0f32
            effect.wave_speed = wave_speed || 2.0f32
            effect.caustics_intensity = caustics_intensity || 0.3f32
            effect.blur_amount = blur_amount || 0.002f32
            effect.bubble_density = bubble_density || 5.0f32
            effect
          end
        end
        
      end
    end
  end
end