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

        # Step 4.5: Check rendering and player issues
        puts "\n4.5. Checking rendering and player setup..."
        check_rendering_issues(config, result, base_dir)

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

      private def self.check_rendering_issues(config : GameConfig, result : CheckResult, base_dir : String)
        # Check player sprite configuration
        if player = config.player
          if sprite_path = player.sprite_path
            full_sprite_path = File.expand_path(sprite_path, base_dir)
            unless File.exists?(full_sprite_path)
              result.errors << "Player sprite not found: #{sprite_path}"
            else
              result.info << "✓ Player sprite found: #{sprite_path}"
            end
          else
            result.warnings << "No player sprite path specified - player will be invisible"
          end

          # Check player sprite dimensions
          if sprite = player.sprite
            if sprite.frame_width <= 0 || sprite.frame_height <= 0
              result.errors << "Invalid player sprite dimensions: #{sprite.frame_width}x#{sprite.frame_height}"
            end
          else
            result.warnings << "No player sprite dimensions specified - may cause rendering issues"
          end
        else
          result.errors << "No player configuration found"
        end

        # Check scene background scaling issues
        if assets = config.assets
          window_width = config.window.try(&.width) || 1024
          window_height = config.window.try(&.height) || 768

          assets.scenes.each do |pattern|
            Dir.glob(File.join(base_dir, pattern)).each do |scene_path|
              begin
                scene_content = File.read(scene_path)
                if scene_content.includes?("background_path:")
                  # Extract background path from YAML
                  lines = scene_content.split('\n')
                  bg_line = lines.find { |line| line.strip.starts_with?("background_path:") }
                  if bg_line
                    bg_path = bg_line.split(":", 2)[1].strip.gsub(/["']/, "")
                    full_bg_path = File.expand_path(bg_path, base_dir)
                    
                    if File.exists?(full_bg_path)
                      # Check if background dimensions might cause scaling issues
                      # Note: This is a heuristic check - actual image dimensions would require image library
                      scene_name = File.basename(scene_path, ".yaml")
                      result.info << "✓ Background found for scene '#{scene_name}': #{bg_path}"
                      
                      # Check if it's a common problematic size
                      if bg_path.includes?("320x180") || bg_path.includes?("small")
                        result.warnings << "Scene '#{scene_name}' background may be too small (#{bg_path}) for window size #{window_width}x#{window_height}"
                      end
                    else
                      result.errors << "Background image not found for scene '#{File.basename(scene_path)}': #{bg_path}"
                    end
                  end
                end
              rescue ex
                result.warnings << "Could not analyze scene file #{File.basename(scene_path)}: #{ex.message}"
              end
            end
          end
        end

        # Check start scene player spawn position and walkable areas
        if start_scene = config.start_scene
          if assets = config.assets
            assets.scenes.each do |pattern|
              Dir.glob(File.join(base_dir, pattern)).each do |scene_path|
                if File.basename(scene_path, ".yaml") == start_scene
                  begin
                    scene_content = File.read(scene_path)
                    unless scene_content.includes?("spawn_position") || scene_content.includes?("start_position")
                      result.warnings << "Start scene '#{start_scene}' may not have proper player spawn position defined"
                    end
                    
                    # Check if player starting position is in walkable area
                    check_player_walkable_position(config, scene_content, start_scene, result)
                  rescue ex
                    result.warnings << "Could not check spawn position in start scene: #{ex.message}"
                  end
                  break
                end
              end
            end
          end
        end
      end

      private def self.check_player_walkable_position(config : GameConfig, scene_content : String, scene_name : String, result : CheckResult)
        # Get player starting position from config
        return unless player = config.player
        return unless start_pos = player.start_position
        
        player_x = start_pos.x
        player_y = start_pos.y
        
        # Parse walkable areas from scene YAML content
        walkable_areas = parse_walkable_areas(scene_content)
        return if walkable_areas.empty?
        
        # Check if player position is in any walkable area
        in_walkable_area = false
        in_non_walkable_area = false
        
        walkable_areas.each do |area|
          if point_in_polygon?(player_x, player_y, area[:vertices])
            if area[:walkable]
              in_walkable_area = true
            else
              in_non_walkable_area = true
            end
          end
        end
        
        if in_non_walkable_area
          result.errors << "Player starting position (#{player_x}, #{player_y}) is in a non-walkable area in scene '#{scene_name}'"
        elsif !in_walkable_area && walkable_areas.any? { |a| a[:walkable] }
          result.warnings << "Player starting position (#{player_x}, #{player_y}) may not be in any walkable area in scene '#{scene_name}'"
        else
          result.info << "✓ Player starting position is in walkable area in scene '#{scene_name}'"
        end
      rescue ex
        result.warnings << "Could not validate player walkable position in scene '#{scene_name}': #{ex.message}"
      end

      private def self.parse_walkable_areas(scene_content : String) : Array(NamedTuple(walkable: Bool, vertices: Array(NamedTuple(x: Float32, y: Float32))))
        areas = [] of NamedTuple(walkable: Bool, vertices: Array(NamedTuple(x: Float32, y: Float32)))
        
        # Simple YAML parsing for walkable_areas section
        lines = scene_content.split('\n')
        in_walkable_areas = false
        in_regions = false
        current_area : NamedTuple(walkable: Bool, vertices: Array(NamedTuple(x: Float32, y: Float32)))? = nil
        
        lines.each do |line|
          stripped = line.strip
          
          if stripped.starts_with?("walkable_areas:")
            in_walkable_areas = true
            next
          elsif in_walkable_areas && stripped.starts_with?("regions:")
            in_regions = true
            next
          elsif in_walkable_areas && in_regions
            # Check if we're leaving the regions section
            if stripped != "" && !stripped.starts_with?("-") && !stripped.starts_with?("name:") && 
               !stripped.starts_with?("walkable:") && !stripped.starts_with?("vertices:") && 
               !stripped.starts_with?("{x:") && !stripped.starts_with?("x:")
              break
            end
            
            if stripped.starts_with?("- name:")
              # Save previous area if exists
              if area = current_area
                areas << area
              end
              # Start new area
              current_area = {walkable: true, vertices: [] of NamedTuple(x: Float32, y: Float32)}
            elsif stripped.starts_with?("walkable:")
              if area = current_area
                walkable_value = stripped.split(":", 2)[1].strip
                current_area = {walkable: walkable_value == "true", vertices: area[:vertices]}
              end
            elsif stripped.includes?("x:") && stripped.includes?("y:")
              # Parse vertex like "- {x: 100, y: 350}" or "x: 100" and "y: 350" on separate lines
              if area = current_area
                x_match = stripped.match(/x:\s*(\d+(?:\.\d+)?)/)
                y_match = stripped.match(/y:\s*(\d+(?:\.\d+)?)/)
                
                if x_match && y_match
                  x = x_match[1].to_f32
                  y = y_match[1].to_f32
                  vertices = area[:vertices].dup
                  vertices << {x: x, y: y}
                  current_area = {walkable: area[:walkable], vertices: vertices}
                end
              end
            end
          end
        end
        
        # Add the last area
        if area = current_area
          areas << area
        end
        
        areas
      rescue ex
        # Return empty array if parsing fails
        [] of NamedTuple(walkable: Bool, vertices: Array(NamedTuple(x: Float32, y: Float32)))
      end

      private def self.point_in_polygon?(x : Float32, y : Float32, vertices : Array(NamedTuple(x: Float32, y: Float32))) : Bool
        return false if vertices.size < 3
        
        # Ray casting algorithm
        inside = false
        j = vertices.size - 1
        
        vertices.each_with_index do |vertex, i|
          if ((vertices[i][:y] > y) != (vertices[j][:y] > y)) &&
             (x < (vertices[j][:x] - vertices[i][:x]) * (y - vertices[i][:y]) / (vertices[j][:y] - vertices[i][:y]) + vertices[i][:x])
            inside = !inside
          end
          j = i
        end
        
        inside
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
