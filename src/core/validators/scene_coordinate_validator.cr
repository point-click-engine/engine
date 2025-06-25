require "../validation_result"
require "../../scenes/scene"
require "../game_config"

module PointClickEngine
  module Core
    module Validators
      # Validates that scene coordinates are consistent and logical
      class SceneCoordinateValidator
        def validate(config : GameConfig) : ValidationResult
          result = ValidationResult.new

          # Get expected display dimensions
          display_width = config.window.try(&.width) || 1024
          display_height = config.window.try(&.height) || 768

          # Load and validate each scene
          if scene_patterns = config.assets.try(&.scenes)
            scene_patterns.each do |pattern|
              # Use current directory if config_path is not available
              base_dir = Dir.current
              full_pattern = pattern

              Dir.glob(full_pattern).each do |scene_path|
                validate_scene_file(scene_path, display_width, display_height, result)
              end
            end
          end

          result
        end

        private def validate_scene_file(path : String, display_width : Int32, display_height : Int32, result : ValidationResult)
          scene_name = File.basename(path, ".yaml")

          begin
            yaml_content = File.read(path)
            scene_data = YAML.parse(yaml_content)

            # Check logical dimensions if specified
            logical_width = scene_data["logical_width"]?.try(&.as_i) || display_width
            logical_height = scene_data["logical_height"]?.try(&.as_i) || display_height

            # Validate logical dimensions
            if logical_width <= 0 || logical_height <= 0
              result.add_error("Scene '#{scene_name}': Invalid logical dimensions (#{logical_width}x#{logical_height})")
            end

            if logical_width < 640 || logical_height < 480
              result.add_warning("Scene '#{scene_name}': Logical dimensions (#{logical_width}x#{logical_height}) are smaller than recommended minimum (640x480)")
            end

            # Check if logical dimensions are explicitly set
            if !scene_data["logical_width"]? || !scene_data["logical_height"]?
              result.add_info("Scene '#{scene_name}': Using default logical dimensions (#{logical_width}x#{logical_height}). Consider explicitly setting logical_width and logical_height.")
            end

            # Validate walkable areas
            if walkable_data = scene_data["walkable_areas"]?
              if regions = walkable_data["regions"]?
                regions.as_a.each do |region|
                  region_name = region["name"]?.try(&.as_s) || "unnamed"

                  if vertices = region["vertices"]?
                    vertices.as_a.each_with_index do |vertex, i|
                      x = vertex["x"].as_f
                      y = vertex["y"].as_f

                      if x < 0 || x > logical_width
                        result.add_warning("Scene '#{scene_name}': Region '#{region_name}' vertex #{i} X coordinate (#{x}) outside logical width (0-#{logical_width})")
                      end

                      if y < 0 || y > logical_height
                        result.add_warning("Scene '#{scene_name}': Region '#{region_name}' vertex #{i} Y coordinate (#{y}) outside logical height (0-#{logical_height})")
                      end
                    end
                  end
                end
              end
            end

            # Validate hotspots
            if hotspots = scene_data["hotspots"]?
              hotspots.as_a.each do |hotspot|
                hotspot_name = hotspot["name"]?.try(&.as_s) || "unnamed"

                if x = hotspot["x"]?
                  if y = hotspot["y"]?
                    if width = hotspot["width"]?
                      if height = hotspot["height"]?
                        hx = x.as_f
                        hy = y.as_f
                        hw = width.as_f
                        hh = height.as_f

                        if hx < 0 || hx + hw > logical_width
                          result.add_warning("Scene '#{scene_name}': Hotspot '#{hotspot_name}' extends outside logical width")
                        end

                        if hy < 0 || hy + hh > logical_height
                          result.add_warning("Scene '#{scene_name}': Hotspot '#{hotspot_name}' extends outside logical height")
                        end
                      end
                    end
                  end
                end
              end
            end

            # Validate character positions
            if characters = scene_data["characters"]?
              characters.as_a.each do |character|
                char_name = character["name"]?.try(&.as_s) || "unnamed"

                if position = character["position"]?
                  if x = position["x"]?
                    if y = position["y"]?
                      char_x = x.as_f
                      char_y = y.as_f

                      if char_x < 0 || char_x > logical_width
                        result.add_warning("Scene '#{scene_name}': Character '#{char_name}' X position (#{char_x}) outside logical width (0-#{logical_width})")
                      end

                      if char_y < 0 || char_y > logical_height
                        result.add_warning("Scene '#{scene_name}': Character '#{char_name}' Y position (#{char_y}) outside logical height (0-#{logical_height})")
                      end
                    end
                  end
                end
              end
            end

            # Check if background path exists but warn about texture dependency
            if bg_path = scene_data["background_path"]?
              result.add_info("Scene '#{scene_name}' uses texture '#{bg_path.as_s}' - coordinates should not depend on texture size")
            end
          rescue ex
            result.add_error("Failed to validate scene '#{scene_name}': #{ex.message}")
          end
        end
      end
    end
  end
end
