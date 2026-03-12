# Mock Raylib for headless testing
module RaylibMock
  class Vector2
    property x : Float32
    property y : Float32

    def initialize(@x : Float32 = 0f32, @y : Float32 = 0f32)
    end
  end

  class Rectangle
    property x : Float32
    property y : Float32
    property width : Float32
    property height : Float32

    def initialize(@x : Float32 = 0f32, @y : Float32 = 0f32, @width : Float32 = 0f32, @height : Float32 = 0f32)
    end
  end

  class Color
    property r : UInt8
    property g : UInt8
    property b : UInt8
    property a : UInt8

    def initialize(@r : UInt8 = 0u8, @g : UInt8 = 0u8, @b : UInt8 = 0u8, @a : UInt8 = 255u8)
    end
  end

  class Texture2D
    def initialize
    end
  end

  class RenderTexture2D
    def initialize
    end
  end

  class Shader
    def initialize
    end
  end

  module MockRaylib
    @@headless_mode = false
    @@window_should_close = false
    @@window_ready = false
    @@fullscreen = false
    @@config_flags = 0
    @@frame_time = 0.016f32
    @@mouse_position = Vector2.new
    @@key_states = {} of Int32 => Bool
    @@mouse_states = {} of Int32 => Bool
    @@window_width = 800
    @@window_height = 600
    @@windowed_width = 800
    @@windowed_height = 600

    def self.set_headless_mode(headless : Bool)
      @@headless_mode = headless
    end

    def self.init_window(width : Int32, height : Int32, title : String)
      @@window_ready = true
      @@windowed_width = width
      @@windowed_height = height
      if (@@config_flags & Raylib::ConfigFlags::FullscreenMode.to_i) != 0
        @@fullscreen = true
        @@window_width = 1920
        @@window_height = 1080
      else
        @@window_width = width
        @@window_height = height
      end
      @@config_flags = 0
    end

    def self.close_window
      @@window_ready = false
    end

    def self.close_window? : Bool
      @@window_should_close
    end

    def self.window_ready? : Bool
      @@window_ready
    end

    def self.set_window_should_close(should_close : Bool)
      @@window_should_close = should_close
    end

    def self.get_frame_time : Float32
      @@frame_time
    end

    def self.set_frame_time(time : Float32)
      @@frame_time = time
    end

    def self.begin_drawing
      # No-op
    end

    def self.end_drawing
      # No-op
    end

    def self.clear_background(color)
      # No-op
    end

    def self.get_mouse_position
      @@mouse_position
    end

    def self.set_mouse_position(x : Float32, y : Float32)
      @@mouse_position = Vector2.new(x, y)
    end

    def self.key_pressed?(key : Int32) : Bool
      @@key_states[key]? || false
    end

    def self.set_key_pressed(key : Int32, pressed : Bool)
      @@key_states[key] = pressed
    end

    def self.mouse_button_pressed?(button : Int32) : Bool
      @@mouse_states[button]? || false
    end

    def self.mouse_button_released?(button : Int32) : Bool
      @@mouse_states[button]? || false
    end

    def self.set_mouse_button_pressed(button : Int32, pressed : Bool)
      @@mouse_states[button] = pressed
    end

    def self.draw_text(text : String, x : Int32, y : Int32, size : Int32, color)
      # No-op
    end

    def self.draw_rectangle(x : Int32, y : Int32, w : Int32, h : Int32, color)
      # No-op
    end

    def self.draw_rectangle_rec(rect, color)
      # No-op
    end

    def self.draw_rectangle_lines_ex(rect, thickness, color)
      # No-op
    end

    def self.load_texture(path : String)
      Texture2D.new
    end

    def self.unload_texture(texture)
      # No-op
    end

    def self.check_collision_point_rec?(point, rect) : Bool
      point.x >= rect.x && point.x <= rect.x + rect.width &&
        point.y >= rect.y && point.y <= rect.y + rect.height
    end

    def self.reset_mock_state
      @@window_should_close = false
      @@window_ready = false
      @@fullscreen = false
      @@config_flags = 0
      @@key_states.clear
      @@mouse_states.clear
      @@mouse_position = Vector2.new
      @@window_width = 800
      @@window_height = 600
      @@windowed_width = 800
      @@windowed_height = 600
    end

    # Additional mock methods for spec compatibility
    def self.set_target_fps(fps : Int32)
      # No-op
    end

    def self.set_config_flags(flags)
      @@config_flags = flags.to_i
    end

    def self.get_time : Float64
      0.0
    end

    def self.draw_fps(x : Int32, y : Int32)
      # No-op
    end

    def self.set_window_size(width : Int32, height : Int32)
      @@window_width = width
      @@window_height = height
      unless @@fullscreen
        @@windowed_width = width
        @@windowed_height = height
      end
    end

    def self.get_screen_width : Int32
      @@window_width
    end

    def self.get_screen_height : Int32
      @@window_height
    end


    def self.toggle_fullscreen
      if @@fullscreen
        @@fullscreen = false
        @@window_width = @@windowed_width
        @@window_height = @@windowed_height
      else
        @@fullscreen = true
        @@windowed_width = @@window_width
        @@windowed_height = @@window_height
        @@window_width = 1920
        @@window_height = 1080
      end
    end

    def self.get_current_monitor : Int32
      0
    end

    def self.window_fullscreen? : Bool
      @@fullscreen
    end

    def self.get_monitor_width(monitor : Int32) : Int32
      1920
    end

    def self.get_monitor_height(monitor : Int32) : Int32
      1080
    end

    def self.poll_input_events
      # No-op - this is crucial for preventing hangs
    end
  end
end

# Conditionally use mock in test environment
{% if env("HEADLESS_MODE") == "true" %}
  alias Raylib = RaylibMock::MockRaylib
  alias RL = RaylibMock::MockRaylib
{% end %}
