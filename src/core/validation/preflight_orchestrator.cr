require "./validation_result"
require "./asset_validation_checker"
require "./rendering_validation_checker"
require "./performance_validation_checker"
require "./security_validation_checker"
require "./platform_info_validator"
require "../validators/config_validator"
require "../validators/asset_validator"
require "../validators/scene_validator"
require "../validators/scene_coordinate_validator"

module PointClickEngine
  module Core
    module Validation
      # Orchestrates the execution of all validation components
      #
      # The PreflightOrchestrator coordinates multiple validators to provide
      # comprehensive game configuration validation. It manages validator
      # execution order, result aggregation, and error handling.
      class PreflightOrchestrator
        property validators : Array(BaseValidator)
        property context : ValidationContext?
        property config : GameConfig?

        def initialize
          @validators = [] of BaseValidator
          setup_default_validators
        end

        # Runs all validations on the specified configuration
        def run_all_validations(config_path : String, strict_mode : Bool = false, development_mode : Bool = false) : ValidationResult
          puts "Running comprehensive pre-flight checks..."
          puts "=" * 60

          # Initialize context
          context = ValidationContextFactory.create(config_path, strict_mode, development_mode)
          @context = context

          # Load and validate configuration first
          config_result = load_and_validate_config(config_path, context)
          return config_result unless config_result.passed

          # Run all validators in priority order
          overall_result = ValidationResult.new
          overall_result.merge(config_result)

          sorted_validators = @validators.sort_by(&.priority)

          sorted_validators.each do |validator|
            next unless validator.should_run?(context)

            puts "\n#{get_step_number(validator)}. #{validator.description}..."

            begin
              validator_result = validator.validate(@config.not_nil!, context)
              overall_result.merge(validator_result)

              # Report progress
              if validator_result.errors.any?
                puts "  ❌ #{validator_result.errors.size} error(s) found"
              elsif validator_result.warnings.any?
                puts "  ⚠️  #{validator_result.warnings.size} warning(s) found"
              else
                puts "  ✅ Validation passed"
              end
            rescue ex
              error_message = "Validator '#{validator.name}' failed: #{ex.message}"
              overall_result.add_error(error_message)
              puts "  ❌ #{error_message}"
            end
          end

          # Add summary information
          add_validation_summary(overall_result, context)

          overall_result
        end

        # Runs only specific validators
        def run_specific_validations(config_path : String, validator_names : Array(String)) : ValidationResult
          context = ValidationContextFactory.create(config_path)
          @context = context

          # Load configuration
          config_result = load_and_validate_config(config_path, context)
          return config_result unless config_result.passed

          overall_result = ValidationResult.new
          overall_result.merge(config_result)

          # Run only requested validators
          @validators.each do |validator|
            if validator_names.includes?(validator.name)
              validator_result = validator.validate(@config.not_nil!, context)
              overall_result.merge(validator_result)
            end
          end

          overall_result
        end

        # Adds a custom validator
        def add_validator(validator : BaseValidator)
          @validators << validator
        end

        # Removes a validator by name
        def remove_validator(name : String)
          @validators.reject! { |v| v.name == name }
        end

        # Gets available validator names
        def get_validator_names : Array(String)
          @validators.map(&.name)
        end

        # Runs a quick validation (skips optional checks)
        def run_quick_validation(config_path : String) : ValidationResult
          context = ValidationContextFactory.create(config_path)
          context.skip_optional_checks = true
          context.include_performance_checks = false
          @context = context

          config_result = load_and_validate_config(config_path, context)
          return config_result unless config_result.passed

          overall_result = ValidationResult.new
          overall_result.merge(config_result)

          # Run only critical validators
          critical_validators = @validators.select { |v| v.priority <= 30 }
          critical_validators.each do |validator|
            next unless validator.should_run?(context)

            validator_result = validator.validate(@config.not_nil!, context)
            overall_result.merge(validator_result)
          end

          overall_result
        end

        # Validates only configuration without running full validation
        def validate_config_only(config_path : String) : ValidationResult
          context = ValidationContextFactory.create(config_path)
          load_and_validate_config(config_path, context)
        end

        private def setup_default_validators
          # Add built-in validators in priority order
          @validators << PlatformInfoValidator.new
          @validators << AssetValidationChecker.new
          @validators << SecurityValidationChecker.new
          @validators << RenderingValidationChecker.new
          @validators << PerformanceValidationChecker.new
        end

        private def load_and_validate_config(config_path : String, context : ValidationContext) : ValidationResult
          result = ValidationResult.new

          puts "\n1. Checking game configuration..."

          # Check if file exists
          unless File.exists?(config_path)
            result.add_error("Configuration file not found: #{config_path}")
            return result
          end

          begin
            # Load configuration
            yaml_content = File.read(config_path)
            config = GameConfig.from_yaml(yaml_content)
            config.config_base_dir = File.dirname(config_path)
            @config = config

            result.add_info("✓ Configuration loaded successfully")

            # Run config validation
            validation_errors = Validators::ConfigValidator.validate(config, config_path)
            unless validation_errors.empty?
              validation_errors.each do |error|
                if error.includes?("matches no files") || error.includes?("not found in asset patterns")
                  result.add_warning(error)
                else
                  result.add_error(error)
                end
              end
            end

            # Validate all assets
            asset_errors = Validators::AssetValidator.validate_all_assets(config, config_path)
            if asset_errors.empty?
              result.add_info("✓ All assets validated")
            else
              result.add_errors(asset_errors)
            end

            # Validate scenes
            validate_scenes(config, config_path, result)

            # Validate scene coordinates
            validate_scene_coordinates(config, result)
          rescue ex : YAML::ParseException
            result.add_error("Invalid YAML syntax: #{ex.message}")
          rescue ex
            result.add_error("Unexpected error loading config: #{ex.message}")
          end

          result
        end

        private def validate_scenes(config : GameConfig, config_path : String, result : ValidationResult)
          puts "\n3. Checking scene files..."
          scene_count = 0
          scene_errors = [] of String
          scene_names = [] of String

          if assets = config.assets
            # First pass: collect all scene names
            assets.scenes.each do |pattern|
              Dir.glob(File.join(File.dirname(config_path), pattern)).each do |scene_path|
                scene_names << File.basename(scene_path, ".yaml")
              end
            end

            # Second pass: validate scenes and check references
            assets.scenes.each do |pattern|
              Dir.glob(File.join(File.dirname(config_path), pattern)).each do |scene_path|
                scene_count += 1
                errors = Validators::SceneValidator.validate_scene_file(scene_path)
                unless errors.empty?
                  scene_errors << "Scene '#{File.basename(scene_path)}':"
                  errors.each { |e| scene_errors << "  - #{e}" }
                end

                # Check scene references
                reference_errors = validate_scene_references(scene_path, scene_names)
                scene_errors.concat(reference_errors)
              end
            end
          end

          if scene_errors.empty?
            result.add_info("✓ #{scene_count} scene(s) validated")
          else
            result.add_errors(scene_errors)
          end

          # Validate player spawn position against start scene
          validate_player_spawn_position(config, config_path, result)
        end

        private def validate_scene_references(scene_path : String, scene_names : Array(String)) : Array(String)
          errors = [] of String
          scene_name = File.basename(scene_path, ".yaml")

          begin
            yaml_content = File.read(scene_path)
            scene_data = YAML.parse(yaml_content)

            # Check hotspots with target_scene (exit type)
            if hotspots = scene_data["hotspots"]?
              hotspots.as_a.each_with_index do |hotspot, idx|
                if target_scene = hotspot["target_scene"]?
                  target = target_scene.as_s
                  unless scene_names.includes?(target)
                    errors << "Scene '#{scene_name}' hotspot ##{idx + 1} references non-existent scene '#{target}'"
                  end
                end
              end
            end

            # Check exits with target_scene
            if exits = scene_data["exits"]?
              exits.as_a.each_with_index do |exit, idx|
                if target_scene = exit["target_scene"]?
                  target = target_scene.as_s
                  unless scene_names.includes?(target)
                    errors << "Scene '#{scene_name}' exit ##{idx + 1} references non-existent scene '#{target}'"
                  end
                end
              end
            end
          rescue ex
            # Ignore parse errors, those are handled elsewhere
          end

          errors
        end

        # Validates player spawn position against start scene walkable areas
        private def validate_player_spawn_position(config : GameConfig, config_path : String, result : ValidationResult)
          player = config.player
          return unless player

          start_pos = player.start_position
          return unless start_pos

          start_scene = config.start_scene
          return unless start_scene && !start_scene.empty?

          # Find start scene file
          base_dir = File.dirname(config_path)
          scene_path : String? = nil

          if assets = config.assets
            assets.scenes.each do |pattern|
              Dir.glob(File.join(base_dir, pattern)).each do |path|
                if File.basename(path, ".yaml") == start_scene
                  scene_path = path
                  break
                end
              end
              break if scene_path
            end
          end

          return unless scene_path && File.exists?(scene_path)

          begin
            yaml_content = File.read(scene_path)
            scene_data = YAML.parse(yaml_content)

            # Get walkable areas
            if walkable_areas = scene_data["walkable_areas"]?
              if regions = walkable_areas["regions"]?
                walkable_regions = [] of Array({x: Float64, y: Float64})
                non_walkable_regions = [] of Array({x: Float64, y: Float64})

                regions.as_a.each do |region|
                  vertices = [] of {x: Float64, y: Float64}
                  if region_vertices = region["vertices"]?
                    region_vertices.as_a.each do |v|
                      x = v["x"]?.try(&.as_f) || v["x"]?.try(&.as_i.to_f64) || 0.0
                      y = v["y"]?.try(&.as_f) || v["y"]?.try(&.as_i.to_f64) || 0.0
                      vertices << {x: x, y: y}
                    end
                  end

                  is_walkable = region["walkable"]?.try(&.as_bool) != false

                  if is_walkable
                    walkable_regions << vertices
                  else
                    non_walkable_regions << vertices
                  end
                end

                spawn_x = start_pos.x.to_f64
                spawn_y = start_pos.y.to_f64

                # Check if spawn is in a walkable region
                in_walkable = walkable_regions.any? { |r| point_in_polygon?(spawn_x, spawn_y, r) }

                # Check if spawn is in a non-walkable region
                in_non_walkable = non_walkable_regions.any? { |r| point_in_polygon?(spawn_x, spawn_y, r) }

                if in_non_walkable
                  # Find nearest walkable position
                  suggested = find_nearest_walkable_position(spawn_x, spawn_y, walkable_regions, non_walkable_regions)
                  result.add_error("Player starting position (#{spawn_x.to_i}, #{spawn_y.to_i}) is in a non-walkable area. Consider moving to (#{suggested[:x].to_i}, #{suggested[:y].to_i})")
                elsif !in_walkable && walkable_regions.any?
                  result.add_error("Player starting position (#{spawn_x.to_i}, #{spawn_y.to_i}) is outside walkable areas. Consider moving the spawn position.")
                else
                  # Check clearance from non-walkable areas
                  radius = calculate_player_radius(player)
                  too_close = non_walkable_regions.any? { |r| point_too_close_to_polygon?(spawn_x, spawn_y, radius, r) }

                  if too_close
                    result.add_error("Player starting position is too close to non-walkable areas (character radius: #{radius.to_i}). Consider moving the spawn position further away.")
                  else
                    result.add_info("Player starting position is in walkable area with adequate clearance")
                  end
                end
              end
            end
          rescue ex
            # Silently handle parse errors
          end
        end

        # Calculate player radius based on sprite dimensions
        private def calculate_player_radius(player : GameConfig::PlayerConfig) : Float64
          if sprite = player.sprite
            frame_width = (sprite.frame_width || 32).to_f64
            frame_height = (sprite.frame_height || 32).to_f64
            scale = player.scale || 1.0
            Math.min(frame_width, frame_height) * scale / 2.0
          else
            16.0 # Default radius
          end
        end

        # Point in polygon using ray casting
        private def point_in_polygon?(x : Float64, y : Float64, polygon : Array({x: Float64, y: Float64})) : Bool
          return false if polygon.size < 3

          inside = false
          j = polygon.size - 1

          polygon.size.times do |i|
            xi, yi = polygon[i][:x], polygon[i][:y]
            xj, yj = polygon[j][:x], polygon[j][:y]

            if ((yi > y) != (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi)
              inside = !inside
            end
            j = i
          end

          inside
        end

        # Check if a point is too close to polygon edges
        private def point_too_close_to_polygon?(x : Float64, y : Float64, radius : Float64, polygon : Array({x: Float64, y: Float64})) : Bool
          return false if polygon.size < 3

          # Check distance to each edge
          j = polygon.size - 1
          polygon.size.times do |i|
            x1, y1 = polygon[i][:x], polygon[i][:y]
            x2, y2 = polygon[j][:x], polygon[j][:y]

            dist = point_to_line_distance(x, y, x1, y1, x2, y2)
            return true if dist < radius

            j = i
          end

          false
        end

        # Distance from point to line segment
        private def point_to_line_distance(px : Float64, py : Float64, x1 : Float64, y1 : Float64, x2 : Float64, y2 : Float64) : Float64
          dx = x2 - x1
          dy = y2 - y1
          length_sq = dx * dx + dy * dy

          if length_sq == 0
            # Line segment is a point
            return Math.sqrt((px - x1) ** 2 + (py - y1) ** 2)
          end

          t = Math.max(0.0, Math.min(1.0, ((px - x1) * dx + (py - y1) * dy) / length_sq))

          proj_x = x1 + t * dx
          proj_y = y1 + t * dy

          Math.sqrt((px - proj_x) ** 2 + (py - proj_y) ** 2)
        end

        # Find nearest walkable position from a given point
        private def find_nearest_walkable_position(x : Float64, y : Float64, walkable : Array(Array({x: Float64, y: Float64})), non_walkable : Array(Array({x: Float64, y: Float64}))) : {x: Float64, y: Float64}
          best_pos = {x: x, y: y}
          best_dist = Float64::MAX

          # Try points in a grid around the spawn
          (-200..200).step(20) do |dx|
            (-200..200).step(20) do |dy|
              test_x = x + dx
              test_y = y + dy

              in_walkable = walkable.any? { |r| point_in_polygon?(test_x, test_y, r) }
              in_non_walkable = non_walkable.any? { |r| point_in_polygon?(test_x, test_y, r) }

              if in_walkable && !in_non_walkable
                dist = Math.sqrt(dx.to_f64 ** 2 + dy.to_f64 ** 2)
                if dist < best_dist
                  best_dist = dist
                  best_pos = {x: test_x, y: test_y}
                end
              end
            end
          end

          best_pos
        end

        private def validate_scene_coordinates(config : GameConfig, result : ValidationResult)
          puts "\n3.5. Checking scene coordinate consistency..."
          coord_validator = Validators::SceneCoordinateValidator.new
          coord_result = coord_validator.validate(config)

          result.add_errors(coord_result.errors)
          result.add_warnings(coord_result.warnings)
          result.add_infos(coord_result.infos)
        end

        private def get_step_number(validator : BaseValidator) : Int32
          # Calculate step number based on validator priority and position
          sorted_validators = @validators.sort_by(&.priority)
          base_step = 4 # Steps 1-3 are config, assets, scenes

          index = sorted_validators.index(validator)
          return base_step + (index || 0) + 1
        end

        private def add_validation_summary(result : ValidationResult, context : ValidationContext)
          # Add context information
          result.add_info("Validation completed for: #{File.basename(context.config_path)}")
          result.add_info("Base directory: #{context.base_dir}")

          if context.strict_mode
            result.add_info("Strict mode: enabled")
          end

          if context.development_mode
            result.add_info("Development mode: enabled")
          end

          # Add performance summary if available
          if context.include_performance_checks && @config
            performance_validator = @validators.find { |v| v.is_a?(PerformanceValidationChecker) }
            if performance_validator.is_a?(PerformanceValidationChecker)
              estimates = performance_validator.get_performance_estimates(@config.not_nil!, context)
              if estimates.any?
                result.add_info("Performance estimates:")
                estimates.each do |key, value|
                  # Convert underscore_case to human readable format
                  humanized_key = key.gsub('_', ' ').split.map(&.capitalize).join(' ')
                  result.add_info("  #{humanized_key}: #{value}")
                end
              end
            end
          end
        end

        # Creates a validation report
        def create_report(result : ValidationResult, format : String = "text") : String
          case format
          when "text"
            create_text_report(result)
          when "json"
            create_json_report(result)
          when "markdown"
            create_markdown_report(result)
          else
            create_text_report(result)
          end
        end

        private def create_text_report(result : ValidationResult) : String
          report = String::Builder.new

          report << "VALIDATION REPORT\n"
          report << "=" * 50 << "\n\n"
          report << "Status: #{result.passed ? "PASSED" : "FAILED"}\n"
          report << "Total Issues: #{result.issue_count}\n\n"

          if result.errors.any?
            report << "ERRORS (#{result.errors.size}):\n"
            result.errors.each { |error| report << "  ❌ #{error}\n" }
            report << "\n"
          end

          if result.warnings.any?
            report << "WARNINGS (#{result.warnings.size}):\n"
            result.warnings.each { |warning| report << "  ⚠️  #{warning}\n" }
            report << "\n"
          end

          if result.security_issues.any?
            report << "SECURITY ISSUES (#{result.security_issues.size}):\n"
            result.security_issues.each { |issue| report << "  🔒 #{issue}\n" }
            report << "\n"
          end

          if result.performance_hints.any?
            report << "PERFORMANCE HINTS (#{result.performance_hints.size}):\n"
            result.performance_hints.each { |hint| report << "  💡 #{hint}\n" }
            report << "\n"
          end

          if result.info.any?
            report << "INFORMATION (#{result.info.size}):\n"
            result.info.each { |info| report << "  ℹ️  #{info}\n" }
          end

          report.to_s
        end

        private def create_json_report(result : ValidationResult) : String
          {
            "status"            => result.passed ? "passed" : "failed",
            "summary"           => result.summary,
            "errors"            => result.errors,
            "warnings"          => result.warnings,
            "security_issues"   => result.security_issues,
            "performance_hints" => result.performance_hints,
            "info"              => result.info,
            "total_issues"      => result.issue_count,
          }.to_json
        end

        private def create_markdown_report(result : ValidationResult) : String
          report = String::Builder.new

          report << "# Validation Report\n\n"
          report << "**Status:** #{result.passed ? "✅ PASSED" : "❌ FAILED"}\n"
          report << "**Total Issues:** #{result.issue_count}\n\n"

          if result.errors.any?
            report << "## ❌ Errors (#{result.errors.size})\n\n"
            result.errors.each { |error| report << "- #{error}\n" }
            report << "\n"
          end

          if result.warnings.any?
            report << "## ⚠️ Warnings (#{result.warnings.size})\n\n"
            result.warnings.each { |warning| report << "- #{warning}\n" }
            report << "\n"
          end

          if result.security_issues.any?
            report << "## 🔒 Security Issues (#{result.security_issues.size})\n\n"
            result.security_issues.each { |issue| report << "- #{issue}\n" }
            report << "\n"
          end

          if result.performance_hints.any?
            report << "## 💡 Performance Hints (#{result.performance_hints.size})\n\n"
            result.performance_hints.each { |hint| report << "- #{hint}\n" }
            report << "\n"
          end

          report.to_s
        end
      end
    end
  end
end
