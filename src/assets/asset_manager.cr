require "compress/zip"
require "../core/exceptions"

module PointClickEngine
  # Asset management system with ZIP archive support
  #
  # The AssetManager provides a unified interface for loading game assets from
  # both the filesystem and ZIP archives. It supports mounting multiple archives,
  # caching loaded assets, and transparent fallback between archives and filesystem.
  #
  # ## Features
  # - Mount multiple ZIP archives as virtual filesystems
  # - Automatic caching of loaded assets
  # - Transparent access to both archived and filesystem assets
  # - Singleton pattern for global access
  #
  # ## Example
  #
  # ```
  # # Mount a game archive
  # AssetManager.mount_archive("game_assets.zip")
  #
  # # Read a text file
  # dialog_text = AssetManager.read_file("dialogs/intro.txt")
  #
  # # Read binary data (e.g., images)
  # image_data = AssetManager.read_bytes("sprites/player.png")
  #
  # # Check if asset exists
  # if AssetManager.exists?("music/theme.ogg")
  #   # Load the music
  # end
  #
  # # List all files in a directory
  # sprites = AssetManager.list_files("sprites/")
  # ```
  class AssetManager
    # Exception raised when a requested asset cannot be found
    class AssetNotFoundError < Core::AssetError
      def initialize(asset_path : String, searched_locations : Array(String) = [] of String)
        message = "Asset not found: #{asset_path}"
        unless searched_locations.empty?
          message += "\nSearched in:\n" + searched_locations.map { |loc| "  - #{loc}" }.join("\n")
        end
        super(message, asset_path)
      end
    end

    # Alias for cached asset data (can be binary or text)
    alias AssetData = Bytes | String

    @archives : Hash(String, Compress::Zip::Reader) = {} of String => Compress::Zip::Reader
    @archive_data : Hash(String, Bytes) = {} of String => Bytes
    @cache : Hash(String, AssetData) = {} of String => AssetData

    def initialize
    end

    # Mount a ZIP archive as a virtual filesystem
    #
    # Archives are searched before the filesystem when loading assets.
    # Multiple archives can be mounted at different mount points.
    #
    # - **path** : Path to the ZIP archive file
    # - **mount_point** : Virtual mount point (default: "/")
    #
    # ```
    # AssetManager.mount_archive("game_data.zip")
    # AssetManager.mount_archive("dlc_content.zip", "/dlc")
    # ```
    def mount_archive(path : String, mount_point : String = "/")
      file_data = File.read(path).to_slice
      @archive_data[mount_point] = file_data
      @archives[mount_point] = Compress::Zip::Reader.new(IO::Memory.new(file_data))
    end

    # Unmount a previously mounted archive
    #
    # This also clears the asset cache to free memory.
    #
    # - **mount_point** : The mount point to unmount (default: "/")
    def unmount_archive(mount_point : String = "/")
      @archives.delete(mount_point)
      @archive_data.delete(mount_point)
      @cache.clear
    end

    # Read a text file from archives or filesystem
    #
    # Searches mounted archives first, then falls back to filesystem.
    # The result is cached for faster subsequent access.
    #
    # - **path** : Path to the file to read
    # - **returns** : File contents as a string
    # - **raises** : AssetNotFoundError if the file doesn't exist
    def read_file(path : String) : String
      if data = read_bytes(path)
        String.new(data)
      else
        raise AssetNotFoundError.new("Asset not found: #{path}")
      end
    end

    # Read binary data from archives or filesystem
    #
    # Searches mounted archives first, then falls back to filesystem.
    # The result is cached for faster subsequent access.
    #
    # - **path** : Path to the file to read
    # - **returns** : File contents as bytes, or nil if not found
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

    # Check if an asset exists in archives or filesystem
    #
    # - **path** : Path to check
    # - **returns** : True if the asset exists
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

    # List all files in a directory across archives and filesystem
    #
    # - **directory** : Directory path to list (empty for all files)
    # - **returns** : Array of file paths
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

    # Clear the asset cache to free memory
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
