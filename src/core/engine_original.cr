# Core Game Engine Module
# Manages the main game loop, initialization, and high-level coordination

require "raylib-cr"
require "yaml"
require "./state_value"

module PointClickEngine
  module Core
    # Main game class - singleton pattern for global access
    class Engine
      include YAML::Serializable

      class_property debug_mode : Bool = false
      @@instance : Engine?

      def self.instance : Engine
        raise "Engine not initialized" unless @@instance
        @@instance.not_nil!
      end

      @[YAML::Field(ignore: true)]
      property initialized : Bool = false
      property window_width : Int32
      property window_height : Int32
      property title : String
      property target_fps : Int32 = 60
      @[YAML::Field(ignore: true)]
      property running : Bool = false
      @[YAML::Field(ignore: true)]
      property handle_clicks : Bool = true

      property current_scene_name : String?
      @[YAML::Field(ignore: true)]
      property current_scene : Scenes::Scene?
      property scenes : Hash(String, Scenes::Scene) = {} of String => Scenes::Scene

      property inventory : Inventory::InventorySystem
      property dialogs : Array(UI::Dialog) = [] of UI::Dialog

      property cursor_texture_path : String?
      @[YAML::Field(ignore: true)]
      property cursor_texture : RL::Texture2D?
      property default_cursor : RL::MouseCursor = RL::MouseCursor::Default

      @[YAML::Field(ignore: true)]
      property display_manager : Graphics::DisplayManager?
      property fullscreen : Bool = false

      # Scripting system
      @[YAML::Field(ignore: true)]
      property script_engine : Scripting::ScriptEngine?
      @[YAML::Field(ignore: true)]
      property event_system : Scripting::EventSystem = Scripting::EventSystem.new

      # Additional managers
      @[YAML::Field(ignore: true)]
      property dialog_manager : UI::DialogManager?
      @[YAML::Field(ignore: true)]
      property achievement_manager : Core::AchievementManager?
      @[YAML::Field(ignore: true)]
      property audio_manager : Audio::AudioManager?
      @[YAML::Field(ignore: true)]
      property shader_system : Graphics::Shaders::ShaderSystem?
      @[YAML::Field(ignore: true)]
      property gui : UI::GUIManager?
      @[YAML::Field(ignore: true)]
      property config : Core::ConfigManager?
      @[YAML::Field(ignore: true)]
      property player : Characters::Character?
      
      # Game state variables
      property state_variables : Hash(String, StateValue) = {} of String => StateValue

      # Cutscene system
      @[YAML::Field(ignore: true)]
      property cutscene_manager : Cutscenes::CutsceneManager = Cutscenes::CutsceneManager.new
      
      # Transition system
      @[YAML::Field(ignore: true)]
      property transition_manager : Graphics::TransitionManager?

      @ui_visible : Bool = true

      def initialize(@window_width : Int32, @window_height : Int32, @title : String)
        @inventory = Inventory::InventorySystem.new(RL::Vector2.new(x: 10, y: @window_height - 80))
        @scenes = {} of String => Scenes::Scene
        @dialogs = [] of UI::Dialog
        @cutscene_manager = Cutscenes::CutsceneManager.new
        @@instance = self
      end

      def initialize
        @window_width = 800
        @window_height = 600
        @title = "Game"
        @inventory = Inventory::InventorySystem.new(RL::Vector2.new(x: 10, y: 520))
        @scenes = {} of String => Scenes::Scene
        @dialogs = [] of UI::Dialog
        @cutscene_manager = Cutscenes::CutsceneManager.new
        @@instance = self
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        @scenes.each_value &.after_yaml_deserialize(ctx)
        @inventory.after_yaml_deserialize(ctx)
        @dialogs.each &.after_yaml_deserialize(ctx)

        if path = @cursor_texture_path
          if RL.window_ready?
            load_cursor(path)
          end
        end

        if name = @current_scene_name
          @current_scene = @scenes[name]?
        end

        @@instance = self
        post_deserialize_linking
      end

      def init
        return if @initialized

        RL.init_window(@window_width, @window_height, @title)
        init_engine_systems
      end

      def init(width : Int32, height : Int32, title : String)
        @window_width = width
        @window_height = height
        @title = title
        init

        monitor = RL.get_current_monitor
        screen_width = RL.get_monitor_width(monitor)
        screen_height = RL.get_monitor_height(monitor)

        if @fullscreen
          RL.set_window_size(screen_width, screen_height)
          RL.set_window_state(RL::ConfigFlags::FullscreenMode)
          @display_manager = Graphics::DisplayManager.new(screen_width, screen_height)
        else
          windowed_width = Math.min(1280, Math.max(800, screen_width - 200))
          windowed_height = Math.min(960, Math.max(600, screen_height - 200))
          RL.set_window_size(windowed_width, windowed_height)
          @display_manager = Graphics::DisplayManager.new(windowed_width, windowed_height)
        end

        RL.set_window_state(RL::ConfigFlags::WindowResizable)
        RL.set_target_fps(@target_fps)

        if path = @cursor_texture_path
          load_cursor(path)
        else
          RL.set_mouse_cursor(@default_cursor)
        end

        # Initialize scripting engine
        initialize_scripting

        @initialized = true
      end

      def load_cursor(path : String)
        @cursor_texture_path = path
        @cursor_texture = AssetLoader.load_texture(path)
        RL.hide_cursor if @initialized
      end

      def add_scene(scene : Scenes::Scene)
        @scenes[scene.name] = scene
        # Setup navigation grid when scene is added
        scene.setup_navigation if scene.enable_pathfinding
      end

      # Archive management methods
      def mount_archive(path : String, mount_point : String = "/")
        AssetManager.mount_archive(path, mount_point)
      end

      def unmount_archive(mount_point : String = "/")
        AssetManager.unmount_archive(mount_point)
      end

      def change_scene(name : String)
        if new_scene = @scenes[name]?
          @current_scene.try &.exit
          @current_scene = new_scene
          @current_scene_name = name
          new_scene.enter
          # Setup navigation when scene becomes active
          new_scene.setup_navigation if new_scene.enable_pathfinding && !new_scene.navigation_grid
        end
      end

      def show_dialog(dialog : UI::Dialog)
        dialog.show
        @dialogs << dialog unless @dialogs.includes?(dialog)
      end

      def show_ui
        @ui_visible = true
      end

      def hide_ui
        @ui_visible = false
      end

      def run
        init
        @running = true
        @current_scene.try &.enter

        while @running && !RL.close_window?
          update(RL.get_frame_time)
          draw
        end
        cleanup
      end

      def stop
        @running = false
      end

      def toggle_fullscreen
        @fullscreen = !@fullscreen

        if @fullscreen
          monitor = RL.get_current_monitor
          screen_width = RL.get_monitor_width(monitor)
          screen_height = RL.get_monitor_height(monitor)
          RL.set_window_size(screen_width, screen_height)
          RL.set_window_state(RL::ConfigFlags::FullscreenMode)
          @display_manager.not_nil!.resize(screen_width, screen_height)
        else
          RL.clear_window_state(RL::ConfigFlags::FullscreenMode)
          windowed_width = 1280
          windowed_height = 960
          RL.set_window_size(windowed_width, windowed_height)
          @display_manager.not_nil!.resize(windowed_width, windowed_height)
        end
      end

      def set_scaling_mode(mode : Graphics::DisplayManager::ScalingMode)
        @display_manager.not_nil!.set_scaling_mode(mode)
      end

      def save_game(filepath : String)
        begin
          File.write(filepath, self.to_yaml)
          puts "Game saved to #{filepath}"
        rescue ex
          STDERR.puts "Error saving game: #{ex}"
        end
      end

      def self.load_game(filepath : String) : Engine?
        begin
          yaml_string = File.read(filepath)
          engine = Engine.from_yaml(yaml_string)
          puts "Game loaded from #{filepath}"
          return engine
        rescue ex
          STDERR.puts "Error loading game: #{ex}"
          return nil
        end
      end

      def update(dt : Float32)
        if RL.window_resized?
          new_width = RL.get_screen_width
          new_height = RL.get_screen_height
          @display_manager.not_nil!.resize(new_width, new_height)
        end

        if RL::KeyboardKey::F11.pressed?
          toggle_fullscreen
        end

        handle_scaling_hotkeys

        raw_mouse_pos = RL.get_mouse_position
        if dm = @display_manager
          game_mouse_pos = dm.screen_to_game(raw_mouse_pos)

          if dm.is_in_game_area(raw_mouse_pos)
            update_game_logic(dt, game_mouse_pos)
          end
        end
      end

      private def handle_scaling_hotkeys
        if RL::KeyboardKey::F2.pressed?
          set_scaling_mode(Graphics::DisplayManager::ScalingMode::FitWithBars)
        elsif RL::KeyboardKey::F3.pressed?
          set_scaling_mode(Graphics::DisplayManager::ScalingMode::Stretch)
        elsif RL::KeyboardKey::F4.pressed?
          set_scaling_mode(Graphics::DisplayManager::ScalingMode::Fill)
        elsif RL::KeyboardKey::F5.pressed?
          set_scaling_mode(Graphics::DisplayManager::ScalingMode::PixelPerfect)
        end
      end

      private def update_game_logic(dt : Float32, mouse_pos : RL::Vector2)
        # Process events first
        @event_system.process_events

        # Update cutscenes
        @cutscene_manager.update(dt)

        # Skip cutscene on ESC or Space
        if @cutscene_manager.is_playing?
          if Raylib.key_pressed?(Raylib::KeyboardKey::Escape) || Raylib.key_pressed?(Raylib::KeyboardKey::Space)
            @cutscene_manager.skip_current
          end
        end

        # Only update game logic if not in cutscene
        unless @cutscene_manager.is_playing?
          @current_scene.try &.update(dt)
          @inventory.update(dt) if @inventory.visible

          # Update additional managers
          @dialog_manager.try &.update(dt)
          @gui.try &.update(dt)
          @achievement_manager.try &.update(dt)
          @audio_manager.try &.update
          @dialogs.each(&.update(dt))
          @dialogs.reject! { |d| !d.visible }

          # Removed - input handling moved to game class

          # Removed - input handling moved to game class

          if @handle_clicks && RL::MouseButton::Left.pressed?
            handle_click(mouse_pos)
          end

          update_cursor
        end
      end

      private def handle_click(game_mouse_pos : RL::Vector2)
        return unless scene = @current_scene

        if hotspot = scene.get_hotspot_at(game_mouse_pos)
          # Special handling for exit zones
          if hotspot.is_a?(Scenes::ExitZone)
            exit_zone = hotspot.as(Scenes::ExitZone)
            exit_zone.on_click_exit(self)
          else
            hotspot.on_click.try &.call
          end
        elsif character = scene.get_character_at(game_mouse_pos)
          if player = scene.player
            character.on_interact(player)
          end
        elsif player = scene.player
          # Use pathfinding if available
          if player.use_pathfinding && scene.enable_pathfinding
            if path = scene.find_path(player.position.x, player.position.y, game_mouse_pos.x, game_mouse_pos.y)
              player.walk_to_with_path(path)
            else
              # No path found, try direct movement
              player.walk_to(game_mouse_pos)
            end
          else
            if player.responds_to?(:handle_click)
              player.handle_click(game_mouse_pos, scene)
            else
              player.walk_to(game_mouse_pos)
            end
          end
        end
      end

      private def update_cursor
        return if @cursor_texture
        mouse_pos = RL.get_mouse_position
        if dm = @display_manager
          game_mouse_pos = dm.screen_to_game(mouse_pos)
          if scene = @current_scene
            if hotspot = scene.get_hotspot_at(game_mouse_pos)
              case hotspot.cursor_type
              when Scenes::Hotspot::CursorType::Hand    then RL.set_mouse_cursor(RL::MouseCursor::PointingHand)
              when Scenes::Hotspot::CursorType::Default then RL.set_mouse_cursor(RL::MouseCursor::Default)
              else                                           RL.set_mouse_cursor(RL::MouseCursor::Crosshair)
              end
            else
              RL.set_mouse_cursor(@default_cursor)
            end
          else
            RL.set_mouse_cursor(@default_cursor)
          end
        end
      end

      private def draw
        return unless dm = @display_manager

        dm.begin_game_rendering
        draw_game_content
        dm.end_game_rendering
      end

      private def draw_game_content
        @current_scene.try &.draw

        # Draw UI only if visible and not in cutscene
        if @ui_visible && !@cutscene_manager.is_playing?
          @inventory.draw
          @dialogs.each(&.draw)
          @dialog_manager.try &.draw
          @gui.try &.draw
        end

        # Draw achievements notifications
        @achievement_manager.try &.draw

        # Draw cutscene overlays
        @cutscene_manager.draw

        if cursor = @cursor_texture
          if dm = @display_manager
            raw_mouse = RL.get_mouse_position
            if dm.is_in_game_area(raw_mouse)
              game_mouse = dm.screen_to_game(raw_mouse)
              RL.draw_texture_v(cursor, game_mouse, RL::WHITE)
            end
          end
        end

        if Engine.debug_mode
          draw_debug_info
        end

        # Draw cutscene skip prompt
        if @cutscene_manager.is_playing?
          skip_text = t("cutscene.skip_prompt", default: "Press ESC or SPACE to skip")
          RL.draw_text(skip_text, 10, RL.get_screen_height - 30, 16, RL::WHITE)
        end
      end

      private def draw_debug_info
        RL.draw_text("FPS: #{RL.get_fps}", 10, 10, 20, RL::GREEN)
        if dm = @display_manager
          raw_mouse = RL.get_mouse_position
          game_mouse = dm.screen_to_game(raw_mouse)
          RL.draw_text("Game Mouse: #{game_mouse.x.to_i}, #{game_mouse.y.to_i}", 10, 35, 20, RL::GREEN)
          RL.draw_text("Resolution: #{Graphics::DisplayManager::REFERENCE_WIDTH}x#{Graphics::DisplayManager::REFERENCE_HEIGHT}", 10, 60, 20, RL::GREEN)

          # Draw navigation debug
          if RL.key_down?(RL::KeyboardKey::N.to_i)
            @current_scene.try &.draw_navigation_debug
          end
        end
      end

      private def post_deserialize_linking
        all_characters = Hash(String, Characters::Character).new
        @scenes.each_value do |scene|
          scene.characters.each { |char| all_characters[char.name] = char }
        end

        all_characters.each_value do |char|
          if partner_name = char.conversation_partner_name
            char.conversation_partner = all_characters[partner_name]?
          end
        end
      end

      # State variable management
      def get_state_variable(name : String) : StateValue?
        @state_variables[name]?
      end
      
      def set_state_variable(name : String, value : String | Int32 | Float32 | Bool)
        @state_variables[name] = StateValue.new(value)
      end
      
      def has_state_variable?(name : String) : Bool
        @state_variables.has_key?(name)
      end
      
      def cleanup
        @display_manager.try &.cleanup
        @transition_manager.try &.cleanup

        # Cleanup scripting engine
        @script_engine.try &.cleanup

        @scenes.each_value do |scene|
          if bg = scene.background
            RL.unload_texture(bg)
          end
          scene.objects.each do |obj|
            if obj.is_a?(Graphics::AnimatedSprite) && (tex = obj.as(Graphics::AnimatedSprite).texture)
              RL.unload_texture(tex)
            end
          end
        end

        @inventory.items.each do |item|
          if icon = item.icon
            RL.unload_texture(icon)
          end
        end

        if cursor = @cursor_texture
          RL.unload_texture(cursor)
        end

        RL.close_window if @initialized && RL.window_ready?
      end

      private def initialize_scripting
        begin
          @script_engine = Scripting::ScriptEngine.new

          # Trigger game started event
          @event_system.trigger_event(
            Scripting::Events::GAME_STARTED,
            {
              "window_width"  => @window_width.to_s,
              "window_height" => @window_height.to_s,
              "title"         => @title,
            }
          )
        rescue ex
          puts "Failed to initialize scripting engine: #{ex.message}"
          @script_engine = nil
        end
      end

      private def init_engine_systems
        # Initialize audio manager if not already set
        @audio_manager ||= Audio::AudioManager.new if Audio::AudioManager.available?

        # Initialize shader system
        @shader_system ||= Graphics::Shaders::ShaderSystem.new

        # Initialize GUI manager
        @gui ||= UI::GUIManager.new

        # Initialize dialog manager
        @dialog_manager ||= UI::DialogManager.new

        # Initialize achievement manager
        @achievement_manager ||= Core::AchievementManager.new

        # Initialize config manager
        @config ||= Core::ConfigManager.new
        
        # Initialize transition manager
        @transition_manager ||= Graphics::TransitionManager.new(@window_width, @window_height)
      end

      # UI Visibility Controls
      def ui_visible : Bool
        @ui_visible
      end

      def hide_ui
        @ui_visible = false
        @gui.try &.hide
        @inventory.hide if @inventory.responds_to?(:hide)
      end

      def show_ui
        @ui_visible = true
        @gui.try &.show
        @inventory.show if @inventory.responds_to?(:show)
      end

      def toggle_ui
        if @ui_visible
          hide_ui
        else
          show_ui
        end
      end
    end

    # Alias for backward compatibility
    alias Game = Engine
  end
end
