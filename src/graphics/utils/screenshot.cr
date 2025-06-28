# Screenshot capture utilities

require "raylib-cr"

module PointClickEngine
  module Graphics
    module Utils
      # Screenshot capture and management
      module Screenshot
        extend self

        # Screenshot formats
        enum Format
          PNG
          BMP
          TGA
          JPG
        end

        # Take a screenshot of the current screen
        def capture : RL::Image
          RL.load_image_from_screen
        end

        # Take a screenshot and save to file
        def capture_to_file(filename : String, format : Format = Format::PNG) : Bool
          image = capture
          success = save_image(image, filename, format)
          RL.unload_image(image)
          success
        end

        # Take a screenshot with automatic naming
        def capture_auto(directory : String = "screenshots", prefix : String = "screenshot") : String?
          # Create directory if it doesn't exist
          Dir.mkdir_p(directory) unless Dir.exists?(directory)

          # Generate filename with timestamp
          timestamp = Time.local.to_s("%Y%m%d_%H%M%S")
          filename = File.join(directory, "#{prefix}_#{timestamp}.png")

          # Add counter if file exists
          counter = 1
          while File.exists?(filename)
            filename = File.join(directory, "#{prefix}_#{timestamp}_#{counter}.png")
            counter += 1
          end

          if capture_to_file(filename)
            filename
          else
            nil
          end
        end

        # Capture a specific region of the screen
        def capture_region(x : Int32, y : Int32, width : Int32, height : Int32) : RL::Image
          full_screen = capture
          region = RL.image_from_image(full_screen, RL::Rectangle.new(
            x: x.to_f32,
            y: y.to_f32,
            width: width.to_f32,
            height: height.to_f32
          ))
          RL.unload_image(full_screen)
          region
        end

        # Capture with post-processing
        def capture_with_effect(effect : Proc(RL::Image, RL::Image)) : RL::Image
          image = capture
          processed = effect.call(image)
          RL.unload_image(image) unless processed == image
          processed
        end

        # Capture thumbnail
        def capture_thumbnail(width : Int32 = 320, height : Int32 = 180) : RL::Image
          image = capture

          # Calculate aspect ratio preserving dimensions
          screen_width = image.width
          screen_height = image.height
          aspect = screen_width.to_f32 / screen_height

          if width.to_f32 / height > aspect
            # Height is limiting factor
            new_width = (height * aspect).to_i
            new_height = height
          else
            # Width is limiting factor
            new_width = width
            new_height = (width / aspect).to_i
          end

          # Resize image
          thumbnail = RL.image_resize(image, new_width, new_height)
          RL.unload_image(image)

          thumbnail
        end

        # Save thumbnail
        def save_thumbnail(filename : String, width : Int32 = 320, height : Int32 = 180) : Bool
          thumbnail = capture_thumbnail(width, height)
          success = save_image(thumbnail, filename, Format::PNG)
          RL.unload_image(thumbnail)
          success
        end

        # Capture sequence for animation
        class Sequence
          property directory : String
          property prefix : String
          property format : Format
          property frame_count : Int32
          property interval : Float32
          property max_frames : Int32

          private property elapsed : Float32
          private property active : Bool

          def initialize(@directory : String = "sequences",
                         @prefix : String = "frame",
                         @format : Format = Format::PNG,
                         @interval : Float32 = 0.1f32,
                         @max_frames : Int32 = 1000)
            @frame_count = 0
            @elapsed = 0.0f32
            @active = false

            # Create directory
            Dir.mkdir_p(@directory) unless Dir.exists?(@directory)
          end

          # Start capturing
          def start
            @active = true
            @frame_count = 0
            @elapsed = 0.0f32
          end

          # Stop capturing
          def stop
            @active = false
          end

          # Update and capture if needed
          def update(delta_time : Float32)
            return unless @active
            return if @frame_count >= @max_frames

            @elapsed += delta_time

            if @elapsed >= @interval
              @elapsed -= @interval
              capture_frame
            end
          end

          # Capture single frame
          def capture_frame
            filename = File.join(@directory, "#{@prefix}_%04d.#{@format.to_s.downcase}" % @frame_count)

            if Screenshot.capture_to_file(filename, @format)
              @frame_count += 1
            end
          end

          # Is sequence active?
          def active? : Bool
            @active
          end

          # Get captured frame filenames
          def frames : Array(String)
            files = [] of String
            @frame_count.times do |i|
              filename = File.join(@directory, "#{@prefix}_%04d.#{@format.to_s.downcase}" % i)
              files << filename if File.exists?(filename)
            end
            files
          end
        end

        # Screenshot comparison for testing
        def compare(image1 : RL::Image, image2 : RL::Image, threshold : Float32 = 0.01f32) : Bool
          return false if image1.width != image2.width || image1.height != image2.height

          total_diff = 0.0f32
          pixel_count = image1.width * image1.height

          image1.height.times do |y|
            image1.width.times do |x|
              color1 = RL.get_image_color(image1, x, y)
              color2 = RL.get_image_color(image2, x, y)

              # Calculate color difference
              dr = (color1.r - color2.r).abs / 255.0f32
              dg = (color1.g - color2.g).abs / 255.0f32
              db = (color1.b - color2.b).abs / 255.0f32
              da = (color1.a - color2.a).abs / 255.0f32

              total_diff += (dr + dg + db + da) / 4.0f32
            end
          end

          average_diff = total_diff / pixel_count
          average_diff <= threshold
        end

        # Create a screenshot with UI overlay
        def capture_with_overlay(&block : -> Nil) : RL::Image
          # Render normal frame
          image = capture

          # Create render texture for overlay
          render_texture = RL.load_render_texture(image.width, image.height)

          # Draw screenshot to render texture
          texture = RL.load_texture_from_image(image)
          RL.begin_texture_mode(render_texture)
          RL.draw_texture(texture, 0, 0, RL::WHITE)

          # Draw overlay
          block.call

          RL.end_texture_mode

          # Get final image
          final_image = RL.load_image_from_texture(render_texture.texture)

          # Cleanup
          RL.unload_texture(texture)
          RL.unload_render_texture(render_texture)
          RL.unload_image(image)

          final_image
        end

        private def save_image(image : RL::Image, filename : String, format : Format) : Bool
          case format
          when Format::PNG
            RL.export_image(image, filename)
          when Format::BMP
            RL.export_image(image, filename.sub(/\.png$/i, ".bmp"))
          when Format::TGA
            RL.export_image(image, filename.sub(/\.png$/i, ".tga"))
          when Format::JPG
            RL.export_image(image, filename.sub(/\.png$/i, ".jpg"))
          else
            false
          end
        end
      end

      # Screenshot manager for game integration
      class ScreenshotManager
        property enabled : Bool = true
        property directory : String
        property format : Screenshot::Format
        property capture_key : RL::KeyboardKey
        property sequence : Screenshot::Sequence?

        # Callbacks
        property on_screenshot : Proc(String, Nil)?
        property on_sequence_start : Proc(Nil)?
        property on_sequence_end : Proc(Nil)?

        def initialize(@directory : String = "screenshots",
                       @format : Screenshot::Format = Screenshot::Format::PNG,
                       @capture_key : RL::KeyboardKey = RL::KeyboardKey::F12)
        end

        # Update manager
        def update(delta_time : Float32)
          return unless @enabled

          # Check for screenshot key
          if RL.is_key_pressed(@capture_key)
            if RL.is_key_down(RL::KeyboardKey::LeftShift)
              # Shift+F12 for sequence
              toggle_sequence
            else
              # F12 for single screenshot
              take_screenshot
            end
          end

          # Update sequence if active
          @sequence.try(&.update(delta_time))
        end

        # Take a screenshot
        def take_screenshot : String?
          if filename = Screenshot.capture_auto(@directory)
            @on_screenshot.try(&.call(filename))
            filename
          end
        end

        # Toggle sequence recording
        def toggle_sequence
          if seq = @sequence
            if seq.active?
              seq.stop
              @on_sequence_end.try(&.call)
              @sequence = nil
            else
              start_sequence
            end
          else
            start_sequence
          end
        end

        # Start sequence recording
        def start_sequence
          @sequence = Screenshot::Sequence.new(@directory)
          @sequence.not_nil!.start
          @on_sequence_start.try(&.call)
        end

        # Check if recording
        def recording? : Bool
          @sequence.try(&.active?) || false
        end
      end
    end
  end
end
