# Base scene effect that can reuse object effect logic

require "../effect"
require "../object_effects"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Base class for scene-wide effects that can leverage object effects
        abstract class BaseSceneEffect < Effect
          # The underlying object effect we're adapting
          getter object_effect : Effect?

          # Scene-specific properties
          property affect_all_layers : Bool = true
          property affected_layers : Array(String) = [] of String
          property screen_space : Bool = false # Apply in screen space vs world space

          def initialize(duration : Float32 = 0.0f32)
            super(duration)
          end
          
          # Optional method for shader-based scene effects to override
          def render_scene_with_effect(&block : -> Nil)
            # Default implementation just renders the scene normally
            yield
          end

          # Apply effect to entire scene
          def apply_to_scene(context : EffectContext, layers : Layers::LayerManager)
            if affect_all_layers
              layers.layers.each do |layer|
                apply_to_layer(context, layer)
              end
            else
              affected_layers.each do |layer_name|
                if layer = layers.get_layer(layer_name)
                  apply_to_layer(context, layer)
                end
              end
            end
          end

          # Apply effect to a specific layer
          abstract def apply_to_layer(context : EffectContext, layer : Layers::Layer)
        end

        # Adapter to use object effects at scene level
        class SceneEffectAdapter < BaseSceneEffect
          def initialize(@object_effect : Effect, duration : Float32 = 0.0f32)
            super(duration)
            # Sync duration if not specified
            if @duration == 0
              @duration = @object_effect.try(&.duration) || 0.0f32
            end
          end

          def update(dt : Float32)
            super
            @object_effect.try(&.update(dt))
          end

          def apply(context : EffectContext)
            # This is called by the effect system
            # We'll handle it in apply_to_layer instead
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Apply the object effect to the entire layer
            # This could mean different things depending on the effect
            effect = @object_effect
            return unless effect

            case effect
            when ObjectEffects::ColorShiftEffect
              # Apply color shift to layer tint
              apply_color_to_layer(effect, layer)
            when ObjectEffects::ShakeEffect
              # Apply shake to layer offset
              apply_shake_to_layer(effect, layer)
            when ObjectEffects::DissolveEffect
              # Apply dissolve to layer opacity
              apply_dissolve_to_layer(effect, layer)
            else
              # Generic application
              apply_generic_to_layer(effect, layer)
            end
          end

          private def apply_color_to_layer(effect : ObjectEffects::ColorShiftEffect, layer : Layers::Layer)
            # Create a temporary sprite-like object to get the color
            temp_sprite = Sprites::Sprite.new
            temp_sprite.tint = layer.tint

            # Let the effect modify it
            effect_context = EffectContext.new(
              EffectContext::TargetType::Scene,
              nil,
              0.016f32
            )
            effect_context.sprite = temp_sprite
            effect.apply(effect_context)

            # Apply the modified tint to the layer
            layer.tint = temp_sprite.tint
          end

          private def apply_shake_to_layer(effect : ObjectEffects::ShakeEffect, layer : Layers::Layer)
            # Use shake offset for layer offset
            if effect.responds_to?(:shake_offset)
              layer.offset = effect.shake_offset
            end
          end

          private def apply_dissolve_to_layer(effect : ObjectEffects::DissolveEffect, layer : Layers::Layer)
            # Map dissolve progress to layer opacity
            alpha = case effect.mode
                    when .in?
                      effect.progress
                    when .out?
                      1.0f32 - effect.progress
                    else
                      1.0f32
                    end
            layer.opacity = alpha
          end

          private def apply_generic_to_layer(effect : Effect, layer : Layers::Layer)
            # For other effects, we might need custom handling
            # or just apply them to all objects in the layer
          end
        end

        # Scene-specific shake that moves the entire view
        class SceneShakeEffect < BaseSceneEffect
          property shake_effect : ObjectEffects::ShakeEffect

          def initialize(amplitude : Float32 = 10.0f32, frequency : Float32 = 10.0f32, duration : Float32 = 0.5f32)
            super(duration)
            @shake_effect = ObjectEffects::ShakeEffect.new(amplitude, frequency, duration)
            @screen_space = true # Shake happens in screen space
          end

          def update(dt : Float32)
            super
            @shake_effect.update(dt)
          end

          def apply(context : EffectContext)
            # Apply shake to camera instead of individual objects
            renderer = context.renderer
            return unless renderer
            
            if camera = renderer.camera
              # Store original position
              original_pos = camera.position.dup

              # Apply shake offset
              temp_sprite = Sprites::Sprite.new
              temp_sprite.position = original_pos

              effect_context = EffectContext.new(
                EffectContext::TargetType::Camera,
                renderer,
                context.delta_time
              )
              effect_context.sprite = temp_sprite

              @shake_effect.apply(effect_context)

              # Get the shake offset
              offset_x = temp_sprite.position.x - original_pos.x
              offset_y = temp_sprite.position.y - original_pos.y

              # Apply to camera
              camera.position.x = original_pos.x - offset_x # Negative because camera moves opposite
              camera.position.y = original_pos.y - offset_y
            end
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # For scene shake, we handle it at camera level in apply()
            # So this is a no-op
          end
        end

        # Scene color overlay (affects everything)
        class SceneColorEffect < BaseSceneEffect
          property color_effect : ObjectEffects::ColorShiftEffect

          def initialize(mode : ObjectEffects::ColorShiftEffect::ColorMode,
                         target_color : RL::Color? = nil,
                         duration : Float32 = 0.0f32)
            super(duration)
            @color_effect = ObjectEffects::ColorShiftEffect.new(mode, target_color, duration)
          end

          def update(dt : Float32)
            super
            @color_effect.update(dt)
          end

          def apply(context : EffectContext)
            # This will be handled per-layer
          end

          def apply_to_layer(context : EffectContext, layer : Layers::Layer)
            # Apply color effect to layer tint
            original_tint = layer.tint

            # Create temporary sprite to get color transformation
            temp_sprite = Sprites::Sprite.new
            temp_sprite.tint = original_tint

            effect_context = EffectContext.new(
              EffectContext::TargetType::Scene,
              context.renderer,
              context.delta_time
            )
            effect_context.sprite = temp_sprite

            @color_effect.apply(effect_context)

            # Apply transformed color to layer
            layer.tint = temp_sprite.tint
          end
        end

        # Factory to create scene effects from object effects
        class SceneEffectFactory
          # Create a scene effect that reuses object effect logic
          def self.from_object_effect(effect_name : String, **params) : BaseSceneEffect?
            # Try to create object effect first
            if object_effect = ObjectEffects.create(effect_name, **params)
              # Wrap it in a scene adapter
              adapter = SceneEffectAdapter.new(object_effect)

              # Configure scene-specific params
              if layers = params[:layers]?
                adapter.affect_all_layers = false
                adapter.affected_layers = parse_layer_names(layers)
              end

              adapter.screen_space = params[:screen_space]? == true

              adapter
            else
              nil
            end
          end

          # Create scene-specific effects
          def self.create(effect_name : String, **params) : BaseSceneEffect?
            # Check if it's a transition effect
            if effect_name.downcase == "transition"
              return create_transition(**params)
            end

            case effect_name.downcase
            when "shake", "screen_shake", "camera_shake"
              amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 10.0f32
              frequency = params[:frequency]?.try(&.as(Number).to_f32) || 10.0f32
              duration = params[:duration]?.try(&.as(Number).to_f32) || 0.5f32

              SceneShakeEffect.new(amplitude, frequency, duration)
            when "tint", "color", "color_overlay"
              mode = case params[:mode]?.try(&.to_s)
                     when "flash"     then ObjectEffects::ColorShiftEffect::ColorMode::Flash
                     when "grayscale" then ObjectEffects::ColorShiftEffect::ColorMode::Grayscale
                     when "sepia"     then ObjectEffects::ColorShiftEffect::ColorMode::Sepia
                     else                  ObjectEffects::ColorShiftEffect::ColorMode::Tint
                     end

              color = ObjectEffects.parse_color(params[:color]?)
              duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

              SceneColorEffect.new(mode, color, duration)
            else
              # Try to adapt an object effect
              from_object_effect(effect_name, **params)
            end
          end

          private def self.create_transition(**params) : TransitionEffect?
            # Parse transition type
            type_name = params[:type]?.try(&.to_s) || "fade"
            transition_type = case type_name.downcase
            when "fade"         then TransitionType::Fade
            when "dissolve"     then TransitionType::Dissolve
            when "slide_left"   then TransitionType::SlideLeft
            when "slide_right"  then TransitionType::SlideRight
            when "slide_up"     then TransitionType::SlideUp
            when "slide_down"   then TransitionType::SlideDown
            else TransitionType::Fade
            end
            
            duration = params[:duration]?.try(&.as(Number).to_f32) || 1.0f32
            
            # Create the transition effect
            transition = TransitionEffect.new(transition_type, duration)
            
            # Set midpoint callback if provided
            if callback = params[:on_midpoint]?
              if callback.responds_to?(:call)
                transition.on_midpoint { callback.call }
              end
            end
            
            transition
          end
          
          private def self.parse_layer_names(layers) : Array(String)
            case layers
            when String
              [layers]
            when Array
              layers.map(&.to_s)
            else
              [] of String
            end
          end
        end
      end
    end
  end
end
