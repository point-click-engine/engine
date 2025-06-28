# Base effect class for all visual effects

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Effects
      # Base class for all visual effects
      #
      # Effects can be applied to objects, scenes, or cameras to create
      # visual enhancements like glow, shake, transitions, etc.
      #
      # ## Creating Custom Effects
      #
      # ```
      # class MyEffect < Effect
      #   def update(dt : Float32)
      #     super
      #     # Update effect state
      #   end
      #
      #   def apply(context : EffectContext)
      #     # Apply visual changes
      #   end
      # end
      # ```
      abstract class Effect
        # Effect properties
        property active : Bool = true
        property duration : Float32 = 0.0f32 # 0 = infinite
        property elapsed : Float32 = 0.0f32
        property intensity : Float32 = 1.0f32

        # Effect parameters (for serialization and configuration)
        property parameters : Hash(String, Float32 | Int32 | Bool | String | RL::Color)

        def initialize(@duration : Float32 = 0.0f32)
          @parameters = {} of String => (Float32 | Int32 | Bool | String | RL::Color)
        end

        # Update effect state
        def update(dt : Float32)
          return unless @active

          @elapsed += dt

          # Check if effect has expired
          if @duration > 0 && @elapsed >= @duration
            @active = false
          end
        end

        # Apply effect to target (implemented by subclasses)
        abstract def apply(context : EffectContext)

        # Get effect progress (0.0 to 1.0)
        def progress : Float32
          return 0.0f32 if @duration <= 0
          (@elapsed / @duration).clamp(0.0f32, 1.0f32)
        end

        # Get remaining time
        def remaining_time : Float32
          return Float32::INFINITY if @duration <= 0
          Math.max(0.0f32, @duration - @elapsed)
        end

        # Check if effect has finished
        def finished? : Bool
          !@active
        end

        # Reset effect to start
        def reset
          @elapsed = 0.0f32
          @active = true
        end

        # Stop effect immediately
        def stop
          @active = false
        end

        # Fade effect in/out over time
        def fade_intensity(target : Float32, speed : Float32, dt : Float32) : Bool
          diff = target - @intensity

          if diff.abs < 0.01f32
            @intensity = target
            return true
          end

          change = diff.sign * speed * dt
          if diff.abs < change.abs
            @intensity = target
            return true
          else
            @intensity += change
            return false
          end
        end
      end

      # Context passed to effects for rendering
      class EffectContext
        # What the effect is being applied to
        enum TargetType
          Object
          Scene
          Camera
          Layer
        end

        property target_type : TargetType
        property renderer : PointClickEngine::Graphics::Renderer
        property render_context : PointClickEngine::Graphics::RenderContext?
        property delta_time : Float32

        # Target-specific properties
        property position : RL::Vector2?
        property size : RL::Vector2?
        property bounds : RL::Rectangle?
        property texture : RL::Texture2D?
        property sprite : Sprites::Sprite?

        def initialize(@target_type : TargetType, @renderer : PointClickEngine::Graphics::Renderer,
                       @delta_time : Float32)
        end
      end

      # Component for attaching effects to game objects
      class EffectComponent
        @effects : Array(Effect) = [] of Effect

        # Add an effect
        def add_effect(effect : Effect)
          @effects << effect
        end

        # Remove specific effect
        def remove_effect(effect : Effect)
          @effects.delete(effect)
        end

        # Remove all effects of a type
        def remove_effects_of_type(effect_type : T.class) forall T
          @effects.reject! { |e| e.is_a?(T) }
        end

        # Clear all effects
        def clear_effects
          @effects.clear
        end

        # Update all effects
        def update(dt : Float32)
          # Update effects and remove finished ones
          @effects.reject! do |effect|
            effect.update(dt)
            effect.finished?
          end
        end

        # Apply all effects
        def apply(context : EffectContext)
          @effects.each do |effect|
            effect.apply(context) if effect.active
          end
        end

        # Get all active effects
        def active_effects : Array(Effect)
          @effects.select(&.active)
        end

        # Check if has specific effect type
        def has_effect?(effect_type : T.class) : Bool forall T
          @effects.any? { |e| e.is_a?(T) }
        end

        # Get first effect of type
        def get_effect(effect_type : T.class) : T? forall T
          @effects.find { |e| e.is_a?(T) }.as(T?)
        end
      end

      # Easing functions for smooth animations
      module Easing
        extend self

        def linear(t : Float32) : Float32
          t
        end

        def ease_in_quad(t : Float32) : Float32
          t * t
        end

        def ease_out_quad(t : Float32) : Float32
          t * (2 - t)
        end

        def ease_in_out_quad(t : Float32) : Float32
          if t < 0.5
            2 * t * t
          else
            -1 + (4 - 2 * t) * t
          end
        end

        def ease_in_cubic(t : Float32) : Float32
          t * t * t
        end

        def ease_out_cubic(t : Float32) : Float32
          t -= 1
          t * t * t + 1
        end

        def ease_in_out_cubic(t : Float32) : Float32
          if t < 0.5
            4 * t * t * t
          else
            t -= 1
            1 + t * 4 * t * t
          end
        end

        def ease_in_sine(t : Float32) : Float32
          1 - Math.cos(t * Math::PI / 2)
        end

        def ease_out_sine(t : Float32) : Float32
          Math.sin(t * Math::PI / 2)
        end

        def ease_in_out_sine(t : Float32) : Float32
          -(Math.cos(Math::PI * t) - 1) / 2
        end

        def ease_in_elastic(t : Float32) : Float32
          return 0.0f32 if t == 0
          return 1.0f32 if t == 1

          p = 0.3f32
          a = 1.0f32
          s = p / 4

          t -= 1
          -(a * (2 ** (10 * t)) * Math.sin((t - s) * 2 * Math::PI / p))
        end

        def ease_out_elastic(t : Float32) : Float32
          return 0.0f32 if t == 0
          return 1.0f32 if t == 1

          p = 0.3f32
          a = 1.0f32
          s = p / 4

          a * (2 ** (-10 * t)) * Math.sin((t - s) * 2 * Math::PI / p) + 1
        end

        def ease_in_out_elastic(t : Float32) : Float32
          return 0.0f32 if t == 0
          return 1.0f32 if t == 1

          p = 0.45f32
          a = 1.0f32
          s = p / 4

          if t < 0.5
            t = t * 2 - 1
            -0.5 * (a * (2 ** (10 * t)) * Math.sin((t - s) * 2 * Math::PI / p))
          else
            t = t * 2 - 1
            a * (2 ** (-10 * t)) * Math.sin((t - s) * 2 * Math::PI / p) * 0.5 + 1
          end
        end

        def ease_out_bounce(t : Float32) : Float32
          if t < 1.0f32 / 2.75f32
            7.5625f32 * t * t
          elsif t < 2.0f32 / 2.75f32
            t -= 1.5f32 / 2.75f32
            7.5625f32 * t * t + 0.75f32
          elsif t < 2.5f32 / 2.75f32
            t -= 2.25f32 / 2.75f32
            7.5625f32 * t * t + 0.9375f32
          else
            t -= 2.625f32 / 2.75f32
            7.5625f32 * t * t + 0.984375f32
          end
        end

        def ease_in_bounce(t : Float32) : Float32
          1.0f32 - ease_out_bounce(1.0f32 - t)
        end

        def ease_in_out_bounce(t : Float32) : Float32
          if t < 0.5f32
            ease_in_bounce(t * 2.0f32) * 0.5f32
          else
            ease_out_bounce(t * 2.0f32 - 1.0f32) * 0.5f32 + 0.5f32
          end
        end
      end
    end
  end
end
