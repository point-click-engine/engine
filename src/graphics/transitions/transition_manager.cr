# Scene transition manager using modular effects

require "./transition_effect"
require "./shader_loader"
require "./effects/basic_effects"
require "./effects/geometric_effects"

module PointClickEngine
  module Graphics
    module Transitions
      # Scene transition manager with shader effects
      class TransitionManager
        property active : Bool = false
        property progress : Float32 = 0.0f32
        property duration : Float32 = 1.0f32
        property current_effect_type : TransitionEffect?
        property on_complete : Proc(Nil)?

        @render_texture : RL::RenderTexture2D?
        @current_effect : BaseTransitionEffect?
        @width : Int32
        @height : Int32

        def initialize(@width : Int32, @height : Int32)
          @render_texture = RL.load_render_texture(@width, @height)
        end

        # Start a transition effect
        def start_transition(effect : TransitionEffect, duration : Float32 = 1.0f32, &on_complete : -> Nil)
          @active = true
          @progress = 0.0f32
          @duration = duration
          @current_effect_type = effect
          @on_complete = on_complete

          # Cleanup previous effect
          @current_effect.try(&.cleanup)

          # Create new effect instance
          @current_effect = create_effect_instance(effect, duration)
          @current_effect.try(&.load_shader)
        end

        # Update transition progress
        def update(dt : Float32)
          return unless @active

          @progress += dt / @duration

          if @progress >= 1.0f32
            @progress = 1.0f32
            @active = false
            @on_complete.try(&.call)
          end

          # Update current effect
          if effect = @current_effect
            effect.progress = @progress
            effect.update_shader_params(@progress)
          end
        end

        # Render with transition effect
        def render_with_transition(&block : -> Nil)
          return yield unless @active
          return yield unless texture = @render_texture
          return yield unless effect = @current_effect
          return yield unless shader = effect.shader

          # Render scene to texture
          RL.begin_texture_mode(texture)
          yield
          RL.end_texture_mode

          # Render texture with shader effect
          RL.begin_shader_mode(shader)
          RL.draw_texture_rec(
            texture.texture,
            RL::Rectangle.new(x: 0, y: 0, width: @width, height: -@height), # Flip Y
            RL::Vector2.new(x: 0, y: 0),
            RL::WHITE
          )
          RL.end_shader_mode
        end

        # Stop current transition
        def stop_transition
          @active = false
          @progress = 0.0f32
          @current_effect.try(&.cleanup)
          @current_effect = nil
        end

        # Check if a transition is currently active
        def transitioning? : Bool
          @active
        end

        # Get current transition progress (0.0 to 1.0)
        def current_progress : Float32
          @progress
        end

        # Set second texture for cross-fade effects
        def set_second_texture(texture : RL::Texture2D)
          if effect = @current_effect
            if effect.is_a?(CrossFadeEffect)
              effect.second_texture = texture
            end
          end
        end

        # Cleanup resources
        def cleanup
          @current_effect.try(&.cleanup)
          if texture = @render_texture
            RL.unload_render_texture(texture)
            @render_texture = nil
          end
        end

        private def create_effect_instance(effect : TransitionEffect, duration : Float32) : BaseTransitionEffect?
          case effect
          when .fade?
            FadeEffect.new(duration)
          when .dissolve?
            DissolveEffect.new(duration)
          when .cross_fade?
            CrossFadeEffect.new(duration)
          when .slide_left?
            SlideEffect.new(duration, SlideDirection::Left)
          when .slide_right?
            SlideEffect.new(duration, SlideDirection::Right)
          when .slide_up?
            SlideEffect.new(duration, SlideDirection::Up)
          when .slide_down?
            SlideEffect.new(duration, SlideDirection::Down)
          when .iris?
            IrisEffect.new(duration)
          when .star_wipe?
            StarWipeEffect.new(duration)
          when .heart_wipe?
            HeartWipeEffect.new(duration)
          when .checkerboard?
            CheckerboardEffect.new(duration)
          when .pixelate?
            PixelateEffect.new(duration)
          else
            # Default to fade for unimplemented effects
            FadeEffect.new(duration)
          end
        end
      end
    end
  end
end
