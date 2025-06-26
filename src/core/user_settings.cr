require "yaml"

module PointClickEngine
  module Core
    # User-modifiable settings that are stored separately from game configuration
    class UserSettings
      include YAML::Serializable

      class AudioSettings
        include YAML::Serializable
        property master_volume : Float32 = 80.0
        property music_volume : Float32 = 70.0
        property sfx_volume : Float32 = 90.0

        def initialize(@master_volume = 80.0_f32, @music_volume = 70.0_f32, @sfx_volume = 90.0_f32)
        end
      end

      class DisplaySettings
        include YAML::Serializable
        property fullscreen : Bool = false
        property vsync : Bool = true
        property show_fps : Bool = false

        def initialize(@fullscreen = false, @vsync = true, @show_fps = false)
        end
      end

      class GameplaySettings
        include YAML::Serializable
        property debug_mode : Bool = false
        property auto_save_interval : Int32 = 300 # seconds
        property text_speed : Float32 = 1.0

        def initialize(@debug_mode = false, @auto_save_interval = 300, @text_speed = 1.0_f32)
        end
      end

      property audio : AudioSettings = AudioSettings.new
      property display : DisplaySettings = DisplaySettings.new
      property gameplay : GameplaySettings = GameplaySettings.new

      def initialize(@audio = AudioSettings.new, @display = DisplaySettings.new, @gameplay = GameplaySettings.new)
      end

      # Load user settings from file, create default if not exists
      def self.load(settings_path : String = "user_settings.yaml") : UserSettings
        if File.exists?(settings_path)
          begin
            yaml_content = File.read(settings_path)
            from_yaml(yaml_content)
          rescue ex
            puts "Warning: Failed to load user settings from #{settings_path}: #{ex.message}"
            puts "Using default settings instead."
            UserSettings.new
          end
        else
          # Create default settings file
          settings = UserSettings.new
          settings.save(settings_path)
          settings
        end
      end

      # Save user settings to file
      def save(settings_path : String = "user_settings.yaml")
        begin
          File.write(settings_path, to_yaml)
        rescue ex
          puts "Warning: Failed to save user settings to #{settings_path}: #{ex.message}"
        end
      end

      # Validate user settings and return errors
      def validate : Array(String)
        errors = [] of String

        # Validate audio volumes
        if audio.master_volume < 0 || audio.master_volume > 100
          errors << "Audio master_volume must be between 0 and 100 (got #{audio.master_volume})"
        end
        if audio.music_volume < 0 || audio.music_volume > 100
          errors << "Audio music_volume must be between 0 and 100 (got #{audio.music_volume})"
        end
        if audio.sfx_volume < 0 || audio.sfx_volume > 100
          errors << "Audio sfx_volume must be between 0 and 100 (got #{audio.sfx_volume})"
        end

        # Validate gameplay settings
        if gameplay.auto_save_interval < 0
          errors << "Auto-save interval cannot be negative"
        end
        if gameplay.text_speed <= 0
          errors << "Text speed must be positive"
        end

        errors
      end

      # Apply settings to the engine
      def apply_to_engine(engine : Engine)
        # Apply audio settings
        if audio_manager = engine.system_manager.audio_manager
          audio_manager.master_volume = (audio.master_volume / 100.0).to_f32
          audio_manager.music_volume = (audio.music_volume / 100.0).to_f32
          audio_manager.sfx_volume = (audio.sfx_volume / 100.0).to_f32
        end

        # Apply display settings
        engine.show_fps = display.show_fps
        # Note: fullscreen and vsync would need to be applied differently depending on the graphics library

        # Apply gameplay settings
        Engine.debug_mode = gameplay.debug_mode
        if gameplay.auto_save_interval > 0
          engine.enable_auto_save(gameplay.auto_save_interval.to_f32)
        end
      end
    end
  end
end
