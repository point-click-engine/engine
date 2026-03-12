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

def spec_fixture_path(*parts : String) : String
  File.join(File.expand_path("fixtures", __DIR__), *parts)
end

# =============================================================================
# SHARED WINDOW MANAGEMENT FOR SPECS
# =============================================================================
#
# PROBLEM: Running all specs together causes hanging on macOS due to
# GLFW/OpenGL context exhaustion from repeated window init/close cycles.
#
# SOLUTION: Use a shared window that persists across all tests.
# - RaylibContext.ensure_window() creates or reuses the shared window
# - RaylibContext.release_window() marks the window as available (doesn't close)
# - The window is only closed at the end of the test suite
#
# MIGRATION: Replace direct RL.init_window/close_window calls with:
#   RaylibContext.ensure_window(width, height, "Test")
#   # ... test code ...
#   RaylibContext.release_window
#
# Or use the helper macro:
#   with_test_window(width, height) do
#     # ... test code ...
#   end
# =============================================================================

# Primary shared window manager for specs
module RaylibContext
  @@window_initialized = false
  @@window_width = 0
  @@window_height = 0
  @@init_count = 0
  @@release_count = 0
  @@current_owner : String? = nil

  # Ensure a window exists with at least the requested dimensions
  # If a window already exists, it will be resized if needed (never recreated)
  def self.ensure_window(width : Int32 = 800, height : Int32 = 600, title : String = "Test")
    @@init_count += 1

    if !@@window_initialized || !window_actually_ready?
      # No window exists, create one
      @@window_initialized = false
      RL.init_window(width, height, title)
      @@window_initialized = true
      @@window_width = width
      @@window_height = height
    elsif @@window_width < width || @@window_height < height
      # Window exists but is too small, resize it
      new_width = {@@window_width, width}.max
      new_height = {@@window_height, height}.max
      RL.set_window_size(new_width, new_height)
      @@window_width = new_width
      @@window_height = new_height
    end

    # Poll events to keep GLFW responsive
    poll_events_if_needed
  end

  # Mark that the test is done with the window (doesn't actually close it)
  def self.release_window
    @@release_count += 1
    @@current_owner = nil
    # Poll events to keep GLFW responsive
    poll_events_if_needed
  end

  # Block-style helper for tests
  def self.with_window(width : Int32 = 800, height : Int32 = 600, title : String = "Test", &)
    ensure_window(width, height, title)
    begin
      yield
    ensure
      release_window
    end
  end

  # Actually close the window (only called at end of test suite)
  def self.cleanup
    if @@window_initialized && window_actually_ready?
      RL.close_window
      @@window_initialized = false
      @@window_width = 0
      @@window_height = 0
    end
  end

  # Check if window is initialized through RaylibContext
  def self.window_initialized?
    @@window_initialized && window_actually_ready?
  end

  # Check if RL reports window as ready (handles both real and mock)
  private def self.window_actually_ready? : Bool
    {% if env("HEADLESS_MODE") == "true" %}
      @@window_initialized
    {% else %}
      RL.window_ready?
    {% end %}
  end

  # Poll GLFW events to prevent hanging
  def self.poll_events_if_needed
    {% if env("HEADLESS_MODE") != "true" %}
      if RL.window_ready?
        RL.poll_input_events
      end
    {% end %}
  end

  # Get statistics for debugging
  def self.stats
    {
      init_count:    @@init_count,
      release_count: @@release_count,
      initialized:   @@window_initialized,
      width:         @@window_width,
      height:        @@window_height,
    }
  end

  # Reset stats (for testing the test infrastructure)
  def self.reset_stats
    @@init_count = 0
    @@release_count = 0
  end

  # Backwards compatibility
  def self.init_count
    @@init_count
  end
end

# Convenient macro for tests that need a window
# Usage:
#   with_test_window(800, 600) do
#     # test code here
#   end
macro with_test_window(width = 800, height = 600, title = "Test", &block)
  RaylibContext.ensure_window({{width}}, {{height}}, {{title}})
  begin
    {{block.body}}
  ensure
    RaylibContext.release_window
  end
end

# Alternative: method-based helper (for cases where macro doesn't work)
def with_test_window(width : Int32 = 800, height : Int32 = 600, title : String = "Test", &)
  RaylibContext.ensure_window(width, height, title)
  begin
    yield
  ensure
    RaylibContext.release_window
  end
end

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

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

# =============================================================================
# TEST CLASSES
# =============================================================================

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

# =============================================================================
# SPEC LIFECYCLE HOOKS
# =============================================================================

# Ensure shared window exists BEFORE each test
# This is critical for macOS GLFW - the window must be created early and
# events must be polled regularly to prevent hanging
Spec.before_each do
  # Create the shared window if it doesn't exist yet
  # This ensures engine.init will see RL.window_ready? == true
  # and won't try to create a new window
  RaylibContext.ensure_window(1024, 768, "Test Suite")

  # Poll GLFW events to keep the window responsive
  RaylibContext.poll_events_if_needed
end

# Ensure window is closed at end of spec run
Spec.after_suite do
  # Print window stats for debugging
  stats = RaylibContext.stats
  if stats[:init_count] > 10
    STDERR.puts "[RaylibContext] Stats: #{stats[:init_count]} window requests, #{stats[:release_count]} releases"
  end

  # Close the shared window
  RaylibContext.cleanup
end

# Reset Engine singleton after each test to ensure test isolation
# Also poll GLFW events to prevent macOS hanging
Spec.after_each do
  if engine = PointClickEngine::Core::Engine.instance?
    # Full cleanup of all systems to prevent resource accumulation:
    # - Audio device (RAudio.close_audio_device)
    # - Shader system
    # - Script engine (Lua VM)
    # - Dialog manager
    # - Render textures/FBOs
    engine.system_manager.cleanup_systems
    engine.system_manager.renderer.try(&.cleanup)
    PointClickEngine::Core::Engine.reset_instance
  end

  PointClickEngine::Graphics::Display.reset_reference_resolution

  # Force garbage collection to clean up finalized objects
  GC.collect

  # Poll GLFW events to prevent hanging on macOS
  RaylibContext.poll_events_if_needed
end
