# Base sprite class for static images

require "raylib-cr"
require "../effects/effect"
require "../effects/object_effects"

module PointClickEngine
  module Graphics
    module Sprites
      # Base sprite class for rendering static images
      #
      # Sprite provides the foundation for all image rendering in the engine.
      # It handles texture loading, positioning, scaling, rotation, and tinting.
      #
      # ## Example
      #
      # ```
      # sprite = Sprite.new("assets/item.png")
      # sprite.position = Vector2.new(100, 200)
      # sprite.scale = 2.0
      # sprite.tint = Color::RED
      # ```
      class Sprite
        # Sprite properties
        property position : RL::Vector2
        property origin : RL::Vector2 # Pivot point for rotation/scaling
        property scale : Float32 = 1.0f32
        property rotation : Float32 = 0.0f32 # In degrees
        property tint : RL::Color = RL::WHITE
        property visible : Bool = true

        # Texture information
        getter texture : RL::Texture2D?
        getter texture_path : String?

        # Source rectangle (for sprite sheets)
        property source_rect : RL::Rectangle?

        # Effects component
        property effects : Effects::EffectComponent?

        # Unique ID for effect tracking
        getter id : UInt64

        # Initialize with texture path
        def initialize(texture_path : String)
          @id = object_id
          @position = RL::Vector2.new(x: 0, y: 0)
          @origin = RL::Vector2.new(x: 0, y: 0)
          load_texture(texture_path)
        end

        # Initialize with position and texture path
        def initialize(x : Float32, y : Float32, texture_path : String)
          @id = object_id
          @position = RL::Vector2.new(x: x, y: y)
          @origin = RL::Vector2.new(x: 0, y: 0)
          load_texture(texture_path)
        end

        # Initialize empty (for deserialization)
        def initialize
          @id = object_id
          @position = RL::Vector2.new(x: 0, y: 0)
          @origin = RL::Vector2.new(x: 0, y: 0)
        end

        # Load texture from file
        def load_texture(path : String)
          @texture_path = path
          # TODO: Use AssetLoader when available
          @texture = RL.load_texture(path)

          # Set default origin to center if not set
          if @origin.x == 0 && @origin.y == 0 && (tex = @texture)
            center_origin
          end
        end

        # Set origin to sprite center
        def center_origin
          if tex = @texture
            @origin = RL::Vector2.new(
              x: tex.width / 2.0f32,
              y: tex.height / 2.0f32
            )
          end
        end

        # Set origin to top-left
        def top_left_origin
          @origin = RL::Vector2.new(x: 0, y: 0)
        end

        # Get sprite bounds in world coordinates
        def bounds : RL::Rectangle
          if tex = @texture
            width = (source_rect.try(&.width) || tex.width) * @scale
            height = (source_rect.try(&.height) || tex.height) * @scale

            RL::Rectangle.new(
              x: @position.x - @origin.x * @scale,
              y: @position.y - @origin.y * @scale,
              width: width,
              height: height
            )
          else
            RL::Rectangle.new(x: @position.x, y: @position.y, width: 0, height: 0)
          end
        end

        # Check if point is inside sprite bounds
        def contains?(x : Float32, y : Float32) : Bool
          bounds = self.bounds
          x >= bounds.x && x <= bounds.x + bounds.width &&
            y >= bounds.y && y <= bounds.y + bounds.height
        end

        # Check if vector is inside sprite bounds
        def contains?(point : RL::Vector2) : Bool
          contains?(point.x, point.y)
        end

        # Draw the sprite
        def draw
          return unless @visible
          return unless tex = @texture

          # Apply effects if present
          if effects = @effects
            # Effects need context - this is simplified
            # In real use, would need renderer context
            return
          end

          source = @source_rect || RL::Rectangle.new(
            x: 0, y: 0,
            width: tex.width.to_f32,
            height: tex.height.to_f32
          )

          dest = RL::Rectangle.new(
            x: @position.x,
            y: @position.y,
            width: source.width * @scale,
            height: source.height * @scale
          )

          RL.draw_texture_pro(
            tex, source, dest,
            @origin * @scale, # Scale the origin too
            @rotation,
            @tint
          )
        end

        # Draw with render context (for camera-aware rendering)
        def draw_with_context(context : PointClickEngine::Graphics::RenderContext,
                              position : RL::Vector2? = nil,
                              tint : RL::Color? = nil)
          return unless @visible
          return unless tex = @texture

          # Apply effects if present
          if effects = @effects
            effect_context = Effects::EffectContext.new(
              Effects::EffectContext::TargetType::Object,
              context.renderer,
              0.016f32 # Assume 60 FPS for now
            )
            effect_context.sprite = self
            effect_context.position = @position
            effect_context.bounds = bounds
            effect_context.texture = tex

            effects.apply(effect_context)
            return
          end

          # Use provided position/tint or sprite's own
          pos = position || @position
          color = tint || @tint

          source = @source_rect || RL::Rectangle.new(
            x: 0, y: 0,
            width: tex.width.to_f32,
            height: tex.height.to_f32
          )

          dest = RL::Rectangle.new(
            x: pos.x,
            y: pos.y,
            width: source.width * @scale,
            height: source.height * @scale
          )

          context.draw_texture_pro(
            tex, source, dest,
            @origin * @scale,
            @rotation,
            color
          )
        end

        # Update sprite (for animation or effects)
        def update(dt : Float32)
          # Update effects if present
          @effects.try(&.update(dt))
        end

        # Cleanup texture resources
        def cleanup
          if tex = @texture
            RL.unload_texture(tex)
            @texture = nil
          end
        end

        # Add an effect to the sprite
        def add_effect(effect : Effects::Effect)
          @effects ||= Effects::EffectComponent.new
          @effects.not_nil!.add_effect(effect)
        end

        # Add effect by name with parameters
        def add_effect(effect_name : String, **params)
          effect = Effects::ObjectEffects.create(effect_name, **params)
          add_effect(effect) if effect
        end

        # Remove all effects of a type
        def remove_effects_of_type(klass : Effects::Effect.class)
          @effects.try(&.remove_effects_of_type(klass))
        end

        # Clear all effects
        def clear_effects
          @effects.try(&.clear_effects)
        end

        # Check if sprite has any active effects
        def has_effects? : Bool
          @effects.try(&.active_effects.any?) || false
        end

        # Clone the sprite
        def clone : Sprite
          sprite = Sprite.new
          sprite.position = @position.dup
          sprite.origin = @origin.dup
          sprite.scale = @scale
          sprite.rotation = @rotation
          sprite.tint = @tint
          sprite.visible = @visible
          sprite.source_rect = @source_rect.try(&.dup)

          # Share the same texture (don't reload)
          if path = @texture_path
            sprite.load_texture(path)
          end

          sprite
        end

        # Utility method to create RL::Vector2 scaled by sprite scale
        private def scaled_origin : RL::Vector2
          RL::Vector2.new(
            x: @origin.x * @scale,
            y: @origin.y * @scale
          )
        end
      end
    end
  end
end
