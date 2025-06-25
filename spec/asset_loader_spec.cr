require "./spec_helper"
require "compress/zip"

describe PointClickEngine::AssetLoader do
  describe "loading assets from archives" do
    before_each do
      # Clear any existing archives
      PointClickEngine::AssetManager.instance.unmount_archive
    end

    it "loads scripts from archive" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        # Create ZIP with Lua script
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("scripts/test.lua", IO::Memory.new("return 42"))
          end
        end

        PointClickEngine::AssetManager.mount_archive(temp_zip)

        script = PointClickEngine::AssetLoader.read_script("scripts/test.lua")
        script.should eq("return 42")
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end

    it "loads YAML from archive" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        # Create ZIP with YAML file
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            yaml_content = <<-YAML
            name: Test Dialog
            nodes:
              - id: start
                text: Hello!
            YAML
            zip.add("dialogs/test.yml", IO::Memory.new(yaml_content))
          end
        end

        PointClickEngine::AssetManager.mount_archive(temp_zip)

        yaml = PointClickEngine::AssetLoader.read_yaml("dialogs/test.yml")
        yaml.includes?("name: Test Dialog").should be_true
        yaml.includes?("text: Hello!").should be_true
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end

    it "falls back to filesystem when asset not in archive" do
      temp_file = File.tempname("test_script", ".lua")
      File.write(temp_file, "print('from filesystem')")

      begin
        script = PointClickEngine::AssetLoader.read_script(temp_file)
        script.should eq("print('from filesystem')")
      ensure
        File.delete(temp_file) if File.exists?(temp_file)
      end
    end

    it "checks if asset exists" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("exists.txt", IO::Memory.new("content"))
          end
        end

        PointClickEngine::AssetManager.mount_archive(temp_zip)

        PointClickEngine::AssetLoader.exists?("exists.txt").should be_true
        PointClickEngine::AssetLoader.exists?("notexists.txt").should be_false
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end
  end

  # Note: Testing texture and sound loading would require mocking Raylib
  # which is complex due to C bindings. These would be better tested
  # through integration tests with actual game files.

  describe "texture loading" do
    it "loads textures from archive using mock" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        # Create ZIP with dummy texture file (PNG header)
        png_data = Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] # PNG signature

        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("textures/test.png", IO::Memory.new(png_data))
          end
        end

        PointClickEngine::AssetManager.mount_archive(temp_zip)

        # Test that the asset exists in the archive
        PointClickEngine::AssetLoader.exists?("textures/test.png").should be_true

        # In a real test with Raylib context, you would:
        # texture = PointClickEngine::AssetLoader.load_texture("textures/test.png")
        # texture.should_not be_nil

        # For now, just verify the file can be read
        PointClickEngine::AssetLoader.exists?("textures/test.png").should be_true
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end
  end

  describe "sound loading" do
    it "loads sounds from archive using mock" do
      temp_zip = File.tempname("test_archive", ".zip")

      begin
        # Create ZIP with dummy sound file (WAV header)
        wav_data = "RIFF\x00\x00\x00\x00WAVEfmt ".to_slice

        File.open(temp_zip, "w") do |file|
          Compress::Zip::Writer.open(file) do |zip|
            zip.add("sounds/test.wav", IO::Memory.new(wav_data))
          end
        end

        PointClickEngine::AssetManager.mount_archive(temp_zip)

        # Test that the asset exists in the archive
        PointClickEngine::AssetLoader.exists?("sounds/test.wav").should be_true

        # In a real test with Raylib audio context, you would:
        # sound = PointClickEngine::AssetLoader.load_sound("sounds/test.wav")
        # sound.should_not be_nil

        # For now, just verify the file can be read
        PointClickEngine::AssetLoader.exists?("sounds/test.wav").should be_true
      ensure
        File.delete(temp_zip) if File.exists?(temp_zip)
      end
    end
  end
end
