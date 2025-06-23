# Rendering context for camera-aware drawing
# Provides transformation methods for drawing objects with camera offset

module PointClickEngine
  module Graphics
    # Context for rendering with camera transformations
    class RenderContext
      property camera : Camera?
      
      def initialize(@camera : Camera? = nil)
      end
      
      # Draw a texture with camera transformation
      def draw_texture(texture : RL::Texture2D, position : RL::Vector2, tint : RL::Color = RL::WHITE)
        screen_pos = transform_position(position)
        RL.draw_texture_v(texture, screen_pos, tint)
      end
      
      # Draw a texture with extended parameters and camera transformation
      def draw_texture_ex(texture : RL::Texture2D, position : RL::Vector2, rotation : Float32, scale : Float32, tint : RL::Color)
        screen_pos = transform_position(position)
        RL.draw_texture_ex(texture, screen_pos, rotation, scale, tint)
      end
      
      # Draw a texture region with camera transformation
      def draw_texture_rec(texture : RL::Texture2D, source : RL::Rectangle, position : RL::Vector2, tint : RL::Color)
        screen_pos = transform_position(position)
        RL.draw_texture_rec(texture, source, screen_pos, tint)
      end
      
      # Draw a texture region with extended parameters
      def draw_texture_pro(texture : RL::Texture2D, source : RL::Rectangle, dest : RL::Rectangle, origin : RL::Vector2, rotation : Float32, tint : RL::Color)
        # Transform destination rectangle position
        transformed_dest = RL::Rectangle.new(
          x: dest.x - (camera ? camera.position.x : 0.0f32),
          y: dest.y - (camera ? camera.position.y : 0.0f32),
          width: dest.width,
          height: dest.height
        )
        RL.draw_texture_pro(texture, source, transformed_dest, origin, rotation, tint)
      end
      
      # Draw a rectangle with camera transformation
      def draw_rectangle(x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color)
        screen_x = x - (camera ? camera.position.x.to_i : 0)
        screen_y = y - (camera ? camera.position.y.to_i : 0)
        RL.draw_rectangle(screen_x, screen_y, width, height, color)
      end
      
      # Draw rectangle lines with camera transformation
      def draw_rectangle_lines(x : Int32, y : Int32, width : Int32, height : Int32, color : RL::Color)
        screen_x = x - (camera ? camera.position.x.to_i : 0)
        screen_y = y - (camera ? camera.position.y.to_i : 0)
        RL.draw_rectangle_lines(screen_x, screen_y, width, height, color)
      end
      
      # Draw text with camera transformation
      def draw_text(text : String, x : Int32, y : Int32, font_size : Int32, color : RL::Color)
        screen_x = x - (camera ? camera.position.x.to_i : 0)
        screen_y = y - (camera ? camera.position.y.to_i : 0)
        RL.draw_text(text, screen_x, screen_y, font_size, color)
      end
      
      # Draw a line with camera transformation
      def draw_line(start_pos : RL::Vector2, end_pos : RL::Vector2, color : RL::Color)
        screen_start = transform_position(start_pos)
        screen_end = transform_position(end_pos)
        RL.draw_line_v(screen_start, screen_end, color)
      end
      
      # Draw a circle with camera transformation
      def draw_circle(center : RL::Vector2, radius : Float32, color : RL::Color)
        screen_center = transform_position(center)
        RL.draw_circle_v(screen_center, radius, color)
      end
      
      # Check if a world position is visible on screen
      def is_visible?(world_pos : RL::Vector2, margin : Float32 = 100.0f32) : Bool
        return true unless camera # If no camera, everything is visible
        camera.is_visible?(world_pos.x, world_pos.y, margin)
      end
      
      # Transform world position to screen position
      def transform_position(world_pos : RL::Vector2) : RL::Vector2
        if cam = camera
          cam.world_to_screen(world_pos.x, world_pos.y)
        else
          world_pos
        end
      end
      
      # Get the camera offset for manual calculations
      def camera_offset : RL::Vector2
        if cam = camera
          RL::Vector2.new(x: -cam.position.x, y: -cam.position.y)
        else
          RL::Vector2.new(x: 0, y: 0)
        end
      end
    end
  end
end