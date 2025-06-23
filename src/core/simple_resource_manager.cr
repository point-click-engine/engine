# Simplified Resource Manager for Phase 2 refactoring
#
# A basic resource manager that provides essential functionality
# without complex error handling patterns that cause compilation issues.

require "./game_constants"

module PointClickEngine
  module Core
    # Simple resource manager with basic functionality
    class SimpleResourceManager
      include GameConstants

      # Resource caches
      @textures : Hash(String, Raylib::Texture2D) = {} of String => Raylib::Texture2D
      @sounds : Hash(String, Raylib::Sound) = {} of String => Raylib::Sound
      @music : Hash(String, Raylib::Music) = {} of String => Raylib::Music

      # Asset search paths
      @asset_paths : Array(String) = ["assets/", "resources/", "./"]

      def initialize
        puts "SimpleResourceManager initialized"
      end

      # Texture management

      def load_texture(path : String) : Raylib::Texture2D?
        # Return cached texture if it exists
        return @textures[path] if @textures.has_key?(path)

        # Try to find the file
        full_path = resolve_asset_path(path)
        return nil unless full_path

        begin
          texture = RL.load_texture(full_path)
          @textures[path] = texture
          puts "Texture loaded: #{path}"
          texture
        rescue ex
          puts "Failed to load texture: #{path} - #{ex.message}"
          nil
        end
      end

      def get_texture(path : String) : Raylib::Texture2D?
        @textures[path]?
      end

      def unload_texture(path : String)
        if texture = @textures[path]?
          RL.unload_texture(texture)
          @textures.delete(path)
          puts "Texture unloaded: #{path}"
        end
      end

      # Sound management

      def load_sound(path : String) : Raylib::Sound?
        return @sounds[path] if @sounds.has_key?(path)

        full_path = resolve_asset_path(path)
        return nil unless full_path

        begin
          sound = RL.load_sound(full_path)
          @sounds[path] = sound
          puts "Sound loaded: #{path}"
          sound
        rescue ex
          puts "Failed to load sound: #{path} - #{ex.message}"
          nil
        end
      end

      def get_sound(path : String) : Raylib::Sound?
        @sounds[path]?
      end

      def unload_sound(path : String)
        if sound = @sounds[path]?
          RL.unload_sound(sound)
          @sounds.delete(path)
          puts "Sound unloaded: #{path}"
        end
      end

      # Music management

      def load_music(path : String) : Raylib::Music?
        return @music[path] if @music.has_key?(path)

        full_path = resolve_asset_path(path)
        return nil unless full_path

        begin
          music = RL.load_music_stream(full_path)
          @music[path] = music
          puts "Music loaded: #{path}"
          music
        rescue ex
          puts "Failed to load music: #{path} - #{ex.message}"
          nil
        end
      end

      def get_music(path : String) : Raylib::Music?
        @music[path]?
      end

      def unload_music(path : String)
        if music = @music[path]?
          RL.unload_music_stream(music)
          @music.delete(path)
          puts "Music unloaded: #{path}"
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
        @textures.each_value { |texture| RL.unload_texture(texture) }
        @textures.clear

        @sounds.each_value { |sound| RL.unload_sound(sound) }
        @sounds.clear

        @music.each_value { |music| RL.unload_music_stream(music) }
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
    end
  end
end
