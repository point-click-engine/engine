require "./asset_manager"
require "../graphics"
require "../audio"

module PointClickEngine
  module AssetLoader
    extend self

    def load_texture(path : String) : RL::Texture2D
      if bytes = AssetManager.read_bytes(path)
        # Create a temporary file to load texture from
        # Raylib doesn't support loading from memory directly for all formats
        temp_path = File.tempname("texture", File.extname(path))
        begin
          File.write(temp_path, bytes)
          RL.load_texture(temp_path)
        ensure
          File.delete(temp_path) if File.exists?(temp_path)
        end
      else
        # Fall back to direct loading
        RL.load_texture(path)
      end
    end

    def load_sound(path : String) : RAudio::Sound
      if bytes = AssetManager.read_bytes(path)
        temp_path = File.tempname("sound", File.extname(path))
        begin
          File.write(temp_path, bytes)
          RAudio.load_sound(temp_path)
        ensure
          File.delete(temp_path) if File.exists?(temp_path)
        end
      else
        RAudio.load_sound(path)
      end
    end

    def load_music_stream(path : String) : RAudio::Music
      if bytes = AssetManager.read_bytes(path)
        temp_path = File.tempname("music", File.extname(path))
        begin
          File.write(temp_path, bytes)
          RAudio.load_music_stream(temp_path)
        ensure
          File.delete(temp_path) if File.exists?(temp_path)
        end
      else
        RAudio.load_music_stream(path)
      end
    end

    def read_script(path : String) : String
      AssetManager.read_file(path)
    rescue AssetManager::AssetNotFoundError
      # Fall back to direct file reading
      File.read(path)
    end

    def read_yaml(path : String) : String
      AssetManager.read_file(path)
    rescue AssetManager::AssetNotFoundError
      # Fall back to direct file reading
      File.read(path)
    end

    def exists?(path : String) : Bool
      AssetManager.exists?(path)
    end
  end
end
