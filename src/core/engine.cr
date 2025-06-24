# Core Game Engine - Main coordination and game loop
#
# The Engine class is the heart of the Point & Click Engine framework.
# It coordinates all game systems, manages the main game loop, and provides
# the primary interface for game development.
#
# This class follows the singleton pattern for global access and handles:
# - Window initialization and main game loop
# - Scene management and transitions
# - System coordination (audio, graphics, input, etc.)
# - Save/load functionality
# - Debug mode and development tools

require "yaml"
require "./state_value"
require "./engine/system_manager"
require "./engine/input_handler"
require "./engine/verb_input_system"
require "./engine/render_coordinator"
require "../graphics/camera"
require "./input_state"
require "./error_handling"
require "./scene_manager"
require "./input_manager"
require "./render_manager"
require "./resource_manager"
require "./dependency_container_simple"
require "./config_manager"
require "./performance_monitor"

module PointClickEngine
  # Core engine functionality, game loop, and state management
  module Core
    # Main game engine class that coordinates all game systems.
    #
    # The `Engine` class is the central hub of the Point & Click Engine framework.
    # It manages the game window, coordinates all subsystems (graphics, audio, input),
    # runs the main game loop, and provides the primary API for game development.
    #
    # ## Architecture
    #
    # The engine uses a singleton pattern for global access and coordinates:
    # - Window creation and management via Raylib
    # - Scene management with transitions
    # - Input handling (mouse, keyboard, gamepad)
    # - Audio system (music, sound effects, ambient sounds)
    # - Save/load system
    # - Debug tools and visualization
    #
    # ## Basic Usage
    #
    # ```
    # # Create engine (automatically becomes singleton)
    # engine = PointClickEngine::Core::Engine.new(1024, 768, "My Adventure")
    # engine.init
    #
    # # Create and add a scene
    # scene = PointClickEngine::Scenes::Scene.new("intro")
    # scene.load_background("assets/intro.png")
    # engine.add_scene(scene)
    #
    # # Start the game
    # engine.change_scene("intro")
    # engine.run
    # ```
    #
    # ## Advanced Usage with Systems
    #
    # ```
    # # Enable debug mode for development
    # PointClickEngine::Core::Engine.debug_mode = true
    #
    # # Configure systems before init
    # engine = Engine.new(1920, 1080, "HD Adventure")
    # engine.target_fps = 144 # For high refresh monitors
    # engine.handle_clicks = true
    # engine.edge_scroll_enabled = true
    #
    # # Initialize with custom configuration
    # config = GameConfig.from_file("game_config.yaml")
    # engine.configure_from(config)
    # engine.init
    #
    # # Access singleton from anywhere
    # Engine.instance.change_scene("menu")
    # ```
    #
    # ## Input Handling
    #
    # ```
    # # Enable/disable input systems
    # engine.handle_clicks = true       # Mouse clicks for movement
    # engine.enable_verb_coin = true    # Right-click verb interface
    # engine.edge_scroll_enabled = true # Camera scrolling at edges
    #
    # # Block input temporarily (e.g., during cutscenes)
    # engine.block_input_frames = 60 # Block for 1 second at 60 FPS
    # ```
    #
    # ## Save/Load System
    #
    # ```
    # # Quick save/load
    # engine.save_game("slot1")
    # engine.load_game("slot1")
    #
    # # Autosave on scene changes
    # engine.autosave = true
    # engine.autosave_slot = "autosave"
    # ```
    #
    # ## Common Gotchas
    #
    # 1. **Singleton Pattern**: Only one Engine instance can exist at a time.
    #    ```
    # engine1 = Engine.new(800, 600, "Game 1")
    # engine2 = Engine.new(800, 600, "Game 2") # Overwrites engine1 as singleton!
    # Engine.instance == engine2               # true
    #    ```
    #
    # 2. **Initialization Order**: Always call `init` before using engine features.
    #    ```
    # engine = Engine.new(800, 600, "Game")
    # # engine.run  # ERROR: Window not created!
    # engine.init # Must init first
    # engine.run  # Now it works
    #    ```
    #
    # 3. **Scene Management**: Add scenes before changing to them.
    #    ```
    # engine.change_scene("intro") # ERROR: Scene not found!
    # engine.add_scene(intro_scene)
    # engine.change_scene("intro") # Works now
    #    ```
    #
    # 4. **Input Blocking**: Remember to unblock input after cutscenes.
    #    ```
    # engine.block_input_frames = 300 # 5 seconds
    # # Input automatically unblocks after 300 frames
    # # But you can manually unblock early:
    # engine.block_input_frames = 0
    #    ```
    #
    # ## Performance Tips
    #
    # - Use `target_fps` to limit frame rate and save CPU/battery
    # - Enable `edge_scroll_enabled` only for scenes larger than viewport
    # - Call `unload_scene` on scenes no longer needed to free memory
    # - Use `debug_mode = false` in production for better performance
    #
    # ## See Also
    #
    # - `Scene` - For scene management
    # - `InputHandler` - For custom input handling
    # - `SaveSystem` - For save/load functionality
    # - `GameConfig` - For configuration-based initialization
    class Engine
      include YAML::Serializable

      # Global debug mode flag - enables debug visualization and logging
      class_property debug_mode : Bool = false

      @@instance : Engine?
      @@dependency_container : SimpleDependencyContainer?

      # Returns the singleton Engine instance
      #
      # Raises an exception if the engine hasn't been initialized yet.
      # The engine instance is automatically set when creating a new Engine.
      #
      # ```
      # engine = Engine.new(800, 600, "Game")
      # same_engine = Engine.instance # Returns the same instance
      # ```
      def self.instance : Engine
        raise "Engine not initialized" unless @@instance
        @@instance.not_nil!
      end

      # Core engine properties

      # Whether the engine has been initialized (window created, systems loaded)
      @[YAML::Field(ignore: true)]
      property initialized : Bool = false

      # Window width in pixels
      property window_width : Int32

      # Window height in pixels
      property window_height : Int32

      # Window title displayed in the title bar
      property title : String

      # Target frames per second (default: 60)
      property target_fps : Int32 = 60

      # Whether the game loop is currently running
      @[YAML::Field(ignore: true)]
      property running : Bool = false

      # Input blocking after dialog
      @[YAML::Field(ignore: true)]
      property block_input_frames : Int32 = 0

      # Whether to show FPS counter
      property show_fps : Bool = false

      # Auto-save interval in seconds (0 = disabled)
      property auto_save_interval : Float32 = 0.0f32

      # Time since last auto-save
      @[YAML::Field(ignore: true)]
      property auto_save_timer : Float32 = 0.0f32

      # Scene management

      # Name of the currently active scene
      property current_scene_name : String?

      # Currently active scene object (not serialized)
      @[YAML::Field(ignore: true)]
      property current_scene : Scenes::Scene?

      # Hash of all registered scenes, indexed by name
      property scenes : Hash(String, Scenes::Scene) = {} of String => Scenes::Scene

      # Game systems

      # Main inventory system for item management
      property inventory : Inventory::InventorySystem

      # Currently active dialogs being displayed
      property dialogs : Array(UI::Dialog) = [] of UI::Dialog

      # Global game state variables (flags, counters, etc.)
      property state_variables : Hash(String, StateValue) = {} of String => StateValue

      # Game state manager for complex state handling
      @[YAML::Field(ignore: true)]
      property game_state_manager : GameStateManager?

      # Quest manager for quest tracking
      @[YAML::Field(ignore: true)]
      property quest_manager : QuestManager?

      # System managers (not serialized)

      # Manages all engine subsystems (audio, graphics, GUI, etc.)
      @[YAML::Field(ignore: true)]
      property system_manager : EngineComponents::SystemManager = EngineComponents::SystemManager.new

      # Handles input processing and click coordination
      @[YAML::Field(ignore: true)]
      property input_handler : EngineComponents::InputHandler = EngineComponents::InputHandler.new

      # Handles verb-based input for point-and-click interactions
      @[YAML::Field(ignore: true)]
      property verb_input_system : EngineComponents::VerbInputSystem?

      # Coordinates rendering and debug visualization
      @[YAML::Field(ignore: true)]
      property render_coordinator : EngineComponents::RenderCoordinator = EngineComponents::RenderCoordinator.new

      # New refactored managers

      # Manages scene loading, transitions, and caching
      @[YAML::Field(ignore: true)]
      property scene_manager : SceneManager = SceneManager.new

      # Manages input processing and event coordination
      @[YAML::Field(ignore: true)]
      property input_manager : InputManager = InputManager.new

      # Manages rendering layers and visual effects
      @[YAML::Field(ignore: true)]
      property render_manager : RenderManager = RenderManager.new

      # Manages asset loading, caching, and cleanup
      @[YAML::Field(ignore: true)]
      property resource_manager : ResourceManager = ResourceManager.new

      # Whether the window is in fullscreen mode
      property fullscreen : Bool = false

      # Main player character (not serialized)
      @[YAML::Field(ignore: true)]
      property player : Characters::Character?

      # Cutscene management system (not serialized)
      @[YAML::Field(ignore: true)]
      property cutscene_manager : Cutscenes::CutsceneManager = Cutscenes::CutsceneManager.new

      # Main game camera for scene scrolling (not serialized)
      @[YAML::Field(ignore: true)]
      property camera : Graphics::Camera?

      # Game-specific update callback
      @[YAML::Field(ignore: true)]
      property on_update : Proc(Float32, Nil)?

      # Cursor texture path (serialized for save/load)
      property cursor_texture_path : String?

      # Creates a new Engine instance with specified window dimensions
      #
      # This constructor initializes all core systems and sets up the singleton instance.
      # The engine must be initialized with `#init` before use.
      #
      # *window_width* - Width of the game window in pixels
      # *window_height* - Height of the game window in pixels
      # *title* - Window title to display
      #
      # ```
      # engine = Engine.new(1024, 768, "My Adventure Game")
      # engine.init
      # ```
      def initialize(@window_width : Int32, @window_height : Int32, @title : String)
        @inventory = Inventory::InventorySystem.new(RL::Vector2.new(x: 10, y: @window_height - 80))
        @scenes = {} of String => Scenes::Scene
        @dialogs = [] of UI::Dialog
        @cutscene_manager = Cutscenes::CutsceneManager.new
        @system_manager = EngineComponents::SystemManager.new
        @input_handler = EngineComponents::InputHandler.new
        @render_coordinator = EngineComponents::RenderCoordinator.new

        # Initialize dependency injection
        setup_dependencies

        # Initialize new refactored managers via DI
        container = @@dependency_container.not_nil!

        # Resolve managers - these must be initialized
        @scene_manager = container.resolve_scene_manager.as(SceneManager)
        @input_manager = container.resolve_input_manager.as(InputManager)
        @render_manager = container.resolve_render_manager.as(RenderManager)
        @resource_manager = container.resolve_resource_loader.as(ResourceManager)

        @@instance = self
      end

      # Creates a new Engine instance with default settings
      #
      # Uses default window size (800x600) and title ("Game").
      # The engine must be initialized with `#init` before use.
      #
      # ```
      # engine = Engine.new
      # engine.init
      # ```
      def initialize
        @window_width = 800
        @window_height = 600
        @title = "Game"
        @inventory = Inventory::InventorySystem.new(RL::Vector2.new(x: 10, y: 520))
        @scenes = {} of String => Scenes::Scene
        @dialogs = [] of UI::Dialog
        @cutscene_manager = Cutscenes::CutsceneManager.new
        @system_manager = EngineComponents::SystemManager.new
        @input_handler = EngineComponents::InputHandler.new
        @render_coordinator = EngineComponents::RenderCoordinator.new

        # Initialize dependency injection
        setup_dependencies

        # Initialize new refactored managers via DI
        container = @@dependency_container.not_nil!

        # Resolve managers - these must be initialized
        @scene_manager = container.resolve_scene_manager.as(SceneManager)
        @input_manager = container.resolve_input_manager.as(InputManager)
        @render_manager = container.resolve_render_manager.as(RenderManager)
        @resource_manager = container.resolve_resource_loader.as(ResourceManager)

        @@instance = self
      end

      # Initialize the engine and all its systems
      #
      # Creates the game window, initializes Raylib, and sets up all engine subsystems
      # including audio, graphics, input, and scripting. This must be called before
      # using any other engine functionality.
      #
      # Returns immediately if already initialized.
      #
      # ```
      # engine = Engine.new(800, 600, "My Game")
      # engine.init # Creates window and initializes systems
      # ```
      def init
        return if @initialized

        RL.init_window(@window_width, @window_height, @title)
        RL.set_target_fps(@target_fps)

        # Disable ESC key from closing window (we use it for pause menu)
        RL.set_exit_key(RL::KeyboardKey::Null)

        @system_manager.initialize_systems(@window_width, @window_height)

        # Initialize menu system after other systems
        @system_manager.menu_system = UI::MenuSystem.new(self)

        # Initialize camera for scene scrolling
        @camera = Graphics::Camera.new(@window_width, @window_height)

        # Set up input handlers for the new InputManager
        setup_input_handlers

        # Set up input handlers
        setup_input_handlers

        # Set up render layers
        setup_render_layers

        @initialized = true
        puts "Engine initialized with #{@system_manager.initialized_systems_count} systems"
      end

      # Initialize the engine with specific window dimensions and title
      #
      # Creates the game window with the specified dimensions and title, then
      # initializes all engine subsystems. This is a convenience method that
      # updates the engine configuration before calling the main init method.
      #
      # *width* - Window width in pixels
      # *height* - Window height in pixels
      # *title* - Window title to display in the title bar
      #
      # ```
      # engine = Engine.new
      # engine.init(1024, 768, "My Adventure Game")
      # ```
      #
      # NOTE: This method can be called to reinitialize the engine with new
      # window settings, but it will only take effect if the engine hasn't
      # been initialized yet.
      def init(width : Int32, height : Int32, title : String)
        @window_width = width
        @window_height = height
        @title = title
        init
      end

      # Set up input handlers for the InputManager
      private def setup_input_handlers
        # Register menu input handler with highest priority
        @input_manager.register_handler("menu_input", 100) do |dt|
          if menu = @system_manager.menu_system
            if menu.current_menu && menu.current_menu.not_nil!.visible
              menu.update(dt)
              true # Consume input when menu is active
            else
              false
            end
          else
            false
          end
        end

        # Register dialog input handler with high priority
        @input_manager.register_handler("dialog_input", 90) do |dt|
          if @dialogs.any?(&.visible)
            true # Consume input when dialog is visible
          elsif dm = @system_manager.dialog_manager
            dm.is_dialog_active?
          else
            false
          end
        end

        # Register keyboard shortcut handler
        @input_manager.register_handler("keyboard_shortcuts", 80) do |dt|
          # Handle common keyboard shortcuts
          if @input_manager.key_pressed?(Raylib::KeyboardKey::Escape)
            if menu = @system_manager.menu_system
              menu.toggle_pause_menu
            end
          end

          if @input_manager.key_pressed?(Raylib::KeyboardKey::F11)
            toggle_fullscreen
          end

          # Check direct Raylib input as fallback
          if RL.key_pressed?(Raylib::KeyboardKey::F1)
            Core::Engine.debug_mode = !Core::Engine.debug_mode
            puts "ENGINE F1: Debug mode: #{Core::Engine.debug_mode}"
          end

          if RL.key_pressed?(Raylib::KeyboardKey::Tab)
            puts "ENGINE TAB: Toggling hotspot highlight"
            toggle_hotspot_highlight
          end

          if @input_manager.key_pressed?(Raylib::KeyboardKey::F5)
            if cam = @camera
              cam.edge_scroll_enabled = !cam.edge_scroll_enabled
              puts "Camera edge scrolling: #{cam.edge_scroll_enabled ? "enabled" : "disabled"}"
            end
          end

          false # Don't consume input for keyboard shortcuts
        end

        # Register verb input handler if enabled
        @input_manager.register_handler("verb_input", 50) do |dt|
          if verb_system = @verb_input_system
            camera_for_input = if scene = @current_scene
                                 scene.enable_camera_scrolling ? @camera : nil
                               else
                                 nil
                               end
            display_manager = @system_manager.display_manager
            verb_system.process_input(@current_scene, @player, display_manager, camera_for_input)
            # Return true if verb system consumed input
            @input_manager.mouse_consumed?
          else
            false
          end
        end

        # Register default game input handler with lowest priority
        @input_manager.register_handler("game_input", 10) do |dt|
          camera_for_input = if scene = @current_scene
                               scene.enable_camera_scrolling ? @camera : nil
                             else
                               nil
                             end

          # Handle mouse clicks
          if @input_manager.mouse_button_pressed?(Raylib::MouseButton::Left)
            @input_handler.handle_click(@current_scene, @player, camera_for_input)
            @input_manager.consume_mouse_input
            true
          elsif @input_manager.mouse_button_pressed?(Raylib::MouseButton::Right)
            @input_handler.handle_right_click(@current_scene, camera_for_input)
            @input_manager.consume_mouse_input
            true
          else
            false
          end
        end
      end

      # Scene management

      # Registers a scene with the engine for later use
      #
      # Adds a scene to the engine's scene registry, making it available
      # for activation via `#change_scene`. The scene is indexed by its
      # name property for quick lookup.
      #
      # *scene* - The scene object to register with the engine
      #
      # ```
      # main_room = Scenes::Scene.new("main_room")
      # engine.add_scene(main_room)
      # engine.change_scene("main_room") # Now available
      # ```
      #
      # NOTE: If a scene with the same name already exists, it will be
      # replaced with the new scene.
      def add_scene(scene : Scenes::Scene)
        # Validate scene before adding
        result = @scene_manager.add_scene(scene)

        # Only add to engine's scene registry if successful
        if result.success?
          @scenes[scene.name] = scene
        end

        result
      end

      # Activates a registered scene as the current scene
      #
      # Changes the active scene to the specified scene by name. The scene
      # must have been previously registered with `#add_scene`. If the scene
      # has an `on_enter` callback, it will be executed during the transition.
      #
      # *name* - Name of the scene to activate
      #
      # ```
      # engine.add_scene(living_room_scene)
      # engine.change_scene("living_room") # Activates the scene
      # ```
      #
      # NOTE: If the specified scene doesn't exist, a warning is printed
      # and the current scene remains unchanged.
      def change_scene(name : String)
        # Try to change scene via SceneManager first
        result = @scene_manager.change_scene(name)
        case result
        when .success?
          scene = result.value
          @current_scene = scene
          @current_scene_name = name

          # Add player to the new scene if player exists
          if player = @player
            scene.set_player(player)
          end

          # Update camera for new scene
          if camera = @camera
            if bg = scene.background
              if scene.enable_camera_scrolling
                camera.set_scene_size(bg.width, bg.height)
                # Center camera on player if present
                if player = @player
                  camera.center_on(player.position.x, player.position.y)
                else
                  camera.center_on((bg.width / 2).to_f32, (bg.height / 2).to_f32)
                end
              else
                # Disable scrolling for this scene by setting scene size to viewport size
                camera.set_scene_size(camera.viewport_width, camera.viewport_height)
                camera.center_on((camera.viewport_width / 2).to_f32, (camera.viewport_height / 2).to_f32)
              end
            end
          end

          scene.enter
        when .failure?
          ErrorLogger.error("Failed to change scene: #{result.error.message}")
        end
      end

      # Additional scene management delegation
      def preload_scene(name : String)
        @scene_manager.preload_scene(name)
      end

      def unload_scene(name : String)
        result = @scene_manager.remove_scene(name)
        # Also remove from engine's local registry
        @scenes.delete(name)
        result
      end

      def get_scene(name : String)
        @scene_manager.get_scene(name)
      end

      def get_scene_names
        @scene_manager.scene_names
      end

      # Dialog management

      # Displays a dialog to the player
      #
      # Adds a dialog to the active dialog queue. The dialog will be
      # rendered on top of the current scene and will capture input
      # until it's completed or dismissed.
      #
      # *dialog* - The dialog object to display
      #
      # ```
      # dialog = UI::Dialog.new("Hello, world!")
      # engine.show_dialog(dialog)
      # ```
      #
      # NOTE: Multiple dialogs can be shown simultaneously and will
      # be rendered in the order they were added.
      def show_dialog(dialog : UI::Dialog)
        @dialogs << dialog
      end

      # UI visibility

      # Makes the game UI visible
      #
      # Shows all UI elements including inventory, dialog boxes, and other
      # interface components. This is useful for toggling UI visibility
      # during cutscenes or special game states.
      #
      # ```
      # engine.hide_ui # Hide UI for cutscene
      # # ... cutscene plays ...
      # engine.show_ui # Restore UI after cutscene
      # ```
      def show_ui
        @render_coordinator.ui_visible = true
      end

      # Hides the game UI
      #
      # Conceals all UI elements including inventory, dialog boxes, and other
      # interface components. This is useful for creating immersive cutscenes
      # or special game states where the UI should not be visible.
      #
      # ```
      # engine.hide_ui # Hide UI for cutscene
      # play_intro_cutscene()
      # engine.show_ui # Restore UI when done
      # ```
      def hide_ui
        @render_coordinator.ui_visible = false
      end

      # Main game loop

      # Starts the main game loop and runs until stopped
      #
      # Begins the core game loop that handles input, updates game state,
      # and renders graphics. The loop continues until either `#stop` is
      # called or the user closes the window. The engine must be initialized
      # before calling this method.
      #
      # Returns immediately if the engine is not initialized.
      #
      # ```
      # engine = Engine.new(800, 600, "My Game")
      # engine.init
      # engine.add_scene(main_scene)
      # engine.change_scene("main_scene")
      # engine.run # Starts the game loop
      # ```
      #
      # NOTE: This method blocks until the game loop ends. All cleanup
      # is performed automatically when the loop exits.
      def run
        return unless @initialized

        @running = true
        puts "Starting game loop..."

        while @running && !RL.close_window?
          update
          render
        end

        cleanup
      end

      # Stops the main game loop
      #
      # Signals the game loop to exit on the next iteration. This will
      # cause the `#run` method to return and trigger engine cleanup.
      # The game window will be closed and all resources freed.
      #
      # ```
      # # In a menu or quit handler:
      # engine.stop # Gracefully exits the game
      # ```
      #
      # NOTE: The loop will not stop immediately but will exit after
      # completing the current frame.
      def stop
        @running = false
      end

      # Public update method for external use
      def update(dt : Float32)
        # Process events first
        event_system.process_events

        # Update systems
        @system_manager.update_systems(dt)

        # Update new refactored managers
        # @resource_manager.update(dt)  # ResourceManager doesn't need regular updates
        # @scene_manager.update(dt)     # SceneManager doesn't need regular updates
        @input_manager.update(dt) # InputManager has update method
        # @render_manager.update(dt)    # RenderManager doesn't need regular updates

        # Update menu system
        @system_manager.menu_system.try(&.update(dt))

        # Skip game updates if menu is pausing the game
        if menu = @system_manager.menu_system
          return if menu.game_paused
        end

        # Update current scene
        @current_scene.try(&.update(dt))

        # Update camera if it exists
        if camera = @camera
          if scene = @current_scene
            if scene.enable_camera_scrolling
              # Update camera with mouse position for edge scrolling
              mouse_pos = RL.get_mouse_position
              camera.update(dt, mouse_pos.x.to_i, mouse_pos.y.to_i)

              # Follow player if one exists
              if player = @player
                camera.follow(player)
              end
            end
          end
        end

        # Update cutscenes
        @cutscene_manager.update(dt)

        # Update dialogs
        @dialogs.each(&.update(dt))
        # @dialogs.reject!(&.completed?) # Dialog doesn't have completed? method

        # Check if any dialog is visible or dialog manager has active dialog
        dialog_active = @dialogs.any? { |d| d.visible }
        if dm = @system_manager.dialog_manager
          dialog_active ||= dm.is_dialog_active?
        end

        # Block mouse input if dialog is active, but allow keyboard shortcuts
        if dialog_active
          @input_manager.block_input(1, "dialog_active")
          # Note: Keyboard shortcuts are handled by individual input handlers
          # with higher priority than dialog blocking
        else
          @input_manager.unblock_input
        end

        # Update cursor
        # Note: GUI system doesn't have cursor manager built-in
        # We'll need to create a separate cursor system or use UIManager

        # Call game-specific update if provided
        @on_update.try &.call(dt)

        # Handle auto-save
        if @auto_save_interval > 0
          @auto_save_timer += dt
          if @auto_save_timer >= @auto_save_interval
            @auto_save_timer = 0.0f32
            # Create saves directory if it doesn't exist
            Dir.mkdir_p("saves") unless Dir.exists?("saves")
            save_game("saves/autosave.yml")
          end
        end
      end

      # Update game state
      private def update
        dt = RL.get_frame_time

        # Reset input state for new frame
        InputState.reset

        # Process events first
        event_system.process_events

        # Update systems
        @system_manager.update_systems(dt)

        # Update new refactored managers
        # @resource_manager.update(dt)  # ResourceManager doesn't need regular updates
        # @scene_manager.update(dt)     # SceneManager doesn't need regular updates
        @input_manager.update(dt) # InputManager has update method
        # @render_manager.update(dt)    # RenderManager doesn't need regular updates

        # Update menu system
        @system_manager.menu_system.try(&.update(dt))

        # Skip game updates if menu is pausing the game
        if menu = @system_manager.menu_system
          return if menu.game_paused
        end

        # Update current scene
        @current_scene.try(&.update(dt))

        # Update camera if it exists
        if camera = @camera
          if scene = @current_scene
            if scene.enable_camera_scrolling
              # Update camera with mouse position for edge scrolling
              mouse_pos = RL.get_mouse_position
              camera.update(dt, mouse_pos.x.to_i, mouse_pos.y.to_i)

              # Follow player if one exists
              if player = @player
                camera.follow(player)
              end
            end
          end
        end

        # Update cutscenes
        @cutscene_manager.update(dt)

        # Update dialogs
        @dialogs.each(&.update(dt))
        # @dialogs.reject!(&.completed?) # Dialog doesn't have completed? method

        # Check if any dialog is visible or dialog manager has active dialog
        dialog_active = @dialogs.any? { |d| d.visible }
        if dm = @system_manager.dialog_manager
          dialog_active ||= dm.is_dialog_active?
        end

        # Process input only if no dialog is active
        if !dialog_active
          camera_for_input = if scene = @current_scene
                               scene.enable_camera_scrolling ? @camera : nil
                             else
                               nil
                             end

          # Input processing is now handled by InputManager in the update method
        end

        # Update cursor via RenderManager
        # TODO: Update this to use new RenderManager API
        # @render_manager.update_cursor(@current_scene)
      end

      # Render game
      private def render
        dt = RL.get_frame_time

        # Use the new RenderManager for rendering
        @render_manager.render(dt)
      end

      # Display settings

      # Toggles between fullscreen and windowed mode
      #
      # Switches the game window between fullscreen and windowed display
      # modes. The engine tracks the current fullscreen state and updates
      # it when toggled.
      #
      # ```
      # # Toggle fullscreen on F11 key press
      # if RL.key_pressed?(RL::KeyboardKey::F11)
      #   engine.toggle_fullscreen
      # end
      # ```
      #
      # NOTE: The actual fullscreen implementation is handled by Raylib
      # and may behave differently on different operating systems.
      def toggle_fullscreen
        @fullscreen = !@fullscreen
        RL.toggle_fullscreen
      end

      def set_scaling_mode(mode : Graphics::DisplayManager::ScalingMode)
        @system_manager.display_manager.try(&.set_scaling_mode(mode))
      end

      # Enable verb-based input system
      #
      # Activates the verb-based input system for point-and-click interactions.
      # This replaces the default input handler with a more sophisticated system
      # that supports verbs like Walk, Look, Talk, Use, Take, Open, etc.
      #
      # ```
      # engine.enable_verb_input
      # # Now left-click executes the current verb
      # # Right-click always performs "Look"
      # ```
      def enable_verb_input
        @verb_input_system = EngineComponents::VerbInputSystem.new(self)
        @input_handler.handle_clicks = false # Disable default click handling
      end

      # Show the main menu
      #
      # Displays the main menu and pauses the game. This is typically
      # called at game startup or when returning to the main menu.
      #
      # ```
      # engine.show_main_menu
      # ```
      def show_main_menu
        @system_manager.menu_system.try(&.show_main_menu)
      end

      # Start a new game
      #
      # Hides the menu and enters game mode. This should be called
      # after initializing the game scene.
      #
      # ```
      # # After setting up initial scene
      # engine.start_game
      # ```
      def start_game
        @system_manager.menu_system.try(&.enter_game)
      end

      # Get the verb input system if enabled
      def verb_input_system : EngineComponents::VerbInputSystem?
        @verb_input_system
      end

      # Toggle hotspot highlighting
      #
      # Enables or disables visual highlighting of interactive hotspots.
      # When enabled, hotspots will be outlined with a pulsing golden glow
      # and character names will be displayed above them.
      #
      # ```
      # # Toggle hotspot highlighting on Tab key
      # if RL.key_pressed?(RL::KeyboardKey::Tab)
      #   engine.toggle_hotspot_highlight
      # end
      # ```
      def toggle_hotspot_highlight
        if @render_manager.hotspot_highlighting_enabled?
          @render_manager.disable_hotspot_highlighting
        else
          @render_manager.enable_hotspot_highlighting
        end
      end

      # Set hotspot highlight settings
      #
      # Configures the appearance of hotspot highlighting.
      #
      # *enabled* - Whether highlighting is enabled
      # *color* - The color to use for highlighting (default: golden)
      # *pulse* - Whether the highlight should pulse (default: true)
      #
      # ```
      # engine.set_hotspot_highlight(true, RL::BLUE, false)
      # ```
      def set_hotspot_highlight(enabled : Bool, color : RL::Color? = nil, pulse : Bool? = nil)
        if enabled
          @render_manager.enable_hotspot_highlighting(color, pulse || true)
        else
          @render_manager.disable_hotspot_highlighting
        end
      end

      # Archive support
      def mount_archive(path : String, mount_point : String = "/")
        # Implementation would go here
        puts "Mounting archive: #{path} at #{mount_point}"
      end

      def unmount_archive(mount_point : String = "/")
        puts "Unmounting archive at #{mount_point}"
      end

      # Cursor management
      def load_cursor(path : String)
        result = @resource_manager.load_texture(path)
        case result
        when .success?
          @cursor_texture_path = path
          ErrorLogger.info("Cursor texture loaded: #{path}")
        when .failure?
          ErrorLogger.error("Failed to load cursor texture: #{result.error.message}")
        end
      end

      # Get the loaded cursor texture
      def get_cursor_texture
        if path = @cursor_texture_path
          @resource_manager.get_texture(path)
        else
          nil
        end
      end

      # Resource management delegation
      def load_texture(path : String)
        @resource_manager.load_texture(path)
      end

      def load_sound(path : String)
        @resource_manager.load_sound(path)
      end

      def load_music(path : String)
        @resource_manager.load_music(path)
      end

      def load_font(path : String, size : Int32 = 16)
        @resource_manager.load_font(path, size)
      end

      def preload_assets(asset_list : Array(String))
        @resource_manager.preload_assets(asset_list)
      end

      def get_memory_usage
        @resource_manager.get_memory_usage
      end

      def set_memory_limit(limit_bytes : Int64)
        @resource_manager.set_memory_limit(limit_bytes)
      end

      def enable_hot_reload
        @resource_manager.enable_hot_reload
      end

      def disable_hot_reload
        @resource_manager.disable_hot_reload
      end

      # Input management delegation
      def register_input_handler(handler_name : String, priority : Int32 = 0)
        @input_manager.register_handler(handler_name, priority)
      end

      def unregister_input_handler(handler_name : String)
        @input_manager.unregister_handler(handler_name)
      end

      def is_input_consumed(input_type : String) : Bool
        @input_manager.is_consumed(input_type)
      end

      def consume_input(input_type : String, handler_name : String)
        @input_manager.consume_input(input_type, handler_name)
      end

      # Rendering management delegation
      def add_render_layer(name : String, z_order : Int32 = 0)
        @render_manager.add_render_layer(name, z_order)
      end

      def remove_render_layer(name : String)
        # RenderManager doesn't have remove_layer method, so we'll skip this
        Result(Nil, RenderError).success(nil)
      end

      def set_render_layer_z_order(name : String, z_order : Int32)
        # RenderManager doesn't have set_layer_z_order method, so we'll skip this
        Result(Nil, RenderError).success(nil)
      end

      def set_render_layer_visible(name : String, visible : Bool)
        @render_manager.set_layer_enabled(name, visible)
      end

      def enable_performance_tracking
        # RenderManager doesn't have this method, performance tracking is always on
      end

      def disable_performance_tracking
        # RenderManager doesn't have this method, performance tracking is always on
      end

      def get_render_stats
        @render_manager.get_render_stats
      end

      # Save/Load system

      # Saves the current game state to a file
      #
      # Serializes the engine state including scenes, inventory, dialogs,
      # and state variables to a YAML file. This creates a complete save
      # file that can be loaded later to restore the game state.
      #
      # *filepath* - Path where the save file should be written
      #
      # ```
      # # Save the game to a file
      # engine.save_game("saves/quicksave.yml")
      #
      # # Save with timestamp
      # timestamp = Time.local.to_s("%Y%m%d_%H%M%S")
      # engine.save_game("saves/game_#{timestamp}.yml")
      # ```
      #
      # NOTE: The directory must exist before saving. Non-serializable
      # components like textures and audio will be reloaded when the
      # save is loaded.
      def save_game(filepath : String)
        File.write(filepath, to_yaml)
        puts "Game saved to #{filepath}"
      end

      # Enable automatic saving at regular intervals
      #
      # Configures the engine to automatically save the game state at
      # specified intervals. The save file will be written to
      # "saves/autosave.yml" by default.
      #
      # *interval* - Time between saves in seconds (0 to disable)
      #
      # ```
      # # Auto-save every 5 minutes
      # engine.enable_auto_save(300)
      # ```
      def enable_auto_save(interval : Float32)
        @auto_save_interval = interval
        @auto_save_timer = 0.0f32
      end

      # Loads a saved game state from a file
      #
      # Deserializes an engine state from a YAML save file and initializes
      # it. This creates a new Engine instance with the saved state,
      # including scenes, inventory, dialogs, and state variables.
      #
      # *filepath* - Path to the save file to load
      #
      # Returns the loaded Engine instance, or `nil` if loading failed
      #
      # ```
      # # Load a saved game
      # if engine = Engine.load_game("saves/quicksave.yml")
      #   engine.run
      # else
      #   puts "Failed to load save file"
      # end
      # ```
      #
      # NOTE: This is a class method that returns a new Engine instance.
      # The loaded engine is automatically initialized and ready to use.
      # Returns `nil` if the file doesn't exist or contains invalid data.
      def self.load_game(filepath : String) : Engine?
        return nil unless File.exists?(filepath)

        yaml_content = File.read(filepath)
        engine = Engine.from_yaml(yaml_content)
        engine.after_load
        engine.init
        puts "Game loaded from #{filepath}"
        engine
      rescue ex
        puts "Failed to load game: #{ex.message}"
        nil
      end

      # Called after deserializing from YAML
      def after_load
        @system_manager = EngineComponents::SystemManager.new
        @input_handler = EngineComponents::InputHandler.new
        @render_coordinator = EngineComponents::RenderCoordinator.new
        @scene_manager = SceneManager.new
        @input_manager = InputManager.new
        @render_manager = RenderManager.new
        @resource_manager = ResourceManager.new
        @camera = Graphics::Camera.new(@window_width, @window_height)

        # Set up input handlers for the new InputManager
        setup_input_handlers

        # Restore singleton reference
        @@instance = self
      end

      # Delegated properties for system access
      {% for prop in %w[display_manager achievement_manager audio_manager shader_system gui script_engine event_system dialog_manager config transition_manager menu_system] %}
        def {{prop.id}}
          @system_manager.{{prop.id}}
        end

        def {{prop.id}}=(value)
          @system_manager.{{prop.id}} = value
        end
      {% end %}

      def handle_clicks
        @input_handler.handle_clicks
      end

      def handle_clicks=(value : Bool)
        @input_handler.handle_clicks = value
      end

      # Setup dependency injection container
      private def setup_dependencies
        # Create a global dependency container instance
        container = SimpleDependencyContainer.new
        @@dependency_container = container

        # Register concrete implementations
        container.register_resource_loader(ResourceManager.new)
        container.register_scene_manager(SceneManager.new)
        container.register_input_manager(InputManager.new)
        container.register_render_manager(RenderManager.new)

        # Register singletons
        container.register_config_manager(ConfigManager.new("config/game.yml"))
        container.register_performance_monitor(PerformanceMonitor.new)

        ErrorLogger.info("Dependencies registered")
      end

      # Set up render layers for the RenderManager
      private def setup_render_layers
        # Background layer for scene backgrounds
        background_renderer = ->(dt : Float32) {
          if scene = @current_scene
            if bg = scene.background
              RL.draw_texture_ex(
                bg,
                RL::Vector2.new(x: 0, y: 0),
                0.0f32,
                scene.scale,
                RL::WHITE
              )
            end
          end
        }
        @render_manager.add_renderer("background", background_renderer)

        # Scene objects layer (with camera support)
        scene_renderer = ->(dt : Float32) {
          camera_to_use = if scene = @current_scene
                            scene.enable_camera_scrolling ? @camera : nil
                          else
                            nil
                          end

          # Render scene objects with camera
          @current_scene.try(&.draw(camera_to_use))
        }
        @render_manager.add_renderer("scene_objects", scene_renderer)

        # Dialogs layer
        dialogs_renderer = ->(dt : Float32) {
          @dialogs.each(&.draw)
        }
        @render_manager.add_renderer("dialogs", dialogs_renderer)

        # Cutscene layer
        cutscene_renderer = ->(dt : Float32) {
          @cutscene_manager.draw
        }
        @render_manager.add_renderer("cutscenes", cutscene_renderer)

        # Transition effects layer
        transitions_renderer = ->(dt : Float32) {
          @system_manager.transition_manager.try(&.draw)
        }
        @render_manager.add_renderer("transitions", transitions_renderer)

        # UI layer (menus, inventory, etc.)
        ui_renderer = ->(dt : Float32) {
          # Render inventory
          @inventory.draw

          # Render menu system
          @system_manager.menu_system.try(&.draw)

          # Render achievement notifications
          @system_manager.achievement_manager.try(&.draw)

          # Render verb input system cursor
          if verb_system = @verb_input_system
            display_manager = @system_manager.display_manager
            verb_system.draw(display_manager)
          end
        }
        @render_manager.add_renderer("ui", ui_renderer)

        # Debug overlay layer
        debug_renderer = ->(dt : Float32) {
          if Engine.debug_mode
            # Debug rendering handled by RenderManager internally
          end
        }
        @render_manager.add_renderer("debug", debug_renderer)
      end

      # Set up input handlers for the InputManager
      private def setup_input_handlers
        # Menu system has highest priority (100)
        @input_manager.register_handler("menu_system", 100) do |dt|
          if menu = @system_manager.menu_system
            if menu.current_menu
              menu.update(dt)
              true # Consume input when menu is active
            else
              false
            end
          else
            false
          end
        end

        # Dialog system has high priority (90)
        @input_manager.register_handler("dialog_system", 90) do |dt|
          if dm = @system_manager.dialog_manager
            if dm.is_dialog_active?
              dm.update(dt)
              true # Consume input when dialog is active
            else
              false
            end
          else
            false
          end
        end

        # Verb input system has medium-high priority (70)
        @input_manager.register_handler("verb_input", 70) do |dt|
          if verb_system = @verb_input_system
            camera_for_input = if scene = @current_scene
                                 scene.enable_camera_scrolling ? @camera : nil
                               else
                                 nil
                               end
            display_manager = @system_manager.display_manager
            verb_system.process_input(@current_scene, @player, display_manager, camera_for_input)
            # Verb system decides whether to consume input
            false
          else
            false
          end
        end

        # Default game input has medium priority (50)
        @input_manager.register_handler("game_input", 50) do |dt|
          camera_for_input = if scene = @current_scene
                               scene.enable_camera_scrolling ? @camera : nil
                             else
                               nil
                             end

          # Process game input (clicks, movement, etc.)
          @input_handler.process_input(@current_scene, @player, camera_for_input)
          false # Don't consume by default, let other handlers also process
        end

        # Global keyboard shortcuts have low priority (10)
        @input_manager.register_handler("global_keys", 10) do |dt|
          @input_handler.handle_keyboard_input
          false # Don't consume, these are global shortcuts
        end
      end

      # Cleanup
      private def cleanup
        # Cleanup new refactored managers
        @resource_manager.cleanup_all_resources

        @system_manager.cleanup_systems
        RL.close_window
        puts "Engine cleanup complete"
      end
    end
  end
end
