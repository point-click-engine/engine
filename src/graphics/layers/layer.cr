# Base layer class for rendering organization

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Layers
      # Base class for rendering layers
      #
      # Layers provide z-ordered rendering and can have independent
      # properties like parallax scrolling, opacity, and effects.
      #
      # ## Example
      #
      # ```
      # background = Layer.new("background", -100)
      # background.parallax_factor = 0.5 # Moves at half camera speed
      #
      # foreground = Layer.new("foreground", 100)
      # foreground.opacity = 0.8
      # ```
      class Layer
        # Layer properties
        property name : String
        property z_order : Int32 # Lower values render first (back)
        property visible : Bool = true
        property opacity : Float32 = 1.0f32
        property parallax_factor : Float32 = 1.0f32 # 0=fixed, 1=normal, >1=faster

        # Layer offset (for scrolling effects independent of camera)
        property offset : RL::Vector2

        # Tint color for the entire layer
        property tint : RL::Color = RL::WHITE

        # Objects in this layer (when integrated with game objects)
        # @objects : Array(GameObject) = [] of GameObject

        def initialize(@name : String, @z_order : Int32 = 0)
          @offset = RL::Vector2.new(x: 0, y: 0)
        end

        # Store the camera2d for this layer's transformations
        @layer_camera : RL::Camera2D?

        # Apply layer transformations for rendering
        def apply_transform(camera : PointClickEngine::Graphics::Camera, renderer : PointClickEngine::Graphics::Renderer)
          # Create a Camera2D for this layer's transformations
          layer_offset_x = 0.0f32
          layer_offset_y = 0.0f32

          # Apply parallax scrolling
          if @parallax_factor != 1.0f32
            layer_offset_x = camera.position.x * (1.0f32 - @parallax_factor)
            layer_offset_y = camera.position.y * (1.0f32 - @parallax_factor)
          end

          # Create Camera2D with combined transformations
          @layer_camera = RL::Camera2D.new(
            offset: RL::Vector2.new(x: 0, y: 0),
            target: RL::Vector2.new(
              x: -layer_offset_x - @offset.x,
              y: -layer_offset_y - @offset.y
            ),
            rotation: 0.0f32,
            zoom: 1.0f32
          )

          RL.begin_mode_2d(@layer_camera.not_nil!)
        end

        # Reset transformations
        def reset_transform
          RL.end_mode_2d if @layer_camera
          @layer_camera = nil
        end

        # Calculate effective tint with opacity
        def effective_tint : RL::Color
          RL::Color.new(
            r: @tint.r,
            g: @tint.g,
            b: @tint.b,
            a: (@tint.a * @opacity).to_u8
          )
        end

        # Check if layer should be rendered
        def should_render? : Bool
          @visible && @opacity > 0.0f32
        end

        # Update layer (for animated properties)
        def update(dt : Float32)
          # Base layer has no update logic
          # Subclasses can override for animations
        end
      end

      # Specialized background layer with additional features
      class BackgroundLayer < Layer
        property background_texture : RL::Texture2D?
        property tile_mode : TileMode = TileMode::Stretch
        property scroll_speed : RL::Vector2 # Auto-scrolling

        enum TileMode
          Stretch # Stretch to fill
          Tile    # Repeat texture
          Center  # Center without scaling
          Fit     # Fit maintaining aspect ratio
        end

        def initialize(name : String, texture_path : String? = nil)
          super(name, -1000) # Far background
          @scroll_speed = RL::Vector2.new(x: 0, y: 0)

          if path = texture_path
            @background_texture = RL.load_texture(path)
          end
        end

        def update(dt : Float32)
          super

          # Apply auto-scrolling
          @offset.x += @scroll_speed.x * dt
          @offset.y += @scroll_speed.y * dt
        end

        def draw_background(viewport_width : Int32, viewport_height : Int32)
          return unless texture = @background_texture

          case @tile_mode
          when .stretch?
            dest = RL::Rectangle.new(
              x: 0, y: 0,
              width: viewport_width.to_f32,
              height: viewport_height.to_f32
            )
            source = RL::Rectangle.new(
              x: 0, y: 0,
              width: texture.width.to_f32,
              height: texture.height.to_f32
            )
            RL.draw_texture_pro(texture, source, dest,
              RL::Vector2.new(x: 0, y: 0), 0, effective_tint)
          when .tile?
            # Calculate tile counts needed
            tiles_x = (viewport_width.to_f / texture.width).ceil.to_i + 1
            tiles_y = (viewport_height.to_f / texture.height).ceil.to_i + 1

            # Calculate tile offset for seamless scrolling
            offset_x = (@offset.x % texture.width).to_i
            offset_y = (@offset.y % texture.height).to_i

            (0..tiles_y).each do |y|
              (0..tiles_x).each do |x|
                RL.draw_texture(
                  texture,
                  x * texture.width - offset_x,
                  y * texture.height - offset_y,
                  effective_tint
                )
              end
            end
          when .center?
            x = (viewport_width - texture.width) / 2
            y = (viewport_height - texture.height) / 2
            RL.draw_texture(texture, x, y, effective_tint)
          when .fit?
            # Calculate scale to fit
            scale_x = viewport_width.to_f / texture.width
            scale_y = viewport_height.to_f / texture.height
            scale = Math.min(scale_x, scale_y)

            width = texture.width * scale
            height = texture.height * scale
            x = (viewport_width - width) / 2
            y = (viewport_height - height) / 2

            dest = RL::Rectangle.new(x: x, y: y, width: width, height: height)
            source = RL::Rectangle.new(
              x: 0, y: 0,
              width: texture.width.to_f32,
              height: texture.height.to_f32
            )
            RL.draw_texture_pro(texture, source, dest,
              RL::Vector2.new(x: 0, y: 0), 0, effective_tint)
          end
        end

        def cleanup
          if texture = @background_texture
            RL.unload_texture(texture)
            @background_texture = nil
          end
        end
      end

      # UI layer that ignores camera transformations
      class UILayer < Layer
        def initialize(name : String = "ui")
          super(name, 1000) # Top layer
        end

        # UI layer doesn't apply camera transform
        def apply_transform(camera : PointClickEngine::Graphics::Camera, renderer : PointClickEngine::Graphics::Renderer)
          # No camera transform for UI - just apply layer offset
          @layer_camera = RL::Camera2D.new(
            offset: RL::Vector2.new(x: 0, y: 0),
            target: RL::Vector2.new(x: -@offset.x, y: -@offset.y),
            rotation: 0.0f32,
            zoom: 1.0f32
          )

          RL.begin_mode_2d(@layer_camera.not_nil!)
        end
      end

      # Scene layer for game objects
      class SceneLayer < Layer
        def initialize(name : String = "scene")
          super(name, 0) # Middle layer
        end
      end

      # Foreground layer for objects in front
      class ForegroundLayer < Layer
        def initialize(name : String = "foreground")
          super(name, 100)
        end
      end
    end
  end
end
