require "spec"
require "json" # Fix for luajit.cr JSON::Any issue
require "file_utils"

# Load mock Raylib if in headless mode
{% if env("HEADLESS_MODE") == "true" %}
  require "./support/raylib_mock"
{% end %}

require "../src/point_click_engine"
require "./support/resource_cleanup"

# RL alias is defined in individual source files that need Raylib types
require "../src/core/game_config"

# Helper to create test vectors
def vec2(x, y)
  RL::Vector2.new(x: x, y: y)
end

# Helper to create test rectangles
def rect(x, y, w, h)
  RL::Rectangle.new(x: x, y: y, width: w, height: h)
end

# Helper to check point in rectangle (since Raylib function not available in tests)
def point_in_rect?(point : RL::Vector2, rect : RL::Rectangle) : Bool
  point.x >= rect.x &&
    point.x <= rect.x + rect.width &&
    point.y >= rect.y &&
    point.y <= rect.y + rect.height
end

# Create a concrete implementation for testing
class TestGameObject < PointClickEngine::Core::GameObject
  property update_called = false
  property draw_called = false

  def update(dt : Float32)
    @update_called = true
  end

  def draw
    @draw_called = true
  end
end

# Helper for specs that need Raylib window context
module RaylibContext
  @@window_initialized = false
  @@window_width = 0
  @@window_height = 0

  def self.with_window(width = 100, height = 100, title = "Test", &block)
    # Always check if window is actually ready
    if !@@window_initialized || !RL.window_ready?
      # Close any existing window first
      if @@window_initialized && !RL.window_ready?
        @@window_initialized = false
      end

      RL.init_window(width, height, title)
      @@window_initialized = true
      @@window_width = width
      @@window_height = height
    elsif @@window_width != width || @@window_height != height
      # Window size mismatch - recreate window
      RL.close_window
      RL.init_window(width, height, title)
      @@window_width = width
      @@window_height = height
    end

    yield
  ensure
    # Don't close window here, let it persist for other tests
  end

  def self.ensure_window(width = 800, height = 600, title = "Test")
    if !@@window_initialized || !RL.window_ready?
      # Close any existing window first
      if @@window_initialized && !RL.window_ready?
        @@window_initialized = false
      end

      RL.init_window(width, height, title)
      @@window_initialized = true
      @@window_width = width
      @@window_height = height
    end
  end

  def self.cleanup
    if @@window_initialized && RL.window_ready?
      RL.close_window
      @@window_initialized = false
    end
  end

  def self.window_initialized?
    @@window_initialized && RL.window_ready?
  end
end

# Ensure window is closed at end of spec run
Spec.after_suite do
  RaylibContext.cleanup
end

# Reset Engine singleton after each test to ensure test isolation
Spec.after_each do
  if PointClickEngine::Core::Engine.instance?
    PointClickEngine::Core::Engine.reset_instance
  end
end
