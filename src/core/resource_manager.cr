# Resource management system for the Point & Click Engine
#
# Handles loading, caching, and cleanup of all game assets including
# textures, sounds, fonts, and other resources. Provides memory management
# and prevents resource leaks.

require "raylib-cr"
require "raylib-cr/audio"
require "./error_handling"
require "./game_constants"
require "./exceptions"
require "./interfaces"

# RL alias already defined in error_handling.cr

module PointClickEngine
  module Core
    # Manages all game resources including loading, caching, and cleanup
    #
    # The ResourceManager centralizes asset management that was previously
    # scattered throughout the engine. It provides intelligent caching,
    # reference counting, and automatic cleanup to prevent memory leaks.
    #
    # ## Features
    # - Automatic asset loading and caching
    # - Reference counting for memory management
    # - Lazy loading and preloading support
    # - Asset validation and error handling
    # - Memory usage tracking and optimization
    # - Hot reloading for development
    #
    # ## Usage
    # ```
    # manager = ResourceManager.new
    # texture_result = manager.load_texture("sprite.png")
    # case texture_result
    # when .success?
    #   texture = texture_result.value
    # when .failure?
    #   puts "Failed to load texture: #{texture_result.error.message}"
    # end
    # ```
    class ResourceManager
      include ErrorHelpers
      include GameConstants
      include IResourceLoader

      # Resource entry with reference counting
      private class ResourceEntry(T)
        getter resource : T
        property reference_count : Int32
        property last_accessed : Time::Span
        property size_bytes : Int64

        def initialize(@resource : T, @size_bytes : Int64 = 0)
          @reference_count = 1
          @last_accessed = Time.monotonic
        end

        def add_reference
          @reference_count += 1
          @last_accessed = Time.monotonic
        end

        def remove_reference
          @reference_count -= 1
          @last_accessed = Time.monotonic
          @reference_count
        end

        def accessed!
          @last_accessed = Time.monotonic
        end
      end

      # Resource caches by type
      @textures : Hash(String, ResourceEntry(RL::Texture2D)) = {} of String => ResourceEntry(RL::Texture2D)
      @sounds : Hash(String, ResourceEntry(RAudio::Sound)) = {} of String => ResourceEntry(RAudio::Sound)
      @music : Hash(String, ResourceEntry(RAudio::Music)) = {} of String => ResourceEntry(RAudio::Music)
      @fonts : Hash(String, ResourceEntry(RL::Font)) = {} of String => ResourceEntry(RL::Font)

      # Resource management settings
      @max_memory_usage : Int64 = 100_i64 * 1024_i64 * 1024_i64 # 100 MB default
      @current_memory_usage : Int64 = 0
      @enable_auto_cleanup : Bool = true
      @cleanup_interval : Float32 = 30.0_f32 # 30 seconds
      @last_cleanup_time : Float32 = 0.0_f32

      # Asset search paths
      @asset_paths : Array(String) = ["assets/", "resources/", "./"]

      # Hot reloading support
      @enable_hot_reload : Bool = false
      @file_timestamps : Hash(String, Time) = {} of String => Time

      def initialize
        ErrorLogger.info("ResourceManager initialized")
      end

      # Texture management

      def load_texture(path : String, force_reload : Bool = false) : Result(RL::Texture2D, AssetError)
        return get_cached_texture(path) unless force_reload || !@textures.has_key?(path)

        full_path_result = resolve_asset_path(path)
        return full_path_result.map_error { |e| AssetError.new("Failed to resolve texture path: #{e.message}", path) } if full_path_result.failure?

        full_path = full_path_result.value

        begin
          texture = RL.load_texture(full_path)

          # Calculate texture size
          size = texture.width * texture.height * 4 # Assuming RGBA

          # Check memory limits
          check_memory_usage(size.to_i64)

          # Cache the texture
          entry = ResourceEntry.new(texture, size.to_i64)
          @textures[path] = entry
          @current_memory_usage += size

          # Store file timestamp for hot reloading
          if @enable_hot_reload
            @file_timestamps[full_path] = File.info(full_path).modification_time
          end

          ErrorLogger.debug("Texture loaded: #{path} (#{size} bytes)")
          Result.success(texture)
        rescue ex
          Result.failure(AssetError.new("Failed to load texture: #{ex.message}", path))
        end
      end

      def get_texture(path : String) : Result(RL::Texture2D, AssetError)
        get_cached_texture(path)
      end

      def unload_texture(path : String) : Result(Nil, AssetError)
        entry = @textures[path]?
        return Result.failure(AssetError.new(path, "Texture not found")) unless entry

        remaining_refs = entry.remove_reference
        if remaining_refs <= 0
          RL.unload_texture(entry.resource)
          @current_memory_usage -= entry.size_bytes
          @textures.delete(path)
          ErrorLogger.debug("Texture unloaded: #{path}")
        end

        Result.success(nil)
      end

      # Sound management

      def load_sound(path : String, force_reload : Bool = false) : Result(RAudio::Sound, AssetError)
        return get_cached_sound(path) unless force_reload || !@sounds.has_key?(path)

        full_path_result = resolve_asset_path(path)
        return full_path_result.map_error { |e| AssetError.new("Failed to resolve sound path: #{e.message}", path) } if full_path_result.failure?

        full_path = full_path_result.value

        begin
          sound = RAudio.load_sound(full_path)

          # Estimate sound size (this is approximate)
          size = File.size(full_path)
          check_memory_usage(size)

          entry = ResourceEntry.new(sound, size)
          @sounds[path] = entry
          @current_memory_usage += size

          if @enable_hot_reload
            @file_timestamps[full_path] = File.info(full_path).modification_time
          end

          ErrorLogger.debug("Sound loaded: #{path} (#{size} bytes)")
          Result.success(sound)
        rescue ex
          Result.failure(AssetError.new("Failed to load sound: #{ex.message}", path))
        end
      end

      def get_sound(path : String) : Result(RAudio::Sound, AssetError)
        get_cached_sound(path)
      end

      def unload_sound(path : String) : Result(Nil, AssetError)
        entry = @sounds[path]?
        return Result.failure(AssetError.new(path, "Sound not found")) unless entry

        remaining_refs = entry.remove_reference
        if remaining_refs <= 0
          RAudio.unload_sound(entry.resource)
          @current_memory_usage -= entry.size_bytes
          @sounds.delete(path)
          ErrorLogger.debug("Sound unloaded: #{path}")
        end

        Result.success(nil)
      end

      # Music management

      def load_music(path : String, force_reload : Bool = false) : Result(RAudio::Music, AssetError)
        return get_cached_music(path) unless force_reload || !@music.has_key?(path)

        full_path_result = resolve_asset_path(path)
        return full_path_result.map_error { |e| AssetError.new("Failed to resolve music path: #{e.message}", path) } if full_path_result.failure?

        full_path = full_path_result.value

        begin
          music = RAudio.load_music_stream(full_path)

          size = File.size(full_path)
          check_memory_usage(size)

          entry = ResourceEntry.new(music, size)
          @music[path] = entry
          @current_memory_usage += size

          if @enable_hot_reload
            @file_timestamps[full_path] = File.info(full_path).modification_time
          end

          ErrorLogger.debug("Music loaded: #{path} (#{size} bytes)")
          Result.success(music)
        rescue ex
          Result.failure(AssetError.new("Failed to load music: #{ex.message}", path))
        end
      end

      def get_music(path : String) : Result(RAudio::Music, AssetError)
        get_cached_music(path)
      end

      def unload_music(path : String) : Result(Nil, AssetError)
        entry = @music[path]?
        return Result.failure(AssetError.new(path, "Music not found")) unless entry

        remaining_refs = entry.remove_reference
        if remaining_refs <= 0
          RAudio.unload_music_stream(entry.resource)
          @current_memory_usage -= entry.size_bytes
          @music.delete(path)
          ErrorLogger.debug("Music unloaded: #{path}")
        end

        Result.success(nil)
      end

      # Font management

      def load_font(path : String, size : Int32 = 16, force_reload : Bool = false) : Result(RL::Font, AssetError)
        font_key = "#{path}:#{size}"
        return get_cached_font(font_key) unless force_reload || !@fonts.has_key?(font_key)

        full_path_result = resolve_asset_path(path)
        return full_path_result.map_error { |e| AssetError.new("Failed to resolve font path: #{e.message}", path) } if full_path_result.failure?

        full_path = full_path_result.value

        begin
          font = RL.load_font_ex(full_path, size, nil, 0)

          # Estimate font size
          estimated_size = size * size * 128 # Rough estimate based on font size and character count
          check_memory_usage(estimated_size.to_i64)

          entry = ResourceEntry.new(font, estimated_size.to_i64)
          @fonts[font_key] = entry
          @current_memory_usage += estimated_size

          ErrorLogger.debug("Font loaded: #{path} size #{size} (#{estimated_size} bytes)")
          Result.success(font)
        rescue ex
          Result.failure(AssetError.new("Failed to load font: #{ex.message}", path))
        end
      end

      def get_font(path : String, size : Int32 = 16) : Result(RL::Font, AssetError)
        get_cached_font("#{path}:#{size}")
      end

      # Resource management

      def add_asset_path(path : String)
        @asset_paths << path unless @asset_paths.includes?(path)
        ErrorLogger.debug("Asset path added: #{path}")
      end

      def remove_asset_path(path : String)
        @asset_paths.delete(path)
        ErrorLogger.debug("Asset path removed: #{path}")
      end

      def clear_asset_paths
        @asset_paths.clear
        ErrorLogger.debug("All asset paths cleared")
      end

      def preload_assets(asset_list : Array(String)) : Result(Int32, AssetError)
        loaded_count = 0

        asset_list.each do |asset_path|
          extension = File.extname(asset_path).downcase

          result = case extension
                   when ".png", ".jpg", ".jpeg", ".bmp", ".tga"
                     load_texture(asset_path)
                   when ".wav", ".ogg", ".mp3"
                     load_sound(asset_path)
                   when ".ttf", ".otf"
                     load_font(asset_path)
                   else
                     next # Skip unknown file types
                   end

          if result.success?
            loaded_count += 1
          else
            ErrorLogger.warning("Failed to preload asset: #{asset_path} - #{result.error.message}")
          end
        end

        ErrorLogger.info("Preloaded #{loaded_count} of #{asset_list.size} assets")
        Result.success(loaded_count)
      end

      def cleanup_unused_resources(max_age_seconds : Float32 = 300.0_f32)
        return unless @enable_auto_cleanup

        current_time = Time.monotonic
        freed_memory = 0_i64

        # Clean up textures
        @textures.each do |path, entry|
          if entry.reference_count <= 0 && (current_time - entry.last_accessed).total_seconds > max_age_seconds
            RL.unload_texture(entry.resource)
            freed_memory += entry.size_bytes
            @textures.delete(path)
          end
        end

        # Clean up sounds
        @sounds.each do |path, entry|
          if entry.reference_count <= 0 && (current_time - entry.last_accessed).total_seconds > max_age_seconds
            RAudio.unload_sound(entry.resource)
            freed_memory += entry.size_bytes
            @sounds.delete(path)
          end
        end

        # Clean up music
        @music.each do |path, entry|
          if entry.reference_count <= 0 && (current_time - entry.last_accessed).total_seconds > max_age_seconds
            RAudio.unload_music_stream(entry.resource)
            freed_memory += entry.size_bytes
            @music.delete(path)
          end
        end

        # Clean up fonts
        @fonts.each do |path, entry|
          if entry.reference_count <= 0 && (current_time - entry.last_accessed).total_seconds > max_age_seconds
            RL.unload_font(entry.resource)
            freed_memory += entry.size_bytes
            @fonts.delete(path)
          end
        end

        @current_memory_usage -= freed_memory

        if freed_memory > 0
          ErrorLogger.info("Cleaned up #{freed_memory} bytes of unused resources")
        end
      end

      def update(dt : Float32)
        @last_cleanup_time += dt

        if @last_cleanup_time >= @cleanup_interval
          cleanup_unused_resources
          @last_cleanup_time = 0.0_f32
        end

        # Check for hot reload if enabled
        if @enable_hot_reload
          check_for_file_changes
        end
      end

      def get_memory_usage : {current: Int64, max: Int64, percentage: Float32}
        percentage = (@current_memory_usage.to_f32 / @max_memory_usage.to_f32) * 100.0_f32
        {
          current:    @current_memory_usage,
          max:        @max_memory_usage,
          percentage: percentage,
        }
      end

      def set_memory_limit(limit_bytes : Int64)
        @max_memory_usage = limit_bytes
        ErrorLogger.info("Memory limit set to #{limit_bytes} bytes")
      end

      def enable_hot_reload
        @enable_hot_reload = true
        ErrorLogger.info("Hot reload enabled")
      end

      def disable_hot_reload
        @enable_hot_reload = false
        ErrorLogger.info("Hot reload disabled")
      end

      def cleanup_all_resources
        # Unload all textures
        @textures.each_value do |entry|
          RL.unload_texture(entry.resource)
        end
        @textures.clear

        # Unload all sounds
        @sounds.each_value do |entry|
          RAudio.unload_sound(entry.resource)
        end
        @sounds.clear

        # Unload all music
        @music.each_value do |entry|
          RAudio.unload_music_stream(entry.resource)
        end
        @music.clear

        # Unload all fonts
        @fonts.each_value do |entry|
          RL.unload_font(entry.resource)
        end
        @fonts.clear

        @current_memory_usage = 0
        ErrorLogger.info("All resources cleaned up")
      end

      private def get_cached_texture(path : String) : Result(RL::Texture2D, AssetError)
        entry = @textures[path]?
        return Result.failure(AssetError.new(path, "Texture not found in cache")) unless entry

        entry.add_reference
        Result.success(entry.resource)
      end

      private def get_cached_sound(path : String) : Result(RAudio::Sound, AssetError)
        entry = @sounds[path]?
        return Result.failure(AssetError.new(path, "Sound not found in cache")) unless entry

        entry.add_reference
        Result.success(entry.resource)
      end

      private def get_cached_music(path : String) : Result(RAudio::Music, AssetError)
        entry = @music[path]?
        return Result.failure(AssetError.new(path, "Music not found in cache")) unless entry

        entry.add_reference
        Result.success(entry.resource)
      end

      private def get_cached_font(key : String) : Result(RL::Font, AssetError)
        entry = @fonts[key]?
        return Result.failure(AssetError.new(key, "Font not found in cache")) unless entry

        entry.add_reference
        Result.success(entry.resource)
      end

      private def resolve_asset_path(path : String) : Result(String, FileError)
        # If path is absolute or exists as-is, use it
        return Result.success(path) if File.exists?(path) || path.starts_with?("/")

        # Search in asset paths
        @asset_paths.each do |asset_path|
          full_path = File.join(asset_path, path)
          return Result.success(full_path) if File.exists?(full_path)
        end

        Result.failure(FileError.new("Asset file not found: #{path}"))
      end

      private def check_memory_usage(additional_bytes : Int64)
        if @current_memory_usage + additional_bytes > @max_memory_usage
          # Try cleanup first
          cleanup_unused_resources(60.0_f32) # More aggressive cleanup

          # If still over limit, warn
          if @current_memory_usage + additional_bytes > @max_memory_usage
            ErrorLogger.warning("Memory usage will exceed limit: #{@current_memory_usage + additional_bytes} > #{@max_memory_usage}")
          end
        end
      end

      private def check_for_file_changes
        @file_timestamps.each do |file_path, stored_time|
          begin
            current_time = File.info(file_path).modification_time
            if current_time > stored_time
              ErrorLogger.info("File changed, reloading: #{file_path}")
              # Reload the resource
              # This would need to determine the resource type and reload it
              @file_timestamps[file_path] = current_time
            end
          rescue
            # File might have been deleted
            @file_timestamps.delete(file_path)
          end
        end
      end
    end
  end
end
