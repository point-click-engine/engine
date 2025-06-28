# Ambient scene effects like weather and atmosphere

require "./base_scene_effect"
require "./transition_adapter"
require "../object_effects/float"
require "../object_effects/color_shift"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Fog effect that reduces visibility and adds atmosphere
        class FogEffect < BaseSceneEffect
          property density : Float32 = 0.5f32
          property color : RL::Color = RL::Color.new(r: 200, g: 200, b: 220, a: 100)
          property speed : Float32 = 10.0f32 # Fog movement speed
          property near_distance : Float32 = 200.0f32
          property far_distance : Float32 = 800.0f32

          @fog_offset : Float32 = 0.0f32
          @fog_layers : Array(FogLayer)

          def initialize(@density : Float32 = 0.5f32, duration : Float32 = 0.0f32)
            super(duration)

            # Create multiple fog layers for depth
            @fog_layers = [
              FogLayer.new(0.3f32, 0.5f32, @speed * 0.5f32),
              FogLayer.new(0.5f32, 0.7f32, @speed * 0.8f32),
              FogLayer.new(0.7f32, 1.0f32, @speed),
            ]
          end

          def update(dt : Float32)
            super
            @fog_offset += dt * @speed

            @fog_layers.each do |layer|
              layer.update(dt)
            end
          end

          def apply(context : EffectContext)
            # Fog is applied as overlay, handled in apply_to_layer
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Only apply fog to scene layers, not UI
            return if layer.is_a?(Layers::UILayer)

            # Apply distance-based fog by tinting the layer
            # In a real implementation, this would be done with shaders
            fog_alpha = (@density * 255 * @intensity).to_u8
            fog_tint = RL::Color.new(
              r: @color.r,
              g: @color.g,
              b: @color.b,
              a: fog_alpha
            )

            # Blend fog color with layer tint
            original = layer.tint
            layer.tint = RL::Color.new(
              r: ((original.r * (255 - fog_alpha) + fog_tint.r * fog_alpha) / 255).to_u8,
              g: ((original.g * (255 - fog_alpha) + fog_tint.g * fog_alpha) / 255).to_u8,
              b: ((original.b * (255 - fog_alpha) + fog_tint.b * fog_alpha) / 255).to_u8,
              a: original.a
            )
          end

          # Draw fog overlay (called separately after layer rendering)
          def draw_overlay(renderer : PointClickEngine::Graphics::Renderer, viewport_width : Int32, viewport_height : Int32)
            # Draw fog layers
            @fog_layers.each do |fog_layer|
              fog_layer.draw(viewport_width, viewport_height, @fog_offset, @color, @density * @intensity)
            end
          end
        end

        # Individual fog layer for parallax effect
        class FogLayer
          property depth : Float32
          property opacity : Float32
          property speed_multiplier : Float32
          property offset : Float32 = 0.0f32

          def initialize(@depth : Float32, @opacity : Float32, @speed_multiplier : Float32)
          end

          def update(dt : Float32)
            @offset += dt * @speed_multiplier
          end

          def draw(width : Int32, height : Int32, base_offset : Float32, color : RL::Color, density : Float32)
            # Simple fog visualization using gradients
            # In real implementation would use fog textures or shaders
            fog_height = (height * 0.3 * @depth).to_i
            y_pos = (height * (1.0 - @depth)).to_i

            alpha = (@opacity * density * 255).to_u8
            fog_color = RL::Color.new(r: color.r, g: color.g, b: color.b, a: alpha)

            # Draw gradient rectangle for fog
            RL.draw_rectangle_gradient_v(
              0, y_pos,
              width, fog_height,
              RL::Color.new(r: color.r, g: color.g, b: color.b, a: 0),
              fog_color
            )
          end
        end

        # Rain effect with particles
        class RainEffect < BaseSceneEffect
          property intensity : Float32 = 0.5f32
          property wind_speed : Float32 = -20.0f32 # Negative = blowing left
          property drop_speed : Float32 = 400.0f32
          property drop_color : RL::Color = RL::Color.new(r: 150, g: 150, b: 200, a: 100)

          @rain_drops : Array(RainDrop)
          @max_drops : Int32

          def initialize(@intensity : Float32 = 0.5f32, duration : Float32 = 0.0f32)
            super(duration)
            @max_drops = (200 * @intensity).to_i
            @rain_drops = [] of RainDrop

            # Pre-populate some drops
            @max_drops.times do
              @rain_drops << create_random_drop(Random.rand(Display::REFERENCE_HEIGHT))
            end
          end

          def update(dt : Float32)
            super

            # Update existing drops
            @rain_drops.each do |drop|
              drop.update(dt, @wind_speed, @drop_speed)
            end

            # Remove drops that have fallen off screen
            @rain_drops.reject! { |drop| drop.position.y > Display::REFERENCE_HEIGHT + 10 }

            # Spawn new drops
            drops_to_spawn = (@max_drops - @rain_drops.size)
            drops_to_spawn.times do
              @rain_drops << create_random_drop(-10)
            end
          end

          def apply(context : EffectContext)
            # Rain is drawn as overlay
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Apply slight blue tint during rain
            if layer.is_a?(Layers::SceneLayer)
              tint_amount = 0.1f32 * @intensity
              original = layer.tint
              layer.tint = RL::Color.new(
                r: (original.r * (1 - tint_amount) + 180 * tint_amount).to_u8,
                g: (original.g * (1 - tint_amount) + 180 * tint_amount).to_u8,
                b: (original.b * (1 - tint_amount) + 200 * tint_amount).to_u8,
                a: original.a
              )
            end
          end

          # Draw rain drops
          def draw_overlay(renderer : PointClickEngine::Graphics::Renderer)
            @rain_drops.each(&.draw(@drop_color))
          end

          private def create_random_drop(y : Number) : RainDrop
            RainDrop.new(
              RL::Vector2.new(
                x: Random.rand(Display::REFERENCE_WIDTH + 200) - 100, # Account for wind
                y: y.to_f32
              ),
              Random.rand(0.5f32..1.0f32), # Size variation
              Random.rand(0.8f32..1.2f32)  # Speed variation
            )
          end
        end

        # Individual rain drop
        class RainDrop
          property position : RL::Vector2
          property size : Float32
          property speed_multiplier : Float32

          def initialize(@position : RL::Vector2, @size : Float32 = 1.0f32, @speed_multiplier : Float32 = 1.0f32)
          end

          def update(dt : Float32, wind_speed : Float32, drop_speed : Float32)
            @position.x += wind_speed * dt
            @position.y += drop_speed * @speed_multiplier * dt
          end

          def draw(color : RL::Color)
            # Draw rain drop as a line
            length = 10.0f32 * @size * @speed_multiplier
            RL.draw_line_ex(
              @position,
              RL::Vector2.new(x: @position.x - 2, y: @position.y + length),
              @size,
              color
            )
          end
        end

        # Darkness effect with light sources
        class DarknessEffect < BaseSceneEffect
          property intensity : Float32 = 0.7f32
          property darkness_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 20, a: 200)
          property light_sources : Array(LightSource) = [] of LightSource

          def initialize(@intensity : Float32 = 0.7f32, duration : Float32 = 0.0f32)
            super(duration)
          end

          def add_light(position : RL::Vector2, radius : Float32, color : RL::Color, flicker : Bool = false)
            @light_sources << LightSource.new(position, radius, color, flicker)
          end

          def update(dt : Float32)
            super
            @light_sources.each(&.update(dt))
          end

          def apply(context : EffectContext)
            # Darkness is applied as overlay
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Don't darken UI layer
            return if layer.is_a?(Layers::UILayer)

            # Apply darkness tint
            darkness_alpha = (@intensity * 255).to_u8
            original = layer.tint

            # Darken the layer
            layer.tint = RL::Color.new(
              r: (original.r * (255 - darkness_alpha) / 255).to_u8,
              g: (original.g * (255 - darkness_alpha) / 255).to_u8,
              b: (original.b * (255 - darkness_alpha) / 255).to_u8,
              a: original.a
            )
          end

          # Draw darkness overlay with light cutouts
          def draw_overlay(renderer : PointClickEngine::Graphics::Renderer, viewport_width : Int32, viewport_height : Int32)
            # In a real implementation, this would use a render texture and blend modes
            # For now, just draw a dark overlay
            darkness_alpha = (@intensity * 255 * 0.8).to_u8
            overlay_color = RL::Color.new(
              r: @darkness_color.r,
              g: @darkness_color.g,
              b: @darkness_color.b,
              a: darkness_alpha
            )

            RL.draw_rectangle(0, 0, viewport_width, viewport_height, overlay_color)

            # Draw light sources (simplified - no proper blending)
            @light_sources.each do |light|
              light.draw(renderer.camera)
            end
          end
        end

        # Light source for darkness effect
        class LightSource
          property position : RL::Vector2
          property radius : Float32
          property color : RL::Color
          property flicker : Bool
          property enabled : Bool = true

          @flicker_time : Float32 = 0.0f32
          @base_radius : Float32

          def initialize(@position : RL::Vector2, @radius : Float32, @color : RL::Color, @flicker : Bool = false)
            @base_radius = @radius
          end

          def update(dt : Float32)
            return unless @flicker && @enabled

            @flicker_time += dt
            flicker_amount = (Math.sin(@flicker_time * 10) * 0.1 + 0.95).to_f32
            @radius = @base_radius * flicker_amount
          end

          def draw(camera : PointClickEngine::Graphics::Camera)
            return unless @enabled

            # Convert to screen position
            screen_pos = camera.apply_offset(@position.x, @position.y)

            # Draw light gradient (simplified)
            steps = 5
            steps.times do |i|
              alpha = ((1.0 - i.to_f / steps) * @color.a).to_u8
              radius = @radius * (1.0 - i.to_f / steps)

              color = RL::Color.new(
                r: @color.r,
                g: @color.g,
                b: @color.b,
                a: alpha
              )

              RL.draw_circle(screen_pos.x.to_i, screen_pos.y.to_i, radius, color)
            end
          end
        end

        # Underwater effect using wave distortion and color
        class UnderwaterEffect < BaseSceneEffect
          property wave_amplitude : Float32 = 0.02f32
          property wave_frequency : Float32 = 3.0f32
          property bubble_count : Int32 = 20
          property tint_color : RL::Color = RL::Color.new(r: 100, g: 150, b: 200, a: 100)

          # Reuse float effect for wave motion
          @wave_effect : ObjectEffects::FloatEffect
          @bubbles : Array(Bubble)

          def initialize(duration : Float32 = 0.0f32)
            super(duration)
            @wave_effect = ObjectEffects::FloatEffect.new(10.0f32, 0.5f32)
            @bubbles = [] of Bubble

            # Create initial bubbles
            @bubble_count.times do
              @bubbles << create_random_bubble
            end
          end

          def update(dt : Float32)
            super
            @wave_effect.update(dt)

            # Update bubbles
            @bubbles.each(&.update(dt))
            @bubbles.reject! { |b| b.position.y < -20 }

            # Spawn new bubbles
            while @bubbles.size < @bubble_count
              @bubbles << create_random_bubble
            end
          end

          def apply(context : EffectContext)
            # Underwater effect modifies how everything is rendered
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Apply blue tint
            return if layer.is_a?(Layers::UILayer)

            original = layer.tint
            blend = 0.3f32 * @intensity

            layer.tint = RL::Color.new(
              r: (original.r * (1 - blend) + @tint_color.r * blend).to_u8,
              g: (original.g * (1 - blend) + @tint_color.g * blend).to_u8,
              b: (original.b * (1 - blend) + @tint_color.b * blend).to_u8,
              a: original.a
            )

            # Apply wave motion to scene layers
            if layer.is_a?(Layers::SceneLayer)
              # Use the float effect's motion for wave-like movement
              wave_offset = Math.sin(@wave_effect.elapsed * @wave_frequency) * @wave_amplitude * 100
              layer.offset.y = wave_offset
            end
          end

          def draw_overlay(renderer : PointClickEngine::Graphics::Renderer)
            # Draw bubbles
            @bubbles.each(&.draw)
          end

          private def create_random_bubble : Bubble
            Bubble.new(
              RL::Vector2.new(
                x: Random.rand(Display::REFERENCE_WIDTH),
                y: Display::REFERENCE_HEIGHT + 20
              ),
              Random.rand(3.0f32..8.0f32),  # Size
              Random.rand(30.0f32..80.0f32) # Speed
            )
          end
        end

        # Bubble for underwater effect
        class Bubble
          property position : RL::Vector2
          property size : Float32
          property rise_speed : Float32
          @wobble_time : Float32 = Random.rand(Math::PI * 2).to_f32

          def initialize(@position : RL::Vector2, @size : Float32, @rise_speed : Float32)
          end

          def update(dt : Float32)
            @position.y -= @rise_speed * dt
            @wobble_time += dt * 2
            @position.x += Math.sin(@wobble_time) * 20 * dt # Wobble side to side
          end

          def draw
            RL.draw_circle_lines(@position.x.to_i, @position.y.to_i, @size,
              RL::Color.new(r: 200, g: 200, b: 255, a: 100))
          end
        end
      end
    end
  end
end
