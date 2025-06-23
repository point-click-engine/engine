# Error handling utilities and Result type pattern
#
# Provides standardized error handling patterns throughout the Point & Click Engine.
# Implements the Result type pattern for operations that can fail, improving
# error handling consistency and debugging capabilities.

require "raylib-cr"
require "raylib-cr/audio"
require "./exceptions"

alias RL = Raylib

module PointClickEngine
  module Core
    # Result type for operations that can succeed or fail
    #
    # This provides a type-safe way to handle operations that might fail
    # without relying on exceptions or nil returns. Inspired by Rust's
    # Result type and functional programming error handling patterns.
    #
    # ## Usage
    # ```
    # def load_texture(path : String) : Result(Texture, AssetError)
    #   if File.exists?(path)
    #     texture = RL.load_texture(path)
    #     Result(T, E).success(texture)
    #   else
    #     Result(T, E).failure(AssetError.new("File not found", path))
    #   end
    # end
    #
    # result = load_texture("sprite.png")
    # case result
    # when .success?
    #   texture = result.value
    #   # Use texture
    # when .failure?
    #   puts "Error: #{result.error.message}"
    # end
    # ```
    struct Result(T, E)
      # Create a successful result
      def self.success(value : T) : Result(T, E) forall T, E
        Result(T, E).new(value, nil, true)
      end

      # Create a failed result
      def self.failure(error : E) : Result(T, E) forall T, E
        Result(T, E).new(nil, error, false)
      end

      # Check if the result is successful
      def success? : Bool
        @success
      end

      # Check if the result is a failure
      def failure? : Bool
        !@success
      end

      # Get the success value (raises if failure)
      def value : T
        raise "Attempted to get value from failed result" unless @success
        @value.not_nil!
      end

      # Get the error (raises if success)
      def error : E
        raise "Attempted to get error from successful result" if @success
        @error.not_nil!
      end

      # Get the success value or a default
      def value_or(default : T) : T
        @success ? @value.not_nil! : default
      end

      # Transform the success value if present
      def map(&block : T -> U) : Result(U, E) forall U
        if @success
          Result(U, E).success(block.call(@value.not_nil!))
        else
          Result(U, E).failure(@error.not_nil!)
        end
      end

      # Transform the error if present
      def map_error(&block : E -> F) : Result(T, F) forall F
        if @success
          Result(T, F).success(@value.not_nil!)
        else
          Result(T, F).failure(block.call(@error.not_nil!))
        end
      end

      # Chain operations that return Results
      def and_then(&block : T -> Result(U, E)) : Result(U, E) forall U
        if @success
          block.call(@value.not_nil!)
        else
          Result(U, E).failure(@error.not_nil!)
        end
      end

      def initialize(@value : T?, @error : E?, @success : Bool)
      end
    end

    # Extended error classes that build on existing exceptions.cr classes

    # Input handling errors
    class InputError < LoadingError
      def initialize(message : String, filename : String? = nil)
        super("Input Error: #{message}", filename)
      end
    end

    # Rendering errors
    class RenderError < LoadingError
      def initialize(message : String, filename : String? = nil)
        super("Render Error: #{message}", filename)
      end
    end

    # Audio system errors
    class AudioError < LoadingError
      def initialize(message : String, filename : String? = nil)
        super("Audio Error: #{message}", filename)
      end
    end

    # File system errors
    class FileError < LoadingError
      def initialize(message : String, filename : String? = nil)
        super("File Error: #{message}", filename)
      end
    end

    # Utility methods for common error handling patterns
    module ErrorHelpers
      extend self

      # Safely execute a block that might raise an exception
      def safe_execute(error_class : E.class, message : String, &block : -> T) : Result(T, E) forall T, E
        begin
          value = block.call
          Result(T, E).success(value)
        rescue ex
          # Handle different error class constructors
          error = case error_class
                  when AssetError.class
                    error_class.new("#{message}: #{ex.message}", "unknown")
                  when FileError.class
                    error_class.new("#{message}: #{ex.message}")
                  else
                    error_class.new("#{message}: #{ex.message}")
                  end
          Result(T, E).failure(error)
        end
      end

      # Safely read a file
      def safe_file_read(path : String) : Result(String, FileError)
        safe_execute(FileError, "Failed to read file: #{path}") do
          File.read(path)
        end
      end

      # Safely write to a file
      def safe_file_write(path : String, content : String) : Result(Nil, FileError)
        safe_execute(FileError, "Failed to write file: #{path}") do
          File.write(path, content)
        end
      end

      # Validate that a file exists
      def validate_file_exists(path : String) : Result(String, FileError)
        if File.exists?(path)
          Result(String, FileError).success(path)
        else
          Result(String, FileError).failure(FileError.new("File not found: #{path}"))
        end
      end

      # Validate that a directory exists
      def validate_directory_exists(path : String) : Result(String, FileError)
        if Dir.exists?(path)
          Result(String, FileError).success(path)
        else
          Result(String, FileError).failure(FileError.new("Directory not found: #{path}"))
        end
      end

      # Create directory if it doesn't exist
      def ensure_directory_exists(path : String) : Result(String, FileError)
        begin
          Dir.mkdir_p(path) unless Dir.exists?(path)
          Result(String, FileError).success(path)
        rescue ex
          Result(String, FileError).failure(FileError.new("Failed to create directory: #{path}"))
        end
      end

      # Validate that a value is not nil
      def validate_not_nil(value : T?, error_message : String) : Result(T, ValidationError) forall T
        if value.nil?
          errors = [error_message]
          Result(T, ValidationError).failure(ValidationError.new(errors))
        else
          Result(T, ValidationError).success(value)
        end
      end

      # Validate that a string is not empty
      def validate_not_empty(value : String, field_name : String) : Result(String, ValidationError)
        if value.empty?
          errors = ["#{field_name} cannot be empty"]
          Result(String, ValidationError).failure(ValidationError.new(errors))
        else
          Result(String, ValidationError).success(value)
        end
      end

      # Validate numeric range
      def validate_range(value : T, min : T, max : T, field_name : String) : Result(T, ValidationError) forall T
        if value < min || value > max
          errors = ["#{field_name} must be between #{min} and #{max}, got #{value}"]
          Result(T, ValidationError).failure(ValidationError.new(errors))
        else
          Result(T, ValidationError).success(value)
        end
      end

      # Load asset with error handling
      def safe_load_texture(path : String) : Result(Raylib::Texture2D, AssetError)
        validate_file_exists(path).and_then do |valid_path|
          begin
            texture = RL.load_texture(valid_path)
            Result(Raylib::Texture2D, AssetError).success(texture)
          rescue ex
            Result(Raylib::Texture2D, AssetError).failure(AssetError.new("Failed to load texture: #{ex.message}", path))
          end
        end
      end

      # Load sound with error handling
      def safe_load_sound(path : String) : Result(RAudio::Sound, AssetError)
        validate_file_exists(path).and_then do |valid_path|
          begin
            sound = RAudio.load_sound(valid_path)
            Result(RAudio::Sound, AssetError).success(sound)
          rescue ex
            Result(RAudio::Sound, AssetError).failure(AssetError.new("Failed to load sound: #{ex.message}", path))
          end
        end
      end

      # Load music with error handling
      def safe_load_music(path : String) : Result(RAudio::Music, AssetError)
        validate_file_exists(path).and_then do |valid_path|
          begin
            music = RAudio.load_music_stream(valid_path)
            Result(RAudio::Music, AssetError).success(music)
          rescue ex
            Result(RAudio::Music, AssetError).failure(AssetError.new("Failed to load music: #{ex.message}", path))
          end
        end
      end
    end

    # Error logging utilities
    module ErrorLogger
      extend self

      @@log_level : LogLevel = LogLevel::Info
      @@log_file : File?

      enum LogLevel
        Debug   = 0
        Info    = 1
        Warning = 2
        Error   = 3
        Fatal   = 4
      end

      def set_log_level(level : LogLevel)
        @@log_level = level
      end

      def set_log_file(path : String)
        @@log_file.try(&.close)
        @@log_file = File.open(path, "a")
      rescue ex
        puts "Failed to open log file: #{ex.message}"
      end

      def debug(message : String)
        log(LogLevel::Debug, message)
      end

      def info(message : String)
        log(LogLevel::Info, message)
      end

      def warning(message : String)
        log(LogLevel::Warning, message)
      end

      def error(message : String)
        log(LogLevel::Error, message)
      end

      def error(error : LoadingError)
        log(LogLevel::Error, error.message || "Unknown error")
      end

      def fatal(message : String)
        log(LogLevel::Fatal, message)
      end

      private def log(level : LogLevel, message : String)
        return if level.value < @@log_level.value

        timestamp = Time.local.to_s("%Y-%m-%d %H:%M:%S")
        level_str = level.to_s.upcase.ljust(7)
        log_message = "[#{timestamp}] #{level_str} #{message}"

        puts log_message

        if log_file = @@log_file
          log_file.puts(log_message)
          log_file.flush
        end
      end

      def close
        @@log_file.try(&.close)
        @@log_file = nil
      end
    end
  end
end
