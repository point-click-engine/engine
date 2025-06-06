# Save/Load system for game state persistence

require "yaml"
require "file_utils"

module PointClickEngine
  module Core
    # Game save data structure
    class SaveData
      include YAML::Serializable

      property version : String = "1.0"
      property timestamp : Time
      property current_scene_name : String
      property player_position_x : Float32 = 0.0
      property player_position_y : Float32 = 0.0
      property inventory_items : Array(Inventory::InventoryItem)
      property game_variables : Hash(String, String)
      property completed_dialogs : Array(String)
      property scene_states : Hash(String, Hash(String, String))

      def initialize
        @timestamp = Time.utc
        @current_scene_name = ""
        @inventory_items = [] of Inventory::InventoryItem
        @game_variables = {} of String => String
        @completed_dialogs = [] of String
        @scene_states = {} of String => Hash(String, String)
      end
    end

    # Save/Load management system
    class SaveSystem
      SAVE_DIRECTORY = "saves"
      SAVE_EXTENSION = ".save"

      def self.ensure_save_directory
        Dir.mkdir_p(SAVE_DIRECTORY) unless Dir.exists?(SAVE_DIRECTORY)
      end

      def self.save_game(engine : Engine, slot_name : String = "autosave") : Bool
        begin
          ensure_save_directory

          save_data = SaveData.new
          save_data.timestamp = Time.utc

          # Save current scene
          if current_scene = engine.current_scene
            save_data.current_scene_name = current_scene.name
          end

          # Save player position
          if current_scene = engine.current_scene
            if player = current_scene.player
              save_data.player_position_x = player.position.x
              save_data.player_position_y = player.position.y
            end
          end

          # Save inventory
          save_data.inventory_items = engine.inventory.items.dup

          # Save game variables (from script engine or dialog trees)
          # save_data.game_variables = engine.game_variables.dup

          # Save completed dialogs
          # save_data.completed_dialogs = engine.completed_dialogs.dup

          # Save scene states
          engine.scenes.each do |scene_name, scene|
            scene_state = {} of String => String
            scene.hotspots.each do |hotspot|
              scene_state["hotspot_#{hotspot.name}_active"] = hotspot.active.to_s
              scene_state["hotspot_#{hotspot.name}_visible"] = hotspot.visible.to_s
            end
            save_data.scene_states[scene_name] = scene_state
          end

          # Write save file
          save_path = File.join(SAVE_DIRECTORY, "#{slot_name}#{SAVE_EXTENSION}")
          File.write(save_path, save_data.to_yaml)

          true
        rescue ex
          puts "Failed to save game: #{ex.message}"
          false
        end
      end

      def self.load_game(engine : Engine, slot_name : String = "autosave") : Bool
        begin
          save_path = File.join(SAVE_DIRECTORY, "#{slot_name}#{SAVE_EXTENSION}")
          return false unless File.exists?(save_path)

          yaml_content = File.read(save_path)
          save_data = SaveData.from_yaml(yaml_content)

          # Restore current scene
          if !save_data.current_scene_name.empty?
            engine.change_scene(save_data.current_scene_name)
          end

          # Restore player position
          if current_scene = engine.current_scene
            if player = current_scene.player
              player.position = RL::Vector2.new(x: save_data.player_position_x, y: save_data.player_position_y)
            end
          end

          # Restore inventory
          engine.inventory.items.clear
          save_data.inventory_items.each do |item|
            engine.inventory.add_item(item)
          end

          # Restore game variables
          # engine.game_variables.clear
          # save_data.game_variables.each do |key, value|
          #   engine.game_variables[key] = value
          # end

          # Restore completed dialogs
          # engine.completed_dialogs.clear
          # save_data.completed_dialogs.each do |dialog|
          #   engine.completed_dialogs << dialog
          # end

          # Restore scene states
          save_data.scene_states.each do |scene_name, scene_state|
            if scene = engine.scenes[scene_name]?
              scene_state.each do |key, value|
                if key.starts_with?("hotspot_") && key.ends_with?("_active")
                  hotspot_name = key.gsub("hotspot_", "").gsub("_active", "")
                  if hotspot = scene.hotspots.find { |h| h.name == hotspot_name }
                    hotspot.active = value == "true"
                  end
                elsif key.starts_with?("hotspot_") && key.ends_with?("_visible")
                  hotspot_name = key.gsub("hotspot_", "").gsub("_visible", "")
                  if hotspot = scene.hotspots.find { |h| h.name == hotspot_name }
                    hotspot.visible = value == "true"
                  end
                end
              end
            end
          end

          true
        rescue ex
          puts "Failed to load game: #{ex.message}"
          false
        end
      end

      def self.get_save_files : Array(String)
        ensure_save_directory
        Dir.children(SAVE_DIRECTORY)
          .select { |f| f.ends_with?(SAVE_EXTENSION) }
          .map { |f| f.gsub(SAVE_EXTENSION, "") }
      end

      def self.delete_save(slot_name : String) : Bool
        begin
          save_path = File.join(SAVE_DIRECTORY, "#{slot_name}#{SAVE_EXTENSION}")
          File.delete(save_path) if File.exists?(save_path)
          true
        rescue
          false
        end
      end

      def self.save_exists?(slot_name : String) : Bool
        save_path = File.join(SAVE_DIRECTORY, "#{slot_name}#{SAVE_EXTENSION}")
        File.exists?(save_path)
      end
    end
  end
end
