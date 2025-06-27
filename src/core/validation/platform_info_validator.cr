require "./validation_result"
require "../game_config"

module PointClickEngine
  module Core
    module Validation
      # Reports platform and development environment information
      #
      # The PlatformInfoValidator collects and reports information about
      # the development environment, platform capabilities, and system
      # configuration to help with debugging and compatibility issues.
      class PlatformInfoValidator < BaseValidator
        def description : String
          "Reports development environment and platform information"
        end

        def validate(config : GameConfig, context : ValidationContext) : ValidationResult
          result = ValidationResult.new

          report_crystal_environment(result)
          report_operating_system(result)
          report_development_tools(result)
          report_platform_capabilities(result)
          report_resource_summary(config, context, result)

          result
        end

        # Reports Crystal language environment
        private def report_crystal_environment(result : ValidationResult)
          crystal_version = Crystal::VERSION
          result.add_info("Running on Crystal #{crystal_version}")

          # Report build mode if we can determine it
          {% if flag?(:release) %}
            result.add_info("Build mode: Release")
          {% else %}
            result.add_info("Build mode: Debug")
          {% end %}

          # Report target platform
          {% if flag?(:win32) %}
            result.add_info("Target platform: Windows")
          {% elsif flag?(:darwin) %}
            result.add_info("Target platform: macOS")
          {% elsif flag?(:linux) %}
            result.add_info("Target platform: Linux")
          {% else %}
            result.add_info("Target platform: Other")
          {% end %}
        end

        # Reports operating system information
        private def report_operating_system(result : ValidationResult)
          os_name = {% if flag?(:win32) %}
                      "Windows"
                    {% elsif flag?(:darwin) %}
                      "macOS"
                    {% elsif flag?(:linux) %}
                      "Linux"
                    {% else %}
                      "Unknown"
                    {% end %}

          result.add_info("Operating System: #{os_name}")

          # Try to get more detailed OS info
          begin
            {% if flag?(:unix) %}
              if system_info = `uname -a 2>/dev/null`.strip
                result.add_info("System info: #{system_info}")
              end
            {% end %}
          rescue
            # Ignore if we can't get system info
          end
        end

        # Reports available development tools
        private def report_development_tools(result : ValidationResult)
          tools_found = [] of String
          tools_missing = [] of String

          # Check for common development tools
          development_tools = {
            "git"        => "git --version",
            "make"       => "make --version",
            "cmake"      => "cmake --version",
            "pkg-config" => "pkg-config --version",
          }

          development_tools.each do |tool, command|
            begin
              if system("which #{tool} >/dev/null 2>&1")
                tools_found << tool
              else
                tools_missing << tool
              end
            rescue
              tools_missing << tool
            end
          end

          if tools_found.any?
            result.add_info("Development tools found: #{tools_found.join(", ")}")
          end

          if tools_missing.any?
            result.add_info("Development tools not found: #{tools_missing.join(", ")}")
          end
        end

        # Reports platform capabilities
        private def report_platform_capabilities(result : ValidationResult)
          capabilities = [] of String

          # Check for OpenGL support (simplified)
          {% if flag?(:darwin) || flag?(:linux) || flag?(:win32) %}
            capabilities << "OpenGL (likely supported)"
          {% end %}

          # Check for audio support
          capabilities << "Audio support (Raylib)"

          # Check architecture
          {% if flag?(:x86_64) %}
            capabilities << "64-bit architecture"
          {% else %}
            capabilities << "32-bit or other architecture"
          {% end %}

          if capabilities.any?
            result.add_info("Platform capabilities: #{capabilities.join(", ")}")
          end
        end

        # Reports resource summary from the configuration
        private def report_resource_summary(config : GameConfig, context : ValidationContext, result : ValidationResult)
          return unless assets = config.assets

          # Count different types of resources
          sprite_count = 0
          scene_count = 0
          audio_count = 0
          total_file_count = 0

          # Count sprites
          assets.sprites.each do |pattern|
            count = Dir.glob(File.join(context.base_dir, pattern)).size
            sprite_count += count
            total_file_count += count
          end

          # Count scenes
          assets.scenes.each do |pattern|
            count = Dir.glob(File.join(context.base_dir, pattern)).size
            scene_count += count
            total_file_count += count
          end

          # Count audio files
          if audio = assets.audio
            audio_count = audio.music.size + audio.sounds.size
            total_file_count += audio_count
          end

          # Count other resources
          shader_count = 0
          if config.features.includes?("shaders")
            shader_files = Dir.glob(File.join(context.base_dir, "shaders", "*.{vert,frag,glsl}"))
            shader_count = shader_files.size
            total_file_count += shader_count
          end

          # Generate resource summary
          summary_parts = [] of String
          summary_parts << "#{scene_count} scene(s)" if scene_count > 0
          summary_parts << "#{sprite_count} sprite(s)" if sprite_count > 0
          summary_parts << "#{audio_count} audio file(s)" if audio_count > 0
          summary_parts << "#{shader_count} shader(s)" if shader_count > 0

          if summary_parts.any?
            result.add_info("Resource summary: #{summary_parts.join(", ")} (#{total_file_count} total files)")
          else
            result.add_info("Resource summary: No resources found")
          end

          # Calculate total asset size if possible
          calculate_total_asset_size(assets, context, result)
        end

        # Calculates and reports total asset size
        private def calculate_total_asset_size(assets : GameConfig::AssetsConfig, context : ValidationContext, result : ValidationResult)
          total_size = 0_i64

          begin
            # Sum sprite file sizes
            assets.sprites.each do |pattern|
              Dir.glob(File.join(context.base_dir, pattern)).each do |file|
                total_size += File.size(file) if File.exists?(file)
              end
            end

            # Sum audio file sizes
            if audio = assets.audio
              (audio.music.values + audio.sounds.values).each do |path|
                full_path = File.expand_path(path, context.base_dir)
                total_size += File.size(full_path) if File.exists?(full_path)
              end
            end

            # Sum scene background sizes
            assets.scenes.each do |pattern|
              Dir.glob(File.join(context.base_dir, pattern)).each do |scene_file|
                next unless File.exists?(scene_file)

                begin
                  content = File.read(scene_file)
                  if match = content.match(/background_path:\s*(.+)/)
                    bg_path = match[1].strip.gsub(/["']/, "")
                    full_bg_path = File.expand_path(bg_path, context.base_dir)
                    total_size += File.size(full_bg_path) if File.exists?(full_bg_path)
                  end
                rescue
                  # Ignore errors reading scene files
                end
              end
            end

            size_mb = total_size / 1_048_576.0
            result.add_info("Total asset size: #{size_mb.round(2)} MB")
          rescue ex
            result.add_warning("Could not calculate total asset size: #{ex.message}")
          end
        end

        def priority : Int32
          10 # Run early to provide context for other validators
        end
      end
    end
  end
end
