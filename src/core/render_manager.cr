# Rendering management system for the Point & Click Engine
#
# Centralizes rendering operations, layer management, and visual effects.
# Extracted from the Engine class to provide better separation of concerns
# and more sophisticated rendering capabilities.

require "raylib-cr"
require "./error_handling"
require "./game_constants"

# Using full Raylib module name to avoid alias conflicts

module PointClickEngine
  module Core
    # Manages all rendering operations including layer management, effects, and optimization
    #
    # The RenderManager centralizes rendering logic that was previously
    # scattered throughout the Engine class. It provides layer-based rendering,
    # visual effects, performance optimization, and debug visualization.
    #
    # ## Features
    # - Layer-based rendering with z-ordering
    # - Visual effects and transitions
    # - Performance optimization and culling
    # - Debug visualization modes
    # - Render target management
    # - Camera integration
    #
    # ## Usage
    # ```
    # manager = RenderManager.new
    # manager.add_render_layer("background", -10)
    # manager.add_render_layer("game_objects", 0)
    # manager.add_render_layer("ui", 10)
    # manager.render(dt)
    # ```
    class RenderManager
      include ErrorHelpers
      include GameConstants
      include IRenderManager

      # Render layer with priority and enabled state
      private record RenderLayer,
        name : String,
        priority : Int32,
        enabled : Bool = true,
        renderers : Array(Proc(Float32, Nil)) = [] of Proc(Float32, Nil)

      # Rendering layers ordered by priority (lower priority rendered first)
      @render_layers : Array(RenderLayer) = [] of RenderLayer

      # Rendering state
      @ui_visible : Bool = true
      @debug_mode : Bool = false
      @show_fps : Bool = false
      @show_bounds : Bool = false
      @show_hotspots : Bool = false

      # Hotspot highlighting
      @hotspot_highlight_enabled : Bool = false
      @hotspot_highlight_color : Raylib::Color = Raylib::Color.new(r: 255, g: 215, b: 0, a: 128) # Golden
      @hotspot_highlight_pulse : Bool = true
      @highlight_pulse_time : Float32 = 0.0_f32

      # Performance tracking
      @frame_count : Int32 = 0
      @render_time : Float32 = 0.0_f32
      @last_fps_update : Float32 = 0.0_f32
      @current_fps : Float32 = 0.0_f32

      # Render statistics
      @objects_rendered : Int32 = 0
      @objects_culled : Int32 = 0
      @draw_calls : Int32 = 0

      def initialize
        setup_default_layers
        ErrorLogger.info("RenderManager initialized")
      end

      # Add a render layer with specified priority
      #
      # Lower priority values are rendered first (background),
      # higher priority values are rendered last (foreground/UI).
      #
      # - *name* : Unique name for the layer
      # - *priority* : Render priority (lower = background)
      # - *enabled* : Whether the layer is initially enabled
      def add_render_layer(name : String, priority : Int32, enabled : Bool = true) : Result(Nil, RenderError)
        # Check if layer already exists
        if @render_layers.any? { |layer| layer.name == name }
          return Result(Nil, RenderError).failure(RenderError.new("Render layer '#{name}' already exists"))
        end

        layer = RenderLayer.new(name, priority, enabled)
        @render_layers << layer
        @render_layers.sort_by! { |l| l.priority }

        ErrorLogger.debug("Render layer added: #{name} (priority: #{priority})")
        Result(Nil, RenderError).success(nil)
      end

      # Add a renderer to a specific layer
      #
      # - *layer_name* : Name of the layer to add to
      # - *renderer* : The rendering function
      def add_renderer(layer_name : String, renderer : Proc(Float32, Nil)) : Result(Nil, RenderError)
        layer_index = @render_layers.index { |layer| layer.name == layer_name }
        unless layer_index
          return Result(Nil, RenderError).failure(RenderError.new("Render layer '#{layer_name}' not found"))
        end

        layer = @render_layers[layer_index]
        new_renderers = layer.renderers.dup
        new_renderers << renderer

        @render_layers[layer_index] = RenderLayer.new(
          layer.name, layer.priority, layer.enabled, new_renderers
        )

        ErrorLogger.debug("Renderer added to layer: #{layer_name}")
        Result(Nil, RenderError).success(nil)
      end

      # Remove a renderer from a layer
      def remove_renderer(layer_name : String, renderer : Proc(Float32, Nil)) : Result(Bool, RenderError)
        layer_index = @render_layers.index { |layer| layer.name == layer_name }
        unless layer_index
          return Result(Bool, RenderError).failure(RenderError.new("Render layer '#{layer_name}' not found"))
        end

        layer = @render_layers[layer_index]
        new_renderers = layer.renderers.reject { |r| r == renderer }
        removed = new_renderers.size < layer.renderers.size

        @render_layers[layer_index] = RenderLayer.new(
          layer.name, layer.priority, layer.enabled, new_renderers
        )

        ErrorLogger.debug("Renderer removed from layer: #{layer_name}") if removed
        Result(Bool, RenderError).success(removed)
      end

      # Enable or disable a render layer
      def set_layer_enabled(layer_name : String, enabled : Bool) : Result(Nil, RenderError)
        layer_index = @render_layers.index { |layer| layer.name == layer_name }
        unless layer_index
          return Result(Nil, RenderError).failure(RenderError.new("Render layer '#{layer_name}' not found"))
        end

        layer = @render_layers[layer_index]
        @render_layers[layer_index] = RenderLayer.new(
          layer.name, layer.priority, enabled, layer.renderers
        )

        ErrorLogger.debug("Layer #{layer_name} enabled: #{enabled}")
        Result(Nil, RenderError).success(nil)
      end

      # Main rendering method
      #
      # Renders all enabled layers in priority order and handles
      # debug visualization, performance tracking, and effects.
      #
      # - *dt* : Delta time since last frame
      def render(dt : Float32)
        start_time = Time.monotonic

        # Reset frame statistics
        @objects_rendered = 0
        @objects_culled = 0
        @draw_calls = 0

        RL.begin_drawing
        RL.clear_background(Raylib::BLACK)

        # Render all layers in priority order
        @render_layers.each do |layer|
          next unless layer.enabled

          layer.renderers.each do |renderer|
            renderer.call(dt)
            @draw_calls += 1
          end
        end

        # Render debug information if enabled
        render_debug_info(dt) if @debug_mode

        # Render FPS counter if enabled
        render_fps_counter if @show_fps

        RL.end_drawing

        # Update performance statistics
        end_time = Time.monotonic
        @render_time = (end_time - start_time).total_milliseconds.to_f32
        update_fps_counter(dt)
        @frame_count += 1
      end

      # Render a scene with camera support
      #
      # Specialized rendering method for scenes that handles camera
      # transformations, culling, and scene-specific rendering.
      def render_scene(scene : Scenes::Scene?, camera : Graphics::Camera? = nil, dt : Float32 = 0.0_f32)
        return unless scene

        if camera
          # Render with camera transformations by passing camera to draw methods
          render_scene_content(scene, camera, dt)
        else
          # Render without camera transformations
          render_scene_content(scene, nil, dt)
        end
      end

      # UI visibility controls

      def show_ui
        @ui_visible = true
        set_layer_enabled("ui", true)
      end

      def hide_ui
        @ui_visible = false
        set_layer_enabled("ui", false)
      end

      def ui_visible? : Bool
        @ui_visible
      end

      # Debug visualization controls

      def enable_debug_mode
        @debug_mode = true
        ErrorLogger.info("Debug rendering enabled")
      end

      def disable_debug_mode
        @debug_mode = false
        ErrorLogger.info("Debug rendering disabled")
      end

      def debug_mode? : Bool
        @debug_mode
      end

      def set_debug_options(show_bounds : Bool = false, show_hotspots : Bool = false, show_fps : Bool = false)
        @show_bounds = show_bounds
        @show_hotspots = show_hotspots
        @show_fps = show_fps
      end

      # Hotspot highlighting

      def enable_hotspot_highlighting(color : Raylib::Color? = nil, pulse : Bool = true)
        @hotspot_highlight_enabled = true
        @hotspot_highlight_color = color if color
        @hotspot_highlight_pulse = pulse
        ErrorLogger.debug("Hotspot highlighting enabled")
      end

      def disable_hotspot_highlighting
        @hotspot_highlight_enabled = false
        ErrorLogger.debug("Hotspot highlighting disabled")
      end

      def hotspot_highlighting_enabled? : Bool
        @hotspot_highlight_enabled
      end

      # Performance and statistics

      def get_render_stats : {objects_rendered: Int32, objects_culled: Int32, draw_calls: Int32, render_time: Float32, fps: Float32}
        {
          objects_rendered: @objects_rendered,
          objects_culled:   @objects_culled,
          draw_calls:       @draw_calls,
          render_time:      @render_time,
          fps:              @current_fps,
        }
      end

      def reset_stats
        @frame_count = 0
        @render_time = 0.0_f32
        @objects_rendered = 0
        @objects_culled = 0
        @draw_calls = 0
      end

      private def setup_default_layers
        add_render_layer("background", -100)
        add_render_layer("scene_objects", 0)
        add_render_layer("characters", 10)
        add_render_layer("effects", 20)
        add_render_layer("ui", 100)
        add_render_layer("debug", 1000)
      end

      private def render_scene_content(scene : Scenes::Scene, camera : Graphics::Camera?, dt : Float32)
        # Render background
        if bg = scene.background
          render_background(bg, camera)
        end

        # Render scene objects with depth sorting
        render_scene_objects(scene, camera)

        # Render characters with depth sorting
        render_characters(scene, camera)

        # Render hotspots if highlighted
        if @hotspot_highlight_enabled || @show_hotspots
          render_hotspots(scene, camera, dt)
        end

        # Render debug information for scene
        if @debug_mode
          render_scene_debug(scene, camera)
        end
      end

      private def render_background(background, camera)
        # This would render the scene background
        # Implementation depends on background type and camera
        @objects_rendered += 1
      end

      private def render_scene_objects(scene, camera)
        # Render scene objects (hotspots, etc.)
        scene.objects.each do |obj|
          if should_render_object(obj, camera)
            obj.draw
            @objects_rendered += 1
          else
            @objects_culled += 1
          end
        end
      rescue
        # Handle case where scene doesn't have objects method
      end

      private def render_characters(scene, camera)
        # Render characters sorted by Y position (depth)
        if scene.responds_to?(:characters)
          characters = scene.characters.sort_by { |char| char.position.y }
          characters.each do |character|
            if should_render_object(character, camera)
              character.draw
              @objects_rendered += 1
            else
              @objects_culled += 1
            end
          end
        end
      rescue
        # Handle rendering errors gracefully
      end

      private def render_hotspots(scene, camera, dt)
        return unless scene.responds_to?(:hotspots)

        @highlight_pulse_time += dt
        alpha = if @hotspot_highlight_pulse
                  (Math.sin(@highlight_pulse_time * 3.0) * 0.3 + 0.7) * 255
                else
                  @hotspot_highlight_color.a
                end

        highlight_color = Raylib::Color.new(
          r: @hotspot_highlight_color.r,
          g: @hotspot_highlight_color.g,
          b: @hotspot_highlight_color.b,
          a: alpha.to_u8
        )

        scene.hotspots.each do |hotspot|
          # Render hotspot highlight
          # This would need to be implemented based on hotspot structure
          @objects_rendered += 1
        end
      rescue
        # Handle hotspot rendering errors
      end

      private def render_scene_debug(scene, camera)
        if @show_bounds && scene.responds_to?(:characters)
          scene.characters.each do |character|
            bounds = character.bounds
            RL.draw_rectangle_lines_ex(bounds, DEBUG_LINE_THICKNESS, Raylib::GREEN)
          end
        end
      rescue
        # Handle debug rendering errors
      end

      private def should_render_object(object, camera) : Bool
        # Simple culling - in a full implementation this would check
        # if the object is within the camera's viewport
        return true unless camera

        # For now, always render (no culling)
        true
      end

      private def render_debug_info(dt)
        return unless @debug_mode

        y_offset = 10
        line_height = 20

        # Render performance info
        RL.draw_text("Objects Rendered: #{@objects_rendered}", 10, y_offset, 16, Raylib::WHITE)
        y_offset += line_height

        RL.draw_text("Objects Culled: #{@objects_culled}", 10, y_offset, 16, Raylib::WHITE)
        y_offset += line_height

        RL.draw_text("Draw Calls: #{@draw_calls}", 10, y_offset, 16, Raylib::WHITE)
        y_offset += line_height

        RL.draw_text("Render Time: #{@render_time.round(2)}ms", 10, y_offset, 16, Raylib::WHITE)
        y_offset += line_height

        RL.draw_text("FPS: #{@current_fps.round(1)}", 10, y_offset, 16, Raylib::WHITE)
      end

      private def render_fps_counter
        RL.draw_fps(10, 10)
      end

      private def update_fps_counter(dt)
        @last_fps_update += dt
        if @last_fps_update >= 1.0
          @current_fps = @frame_count / @last_fps_update
          @frame_count = 0
          @last_fps_update = 0.0_f32
        end
      end
    end
  end
end
