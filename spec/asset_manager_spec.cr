require "./spec_helper"
require "compress/zip"

describe PointClickEngine::AssetManager do
  describe "#mount_archive and #read_file" do
    it "reads files from a mounted ZIP archive" do
      # Create a temporary ZIP file
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        # Create ZIP with test content
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("test.txt", IO::Memory.new("Hello from archive!"))
            zip.add("scripts/test.lua", IO::Memory.new("print('Lua script')"))
            zip.add("data/config.yml", IO::Memory.new("key: value"))
          end
        end

        manager = PointClickEngine::AssetManager.new
        manager.mount_archive(temp_zip)

        # Test reading text file
        content = manager.read_file("test.txt")
        content.should eq("Hello from archive!")

        # Test reading Lua script
        script = manager.read_file("scripts/test.lua")
        script.should eq("print('Lua script')")

        # Test reading YAML file
        yaml = manager.read_file("data/config.yml")
        yaml.should eq("key: value")
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end

    it "falls back to filesystem when file not in archive" do
      manager = PointClickEngine::AssetManager.new

      # Create a temporary file on filesystem
      temp_file = File.tempname("test_file", ".txt")
      File.write(temp_file, "Filesystem content")

      begin
        content = manager.read_file(temp_file)
        content.should eq("Filesystem content")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "raises error when file not found" do
      manager = PointClickEngine::AssetManager.new

      expect_raises(PointClickEngine::AssetManager::AssetNotFoundError, "Asset not found: nonexistent.txt") do
        manager.read_file("nonexistent.txt")
      end
    end
  end

  describe "#read_bytes" do
    it "reads binary data from archive" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        # Create ZIP with binary content
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            binary_data = Bytes[0x89, 0x50, 0x4E, 0x47] # PNG header
            zip.add("image.png", IO::Memory.new(binary_data))
          end
        end

        manager = PointClickEngine::AssetManager.new
        manager.mount_archive(temp_zip)

        bytes = manager.read_bytes("image.png")
        bytes.should_not be_nil
        bytes.not_nil!.should eq(Bytes[0x89, 0x50, 0x4E, 0x47])
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end

    it "returns nil when file not found" do
      manager = PointClickEngine::AssetManager.new
      bytes = manager.read_bytes("nonexistent.png")
      bytes.should be_nil
    end
  end

  describe "#exists?" do
    it "checks if file exists in archive" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("exists.txt", IO::Memory.new("content"))
          end
        end

        manager = PointClickEngine::AssetManager.new
        manager.mount_archive(temp_zip)

        manager.exists?("exists.txt").should be_true
        manager.exists?("notexists.txt").should be_false
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end

    it "checks filesystem when not in archive" do
      manager = PointClickEngine::AssetManager.new

      temp_file = File.tempname("test_file", ".txt")
      File.write(temp_file, "content")

      begin
        manager.exists?(temp_file).should be_true
        manager.exists?("nonexistent.txt").should be_false
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end
  end

  describe "#list_files" do
    it "lists files from archive" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("file1.txt", IO::Memory.new("content1"))
            zip.add("dir/file2.txt", IO::Memory.new("content2"))
            zip.add("dir/subdir/file3.txt", IO::Memory.new("content3"))
          end
        end

        manager = PointClickEngine::AssetManager.new
        manager.mount_archive(temp_zip)

        files = manager.list_files
        files.includes?("file1.txt").should be_true
        files.includes?("dir/file2.txt").should be_true
        files.includes?("dir/subdir/file3.txt").should be_true

        # List files in specific directory
        dir_files = manager.list_files("dir")
        dir_files.includes?("dir/file2.txt").should be_true
        dir_files.includes?("dir/subdir/file3.txt").should be_true
        dir_files.includes?("file1.txt").should be_false
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end
  end

  describe "#unmount_archive" do
    it "removes archive and clears cache" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("test.txt", IO::Memory.new("content"))
          end
        end

        manager = PointClickEngine::AssetManager.new
        manager.mount_archive(temp_zip)

        # Verify file is accessible
        manager.exists?("test.txt").should be_true

        # Unmount archive
        manager.unmount_archive

        # File should no longer be accessible
        manager.exists?("test.txt").should be_false
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end
  end

  describe "caching" do
    it "caches read files" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("cached.txt", IO::Memory.new("cached content"))
          end
        end

        manager = PointClickEngine::AssetManager.new
        manager.mount_archive(temp_zip)

        # First read
        content1 = manager.read_file("cached.txt")

        # Second read should come from cache
        content2 = manager.read_file("cached.txt")

        content1.should eq(content2)
        content1.should eq("cached content")
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end
  end

  describe "singleton instance" do
    it "provides global access" do
      PointClickEngine::AssetManager.instance.should be_a(PointClickEngine::AssetManager)
      PointClickEngine::AssetManager.instance.should eq(PointClickEngine::AssetManager.instance)
    end

    it "delegates class methods to instance" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("singleton.txt", IO::Memory.new("singleton content"))
          end
        end

        PointClickEngine::AssetManager.mount_archive(temp_zip)

        content = PointClickEngine::AssetManager.read_file("singleton.txt")
        content.should eq("singleton content")

        PointClickEngine::AssetManager.unmount_archive
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end
  end
end
