require "spec"
require "../src/point_click_engine"
require "raylib-cr"

# Helper to create test vectors
def vec2(x, y)
  vec = RL::Vector2.new
  vec.x = x
  vec.y = y
  vec
end

# Helper to create test rectangles
def rect(x, y, w, h)
  rectangle = RL::Rectangle.new #(x, y, w, h)
rectangle.x = x
rectangle.y = y
rectangle.w = w
rectangle.h = h
rectangle
end

# Create a concrete implementation for testing
class TestGameObject < PointClickEngine::GameObject
  property update_called = false
  property draw_called = false

  def update(dt : Float32)
    @update_called = true
  end

  def draw
    @draw_called = true
  end
end
