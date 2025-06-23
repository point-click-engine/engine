require "../exceptions"
require "yaml"

module PointClickEngine
  module Core
    module Validators
      class SceneValidator
        def self.validate_scene_file(path : String) : Array(String)
          errors = [] of String

          unless File.exists?(path)
            errors << "Scene file not found: #{path}"
            return errors
          end

          begin
            yaml_content = File.read(path)
            scene_data = YAML.parse(yaml_content)
            scene_name = File.basename(path, ".yaml")

            # Validate required fields
            unless scene_data["name"]?
              errors << "Missing required field 'name'"
            else
              name = scene_data["name"].as_s
              if name.empty?
                errors << "Scene name cannot be empty"
              elsif name != scene_name
                errors << "Scene name '#{name}' doesn't match filename '#{scene_name}'"
              end
            end

            # Validate background
            if background = scene_data["background_path"]?
              if background.as_s.empty?
                errors << "Background path cannot be empty"
              end
            else
              errors << "Missing required field 'background_path'"
            end

            # Validate scale
            if scale = scene_data["scale"]?
              scale_val = scale.as_f.to_f32
              if scale_val <= 0 || scale_val > 10
                errors << "Scale must be between 0 and 10 (got #{scale_val})"
              end
            end

            # Validate navigation settings
            if scene_data["enable_pathfinding"]?.try(&.as_bool)
              if cell_size = scene_data["navigation_cell_size"]?
                size = cell_size.as_i
                if size <= 0 || size > 100
                  errors << "Navigation cell size must be between 1 and 100 (got #{size})"
                end
              end
            end

            # Validate hotspots
            if hotspots = scene_data["hotspots"]?
              errors.concat(validate_hotspots(hotspots.as_a))
            end

            # Validate walkable areas
            if areas = scene_data["walkable_areas"]?
              errors.concat(validate_walkable_areas_object(areas))
            end

            # Validate exits
            if exits = scene_data["exits"]?
              errors.concat(validate_exits(exits.as_a))
            end

            # Validate scale zones
            if zones = scene_data["scale_zones"]?
              errors.concat(validate_scale_zones(zones.as_a))
            end

            # Validate characters
            if characters = scene_data["characters"]?
              errors.concat(validate_characters(characters.as_a))
            end
          rescue ex : YAML::ParseException
            errors << "Invalid YAML syntax: #{ex.message}"
          rescue ex
            errors << "Failed to validate scene: #{ex.message}"
          end

          errors
        end

        private def self.validate_hotspots(hotspots : Array(YAML::Any)) : Array(String)
          errors = [] of String

          hotspots.each_with_index do |hotspot, index|
            prefix = "Hotspot ##{index + 1}"

            # Validate name
            if name = hotspot["name"]?
              if name.as_s.empty?
                errors << "#{prefix}: Name cannot be empty"
              end
            else
              errors << "#{prefix}: Missing required field 'name'"
            end

            # Validate type
            if type = hotspot["type"]?
              valid_types = ["rectangle", "polygon", "dynamic"]
              unless valid_types.includes?(type.as_s)
                errors << "#{prefix}: Invalid type '#{type}'. Must be one of: #{valid_types.join(", ")}"
              end
            end

            # Validate position and size for rectangle/dynamic
            if !hotspot["type"]? || hotspot["type"].as_s != "polygon"
              ["x", "y", "width", "height"].each do |field|
                if val = hotspot[field]?
                  if val.as_f < 0
                    errors << "#{prefix}: #{field} cannot be negative"
                  end
                else
                  errors << "#{prefix}: Missing required field '#{field}'"
                end
              end
            end

            # Validate polygon points
            if hotspot["type"]?.try(&.as_s) == "polygon"
              if points = hotspot["points"]?
                points_array = points.as_a
                if points_array.size < 3
                  errors << "#{prefix}: Polygon must have at least 3 points"
                end

                points_array.each_with_index do |point, pidx|
                  unless point["x"]? && point["y"]?
                    errors << "#{prefix}: Point ##{pidx + 1} missing x or y coordinate"
                  end
                end
              else
                errors << "#{prefix}: Polygon type requires 'points' array"
              end
            end

            # Validate actions
            if actions = hotspot["actions"]?
              valid_actions = ["look", "use", "talk", "take"]
              actions.as_h.each do |action, data|
                unless valid_actions.includes?(action.as_s)
                  errors << "#{prefix}: Unknown action '#{action}'"
                end
              end
            end

            # Validate dynamic hotspot conditions
            if hotspot["type"]?.try(&.as_s) == "dynamic"
              unless hotspot["conditions"]?
                errors << "#{prefix}: Dynamic hotspot requires 'conditions'"
              end
            end
          end

          errors
        end

        private def self.validate_walkable_areas_object(areas : YAML::Any) : Array(String)
          errors = [] of String

          # Validate regions
          if regions = areas["regions"]?
            regions.as_a.each_with_index do |region, index|
              prefix = "Walkable region ##{index + 1}"

              # Validate name
              unless region["name"]?
                errors << "#{prefix}: Missing required field 'name'"
              end

              # Validate walkable flag
              unless region["walkable"]?
                errors << "#{prefix}: Missing required field 'walkable'"
              end

              # Validate vertices
              if vertices = region["vertices"]?
                vertices_array = vertices.as_a
                if vertices_array.size < 3
                  errors << "#{prefix}: Must have at least 3 vertices"
                end

                vertices_array.each_with_index do |vertex, vidx|
                  if vertex["x"]? && vertex["y"]?
                    if vertex["x"].as_f < 0 || vertex["y"].as_f < 0
                      errors << "#{prefix}: Vertex ##{vidx + 1} has negative coordinates"
                    end
                  else
                    errors << "#{prefix}: Vertex ##{vidx + 1} missing x or y coordinate"
                  end
                end
              else
                errors << "#{prefix}: Missing required field 'vertices'"
              end
            end
          end

          # Validate walk_behind regions if present
          if walk_behind = areas["walk_behind"]?
            walk_behind.as_a.each_with_index do |region, index|
              prefix = "Walk-behind region ##{index + 1}"

              unless region["name"]?
                errors << "#{prefix}: Missing required field 'name'"
              end

              unless region["y_threshold"]?
                errors << "#{prefix}: Missing required field 'y_threshold'"
              end

              if vertices = region["vertices"]?
                vertices_array = vertices.as_a
                if vertices_array.size < 3
                  errors << "#{prefix}: Must have at least 3 vertices"
                end
              else
                errors << "#{prefix}: Missing required field 'vertices'"
              end
            end
          end

          # Validate scale_zones if present
          if scale_zones = areas["scale_zones"]?
            scale_zones.as_a.each_with_index do |zone, index|
              prefix = "Scale zone ##{index + 1}"

              ["min_y", "max_y", "min_scale", "max_scale"].each do |field|
                unless zone[field]?
                  errors << "#{prefix}: Missing required field '#{field}'"
                end
              end

              if zone["min_y"]? && zone["max_y"]?
                if zone["min_y"].as_f > zone["max_y"].as_f
                  errors << "#{prefix}: min_y cannot be greater than max_y"
                end
              end

              if zone["min_scale"]? && zone["max_scale"]?
                if zone["min_scale"].as_f > zone["max_scale"].as_f
                  errors << "#{prefix}: min_scale cannot be greater than max_scale"
                end
              end
            end
          end

          errors
        end

        private def self.validate_exits(exits : Array(YAML::Any)) : Array(String)
          errors = [] of String

          exits.each_with_index do |exit, index|
            prefix = "Exit ##{index + 1}"

            # Required fields
            ["x", "y", "width", "height", "target_scene"].each do |field|
              unless exit[field]?
                errors << "#{prefix}: Missing required field '#{field}'"
              end
            end

            # Validate dimensions
            ["x", "y", "width", "height"].each do |field|
              if val = exit[field]?
                if val.as_f < 0
                  errors << "#{prefix}: #{field} cannot be negative"
                end
              end
            end

            # Validate target
            if target = exit["target_scene"]?
              if target.as_s.empty?
                errors << "#{prefix}: Target scene cannot be empty"
              end
            end

            # Validate spawn position if present
            if spawn = exit["spawn_position"]?
              unless spawn["x"]? && spawn["y"]?
                errors << "#{prefix}: Spawn position requires both x and y"
              end
            end
          end

          errors
        end

        private def self.validate_scale_zones(zones : Array(YAML::Any)) : Array(String)
          errors = [] of String

          zones.each_with_index do |zone, index|
            prefix = "Scale zone ##{index + 1}"

            # Validate bounds
            ["x", "y", "width", "height"].each do |field|
              if val = zone[field]?
                if val.as_f < 0
                  errors << "#{prefix}: #{field} cannot be negative"
                end
              else
                errors << "#{prefix}: Missing required field '#{field}'"
              end
            end

            # Validate scale values
            ["min_scale", "max_scale"].each do |field|
              if val = zone[field]?
                scale = val.as_f.to_f32
                if scale <= 0 || scale > 5
                  errors << "#{prefix}: #{field} must be between 0 and 5"
                end
              else
                errors << "#{prefix}: Missing required field '#{field}'"
              end
            end

            # Check min < max
            if zone["min_scale"]? && zone["max_scale"]?
              if zone["min_scale"].as_f > zone["max_scale"].as_f
                errors << "#{prefix}: min_scale cannot be greater than max_scale"
              end
            end
          end

          errors
        end

        private def self.validate_characters(characters : Array(YAML::Any)) : Array(String)
          errors = [] of String

          characters.each_with_index do |char, index|
            prefix = "Character ##{index + 1}"

            # Required fields
            if name = char["name"]?
              if name.as_s.empty?
                errors << "#{prefix}: Name cannot be empty"
              end
            else
              errors << "#{prefix}: Missing required field 'name'"
            end

            # Position
            if position = char["position"]?
              ["x", "y"].each do |field|
                if val = position[field]?
                  if val.as_f < 0
                    errors << "#{prefix}: position.#{field} cannot be negative"
                  end
                else
                  errors << "#{prefix}: Missing required field 'position.#{field}'"
                end
              end
            else
              errors << "#{prefix}: Missing required field 'position'"
            end

            # Validate sprite if present
            if sprite = char["sprite"]?
              if sprite.as_s.empty?
                errors << "#{prefix}: Sprite path cannot be empty"
              end
            end

            # Validate dialog if present
            if dialog = char["dialog"]?
              if dialog.as_s.empty?
                errors << "#{prefix}: Dialog name cannot be empty"
              end
            end
          end

          errors
        end
      end
    end
  end
end
