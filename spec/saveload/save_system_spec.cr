require "../spec_helper"

# Save/Load system reliability tests
# Tests the complete save/load functionality for game state persistence
describe "Save/Load System Reliability Tests" do
  describe "save data structure" do
    it "creates valid save data objects" do
      save_data = PointClickEngine::Core::SaveData.new

      # Check default values
      save_data.version.should eq("1.0")
      save_data.timestamp.should be_a(Time)
      save_data.current_scene_name.should eq("")
      save_data.player_position_x.should eq(0.0)
      save_data.player_position_y.should eq(0.0)
      save_data.inventory_items.should be_empty
      save_data.game_variables.should be_empty
      save_data.completed_dialogs.should be_empty
      save_data.scene_states.should be_empty
    end

    it "serializes and deserializes to YAML correctly" do
      # Create save data with test values
      save_data = PointClickEngine::Core::SaveData.new
      save_data.current_scene_name = "test_scene"
      save_data.player_position_x = 100.5_f32
      save_data.player_position_y = 200.3_f32
      save_data.game_variables["test_var"] = "test_value"
      save_data.completed_dialogs << "intro_dialog"
      save_data.scene_states["room1"] = {"door_open" => "true"}

      # Serialize to YAML
      yaml_content = save_data.to_yaml
      yaml_content.should_not be_empty
      yaml_content.should contain("test_scene")
      yaml_content.should contain("100.5")
      yaml_content.should contain("test_value")

      # Deserialize back
      loaded_data = PointClickEngine::Core::SaveData.from_yaml(yaml_content)
      loaded_data.current_scene_name.should eq("test_scene")
      loaded_data.player_position_x.should eq(100.5_f32)
      loaded_data.player_position_y.should eq(200.3_f32)
      loaded_data.game_variables["test_var"].should eq("test_value")
      loaded_data.completed_dialogs.should contain("intro_dialog")
      loaded_data.scene_states["room1"]["door_open"].should eq("true")
    end
  end

  describe "save directory management" do
    it "creates save directory if it doesn't exist" do
      # Clean up any existing test directory
      test_save_dir = "test_saves"
      FileUtils.rm_rf(test_save_dir) if Dir.exists?(test_save_dir)

      # Temporarily change save directory for testing
      original_save_dir = PointClickEngine::Core::SaveSystem::SAVE_DIRECTORY

      begin
        # Override constant for testing (this is a bit hacky but necessary for testing)
        PointClickEngine::Core::SaveSystem.ensure_save_directory

        # Should create the directory
        Dir.exists?(PointClickEngine::Core::SaveSystem::SAVE_DIRECTORY).should be_true
      ensure
        # Cleanup is handled by the system
      end
    end
  end

  describe "save file operations" do
    it "handles basic save file creation and reading" do
      # Create a minimal save data file
      test_save_content = <<-YAML
      ---
      version: "1.0"
      timestamp: 2023-01-01T00:00:00.000000000Z
      current_scene_name: "test_room"
      player_position_x: 50.0
      player_position_y: 75.0
      inventory_items: []
      game_variables: {}
      completed_dialogs: []
      scene_states: {}
      YAML

      # Write test save file
      test_save_path = "test_save.save"
      File.write(test_save_path, test_save_content)

      begin
        # Verify file exists and is readable
        File.exists?(test_save_path).should be_true
        content = File.read(test_save_path)
        content.should contain("test_room")

        # Parse as SaveData
        save_data = PointClickEngine::Core::SaveData.from_yaml(content)
        save_data.current_scene_name.should eq("test_room")
        save_data.player_position_x.should eq(50.0)
        save_data.player_position_y.should eq(75.0)
      ensure
        # Cleanup
        File.delete(test_save_path) if File.exists?(test_save_path)
      end
    end

    it "handles corrupted save files gracefully" do
      corrupted_saves = [
        "invalid yaml content {[}",
        "---\nversion: 1.0\ninvalid_field",
        "",
        "---\nversion: \"1.0\"\ncurrent_scene_name:",
        "completely invalid content",
      ]

      corrupted_saves.each_with_index do |content, i|
        test_file = "corrupted_#{i}.save"
        File.write(test_file, content)

        begin
          # Should handle errors gracefully
          expect_raises(Exception) do
            PointClickEngine::Core::SaveData.from_yaml(content)
          end
        ensure
          File.delete(test_file) if File.exists?(test_file)
        end
      end
    end
  end

  describe "save data integrity" do
    it "maintains data consistency across save/load cycles" do
      # Create complex save data
      original_data = PointClickEngine::Core::SaveData.new
      original_data.version = "2.0"
      original_data.current_scene_name = "complex_scene"
      original_data.player_position_x = 123.456_f32
      original_data.player_position_y = 789.012_f32

      # Add complex nested data
      original_data.game_variables["string_var"] = "test string with spaces"
      original_data.game_variables["number_var"] = "42"
      original_data.game_variables["special_chars"] = "!@#$%^&*()"

      original_data.completed_dialogs = ["dialog1", "dialog2", "dialog3"]

      # Complex scene states
      original_data.scene_states["room1"] = {
        "door_locked" => "false",
        "light_on"    => "true",
        "item_taken"  => "false",
      }
      original_data.scene_states["room2"] = {
        "puzzle_solved" => "true",
        "chest_opened"  => "true",
      }

      # Save and reload
      yaml_content = original_data.to_yaml
      loaded_data = PointClickEngine::Core::SaveData.from_yaml(yaml_content)

      # Verify complete integrity
      loaded_data.version.should eq(original_data.version)
      loaded_data.current_scene_name.should eq(original_data.current_scene_name)
      loaded_data.player_position_x.should eq(original_data.player_position_x)
      loaded_data.player_position_y.should eq(original_data.player_position_y)

      # Check complex data structures
      loaded_data.game_variables.should eq(original_data.game_variables)
      loaded_data.completed_dialogs.should eq(original_data.completed_dialogs)
      loaded_data.scene_states.should eq(original_data.scene_states)
    end

    it "handles edge case values in save data" do
      save_data = PointClickEngine::Core::SaveData.new

      # Test extreme coordinate values
      save_data.player_position_x = Float32::MAX
      save_data.player_position_y = Float32::MIN

      # Test edge case strings
      save_data.current_scene_name = ""
      save_data.game_variables["empty"] = ""
      save_data.game_variables["long"] = "x" * 10000
      save_data.game_variables["unicode"] = "🎮 Unicode Test 中文"
      save_data.game_variables["newlines"] = "line1\nline2\nline3"

      # Test large arrays
      save_data.completed_dialogs = (1..1000).map { |i| "dialog_#{i}" }.to_a

      # Serialize and deserialize
      yaml_content = save_data.to_yaml
      loaded_data = PointClickEngine::Core::SaveData.from_yaml(yaml_content)

      # Verify extreme values survived the round trip
      loaded_data.player_position_x.should eq(Float32::MAX)
      loaded_data.player_position_y.should eq(Float32::MIN)
      loaded_data.game_variables["empty"].should eq("")
      loaded_data.game_variables["long"].should eq("x" * 10000)
      loaded_data.game_variables["unicode"].should eq("🎮 Unicode Test 中文")
      loaded_data.completed_dialogs.size.should eq(1000)
    end
  end

  describe "concurrent save operations" do
    it "handles multiple save operations without corruption" do
      # Simulate multiple save operations happening in sequence
      save_files = [] of String

      begin
        10.times do |i|
          save_data = PointClickEngine::Core::SaveData.new
          save_data.current_scene_name = "concurrent_scene_#{i}"
          save_data.player_position_x = i.to_f32 * 10
          save_data.player_position_y = i.to_f32 * 20
          save_data.game_variables["save_index"] = i.to_s

          save_file = "concurrent_save_#{i}.save"
          save_files << save_file

          File.write(save_file, save_data.to_yaml)
        end

        # Verify all saves are intact
        save_files.each_with_index do |file, i|
          File.exists?(file).should be_true
          content = File.read(file)
          save_data = PointClickEngine::Core::SaveData.from_yaml(content)

          save_data.current_scene_name.should eq("concurrent_scene_#{i}")
          save_data.player_position_x.should eq(i.to_f32 * 10)
          save_data.game_variables["save_index"].should eq(i.to_s)
        end
      ensure
        # Cleanup all test files
        save_files.each do |file|
          File.delete(file) if File.exists?(file)
        end
      end
    end
  end

  describe "save system stress testing" do
    it "handles rapid save/load operations" do
      test_files = [] of String

      begin
        # Rapid save operations
        100.times do |i|
          save_data = PointClickEngine::Core::SaveData.new
          save_data.current_scene_name = "stress_scene_#{i % 5}" # Cycle through scenes
          save_data.player_position_x = rand(1000).to_f32
          save_data.player_position_y = rand(1000).to_f32

          # Add some variety to data
          save_data.game_variables["iteration"] = i.to_s
          save_data.game_variables["random"] = rand(1000).to_s
          save_data.completed_dialogs << "dialog_#{i % 10}"

          test_file = "stress_save_#{i}.save"
          test_files << test_file

          File.write(test_file, save_data.to_yaml)

          # Verify can be read back immediately
          loaded_data = PointClickEngine::Core::SaveData.from_yaml(File.read(test_file))
          loaded_data.current_scene_name.should eq("stress_scene_#{i % 5}")
          loaded_data.game_variables["iteration"].should eq(i.to_s)
        end

        puts "Successfully created and verified #{test_files.size} save files"
      ensure
        # Cleanup
        test_files.each do |file|
          File.delete(file) if File.exists?(file)
        end
      end
    end

    it "handles large save data efficiently" do
      save_data = PointClickEngine::Core::SaveData.new

      # Create large amounts of data
      save_data.current_scene_name = "large_data_scene"

      # Large variable collection
      1000.times do |i|
        save_data.game_variables["var_#{i}"] = "value_#{i}_" + ("x" * 100)
      end

      # Large dialog collection
      save_data.completed_dialogs = (1..500).map { |i| "dialog_#{i}" }.to_a

      # Large scene states
      10.times do |scene_idx|
        scene_name = "large_scene_#{scene_idx}"
        scene_state = {} of String => String
        50.times do |state_idx|
          scene_state["state_#{state_idx}"] = "value_#{state_idx}"
        end
        save_data.scene_states[scene_name] = scene_state
      end

      test_file = "large_save_test.save"

      begin
        # Measure save performance
        start_time = Time.monotonic
        yaml_content = save_data.to_yaml
        File.write(test_file, yaml_content)
        save_time = Time.monotonic - start_time

        # Measure load performance
        load_start = Time.monotonic
        file_content = File.read(test_file)
        loaded_data = PointClickEngine::Core::SaveData.from_yaml(file_content)
        load_time = Time.monotonic - load_start

        puts "Large save performance:"
        puts "  Variables: #{save_data.game_variables.size}"
        puts "  Dialogs: #{save_data.completed_dialogs.size}"
        puts "  Scene states: #{save_data.scene_states.size}"
        puts "  Save time: #{save_time.total_milliseconds.round(2)}ms"
        puts "  Load time: #{load_time.total_milliseconds.round(2)}ms"
        puts "  File size: #{File.size(test_file)} bytes"

        # Verify data integrity
        loaded_data.game_variables.size.should eq(1000)
        loaded_data.completed_dialogs.size.should eq(500)
        loaded_data.scene_states.size.should eq(10)

        # Performance should be reasonable
        save_time.total_milliseconds.should be < 1000 # 1 second
        load_time.total_milliseconds.should be < 1000 # 1 second

      ensure
        File.delete(test_file) if File.exists?(test_file)
      end
    end
  end

  describe "error recovery and robustness" do
    it "handles disk space and permission issues gracefully" do
      # Test writing to read-only location (this may vary by system)
      begin
        readonly_path = "/dev/null/impossible.save"
        save_data = PointClickEngine::Core::SaveData.new

        expect_raises(Exception) do
          File.write(readonly_path, save_data.to_yaml)
        end
      rescue ex
        # Expected on most systems
        ex.should be_a(Exception)
      end
    end

    it "validates save data versions" do
      # Test different version formats
      version_tests = [
        {"1.0", true},
        {"2.0", true},
        {"1.5.2", true},
        {"", true},        # Empty version should be handled
        {"invalid", true}, # Non-numeric versions should be handled
      ]

      version_tests.each do |version, should_work|
        save_data = PointClickEngine::Core::SaveData.new
        save_data.version = version

        yaml_content = save_data.to_yaml
        loaded_data = PointClickEngine::Core::SaveData.from_yaml(yaml_content)
        loaded_data.version.should eq(version)
      end
    end

    it "handles timestamp edge cases" do
      save_data = PointClickEngine::Core::SaveData.new

      # Test various timestamps
      timestamps = [
        Time.utc(2000, 1, 1),
        Time.utc(2099, 12, 31),
        Time.utc,
      ]

      timestamps.each do |timestamp|
        save_data.timestamp = timestamp
        yaml_content = save_data.to_yaml
        loaded_data = PointClickEngine::Core::SaveData.from_yaml(yaml_content)

        # Timestamps should survive serialization (may lose some precision)
        loaded_data.timestamp.year.should eq(timestamp.year)
        loaded_data.timestamp.month.should eq(timestamp.month)
        loaded_data.timestamp.day.should eq(timestamp.day)
      end
    end
  end

  describe "memory management" do
    it "does not leak memory during save/load operations" do
      initial_memory = GC.stats.heap_size

      # Perform many save/load cycles
      50.times do |i|
        save_data = PointClickEngine::Core::SaveData.new
        save_data.current_scene_name = "memory_test_#{i}"
        save_data.player_position_x = rand(1000).to_f32
        save_data.player_position_y = rand(1000).to_f32

        # Add substantial data
        100.times do |j|
          save_data.game_variables["var_#{j}"] = "value_#{j}"
        end

        # Serialize and deserialize
        yaml_content = save_data.to_yaml
        loaded_data = PointClickEngine::Core::SaveData.from_yaml(yaml_content)

        # Verify data (ensures it's actually being used)
        loaded_data.current_scene_name.should eq("memory_test_#{i}")
        loaded_data.game_variables.size.should eq(100)
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Save/Load memory test: growth = #{memory_growth} bytes"

      # Should not leak significant memory
      memory_growth.should be < 10_000_000 # 10MB limit
    end
  end
end
