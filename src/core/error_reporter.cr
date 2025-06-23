require "./exceptions"
require "colorize"

module PointClickEngine
  module Core
    class ErrorReporter
      def self.report_loading_error(error : Exception, context : String = "")
        puts "\n#{"=" * 60}".colorize(:red)
        puts "❌ LOADING ERROR".colorize(:red).bold
        puts "=" * 60
        
        unless context.empty?
          puts "Context: #{context}".colorize(:yellow)
        end

        case error
        when ConfigError
          puts "Type: Configuration Error".colorize(:red)
          if error.filename
            puts "File: #{error.filename}".colorize(:cyan)
          end
          if error.field
            puts "Field: #{error.field}".colorize(:cyan)
          end
          puts "\nError: #{error.message}".colorize(:white)
          
        when AssetError
          puts "Type: Asset Loading Error".colorize(:red)
          puts "Asset: #{error.asset_path}".colorize(:cyan)
          if error.filename
            puts "Referenced in: #{error.filename}".colorize(:cyan)
          end
          puts "\nError: #{error.message}".colorize(:white)
          
        when SceneError
          puts "Type: Scene Loading Error".colorize(:red)
          puts "Scene: #{error.scene_name}".colorize(:cyan)
          if error.field
            puts "Field: #{error.field}".colorize(:cyan)
          end
          puts "\nError: #{error.message}".colorize(:white)
          
        when ValidationError
          puts "Type: Validation Error".colorize(:red)
          if error.filename
            puts "File: #{error.filename}".colorize(:cyan)
          end
          puts "\nValidation failed with #{error.errors.size} error(s):".colorize(:white)
          error.errors.each_with_index do |err, i|
            puts "  #{i + 1}. #{err}".colorize(:red)
          end
          
        else
          puts "Type: #{error.class}".colorize(:red)
          puts "\nError: #{error.message}".colorize(:white)
        end

        # Print stack trace for debugging
        if ENV["DEBUG"]?
          puts "\nStack trace:".colorize(:dark_gray)
          error.backtrace.first(10).each do |line|
            puts "  #{line}".colorize(:dark_gray)
          end
        else
          puts "\nTip: Set DEBUG=1 environment variable to see stack trace".colorize(:dark_gray)
        end

        puts "=" * 60
      end

      def self.report_warning(message : String, context : String = "")
        puts "\n⚠️  WARNING: #{message}".colorize(:yellow)
        unless context.empty?
          puts "   Context: #{context}".colorize(:dark_gray)
        end
      end

      def self.report_info(message : String)
        puts "ℹ️  #{message}".colorize(:blue)
      end

      def self.report_success(message : String)
        puts "✅ #{message}".colorize(:green)
      end

      def self.report_progress(message : String)
        print "⏳ #{message}...".colorize(:cyan)
      end

      def self.report_progress_done(success : Bool = true)
        if success
          puts " ✓".colorize(:green)
        else
          puts " ✗".colorize(:red)
        end
      end

      # Format a list of items nicely
      def self.format_list(title : String, items : Array(String))
        puts "\n#{title}:".colorize(:white).bold
        items.each do |item|
          puts "  • #{item}"
        end
      end

      # Create a visual separator
      def self.separator(char : String = "=", length : Int32 = 60)
        puts char * length
      end

      # Report multiple errors at once
      def self.report_multiple_errors(errors : Array(Exception), title : String = "Multiple Errors Occurred")
        separator
        puts "❌ #{title}".colorize(:red).bold
        separator
        
        errors.each_with_index do |error, index|
          puts "\nError #{index + 1}:".colorize(:red).bold
          case error
          when LoadingError
            if error.filename
              puts "  File: #{error.filename}".colorize(:cyan)
            end
            puts "  Message: #{error.message}".colorize(:white)
          else
            puts "  #{error.message}".colorize(:white)
          end
        end
        
        separator
      end
    end
  end
end