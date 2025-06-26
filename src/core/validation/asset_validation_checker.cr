require "./validation_result"
require "../game_config"

module PointClickEngine
  module Core
    module Validation
      # Comprehensive asset validation system
      #
      # The AssetValidationChecker handles validation of all game assets including
      # sprites, audio files, scene backgrounds, and other media resources.
      # It checks for existence, size, format, and performance considerations.
      class AssetValidationChecker < BaseValidator
        def description : String
          "Validates game assets including sprites, audio, backgrounds, and media files"
        end

        def validate(config : GameConfig, context : ValidationContext) : ValidationResult
          result = ValidationResult.new

          validate_scene_backgrounds(config, context, result)
          validate_asset_sizes(config, context, result)
          validate_asset_formats(config, context, result)
          validate_shader_assets(config, context, result)

          result
        end

        # Validates scene background images
        private def validate_scene_backgrounds(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          window_width = config.window.try(&.width) || 1024
          window_height = config.window.try(&.height) || 768

          assets.scenes.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |scene_path|
              begin
                scene_content = File.read(scene_path)
                scene_name = File.basename(scene_path, ".yaml")
                lines = scene_content.split('\n')

                validate_scene_background_path(scene_content, lines, scene_name, context, result)
                validate_scene_scale(scene_content, lines, scene_name, result)
              rescue ex
                result.add_warning("Could not analyze scene file #{File.basename(scene_path)}: #{ex.message}")
              end
            end
          end
        end

        # Validates individual scene background path
        private def validate_scene_background_path(scene_content : String, lines : Array(String), scene_name : String, context : ValidationContext, result : ValidationResult)
          if scene_content.includes?("background_path:")
            # Extract background path from YAML
            bg_line = lines.find { |line| line.strip.starts_with?("background_path:") }
            if bg_line
              bg_path = bg_line.split(":", 2)[1].strip.gsub(/["']/, "")
              full_bg_path = File.expand_path(bg_path, context.base_dir)

              if File.exists?(full_bg_path)
                # Check file size
                bg_size = File.size(full_bg_path)
                if bg_size > 10_000_000 # 10MB
                  result.add_warning("Scene '#{scene_name}' background is large (#{(bg_size / 1_048_576.0).round(1)} MB)")
                end

                # Check image format
                validate_image_format(full_bg_path, "background for scene '#{scene_name}'", result)

                result.add_info("✓ Background found for scene '#{scene_name}': #{bg_path}")
              else
                result.add_error("Background image not found for scene '#{scene_name}': #{bg_path}")
              end
            end
          else
            result.add_warning("Scene '#{scene_name}' has no background specified")
          end
        end

        # Validates scene scale values
        private def validate_scene_scale(scene_content : String, lines : Array(String), scene_name : String, result : ValidationResult)
          if scene_content.includes?("scale:")
            scale_line = lines.find { |line| line.strip.starts_with?("scale:") }
            if scale_line
              scale_value = scale_line.split(":", 2)[1].strip.to_f?
              if scale_value && (scale_value <= 0 || scale_value > 10)
                result.add_warning("Scene '#{scene_name}' has unusual scale value: #{scale_value}")
              end
            end
          end
        end

        # Validates asset file sizes for performance
        private def validate_asset_sizes(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          large_assets = [] of String
          total_asset_size = 0_i64

          # Check audio files
          if audio = assets.audio
            validate_audio_file_sizes(audio.music, "Music", context, result, large_assets, pointerof(total_asset_size))
            validate_audio_file_sizes(audio.sounds, "Sound", context, result, large_assets, pointerof(total_asset_size))
          end

          # Check sprite files
          validate_sprite_file_sizes(assets, context, result, large_assets, pointerof(total_asset_size))

          # Report findings
          if large_assets.any?
            result.add_performance_hint("Large assets found:")
            large_assets.each { |asset| result.add_performance_hint("  - #{asset}") }
          end

          total_size_mb = total_asset_size / 1_048_576.0
          if total_size_mb > 500
            result.add_performance_hint("Total asset size is large: #{total_size_mb.round(1)} MB")
          else
            result.add_info("Total asset size: #{total_size_mb.round(1)} MB")
          end
        end

        # Validates audio file sizes
        private def validate_audio_file_sizes(audio_files : Hash(String, String), category : String, context : ValidationContext, result : ValidationResult, large_assets : Array(String), total_size : Int64*)
          audio_files.each do |name, path|
            full_path = File.expand_path(path, context.base_dir)
            if File.exists?(full_path)
              size = File.size(full_path)
              total_size.value += size
              size_mb = size / 1_048_576.0

              threshold = category == "Music" ? 10.0 : 5.0
              if size_mb > threshold
                large_assets << "#{category} '#{name}': #{size_mb.round(1)} MB"
              end

              # Validate audio format
              validate_audio_format(full_path, "#{category.downcase} '#{name}'", result)
            end
          end
        end

        # Validates sprite file sizes
        private def validate_sprite_file_sizes(assets : GameConfig::AssetsConfig, context : ValidationContext, result : ValidationResult, large_assets : Array(String), total_size : Int64*)
          assets.sprites.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |sprite_path|
              if File.exists?(sprite_path)
                size = File.size(sprite_path)
                total_size.value += size
                size_mb = size / 1_048_576.0

                if size_mb > 5.0
                  large_assets << "Sprite '#{File.basename(sprite_path)}': #{size_mb.round(1)} MB"
                end

                # Validate image format
                validate_image_format(sprite_path, "sprite '#{File.basename(sprite_path)}'", result)
              end
            end
          end
        end

        # Validates asset file formats
        private def validate_asset_formats(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          # Check for unsupported formats
          unsupported_extensions = [] of String

          # Check sprite formats
          assets.sprites.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |file_path|
              ext = File.extname(file_path).downcase
              unless [".png", ".jpg", ".jpeg", ".bmp", ".tga"].includes?(ext)
                unsupported_extensions << "#{File.basename(file_path)} (#{ext})"
              end
            end
          end

          # Check audio formats
          if audio = assets.audio
            (audio.music.values + audio.sounds.values).each do |path|
              full_path = File.expand_path(path, context.base_dir)
              if File.exists?(full_path)
                ext = File.extname(full_path).downcase
                unless [".wav", ".ogg", ".mp3", ".flac"].includes?(ext)
                  unsupported_extensions << "#{File.basename(full_path)} (#{ext})"
                end
              end
            end
          end

          if unsupported_extensions.any?
            result.add_warning("Potentially unsupported file formats found:")
            unsupported_extensions.each { |file| result.add_warning("  - #{file}") }
          end
        end

        # Validates image file format specifics
        private def validate_image_format(file_path : String, description : String, result : ValidationResult)
          ext = File.extname(file_path).downcase

          case ext
          when ".jpg", ".jpeg"
            result.add_performance_hint("#{description} uses JPEG format - consider PNG for better quality")
          when ".bmp"
            result.add_performance_hint("#{description} uses BMP format - consider PNG for smaller file size")
          when ".tga"
            result.add_warning("#{description} uses TGA format - may not be supported on all platforms")
          end
        end

        # Validates audio file format specifics
        private def validate_audio_format(file_path : String, description : String, result : ValidationResult)
          ext = File.extname(file_path).downcase

          case ext
          when ".mp3"
            result.add_performance_hint("#{description} uses MP3 format - consider OGG for better compression")
          when ".flac"
            result.add_performance_hint("#{description} uses FLAC format - consider OGG for smaller file size")
          when ".wav"
            file_size = File.size(file_path)
            if file_size > 5_000_000 # 5MB
              result.add_performance_hint("#{description} is a large WAV file - consider OGG compression")
            end
          end
        end

        # Validates shader assets
        private def validate_shader_assets(config : GameConfig, context : ValidationContext, result : ValidationResult)
          if config.features.includes?("shaders")
            # Check for shader files
            shader_dir = File.join(context.base_dir, "shaders")
            if Dir.exists?(shader_dir)
              shader_files = Dir.glob(File.join(shader_dir, "*.{vert,frag,glsl}"))
              if shader_files.empty?
                result.add_warning("Shaders enabled but no shader files found in #{shader_dir}")
              else
                result.add_info("✓ Found #{shader_files.size} shader file(s)")
                validate_shader_files(shader_files, result)
              end
            else
              result.add_warning("Shaders enabled but shaders directory not found")
            end
          end
        end

        # Validates individual shader files
        private def validate_shader_files(shader_files : Array(String), result : ValidationResult)
          vertex_shaders = shader_files.select { |f| File.extname(f) == ".vert" }
          fragment_shaders = shader_files.select { |f| File.extname(f) == ".frag" }

          if vertex_shaders.empty?
            result.add_warning("No vertex shaders (.vert) found - may cause rendering issues")
          end

          if fragment_shaders.empty?
            result.add_warning("No fragment shaders (.frag) found - may cause rendering issues")
          end

          # Check for matching pairs
          vertex_shaders.each do |vert_file|
            base_name = File.basename(vert_file, ".vert")
            matching_frag = fragment_shaders.find { |f| File.basename(f, ".frag") == base_name }
            unless matching_frag
              result.add_warning("Vertex shader '#{base_name}.vert' has no matching fragment shader")
            end
          end
        end

        # Validates asset archive integrity
        def validate_archive_integrity(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          # Check for asset archives or packed files
          archive_patterns = ["*.pak", "*.zip", "*.tar", "*.7z"]
          archive_patterns.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |archive_path|
              begin
                # Basic existence and size check
                size = File.size(archive_path)
                if size == 0
                  result.add_error("Asset archive is empty: #{File.basename(archive_path)}")
                else
                  result.add_info("✓ Asset archive found: #{File.basename(archive_path)} (#{(size / 1_048_576.0).round(1)} MB)")
                end
              rescue ex
                result.add_error("Cannot access asset archive: #{File.basename(archive_path)} - #{ex.message}")
              end
            end
          end
        end

        # Gets asset validation statistics
        def get_asset_stats(config : GameConfig, context : ValidationContext) : Hash(String, Int32 | Float64)
          stats = {} of String => Int32 | Float64
          return stats unless assets = config.assets

          # Count assets by type
          sprite_count = 0
          audio_count = 0
          total_size = 0_i64

          # Count sprites
          assets.sprites.each do |pattern|
            sprite_count += Dir.glob(File.join(context.base_dir, pattern)).size
          end

          # Count audio files
          if audio = assets.audio
            audio_count = audio.music.size + audio.sounds.size
          end

          # Calculate total size
          assets.sprites.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |file|
              total_size += File.size(file) if File.exists?(file)
            end
          end

          if audio = assets.audio
            (audio.music.values + audio.sounds.values).each do |path|
              full_path = File.expand_path(path, context.base_dir)
              total_size += File.size(full_path) if File.exists?(full_path)
            end
          end

          stats["sprite_count"] = sprite_count
          stats["audio_count"] = audio_count
          stats["total_size_mb"] = (total_size / 1_048_576.0).round(2)

          stats
        end

        def priority : Int32
          20 # Run after basic validation but before specialized checks
        end
      end
    end
  end
end
