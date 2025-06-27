# Scene transition manager using modular effects

require "./transition_effect"
require "./shader_loader"
require "./effects/basic_effects"
require "./effects/geometric_effects"
require "./effects/artistic_effects"
require "./effects/cinematic_effects"
require "./effects/advanced_effects"

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
        @callback_called : Bool = false
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
          @callback_called = false

          # Cleanup previous effect
          @current_effect.try(&.cleanup)

          # Create new effect instance
          @current_effect = create_effect_instance(effect, duration)

          # Load the shader for the effect
          if effect_instance = @current_effect
            effect_instance.shader = effect_instance.load_shader
            # Shader loaded successfully
          end
        end

        # Update transition progress
        def update(dt : Float32)
          return unless @active

          @progress += dt / @duration
          
          if (Time.monotonic.total_milliseconds.to_i % 300) < 20  # Print periodically
            puts "[TransitionManager] Progress: #{@progress.round(2)}, Active: #{@active}"
          end

          # Call the scene change callback at halfway point
          if @progress >= 0.5f32 && !@callback_called
            puts "[TransitionManager] Triggering scene change callback at 50%"
            @on_complete.try(&.call)
            @callback_called = true
          end

          if @progress >= 1.0f32
            @progress = 1.0f32
            @active = false
            puts "[TransitionManager] Transition complete"
          end

          # Update current effect
          if effect = @current_effect
            effect.progress = @progress
            effect.update_shader_params(@progress)
          end
        end

        # Draw method for compatibility with render layer system
        def draw
          return unless @active
          return unless texture = @render_texture
          return unless effect = @current_effect

          # For fade effect, draw overlay
          if effect.is_a?(FadeEffect)
            alpha = (255 * @progress).to_u8
            RL.draw_rectangle(0, 0, @width, @height, RL::Color.new(r: 0, g: 0, b: 0, a: alpha))
          end
        end

        # Render with transition effect
        def render_with_transition(&block : -> Nil)
          unless @active
            yield
            return
          end

          puts "[TransitionManager] render_with_transition called, active=#{@active}"
          
          return yield unless texture = @render_texture
          return yield unless effect = @current_effect

          # If no shader, just render with basic fade
          unless shader = effect.shader
            # No shader available, fallback to fade
            yield

            # Simple fade overlay
            alpha = (255 * @progress).to_u8
            RL.draw_rectangle(0, 0, @width, @height, RL::Color.new(r: 0, g: 0, b: 0, a: alpha))

            # Fallback fade effect applied
            return
          end

          # Render scene to texture
          RL.begin_texture_mode(texture)
          yield
          RL.end_texture_mode

          # Update shader parameters before rendering
          effect.update_shader_params(@progress)

          # Render texture with shader effect
          RL.begin_shader_mode(shader)
          RL.draw_texture_rec(
            texture.texture,
            RL::Rectangle.new(x: 0, y: 0, width: @width, height: -@height), # Flip Y
            RL::Vector2.new(x: 0, y: 0),
            RL::WHITE
          )
          RL.end_shader_mode

          # Transition effect applied
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
          # Basic effects
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
            # Geometric effects
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
            # Artistic effects
          when .swirl?
            SwirlEffect.new(duration)
          when .curtain?
            CurtainEffect.new(duration)
          when .ripple?
            RippleEffect.new(duration)
          when .glitch?
            GlitchEffect.new(duration)
            # Cinematic effects
          when .warp?
            WarpEffect.new(duration)
          when .wave?
            WaveEffect.new(duration)
          when .film_burn?
            FilmBurnEffect.new(duration)
          when .static?
            StaticEffect.new(duration)
          when .matrix_rain?
            MatrixRainEffect.new(duration)
            # Advanced effects
          when .zoom_blur?
            ZoomBlurEffect.new(duration)
          when .clock_wipe?
            ClockWipeEffect.new(duration)
          when .barn_door?
            BarnDoorEffect.new(duration)
          when .page_turn?
            PageTurnEffect.new(duration)
          when .shatter?
            ShatterEffect.new(duration)
          when .vortex?
            VortexEffect.new(duration)
          when .fire?
            FireEffect.new(duration)
          else
            # Default to fade for any remaining unimplemented effects
            FadeEffect.new(duration)
          end
        end
      end
    end
  end
end
