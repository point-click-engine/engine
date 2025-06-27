require "json"
require "file_utils"

module PointClickEngine
  module UI
    # Manages game configuration and settings
    #
    # The ConfigurationManager handles all configuration-related functionality including:
    # - Resolution and display settings
    # - Audio volume controls
    # - Game preferences and options
    # - Configuration persistence and loading
    class ConfigurationManager
      # Available resolution options
      struct Resolution
        property width : Int32
        property height : Int32
        property name : String

        def initialize(@width : Int32, @height : Int32, @name : String = "")
          @name = "#{@width}x#{@height}" if @name.empty?
        end

        def to_s(io : IO) : Nil
          io << @name
        end
      end

      # Configuration categories
      enum ConfigCategory
        Display
        Audio
        Gameplay
        Controls
        Advanced
      end

      # Configuration data structure
      struct ConfigData
        # Display settings
        property resolution : Resolution = Resolution.new(1024, 768, "1024x768")
        property fullscreen : Bool = false
        property vsync : Bool = true
        property scaling_mode : String = "maintain_aspect"

        # Audio settings
        property master_volume : Float32 = 1.0
        property music_volume : Float32 = 0.8
        property sfx_volume : Float32 = 1.0
        property voice_volume : Float32 = 1.0

        # Gameplay settings
        property text_speed : Float32 = 1.0
        property auto_save : Bool = true
        property auto_save_interval : Int32 = 300
        property difficulty : String = "normal"

        # Control settings
        property mouse_sensitivity : Float32 = 1.0
        property keyboard_navigation : Bool = true
        property gamepad_enabled : Bool = false

        # Advanced settings
        property debug_mode : Bool = false
        property performance_mode : Bool = false
        property language : String = "en"

        def initialize
        end
      end

      # Current configuration
      property config : ConfigData = ConfigData.new

      # Available options
      property available_resolutions : Array(Resolution) = [] of Resolution
      property available_languages : Array(String) = ["en", "es", "fr", "de", "it"]
      property available_difficulties : Array(String) = ["easy", "normal", "hard"]

      # Configuration file path
      property config_file_path : String = "settings.json"

      # Change tracking
      property has_unsaved_changes : Bool = false
      property config_version : Int32 = 1

      # Callbacks for configuration changes
      property on_resolution_changed : Proc(Resolution, Nil)?
      property on_volume_changed : Proc(String, Float32, Nil)?
      property on_setting_changed : Proc(String, String, Nil)?

      def initialize
        setup_default_resolutions
        load_configuration
      end

      # Loads configuration from file
      def load_configuration : Bool
        return false unless File.exists?(@config_file_path)

        begin
          json_data = File.read(@config_file_path)
          config_hash = JSON.parse(json_data).as_h

          # Load display settings
          if display = config_hash["display"]?.try(&.as_h)
            load_display_settings(display)
          end

          # Load audio settings
          if audio = config_hash["audio"]?.try(&.as_h)
            load_audio_settings(audio)
          end

          # Load gameplay settings
          if gameplay = config_hash["gameplay"]?.try(&.as_h)
            load_gameplay_settings(gameplay)
          end

          # Load control settings
          if controls = config_hash["controls"]?.try(&.as_h)
            load_control_settings(controls)
          end

          # Load advanced settings
          if advanced = config_hash["advanced"]?.try(&.as_h)
            load_advanced_settings(advanced)
          end

          @has_unsaved_changes = false
          return true
        rescue ex
          puts "Failed to load configuration: #{ex.message}"
          return false
        end
      end

      # Saves configuration to file
      def save_configuration : Bool
        begin
          config_data = {
            "version" => @config_version,
            "display" => {
              "resolution_width"  => @config.resolution.width,
              "resolution_height" => @config.resolution.height,
              "fullscreen"        => @config.fullscreen,
              "vsync"             => @config.vsync,
              "scaling_mode"      => @config.scaling_mode,
            },
            "audio" => {
              "master_volume" => @config.master_volume,
              "music_volume"  => @config.music_volume,
              "sfx_volume"    => @config.sfx_volume,
              "voice_volume"  => @config.voice_volume,
            },
            "gameplay" => {
              "text_speed"         => @config.text_speed,
              "auto_save"          => @config.auto_save,
              "auto_save_interval" => @config.auto_save_interval,
              "difficulty"         => @config.difficulty,
            },
            "controls" => {
              "mouse_sensitivity"   => @config.mouse_sensitivity,
              "keyboard_navigation" => @config.keyboard_navigation,
              "gamepad_enabled"     => @config.gamepad_enabled,
            },
            "advanced" => {
              "debug_mode"       => @config.debug_mode,
              "performance_mode" => @config.performance_mode,
              "language"         => @config.language,
            },
          }

          File.write(@config_file_path, config_data.to_json)
          @has_unsaved_changes = false
          return true
        rescue ex
          puts "Failed to save configuration: #{ex.message}"
          return false
        end
      end

      # Sets display resolution
      def set_resolution(resolution : Resolution)
        return if @config.resolution.width == resolution.width &&
                  @config.resolution.height == resolution.height

        @config.resolution = resolution
        @has_unsaved_changes = true
        @on_resolution_changed.try(&.call(resolution))
        @on_setting_changed.try(&.call("resolution", resolution.name))
      end

      # Sets display resolution by index
      def set_resolution_by_index(index : Int32)
        return unless index >= 0 && index < @available_resolutions.size
        set_resolution(@available_resolutions[index])
      end

      # Gets current resolution index
      def get_resolution_index : Int32
        @available_resolutions.each_with_index do |res, index|
          if res.width == @config.resolution.width && res.height == @config.resolution.height
            return index
          end
        end
        0
      end

      # Sets fullscreen mode
      def set_fullscreen(fullscreen : Bool)
        return if @config.fullscreen == fullscreen

        @config.fullscreen = fullscreen
        @has_unsaved_changes = true
        @on_setting_changed.try(&.call("fullscreen", fullscreen.to_s))
      end

      # Sets VSync
      def set_vsync(vsync : Bool)
        return if @config.vsync == vsync

        @config.vsync = vsync
        @has_unsaved_changes = true
        @on_setting_changed.try(&.call("vsync", vsync.to_s))
      end

      # Sets master volume
      def set_master_volume(volume : Float32)
        volume = volume.clamp(0.0f32, 1.0f32)
        return if @config.master_volume == volume

        @config.master_volume = volume
        @has_unsaved_changes = true
        @on_volume_changed.try(&.call("master", volume))
        @on_setting_changed.try(&.call("master_volume", volume.to_s))
      end

      # Sets music volume
      def set_music_volume(volume : Float32)
        volume = volume.clamp(0.0f32, 1.0f32)
        return if @config.music_volume == volume

        @config.music_volume = volume
        @has_unsaved_changes = true
        @on_volume_changed.try(&.call("music", volume))
        @on_setting_changed.try(&.call("music_volume", volume.to_s))
      end

      # Sets SFX volume
      def set_sfx_volume(volume : Float32)
        volume = volume.clamp(0.0f32, 1.0f32)
        return if @config.sfx_volume == volume

        @config.sfx_volume = volume
        @has_unsaved_changes = true
        @on_volume_changed.try(&.call("sfx", volume))
        @on_setting_changed.try(&.call("sfx_volume", volume.to_s))
      end

      # Sets voice volume
      def set_voice_volume(volume : Float32)
        volume = volume.clamp(0.0f32, 1.0f32)
        return if @config.voice_volume == volume

        @config.voice_volume = volume
        @has_unsaved_changes = true
        @on_volume_changed.try(&.call("voice", volume))
        @on_setting_changed.try(&.call("voice_volume", volume.to_s))
      end

      # Sets text speed
      def set_text_speed(speed : Float32)
        speed = speed.clamp(0.1f32, 3.0f32)
        return if @config.text_speed == speed

        @config.text_speed = speed
        @has_unsaved_changes = true
        @on_setting_changed.try(&.call("text_speed", speed.to_s))
      end

      # Sets auto save setting
      def set_auto_save(enabled : Bool)
        return if @config.auto_save == enabled

        @config.auto_save = enabled
        @has_unsaved_changes = true
        @on_setting_changed.try(&.call("auto_save", enabled.to_s))
      end

      # Sets difficulty level
      def set_difficulty(difficulty : String)
        return unless @available_difficulties.includes?(difficulty)
        return if @config.difficulty == difficulty

        @config.difficulty = difficulty
        @has_unsaved_changes = true
        @on_setting_changed.try(&.call("difficulty", difficulty))
      end

      # Sets language
      def set_language(language : String)
        return unless @available_languages.includes?(language)
        return if @config.language == language

        @config.language = language
        @has_unsaved_changes = true
        @on_setting_changed.try(&.call("language", language))
      end

      # Gets configuration value by key
      def get_setting(key : String) : String
        case key
        when "resolution"    then @config.resolution.name
        when "fullscreen"    then @config.fullscreen.to_s
        when "vsync"         then @config.vsync.to_s
        when "master_volume" then @config.master_volume.to_s
        when "music_volume"  then @config.music_volume.to_s
        when "sfx_volume"    then @config.sfx_volume.to_s
        when "voice_volume"  then @config.voice_volume.to_s
        when "text_speed"    then @config.text_speed.to_s
        when "auto_save"     then @config.auto_save.to_s
        when "difficulty"    then @config.difficulty
        when "language"      then @config.language
        when "debug_mode"    then @config.debug_mode.to_s
        else                      ""
        end
      end

      # Resets to default configuration
      def reset_to_defaults
        @config = ConfigData.new
        @has_unsaved_changes = true
      end

      # Resets specific category to defaults
      def reset_category_to_defaults(category : ConfigCategory)
        case category
        when ConfigCategory::Display
          @config.resolution = Resolution.new(1024, 768)
          @config.fullscreen = false
          @config.vsync = true
        when ConfigCategory::Audio
          @config.master_volume = 1.0
          @config.music_volume = 0.8
          @config.sfx_volume = 1.0
          @config.voice_volume = 1.0
        when ConfigCategory::Gameplay
          @config.text_speed = 1.0
          @config.auto_save = true
          @config.difficulty = "normal"
        when ConfigCategory::Controls
          @config.mouse_sensitivity = 1.0
          @config.keyboard_navigation = true
          @config.gamepad_enabled = false
        when ConfigCategory::Advanced
          @config.debug_mode = false
          @config.performance_mode = false
          @config.language = "en"
        end

        @has_unsaved_changes = true
      end

      # Gets configuration summary for display
      def get_config_summary : Hash(String, String)
        {
          "Resolution"    => @config.resolution.name,
          "Fullscreen"    => @config.fullscreen ? "Yes" : "No",
          "Master Volume" => "#{(@config.master_volume * 100).to_i}%",
          "Music Volume"  => "#{(@config.music_volume * 100).to_i}%",
          "Text Speed"    => "#{(@config.text_speed * 100).to_i}%",
          "Difficulty"    => @config.difficulty.capitalize,
          "Language"      => @config.language.upcase,
          "Auto Save"     => @config.auto_save ? "Enabled" : "Disabled",
        }
      end

      # Validates current configuration
      def validate_configuration : Array(String)
        issues = [] of String

        # Validate resolution
        if @config.resolution.width <= 0 || @config.resolution.height <= 0
          issues << "Invalid resolution dimensions"
        end

        # Validate volumes
        unless (0.0..1.0).includes?(@config.master_volume)
          issues << "Master volume out of range"
        end

        unless (0.0..1.0).includes?(@config.music_volume)
          issues << "Music volume out of range"
        end

        # Validate difficulty
        unless @available_difficulties.includes?(@config.difficulty)
          issues << "Invalid difficulty setting"
        end

        # Validate language
        unless @available_languages.includes?(@config.language)
          issues << "Invalid language setting"
        end

        issues
      end

      # Sets up default resolution options
      private def setup_default_resolutions
        @available_resolutions = [
          Resolution.new(800, 600, "800x600"),
          Resolution.new(1024, 768, "1024x768"),
          Resolution.new(1280, 720, "1280x720 (HD)"),
          Resolution.new(1280, 1024, "1280x1024"),
          Resolution.new(1600, 900, "1600x900"),
          Resolution.new(1920, 1080, "1920x1080 (Full HD)"),
          Resolution.new(2560, 1440, "2560x1440 (2K)"),
          Resolution.new(3840, 2160, "3840x2160 (4K)"),
        ]
      end

      # Loads display settings from hash
      private def load_display_settings(display : Hash(String, JSON::Any))
        if width = display["resolution_width"]?.try(&.as_i)
          if height = display["resolution_height"]?.try(&.as_i)
            @config.resolution = Resolution.new(width, height)
          end
        end

        if fullscreen = display["fullscreen"]?.try(&.as_bool)
          @config.fullscreen = fullscreen
        end

        if vsync = display["vsync"]?.try(&.as_bool)
          @config.vsync = vsync
        end

        if scaling = display["scaling_mode"]?.try(&.as_s)
          @config.scaling_mode = scaling
        end
      end

      # Loads audio settings from hash
      private def load_audio_settings(audio : Hash(String, JSON::Any))
        if master = audio["master_volume"]?.try(&.as_f)
          @config.master_volume = master.to_f32
        end

        if music = audio["music_volume"]?.try(&.as_f)
          @config.music_volume = music.to_f32
        end

        if sfx = audio["sfx_volume"]?.try(&.as_f)
          @config.sfx_volume = sfx.to_f32
        end

        if voice = audio["voice_volume"]?.try(&.as_f)
          @config.voice_volume = voice.to_f32
        end
      end

      # Loads gameplay settings from hash
      private def load_gameplay_settings(gameplay : Hash(String, JSON::Any))
        if speed = gameplay["text_speed"]?.try(&.as_f)
          @config.text_speed = speed.to_f32
        end

        if auto_save = gameplay["auto_save"]?.try(&.as_bool)
          @config.auto_save = auto_save
        end

        if interval = gameplay["auto_save_interval"]?.try(&.as_i)
          @config.auto_save_interval = interval
        end

        if difficulty = gameplay["difficulty"]?.try(&.as_s)
          @config.difficulty = difficulty
        end
      end

      # Loads control settings from hash
      private def load_control_settings(controls : Hash(String, JSON::Any))
        if sensitivity = controls["mouse_sensitivity"]?.try(&.as_f)
          @config.mouse_sensitivity = sensitivity.to_f32
        end

        if keyboard = controls["keyboard_navigation"]?.try(&.as_bool)
          @config.keyboard_navigation = keyboard
        end

        if gamepad = controls["gamepad_enabled"]?.try(&.as_bool)
          @config.gamepad_enabled = gamepad
        end
      end

      # Loads advanced settings from hash
      private def load_advanced_settings(advanced : Hash(String, JSON::Any))
        if debug = advanced["debug_mode"]?.try(&.as_bool)
          @config.debug_mode = debug
        end

        if performance = advanced["performance_mode"]?.try(&.as_bool)
          @config.performance_mode = performance
        end

        if language = advanced["language"]?.try(&.as_s)
          @config.language = language
        end
      end
    end
  end
end
