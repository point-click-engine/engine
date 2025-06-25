# Simplified Resource Manager for Phase 2 refactoring
#
# A basic resource manager that provides essential functionality
# without complex error handling patterns that cause compilation issues.

require "raylib-cr"
require "raylib-cr/audio"
require "./game_constants"
require "./interfaces"
require "./error_handling"

module PointClickEngine
  module Core
    # Simple resource manager with basic functionality
    class SimpleResourceManager
      include GameConstants
      include IResourceLoader

      # Resource caches
      @textures : Hash(String, RL::Texture2D) = {} of String => RL::Texture2D
      @sounds : Hash(String, RAudio::Sound) = {} of String => RAudio::Sound
      @music : Hash(String, RAudio::Music) = {} of String => RAudio::Music

      # Asset search paths
      @asset_paths : Array(String) = ["assets/", "resources/", "./"]

      # Memory management
      @memory_limit : Int64 = 100_000_000_i64 # 100MB default
      @hot_reload_enabled : Bool = false
      @file_watchers : Hash(String, Time) = {} of String => Time

      def initialize
        puts "SimpleResourceManager initialized"
      end

      # Texture management

      def load_texture(path : String) : Result(Raylib::Texture2D, AssetError)
        # Validate path
        if path.strip.empty?
          return Result(Raylib::Texture2D, AssetError).failure(
            AssetError.new("Invalid path: empty or whitespace-only path", path)
          )
        end

        # Return cached texture if it exists
        if @textures.has_key?(path)
          return Result(Raylib::Texture2D, AssetError).success(@textures[path])
        end

        # Try to find the file
        full_path = resolve_asset_path(path)
        unless full_path
          return Result(Raylib::Texture2D, AssetError).failure(
            AssetError.new("Asset not found: #{path}", path)
          )
        end

        begin
          texture = RL.load_texture(full_path)
          @textures[path] = texture
          puts "Texture loaded: #{path}"
          Result(Raylib::Texture2D, AssetError).success(texture)
        rescue ex
          puts "Failed to load texture: #{path} - #{ex.message}"
          Result(Raylib::Texture2D, AssetError).failure(
            AssetError.new("Failed to load texture: #{ex.message}", path)
          )
        end
      end

      def get_texture(path : String) : RL::Texture2D?
        @textures[path]?
      end

      def unload_texture(path : String) : Result(Nil, AssetError)
        if texture = @textures[path]?
          # Only unload if texture is valid
          begin
            if texture.id > 0
              RL.unload_texture(texture)
            end
          rescue ex
            # Ignore unload errors during cleanup
            puts "Warning: Failed to unload texture #{path}: #{ex.message}"
          end
          @textures.delete(path)
          puts "Texture unloaded: #{path}"
          Result(Nil, AssetError).success(nil)
        else
          Result(Nil, AssetError).failure(
            AssetError.new("Texture not found: #{path}", path)
          )
        end
      end

      # Sound management

      def load_sound(path : String) : Result(RAudio::Sound, AssetError)
        # Validate path
        if path.strip.empty?
          return Result(RAudio::Sound, AssetError).failure(
            AssetError.new("Invalid path: empty or whitespace-only path", path)
          )
        end

        if @sounds.has_key?(path)
          return Result(RAudio::Sound, AssetError).success(@sounds[path])
        end

        full_path = resolve_asset_path(path)
        unless full_path
          return Result(RAudio::Sound, AssetError).failure(
            AssetError.new("Asset not found: #{path}", path)
          )
        end

        begin
          sound = RAudio.load_sound(full_path)
          @sounds[path] = sound
          puts "Sound loaded: #{path}"
          Result(RAudio::Sound, AssetError).success(sound)
        rescue ex
          puts "Failed to load sound: #{path} - #{ex.message}"
          Result(RAudio::Sound, AssetError).failure(
            AssetError.new("Failed to load sound: #{ex.message}", path)
          )
        end
      end

      def get_sound(path : String) : RAudio::Sound?
        @sounds[path]?
      end

      def unload_sound(path : String) : Result(Nil, AssetError)
        if sound = @sounds[path]?
          # Only unload if sound is valid
          begin
            if sound.frame_count > 0
              RAudio.unload_sound(sound)
            end
          rescue ex
            # Ignore unload errors during cleanup
            puts "Warning: Failed to unload sound #{path}: #{ex.message}"
          end
          @sounds.delete(path)
          puts "Sound unloaded: #{path}"
          Result(Nil, AssetError).success(nil)
        else
          Result(Nil, AssetError).failure(
            AssetError.new("Sound not found: #{path}", path)
          )
        end
      end

      # Music management

      def load_music(path : String) : Result(RAudio::Music, AssetError)
        # Validate path
        if path.strip.empty?
          return Result(RAudio::Music, AssetError).failure(
            AssetError.new("Invalid path: empty or whitespace-only path", path)
          )
        end

        if @music.has_key?(path)
          return Result(RAudio::Music, AssetError).success(@music[path])
        end

        full_path = resolve_asset_path(path)
        unless full_path
          return Result(RAudio::Music, AssetError).failure(
            AssetError.new("Asset not found: #{path}", path)
          )
        end

        begin
          music = RAudio.load_music_stream(full_path)
          @music[path] = music
          puts "Music loaded: #{path}"
          Result(RAudio::Music, AssetError).success(music)
        rescue ex
          puts "Failed to load music: #{path} - #{ex.message}"
          Result(RAudio::Music, AssetError).failure(
            AssetError.new("Failed to load music: #{ex.message}", path)
          )
        end
      end

      def get_music(path : String) : RAudio::Music?
        @music[path]?
      end

      def unload_music(path : String) : Result(Nil, AssetError)
        if music = @music[path]?
          # Only unload if music is valid
          begin
            if music.frame_count > 0
              RAudio.unload_music_stream(music)
            end
          rescue ex
            # Ignore unload errors during cleanup
            puts "Warning: Failed to unload music #{path}: #{ex.message}"
          end
          @music.delete(path)
          puts "Music unloaded: #{path}"
          Result(Nil, AssetError).success(nil)
        else
          Result(Nil, AssetError).failure(
            AssetError.new("Music not found: #{path}", path)
          )
        end
      end

      # Asset path management

      def add_asset_path(path : String)
        @asset_paths << path unless @asset_paths.includes?(path)
        puts "Asset path added: #{path}"
      end

      def clear_asset_paths
        @asset_paths.clear
        puts "All asset paths cleared"
      end

      # Cleanup

      def cleanup_all_resources
        # Safely unload textures
        @textures.each do |path, texture|
          begin
            # Check if texture is valid before unloading
            if texture.id > 0
              RL.unload_texture(texture)
            end
          rescue ex
            puts "Warning: Failed to unload texture #{path}: #{ex.message}"
          end
        end
        @textures.clear

        # Safely unload sounds
        @sounds.each do |path, sound|
          begin
            # Check if sound has valid data before unloading
            if sound.frame_count > 0
              RAudio.unload_sound(sound)
            end
          rescue ex
            puts "Warning: Failed to unload sound #{path}: #{ex.message}"
          end
        end
        @sounds.clear

        # Safely unload music
        @music.each do |path, music|
          begin
            # Check if music has valid data before unloading
            if music.frame_count > 0
              RAudio.unload_music_stream(music)
            end
          rescue ex
            puts "Warning: Failed to unload music #{path}: #{ex.message}"
          end
        end
        @music.clear

        puts "All resources cleaned up"
      end

      # Statistics

      def get_resource_count : {textures: Int32, sounds: Int32, music: Int32}
        {
          textures: @textures.size,
          sounds:   @sounds.size,
          music:    @music.size,
        }
      end

      def get_memory_usage : {current: Int64, max: Int64, percentage: Float32}
        # Simple memory tracking - return basic stats
        current = estimate_memory_usage
        percentage = (current.to_f32 / @memory_limit.to_f32) * 100.0_f32

        {
          current:    current,
          max:        @memory_limit,
          percentage: percentage,
        }
      end

      def set_memory_limit(limit : Int64)
        @memory_limit = limit
        puts "Memory limit set to #{limit / 1_048_576} MB"

        # Check if we're over the new limit
        current = estimate_memory_usage
        if current > limit
          puts "Warning: Current memory usage (#{current / 1_048_576} MB) exceeds new limit"
          cleanup_unused_resources
        end
      end

      def enable_hot_reload
        @hot_reload_enabled = true
        puts "Hot reload enabled"

        # Record modification times for loaded assets
        @textures.each_key do |path|
          if full_path = resolve_asset_path(path)
            @file_watchers[path] = File.info(full_path).modification_time
          end
        end
      end

      def disable_hot_reload
        @hot_reload_enabled = false
        @file_watchers.clear
        puts "Hot reload disabled"
      end

      def hot_reload_enabled? : Bool
        @hot_reload_enabled
      end

      def check_for_changes
        return unless @hot_reload_enabled

        changed_files = [] of String

        @file_watchers.each do |path, last_modified|
          if full_path = resolve_asset_path(path)
            begin
              current_time = File.info(full_path).modification_time
              if current_time > last_modified
                changed_files << path
                @file_watchers[path] = current_time
              end
            rescue
              # File might have been deleted
            end
          end
        end

        # Reload changed assets
        changed_files.each do |path|
          reload_asset(path)
        end
      end

      def cleanup_unused_resources(max_age_seconds : Float32 = 300.0_f32)
        # Simple cleanup - for now just report what we would do
        puts "Cleanup would remove resources older than #{max_age_seconds} seconds"
        # In a full implementation, this would check last access times
      end

      def load_font(path : String, size : Int32) : Result(Raylib::Font, AssetError)
        # For now, just use default font
        begin
          font = RL.get_font_default
          Result(Raylib::Font, AssetError).success(font)
        rescue ex
          Result(Raylib::Font, AssetError).failure(
            AssetError.new("Failed to load font: #{ex.message}", path)
          )
        end
      end

      def preload_assets(asset_list : Array(String)) : Int32
        success_count = 0

        asset_list.each do |asset_path|
          case File.extname(asset_path).downcase
          when ".png", ".jpg", ".jpeg", ".bmp", ".tga"
            success_count += 1 if load_texture(asset_path).success?
          when ".wav", ".flac"
            success_count += 1 if load_sound(asset_path).success?
          when ".ogg", ".mp3"
            success_count += 1 if load_music(asset_path).success?
          end
        end

        success_count
      end

      private def resolve_asset_path(path : String) : String?
        # If path exists as-is, use it
        return path if File.exists?(path)

        # Search in asset paths
        @asset_paths.each do |asset_path|
          full_path = File.join(asset_path, path)
          return full_path if File.exists?(full_path)
        end

        nil
      end

      private def estimate_memory_usage : Int64
        texture_memory = @textures.sum do |_, texture|
          # Estimate: width * height * 4 bytes (RGBA)
          texture.width.to_i64 * texture.height.to_i64 * 4_i64
        end

        # Rough estimates for audio
        sound_memory = @sounds.size.to_i64 * 100_000_i64  # ~100KB per sound effect
        music_memory = @music.size.to_i64 * 5_000_000_i64 # ~5MB per music track

        texture_memory + sound_memory + music_memory
      end

      private def reload_asset(path : String)
        puts "Reloading asset: #{path}"

        case File.extname(path).downcase
        when ".png", ".jpg", ".jpeg", ".bmp", ".tga"
          # Reload texture
          if @textures.has_key?(path)
            unload_texture(path)
            load_texture(path)
          end
        when ".wav", ".flac"
          # Reload sound
          if @sounds.has_key?(path)
            unload_sound(path)
            load_sound(path)
          end
        when ".ogg", ".mp3"
          # Reload music
          if @music.has_key?(path)
            unload_music(path)
            load_music(path)
          end
        end
      end
    end
  end
end
