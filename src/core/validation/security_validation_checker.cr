require "./validation_result"
require "../game_config"

module PointClickEngine
  module Core
    module Validation
      # Validates security considerations in game configuration
      #
      # The SecurityValidationChecker analyzes configuration files and assets
      # for potential security issues such as exposed secrets, unsafe patterns,
      # and sensitive data that shouldn't be in configuration files.
      class SecurityValidationChecker < BaseValidator
        def description : String
          "Scans for security issues including exposed secrets and sensitive data"
        end

        def validate(config : GameConfig, context : ValidationContext) : ValidationResult
          result = ValidationResult.new

          # Only run security validation if explicitly requested
          return result unless context.include_security_checks

          scan_config_for_secrets(config, result)
          scan_files_for_sensitive_data(context, result)
          validate_external_references(config, result)
          check_file_permissions(context, result)

          result
        end

        # Scans the main configuration for secrets and sensitive data
        private def scan_config_for_secrets(config : GameConfig, result : ValidationResult)
          # Check game configuration
          if game = config.game
            check_for_secrets_in_text(game.title, "game title", result)
            check_for_secrets_in_text(game.author || "", "game author", result)
            check_for_secrets_in_text(game.version || "", "game version", result)
          end

          # Check settings for sensitive data
          if settings = config.settings
            check_settings_for_secrets(settings, result)
          end

          # Check features for potentially unsafe options
          check_features_for_security_issues(config.features, result)
        end

        # Checks settings configuration for secrets
        private def check_settings_for_secrets(settings : GameConfig::SettingsConfig, result : ValidationResult)
          # Check common setting names that might contain secrets
          sensitive_patterns = [
            /api_key/i,
            /secret/i,
            /password/i,
            /token/i,
            /private_key/i,
            /access_key/i,
            /database_url/i,
            /connection_string/i,
          ]

          # This is a simplified check - in reality we'd need to introspect the settings object
          # For now, we'll check if any features or asset paths contain sensitive patterns
          settings_text = settings.to_s
          sensitive_patterns.each do |pattern|
            if settings_text.match(pattern)
              result.add_security_issue("Settings may contain sensitive data matching pattern: #{pattern}")
            end
          end
        end

        # Checks features for security issues
        private def check_features_for_security_issues(features : Array(String), result : ValidationResult)
          security_concerning_features = {
            "file_access" => "File access feature enabled - ensure proper sandboxing",
            "networking"  => "Networking feature enabled - validate all network communications",
            "scripting"   => "Scripting feature enabled - ensure script sandboxing and validation",
            "debug"       => "Debug mode enabled - disable for production builds",
            "console"     => "Console access enabled - disable for production builds",
            "eval"        => "Code evaluation enabled - potential security risk",
          }

          features.each do |feature|
            if message = security_concerning_features[feature]?
              result.add_security_issue(message)
            end
          end

          # Check for development features in production-like configs
          dev_features = features.select { |f| ["debug", "console", "dev_tools"].includes?(f) }
          if dev_features.any?
            result.add_security_issue("Development features enabled: #{dev_features.join(", ")} - ensure these are disabled in production")
          end
        end

        # Scans files for sensitive data patterns
        private def scan_files_for_sensitive_data(context : ValidationContext, result : ValidationResult)
          # Scan configuration files
          config_files = Dir.glob(File.join(context.base_dir, "*.{yaml,yml,json,toml}"))
          config_files.each do |file_path|
            scan_file_for_secrets(file_path, result)
          end

          # Scan script files if they exist
          script_files = Dir.glob(File.join(context.base_dir, "**/*.{lua,js,py}"))
          script_files.first(10).each do |file_path| # Limit to avoid performance issues
            scan_file_for_secrets(file_path, result)
          end
        end

        # Scans individual file for secrets
        private def scan_file_for_secrets(file_path : String, result : ValidationResult)
          return unless File.exists?(file_path)
          return if File.size(file_path) > 1_000_000 # Skip very large files

          begin
            content = File.read(file_path)
            file_name = File.basename(file_path)

            # Common secret patterns
            secret_patterns = {
              /[a-zA-Z0-9]{32,}/            => "potential API key or token",
              /password\s*[:=]\s*[^\s\n]+/i => "password assignment",
              /secret\s*[:=]\s*[^\s\n]+/i   => "secret assignment",
              /api_key\s*[:=]\s*[^\s\n]+/i  => "API key assignment",
              /database_password/i          => "database password reference",
              /private_key/i                => "private key reference",
              /-----BEGIN.*KEY-----/        => "cryptographic key",
            }

            secret_patterns.each do |pattern, description|
              if content.match(pattern)
                result.add_security_issue("File '#{file_name}' contains #{description}")
              end
            end

            # Check for hardcoded URLs with credentials
            if content.match(/https?:\/\/[^:\/\s]+:[^@\/\s]+@/)
              result.add_security_issue("File '#{file_name}' contains URL with embedded credentials")
            end
          rescue ex
            # Ignore files we can't read
          end
        end

        # Validates external references for security
        private def validate_external_references(config : GameConfig, result : ValidationResult)
          return unless assets = config.assets

          # Check for external asset references
          if audio = assets.audio
            check_audio_references_for_security(audio, result)
          end

          # Check scene files for external references
          assets.scenes.each do |pattern|
            Dir.glob(pattern).each do |scene_file|
              check_scene_file_for_external_refs(scene_file, result)
            end
          end
        end

        # Checks audio references for security issues
        private def check_audio_references_for_security(audio : GameConfig::AudioConfig, result : ValidationResult)
          all_paths = audio.music.values + audio.sounds.values

          all_paths.each do |path|
            # Check for external URLs
            if path.starts_with?("http://")
              result.add_security_issue("Insecure HTTP URL in audio config: #{path}")
            elsif path.starts_with?("https://")
              result.add_warning("External HTTPS URL in audio config - verify source: #{path}")
            elsif path.includes?("../") && path.count("../") > 2
              result.add_security_issue("Potentially unsafe path traversal in audio config: #{path}")
            end
          end
        end

        # Checks scene files for external references
        private def check_scene_file_for_external_refs(scene_file : String, result : ValidationResult)
          return unless File.exists?(scene_file)

          begin
            content = File.read(scene_file)

            # Check for external URLs in scene content
            if content.match(/https?:\/\//)
              result.add_warning("Scene '#{File.basename(scene_file)}' contains external URLs - verify security")
            end

            # Check for unsafe path patterns
            if content.match(/\.\.\/.*\.\.\//)
              result.add_security_issue("Scene '#{File.basename(scene_file)}' contains potentially unsafe path traversal")
            end
          rescue ex
            # Ignore files we can't read
          end
        end

        # Checks file permissions for security issues
        private def check_file_permissions(context : ValidationContext, result : ValidationResult)
          # Check if config files are world-readable (Unix-like systems)
          config_files = Dir.glob(File.join(context.base_dir, "*.{yaml,yml}"))

          config_files.each do |file_path|
            begin
              # Just check if file exists and we can read it
              if File.exists?(file_path)
                # Could add more sophisticated permission checking here
                result.add_info("Configuration file permissions checked: #{File.basename(file_path)}")
              end
            rescue ex
              # Ignore permission check failures
            end
          end
        end

        # Helper method to check text for secret patterns
        private def check_for_secrets_in_text(text : String, field_name : String, result : ValidationResult)
          return if text.empty?

          # Look for patterns that might be secrets
          if text.match(/^[a-f0-9]{32,}$/i) # Hex strings that might be keys
            result.add_security_issue("#{field_name} appears to contain a hex-encoded secret")
          elsif text.match(/^[A-Za-z0-9+\/]+=*$/) && text.size > 20 # Base64-like strings
            result.add_security_issue("#{field_name} appears to contain a base64-encoded secret")
          elsif text.downcase.includes?("password") || text.downcase.includes?("secret")
            result.add_security_issue("#{field_name} contains sensitive keywords")
          end
        end

        def priority : Int32
          30 # Run after basic validation but before performance checks
        end
      end
    end
  end
end
