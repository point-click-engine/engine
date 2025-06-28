# Adapter to integrate existing transition system with new effects architecture

require "./base_scene_effect"
require "../../transitions/transition_manager"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Adapter that wraps the existing transition system as a scene effect
        class TransitionAdapter < BaseSceneEffect
          getter transition_type : Transitions::TransitionEffect
          getter reverse : Bool = false

          @transition_manager : Transitions::TransitionManager?
          @scene_change_callback : Proc(Nil)?
          @callback_triggered : Bool = false
          @progress : Float32 = 0.0f32

          def initialize(@transition_type : Transitions::TransitionEffect,
                         duration : Float32 = 1.0f32,
                         @reverse : Bool = false)
            super(duration)
            @affect_all_layers = true # Transitions affect entire scene
          end

          # Set callback for when scene should change (at 50% progress)
          def on_scene_change(&block : -> Nil)
            @scene_change_callback = block
          end

          def update(dt : Float32)
            super

            # Create transition manager on first update (when we have access to display size)
            unless manager = @transition_manager
              manager = Transitions::TransitionManager.new(
                Display::REFERENCE_WIDTH,
                Display::REFERENCE_HEIGHT
              )
              @transition_manager = manager

              # Start the transition
              manager.start_transition(@transition_type, @duration) do
                # This callback is called at 50% progress
                @scene_change_callback.try(&.call)
                @callback_triggered = true
              end
            end

            # Update transition
            manager.update(dt)

            # Sync progress
            @progress = if @reverse
                          1.0f32 - manager.progress
                        else
                          manager.progress
                        end

            # Mark as finished when transition completes
            @active = manager.active
          end

          def apply(context : EffectContext)
            # Transition rendering is handled in apply_to_scene
          end

          def apply_to_scene(context : EffectContext, layers : Layers::LayerManager)
            # The transition manager needs to wrap the entire render process
            # This is handled by the renderer when this effect is active
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Transitions don't apply to individual layers
            # They wrap the entire rendering process
          end

          # Get the transition manager for renderer integration
          def transition_manager : Transitions::TransitionManager?
            @transition_manager
          end

          # Check if this is a transition effect
          def transition? : Bool
            true
          end

          # Render the transition overlay (for simple effects like fade)
          def render_overlay
            @transition_manager.try(&.draw)
          end

          # Cleanup
          def cleanup
            @transition_manager.try(&.cleanup)
            @transition_manager = nil
          end
        end

        # Factory extension for transition effects
        class SceneEffectFactory
          # Create transition effects
          def self.create_transition(transition_name : String, **params) : TransitionAdapter?
            # Parse transition type
            transition_type = case transition_name.downcase
                              when "fade"                                  then Transitions::TransitionEffect::Fade
                              when "dissolve"                              then Transitions::TransitionEffect::Dissolve
                              when "slide_left", "slide-left"              then Transitions::TransitionEffect::SlideLeft
                              when "slide_right", "slide-right"            then Transitions::TransitionEffect::SlideRight
                              when "slide_up", "slide-up"                  then Transitions::TransitionEffect::SlideUp
                              when "slide_down", "slide-down"              then Transitions::TransitionEffect::SlideDown
                              when "cross_fade", "cross-fade", "crossfade" then Transitions::TransitionEffect::CrossFade
                              when "iris"                                  then Transitions::TransitionEffect::Iris
                              when "pixelate"                              then Transitions::TransitionEffect::Pixelate
                              when "swirl"                                 then Transitions::TransitionEffect::Swirl
                              when "checkerboard"                          then Transitions::TransitionEffect::Checkerboard
                              when "star_wipe", "star-wipe"                then Transitions::TransitionEffect::StarWipe
                              when "heart_wipe", "heart-wipe"              then Transitions::TransitionEffect::HeartWipe
                              when "curtain"                               then Transitions::TransitionEffect::Curtain
                              when "ripple"                                then Transitions::TransitionEffect::Ripple
                              when "warp"                                  then Transitions::TransitionEffect::Warp
                              when "wave"                                  then Transitions::TransitionEffect::Wave
                              when "film_burn", "film-burn"                then Transitions::TransitionEffect::FilmBurn
                              when "static"                                then Transitions::TransitionEffect::Static
                              when "matrix_rain", "matrix-rain"            then Transitions::TransitionEffect::MatrixRain
                              when "zoom_blur", "zoom-blur"                then Transitions::TransitionEffect::ZoomBlur
                              when "clock_wipe", "clock-wipe"              then Transitions::TransitionEffect::ClockWipe
                              when "barn_door", "barn-door"                then Transitions::TransitionEffect::BarnDoor
                              when "page_turn", "page-turn"                then Transitions::TransitionEffect::PageTurn
                              when "shatter"                               then Transitions::TransitionEffect::Shatter
                              when "vortex"                                then Transitions::TransitionEffect::Vortex
                              when "fire"                                  then Transitions::TransitionEffect::Fire
                              when "glitch"                                then Transitions::TransitionEffect::Glitch
                              else
                                return nil
                              end

            duration = params[:duration]?.try(&.as(Number).to_f32) || 1.0f32
            reverse = params[:reverse]? == true || params[:direction]? == "out"

            TransitionAdapter.new(transition_type, duration, reverse)
          end
        end
      end
    end
  end
end
