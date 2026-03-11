# Glow effect for objects and textures
#
# Provides a soft glow effect by drawing multiple scaled versions
# of the source with decreasing alpha.

require "../effect"

module PointClickEngine
  module Graphics
    module Effects
      module ObjectEffects
        # Glow effect that can be applied to sprites or textures directly
        class GlowEffect < Effect
          property color : RL::Color
          property radius : Float32 = 10.0f32
          property layers : Int32 = 5
          property pulse : Bool = false
          property pulse_speed : Float32 = 2.0f32

          @pulse_time : Float32 = 0.0f32

          def initialize(@color : RL::Color = RL::Color.new(r: 255, g: 255, b: 200, a: 255),
                         @radius : Float32 = 10.0f32,
                         duration : Float32 = 0.0f32)
            super(duration)
          end

          def update(dt : Float32)
            super
            @pulse_time += dt * @pulse_speed if @pulse
          end

          def apply(context : EffectContext)
            return unless sprite = context.sprite
            draw_glow_for_sprite(sprite)
          end

          # Draw glow for a sprite
          def draw_glow_for_sprite(sprite : Sprites::Sprite)
            return unless texture = sprite.texture

            current_intensity = @pulse ? (Math.sin(@pulse_time) + 1.0f32) * 0.5f32 * @intensity : @intensity

            # Draw multiple scaled versions with decreasing alpha
            (1..@layers).reverse_each do |i|
              scale_factor = sprite.scale * (1.0f32 + (i * 0.02f32 * @radius / 10.0f32))
              alpha = (20 * current_intensity / i).to_u8

              glow_color = RL::Color.new(r: @color.r, g: @color.g, b: @color.b, a: alpha)

              original_scale = sprite.scale
              original_tint = sprite.tint

              sprite.scale = scale_factor
              sprite.tint = glow_color
              sprite.draw

              sprite.scale = original_scale
              sprite.tint = original_tint
            end
          end

          # Draw glow directly for a texture at a position (for action sequences)
          def draw_glow_for_texture(texture : Raylib::Texture2D, position : Raylib::Vector2,
                                    scale : Float32 = 1.0f32, alpha : Float32 = 1.0f32)
            current_intensity = @pulse ? (Math.sin(@pulse_time) + 1.0f32) * 0.5f32 * @intensity : @intensity

            # Draw multiple scaled versions with decreasing alpha
            (1..@layers).reverse_each do |i|
              scale_factor = scale * (1.0f32 + (i * 0.02f32 * @radius / 10.0f32))
              layer_alpha = (20 * current_intensity * alpha / i).to_u8

              glow_color = RL::Color.new(r: @color.r, g: @color.g, b: @color.b, a: layer_alpha)

              # Offset to keep centered when scaling
              offset_x = (texture.width * (scale_factor - scale)) / 2
              offset_y = (texture.height * (scale_factor - scale)) / 2
              glow_pos = Raylib::Vector2.new(
                x: position.x - offset_x,
                y: position.y - offset_y
              )

              Raylib.draw_texture_ex(texture, glow_pos, 0.0f32, scale_factor, glow_color)
            end
          end
        end
      end
    end
  end
end
