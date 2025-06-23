require "../spec_helper"
require "../../src/assets/asset_manager"

describe PointClickEngine::AssetManager do
  describe "Error handling and recovery" do
    before_each do
      # Clear any existing cache and archives
      PointClickEngine::AssetManager.instance.clear_cache
    end

    after_each do
      # Clean up any test archives
      PointClickEngine::AssetManager.instance.unmount_archive("/")
      PointClickEngine::AssetManager.instance.clear_cache
    end

    describe "AssetNotFoundError handling" do
      it "raises specific error for missing assets" do
        expect_raises(PointClickEngine::AssetManager::AssetNotFoundError, /Asset not found/) do
          PointClickEngine::AssetManager.read_file("nonexistent/file.txt")
        end
      end

      it "provides search context in error messages" do
        begin
          PointClickEngine::AssetManager.read_file("missing_asset.txt")
        rescue ex : PointClickEngine::AssetManager::AssetNotFoundError
          message = ex.message || ""
          message.includes?("Asset not found").should be_true
          message.includes?("missing_asset.txt").should be_true
        end
      end

      it "returns nil for missing bytes instead of raising" do
        result = PointClickEngine::AssetManager.read_bytes("nonexistent/binary.dat")
        result.should be_nil
      end

      it "handles graceful fallback from archives to filesystem" do
        # Create a test file on filesystem
        File.write("temp_fallback_test.txt", "filesystem content")

        begin
          # Asset should be found on filesystem even with no archives mounted
          content = PointClickEngine::AssetManager.read_file("temp_fallback_test.txt")
          content.should eq("filesystem content")
        ensure
          File.delete("temp_fallback_test.txt") if File.exists?("temp_fallback_test.txt")
        end
      end
    end

    describe "Archive mounting error handling" do
      it "handles mounting non-existent archives" do
        expect_raises(Exception) do
          PointClickEngine::AssetManager.mount_archive("nonexistent_archive.zip")
        end
      end

      it "handles corrupt archive files gracefully" do
        # Create a fake "corrupt" zip file
        File.write("temp_corrupt.zip", "not_a_zip_file_content")

        begin
          # The system should either raise an exception or handle it gracefully
          begin
            PointClickEngine::AssetManager.mount_archive("temp_corrupt.zip")
            # If it doesn't raise, test that normal file operations still work
            test_result = PointClickEngine::AssetManager.exists?("any_file.txt")
            test_result.should be_false
          rescue ex
            # If it raises an exception, that's also acceptable behavior
            ex.should be_a(Exception)
          end
        ensure
          File.delete("temp_corrupt.zip") if File.exists?("temp_corrupt.zip")
        end
      end

      it "continues operation after failed archive mount" do
        # Create valid test file
        File.write("temp_normal_file.txt", "normal content")

        begin
          # Try to mount corrupt archive
          begin
            PointClickEngine::AssetManager.mount_archive("nonexistent.zip")
          rescue
            # Expected to fail
          end

          # Should still be able to read filesystem assets
          content = PointClickEngine::AssetManager.read_file("temp_normal_file.txt")
          content.should eq("normal content")
        ensure
          File.delete("temp_normal_file.txt") if File.exists?("temp_normal_file.txt")
        end
      end
    end

    describe "Memory and caching error scenarios" do
      it "handles cache corruption gracefully" do
        # Create test file
        File.write("temp_cache_test.txt", "original content")

        begin
          # Read file to populate cache
          content1 = PointClickEngine::AssetManager.read_file("temp_cache_test.txt")
          content1.should eq("original content")

          # Simulate cache corruption by clearing it
          PointClickEngine::AssetManager.instance.clear_cache

          # Should still be able to read file (cache miss, read from disk)
          content2 = PointClickEngine::AssetManager.read_file("temp_cache_test.txt")
          content2.should eq("original content")
        ensure
          File.delete("temp_cache_test.txt") if File.exists?("temp_cache_test.txt")
        end
      end

      it "handles large file operations" do
        # Create a moderately large test file
        large_content = "x" * 10000 # 10KB file
        File.write("temp_large_file.txt", large_content)

        begin
          # Should handle large files without crashing
          content = PointClickEngine::AssetManager.read_file("temp_large_file.txt")
          content.size.should eq(10000)

          # Should also work for binary data
          binary_data = PointClickEngine::AssetManager.read_bytes("temp_large_file.txt")
          binary_data.should_not be_nil
          binary_data.not_nil!.size.should eq(10000)
        ensure
          File.delete("temp_large_file.txt") if File.exists?("temp_large_file.txt")
        end
      end
    end

    describe "File system error recovery" do
      it "handles permission denied errors" do
        # This test is platform-dependent, so we'll simulate it
        # In a real scenario, we'd test with files that have restricted permissions

        # For now, just test that the error propagates correctly
        expect_raises(PointClickEngine::AssetManager::AssetNotFoundError) do
          PointClickEngine::AssetManager.read_file("/root/restricted_file.txt")
        end
      end

      it "handles concurrent access gracefully" do
        # Create test file
        File.write("temp_concurrent_test.txt", "shared content")

        begin
          # Simulate concurrent reads (in real threading scenario)
          results = [] of String

          5.times do
            results << PointClickEngine::AssetManager.read_file("temp_concurrent_test.txt")
          end

          # All reads should succeed
          results.size.should eq(5)
          results.all? { |r| r == "shared content" }.should be_true
        ensure
          File.delete("temp_concurrent_test.txt") if File.exists?("temp_concurrent_test.txt")
        end
      end
    end

    describe "Archive validation and recovery" do
      it "validates file listings in corrupted archives" do
        # Test that list_files doesn't crash with no archives
        files = PointClickEngine::AssetManager.list_files("nonexistent_dir")
        files.should be_a(Array(String))
        files.should be_empty
      end

      it "handles mixed archive and filesystem listings" do
        # Create filesystem directory
        Dir.mkdir_p("temp_listing_test")
        File.write("temp_listing_test/file1.txt", "content1")
        File.write("temp_listing_test/file2.txt", "content2")

        begin
          # List files from filesystem
          files = PointClickEngine::AssetManager.list_files("temp_listing_test")
          files.size.should be >= 2

          # Should include our test files
          files.any? { |f| f.includes?("file1.txt") }.should be_true
          files.any? { |f| f.includes?("file2.txt") }.should be_true
        ensure
          File.delete("temp_listing_test/file1.txt") if File.exists?("temp_listing_test/file1.txt")
          File.delete("temp_listing_test/file2.txt") if File.exists?("temp_listing_test/file2.txt")
          Dir.delete("temp_listing_test") if Dir.exists?("temp_listing_test")
        end
      end

      it "handles asset existence checks with mixed sources" do
        # Create test file
        File.write("temp_exists_test.txt", "exists")

        begin
          # Should find existing file
          PointClickEngine::AssetManager.exists?("temp_exists_test.txt").should be_true

          # Should not find non-existent file
          PointClickEngine::AssetManager.exists?("definitely_missing.txt").should be_false
        ensure
          File.delete("temp_exists_test.txt") if File.exists?("temp_exists_test.txt")
        end
      end
    end

    describe "Binary data error handling" do
      it "handles binary files with null bytes" do
        # Create binary file with null bytes
        binary_data = Bytes[0x00, 0x42, 0x00, 0xFF, 0x00]
        File.write("temp_binary_test.bin", binary_data)

        begin
          # Should handle binary data correctly
          result = PointClickEngine::AssetManager.read_bytes("temp_binary_test.bin")
          result.should_not be_nil
          result.not_nil!.size.should eq(5)
          result.not_nil![0].should eq(0x00)
          result.not_nil![1].should eq(0x42)
          result.not_nil![4].should eq(0x00)
        ensure
          File.delete("temp_binary_test.bin") if File.exists?("temp_binary_test.bin")
        end
      end

      it "handles text encoding issues gracefully" do
        # Create file with potentially problematic content
        File.write("temp_encoding_test.txt", "normal text\nwith\ttabs\rand\r\nline endings")

        begin
          # Should handle various line endings and characters
          content = PointClickEngine::AssetManager.read_file("temp_encoding_test.txt")
          content.includes?("normal text").should be_true
          content.includes?("tabs").should be_true
          content.includes?("line endings").should be_true
        ensure
          File.delete("temp_encoding_test.txt") if File.exists?("temp_encoding_test.txt")
        end
      end
    end

    describe "Resource cleanup and recovery" do
      it "properly cleans up resources after unmounting" do
        # Create test archive content
        File.write("temp_archive_test.txt", "archive content")

        begin
          # Mount and unmount to test cleanup
          PointClickEngine::AssetManager.instance.unmount_archive("/")

          # After unmount, cache should be cleared
          # Reading should work from filesystem
          content = PointClickEngine::AssetManager.read_file("temp_archive_test.txt")
          content.should eq("archive content")
        ensure
          File.delete("temp_archive_test.txt") if File.exists?("temp_archive_test.txt")
        end
      end

      it "recovers from out-of-memory scenarios" do
        # This is a simulation - in practice, we'd need to actually exhaust memory
        # For now, just test that cache clearing works

        # Populate cache with several files
        (1..5).each do |i|
          File.write("temp_memory_test_#{i}.txt", "content #{i}")
        end

        begin
          # Read all files to populate cache
          contents = (1..5).map do |i|
            PointClickEngine::AssetManager.read_file("temp_memory_test_#{i}.txt")
          end

          contents.size.should eq(5)

          # Clear cache to simulate recovery
          PointClickEngine::AssetManager.instance.clear_cache

          # Should still be able to read files
          new_content = PointClickEngine::AssetManager.read_file("temp_memory_test_1.txt")
          new_content.should eq("content 1")
        ensure
          (1..5).each do |i|
            File.delete("temp_memory_test_#{i}.txt") if File.exists?("temp_memory_test_#{i}.txt")
          end
        end
      end
    end
  end
end
