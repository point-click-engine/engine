# Post-processing pipeline for shader effects

require "raylib-cr"
require "./shader_effect"

module PointClickEngine
  module Graphics
    module Shaders
      # Manages a chain of post-processing effects
      class PostProcessor
        # Effect chain entry
        struct EffectEntry
          property effect : ShaderEffect
          property enabled : Bool

          def initialize(@effect : ShaderEffect, @enabled : Bool = true)
          end
        end

        # Screen dimensions
        property width : Int32
        property height : Int32

        # Effect chain
        property effects : Array(EffectEntry)

        # Render textures for ping-pong rendering
        @render_texture_a : RL::RenderTexture2D
        @render_texture_b : RL::RenderTexture2D

        # Time tracking
        @time : Float32 = 0.0f32

        def initialize(@width : Int32, @height : Int32)
          @effects = [] of EffectEntry

          # Create render textures
          @render_texture_a = RL.load_render_texture(@width, @height)
          @render_texture_b = RL.load_render_texture(@width, @height)
        end

        # Add effect to chain
        def add_effect(effect : ShaderEffect, enabled : Bool = true)
          @effects << EffectEntry.new(effect, enabled)
        end

        # Remove effect from chain
        def remove_effect(effect : ShaderEffect)
          @effects.reject! { |entry| entry.effect == effect }
        end

        # Enable/disable effect
        def set_effect_enabled(effect : ShaderEffect, enabled : Bool)
          if entry = @effects.find { |e| e.effect == effect }
            entry.enabled = enabled
          end
        end

        # Clear all effects
        def clear_effects
          @effects.clear
        end

        # Begin capturing to post-processor
        def begin_capture
          RL.begin_texture_mode(@render_texture_a)
          RL.clear_background(RL::BLACK)
        end

        # End capture and apply effects
        def end_capture
          RL.end_texture_mode
        end

        # Process and render to screen
        def render(delta_time : Float32)
          @time += delta_time

          # Apply each enabled effect in sequence
          source = @render_texture_a
          target = @render_texture_b

          active_effects = @effects.select(&.enabled)

          if active_effects.empty?
            # No effects, just draw source
            draw_texture_flipped(source)
            return
          end

          active_effects.each_with_index do |entry, index|
            entry.effect.apply(source, target, @time)

            # Swap buffers for next effect
            source, target = target, source
          end

          # Draw final result
          draw_texture_flipped(source)
        end

        # Resize render textures
        def resize(@width : Int32, @height : Int32)
          # Cleanup old textures
          RL.unload_render_texture(@render_texture_a)
          RL.unload_render_texture(@render_texture_b)

          # Create new ones
          @render_texture_a = RL.load_render_texture(@width, @height)
          @render_texture_b = RL.load_render_texture(@width, @height)
        end

        # Get effect by type
        def get_effect(type : T.class) : T? forall T
          @effects.each do |entry|
            return entry.effect.as(T) if entry.effect.is_a?(T)
          end
          nil
        end

        # Check if has any active effects
        def has_active_effects? : Bool
          @effects.any?(&.enabled)
        end

        # Cleanup
        def cleanup
          RL.unload_render_texture(@render_texture_a)
          RL.unload_render_texture(@render_texture_b)

          @effects.each do |entry|
            entry.effect.cleanup
          end
          @effects.clear
        end

        private def draw_texture_flipped(render_texture : RL::RenderTexture2D)
          RL.draw_texture_rec(
            render_texture.texture,
            RL::Rectangle.new(0, 0, render_texture.texture.width, -render_texture.texture.height),
            RL::Vector2.new(0, 0),
            RL::WHITE
          )
        end
      end

      # Quick post-processing presets
      module PostProcessPresets
        extend self

        # Create retro CRT preset
        def crt(post_processor : PostProcessor)
          post_processor.clear_effects
          post_processor.add_effect(Retro::CRTEffect.create)
        end

        # Create Game Boy preset
        def gameboy(post_processor : PostProcessor)
          post_processor.clear_effects

          # Pixelate first
          pixelate = Retro::PixelateEffect.create
          pixelate.pixel_size = 3.0f32
          post_processor.add_effect(pixelate)

          # Then LCD effect
          post_processor.add_effect(Retro::LCDEffect.create)
        end

        # Create VHS preset
        def vhs(post_processor : PostProcessor)
          post_processor.clear_effects
          post_processor.add_effect(Retro::VHSEffect.create)
        end

        # Create retro arcade preset
        def arcade(post_processor : PostProcessor)
          post_processor.clear_effects

          # Slight pixelation
          pixelate = Retro::PixelateEffect.create
          pixelate.pixel_size = 2.0f32
          pixelate.intensity = 0.5f32
          post_processor.add_effect(pixelate)

          # CRT effect
          crt = Retro::CRTEffect.create
          crt.scanline_intensity = 0.2f32
          crt.curvature = 0.15f32
          post_processor.add_effect(crt)
        end
      end
    end
  end
end
