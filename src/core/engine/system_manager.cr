# Engine system initialization and management

require "../achievement_manager"
require "../../audio/audio_manager"
require "../../graphics/shaders/shader_system"
require "../../ui/gui_manager"
require "../../scripting/script_engine"
require "../../scripting/event_system"
require "../../ui/dialog_manager"
require "../config_manager"
require "../../graphics/cameras/camera_manager"
require "../../graphics/display_manager"
require "../../graphics/transitions"
require "../../ui/menu_system"
require "./verb_input_system"

module PointClickEngine
  module Core
    module EngineComponents
      # Manages initialization and coordination of engine subsystems
      class SystemManager
        property achievement_manager : AchievementManager?
        property audio_manager : Audio::AudioManager?
        property shader_system : Graphics::Shaders::ShaderSystem?
        property gui : UI::GUIManager?
        property script_engine : Scripting::ScriptEngine?
        property event_system : Scripting::EventSystem
        property dialog_manager : UI::DialogManager?
        property config : ConfigManager?
        property camera_manager : Graphics::Cameras::CameraManager?
        property display_manager : Graphics::DisplayManager?
        property transition_manager : Graphics::TransitionManager?
        property menu_system : UI::MenuSystem?

        def initialize
          @event_system = Scripting::EventSystem.new
        end

        # Initialize all engine systems
        def initialize_systems(width : Int32, height : Int32)
          # Initialize display manager first
          @display_manager = Graphics::DisplayManager.new(width, height)

          # Initialize camera manager
          @camera_manager = Graphics::Cameras::CameraManager.new(width, height)

          # Initialize audio system
          if Audio::AudioManager.available?
            @audio_manager = Audio::AudioManager.new
          end

          # Initialize achievement system
          @achievement_manager = AchievementManager.new

          # Initialize shader system
          @shader_system = Graphics::Shaders::ShaderSystem.new

          # Initialize GUI manager
          @gui = UI::GUIManager.new

          # Initialize config manager
          @config = ConfigManager.new("config/game.yml")

          # Initialize dialog manager
          @dialog_manager = UI::DialogManager.new

          # Initialize transition manager
          @transition_manager = Graphics::TransitionManager.new(width, height)

          # Initialize menu system
          @menu_system = UI::MenuSystem.new

          # Initialize scripting engine
          begin
            @script_engine = Scripting::ScriptEngine.new
            puts "Script engine initialized successfully"
          rescue ex
            puts "Warning: Script engine initialization failed: #{ex.message}"
            @script_engine = nil
          end
        end

        # Setup menu callbacks with engine reference
        def setup_menu_callbacks(engine)
          return unless @menu_system

          # New Game callback
          @menu_system.not_nil!.on_new_game = -> {
            engine.start_new_game
          }

          # Load Game callback
          @menu_system.not_nil!.on_load_game = -> {
            @menu_system.not_nil!.switch_to_menu("load")
          }

          # Save Game callback
          @menu_system.not_nil!.on_save_game = -> {
            engine.save_game("quicksave")
          }

          # Options callback
          @menu_system.not_nil!.on_options = -> {
            @menu_system.not_nil!.switch_to_menu("options")
          }

          # Resume callback
          @menu_system.not_nil!.on_resume = -> {
            @menu_system.not_nil!.hide
          }

          # Quit callback
          @menu_system.not_nil!.on_quit = -> {
            engine.stop
          }
        end

        # Update all systems
        def update_systems(dt : Float32)
          @achievement_manager.try(&.update(dt))
          @audio_manager.try(&.update)
          # @shader_system.try(&.update(dt)) # No update method
          @gui.try(&.update(dt))
          @dialog_manager.try(&.update(dt))
          @transition_manager.try(&.update(dt))
          @menu_system.try(&.update(dt))
          @event_system.process_events
        end

        # Cleanup all systems
        def cleanup_systems
          # Cleanup systems that have cleanup methods
          @audio_manager.try(&.finalize) # Has finalize method
          @shader_system.try(&.cleanup)  # Has cleanup method
          # @gui.try(&.cleanup)               # No cleanup method - GUI::GUIManager
          @script_engine.try(&.cleanup)      # Has cleanup method
          @dialog_manager.try(&.cleanup)     # Has cleanup method
          @transition_manager.try(&.cleanup) # Has cleanup method
          @display_manager.try(&.cleanup)    # Has cleanup method

          # Systems without cleanup methods:
          # - @achievement_manager (no cleanup method)
          # - @gui (no cleanup method)
          # - @event_system (no cleanup method)
          # - @config (no cleanup method)
          # - @menu_system (no cleanup method)
        end

        # Get initialized systems count for debugging
        def initialized_systems_count : Int32
          count = 0
          count += 1 if @achievement_manager
          count += 1 if @audio_manager
          count += 1 if @shader_system
          count += 1 if @gui
          count += 1 if @script_engine
          count += 1 if @dialog_manager
          count += 1 if @config
          count += 1 if @display_manager
          count += 1 if @transition_manager
          count
        end

        # Check if core systems are ready
        def core_systems_ready? : Bool
          @display_manager && @gui && @dialog_manager && @config
        end
      end
    end
  end
end
