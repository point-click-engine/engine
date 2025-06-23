require "./exceptions"
require "./validators/config_validator"
require "./validators/asset_validator"
require "./validators/scene_validator"
require "./game_config"

module PointClickEngine
  module Core
    class PreflightCheck
      struct CheckResult
        property passed : Bool = true
        property errors : Array(String) = [] of String
        property warnings : Array(String) = [] of String
        property info : Array(String) = [] of String
      end

      def self.run(config_path : String) : CheckResult
        result = CheckResult.new

        puts "Running pre-flight checks..."
        puts "=" * 50

        # Step 1: Validate configuration file
        puts "\n1. Checking game configuration..."
        begin
          config = GameConfig.from_file(config_path)
          result.info << "✓ Configuration loaded successfully"
        rescue ex : ConfigError
          result.passed = false
          result.errors << "Configuration Error: #{ex.message}"
          display_summary(result)
          return result
        rescue ex : ValidationError
          result.passed = false
          result.errors.concat(ex.errors)
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

        # Step 4: Check for common issues
        puts "\n4. Checking for common issues..."
        base_dir = File.dirname(config_path)
        check_common_issues(config, result, base_dir)

        # Step 5: Performance warnings
        puts "\n5. Checking performance considerations..."
        check_performance(config, config_path, result)

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

        # Check resolution
        if window = config.window
          if window.width > 1920 || window.height > 1080
            result.warnings << "Window size (#{window.width}x#{window.height}) is larger than 1920x1080 - may cause performance issues"
          end
        end

        # Check features
        if config.features.includes?("shaders")
          result.info << "✓ Shaders enabled - ensure graphics card supports them"
        end

        if config.features.includes?("auto_save")
          result.info << "✓ Auto-save enabled"
        end
      end

      private def self.check_performance(config : GameConfig, config_path : String, result : CheckResult)
        base_dir = File.dirname(config_path)

        # Check asset sizes
        large_assets = [] of String

        if assets = config.assets
          # Check audio files
          if audio = assets.audio
            audio.music.each do |name, path|
              full_path = File.expand_path(path, base_dir)
              if File.exists?(full_path)
                size_mb = File.size(full_path) / 1_048_576.0
                if size_mb > 10
                  large_assets << "Music '#{name}': #{size_mb.round(1)} MB"
                end
              end
            end
          end
        end

        unless large_assets.empty?
          result.warnings << "Large assets detected (consider compression):"
          large_assets.each { |a| result.warnings << "  - #{a}" }
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
        end
      end

      private def self.display_summary(result : CheckResult)
        puts "\n" + "=" * 50
        puts "Pre-flight Check Summary:"
        puts "=" * 50

        if result.info.any?
          puts "\nℹ️  Information:"
          result.info.each { |msg| puts "   #{msg}" }
        end

        if result.warnings.any?
          puts "\n⚠️  Warnings:"
          result.warnings.each { |msg| puts "   #{msg}" }
        end

        if result.errors.any?
          puts "\n❌ Errors:"
          result.errors.each { |msg| puts "   #{msg}" }
        end

        puts "\n" + "=" * 50
        if result.passed
          puts "✅ All checks passed! Game is ready to run."
        else
          puts "❌ Pre-flight checks failed with #{result.errors.size} error(s)."
          puts "   Please fix the errors before running the game."
        end
        puts "=" * 50
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
