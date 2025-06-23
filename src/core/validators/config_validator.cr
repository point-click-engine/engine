require "../exceptions"
require "../game_config"

module PointClickEngine
  module Core
    module Validators
      class ConfigValidator
        def self.validate(config : GameConfig, config_path : String) : Array(String)
          errors = [] of String

          # Validate required fields
          validate_game_info(config.game, errors)

          if window = config.window
            validate_window_config(window, errors)
          end

          if player = config.player
            validate_player_config(player, config_path, errors)
          end

          if assets = config.assets
            validate_assets_config(assets, config_path, errors)
          end

          if display = config.display
            validate_display_config(display, errors)
          end

          if settings = config.settings
            validate_settings_config(settings, errors)
          end

          if initial_state = config.initial_state
            validate_initial_state(initial_state, errors)
          end

          # Validate start scene exists if specified
          if scene = config.start_scene
            if assets = config.assets
              unless scene_exists_in_config_dir?(assets, scene, config_path)
                errors << "Start scene '#{scene}' not found in asset patterns"
              end
            end
          end

          # Validate start music exists if specified
          if music = config.start_music
            if config.assets && config.assets.not_nil!.audio
              unless config.assets.not_nil!.audio.not_nil!.music.has_key?(music)
                errors << "Start music '#{music}' not defined in audio.music section"
              end
            end
          end

          errors
        end

        private def self.validate_game_info(game_info : GameConfig::GameInfo?, errors : Array(String))
          unless game_info
            errors << "Missing required 'game' section"
            return
          end

          if game_info.title.empty?
            errors << "Game title cannot be empty"
          end
        end

        private def self.validate_window_config(window : GameConfig::WindowConfig, errors : Array(String))
          if window.width <= 0
            errors << "Window width must be positive (got #{window.width})"
          end
          if window.height <= 0
            errors << "Window height must be positive (got #{window.height})"
          end
          if window.target_fps <= 0 || window.target_fps > 300
            errors << "Target FPS must be between 1 and 300 (got #{window.target_fps})"
          end
        end

        private def self.validate_player_config(player : GameConfig::PlayerConfig, config_path : String, errors : Array(String))
          if player.sprite_path.empty?
            errors << "Player sprite_path cannot be empty"
          else
            base_dir = File.dirname(config_path)
            full_path = File.join(base_dir, player.sprite_path)
            unless File.exists?(full_path) || file_exists_in_patterns?(player.sprite_path)
              errors << "Player sprite file '#{player.sprite_path}' not found"
            end
          end

          sprite = player.sprite
          if sprite.frame_width <= 0
            errors << "Player sprite frame_width must be positive"
          end
          if sprite.frame_height <= 0
            errors << "Player sprite frame_height must be positive"
          end
          if sprite.columns <= 0
            errors << "Player sprite columns must be positive"
          end
          if sprite.rows <= 0
            errors << "Player sprite rows must be positive"
          end

          if pos = player.start_position
            if pos.x < 0
              errors << "Player start position X cannot be negative"
            end
            if pos.y < 0
              errors << "Player start position Y cannot be negative"
            end
          end
        end

        private def self.validate_assets_config(assets : GameConfig::AssetsConfig, config_path : String, errors : Array(String))
          base_dir = File.dirname(config_path)

          # Check scene patterns
          if assets.scenes.empty?
            errors << "No scene patterns defined in assets.scenes"
          else
            scene_count = 0
            assets.scenes.each do |pattern|
              glob_pattern = File.join(base_dir, pattern)
              matching_files = Dir.glob(glob_pattern)
              scene_count += matching_files.size

              if matching_files.empty?
                errors << "Scene pattern '#{pattern}' matches no files"
              end
            end

            if scene_count == 0
              errors << "No scene files found using provided patterns"
            end
          end

          # Check dialog patterns
          assets.dialogs.each do |pattern|
            glob_pattern = File.join(base_dir, pattern)
            if Dir.glob(glob_pattern).empty?
              errors << "Dialog pattern '#{pattern}' matches no files"
            end
          end

          # Check quest patterns
          assets.quests.each do |pattern|
            glob_pattern = File.join(base_dir, pattern)
            if Dir.glob(glob_pattern).empty?
              errors << "Quest pattern '#{pattern}' matches no files"
            end
          end

          # Validate audio assets
          if audio = assets.audio
            audio.music.each do |name, path|
              full_path = File.expand_path(path, base_dir)
              unless File.exists?(full_path)
                errors << "Music file '#{name}' not found at: #{path}"
              end
            end

            audio.sounds.each do |name, path|
              full_path = File.expand_path(path, base_dir)
              unless File.exists?(full_path)
                errors << "Sound file '#{name}' not found at: #{path}"
              end
            end
          end
        end

        private def self.validate_display_config(display : GameConfig::DisplayConfig, errors : Array(String))
          valid_modes = ["FitWithBars", "Stretch", "PixelPerfect"]
          unless valid_modes.includes?(display.scaling_mode)
            errors << "Invalid scaling_mode '#{display.scaling_mode}'. Must be one of: #{valid_modes.join(", ")}"
          end

          if display.target_width <= 0
            errors << "Display target_width must be positive"
          end
          if display.target_height <= 0
            errors << "Display target_height must be positive"
          end
        end

        private def self.validate_settings_config(settings : GameConfig::SettingsConfig, errors : Array(String))
          if settings.master_volume < 0 || settings.master_volume > 1
            errors << "master_volume must be between 0 and 1 (got #{settings.master_volume})"
          end
          if settings.music_volume < 0 || settings.music_volume > 1
            errors << "music_volume must be between 0 and 1 (got #{settings.music_volume})"
          end
          if settings.sfx_volume < 0 || settings.sfx_volume > 1
            errors << "sfx_volume must be between 0 and 1 (got #{settings.sfx_volume})"
          end
        end

        private def self.validate_initial_state(state : GameConfig::InitialState, errors : Array(String))
          # Check for reserved flag/variable names
          reserved_names = ["true", "false", "nil", "null"]

          state.flags.each_key do |name|
            if reserved_names.includes?(name.downcase)
              errors << "Flag name '#{name}' is reserved and cannot be used"
            end
            if name.empty?
              errors << "Flag names cannot be empty"
            end
          end

          state.variables.each_key do |name|
            if reserved_names.includes?(name.downcase)
              errors << "Variable name '#{name}' is reserved and cannot be used"
            end
            if name.empty?
              errors << "Variable names cannot be empty"
            end
          end
        end

        private def self.scene_exists_in_config_dir?(assets : GameConfig::AssetsConfig, scene_name : String, config_path : String) : Bool
          base_dir = File.dirname(config_path)
          assets.scenes.each do |pattern|
            Dir.glob(File.join(base_dir, pattern)).each do |path|
              if File.basename(path, ".yaml") == scene_name
                return true
              end
            end
          end
          false
        end

        private def self.file_exists_in_patterns?(file_path : String) : Bool
          # Check if file exists directly or in common asset directories
          return true if File.exists?(file_path)

          # Check common asset directories
          ["assets/", "data/", "resources/"].each do |dir|
            return true if File.exists?(File.join(dir, file_path))
          end

          false
        end
      end
    end
  end
end
