require "yaml"
require "./scene"
require "./hotspot"
require "../characters/character"
require "../assets/asset_loader"

module PointClickEngine
  module Scenes
    class SceneLoader
      def self.load_from_yaml(path : String) : Scene
        yaml_content = AssetLoader.read_yaml(path)
        scene_data = YAML.parse(yaml_content)

        scene = Scene.new(scene_data["name"].as_s)

        if background_path = scene_data["background_path"]?
          scene.background_path = background_path.as_s
        end

        if scale = scene_data["scale"]?
          scene.scale = scale.as_f.to_f32
        end

        if enable_pathfinding = scene_data["enable_pathfinding"]?
          scene.enable_pathfinding = enable_pathfinding.as_bool
        end

        if navigation_cell_size = scene_data["navigation_cell_size"]?
          scene.navigation_cell_size = navigation_cell_size.as_i
        end

        if hotspots = scene_data["hotspots"]?
          hotspots.as_a.each do |hotspot_data|
            pos = Raylib::Vector2.new(
              x: hotspot_data["x"].as_f.to_f32,
              y: hotspot_data["y"].as_f.to_f32
            )

            size = Raylib::Vector2.new(
              x: hotspot_data["width"].as_f.to_f32,
              y: hotspot_data["height"].as_f.to_f32
            )

            hotspot = Hotspot.new(hotspot_data["name"].as_s, pos, size)

            if description = hotspot_data["description"]?
              hotspot.description = description.as_s
            end

            scene.add_hotspot(hotspot)
          end
        end

        if characters = scene_data["characters"]?
          characters.as_a.each do |char_data|
            pos = if position = char_data["position"]?
                    Raylib::Vector2.new(
                      x: position["x"].as_f.to_f32,
                      y: position["y"].as_f.to_f32
                    )
                  else
                    Raylib::Vector2.new(x: 0f32, y: 0f32)
                  end

            size = Raylib::Vector2.new(x: 32f32, y: 64f32) # Default character size
            if char_size = char_data["size"]?
              size.x = char_size["width"].as_f.to_f32
              size.y = char_size["height"].as_f.to_f32
            end

            character = Characters::NPC.new(char_data["name"].as_s, pos, size)

            if sprite_path = char_data["sprite_path"]?
              frame_width = 32
              frame_height = 64
              if sprite_info = char_data["sprite_info"]?
                frame_width = sprite_info["frame_width"].as_i
                frame_height = sprite_info["frame_height"].as_i
              end
              character.load_spritesheet(sprite_path.as_s, frame_width, frame_height)
            end

            scene.add_character(character)
          end
        end

        if script_path = scene_data["script_path"]?
          scene.script_path = script_path.as_s
        end

        scene
      end

      def self.save_to_yaml(scene : Scene, path : String)
        yaml_data = {
          "name"                 => scene.name,
          "background_path"      => scene.background_path,
          "scale"                => scene.scale,
          "enable_pathfinding"   => scene.enable_pathfinding,
          "navigation_cell_size" => scene.navigation_cell_size,
          "hotspots"             => scene.hotspots.map do |hotspot|
            {
              "name"        => hotspot.name,
              "x"           => hotspot.bounds.x,
              "y"           => hotspot.bounds.y,
              "width"       => hotspot.bounds.width,
              "height"      => hotspot.bounds.height,
              "description" => hotspot.description,
            }
          end,
          "characters" => scene.characters.map do |character|
            {
              "name"     => character.name,
              "position" => {
                "x" => character.position.x,
                "y" => character.position.y,
              },
            }
          end,
        }

        File.write(path, yaml_data.to_yaml)
      end
    end
  end
end
