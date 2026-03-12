# Core Game Engine - Minimal coordination and game loop
#
# The Engine class coordinates all game systems and manages the main game loop.
# It provides direct access to all subsystems through component managers.

require "yaml"
require "./engine/system_manager"
require "./engine/input_handler"
require "./engine/render_coordinator"
require "./engine/verb_input_system"
require "../graphics/graphics"
require "./scene_manager"
require "./input_manager"
require "./render_manager"
require "./resource_manager"
require "./save_system"
require "../inventory/inventory_system"
require "../inventory/item_registry"
require "./game_state_manager"
require "./quest_system"
require "./timer_manager"
require "../actions/action_runner"
require "../actions/action_overlay_manager"

module PointClickEngine
  module Core
    # Main game engine class that coordinates all game systems.
    class Engine
      # Singleton instance
      @@instance : Engine?

      # Core properties
      property window_width : Int32
      property window_height : Int32
      property reference_width : Int32
      property reference_height : Int32
      property window_title : String
      property target_fps : Int32 = 60
      property running : Bool = false

      # Component managers - direct access for users
      property system_manager : EngineComponents::SystemManager = EngineComponents::SystemManager.new
      getter scene_manager : SceneManager { SceneManager.new(self, @system_manager.event_bus) }
      property input_manager : InputManager = InputManager.new
      property render_manager : RenderManager = RenderManager.new
      property resource_manager : ResourceManager = ResourceManager.new
      property inventory : Inventory::InventorySystem = Inventory::InventorySystem.new
      property item_registry : Inventory::ItemRegistry = Inventory::ItemRegistry.new
      property game_state_manager : GameStateManager?
      property quest_manager : QuestManager?
      property timer_manager : TimerManager = TimerManager.new
      property action_overlay_manager : Actions::ActionOverlayManager = Actions::ActionOverlayManager.new
      getter global_script_runner : Actions::ActionRunner?

      # Core components
      @input_handler : EngineComponents::InputHandler?
      @render_coordinator : EngineComponents::RenderCoordinator = EngineComponents::RenderCoordinator.new
      @verb_input_system : EngineComponents::VerbInputSystem?
      @update_callback : Proc(Float32, Nil)?
      property effect_manager : Graphics::EffectManager = Graphics::EffectManager.new

      # Auto-save functionality
      property auto_save_interval : Float32 = 0.0_f32
      property auto_save_timer : Float32 = 0.0_f32

      # Player control (disabled during action sequences)
      property player_control_enabled : Bool = true

      # Fullscreen state
      @fullscreen : Bool = false
      @paused : Bool = false
      @pause_toggled_this_frame : Bool = false

      # Initialization state
      @engine_initialized : Bool = false

      # Current scene reference
      property current_scene : Scenes::Scene?

      # Optional custom service overrides (for testing/DI)
      @custom_resource_manager : IResourceLoader?
      @custom_input_manager : IInputManager?
      @custom_render_manager : IRenderManager?

      # Whether to skip singleton registration (for testing)
      @skip_singleton : Bool = false

      # Get renderer from system manager
      def renderer : Graphics::Renderer
        @system_manager.renderer.not_nil!
      end

      # Get camera from renderer for compatibility
      def camera : Graphics::Camera
        renderer.camera
      end

      # Temporary player storage until a scene is available
      @pending_player : Characters::Character?

      # Singleton accessor
      def self.instance : Engine
        @@instance || raise "Engine not initialized. Call Engine.new first."
      end

      def self.instance? : Engine?
        @@instance
      end

      def self.instance=(engine : Engine?)
        @@instance = engine
      end

      # Reset instance for testing purposes
      def self.reset_instance
        @@instance = nil
      end

      # Class-level debug mode setter/getter
      @@debug_mode : Bool = false

      def self.debug_mode=(value : Bool)
        @@debug_mode = value
      end

      def self.debug_mode
        @@debug_mode
      end

      # Creates a new game engine instance
      def initialize(@window_width : Int32, @window_height : Int32, @window_title : String)
        @reference_width = @window_width
        @reference_height = @window_height
        raise "Engine already initialized" if @@instance
        @@instance = self
      end

      # Creates a new game engine instance with optional DI overrides
      # Use skip_singleton: true for testing to allow multiple engine instances
      def initialize(
        @window_width : Int32,
        @window_height : Int32,
        @window_title : String,
        resource_manager : IResourceLoader? = nil,
        input_manager : IInputManager? = nil,
        render_manager : IRenderManager? = nil,
        skip_singleton : Bool = false,
      )
        @reference_width = @window_width
        @reference_height = @window_height
        @skip_singleton = skip_singleton
        unless skip_singleton
          raise "Engine already initialized" if @@instance
          @@instance = self
        end

        @custom_resource_manager = resource_manager
        @custom_input_manager = input_manager
        @custom_render_manager = render_manager
      end

      # Initializes the engine and all subsystems
      def init
        # Initialize Raylib window only if not already open (for tests using RaylibContext)
        unless RL.window_ready?
          RL.set_config_flags(RL::ConfigFlags::FullscreenMode) if @fullscreen
          RL.init_window(@window_width, @window_height, @window_title)
        end
        RL.set_exit_key(RL::KeyboardKey::Null.value)
        RL.set_target_fps(@target_fps)

        # Initialize subsystems
        @system_manager.initialize_systems(@window_width, @window_height, @reference_width, @reference_height)
        if dm = display_manager
          dm.refresh_from_window
          sync_display_state(dm)
        end

        # Wire up timer manager with EventBus
        @timer_manager.event_bus = @system_manager.event_bus

        # Setup menu callbacks via SystemManager
        @system_manager.setup_menu_callbacks(self)

        # Initialize input handler
        @input_handler = EngineComponents::InputHandler.new

        # Mark as initialized
        @engine_initialized = true
      end

      def engine_ready? : Bool
        @engine_initialized
      end

      def input_handler
        @input_handler
      end

      # Main game loop
      def run
        @running = true

        while @running && !RL.close_window?
          dt = RL.get_frame_time

          # Reset input state at start of each frame
          InputState.reset

          # Update phase
          update(dt)

          # Render phase
          RL.begin_drawing
          RL.clear_background(RL::BLACK)

          render

          RL.end_drawing
        end

        cleanup
      end

      # Stops the game loop
      def stop
        @running = false
      end

      # Updates all game systems
      def update(dt : Float32)
        @pause_toggled_this_frame = false

        # Update input manager first
        @input_manager.process_input(dt)
        process_global_shortcuts

        if @paused
          return if @pause_toggled_this_frame
          @system_manager.update_menu_only(dt)
          return
        end

        if gameplay_input_active?
          # Handle input - use verb input if enabled, otherwise standard input
          if @verb_input_system && @verb_input_system.not_nil!.enabled
            @verb_input_system.not_nil!.process_input(@current_scene, player, display_manager, camera)
          else
            @input_handler.try do |handler|
              handler.handle_click(@current_scene, player, camera)
              handler.handle_keyboard_input
            end
          end
        end

        # Update systems
        @system_manager.update_systems(dt)

        # Update timer manager
        @timer_manager.update(dt)

        # Update scene-local sequences first, then any engine-level sequence
        # that should survive scene changes (startup cinematics, Lua-triggered sequences).
        @current_scene.try(&.update(dt))
        @global_script_runner.try(&.update(dt))
        clear_completed_script_runners
        @action_overlay_manager.update(dt)

        # Update inventory
        @inventory.update(dt)

        # Update camera and effects
        mouse_pos = RL.get_mouse_position
        camera.update(dt)

        # Update all effects (including scene transitions)
        @effect_manager.update(dt)
        @effect_manager.update_camera_effects(camera, dt)

        # Handle auto-save
        handle_auto_save(dt)

        # Call update callback if set
        @update_callback.try(&.call(dt))
      end

      # Renders the game
      private def render
        refresh_runtime_render_context

        # Check if we have an active shader-based transition
        if transition = @effect_manager.active_transition
          log_render_debug("transition", "type=#{transition.transition_type} camera=#{format_vec(camera.position)}")
          if transition.responds_to?(:render_with_shader)
            render_shader_scene do
              transition.render_with_shader do
                render_scene_layers(true)
              end
            end
          else
            render_scene_content
          end
          # Check if we have an active rain effect
        elsif rain_effect = @effect_manager.active_rain_effect
          log_render_debug("rain_shader", "scene=#{@current_scene.try(&.name) || "none"} camera=#{format_vec(camera.position)}")
          if rain_effect.responds_to?(:render_scene_with_rain)
            render_shader_scene do
              rain_effect.render_scene_with_rain do
                render_scene_layers(true)
              end
            end
          else
            render_scene_content
          end
          # Check if we have an active fog effect
        elsif fog_effect = @effect_manager.active_fog_effect
          log_render_debug("fog_shader", "scene=#{@current_scene.try(&.name) || "none"} camera=#{format_vec(camera.position)}")
          if fog_effect.responds_to?(:render_scene_with_fog)
            render_shader_scene do
              fog_effect.render_scene_with_fog do
                render_scene_layers(true)
              end
            end
          else
            render_scene_content
          end
          # Check if we have an active darkness effect
        elsif darkness_effect = @effect_manager.active_darkness_effect
          log_render_debug("darkness_shader", "scene=#{@current_scene.try(&.name) || "none"} camera=#{format_vec(camera.position)}")
          if darkness_effect.responds_to?(:render_scene_with_darkness)
            render_shader_scene do
              darkness_effect.render_scene_with_darkness do
                render_scene_layers(true)
              end
            end
          else
            render_scene_content
          end
          # Check if we have an active underwater effect
        elsif underwater_effect = @effect_manager.active_underwater_effect
          log_render_debug("underwater_shader", "scene=#{@current_scene.try(&.name) || "none"} camera=#{format_vec(camera.position)}")
          if underwater_effect.responds_to?(:render_scene_with_underwater)
            render_shader_scene do
              underwater_effect.render_scene_with_underwater do
                render_scene_layers(true)
              end
            end
          else
            render_scene_content
          end
        else
          render_scene_content
        end

        if modal_ui_active?
          draw_modal_cursor
        elsif gameplay_cursor_active?
          @verb_input_system.try(&.draw(self.display_manager))
        else
          RL.show_cursor
        end
      end

      # Renders the scene content (separated for use with transitions)
      private def render_scene_content(skip_overlays : Bool = false, apply_display_transform : Bool = true)
        if apply_display_transform
          with_logical_render_space(true) do
            render_scene_content(skip_overlays: skip_overlays, apply_display_transform: false)
          end
          return
        end

        render_scene_layers(skip_overlays)
        render_ui_layers
      end

      private def render_shader_scene(&block)
        with_logical_render_space(true) do
          yield
          @effect_manager.draw_scene_overlays(renderer, skip_transitions: true)
          render_ui_layers
        end
      end

      private def render_scene_layers(skip_overlays : Bool = false)
        render_world_scene(false)
        render_action_and_script_overlays(false)
        unless skip_overlays
          @effect_manager.draw_scene_overlays(renderer)
        end
      end

      private def render_ui_layers
        render_hotspots_ui_and_debug(false)
      end

      private def render_world_scene(apply_display_transform : Bool)
        # Create a temporary layer manager for scene effects
        # In a full implementation, this would be part of the renderer
        layers = Graphics::LayerManager.new
        layers.add_default_layers

        # Apply scene effects (including transitions) to the layers
        @effect_manager.apply_scene_effects(renderer, layers, RL.get_frame_time)

        # Render scene with camera using the renderer
        renderer.render(apply_display_transform) do |context|
          @current_scene.try do |scene|
            scene.draw(camera)
          end
        end
      end

      private def render_action_and_script_overlays(apply_display_transform : Bool)
        with_logical_render_space(apply_display_transform) do
          @action_overlay_manager.draw
          @current_scene.try(&.draw_script_overlays)
          @global_script_runner.try(&.draw)
        end
      end

      private def render_hotspots_ui_and_debug(apply_display_transform : Bool)
        with_logical_render_space(apply_display_transform) do
          if @render_coordinator.hotspot_highlight_enabled && @current_scene
            render_hotspot_highlights(@current_scene.not_nil!)
          end

          @system_manager.dialog_manager.try(&.draw)
          @inventory.draw
          @system_manager.menu_system.try(&.render)
          render_debug_info if @@debug_mode
        end
      end

      private def draw_modal_cursor
        if dm = display_manager
          raw_mouse = RL.get_mouse_position
          game_mouse = dm.screen_to_game(raw_mouse)

          with_logical_render_space(true) do
            if cursor_manager = @verb_input_system.try(&.cursor_manager)
              cursor_manager.draw(game_mouse)
            else
              draw_software_cursor(game_mouse)
            end
          end
        else
          RL.show_cursor
        end
      end

      private def draw_software_cursor(position : RL::Vector2)
        RL.hide_cursor
        color = RL::Color.new(r: 255, g: 240, b: 180, a: 255)
        shadow = RL::Color.new(r: 0, g: 0, b: 0, a: 180)

        points = [
          RL::Vector2.new(x: position.x, y: position.y),
          RL::Vector2.new(x: position.x + 8, y: position.y + 20),
          RL::Vector2.new(x: position.x + 4, y: position.y + 17),
          RL::Vector2.new(x: position.x + 2, y: position.y + 24),
          RL::Vector2.new(x: position.x - 1, y: position.y + 23),
          RL::Vector2.new(x: position.x + 1, y: position.y + 16),
          RL::Vector2.new(x: position.x - 4, y: position.y + 18),
        ]

        shadow_points = points.map do |point|
          RL::Vector2.new(x: point.x + 1, y: point.y + 1)
        end

        RL.draw_triangle_fan(shadow_points.to_unsafe, shadow_points.size, shadow)
        RL.draw_triangle_fan(points.to_unsafe, points.size, color)
        RL.draw_line_ex(points[0], points[1], 1.5f32, RL::BLACK)
        RL.draw_line_ex(points[1], points[2], 1.5f32, RL::BLACK)
        RL.draw_line_ex(points[2], points[3], 1.5f32, RL::BLACK)
        RL.draw_line_ex(points[3], points[4], 1.5f32, RL::BLACK)
        RL.draw_line_ex(points[4], points[5], 1.5f32, RL::BLACK)
        RL.draw_line_ex(points[5], points[6], 1.5f32, RL::BLACK)
        RL.draw_line_ex(points[6], points[0], 1.5f32, RL::BLACK)
      end

      private def with_logical_render_space(apply_display_transform : Bool, &)
        if apply_display_transform
          if dm = display_manager
            dm.with_game_coordinates do
              yield
            end
          else
            yield
          end
        else
          yield
        end
      end

      private def log_render_debug(tag : String, message : String)
        return unless @@debug_mode
        dm = display_manager
        display_info = if dm
                         " display=(window=#{dm.window_width}x#{dm.window_height} " \
                         "scale=#{dm.scale_factor.round(3)} offset=#{dm.offset_x.round(2)},#{dm.offset_y.round(2)})"
                       else
                         ""
                       end
        Core::ErrorLogger.debug("[EngineRender] #{tag} #{message}#{display_info}")
      end

      private def format_vec(vec : RL::Vector2) : String
        "(x=#{vec.x.round(2)},y=#{vec.y.round(2)})"
      end

      private def refresh_runtime_render_context
        context = current_frame_context
        @action_overlay_manager.target_width = context.logical_width
        @action_overlay_manager.target_height = context.logical_height
        dialog_manager.try { |manager| manager.frame_context = context }
      end

      # Render hotspot highlights
      private def render_hotspot_highlights(scene : Scenes::Scene)
        # Get camera offset from renderer's camera
        cam = camera
        camera_offset = RL::Vector2.new(x: -cam.position.x, y: -cam.position.y)

        # Calculate pulsing effect
        time = RL.get_time
        pulse = ((Math.sin(time * 3.0) + 1.0) / 2.0).to_f32
        pulse_alpha = (80 + pulse * 40).to_u8

        # Draw each hotspot with golden highlight
        scene.hotspot_manager.try(&.hotspots.each do |hotspot|
          next unless hotspot.visible

          bounds = hotspot.bounds
          highlight_rect = RL::Rectangle.new(
            x: bounds.x + camera_offset.x,
            y: bounds.y + camera_offset.y,
            width: bounds.width,
            height: bounds.height
          )

          # Draw filled rectangle with pulsing transparency
          RL.draw_rectangle_rec(highlight_rect, RL::Color.new(r: 255, g: 215, b: 0, a: pulse_alpha))

          # Draw outline
          RL.draw_rectangle_lines_ex(highlight_rect, 3, RL::Color.new(r: 255, g: 215, b: 0, a: 255))
        end)
      end

      # Renders debug information
      private def render_debug_info
        y_offset = 10
        RL.draw_text("DEBUG MODE", 10, y_offset, 20, RL::RED)
        y_offset += 25

        RL.draw_fps(10, y_offset)
        y_offset += 25

        if scene = @current_scene
          RL.draw_text("Scene: #{scene.name}", 10, y_offset, 20, RL::WHITE)
          y_offset += 25
        end

        mouse_pos = RL.get_mouse_position
        RL.draw_text("Mouse: #{mouse_pos.x.to_i}, #{mouse_pos.y.to_i}", 10, y_offset, 20, RL::WHITE)
        y_offset += 25
        RL.draw_text("Reference: #{@reference_width}x#{@reference_height}", 10, y_offset, 20, RL::WHITE)
      end

      # Cleans up all resources
      private def cleanup
        @system_manager.cleanup_systems

        RL.close_window
        @@instance = nil
      end

      # Save/Load functionality
      def save_game(slot_name : String = "autosave") : Bool
        SaveSystem.save_game(self, slot_name)
      end

      def load_game(slot_name : String = "autosave") : Bool
        SaveSystem.load_game(self, slot_name)
      end

      # Convenience accessors
      def player : Characters::Character?
        @current_scene.try(&.player) || @pending_player
      end

      def scenes : Hash(String, Scenes::Scene)
        scene_manager.scenes
      end

      # Enable verb input system
      def enable_verb_input
        @verb_input_system ||= EngineComponents::VerbInputSystem.new(self)
        @verb_input_system.not_nil!.enabled = true
      end

      def verb_input_system
        @verb_input_system
      end

      def shader_system
        @system_manager.shader_system
      end

      def display_manager
        @system_manager.display_manager
      end

      def gui
        @system_manager.gui
      end

      def show_fps=(value : Bool)
        @@debug_mode = value
      end

      def show_fps
        @@debug_mode
      end

      def event_bus
        @system_manager.event_bus
      end

      def player=(value : Characters::Character?)
        if scene = @current_scene
          scene.player = value
          @pending_player = nil
        else
          # Store player until a scene is available
          @pending_player = value
        end
      end

      def on_update=(callback : Proc(Float32, Nil)?)
        @update_callback = callback
      end

      def on_update
        @update_callback
      end

      def enable_auto_save(interval : Float32)
        @auto_save_interval = interval
        @auto_save_timer = 0.0_f32
        puts "Auto-save enabled with interval: #{interval} seconds" if interval > 0
      end

      def start_game
        # Start the game
        puts "Game started"
      end

      def return_to_menu
        # Return to main menu
        puts "[Engine] Returning to main menu"
        @system_manager.menu_system.try(&.show)
        @game_started = false
        # Clear current scene and action overlays
        stop_script
        @action_overlay_manager.clear_all
        @effect_manager.clear_scene_effects
        # Stop music
        @system_manager.audio_manager.try(&.stop_music)
      end

      def dialog_manager
        @system_manager.dialog_manager
      end

      def script_engine
        @system_manager.script_engine
      end

      def show_main_menu
        @paused = false
        @system_manager.menu_system.try(&.show_main_menu)
      end

      def menu_system
        @system_manager.menu_system
      end

      def reference_resolution : Tuple(Int32, Int32)
        {@reference_width, @reference_height}
      end

      def active_game_area_rect : RL::Rectangle?
        display_manager.try(&.active_game_area_rect)
      end

      def transformed_mouse_position : RL::Vector2
        if dm = display_manager
          dm.screen_to_game(RL.get_mouse_position)
        else
          RL.get_mouse_position
        end
      end

      def modal_ui_active? : Bool
        menu_system.try(&.visible) || false
      end

      def current_frame_context : Graphics::FrameContext
        scene_width = @current_scene.try(&.logical_width) || @reference_width
        scene_height = @current_scene.try(&.logical_height) || @reference_height
        canvas_width = @action_overlay_manager.canvas_width
        canvas_height = @action_overlay_manager.canvas_height

        renderer.build_frame_context(
          scene_width,
          scene_height,
          canvas_width,
          canvas_height
        )
      end

      def gameplay_input_active? : Bool
        !@paused && !modal_ui_active? && !blocking_dialog_active?
      end

      def gameplay_cursor_active? : Bool
        !@paused && !modal_ui_active? && @verb_input_system.try(&.enabled) == true
      end

      def paused? : Bool
        @paused
      end

      def toggle_hotspot_highlight
        # Toggle hotspot highlighting in render coordinator
        @render_coordinator.hotspot_highlight_enabled = !@render_coordinator.hotspot_highlight_enabled
        puts "[Engine] Hotspot highlighting: #{@render_coordinator.hotspot_highlight_enabled ? "ON" : "OFF"}"
      end

      def hotspot_highlight_enabled? : Bool
        @render_coordinator.hotspot_highlight_enabled
      end

      # Scene management
      def change_scene(scene_name : String, activation_options : SceneManager::ActivationOptions = SceneManager::ActivationOptions.new)
        puts "[Engine] Changing scene to: #{scene_name}"

        # Save current player before changing scene
        current_player = player

        result = scene_manager.change_scene(scene_name, activation_options)
        case result
        when .success?
          @current_scene = result.value
          puts "[Engine] Scene changed successfully"

          # Transfer scene effects to the effect manager
          if scene = @current_scene
            # Clear existing scene effects
            @effect_manager.clear_scene_effects

            # Add scene effects to the effect manager
            scene.scene_effects.each do |effect|
              @effect_manager.add_scene_effect(effect)
            end

            puts "[Engine] Transferred #{scene.scene_effects.size} scene effects to effect manager"
          end

          # Update camera bounds for the new scene
          if scene = @current_scene
            scene_width = scene.logical_width
            scene_height = scene.logical_height

            if renderer = @system_manager.renderer
              active_camera = renderer.camera
              active_camera.reset
              active_camera.set_bounds(scene_width, scene_height, @reference_width, @reference_height)

              if scene.enable_camera_scrolling
                if current_player = scene.player
                  active_camera.center_on(current_player.position.x, current_player.position.y, @reference_width, @reference_height)
                end
              end

              log_render_debug("scene_change",
                "scene=#{scene.name} logical=#{scene_width}x#{scene_height} " \
                "camera=#{format_vec(active_camera.position)} bounds=(#{active_camera.min_x.round(2)},#{active_camera.min_y.round(2)},#{active_camera.max_x.round(2)},#{active_camera.max_y.round(2)})")
            end

            puts "[Engine] Scene dimensions: #{scene_width}x#{scene_height}"
          end

          # Always assign player to new scene (either pending or current)
          if pending = @pending_player
            puts "[Engine] Assigning pending player to scene"
            @current_scene.try { |scene| scene.player = pending }
            @pending_player = nil
          elsif current_player
            puts "[Engine] Transferring current player to new scene"
            @current_scene.try { |scene| scene.player = current_player }
          else
            puts "[Engine] No player to assign"
          end

          puts "[Engine] Current scene player: #{@current_scene.try(&.player) ? "exists" : "nil"}"

          # Scene lifecycle, script loading, and event publishing are handled by SceneManager.
        when .failure?
          raise "Failed to change scene: #{result.error.message}"
        end
      end

      def add_scene(scene : Scenes::Scene)
        scene_manager.add_scene(scene)
      end

      # Convenience method for scene transitions
      def change_scene_with_transition(scene_name : String, transition_type : String = "fade",
                                       duration : Float32 = 1.0f32,
                                       player_position : RL::Vector2? = nil,
                                       activation_options : SceneManager::ActivationOptions = SceneManager::ActivationOptions.new)
        scene_manager.change_scene_with_transition(scene_name, transition_type, duration, player_position, activation_options)
      end

      # ============================================================
      # ACTION SEQUENCE METHODS
      # ============================================================

      # Run an action sequence from YAML file
      def run_script(path : String)
        @current_scene.try(&.run_script_file(path))
      end

      # Run an action sequence from an ActionRunner
      def run_script(runner : Actions::ActionRunner)
        if current_runner = @global_script_runner
          return if current_runner == runner && current_runner.running
          current_runner.stop if current_runner.running
        end

        runner.engine = self
        @global_script_runner = runner
        runner.play
      end

      # Check if an action sequence is running
      def script_running? : Bool
        (@global_script_runner.try(&.running) || false) || (@current_scene.try(&.script_running?) || false)
      end

      # Stop current action sequence
      def stop_script
        @global_script_runner.try(&.stop)
        @global_script_runner = nil
        @current_scene.try(&.stop_script)
      end

      # Skip current action sequence
      def skip_script
        if runner = @global_script_runner
          runner.skip if runner.running
        else
          @current_scene.try(&.skip_script)
        end
      end

      def active_script_runner : Actions::ActionRunner?
        @global_script_runner || @current_scene.try(&.script_runner)
      end

      # Window management
      def pause_game
        return if @paused

        @paused = true
        @pause_toggled_this_frame = true
        @system_manager.audio_manager.try(&.pause_music)
        @system_manager.menu_system.try(&.show_pause_menu)
        @system_manager.event_bus.publish_sync(Events::GamePausedEvent.new)
      end

      def resume_game
        return unless @paused

        @paused = false
        @pause_toggled_this_frame = true
        @system_manager.menu_system.try(&.hide)
        @system_manager.audio_manager.try(&.resume_music)
        @system_manager.event_bus.publish_sync(Events::GameResumedEvent.new)
      end

      def toggle_pause_menu
        menu = @system_manager.menu_system
        return unless menu
        return unless menu.not_nil!.in_game

        if @paused
          resume_game
        else
          pause_game
        end
      end

      def toggle_fullscreen
        if dm = display_manager
          dm.toggle_fullscreen
          sync_display_state(dm)
        else
          @fullscreen = !@fullscreen
        end
      end

      def fullscreen : Bool
        display_manager.try(&.fullscreen?) || @fullscreen
      end

      def fullscreen=(value : Bool)
        if dm = display_manager
          dm.set_fullscreen(value)
          sync_display_state(dm)
        else
          @fullscreen = value
        end
      end

      def set_window_size(width : Int32, height : Int32)
        @window_width = width
        @window_height = height
        RL.set_window_size(width, height)
        display_manager.try(&.resize(width, height))
        # Update camera bounds if needed
        camera.set_bounds(width, height)
      end

      # Start a new game
      def start_new_game
        puts "[Engine] Starting new game"
        @paused = false
        @system_manager.audio_manager.try(&.resume_music)
        # Hide the menu
        @system_manager.menu_system.try(&.hide)
        @system_manager.menu_system.try(&.enter_game)

        # Trigger the game started event
        # Scene loading is handled by GameStartedEvent subscribers (game_config.cr)
        # which may play an intro sequence first
        puts "[Engine] Triggering GameStartedEvent"
        @system_manager.event_bus.publish_sync(Events::GameStartedEvent.new(new_game: true))
        puts "[Engine] Event triggered"
      end

      # Auto-save handling
      private def handle_auto_save(dt : Float32)
        return if @auto_save_interval <= 0.0_f32

        @auto_save_timer += dt
        if @auto_save_timer >= @auto_save_interval
          # Create saves directory if it doesn't exist
          Dir.mkdir_p("saves") unless Dir.exists?("saves")

          # Save the game
          save_game("autosave")

          # Reset timer
          @auto_save_timer = 0.0_f32
        end
      end

      private def sync_display_state(display : Graphics::Display)
        @fullscreen = display.fullscreen?
      end

      private def process_global_shortcuts
        if @input_manager.key_pressed?(Raylib::KeyboardKey::Escape)
          toggle_pause_menu
          @input_manager.consume_keyboard_input
        end

        if @input_manager.key_pressed?(Raylib::KeyboardKey::F11)
          toggle_fullscreen
          @input_manager.consume_keyboard_input
        end
      end

      private def blocking_dialog_active? : Bool
        dialog_manager.try(&.is_dialog_active?) || false
      end

      private def clear_completed_script_runners
        if runner = @global_script_runner
          @global_script_runner = nil if runner.completed
        end
      end
    end
  end
end
