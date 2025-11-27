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

          analyze_scene_backgrounds(config, context, result)
          analyze_asset_performance(config, context, result)
          analyze_rendering_performance(config, result)
          analyze_memory_usage(config, context, result)
          analyze_audio_performance(config, context, result)
          analyze_scene_complexity(config, context, result)
          validate_audio_volume_settings(config, result)
          validate_feature_compatibility(config, result)
          provide_optimization_hints(config, result)

          result
        end

        # Analyzes scene background images for performance issues
        private def analyze_scene_backgrounds(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          assets.scenes.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |scene_path|
              next unless File.exists?(scene_path) && scene_path.ends_with?(".yaml")

              begin
                scene_content = File.read(scene_path)
                if match = scene_content.match(/background_path:\s*["']?([^"'\n]+)["']?/)
                  background_path = match[1].strip.gsub(/^["']|["']$/, "")
                  full_path = File.join(context.base_dir, background_path)

                  if File.exists?(full_path)
                    size = File.size(full_path)
                    size_mb = size / 1_048_576.0
                    scene_name = File.basename(scene_path, ".yaml")

                    if size_mb > 10.0
                      result.add_warning("Scene '#{scene_name}' background is large (#{size_mb.round(1)} MB)")
                      result.add_performance_hint("Consider compressing large background image in scene '#{scene_name}'")
                    elsif size_mb > 5.0
                      result.add_performance_hint("Background in scene '#{scene_name}' is moderately large (#{size_mb.round(1)} MB)")
                    end

                    # Check for resolution mismatch if window config exists
                    if window = config.window
                      window_pixels = window.width * window.height
                      # Estimate image resolution from file size (rough heuristic)
                      # Assume ~4 bytes per pixel for uncompressed, PNG compresses ~2-5x
                      estimated_pixels = (size * 3).to_i64 # Conservative estimate
                      if estimated_pixels > window_pixels * 4
                        result.add_performance_hint("Background '#{File.basename(background_path)}' may have higher resolution than needed for #{window.width}x#{window.height} window - consider downscaling")
                      end
                    end
                  end
                end
              rescue
                # Ignore parse errors
              end
            end
          end
        end

        # Analyzes asset-related performance considerations
        private def analyze_asset_performance(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          large_assets = [] of String
          total_asset_size = 0_i64
          texture_memory_usage = 0_i64
          total_asset_count = 0

          # Analyze audio asset performance
          if audio = assets.audio
            analyze_audio_asset_performance(audio, context, result, large_assets, pointerof(total_asset_size))
          end

          # Count and analyze all PNG/image files in common asset directories
          ["test_assets", "assets", "sprites", "images", "backgrounds"].each do |asset_dir|
            full_dir = File.join(context.base_dir, asset_dir)
            if Dir.exists?(full_dir)
              Dir.glob(File.join(full_dir, "**/*.{png,jpg,jpeg,bmp,gif}")).each do |file|
                total_asset_count += 1
                if File.exists?(file)
                  size = File.size(file)
                  total_asset_size += size
                  texture_memory_usage += estimate_texture_memory_usage(file)
                  size_mb = size / 1_048_576.0
                  if size_mb > 5.0
                    large_assets << "#{File.basename(file)}: #{size_mb.round(1)} MB"
                  end
                end
              end
            end
          end

          # Warn about excessive asset count
          if total_asset_count > 50
            result.add_performance_hint("Many asset files (#{total_asset_count}) found - consider using asset bundling or atlasing")
          end

          # Analyze audio referenced in scene files
          analyze_scene_audio_references(config, context, result)

          # Report overall findings
          report_asset_performance_summary(large_assets, total_asset_size, texture_memory_usage, result)
        end

        # Analyzes audio files referenced in scene YAML files
        private def analyze_scene_audio_references(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          assets.scenes.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |scene_path|
              next unless File.exists?(scene_path) && scene_path.ends_with?(".yaml")

              begin
                scene_content = File.read(scene_path)

                # Check for audio references in scenes
                if match = scene_content.match(/background_music:\s*["']?([^"'\n]+)["']?/)
                  audio_path = match[1].strip.gsub(/^["']|["']$/, "")
                  full_path = File.join(context.base_dir, audio_path)

                  if File.exists?(full_path)
                    size = File.size(full_path)
                    size_mb = size / 1_048_576.0
                    ext = File.extname(full_path).downcase

                    if size_mb > 20.0
                      result.add_performance_hint("Large audio file '#{File.basename(audio_path)}' (#{size_mb.round(1)} MB) - consider compression")
                    end

                    if ext == ".wav" && size_mb > 3.0
                      result.add_performance_hint("Large WAV audio file '#{File.basename(audio_path)}' - consider compression to OGG format")
                    end
                  end
                end
              rescue
                # Ignore parse errors
              end
            end
          end
        end

        # Analyzes audio asset performance
        private def analyze_audio_asset_performance(audio : GameConfig::AudioConfig, context : ValidationContext, result : ValidationResult, large_assets : Array(String), total_size : Int64*)
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
        private def analyze_sprite_asset_performance(assets : GameConfig::AssetsConfig, context : ValidationContext, result : ValidationResult, large_assets : Array(String), total_size : Int64*, texture_memory : Int64*)
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
          texture_memory = 0_i64

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

            # Report texture memory specifically
            texture_memory_mb = texture_memory / 1_048_576.0
            if texture_memory_mb > 0
              result.add_info("Estimated texture memory usage: #{texture_memory_mb.round(1)} MB")
            end
          end

          # Scene memory
          scene_memory = estimate_scene_memory_usage(config, context)
          estimated_memory_usage += scene_memory

          # Report memory analysis
          total_memory_mb = estimated_memory_usage / 1_048_576.0
          if total_memory_mb > 1024 # 1GB
            result.add_performance_hint("Estimated memory usage is high (#{total_memory_mb.round(1)} MB) - potential memory pressure on lower-end devices")
            result.add_performance_hint("Consider asset streaming or loading optimization for memory-constrained devices")
          elsif total_memory_mb > 512 # 512MB
            result.add_performance_hint("Estimated memory usage (#{total_memory_mb.round(1)} MB) - monitor for memory pressure on mobile devices")
          elsif total_memory_mb > 256 # 256MB
            result.add_performance_hint("Estimated memory usage: #{total_memory_mb.round(1)} MB - acceptable for desktop but monitor for mobile")
          else
            result.add_info("Estimated memory usage: #{total_memory_mb.round(1)} MB")
          end
        end

        # Estimates audio memory usage
        private def estimate_audio_memory_usage(audio : GameConfig::AudioConfig, context : ValidationContext) : Int64
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
        private def estimate_total_texture_memory(assets : GameConfig::AssetsConfig, context : ValidationContext) : Int64
          total_texture_memory = 0_i64

          # Process sprites
          assets.sprites.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |sprite_path|
              if File.exists?(sprite_path)
                total_texture_memory += estimate_texture_memory_usage(sprite_path)
              end
            end
          end

          # Process scene backgrounds
          assets.scenes.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |scene_path|
              if File.exists?(scene_path) && scene_path.ends_with?(".yaml")
                begin
                  scene_content = File.read(scene_path)
                  if match = scene_content.match(/background_path:\s*(.+)/)
                    background_path = match[1].strip
                    full_path = File.join(context.base_dir, background_path)
                    if File.exists?(full_path)
                      total_texture_memory += estimate_texture_memory_usage(full_path)
                    end
                  end
                rescue
                  # Ignore errors reading scene files
                end
              end
            end
          end

          total_texture_memory
        end

        # Estimates scene memory usage
        private def estimate_scene_memory_usage(config : GameConfig, context : ValidationContext) : Int64
          return 0_i64 unless assets = config.assets

          scene_count = 0_i64
          assets.scenes.each do |pattern|
            scene_count += Dir.glob(File.join(context.base_dir, pattern)).size.to_i64
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

          # Check individual audio file sizes
          audio.music.each do |name, path|
            full_path = File.expand_path(path, context.base_dir)
            if File.exists?(full_path)
              size = File.size(full_path)
              size_mb = size / 1_048_576.0
              ext = File.extname(full_path).downcase

              if size_mb > 20.0
                result.add_performance_hint("Large audio file '#{name}' (#{size_mb.round(1)} MB) - consider compression or streaming")
              end

              if ext == ".wav" && size_mb > 5.0
                result.add_performance_hint("Large WAV audio file '#{name}' - consider OGG or MP3 compression")
              end
            end
          end

          audio.sounds.each do |name, path|
            full_path = File.expand_path(path, context.base_dir)
            if File.exists?(full_path)
              size = File.size(full_path)
              size_mb = size / 1_048_576.0
              ext = File.extname(full_path).downcase

              if size_mb > 10.0
                result.add_performance_hint("Large sound effect '#{name}' (#{size_mb.round(1)} MB) - consider compression")
              end

              if ext == ".wav" && size_mb > 2.0
                result.add_performance_hint("Large WAV sound '#{name}' - consider converting to compressed format")
              end
            end
          end
        end

        # Analyzes scene complexity for performance considerations
        private def analyze_scene_complexity(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          # Check target FPS setting from window config
          target_fps = config.window.try(&.target_fps) || 60

          assets.scenes.each do |pattern|
            Dir.glob(File.join(context.base_dir, pattern)).each do |scene_path|
              next unless File.exists?(scene_path) && scene_path.ends_with?(".yaml")

              begin
                scene_content = File.read(scene_path)
                scene_name = File.basename(scene_path, ".yaml")
                scene_data = YAML.parse(scene_content)

                # Count hotspots
                hotspot_count = 0
                if hotspots = scene_data["hotspots"]?
                  hotspot_count = hotspots.as_a.size
                end

                # Count characters
                character_count = 0
                if characters = scene_data["characters"]?
                  character_count = characters.as_a.size
                end

                # Count interactive objects
                object_count = 0
                if objects = scene_data["objects"]?
                  object_count = objects.as_a.size
                end

                total_entities = hotspot_count + character_count + object_count

                # Warn about complex scenes
                if total_entities > 50
                  result.add_performance_hint("Scene '#{scene_name}' has #{total_entities} entities - may impact performance at #{target_fps} fps")
                end

                if hotspot_count > 100
                  result.add_performance_hint("Scene '#{scene_name}' has many hotspots (#{hotspot_count}) - consider reducing for better performance")
                end

                # Calculate estimated scene load time
                scene_total_size = estimate_scene_total_asset_size(scene_path, scene_content, context)
                if scene_total_size > 20 * 1024 * 1024 # 20MB
                  load_time_estimate = scene_total_size / (10.0 * 1024 * 1024) # Assume 10MB/s load speed
                  result.add_performance_hint("Scene '#{scene_name}' may have slow loading time (estimated #{load_time_estimate.round(1)}s)")
                end
              rescue
                # Ignore parse errors
              end
            end
          end

          # High FPS warning
          if target_fps > 60
            result.add_performance_hint("Targeting #{target_fps} fps - ensure performance optimization for high frame rate rendering")
          end
        end

        # Estimate total asset size for a scene
        private def estimate_scene_total_asset_size(scene_path : String, scene_content : String, context : ValidationContext) : Int64
          total_size = 0_i64

          # Background
          if match = scene_content.match(/background_path:\s*["']?([^"'\n]+)["']?/)
            bg_path = File.join(context.base_dir, match[1].strip.gsub(/^["']|["']$/, ""))
            total_size += File.size(bg_path) if File.exists?(bg_path)
          end

          # Audio in scene
          if match = scene_content.match(/background_music:\s*["']?([^"'\n]+)["']?/)
            audio_path = File.join(context.base_dir, match[1].strip.gsub(/^["']|["']$/, ""))
            total_size += File.size(audio_path) if File.exists?(audio_path)
          end

          total_size
        end

        # Audio volume validation is now handled by UserSettings validation
        # This method is kept for compatibility but does nothing
        private def validate_audio_volume_settings(config : GameConfig, result : ValidationResult)
          # Audio volume settings have been moved to UserSettings
          # Validation is handled separately when UserSettings.validate is called
        end

        # Validates feature compatibility and conflicts
        private def validate_feature_compatibility(config : GameConfig, result : ValidationResult)
          features = config.features

          # Check for conflicting features
          conflicting_pairs = {
            {"shaders", "low_end_mode"}            => "Shaders and low-end mode conflict - shaders require GPU capabilities",
            {"high_quality_audio", "low_end_mode"} => "High quality audio and low-end mode conflict - consider audio quality settings",
            {"networking", "offline_mode"}         => "Networking and offline mode conflict - clarify intended behavior",
            {"physics", "simple_mode"}             => "Advanced physics and simple mode conflict - choose appropriate complexity level",
          }

          conflicting_pairs.each do |pair, message|
            feature1, feature2 = pair
            if features.includes?(feature1) && features.includes?(feature2)
              result.add_warning("Feature conflict detected: #{message}")
            end
          end

          # Check for performance-heavy feature combinations
          heavy_features = features.select { |f| ["shaders", "physics", "networking", "high_quality_audio"].includes?(f) }
          if heavy_features.size >= 3
            result.add_performance_hint("Multiple performance-heavy features enabled (#{heavy_features.join(", ")}) - ensure adequate system requirements")
          end

          # Check mobile compatibility
          mobile_incompatible = features.select { |f| ["shaders", "high_quality_audio", "physics"].includes?(f) }
          if mobile_incompatible.size >= 2
            result.add_performance_hint("Features may impact mobile performance: #{mobile_incompatible.join(", ")}")
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
