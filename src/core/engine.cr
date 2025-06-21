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
require "./engine/render_coordinator"

module PointClickEngine
  # Core engine functionality, game loop, and state management
  module Core
    # Main game engine class using singleton pattern for global access
    #
    # The Engine coordinates all game systems and provides the main game loop.
    # It manages scenes, handles input, coordinates rendering, and maintains
    # game state. Most game functionality is accessed through this class.
    #
    # ## Example
    #
    # ```
    # # Create and initialize the engine
    # engine = PointClickEngine::Core::Engine.new(800, 600, "My Game")
    # engine.init
    #
    # # Add scenes and start the game
    # engine.add_scene(my_scene)
    # engine.change_scene("main_room")
    # engine.run
    # ```
    class Engine
      include YAML::Serializable

      # Global debug mode flag - enables debug visualization and logging
      class_property debug_mode : Bool = false

      @@instance : Engine?

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

      # System managers (not serialized)

      # Manages all engine subsystems (audio, graphics, GUI, etc.)
      @[YAML::Field(ignore: true)]
      property system_manager : EngineComponents::SystemManager

      # Handles input processing and click coordination
      @[YAML::Field(ignore: true)]
      property input_handler : EngineComponents::InputHandler

      # Coordinates rendering and debug visualization
      @[YAML::Field(ignore: true)]
      property render_coordinator : EngineComponents::RenderCoordinator

      # Legacy properties for backwards compatibility

      # Path to custom cursor texture file
      property cursor_texture_path : String?

      # Loaded cursor texture (not serialized)
      @[YAML::Field(ignore: true)]
      property cursor_texture : RL::Texture2D?

      # Default mouse cursor type
      property default_cursor : RL::MouseCursor = RL::MouseCursor::Default

      # Whether the window is in fullscreen mode
      property fullscreen : Bool = false

      # Main player character (not serialized)
      @[YAML::Field(ignore: true)]
      property player : Characters::Character?

      # Cutscene management system (not serialized)
      @[YAML::Field(ignore: true)]
      property cutscene_manager : Cutscenes::CutsceneManager = Cutscenes::CutsceneManager.new

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
        @@instance = self
      end

      # Called automatically after deserializing from YAML
      #
      # Reconstructs non-serialized components like system managers.
      # This is used internally by the save/load system.
      def after_yaml_deserialize(ctx : YAML::ParseContext)
        @system_manager = EngineComponents::SystemManager.new
        @input_handler = EngineComponents::InputHandler.new
        @render_coordinator = EngineComponents::RenderCoordinator.new
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

        @system_manager.initialize_systems(@window_width, @window_height)

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
        @scenes[scene.name] = scene
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
        if scene = @scenes[name]?
          @current_scene = scene
          @current_scene_name = name
          scene.on_enter.try(&.call)
        else
          puts "Warning: Scene '#{name}' not found"
        end
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

        while @running && !RL.window_should_close?
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
        # Update systems
        @system_manager.update_systems(dt)

        # Update current scene
        @current_scene.try(&.update(dt))

        # Update cutscenes
        @cutscene_manager.update(dt)

        # Update dialogs
        @dialogs.each(&.update(dt))
        # @dialogs.reject!(&.completed?) # Dialog doesn't have completed? method

        # Process input
        @input_handler.process_input(@current_scene, @player)

        # Update cursor
        @render_coordinator.update_cursor(@current_scene)
      end

      # Update game state
      private def update
        dt = RL.get_frame_time

        # Update systems
        @system_manager.update_systems(dt)

        # Update current scene
        @current_scene.try(&.update(dt))

        # Update cutscenes
        @cutscene_manager.update(dt)

        # Update dialogs
        @dialogs.each(&.update(dt))
        # @dialogs.reject!(&.completed?) # Dialog doesn't have completed? method

        # Process input
        @input_handler.process_input(@current_scene, @player)

        # Update cursor
        @render_coordinator.update_cursor(@current_scene)
      end

      # Render game
      private def render
        RL.begin_drawing

        @render_coordinator.render(
          @current_scene,
          @dialogs,
          @cutscene_manager,
          @system_manager.transition_manager
        )

        RL.end_drawing
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
        @cursor_texture_path = path
        # Load cursor texture implementation
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
        engine.init
        puts "Game loaded from #{filepath}"
        engine
      rescue ex
        puts "Failed to load game: #{ex.message}"
        nil
      end

      # Delegated properties for backwards compatibility
      {% for prop in %w[display_manager achievement_manager audio_manager shader_system gui script_engine event_system dialog_manager config transition_manager] %}
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

      # Cleanup
      private def cleanup
        @system_manager.cleanup_systems
        RL.close_window
        puts "Engine cleanup complete"
      end
    end
  end
end
