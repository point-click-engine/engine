require "spec"
require "../src/point_click_engine"

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
