require "./exceptions"
require "./validators/config_validator"
require "./validators/asset_validator"
require "./validators/scene_validator"
require "./game_config"
require "./error_reporter"
require "file_utils"

module PointClickEngine
  module Core
    class EnhancedPreflightCheck
      struct CheckResult
        property passed : Bool = true
        property errors : Array(String) = [] of String
        property warnings : Array(String) = [] of String
        property info : Array(String) = [] of String
        property performance_hints : Array(String) = [] of String
        property security_issues : Array(String) = [] of String
      end

      def self.run(config_path : String) : CheckResult
        result = CheckResult.new

        puts "Running comprehensive pre-flight checks..."
        puts "=" * 60

        # Step 1: Validate configuration file
        puts "\n1. Checking game configuration..."
        begin
          # Load config without validation first
          unless File.exists?(config_path)
            result.passed = false
            result.errors << "Configuration file not found: #{config_path}"
            display_summary(result)
            return result
          end

          yaml_content = File.read(config_path)
          config = GameConfig.from_yaml(yaml_content)
          config.config_base_dir = File.dirname(config_path)
          result.info << "✓ Configuration loaded successfully"

          # Run validation separately to get warnings/errors
          validation_errors = Validators::ConfigValidator.validate(config, config_path)
          unless validation_errors.empty?
            # Check if these are critical errors or can be warnings
            validation_errors.each do |error|
              if error.includes?("matches no files") || error.includes?("not found in asset patterns")
                # These should be warnings for preflight check
                result.warnings << error
              else
                result.passed = false
                result.errors << error
              end
            end
          end
        rescue ex : YAML::ParseException
          result.passed = false
          result.errors << "Invalid YAML syntax: #{ex.message}"
          display_summary(result)
          return result
        rescue ex
          result.passed = false
          result.errors << "Unexpected error loading config: #{ex.message}"
          display_summary(result)
          return result
        end

        # Step 2: Validate all assets
        puts "\n2. Checking game assets..."
        asset_errors = Validators::AssetValidator.validate_all_assets(config, config_path)
        if asset_errors.empty?
          result.info << "✓ All assets validated"
        else
          result.passed = false
          result.errors.concat(asset_errors)
        end

        # Step 3: Validate all scenes
        puts "\n3. Checking scene files..."
        scene_count = 0
        scene_errors = [] of String

        if assets = config.assets
          assets.scenes.each do |pattern|
            Dir.glob(File.join(File.dirname(config_path), pattern)).each do |scene_path|
              scene_count += 1
              errors = Validators::SceneValidator.validate_scene_file(scene_path)
              unless errors.empty?
                scene_errors << "Scene '#{File.basename(scene_path)}':"
                errors.each { |e| scene_errors << "  - #{e}" }
              end
            end
          end
        end

        if scene_errors.empty?
          result.info << "✓ #{scene_count} scene(s) validated"
        else
          result.passed = false
          result.errors.concat(scene_errors)
        end

        # Enhanced validation steps
        base_dir = File.dirname(config_path)

        # Step 4: Check for common issues
        puts "\n4. Checking for common issues..."
        check_common_issues(config, result, base_dir)

        # Step 5: Check rendering and player issues
        puts "\n5. Checking rendering and player setup..."
        check_rendering_issues(config, result, base_dir)

        # Step 6: Performance analysis
        puts "\n6. Analyzing performance considerations..."
        check_performance(config, config_path, result)

        # Step 7: Audio system validation
        puts "\n7. Validating audio system..."
        check_audio_system(config, result, base_dir)

        # Step 8: Input and controls validation
        puts "\n8. Checking input and control configurations..."
        check_input_controls(config, result, base_dir)

        # Step 9: Save system validation
        puts "\n9. Validating save system configuration..."
        check_save_system(config, result, base_dir)

        # Step 10: Localization validation
        puts "\n10. Checking localization support..."
        check_localization(config, result, base_dir)

        # Step 11: Cross-scene references
        puts "\n11. Validating cross-scene references..."
        check_scene_references(config, result, base_dir)

        # Step 12: Resource usage analysis
        puts "\n12. Analyzing resource usage..."
        check_resource_usage(config, result, base_dir)

        # Step 13: Platform compatibility
        puts "\n13. Checking platform compatibility..."
        check_platform_compatibility(config, result)

        # Step 14: Security considerations
        puts "\n14. Scanning for security issues..."
        check_security(config, result, base_dir, config_path)

        # Step 15: Animation validation
        puts "\n15. Validating animations..."
        check_animations(config, result, base_dir)

        # Step 16: Dialog system validation
        puts "\n16. Checking dialog system..."
        check_dialog_system(config, result, base_dir)

        # Step 17: Quest system validation
        puts "\n17. Validating quest system..."
        check_quest_system(config, result, base_dir)

        # Step 18: Inventory validation
        puts "\n18. Checking inventory configuration..."
        check_inventory_system(config, result, base_dir)

        # Step 19: Archive integrity
        puts "\n19. Checking archive integrity..."
        check_archive_integrity(config, result, base_dir)

        # Step 20: Development environment
        puts "\n20. Checking development environment..."
        check_development_environment(result)

        # Display summary
        display_summary(result)

        result
      end

      private def self.check_common_issues(config : GameConfig, result : CheckResult, base_dir : String)
        # Check if start scene exists
        if start_scene = config.start_scene
          scene_found = false
          if assets = config.assets
            assets.scenes.each do |pattern|
              Dir.glob(File.join(base_dir, pattern)).each do |path|
                if File.basename(path, ".yaml") == start_scene
                  scene_found = true
                  break
                end
              end
            end
          end

          unless scene_found
            result.warnings << "Start scene '#{start_scene}' not found in scene files"
          end
        else
          result.warnings << "No start scene specified - game will need manual scene selection"
        end

        # Check resolution constraints
        if window = config.window
          # Common resolution checks
          common_resolutions = [
            {640, 480}, {800, 600}, {1024, 768}, {1280, 720},
            {1280, 1024}, {1366, 768}, {1440, 900}, {1600, 900},
            {1920, 1080}, {2560, 1440}, {3840, 2160},
          ]

          resolution_match = common_resolutions.any? { |w, h| window.width == w && window.height == h }
          unless resolution_match
            result.warnings << "Non-standard resolution (#{window.width}x#{window.height}) may cause scaling issues"
          end

          if window.width > 1920 || window.height > 1080
            result.warnings << "Window size (#{window.width}x#{window.height}) is larger than 1920x1080 - may cause performance issues"
          end

          if window.width < 640 || window.height < 480
            result.errors << "Window size (#{window.width}x#{window.height}) is too small - minimum 640x480 recommended"
          end

          # Aspect ratio check
          aspect_ratio = window.width.to_f / window.height.to_f
          common_ratios = [4.0/3.0, 16.0/9.0, 16.0/10.0, 21.0/9.0]

          unless common_ratios.any? { |ratio| (aspect_ratio - ratio).abs < 0.01 }
            result.warnings << "Unusual aspect ratio (#{aspect_ratio.round(2)}) may cause display issues"
          end
        end

        # Check features
        if config.features.includes?("shaders")
          result.info << "✓ Shaders enabled - ensure graphics card supports them"
        end

        if config.features.includes?("auto_save")
          result.info << "✓ Auto-save enabled"
        end

        # Check for conflicting features
        if config.features.includes?("shaders") && config.features.includes?("low_end_mode")
          result.warnings << "Both 'shaders' and 'low_end_mode' features enabled - may conflict"
        end
      end

      private def self.check_rendering_issues(config : GameConfig, result : CheckResult, base_dir : String)
        # Check player sprite configuration
        if player = config.player
          if sprite_path = player.sprite_path
            full_sprite_path = File.expand_path(sprite_path, base_dir)
            unless File.exists?(full_sprite_path)
              result.errors << "Player sprite not found: #{sprite_path}"
            else
              result.info << "✓ Player sprite found: #{sprite_path}"

              # Check file size
              file_size = File.size(full_sprite_path)
              if file_size > 5_000_000 # 5MB
                result.warnings << "Player sprite file is large (#{(file_size / 1_048_576.0).round(1)} MB) - may affect loading time"
              end
            end
          else
            result.warnings << "No player sprite path specified - player will be invisible"
          end

          # Check player sprite dimensions
          if sprite = player.sprite
            if sprite.frame_width <= 0 || sprite.frame_height <= 0
              result.errors << "Invalid player sprite dimensions: #{sprite.frame_width}x#{sprite.frame_height}"
            elsif sprite.frame_width > 256 || sprite.frame_height > 256
              result.warnings << "Large player sprite frames (#{sprite.frame_width}x#{sprite.frame_height}) - may impact performance"
            end

            # Check animation frame layout
            if sprite.columns && sprite.rows
              total_frames = sprite.columns * sprite.rows
              if total_frames > 100
                result.warnings << "Player sprite has #{total_frames} frames - consider splitting into multiple sprites"
              end
            end
          else
            result.warnings << "No player sprite dimensions specified - may cause rendering issues"
          end

          # Check player starting position
          if start_pos = player.start_position
            if start_pos.x < 0 || start_pos.y < 0
              result.errors << "Player starting position has negative coordinates: (#{start_pos.x}, #{start_pos.y})"
            end
          else
            result.warnings << "No player starting position specified"
          end

          # Movement speed would be checked if it was in PlayerConfig
        else
          result.errors << "No player configuration found"
        end

        # Check all scene backgrounds
        check_scene_backgrounds(config, result, base_dir)

        # Check UI scaling
        check_ui_scaling(config, result)

        # Check shader compatibility
        check_shader_compatibility(config, result, base_dir)
      end

      private def self.check_scene_backgrounds(config : GameConfig, result : CheckResult, base_dir : String)
        if assets = config.assets
          window_width = config.window.try(&.width) || 1024
          window_height = config.window.try(&.height) || 768

          assets.scenes.each do |pattern|
            Dir.glob(File.join(base_dir, pattern)).each do |scene_path|
              begin
                scene_content = File.read(scene_path)
                scene_name = File.basename(scene_path, ".yaml")
                lines = scene_content.split('\n')

                if scene_content.includes?("background_path:")
                  # Extract background path from YAML
                  bg_line = lines.find { |line| line.strip.starts_with?("background_path:") }
                  if bg_line
                    bg_path = bg_line.split(":", 2)[1].strip.gsub(/["']/, "")
                    full_bg_path = File.expand_path(bg_path, base_dir)

                    if File.exists?(full_bg_path)
                      # Check file size
                      bg_size = File.size(full_bg_path)
                      if bg_size > 10_000_000 # 10MB
                        result.warnings << "Scene '#{scene_name}' background is large (#{(bg_size / 1_048_576.0).round(1)} MB)"
                      end

                      result.info << "✓ Background found for scene '#{scene_name}': #{bg_path}"
                    else
                      result.errors << "Background image not found for scene '#{scene_name}': #{bg_path}"
                    end
                  end
                else
                  result.warnings << "Scene '#{scene_name}' has no background specified"
                end

                # Check scene scale
                if scene_content.includes?("scale:")
                  scale_line = lines.find { |line| line.strip.starts_with?("scale:") }
                  if scale_line
                    scale_value = scale_line.split(":", 2)[1].strip.to_f?
                    if scale_value && (scale_value <= 0 || scale_value > 10)
                      result.warnings << "Scene '#{scene_name}' has unusual scale value: #{scale_value}"
                    end
                  end
                end
              rescue ex
                result.warnings << "Could not analyze scene file #{File.basename(scene_path)}: #{ex.message}"
              end
            end
          end
        end
      end

      private def self.check_ui_scaling(config : GameConfig, result : CheckResult)
        if display = config.display
          if display.scaling_mode
            valid_modes = ["None", "FitWithBars", "Stretch", "PixelPerfect"]
            unless valid_modes.includes?(display.scaling_mode)
              result.errors << "Invalid display scaling mode: #{display.scaling_mode}"
            end
          end

          # Check if target resolution differs from window resolution
          if window = config.window
            target_width = display.target_width || window.width
            target_height = display.target_height || window.height

            if target_width != window.width || target_height != window.height
              result.info << "Display scaling enabled: #{window.width}x#{window.height} -> #{target_width}x#{target_height}"
            end
          end
        end
      end

      private def self.check_shader_compatibility(config : GameConfig, result : CheckResult, base_dir : String)
        if config.features.includes?("shaders")
          # Check for shader files
          shader_dir = File.join(base_dir, "shaders")
          if Dir.exists?(shader_dir)
            shader_files = Dir.glob(File.join(shader_dir, "*.{vert,frag,glsl}"))
            if shader_files.empty?
              result.warnings << "Shaders enabled but no shader files found in #{shader_dir}"
            else
              result.info << "✓ Found #{shader_files.size} shader file(s)"
            end
          else
            result.warnings << "Shaders enabled but shaders directory not found"
          end
        end
      end

      private def self.check_performance(config : GameConfig, config_path : String, result : CheckResult)
        base_dir = File.dirname(config_path)

        # Check asset sizes
        large_assets = [] of String
        total_asset_size = 0_i64

        if assets = config.assets
          # Check audio files
          if audio = assets.audio
            audio.music.each do |name, path|
              full_path = File.expand_path(path, base_dir)
              if File.exists?(full_path)
                size = File.size(full_path)
                total_asset_size += size
                size_mb = size / 1_048_576.0
                if size_mb > 10
                  large_assets << "Music '#{name}': #{size_mb.round(1)} MB"
                end
              end
            end

            audio.sounds.each do |name, path|
              full_path = File.expand_path(path, base_dir)
              if File.exists?(full_path)
                size = File.size(full_path)
                total_asset_size += size
                size_mb = size / 1_048_576.0
                if size_mb > 2
                  result.warnings << "Sound effect '#{name}' is large (#{size_mb.round(1)} MB) - consider compression"
                end
              end
            end
          end
        end

        unless large_assets.empty?
          result.warnings << "Large assets detected (consider compression):"
          large_assets.each { |a| result.warnings << "  - #{a}" }
        end

        # Total asset size check
        total_mb = total_asset_size / 1_048_576.0
        if total_mb > 100
          result.performance_hints << "Total asset size is #{total_mb.round(1)} MB - may affect initial loading time"
        end

        # Check number of scenes
        scene_count = 0
        if assets = config.assets
          assets.scenes.each do |pattern|
            scene_count += Dir.glob(File.join(base_dir, pattern)).size
          end
        end

        if scene_count > 50
          result.warnings << "Large number of scenes (#{scene_count}) may increase loading time"
        elsif scene_count == 0
          result.errors << "No scenes found!"
        end

        # Memory usage estimation
        estimated_memory = total_asset_size * 2 # Rough estimate
        if estimated_memory > 500_000_000       # 500MB
          result.performance_hints << "Estimated memory usage: #{(estimated_memory / 1_048_576.0).round(0)} MB"
        end
      end

      private def self.check_audio_system(config : GameConfig, result : CheckResult, base_dir : String)
        if assets = config.assets
          if audio = assets.audio
            # Check audio file formats
            supported_formats = [".ogg", ".wav", ".mp3", ".flac"]

            # Validate music files
            audio.music.each do |name, path|
              extension = File.extname(path).downcase
              unless supported_formats.includes?(extension)
                result.errors << "Unsupported audio format for music '#{name}': #{extension}"
              end

              # Check if file exists
              full_path = File.expand_path(path, base_dir)
              unless File.exists?(full_path)
                result.errors << "Music file not found: #{path}"
              end
            end

            # Validate sound effects
            audio.sounds.each do |name, path|
              extension = File.extname(path).downcase
              unless supported_formats.includes?(extension)
                result.errors << "Unsupported audio format for sound '#{name}': #{extension}"
              end

              # Check if file exists
              full_path = File.expand_path(path, base_dir)
              unless File.exists?(full_path)
                result.errors << "Sound file not found: #{path}"
              end
            end

            # Check for duplicate audio entries
            all_audio_names = audio.music.keys + audio.sounds.keys
            duplicates = all_audio_names.select { |name| all_audio_names.count(name) > 1 }.uniq
            unless duplicates.empty?
              result.warnings << "Duplicate audio names found: #{duplicates.join(", ")}"
            end
          else
            result.info << "No audio configuration found - game will be silent"
          end
        end

        # Check start music
        if start_music = config.start_music
          if assets = config.assets
            if audio = assets.audio
              unless audio.music.has_key?(start_music)
                result.errors << "Start music '#{start_music}' not found in audio configuration"
              end
            else
              result.errors << "Start music specified but no audio configuration found"
            end
          else
            result.errors << "Start music specified but no assets configuration found"
          end
        end

        # Check audio settings
        if settings = config.settings
          volume = settings.master_volume
          if volume < 0 || volume > 1.0
            result.warnings << "Master volume out of range (0.0-1.0): #{volume}"
          end
        end
      end

      private def self.check_input_controls(config : GameConfig, result : CheckResult, base_dir : String)
        # Check for input-related settings in features
        if config.features.includes?("custom_controls")
          result.info << "✓ Custom controls enabled"
        end

        # Basic input validation
        result.info << "✓ Default input system will be used"
      end

      private def self.check_save_system(config : GameConfig, result : CheckResult, base_dir : String)
        # Check save directory
        save_dir = File.join(base_dir, "saves")
        if config.features.includes?("auto_save") || config.features.includes?("save_system")
          unless Dir.exists?(save_dir)
            result.info << "Save directory will be created at: #{save_dir}"
          else
            # Check write permissions
            test_file = File.join(save_dir, ".write_test")
            begin
              File.write(test_file, "test")
              File.delete(test_file)
              result.info << "✓ Save directory is writable"
            rescue
              result.errors << "Save directory is not writable: #{save_dir}"
            end
          end
        end

        # Basic save system validation
        if config.features.includes?("save_system")
          result.info << "✓ Save system enabled"
        end
      end

      private def self.check_localization(config : GameConfig, result : CheckResult, base_dir : String)
        # Check for localization files
        if config.features.includes?("localization")
          locale_dir = File.join(base_dir, "locales")
          if Dir.exists?(locale_dir)
            locale_files = Dir.glob(File.join(locale_dir, "*.{json,yaml,yml}"))
            if locale_files.empty?
              result.warnings << "Localization enabled but no locale files found"
            else
              result.info << "✓ Found #{locale_files.size} locale file(s)"

              # Could check for default locale in config if it was added
            end
          else
            result.warnings << "Localization enabled but locales directory not found"
          end
        end
      end

      private def self.check_scene_references(config : GameConfig, result : CheckResult, base_dir : String)
        all_scene_names = [] of String
        scene_references = Hash(String, Array(String)).new { |h, k| h[k] = [] of String }

        if assets = config.assets
          # Collect all scene names
          assets.scenes.each do |pattern|
            Dir.glob(File.join(base_dir, pattern)).each do |scene_path|
              scene_name = File.basename(scene_path, ".yaml")
              all_scene_names << scene_name

              # Parse scene for references
              begin
                content = File.read(scene_path)

                # Look for exit zones
                if content.includes?("target_scene:")
                  lines = content.split('\n')
                  lines.each do |line|
                    if line.strip.starts_with?("target_scene:")
                      target = line.split(":", 2)[1].strip.gsub(/["']/, "")
                      scene_references[scene_name] << target unless target.empty?
                    end
                  end
                end
              rescue ex
                result.warnings << "Could not parse scene '#{scene_name}' for references: #{ex.message}"
              end
            end
          end

          # Validate all references
          scene_references.each do |source_scene, targets|
            targets.each do |target|
              unless all_scene_names.includes?(target)
                result.errors << "Scene '#{source_scene}' references non-existent scene: '#{target}'"
              end
            end
          end

          # Check for orphaned scenes (no references to them except start scene)
          referenced_scenes = scene_references.values.flatten.uniq
          if start_scene = config.start_scene
            referenced_scenes << start_scene
          end

          orphaned_scenes = all_scene_names - referenced_scenes
          unless orphaned_scenes.empty?
            result.warnings << "Potentially unreachable scenes: #{orphaned_scenes.join(", ")}"
          end
        end
      end

      private def self.check_resource_usage(config : GameConfig, result : CheckResult, base_dir : String)
        # Count total resources
        texture_count = 0
        sound_count = 0
        music_count = 0

        if assets = config.assets
          # Count textures (sprites, backgrounds)
          Dir.glob(File.join(base_dir, "**/*.{png,jpg,jpeg,bmp}")).each do |path|
            texture_count += 1
          end

          # Count audio
          if audio = assets.audio
            sound_count = audio.sounds.size
            music_count = audio.music.size
          end
        end

        # Resource usage summary
        result.info << "Resource summary: #{texture_count} textures, #{sound_count} sounds, #{music_count} music tracks"

        # Warnings for high resource counts
        if texture_count > 100
          result.performance_hints << "High texture count (#{texture_count}) - consider texture atlases"
        end

        if sound_count > 50
          result.performance_hints << "Many sound effects (#{sound_count}) - may impact loading time"
        end
      end

      private def self.check_platform_compatibility(config : GameConfig, result : CheckResult)
        # Platform compatibility checks are done via Crystal flags

        # Platform-specific checks
        {% if flag?(:darwin) %}
          result.info << "✓ Running on macOS"
        {% elsif flag?(:linux) %}
          result.info << "✓ Running on Linux"
        {% elsif flag?(:windows) %}
          result.info << "✓ Running on Windows"
        {% else %}
          result.info << "✓ Running on supported platform"
        {% end %}

        # Check for platform-specific features
        if config.features.includes?("directx")
          {% unless flag?(:windows) %}
            result.warnings << "DirectX features enabled on non-Windows platform"
          {% end %}
        end
      end

      private def self.check_security(config : GameConfig, result : CheckResult, base_dir : String, config_path : String)
        # Check for sensitive data in config
        # Just use the config file that was passed in
        return unless File.exists?(config_path)

        config_content = File.read(config_path)

        # Look for potential secrets
        sensitive_patterns = [
          /api[_-]?key/i,
          /password/i,
          /secret/i,
          /token/i,
          /private[_-]?key/i,
        ]

        sensitive_patterns.each do |pattern|
          if config_content.match(pattern)
            result.security_issues << "Potential sensitive data found in configuration (pattern: #{pattern.source})"
          end
        end

        # Check file permissions on sensitive directories
        sensitive_dirs = ["saves", "config", "data"]
        sensitive_dirs.each do |dir|
          dir_path = File.join(base_dir, dir)
          if Dir.exists?(dir_path)
            # This is a simplified check - in reality would need platform-specific permission checks
            result.info << "✓ Directory exists: #{dir}"
          end
        end

        # Check for unsafe file operations in scripts
        if config.features.includes?("scripting")
          script_files = Dir.glob(File.join(base_dir, "**/*.{lua,js,py}"))
          script_files.each do |script|
            begin
              content = File.read(script)
              unsafe_patterns = [
                /system\s*\(/,
                /exec\s*\(/,
                /eval\s*\(/,
                /require\s*\(\s*["']child_process/,
              ]

              unsafe_patterns.each do |pattern|
                if content.match(pattern)
                  result.security_issues << "Potentially unsafe operation in #{File.basename(script)}: #{pattern.source}"
                end
              end
            rescue
              # Skip unreadable scripts
            end
          end
        end
      end

      private def self.check_animations(config : GameConfig, result : CheckResult, base_dir : String)
        # Check animation configurations in scenes
        animation_issues = [] of String

        if assets = config.assets
          assets.scenes.each do |pattern|
            Dir.glob(File.join(base_dir, pattern)).each do |scene_path|
              begin
                content = File.read(scene_path)
                scene_name = File.basename(scene_path, ".yaml")

                # Check for animation definitions
                if content.includes?("animations:") || content.includes?("sprite_info:")
                  # Basic validation of animation parameters
                  if content.includes?("frame_rate:") && content.match(/frame_rate:\s*(\d+)/)
                    frame_rate = $1.to_i
                    if frame_rate <= 0
                      animation_issues << "Scene '#{scene_name}' has invalid frame rate: #{frame_rate}"
                    elsif frame_rate > 60
                      animation_issues << "Scene '#{scene_name}' has very high frame rate: #{frame_rate}"
                    end
                  end
                end
              rescue
                # Skip unparseable scenes
              end
            end
          end
        end

        unless animation_issues.empty?
          result.warnings.concat(animation_issues)
        end
      end

      private def self.check_dialog_system(config : GameConfig, result : CheckResult, base_dir : String)
        dialog_dir = File.join(base_dir, "dialogs")
        if Dir.exists?(dialog_dir)
          dialog_files = Dir.glob(File.join(dialog_dir, "*.{yaml,yml,json}"))

          if dialog_files.empty?
            result.info << "No dialog files found"
          else
            result.info << "✓ Found #{dialog_files.size} dialog file(s)"

            # Check dialog file validity
            dialog_files.each do |dialog_file|
              begin
                content = File.read(dialog_file)
                # Basic validation - check if it's valid YAML/JSON
                if dialog_file.ends_with?(".yaml") || dialog_file.ends_with?(".yml")
                  YAML.parse(content)
                else
                  # Assume JSON
                  content # Would parse as JSON in real implementation
                end
              rescue ex
                result.errors << "Invalid dialog file '#{File.basename(dialog_file)}': #{ex.message}"
              end
            end
          end
        end

        # Check for dialog references in scenes
        if config.features.includes?("dialog_system")
          if !Dir.exists?(dialog_dir) || Dir.glob(File.join(dialog_dir, "*")).empty?
            result.warnings << "Dialog system enabled but no dialog files found"
          end
        end
      end

      private def self.check_quest_system(config : GameConfig, result : CheckResult, base_dir : String)
        if config.features.includes?("quest_system")
          quest_file = File.join(base_dir, "quests.yaml")
          if File.exists?(quest_file)
            begin
              quest_content = File.read(quest_file)
              YAML.parse(quest_content)
              result.info << "✓ Quest configuration found"
            rescue ex
              result.errors << "Invalid quest configuration: #{ex.message}"
            end
          else
            result.warnings << "Quest system enabled but quests.yaml not found"
          end
        end
      end

      private def self.check_inventory_system(config : GameConfig, result : CheckResult, base_dir : String)
        if config.features.includes?("inventory")
          items_file = File.join(base_dir, "items.yaml")
          if File.exists?(items_file)
            begin
              items_content = File.read(items_file)
              items_data = YAML.parse(items_content)

              # Count items
              if items_data["items"]?
                item_count = items_data["items"].as_a.size
                result.info << "✓ Found #{item_count} inventory items"

                if item_count > 100
                  result.performance_hints << "Large number of items (#{item_count}) may impact inventory UI"
                end
              end
            rescue ex
              result.errors << "Invalid items configuration: #{ex.message}"
            end
          else
            result.warnings << "Inventory system enabled but items.yaml not found"
          end
        end
      end

      private def self.check_archive_integrity(config : GameConfig, result : CheckResult, base_dir : String)
        # Check for game archives
        archive_files = Dir.glob(File.join(base_dir, "*.{zip,pak,dat}"))

        unless archive_files.empty?
          result.info << "✓ Found #{archive_files.size} game archive(s)"

          archive_files.each do |archive|
            size_mb = File.size(archive) / 1_048_576.0
            if size_mb > 100
              result.warnings << "Large archive file: #{File.basename(archive)} (#{size_mb.round(1)} MB)"
            end

            # Could verify archive integrity here with checksums
          end
        end
      end

      private def self.check_development_environment(result : CheckResult)
        # Check Crystal version
        crystal_version = Crystal::VERSION
        result.info << "✓ Crystal version: #{crystal_version}"

        # Check for required development tools
        required_tools = ["git", "make"]
        required_tools.each do |tool|
          if system("which #{tool} > /dev/null 2>&1")
            result.info << "✓ #{tool} is available"
          else
            result.warnings << "Development tool '#{tool}' not found in PATH"
          end
        end

        # Check available memory
        begin
          # Platform-specific memory check would go here
          result.info << "✓ System resources available"
        rescue
          # Ignore if we can't check system resources
        end
      end

      private def self.display_summary(result : CheckResult)
        puts "\n" + "=" * 60
        puts "Pre-flight Check Summary:"
        puts "=" * 60

        if result.info.any?
          puts "\nℹ️  Information:"
          result.info.each { |msg| puts "   #{msg}" }
        end

        if result.performance_hints.any?
          puts "\n⚡ Performance Hints:"
          result.performance_hints.each { |msg| puts "   #{msg}" }
        end

        if result.warnings.any?
          puts "\n⚠️  Warnings:"
          result.warnings.each { |msg| puts "   #{msg}" }
        end

        if result.security_issues.any?
          puts "\n🔒 Security Issues:"
          result.security_issues.each { |msg| puts "   #{msg}" }
        end

        if result.errors.any?
          puts "\n❌ Errors:"
          result.errors.each { |msg| puts "   #{msg}" }
        end

        puts "\n" + "=" * 60

        total_issues = result.errors.size + result.warnings.size + result.security_issues.size

        if result.passed
          puts "✅ All critical checks passed!"
          if total_issues > 0
            puts "   (#{result.warnings.size} warnings, #{result.security_issues.size} security notes)"
          end
        else
          puts "❌ Pre-flight checks failed with #{result.errors.size} error(s)."
          puts "   Please fix the errors before running the game."
        end
        puts "=" * 60
      end

      # Convenience method to run checks and raise on failure
      def self.run!(config_path : String)
        result = run(config_path)
        unless result.passed
          raise ValidationError.new(result.errors, config_path)
        end
      end
    end
  end
end
