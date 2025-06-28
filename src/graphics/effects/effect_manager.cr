# Central manager for all visual effects in the engine

require "./effect"
require "./object_effects"
require "./scene_effects/base_scene_effect"
require "./scene_effects/ambient_effects"
require "./camera_effects"

module PointClickEngine
  module Graphics
    module Effects
      # Manages effects at different levels (object, scene, camera)
      class EffectManager
        # Scene-wide effects
        @scene_effects : EffectComponent

        # Camera effects
        @camera_effects : EffectComponent

        # Global post-processing effects
        @post_process_effects : EffectComponent

        # Effect pools for reuse
        @effect_pools : Hash(String, Array(Effect))

        # Active effect components by target
        @object_effects : Hash(UInt64, EffectComponent)

        def initialize
          @scene_effects = EffectComponent.new
          @camera_effects = EffectComponent.new
          @post_process_effects = EffectComponent.new
          @effect_pools = {} of String => Array(Effect)
          @object_effects = {} of UInt64 => EffectComponent
        end

        # Add effect to an object
        def add_object_effect(object_id : UInt64, effect_name : String, **params) : Effect?
          effect = create_or_pool_effect(effect_name, **params)
          return unless effect

          component = @object_effects[object_id] ||= EffectComponent.new
          component.add_effect(effect)
          effect
        end

        # Add effect to an object using Effect instance
        def add_object_effect(object_id : UInt64, effect : Effect)
          component = @object_effects[object_id] ||= EffectComponent.new
          component.add_effect(effect)
        end

        # Get effect component for object
        def get_object_effects(object_id : UInt64) : EffectComponent?
          @object_effects[object_id]?
        end

        # Remove all effects from object
        def clear_object_effects(object_id : UInt64)
          @object_effects.delete(object_id)
        end

        # Add scene-wide effect
        def add_scene_effect(effect_name : String, **params) : Effect?
          effect = create_scene_effect(effect_name, **params)
          return unless effect

          @scene_effects.add_effect(effect)
          effect
        end

        # Add camera effect
        def add_camera_effect(effect_name : String, **params) : Effect?
          effect = create_camera_effect(effect_name, **params)
          return unless effect

          @camera_effects.add_effect(effect)
          effect
        end

        # Add post-processing effect
        def add_post_process(effect_name : String, **params) : Effect?
          effect = create_or_pool_effect(effect_name, **params)
          return unless effect

          @post_process_effects.add_effect(effect)
          effect
        end

        # Update all effects
        def update(dt : Float32)
          # Update scene effects
          @scene_effects.update(dt)

          # Update camera effects
          @camera_effects.update(dt)

          # Update post-process effects
          @post_process_effects.update(dt)

          # Update all object effects
          @object_effects.each_value(&.update(dt))

          # Clean up finished object effects
          @object_effects.reject! { |_, component| component.active_effects.empty? }

          # Return finished effects to pools
          collect_finished_effects
        end
        
        # Update camera effects and apply to camera
        def update_camera_effects(camera : Graphics::Core::Camera, dt : Float32)
          # Update camera effects
          @camera_effects.update(dt)
          
          # Apply each camera effect directly
          @camera_effects.active_effects.each do |effect|
            if camera_effect = effect.as?(CameraEffects::BaseCameraEffect)
              camera_effect.apply_to_camera(camera, dt)
            end
          end
        end

        # Apply effects to renderer (including camera)
        def apply_to_renderer(renderer : PointClickEngine::Graphics::Renderer, dt : Float32 = 0.016f32)
          # Apply camera effects
          if camera = renderer.camera
            context = EffectContext.new(
              EffectContext::TargetType::Camera,
              renderer,
              dt
            )

            # Apply each camera effect directly
            @camera_effects.active_effects.each do |effect|
              if camera_effect = effect.as?(CameraEffects::BaseCameraEffect)
                camera_effect.apply_to_camera(camera, dt)
              else
                effect.apply(context)
              end
            end
          end
        end

        # Apply effects to a sprite
        def apply_to_sprite(object_id : UInt64, sprite : Sprites::Sprite,
                            renderer : PointClickEngine::Graphics::Renderer, dt : Float32)
          return unless component = @object_effects[object_id]?

          context = EffectContext.new(
            EffectContext::TargetType::Object,
            renderer,
            dt
          )

          context.sprite = sprite
          context.position = sprite.position
          context.bounds = sprite.bounds

          component.apply(context)
        end

        # Apply scene effects
        def apply_scene_effects(renderer : PointClickEngine::Graphics::Renderer, layers : Layers::LayerManager, dt : Float32)
          context = EffectContext.new(
            EffectContext::TargetType::Scene,
            renderer,
            dt
          )

          # Apply each scene effect
          @scene_effects.active_effects.each do |effect|
            if scene_effect = effect.as?(SceneEffects::BaseSceneEffect)
              scene_effect.apply_to_scene(context, layers)
            else
              effect.apply(context)
            end
          end
        end

        # Draw scene effect overlays (for effects that need to draw)
        def draw_scene_overlays(renderer : PointClickEngine::Graphics::Renderer)
          @scene_effects.active_effects.each do |effect|
            case effect
            when SceneEffects::FogEffect
              effect.draw_overlay(renderer, Display::REFERENCE_WIDTH, Display::REFERENCE_HEIGHT)
            when SceneEffects::RainEffect
              effect.draw_overlay(renderer)
            when SceneEffects::DarknessEffect
              effect.draw_overlay(renderer, Display::REFERENCE_WIDTH, Display::REFERENCE_HEIGHT)
            when SceneEffects::UnderwaterEffect
              effect.draw_overlay(renderer)
            end
          end
        end

        # Clear camera effects
        def clear_camera_effects
          @camera_effects.clear_effects
        end
        
        # Clear all effects
        def clear_all
          @scene_effects.clear_effects
          @camera_effects.clear_effects
          @post_process_effects.clear_effects
          @object_effects.clear
        end

        # Get statistics
        def stats : NamedTuple(
          scene_effects: Int32,
          camera_effects: Int32,
          post_process_effects: Int32,
          objects_with_effects: Int32,
          total_object_effects: Int32,
          pooled_effects: Int32)
          total_object_effects = @object_effects.values.sum { |c| c.active_effects.size }
          pooled_effects = @effect_pools.values.sum(&.size)

          {
            scene_effects:        @scene_effects.active_effects.size,
            camera_effects:       @camera_effects.active_effects.size,
            post_process_effects: @post_process_effects.active_effects.size,
            objects_with_effects: @object_effects.size,
            total_object_effects: total_object_effects,
            pooled_effects:       pooled_effects,
          }
        end

        private def create_or_pool_effect(effect_name : String, **params) : Effect?
          pool_key = effect_name

          # Check if we can reuse a pooled effect
          if pool = @effect_pools[pool_key]?
            if effect = pool.pop?
              # Reset and configure pooled effect
              effect.reset
              effect.duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32
              effect.intensity = params[:intensity]?.try(&.as(Number).to_f32) || 1.0f32
              configure_effect(effect, **params)
              return effect
            end
          end

          # Create new effect
          ObjectEffects.create(effect_name, **params)
        end

        private def create_scene_effect(effect_name : String, **params) : Effect?
          # First try scene-specific effects
          if effect = SceneEffects::SceneEffectFactory.create(effect_name, **params)
            return effect
          end

          # Try adapting an object effect
          SceneEffects::SceneEffectFactory.from_object_effect(effect_name, **params)
        end

        private def create_camera_effect(effect_name : String, **params) : Effect?
          CameraEffects.create(effect_name, **params)
        end

        private def configure_effect(effect : Effect, **params)
          # Configure effect based on its type
          # This would be expanded as we add more effect types
          case effect
          when ObjectEffects::HighlightEffect
            effect.color = parse_color(params[:color]?) if params[:color]?
            effect.thickness = params[:thickness]?.try(&.as(Number).to_f32) if params[:thickness]?
            effect.radius = params[:radius]?.try(&.as(Number).to_f32) if params[:radius]?
          when ObjectEffects::ShakeEffect
            effect.amplitude = params[:amplitude]?.try(&.as(Number).to_f32) if params[:amplitude]?
            effect.frequency = params[:frequency]?.try(&.as(Number).to_f32) if params[:frequency]?
            # Add more effect types as needed
          end
        end

        private def collect_finished_effects
          # Collect finished effects from all components for pooling
          collect_from_component(@scene_effects)
          collect_from_component(@camera_effects)
          collect_from_component(@post_process_effects)
          @object_effects.each_value { |component| collect_from_component(component) }
        end

        private def collect_from_component(component : EffectComponent)
          # This would need access to internal effects array
          # For now, effects are cleaned up automatically
        end

        private def parse_color(color_value) : RL::Color?
          ObjectEffects.parse_color(color_value)
        end
      end

      # Global effect manager instance
      class_property effect_manager : EffectManager { EffectManager.new }
    end
  end
end
