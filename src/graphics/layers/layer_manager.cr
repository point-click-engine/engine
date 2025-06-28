# Layer management system for organizing rendering

require "./layer"

module PointClickEngine
  module Graphics
    module Layers
      # Manages multiple rendering layers
      #
      # LayerManager organizes rendering into z-ordered layers, each with
      # independent properties like parallax scrolling and opacity.
      #
      # ## Example
      #
      # ```
      # layers = LayerManager.new
      # layers.add_default_layers
      #
      # # Add custom layer
      # clouds = Layer.new("clouds", 50)
      # clouds.parallax_factor = 0.3
      # layers.add_layer(clouds)
      #
      # # Render all layers
      # layers.render(camera, renderer) do |layer|
      #   # Render objects in layer
      # end
      # ```
      class LayerManager
        # All managed layers
        getter layers : Array(Layer)

        # Quick access to common layers
        getter background_layer : BackgroundLayer?
        getter scene_layer : SceneLayer?
        getter foreground_layer : ForegroundLayer?
        getter ui_layer : UILayer?

        def initialize
          @layers = [] of Layer
        end

        # Add default layers for a typical adventure game
        def add_default_layers
          # Background layer
          @background_layer = BackgroundLayer.new("background")
          add_layer(@background_layer.not_nil!)

          # Main scene layer
          @scene_layer = SceneLayer.new("scene")
          add_layer(@scene_layer.not_nil!)

          # Foreground layer
          @foreground_layer = ForegroundLayer.new("foreground")
          add_layer(@foreground_layer.not_nil!)

          # UI layer (always on top)
          @ui_layer = UILayer.new("ui")
          add_layer(@ui_layer.not_nil!)
        end

        # Add a layer
        def add_layer(layer : Layer)
          @layers << layer
          sort_layers
        end

        # Remove a layer
        def remove_layer(layer : Layer)
          @layers.delete(layer)
        end

        # Remove layer by name
        def remove_layer(name : String)
          @layers.reject! { |layer| layer.name == name }
        end

        # Get layer by name
        def get_layer(name : String) : Layer?
          @layers.find { |layer| layer.name == name }
        end

        # Get layer by z-order (exact match)
        def get_layer_at_z(z_order : Int32) : Layer?
          @layers.find { |layer| layer.z_order == z_order }
        end

        # Get all layers at or above z-order
        def get_layers_above(z_order : Int32) : Array(Layer)
          @layers.select { |layer| layer.z_order >= z_order }
        end

        # Get all layers at or below z-order
        def get_layers_below(z_order : Int32) : Array(Layer)
          @layers.select { |layer| layer.z_order <= z_order }
        end

        # Update all layers
        def update(dt : Float32)
          @layers.each(&.update(dt))
        end

        # Render all layers in order
        def render(camera : PointClickEngine::Graphics::Camera, renderer : PointClickEngine::Graphics::Renderer, &block : Layer ->)
          @layers.each do |layer|
            next unless layer.should_render?

            # Special handling for background layer
            if layer.is_a?(BackgroundLayer)
              layer.draw_background(
                PointClickEngine::Graphics::Display::REFERENCE_WIDTH,
                PointClickEngine::Graphics::Display::REFERENCE_HEIGHT
              )
            end

            # Apply layer transform
            layer.apply_transform(camera, renderer)

            # Yield to render objects in this layer
            yield layer

            # Reset transform
            layer.reset_transform
          end
        end

        # Set layer visibility
        def set_layer_visible(name : String, visible : Bool)
          if layer = get_layer(name)
            layer.visible = visible
          end
        end

        # Set layer opacity
        def set_layer_opacity(name : String, opacity : Float32)
          if layer = get_layer(name)
            layer.opacity = opacity.clamp(0.0f32, 1.0f32)
          end
        end

        # Fade layer in/out (returns true when complete)
        def fade_layer(name : String, target_opacity : Float32,
                       speed : Float32, dt : Float32) : Bool
          return true unless layer = get_layer(name)

          current = layer.opacity
          diff = target_opacity - current

          if diff.abs < 0.01f32
            layer.opacity = target_opacity
            return true
          end

          change = diff.sign * speed * dt
          if diff.abs < change.abs
            layer.opacity = target_opacity
            return true
          else
            layer.opacity += change
            return false
          end
        end

        # Move layer in z-order
        def set_layer_z_order(name : String, new_z_order : Int32)
          if layer = get_layer(name)
            layer.z_order = new_z_order
            sort_layers
          end
        end

        # Clear all layers
        def clear
          @layers.each do |layer|
            layer.cleanup if layer.responds_to?(:cleanup)
          end
          @layers.clear

          @background_layer = nil
          @scene_layer = nil
          @foreground_layer = nil
          @ui_layer = nil
        end

        private def sort_layers
          @layers.sort! { |a, b| a.z_order <=> b.z_order }
        end
      end
    end
  end
end
