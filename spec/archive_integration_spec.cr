require "./spec_helper"
require "compress/zip"

describe "Archive Loading Integration" do
  it "loads a complete game from archive" do
    # Create a temporary game archive
    temp_archive = File.tempname("test_game", ".zip")

    begin
      # Create ZIP with game assets
      File.open(temp_archive, "w") do |file|
        Compress::Zip::Writer.open(file) do |zip|
          # Add a simple Lua script
          lua_script = <<-LUA
          function on_init(character)
            print("Character initialized from archive")
          end
          
          function on_interact(character, player)
            print("Interaction from archive script")
            return "Hello from the archive!"
          end
          LUA
          zip.add("scripts/npc.lua", IO::Memory.new(lua_script))

          # Add a dialog tree YAML
          dialog_yaml = <<-YAML
          name: "Archive Dialog"
          nodes:
            - id: "start"
              text: "Hello! I'm loaded from an archive."
              choices:
                - text: "Amazing!"
                  next: "end"
            - id: "end"
              text: "Thanks for testing archive loading!"
          YAML
          zip.add("dialogs/test_dialog.yml", IO::Memory.new(dialog_yaml))

          # Add a save game YAML
          save_yaml = <<-YAML
          engine:
            window_width: 800
            window_height: 600
            title: "Archive Test Game"
            current_scene_name: "test_scene"
            scenes:
              test_scene:
                name: "test_scene"
                width: 800
                height: 600
                hotspots:
                  - name: "test_hotspot"
                    x: 100
                    y: 100
                    width: 50
                    height: 50
                    description: "A test hotspot"
            inventory:
              max_items: 10
              items: []
          YAML
          zip.add("saves/test_save.yml", IO::Memory.new(save_yaml))
        end
      end

      # Mount the archive
      PointClickEngine::AssetManager.mount_archive(temp_archive)

      # Test that we can read the script
      script_content = PointClickEngine::AssetManager.read_file("scripts/npc.lua")
      script_content.should contain("Character initialized from archive")

      # Test that we can read the dialog
      dialog_content = PointClickEngine::AssetManager.read_file("dialogs/test_dialog.yml")
      dialog_content.should contain("Archive Dialog")
      dialog_content.should contain("Hello! I'm loaded from an archive.")

      # Test that we can load and parse the dialog tree
      dialog_yaml_parsed = YAML.parse(dialog_content)
      dialog_yaml_parsed["name"].as_s.should eq("Archive Dialog")

      # Test listing files
      files = PointClickEngine::AssetManager.list_files
      files.should contain("scripts/npc.lua")
      files.should contain("dialogs/test_dialog.yml")
      files.should contain("saves/test_save.yml")

      # Test listing files in a directory
      script_files = PointClickEngine::AssetManager.list_files("scripts")
      script_files.should contain("scripts/npc.lua")
      script_files.size.should eq(1)

      # Unmount and verify files are no longer accessible
      PointClickEngine::AssetManager.unmount_archive
      PointClickEngine::AssetManager.exists?("scripts/npc.lua").should be_false
    ensure
      File.delete(temp_archive) if File.exists?(temp_archive)
      # Clean up in case of failure
      PointClickEngine::AssetManager.instance.unmount_archive rescue nil
    end
  end

  it "supports multiple archives mounted at different points" do
    archive1 = File.tempname("archive1", ".zip")
    archive2 = File.tempname("archive2", ".zip")

    begin
      # Create first archive
      File.open(archive1, "w") do |file|
        Compress::Zip::Writer.open(file) do |zip|
          zip.add("file1.txt", IO::Memory.new("From archive 1"))
        end
      end

      # Create second archive
      File.open(archive2, "w") do |file|
        Compress::Zip::Writer.open(file) do |zip|
          zip.add("file2.txt", IO::Memory.new("From archive 2"))
        end
      end

      # Mount both archives
      PointClickEngine::AssetManager.mount_archive(archive1, "/archive1")
      PointClickEngine::AssetManager.mount_archive(archive2, "/archive2")

      # Both files should be accessible
      content1 = PointClickEngine::AssetManager.read_file("file1.txt")
      content1.should eq("From archive 1")

      content2 = PointClickEngine::AssetManager.read_file("file2.txt")
      content2.should eq("From archive 2")

      # Clean up
      PointClickEngine::AssetManager.unmount_archive("/archive1")
      PointClickEngine::AssetManager.unmount_archive("/archive2")
    ensure
      File.delete(archive1) if File.exists?(archive1)
      File.delete(archive2) if File.exists?(archive2)
    end
  end
end
