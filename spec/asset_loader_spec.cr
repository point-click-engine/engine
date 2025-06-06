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
        yaml.should contain("name: Test Dialog")
        yaml.should contain("text: Hello!")
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
    pending "loads textures from archive (requires Raylib context)" do
      # This would need a full Raylib window context to test properly
    end
  end

  describe "sound loading" do
    pending "loads sounds from archive (requires Raylib audio context)" do
      # This would need Raylib audio initialized to test properly
    end
  end
end