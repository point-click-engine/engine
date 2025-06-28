# Transition effects for scene changes using the new graphics system

require "./base_scene_effect"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Enum for transition types
        enum TransitionType
          Fade
          Dissolve
          SlideLeft
          SlideRight
          SlideUp
          SlideDown
          Iris
          Swirl
          StarWipe
          HeartWipe
          Curtain
          Ripple
          Checkerboard
          Pixelate
          Warp
          Wave
          Glitch
          FilmBurn
          Static
          MatrixRain
          ZoomBlur
          ClockWipe
          BarnDoor
          PageTurn
          Shatter
          Vortex
          Fire
          CrossFade
        end

        # Scene transition effect
        class TransitionEffect < BaseSceneEffect
          getter transition_type : TransitionType
          getter reverse : Bool = false
          getter midpoint_callback : Proc(Nil)?
          
          @phase : Float32 = 0.0f32
          @midpoint_triggered : Bool = false

          def initialize(@transition_type : TransitionType,
                         duration : Float32 = 1.0f32,
                         @reverse : Bool = false)
            super(duration)
            @affect_all_layers = true
          end

          # Set callback for midpoint (scene change)
          def on_midpoint(&block : -> Nil)
            @midpoint_callback = block
          end

          def update(dt : Float32)
            super(dt)
            
            # Trigger midpoint callback at 50%
            if !@midpoint_triggered && progress >= 0.5
              @midpoint_triggered = true
              @midpoint_callback.try(&.call)
            end
          end

          def apply_to_layer(context : Effects::EffectContext, layer : Layers::Layer)
            # Calculate phase (0-1 for first half, 1-0 for second half)
            @phase = progress < 0.5 ? progress * 2.0 : 2.0 - (progress * 2.0)
            
            case @transition_type
            when .fade?
              apply_fade(layer)
            when .dissolve?
              apply_dissolve(layer)
            when .slide_left?, .slide_right?, .slide_up?, .slide_down?
              apply_slide(layer, context)
            else
              # Default to fade for unimplemented transitions
              apply_fade(layer)
            end
          end

          private def apply_fade(layer : Layers::Layer)
            # Simple fade using layer opacity
            layer.opacity = 1.0 - @phase
          end

          private def apply_dissolve(layer : Layers::Layer)
            # Use a more complex dissolve pattern
            layer.opacity = 1.0 - @phase
            # Could add noise or dithering here
          end

          private def apply_slide(layer : Layers::Layer, context : Effects::EffectContext)
            # Slide based on direction
            # Use a default viewport width for now
            viewport_width = 1024.0f32
            offset = @phase * viewport_width
            
            case @transition_type
            when .slide_left?
              layer.offset.x = -offset
            when .slide_right?
              layer.offset.x = offset
            when .slide_up?
              layer.offset.y = -offset
            when .slide_down?
              layer.offset.y = offset
            end
          end

          # Apply transition effect (delegates to apply_to_layer)
          def apply(context : Effects::EffectContext)
            # Transition effects are applied at the layer level
            # This is handled by the scene effect system
          end

          def clone : Effect
            effect = TransitionEffect.new(@transition_type, @duration, @reverse)
            effect.on_midpoint { @midpoint_callback.try(&.call) }
            effect
          end
        end

        # Factory method for creating transitions
        def self.create_transition(type : TransitionType, duration : Float32 = 1.0f32) : TransitionEffect
          TransitionEffect.new(type, duration)
        end
      end
    end
  end
end