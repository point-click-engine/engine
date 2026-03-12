require "./asset_manager"
require "../graphics"
require "../audio"

module PointClickEngine
  module AssetLoader
    extend self

    # Load a resource via temp file if from archive, otherwise directly
    # Raylib doesn't support loading from memory for all formats
    private def with_temp_file(path : String, prefix : String, &)
      if bytes = AssetManager.read_bytes(path)
        temp_path = File.tempname(prefix, File.extname(path))
        begin
          File.write(temp_path, bytes)
          yield temp_path
        ensure
          File.delete(temp_path) if File.exists?(temp_path)
        end
      else
        yield path
      end
    end

    def load_texture(path : String) : RL::Texture2D
      with_temp_file(path, "texture") do |load_path|
        RL.load_texture(load_path)
      end
    end

    def load_sound(path : String) : RAudio::Sound
      with_temp_file(path, "sound") do |load_path|
        RAudio.load_sound(load_path)
      end
    end

    def load_music_stream(path : String) : RAudio::Music
      with_temp_file(path, "music") do |load_path|
        RAudio.load_music_stream(load_path)
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
