require "compress/zip"

module PointClickEngine
  class AssetManager
    class AssetNotFoundError < Exception; end

    alias AssetData = Bytes | String

    @archives : Hash(String, Compress::Zip::Reader) = {} of String => Compress::Zip::Reader
    @archive_data : Hash(String, Bytes) = {} of String => Bytes
    @cache : Hash(String, AssetData) = {} of String => AssetData

    def initialize
    end

    def mount_archive(path : String, mount_point : String = "/")
      file_data = File.read(path).to_slice
      @archive_data[mount_point] = file_data
      @archives[mount_point] = Compress::Zip::Reader.new(IO::Memory.new(file_data))
    end

    def unmount_archive(mount_point : String = "/")
      @archives.delete(mount_point)
      @archive_data.delete(mount_point)
      @cache.clear
    end

    def read_file(path : String) : String
      if data = read_bytes(path)
        String.new(data)
      else
        raise AssetNotFoundError.new("Asset not found: #{path}")
      end
    end

    def read_bytes(path : String) : Bytes?
      return @cache[path].as(Bytes) if @cache.has_key?(path) && @cache[path].is_a?(Bytes)

      # Try archives first
      @archives.each do |mount_point, archive|
        normalized_path = normalize_path(path)

        # Re-create reader from stored data to reset position
        reader = Compress::Zip::Reader.new(IO::Memory.new(@archive_data[mount_point]))

        reader.each_entry do |entry|
          if entry.filename == normalized_path
            data = entry.io.gets_to_end.to_slice
            @cache[path] = data
            return data
          end
        end
      end

      # Fall back to filesystem
      if File.exists?(path)
        data = File.read(path).to_slice
        @cache[path] = data
        return data
      end

      nil
    end

    def exists?(path : String) : Bool
      # Check archives
      @archives.each do |mount_point, archive|
        normalized_path = normalize_path(path)

        # Re-create reader from stored data
        reader = Compress::Zip::Reader.new(IO::Memory.new(@archive_data[mount_point]))

        reader.each_entry do |entry|
          return true if entry.filename == normalized_path
        end
      end

      # Check filesystem
      File.exists?(path)
    end

    def list_files(directory : String = "") : Array(String)
      files = [] of String
      normalized_dir = normalize_path(directory)

      # List from archives
      @archives.each do |mount_point, archive|
        reader = Compress::Zip::Reader.new(IO::Memory.new(@archive_data[mount_point]))

        reader.each_entry do |entry|
          if normalized_dir.empty? || entry.filename.starts_with?(normalized_dir)
            files << entry.filename
          end
        end
      end

      # List from filesystem if directory exists
      if File.directory?(directory)
        Dir.glob(File.join(directory, "**/*")).each do |file|
          files << file if File.file?(file)
        end
      end

      files.uniq
    end

    def clear_cache
      @cache.clear
    end

    private def normalize_path(path : String) : String
      path.lstrip('/')
    end

    # Singleton instance
    @@instance : AssetManager?

    def self.instance
      @@instance ||= new
    end

    # Convenience methods
    def self.mount_archive(path : String, mount_point : String = "/")
      instance.mount_archive(path, mount_point)
    end

    def self.unmount_archive(mount_point : String = "/")
      instance.unmount_archive(mount_point)
    end

    def self.read_file(path : String) : String
      instance.read_file(path)
    end

    def self.read_bytes(path : String) : Bytes?
      instance.read_bytes(path)
    end

    def self.exists?(path : String) : Bool
      instance.exists?(path)
    end

    def self.list_files(directory : String = "") : Array(String)
      instance.list_files(directory)
    end
  end
end
