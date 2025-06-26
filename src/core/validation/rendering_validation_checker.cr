require "./validation_result"
require "../game_config"

module PointClickEngine
  module Core
    module Validation
      # Validates rendering configuration and player setup
      #
      # The RenderingValidationChecker handles validation of rendering settings,
      # player sprite configuration, UI scaling, and graphics-related features.
      class RenderingValidationChecker < BaseValidator
        def description : String
          "Validates rendering settings, player sprites, UI scaling, and graphics configuration"
        end

        def validate(config : GameConfig, context : ValidationContext) : ValidationResult
          result = ValidationResult.new

          validate_player_sprite_setup(config, context, result)
          validate_ui_scaling(config, result)
          validate_display_settings(config, result)
          validate_animation_settings(config, context, result)

          result
        end

        # Validates player sprite configuration
        private def validate_player_sprite_setup(config : GameConfig, context : ValidationContext, result : ValidationResult)
          if player = config.player
            validate_player_sprite_file(player, context, result)
            validate_player_sprite_dimensions(player, result)
            validate_player_starting_position(player, result)
          else
            result.add_error("No player configuration found")
          end
        end

        # Validates player sprite file exists and properties
        private def validate_player_sprite_file(player : GameConfig::PlayerConfig, context : ValidationContext, result : ValidationResult)
          if sprite_path = player.sprite_path
            full_sprite_path = File.expand_path(sprite_path, context.base_dir)
            if File.exists?(full_sprite_path)
              result.add_info("✓ Player sprite found: #{sprite_path}")

              # Check sprite file size
              sprite_size = File.size(full_sprite_path)
              if sprite_size > 5_000_000 # 5MB
                result.add_performance_hint("Player sprite is large (#{(sprite_size / 1_048_576.0).round(1)} MB)")
              end

              # Check sprite format
              validate_sprite_format(full_sprite_path, result)
            else
              result.add_error("Player sprite not found: #{sprite_path}")
            end
          else
            result.add_error("No player sprite path specified")
          end
        end

        # Validates sprite file format
        private def validate_sprite_format(sprite_path : String, result : ValidationResult)
          ext = File.extname(sprite_path).downcase
          case ext
          when ".png"
            # PNG is ideal for sprites
            result.add_info("✓ Player sprite uses PNG format (recommended)")
          when ".jpg", ".jpeg"
            result.add_warning("Player sprite uses JPEG format - PNG recommended for transparency support")
          when ".bmp"
            result.add_warning("Player sprite uses BMP format - PNG recommended for smaller file size")
          when ".tga"
            result.add_warning("Player sprite uses TGA format - may not be supported on all platforms")
          else
            result.add_error("Player sprite uses unsupported format: #{ext}")
          end
        end

        # Validates player sprite dimensions and frame configuration
        private def validate_player_sprite_dimensions(player : GameConfig::PlayerConfig, result : ValidationResult)
          if sprite_config = player.sprite
            if sprite_config.frame_width && sprite_config.frame_height
              frame_width = sprite_config.frame_width.not_nil!
              frame_height = sprite_config.frame_height.not_nil!

              # Check for reasonable frame dimensions
              if frame_width <= 0 || frame_height <= 0
                result.add_error("Player sprite frame dimensions must be positive: #{frame_width}x#{frame_height}")
              elsif frame_width > 512 || frame_height > 512
                result.add_warning("Player sprite frames are very large: #{frame_width}x#{frame_height}")
              end

              # Calculate total frames if sprite sheet info is available
              if sprite_config.rows && sprite_config.columns
                rows = sprite_config.rows.not_nil!
                columns = sprite_config.columns.not_nil!
                total_frames = rows * columns

                if total_frames > 100
                  result.add_performance_hint("Player sprite has #{total_frames} frames - consider splitting into multiple sprites")
                end

                # Check for power-of-2 dimensions for better GPU performance
                unless is_power_of_two?(frame_width) && is_power_of_two?(frame_height)
                  result.add_performance_hint("Player sprite frame dimensions are not power-of-2 (#{frame_width}x#{frame_height}) - may impact GPU performance")
                end
              end
            else
              result.add_warning("No player sprite dimensions specified - may cause rendering issues")
            end
          else
            result.add_warning("No player sprite configuration found")
          end
        end

        # Validates player starting position
        private def validate_player_starting_position(player : GameConfig::PlayerConfig, result : ValidationResult)
          if start_pos = player.start_position
            if start_pos.x < 0 || start_pos.y < 0
              result.add_error("Player starting position has negative coordinates: (#{start_pos.x}, #{start_pos.y})")
            end

            # Check if starting position is reasonable
            if start_pos.x > 10000 || start_pos.y > 10000
              result.add_warning("Player starting position is very large: (#{start_pos.x}, #{start_pos.y})")
            end
          else
            result.add_warning("No player starting position specified")
          end
        end

        # Validates UI scaling configuration
        private def validate_ui_scaling(config : GameConfig, result : ValidationResult)
          if display = config.display
            validate_scaling_mode(display, result)
            validate_target_resolution(display, config, result)
          else
            result.add_info("No display configuration found - using defaults")
          end
        end

        # Validates display scaling mode
        private def validate_scaling_mode(display : GameConfig::DisplayConfig, result : ValidationResult)
          if scaling_mode = display.scaling_mode
            valid_modes = ["None", "FitWithBars", "Stretch", "PixelPerfect"]
            if valid_modes.includes?(scaling_mode)
              result.add_info("✓ Display scaling mode: #{scaling_mode}")

              # Provide mode-specific advice
              case scaling_mode
              when "Stretch"
                result.add_warning("Stretch scaling mode may cause aspect ratio distortion")
              when "PixelPerfect"
                result.add_performance_hint("PixelPerfect scaling provides crisp pixels but may show black bars")
              end
            else
              result.add_error("Invalid display scaling mode: #{scaling_mode}")
              result.add_info("Valid modes: #{valid_modes.join(", ")}")
            end
          end
        end

        # Validates target resolution settings
        private def validate_target_resolution(display : GameConfig::DisplayConfig, config : GameConfig, result : ValidationResult)
          if window = config.window
            window_width = window.width
            window_height = window.height
            target_width = display.target_width || window_width
            target_height = display.target_height || window_height

            if target_width != window_width || target_height != window_height
              result.add_info("Display scaling enabled: #{window_width}x#{window_height} -> #{target_width}x#{target_height}")

              # Check for common aspect ratios
              aspect_ratio = target_width.to_f / target_height.to_f
              if (aspect_ratio - 16.0/9.0).abs < 0.01
                result.add_info("✓ Target resolution uses 16:9 aspect ratio")
              elsif (aspect_ratio - 4.0/3.0).abs < 0.01
                result.add_info("✓ Target resolution uses 4:3 aspect ratio")
              else
                result.add_warning("Target resolution uses unusual aspect ratio: #{aspect_ratio.round(2)}")
              end
            end

            # Check for very small or large resolutions
            if target_width < 320 || target_height < 240
              result.add_warning("Target resolution is very small: #{target_width}x#{target_height}")
            elsif target_width > 3840 || target_height > 2160
              result.add_warning("Target resolution is very large: #{target_width}x#{target_height}")
            end
          end
        end

        # Validates general display settings
        private def validate_display_settings(config : GameConfig, result : ValidationResult)
          if window = config.window
            validate_window_settings(window, config, result)
            validate_fullscreen_settings(window, result)
          end

          if display = config.display
            validate_vsync_settings(display, result)
          end
        end

        # Validates window configuration
        private def validate_window_settings(window : GameConfig::WindowConfig, config : GameConfig, result : ValidationResult)
          width = window.width
          height = window.height

          # Check for reasonable window dimensions
          if width <= 0 || height <= 0
            result.add_error("Window dimensions must be positive: #{width}x#{height}")
          elsif width <= 320 || height <= 240
            result.add_error("Window resolution is too small: #{width}x#{height} - minimum supported is 640x480")
          elsif width < 640 || height < 480
            result.add_warning("Window is very small: #{width}x#{height} - may cause usability issues")
          elsif width > 7680 || height > 4320
            result.add_warning("Window is very large: #{width}x#{height} - may cause performance issues")
          end

          # Check for standard resolutions
          standard_resolutions = [
            {640, 480}, {800, 600}, {1024, 768}, {1280, 720}, {1280, 1024},
            {1366, 768}, {1440, 900}, {1600, 900}, {1680, 1050}, {1920, 1080},
            {1920, 1200}, {2560, 1440}, {2560, 1600}, {3840, 2160},
          ]

          unless standard_resolutions.includes?({width, height})
            result.add_warning("Non-standard resolution: #{width}x#{height}")
          end

          # Warn about resolutions larger than 1920x1080
          if width > 1920 || height > 1080
            result.add_warning("Resolution is larger than 1920x1080 - may impact performance")
            if width >= 3840 || height >= 2160
              result.add_performance_hint("High resolution (#{width}x#{height}) - ensure adequate GPU performance")
            end
          end

          # Check aspect ratio
          aspect_ratio = width.to_f / height.to_f
          common_ratios = [4.0/3.0, 16.0/9.0, 16.0/10.0, 21.0/9.0]

          ratio_match = common_ratios.any? { |ratio| (aspect_ratio - ratio).abs < 0.1 }
          unless ratio_match
            result.add_warning("Unusual aspect ratio: #{aspect_ratio.round(2)} - may cause display issues")
          end

          # Check title from GameInfo
          if game = config.game
            if title = game.title
              if title.empty?
                result.add_warning("Window title is empty")
              elsif title.size > 100
                result.add_warning("Window title is very long (#{title.size} characters)")
              end
            else
              result.add_warning("No window title specified")
            end
          end
        end

        # Validates VSync settings
        private def validate_vsync_settings(display : GameConfig::DisplayConfig, result : ValidationResult)
          if vsync = display.vsync
            if vsync
              result.add_info("✓ VSync enabled - provides smooth animation")
            else
              result.add_performance_hint("VSync disabled - may cause screen tearing but potentially higher FPS")
            end
          end
        end

        # Validates fullscreen settings
        private def validate_fullscreen_settings(window : GameConfig::WindowConfig, result : ValidationResult)
          if fullscreen = window.fullscreen
            if fullscreen
              result.add_info("✓ Display mode: fullscreen")
            else
              result.add_info("✓ Display mode: windowed")
            end
          end
        end

        # Validates animation-related settings
        private def validate_animation_settings(config : GameConfig, context : ValidationContext, result : ValidationResult)
          if player = config.player
            if sprite_config = player.sprite
              validate_animation_frame_timing(sprite_config, result)
              validate_animation_sequences(sprite_config, result)
            end
          end
        end

        # Validates animation frame timing
        private def validate_animation_frame_timing(sprite_config : GameConfig::SpriteInfo, result : ValidationResult)
          if fps = sprite_config.fps
            if fps <= 0
              result.add_error("Animation FPS must be positive: #{fps}")
            elsif fps > 60
              result.add_warning("Animation FPS is very high: #{fps} - may impact performance")
            elsif fps < 6
              result.add_warning("Animation FPS is very low: #{fps} - animations may appear choppy")
            else
              result.add_info("✓ Animation FPS: #{fps}")
            end
          end
        end

        # Validates animation sequences
        private def validate_animation_sequences(sprite_config : GameConfig::SpriteInfo, result : ValidationResult)
          if animations = sprite_config.animations
            if animations.empty?
              result.add_warning("No animations defined for player sprite")
            else
              animations.each do |name, anim_config|
                validate_single_animation(name, anim_config, sprite_config, result)
              end
            end
          end
        end

        # Validates a single animation configuration
        private def validate_single_animation(name : String, anim_config : GameConfig::AnimationConfig, sprite_config : GameConfig::SpriteInfo, result : ValidationResult)
          if start_frame = anim_config.start_frame
            if end_frame = anim_config.end_frame
              if start_frame < 0 || end_frame < 0
                result.add_error("Animation '#{name}' has negative frame numbers: #{start_frame}-#{end_frame}")
              elsif start_frame > end_frame
                result.add_error("Animation '#{name}' start frame is after end frame: #{start_frame}-#{end_frame}")
              end

              # Check frame count
              frame_count = end_frame - start_frame + 1
              if frame_count == 1
                result.add_warning("Animation '#{name}' has only one frame")
              elsif frame_count > 50
                result.add_performance_hint("Animation '#{name}' has many frames (#{frame_count}) - consider optimization")
              end
            end
          end
        end

        # Helper method to check if a number is power of 2
        private def is_power_of_two?(n : Int32) : Bool
          n > 0 && (n & (n - 1)) == 0
        end

        def priority : Int32
          30 # Run after asset validation
        end
      end
    end
  end
end
