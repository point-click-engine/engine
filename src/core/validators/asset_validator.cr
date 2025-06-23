require "../exceptions"
require "../../assets/asset_manager"

module PointClickEngine
  module Core
    module Validators
      class AssetValidator
        struct AssetCheck
          property path : String
          property type : String
          property required : Bool
          property exists : Bool = false
          property error : String? = nil

          def initialize(@path : String, @type : String, @required : Bool = true)
          end
        end

        def self.validate_all_assets(config : GameConfig, config_path : String) : Array(String)
          errors = [] of String
          base_dir = File.dirname(config_path)
          
          # Collect all assets to check
          assets_to_check = [] of AssetCheck

          # Player sprite
          if player = config.player
            assets_to_check << AssetCheck.new(player.sprite_path, "sprite", true)
          end

          # Scene backgrounds and assets
          if assets = config.assets
            assets.scenes.each do |pattern|
              Dir.glob(File.join(base_dir, pattern)).each do |scene_path|
                begin
                  scene_assets = extract_scene_assets(scene_path)
                  assets_to_check.concat(scene_assets)
                rescue ex
                  errors << "Failed to parse scene '#{scene_path}': #{ex.message}"
                end
              end
            end

            # Audio assets
            if audio = assets.audio
              audio.music.each do |name, path|
                assets_to_check << AssetCheck.new(path, "music", true)
              end
              
              audio.sounds.each do |name, path|
                assets_to_check << AssetCheck.new(path, "sound", true)
              end
            end
          end

          # Check each asset
          assets_to_check.each do |asset|
            check_asset(asset, base_dir)
            if asset.required && !asset.exists
              errors << "Missing #{asset.type}: #{asset.path}#{asset.error ? " - #{asset.error}" : ""}"
            end
          end

          # Check for common asset issues
          errors.concat(check_asset_formats(assets_to_check))
          
          errors
        end

        private def self.extract_scene_assets(scene_path : String) : Array(AssetCheck)
          assets = [] of AssetCheck
          
          begin
            yaml_content = File.read(scene_path)
            scene_name = File.basename(scene_path, ".yaml")
            
            # Simple extraction of asset references from YAML
            # Look for common asset fields
            yaml_content.each_line do |line|
              if match = line.match(/background:\s*["']?([^"'\s]+)["']?/)
                assets << AssetCheck.new(match[1], "background", true)
              elsif match = line.match(/sprite:\s*["']?([^"'\s]+)["']?/)
                assets << AssetCheck.new(match[1], "sprite", false)
              elsif match = line.match(/portrait:\s*["']?([^"'\s]+)["']?/)
                assets << AssetCheck.new(match[1], "portrait", false)
              elsif match = line.match(/cursor:\s*["']?([^"'\s]+)["']?/)
                assets << AssetCheck.new(match[1], "cursor", false)
              elsif match = line.match(/sound:\s*["']?([^"'\s]+)["']?/)
                assets << AssetCheck.new(match[1], "sound", false)
              end
            end
          rescue ex
            # Error will be reported by caller
          end
          
          assets
        end

        private def self.check_asset(asset : AssetCheck, base_dir : String)
          # Try multiple paths
          paths_to_try = [
            asset.path,
            File.join(base_dir, asset.path),
            File.join(base_dir, "assets", asset.path),
            File.join(base_dir, "data", asset.path),
            File.join(base_dir, "resources", asset.path)
          ]

          # Also check in any mounted archives
          if PointClickEngine::AssetManager.instance.exists?(asset.path)
            asset.exists = true
            return
          end

          # Check filesystem
          paths_to_try.each do |path|
            if File.exists?(path)
              asset.exists = true
              
              # Verify file is readable and not empty
              begin
                if File.size(path) == 0
                  asset.error = "file is empty"
                  asset.exists = false
                end
              rescue ex
                asset.error = "cannot read file: #{ex.message}"
                asset.exists = false
              end
              
              return
            end
          end
          
          asset.exists = false
        end

        private def self.check_asset_formats(assets : Array(AssetCheck)) : Array(String)
          errors = [] of String
          
          # Group assets by type
          by_type = assets.group_by(&.type)
          
          # Check image formats
          ["sprite", "background", "portrait", "cursor"].each do |type|
            if images = by_type[type]?
              images.each do |asset|
                next unless asset.exists
                
                ext = File.extname(asset.path).downcase
                unless [".png", ".jpg", ".jpeg", ".bmp", ".tga"].includes?(ext)
                  errors << "Unsupported image format for #{asset.type} '#{asset.path}': #{ext}"
                end
              end
            end
          end
          
          # Check audio formats
          if sounds = by_type["sound"]?
            sounds.each do |asset|
              next unless asset.exists
              
              ext = File.extname(asset.path).downcase
              unless [".wav", ".ogg", ".mp3", ".flac"].includes?(ext)
                errors << "Unsupported sound format '#{asset.path}': #{ext}"
              end
            end
          end
          
          if music = by_type["music"]?
            music.each do |asset|
              next unless asset.exists
              
              ext = File.extname(asset.path).downcase
              unless [".ogg", ".mp3", ".wav", ".flac"].includes?(ext)
                errors << "Unsupported music format '#{asset.path}': #{ext}"
              end
            end
          end
          
          errors
        end
      end
    end
  end
end