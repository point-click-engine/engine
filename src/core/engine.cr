# Core Game Engine - Minimal coordination and game loop
#
# The Engine class coordinates all game systems and manages the main game loop.
# It provides direct access to all subsystems through component managers.

require "yaml"
require "./engine/system_manager"
require "./engine/input_handler"
require "./engine/render_coordinator"
require "./engine/verb_input_system"
require "../graphics/camera"
require "./scene_manager"
require "./input_manager"
require "./render_manager"
require "./resource_manager"
require "./save_system"
require "../inventory/inventory_system"
require "./game_state_manager"
require "./quest_system"

module PointClickEngine
  module Core
    # Main game engine class that coordinates all game systems.
    class Engine
      # Singleton instance
      @@instance : Engine?

      # Core properties
      property window_width : Int32
      property window_height : Int32
      property window_title : String
      property target_fps : Int32 = 60
      property running : Bool = false

      # Component managers - direct access for users
      property system_manager : EngineComponents::SystemManager = EngineComponents::SystemManager.new
      property scene_manager : SceneManager = SceneManager.new
      property input_manager : InputManager = InputManager.new
      property render_manager : RenderManager = RenderManager.new
      property resource_manager : ResourceManager = ResourceManager.new
      property inventory : Inventory::InventorySystem = Inventory::InventorySystem.new
      property game_state_manager : GameStateManager?
      property quest_manager : QuestManager?

      # Core components
      @input_handler : EngineComponents::InputHandler?
      @render_coordinator : EngineComponents::RenderCoordinator = EngineComponents::RenderCoordinator.new
      @verb_input_system : EngineComponents::VerbInputSystem?
      @update_callback : Proc(Float32, Nil)?

      # Auto-save functionality
      property auto_save_interval : Float32 = 0.0_f32
      property auto_save_timer : Float32 = 0.0_f32

      # Fullscreen state
      @fullscreen : Bool = false

      # Initialization state
      @engine_initialized : Bool = false

      # Current scene reference
      property current_scene : Scenes::Scene?

      # Global camera
      property camera : Graphics::Camera?

      # Temporary player storage until a scene is available
      @pending_player : Characters::Character?

      # Singleton accessor
      def self.instance : Engine
        @@instance || raise "Engine not initialized. Call Engine.new first."
      end

      def self.instance? : Engine?
        @@instance
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
        raise "Engine already initialized" if @@instance
        @@instance = self
      end

      # Initializes the engine and all subsystems
      def init
        # Initialize Raylib window
        RL.init_window(@window_width, @window_height, @window_title)
        RL.set_target_fps(@target_fps)

        # Initialize subsystems
        @system_manager.initialize_systems(@window_width, @window_height)

        # Initialize input handler
        @input_handler = EngineComponents::InputHandler.new

        # Setup camera
        @camera = Graphics::Camera.new(@window_width, @window_height)
        @camera.not_nil!.set_scene_size(@window_width, @window_height)

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
        # Handle input - use verb input if enabled, otherwise standard input
        if @verb_input_system && @verb_input_system.not_nil!.enabled
          @verb_input_system.not_nil!.process_input(@current_scene, player, display_manager, @camera)
        else
          @input_handler.try do |handler|
            handler.handle_click(@current_scene, player, @camera)
            handler.handle_keyboard_input
          end
        end

        # Update systems
        @system_manager.update_systems(dt)

        # Update scene
        @current_scene.try(&.update(dt))

        # Update inventory
        @inventory.update(dt)

        # Update camera
        mouse_pos = RL.get_mouse_position
        @camera.try(&.update(dt, mouse_pos.x.to_i, mouse_pos.y.to_i))

        # Handle auto-save
        handle_auto_save(dt)

        # Call update callback if set
        @update_callback.try(&.call(dt))
      end

      # Renders the game
      private def render
        # Render scene with camera
        @current_scene.try(&.draw(@camera))

        # Render UI and overlays
        @system_manager.dialog_manager.try(&.draw)
        @inventory.draw
        @system_manager.menu_system.try(&.render)

        # Debug rendering
        if @@debug_mode
          render_debug_info
        end
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
        @scene_manager.scenes
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

      def event_system
        @system_manager.event_system
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

      def dialog_manager
        @system_manager.dialog_manager
      end

      def script_engine
        @system_manager.script_engine
      end

      def show_main_menu
        @system_manager.menu_system.try(&.show_main_menu)
      end

      def menu_system
        @system_manager.menu_system
      end

      def toggle_hotspot_highlight
        # Toggle hotspot highlighting in current scene
        @current_scene.try(&.toggle_hotspot_highlight)
      end

      # Scene management
      def change_scene(scene_name : String)
        result = @scene_manager.change_scene(scene_name)
        case result
        when .success?
          @current_scene = result.value
          # Assign pending player if any
          if pending = @pending_player
            @current_scene.try { |scene| scene.player = pending }
            @pending_player = nil
          end
          @current_scene.try(&.on_enter)
        when .failure?
          raise "Failed to change scene: #{result.error.message}"
        end
      end

      def change_scene_with_transition(scene_name : String, effect : Graphics::Transitions::TransitionEffect?, duration : Float32, position : RL::Vector2? = nil)
        # Start transition if effect specified
        if effect && (tm = @system_manager.transition_manager)
          tm.start_transition(effect, duration) do
            # Change scene at halfway point
            change_scene(scene_name)

            # If position provided, move player
            if pos = position
              if player = self.player
                player.position = pos
              end
            end
          end
        else
          # No transition, just change scene
          change_scene(scene_name)

          # If position provided, move player
          if pos = position
            if player = self.player
              player.position = pos
            end
          end
        end
      end

      def add_scene(scene : Scenes::Scene)
        @scene_manager.add_scene(scene)
      end

      # Window management
      def toggle_fullscreen
        @fullscreen = !@fullscreen
        # TODO: Actually implement fullscreen toggle with Raylib
        # RL.toggle_fullscreen
      end

      def fullscreen : Bool
        @fullscreen
      end

      def fullscreen=(value : Bool)
        @fullscreen = value
        # TODO: Actually implement fullscreen setting with Raylib
        # if value
        #   RL.set_window_flag(RL::FLAG_FULLSCREEN_MODE)
        # else
        #   RL.clear_window_flag(RL::FLAG_FULLSCREEN_MODE)
        # end
      end

      def set_window_size(width : Int32, height : Int32)
        @window_width = width
        @window_height = height
        RL.set_window_size(width, height)
        @camera.try(&.set_bounds(0, 0, width, height))
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
    end
  end
end
