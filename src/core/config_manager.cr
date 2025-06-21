require "yaml"

module PointClickEngine
  module Core
    class ConfigManager
      property settings : Hash(String, String) = {} of String => String
      property config_file : String = "config.yaml"

      def initialize
        load_defaults
      end

      def initialize(@config_file : String)
        load_defaults
        load_from_file
      end

      def get(key : String) : String?
        @settings[key]?
      end

      def get(key : String, default : String) : String
        @settings[key]? || default
      end

      def set(key : String, value : String)
        @settings[key] = value
      end

      def get_int(key : String, default : Int32 = 0) : Int32
        value = get(key)
        return default unless value
        value.to_i? || default
      end

      def get_float(key : String, default : Float32 = 0.0f32) : Float32
        value = get(key)
        return default unless value
        value.to_f32? || default
      end

      def get_bool(key : String, default : Bool = false) : Bool
        value = get(key)
        return default unless value
        case value.downcase
        when "true", "yes", "1", "on"
          true
        when "false", "no", "0", "off"
          false
        else
          default
        end
      end

      def save_to_file
        File.write(@config_file, @settings.to_yaml)
      rescue ex
        puts "Failed to save config: #{ex.message}"
      end

      def load_from_file
        return unless File.exists?(@config_file)

        yaml_content = File.read(@config_file)
        loaded = Hash(String, String).from_yaml(yaml_content)
        @settings.merge!(loaded)
      rescue ex
        puts "Failed to load config: #{ex.message}"
      end

      private def load_defaults
        # Game defaults
        @settings["game.version"] = "1.0.0"
        @settings["game.debug"] = "false"

        # Graphics defaults
        @settings["graphics.fullscreen"] = "false"
        @settings["graphics.vsync"] = "true"
        @settings["graphics.resolution.width"] = "1024"
        @settings["graphics.resolution.height"] = "768"

        # Audio defaults
        @settings["audio.master_volume"] = "1.0"
        @settings["audio.music_volume"] = "0.7"
        @settings["audio.sfx_volume"] = "0.8"
        @settings["audio.mute"] = "false"

        # Gameplay defaults
        @settings["gameplay.text_speed"] = "normal"
        @settings["gameplay.auto_save"] = "true"
        @settings["gameplay.language"] = "en"
      end
    end
  end
end
