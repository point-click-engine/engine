require "../src/point_click_engine"

# Minimal test to verify graphics system works
RL.init_window(800, 600, "Minimal Graphics Test")
RL.set_target_fps(60)

display = PointClickEngine::Graphics::Display.new(800, 600)
renderer = PointClickEngine::Graphics::Renderer.new(display)

until RL.close_window?
  RL.begin_drawing
  RL.clear_background(RL::BLACK)

  renderer.render do |context|
    context.draw_rectangle(100, 100, 200, 200, RL::GREEN)
    context.draw_text("Graphics System Working!", 250, 300, 20, RL::WHITE)
  end

  RL.end_drawing
end

RL.close_window
