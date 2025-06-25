require "./validation_result"
require "../game_config"

module PointClickEngine
  module Core
    module Validation
      # Validates performance considerations and optimization opportunities
      #
      # The PerformanceValidationChecker analyzes the game configuration
      # for potential performance issues and provides optimization recommendations.
      class PerformanceValidationChecker < BaseValidator
        def description : String
          "Analyzes performance considerations and provides optimization recommendations"
        end

        def validate(config : GameConfig, context : ValidationContext) : ValidationResult
          result = ValidationResult.new

          return result unless context.include_performance_checks

          analyze_asset_performance(config, context, result)
          analyze_rendering_performance(config, result)
          analyze_memory_usage(config, context, result)
          analyze_audio_performance(config, context, result)
          provide_optimization_hints(config, result)

          result
        end

        # Analyzes asset-related performance considerations
        private def analyze_asset_performance(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          large_assets = [] of String
          total_asset_size = 0_i64
          texture_memory_usage = 0_i64

          # Analyze audio asset performance
          if audio = assets.audio
            analyze_audio_asset_performance(audio, context, result, large_assets, pointerof(total_asset_size))
          end

          # Analyze sprite asset performance
          analyze_sprite_asset_performance(assets, context, result, large_assets, pointerof(total_asset_size), pointerof(texture_memory_usage))

          # Report overall findings
          report_asset_performance_summary(large_assets, total_asset_size, texture_memory_usage, result)
        end

        # Analyzes audio asset performance
        private def analyze_audio_asset_performance(audio : AudioConfig, context : ValidationContext, result : ValidationResult, large_assets : Array(String), total_size : Int64*)
          # Check music files
          audio.music.each do |name, path|
            full_path = File.expand_path(path, context.base_dir)
            if File.exists?(full_path)
              size = File.size(full_path)
              total_size.value += size
              size_mb = size / 1_048_576.0

              if size_mb > 10
                large_assets << "Music '#{name}': #{size_mb.round(1)} MB"
                result.add_performance_hint("Consider compressing music '#{name}' or using OGG format")
              end

              # Check file format for performance
              ext = File.extname(full_path).downcase
              case ext
              when ".wav"
                if size_mb > 2
                  result.add_performance_hint("Large WAV file '#{name}' - consider OGG compression")
                end
              when ".mp3"
                result.add_performance_hint("MP3 file '#{name}' - OGG format may provide better compression")
              end
            end
          end

          # Check sound files
          audio.sounds.each do |name, path|
            full_path = File.expand_path(path, context.base_dir)
            if File.exists?(full_path)
              size = File.size(full_path)
              total_size.value += size
              size_mb = size / 1_048_576.0

              if size_mb > 5
                large_assets << "Sound '#{name}': #{size_mb.round(1)} MB"
                result.add_performance_hint("Sound effect '#{name}' is large - consider shorter duration or compression")
              end
            end
          end
        end

        # Analyzes sprite asset performance
        private def analyze_sprite_asset_performance(assets : AssetsConfig, context : ValidationContext, result : ValidationResult, large_assets : Array(String), total_size : Int64*, texture_memory : Int64*)
          sprite_count = 0
          large_texture_count = 0

          assets.sprites.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |sprite_path|
              if File.exists?(sprite_path)
                sprite_count += 1
                size = File.size(sprite_path)
                total_size.value += size
                size_mb = size / 1_048_576.0

                if size_mb > 5.0
                  large_assets << "Sprite '#{File.basename(sprite_path)}': #{size_mb.round(1)} MB"
                  large_texture_count += 1
                end

                # Estimate texture memory usage (rough calculation)
                # Assume 32-bit RGBA for worst case
                estimated_texture_memory = estimate_texture_memory_usage(sprite_path)
                texture_memory.value += estimated_texture_memory

                if estimated_texture_memory > 16_777_216 # 16MB
                  result.add_performance_hint("Sprite '#{File.basename(sprite_path)}' may use significant GPU memory")
                end
              end
            end
          end

          if large_texture_count > 10
            result.add_performance_hint("Many large textures (#{large_texture_count}) - consider texture atlasing")
          end

          result.add_info("Total sprites analyzed: #{sprite_count}")
        end

        # Estimates texture memory usage for a sprite
        private def estimate_texture_memory_usage(sprite_path : String) : Int64
          # This is a rough estimation - in reality you'd need image dimensions
          file_size = File.size(sprite_path)

          # Rough heuristic: uncompressed texture is typically 10-20x larger than file size
          # depending on compression and format
          file_size * 15
        end

        # Reports asset performance summary
        private def report_asset_performance_summary(large_assets : Array(String), total_asset_size : Int64, texture_memory_usage : Int64, result : ValidationResult)
          if large_assets.any?
            result.add_performance_hint("Large assets found (#{large_assets.size}):")
            large_assets.first(5).each { |asset| result.add_performance_hint("  - #{asset}") }
            if large_assets.size > 5
              result.add_performance_hint("  ... and #{large_assets.size - 5} more")
            end
          end

          total_size_mb = total_asset_size / 1_048_576.0
          if total_size_mb > 500
            result.add_performance_hint("Total asset size is large: #{total_size_mb.round(1)} MB")
            result.add_performance_hint("Consider asset streaming or compression for mobile platforms")
          end

          texture_memory_mb = texture_memory_usage / 1_048_576.0
          if texture_memory_mb > 256
            result.add_performance_hint("Estimated texture memory usage: #{texture_memory_mb.round(1)} MB")
            result.add_performance_hint("Consider texture compression or reducing texture sizes")
          end
        end

        # Analyzes rendering performance considerations
        private def analyze_rendering_performance(config : GameConfig, result : ValidationResult)
          if window = config.window
            width = window.width
            height = window.height
            pixel_count = width * height

            # High resolution warning
            if pixel_count > 3_840 * 2_160 # 4K
              result.add_performance_hint("Very high resolution (#{width}x#{height}) - may impact performance on lower-end devices")
            elsif pixel_count > 1_920 * 1_080 # 1080p
              result.add_performance_hint("High resolution (#{width}x#{height}) - ensure adequate GPU performance")
            end

            # Check aspect ratio for potential scaling issues
            aspect_ratio = width.to_f / height.to_f
            if aspect_ratio > 3.0 || aspect_ratio < 0.3
              result.add_performance_hint("Unusual aspect ratio (#{aspect_ratio.round(2)}) may cause scaling performance issues")
            end
          end

          # Check for performance-impacting features
          if display = config.display
            if display.vsync == false
              result.add_performance_hint("VSync disabled - may cause screen tearing but can improve responsiveness")
            end
          end

          # Check shader usage
          if config.features.includes?("shaders")
            result.add_performance_hint("Shaders enabled - ensure adequate GPU performance for target platforms")
          end
        end

        # Analyzes memory usage patterns
        private def analyze_memory_usage(config : GameConfig, context : ValidationContext, result : ValidationResult)
          estimated_memory_usage = 0_i64

          # Estimate based on assets
          if assets = config.assets
            # Audio memory (rough estimate)
            if audio = assets.audio
              audio_memory = estimate_audio_memory_usage(audio, context)
              estimated_memory_usage += audio_memory
            end

            # Texture memory (already calculated above)
            texture_memory = estimate_total_texture_memory(assets, context)
            estimated_memory_usage += texture_memory
          end

          # Scene memory
          scene_memory = estimate_scene_memory_usage(config, context)
          estimated_memory_usage += scene_memory

          # Report memory analysis
          total_memory_mb = estimated_memory_usage / 1_048_576.0
          if total_memory_mb > 1024 # 1GB
            result.add_performance_hint("Estimated memory usage is high: #{total_memory_mb.round(1)} MB")
            result.add_performance_hint("Consider asset streaming or loading optimization for memory-constrained devices")
          elsif total_memory_mb > 512 # 512MB
            result.add_performance_hint("Estimated memory usage: #{total_memory_mb.round(1)} MB - monitor for mobile compatibility")
          else
            result.add_info("Estimated memory usage: #{total_memory_mb.round(1)} MB")
          end
        end

        # Estimates audio memory usage
        private def estimate_audio_memory_usage(audio : AudioConfig, context : ValidationContext) : Int64
          total_audio_memory = 0_i64

          # Music typically streams, so estimate buffer size
          music_count = audio.music.size
          total_audio_memory += music_count * 4_194_304 # 4MB buffer per music track

          # Sound effects are usually loaded into memory
          audio.sounds.each do |name, path|
            full_path = File.expand_path(path, context.base_dir)
            if File.exists?(full_path)
              file_size = File.size(full_path)
              # Estimate uncompressed size (roughly 10x for compressed audio)
              total_audio_memory += file_size * 10
            end
          end

          total_audio_memory
        end

        # Estimates total texture memory usage
        private def estimate_total_texture_memory(assets : AssetsConfig, context : ValidationContext) : Int64
          total_texture_memory = 0_i64

          assets.sprites.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |sprite_path|
              if File.exists?(sprite_path)
                total_texture_memory += estimate_texture_memory_usage(sprite_path)
              end
            end
          end

          total_texture_memory
        end

        # Estimates scene memory usage
        private def estimate_scene_memory_usage(config : GameConfig, context : ValidationContext) : Int64
          return 0_i64 unless assets = config.assets

          scene_count = 0
          assets.scenes.each do |pattern|
            scene_count += Dir.glob(File.join(context.base_dir, pattern)).size
          end

          # Rough estimate: 1MB per scene for data structures, scripts, etc.
          scene_count * 1_048_576_i64
        end

        # Analyzes audio performance considerations
        private def analyze_audio_performance(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets
          return unless audio = assets.audio

          # Check simultaneous audio capacity
          total_audio_files = audio.music.size + audio.sounds.size
          if total_audio_files > 100
            result.add_performance_hint("Large number of audio files (#{total_audio_files}) - consider audio pooling")
          end

          # Check for multiple music tracks (may indicate streaming needs)
          if audio.music.size > 10
            result.add_performance_hint("Many music tracks (#{audio.music.size}) - ensure proper streaming implementation")
          end

          # Check sound effect count
          if audio.sounds.size > 50
            result.add_performance_hint("Many sound effects (#{audio.sounds.size}) - consider sound pooling and limits")
          end
        end

        # Provides general optimization hints
        private def provide_optimization_hints(config : GameConfig, result : ValidationResult)
          hints = [] of String

          # Platform-specific hints
          hints << "Consider texture compression for mobile platforms"
          hints << "Implement level-of-detail (LOD) for complex scenes"
          hints << "Use object pooling for frequently created/destroyed objects"
          hints << "Implement frustum culling for large scenes"
          hints << "Consider audio compression and streaming for large audio files"

          # Feature-specific hints
          if config.features.includes?("networking")
            hints << "Implement efficient network protocols and data compression"
          end

          if config.features.includes?("physics")
            hints << "Optimize physics simulation step size and collision detection"
          end

          # Add general performance hints
          result.add_performance_hint("General optimization recommendations:")
          hints.each { |hint| result.add_performance_hint("  - #{hint}") }
        end

        # Gets performance benchmark estimates
        def get_performance_estimates(config : GameConfig, context : ValidationContext) : Hash(String, Float64 | Int32)
          estimates = {} of String => Float64 | Int32

          # Estimate loading time (very rough)
          if assets = config.assets
            total_size = 0_i64

            assets.sprites.each do |pattern|
              Dir.glob(File.join(context.base_dir, pattern)).each do |file|
                total_size += File.size(file) if File.exists?(file)
              end
            end

            # Rough estimate: 1MB per second loading time
            estimates["estimated_loading_time_seconds"] = (total_size / 1_048_576.0).round(1)
          end

          # Estimate memory usage
          estimated_memory = analyze_memory_usage_numeric(config, context)
          estimates["estimated_memory_mb"] = (estimated_memory / 1_048_576.0).round(1)

          # Estimate performance tier requirement
          if window = config.window
            pixel_count = window.width * window.height
            if pixel_count > 1_920 * 1_080
              estimates["recommended_performance_tier"] = 3 # High-end
            elsif pixel_count > 1_280 * 720
              estimates["recommended_performance_tier"] = 2 # Mid-range
            else
              estimates["recommended_performance_tier"] = 1 # Low-end
            end
          end

          estimates
        end

        # Numeric memory usage analysis for estimates
        private def analyze_memory_usage_numeric(config : GameConfig, context : ValidationContext) : Int64
          memory_usage = 0_i64

          if assets = config.assets
            if audio = assets.audio
              memory_usage += estimate_audio_memory_usage(audio, context)
            end
            memory_usage += estimate_total_texture_memory(assets, context)
          end

          memory_usage += estimate_scene_memory_usage(config, context)
          memory_usage
        end

        def priority : Int32
          40 # Run after core validations
        end
      end
    end
  end
end
