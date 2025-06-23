# Game configuration from YAML
require "yaml"
require "./engine"
require "./game_state_manager"
require "./quest_system"
require "../characters/player"
require "../scenes/scene_loader"
require "../graphics/display_manager"
require "../graphics/shaders/shader_helpers"
require "../characters/dialogue/dialog_tree"
require "./exceptions"
require "./validators/config_validator"
require "./error_reporter"

module PointClickEngine
  module Core
    # Game configuration structure that maps to YAML
    class GameConfig
      include YAML::Serializable

      class GameInfo
        include YAML::Serializable
        property title : String
        property version : String?
        property author : String?
      end

      class WindowConfig
        include YAML::Serializable
        property width : Int32 = 1024
        property height : Int32 = 768
        property fullscreen : Bool = false
        property target_fps : Int32 = 60
      end

      class DisplayConfig
        include YAML::Serializable
        property scaling_mode : String = "FitWithBars"
        property target_width : Int32 = 1024
        property target_height : Int32 = 768
      end

      class SpriteInfo
        include YAML::Serializable
        property frame_width : Int32
        property frame_height : Int32
        property columns : Int32
        property rows : Int32
      end

      class Position
        include YAML::Serializable
        property x : Float32
        property y : Float32
      end

      class PlayerConfig
        include YAML::Serializable
        property name : String = "Player"
        property sprite_path : String
        property sprite : SpriteInfo
        property scale : Float32 = 1.0f32
        property start_position : Position?
      end

      class AssetsConfig
        include YAML::Serializable
        property scenes : Array(String) = [] of String
        property dialogs : Array(String) = [] of String
        property quests : Array(String) = [] of String
        property audio : AudioConfig?
      end

      class AudioConfig
        include YAML::Serializable
        property music : Hash(String, String) = {} of String => String
        property sounds : Hash(String, String) = {} of String => String
      end

      class SettingsConfig
        include YAML::Serializable
        property debug_mode : Bool = false
        property show_fps : Bool = false
        property master_volume : Float32 = 0.8
        property music_volume : Float32 = 0.7
        property sfx_volume : Float32 = 0.9
      end

      class InitialState
        include YAML::Serializable
        property flags : Hash(String, Bool) = {} of String => Bool
        property variables : Hash(String, Float32 | Int32 | String) = {} of String => Float32 | Int32 | String
      end

      class UIHint
        include YAML::Serializable
        property text : String
        property duration : Float32 = 5.0
      end

      class UIConfig
        include YAML::Serializable
        property hints : Array(UIHint) = [] of UIHint
        property opening_message : String?
      end

      property game : GameInfo
      property window : WindowConfig?
      property display : DisplayConfig?
      property player : PlayerConfig?
      property features : Array(String) = [] of String
      property assets : AssetsConfig?
      property settings : SettingsConfig?
      property initial_state : InitialState?
      property start_scene : String?
      property start_music : String?
      property ui : UIConfig?

      # Non-serialized property to store config directory
      @[YAML::Field(ignore: true)]
      property config_base_dir : String = ""

      # Load configuration from YAML file
      def self.from_file(path : String) : GameConfig
        unless File.exists?(path)
          raise ConfigError.new("Configuration file not found", path)
        end

        begin
          yaml_content = File.read(path)
          config = from_yaml(yaml_content)

          # Validate configuration
          errors = Validators::ConfigValidator.validate(config, path)
          unless errors.empty?
            raise ValidationError.new(errors, path)
          end

          # Store base directory for asset loading
          config.config_base_dir = File.dirname(path)

          config
        rescue ex : YAML::ParseException
          raise ConfigError.new("Invalid YAML syntax: #{ex.message}", path)
        rescue ex : ValidationError
          raise ex
        rescue ex
          raise ConfigError.new("Failed to load configuration: #{ex.message}", path)
        end
      end

      # Create and configure engine from this config
      def create_engine : Engine
        # Use defaults if window config not provided
        w = window.try(&.width) || 1024
        h = window.try(&.height) || 768

        engine = Engine.new(w, h, game.title)
        engine.init

        # Configure engine from settings
        configure_engine(engine)

        # Load all assets
        load_assets(engine)

        # Set up initial game state
        setup_initial_state(engine)

        # Configure UI
        setup_ui(engine)

        engine
      end

      private def configure_engine(engine : Engine)
        # Create and assign managers
        engine.game_state_manager = Core::GameStateManager.new
        engine.quest_manager = QuestManager.new

        # Enable features
        features.each do |feature|
          case feature.downcase
          when "verbs"
            engine.enable_verb_input
          when "floating_dialogs"
            engine.dialog_manager.try { |dm| dm.enable_floating = true }
          when "portraits"
            engine.dialog_manager.try { |dm| dm.enable_portraits = true }
          when "shaders"
            setup_shaders(engine)
          when "auto_save"
            # Enable autosave feature
            engine.enable_auto_save(300) # Every 5 minutes
          when "debug"
            Engine.debug_mode = true
          end
        end

        # Configure display
        if dm = engine.display_manager
          if disp = display
            dm.scaling_mode = case disp.scaling_mode
                              when "FitWithBars"
                                Graphics::DisplayManager::ScalingMode::FitWithBars
                              when "Stretch"
                                Graphics::DisplayManager::ScalingMode::Stretch
                              when "PixelPerfect"
                                Graphics::DisplayManager::ScalingMode::PixelPerfect
                              else
                                Graphics::DisplayManager::ScalingMode::FitWithBars
                              end
            dm.target_width = disp.target_width
            dm.target_height = disp.target_height
          end
        end

        # Configure player
        if player_config = player
          player_obj = Characters::Player.new(
            player_config.name,
            Raylib::Vector2.new(
              x: player_config.start_position.try(&.x) || (window.try(&.width) || 1024) / 2,
              y: player_config.start_position.try(&.y) || (window.try(&.height) || 768) - 150
            ),
            Raylib::Vector2.new(
              x: player_config.sprite.frame_width.to_f32,
              y: player_config.sprite.frame_height.to_f32
            )
          )

          # Resolve player sprite path relative to config directory
          full_player_sprite_path = File.join(config_base_dir, player_config.sprite_path)
          player_obj.load_enhanced_spritesheet(
            full_player_sprite_path,
            player_config.sprite.frame_width,
            player_config.sprite.frame_height,
            player_config.sprite.columns,
            player_config.sprite.rows
          )

          # Apply scale from config
          player_obj.manual_scale = player_config.scale
          player_obj.scale = player_config.scale

          # Increase walking speed to compensate for larger appearance
          player_obj.walking_speed = GameConstants::SCALED_WALKING_SPEED

          engine.player = player_obj
        end

        # Apply settings
        if s = settings
          Engine.debug_mode = s.debug_mode
          engine.show_fps = s.show_fps
        end

        # Configure audio volumes
        if audio = engine.audio_manager
          if s = settings
            audio.master_volume = s.master_volume
            audio.music_volume = s.music_volume
            audio.sfx_volume = s.sfx_volume
          end
        end

        # Set target FPS
        engine.target_fps = window.try(&.target_fps) || 60

        # Set up update callback for managers
        engine.on_update = ->(dt : Float32) do
          if gsm = engine.game_state_manager
            gsm.update_timers(dt)
            gsm.update_game_time(dt)
          end
          if qm = engine.quest_manager
            qm.update_all_quests(gsm.not_nil!, dt) if gsm
          end
        end
      end

      private def load_assets(engine : Engine)
        # Load scenes
        assets.try(&.scenes.each do |pattern|
          Dir.glob(File.join(config_base_dir, pattern)).each do |path|
            if File.exists?(path)
              begin
                ErrorReporter.report_progress("Loading scene '#{File.basename(path)}'")
                scene = Scenes::SceneLoader.load_from_yaml(path)
                engine.add_scene(scene)
                ErrorReporter.report_progress_done(true)
              rescue ex : SceneError
                ErrorReporter.report_progress_done(false)
                ErrorReporter.report_loading_error(ex, "Loading scenes")
                raise ex
              rescue ex
                ErrorReporter.report_progress_done(false)
                raise SceneError.new("Failed to load scene: #{ex.message}", File.basename(path, ".yaml"))
              end
            end
          end
        end)

        # Load dialogs
        assets.try(&.dialogs.each do |pattern|
          Dir.glob(File.join(config_base_dir, pattern)).each do |path|
            begin
              ErrorReporter.report_progress("Loading dialog '#{File.basename(path)}'")
              dialog_tree = Characters::Dialogue::DialogTree.load_from_file(path)
              puts "Loaded dialog tree '#{dialog_tree.name}' with #{dialog_tree.nodes.size} nodes"
              # Store dialog tree in engine for character access
              if dm = engine.dialog_manager
                dm.add_dialog_tree(dialog_tree)
              end
              ErrorReporter.report_progress_done(true)
            rescue ex
              ErrorReporter.report_progress_done(false)
              ErrorReporter.report_warning("Failed to load dialog from #{path}: #{ex.message}", "Loading dialogs")
            end
          end
        end)

        # Load quests
        if qm = engine.quest_manager
          assets.try(&.quests.each do |pattern|
            Dir.glob(File.join(config_base_dir, pattern)).each do |path|
              if File.exists?(path)
                ErrorReporter.report_progress("Loading quests '#{File.basename(path)}'")
                success = qm.load_quests_from_yaml(path)
                ErrorReporter.report_progress_done(success)
                unless success
                  ErrorReporter.report_warning("Failed to load some quests from #{path}", "Loading quests")
                end
              end
            end
          end)
        end

        # Load audio
        if audio = engine.audio_manager
          assets.try(&.audio).try do |audio_config|
            # Load music
            audio_config.music.each do |name, path|
              if File.exists?(path)
                audio.load_music(name, path)
              end
            end

            # Load sounds
            audio_config.sounds.each do |name, path|
              if File.exists?(path)
                audio.load_sound_effect(name, path)
              end
            end
          end
        end
      end

      private def setup_initial_state(engine : Engine)
        if gsm = engine.game_state_manager
          if initial = initial_state
            # Set initial flags
            initial.flags.each do |name, value|
              gsm.set_flag(name, value)
            end

            # Set initial variables
            initial.variables.each do |name, value|
              case value
              when Int32
                gsm.set_variable(name, value)
              when Float32
                gsm.set_variable(name, value)
              when String
                gsm.set_variable(name, value)
              end
            end
          end

          # Add state change handler for quest updates
          quest_manager = engine.quest_manager
          gsm.add_change_handler(->(name : String, value : GameValue) {
            if qm = quest_manager
              qm.update_all_quests(gsm, 0.0f32)
            end
          })
        end
      end

      private def setup_ui(engine : Engine)
        # Set up game start handler
        ui_config = self.ui
        start_scene_name = self.start_scene
        start_music_name = self.start_music

        engine.event_system.on("game:new") do
          # Change to start scene
          if scene_name = start_scene_name
            engine.change_scene(scene_name)
          end

          # Play start music
          if music_name = start_music_name
            engine.audio_manager.try &.play_music(music_name, true)
          end

          # Show opening message
          if u = ui_config
            if msg = u.opening_message
              engine.dialog_manager.try &.show_message(msg)
            end

            # Show hints
            if gui = engine.gui
              y_offset = 10f32
              u.hints.each_with_index do |hint, i|
                label_id = "hint_#{i}"
                gui.add_label(label_id, hint.text,
                  Raylib::Vector2.new(x: 10f32, y: y_offset),
                  16, Raylib::WHITE)
                y_offset += 20f32

                # Auto-hide after duration - using a timer event
                # For now, we'll just note that hints should be hidden after duration
                # This would need to be handled by the GUI system itself
              end
            end
          end

          # Start the game
          engine.start_game
        end
      end

      private def setup_shaders(engine : Engine)
        return unless shader_system = engine.shader_system

        # Create common shaders
        Graphics::Shaders::ShaderHelpers.create_vignette_shader(shader_system)
        Graphics::Shaders::ShaderHelpers.create_bloom_shader(shader_system)
      end
    end
  end
end
