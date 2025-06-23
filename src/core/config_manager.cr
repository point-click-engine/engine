# Configuration management system for the Point & Click Engine

require "yaml"
require "./error_handling"
require "./interfaces"

module PointClickEngine
  module Core
    class ConfigManager
      include ErrorHelpers
      include IConfigManager

      @config_file : String
      @config_data : Hash(String, String) = {} of String => String

      def initialize(@config_file : String)
        ErrorLogger.info("ConfigManager initialized")
      end

      def get(key : String, default_value : String? = nil) : String?
        @config_data[key]? || default_value
      end

      def set(key : String, value : String)
        @config_data[key] = value
      end

      def has_key?(key : String) : Bool
        @config_data.has_key?(key)
      end

      def save_config : Result(Nil, ConfigError)
        begin
          File.write(@config_file, @config_data.to_yaml)
          Result.success(nil)
        rescue ex
          Result.failure(ConfigError.new("Failed to save config: #{ex.message}", @config_file))
        end
      end

      def load_config : Result(Nil, ConfigError)
        begin
          if File.exists?(@config_file)
            yaml_content = File.read(@config_file)
            @config_data = Hash(String, String).from_yaml(yaml_content)
          end
          Result.success(nil)
        rescue ex
          Result.failure(ConfigError.new("Failed to load config: #{ex.message}", @config_file))
        end
      end
    end
  end
end
