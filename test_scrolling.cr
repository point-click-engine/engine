require "./src/point_click_engine"

# Create engine
engine = PointClickEngine::Core::Engine.new(1024, 768, "Scrolling Test")
engine.init

# Create a test scene with a larger background
test_scene = PointClickEngine::Scenes::Scene.new("test_scroll")
test_scene.enable_camera_scrolling = true

# Create a simple colored background texture for testing
# This creates a 2048x1536 texture (2x the viewport size)
test_texture = RL.load_render_texture(2048, 1536)
RL.begin_texture_mode(test_texture)
RL.clear_background(RL::Color.new(r: 50, g: 100, b: 150, a: 255))

# Draw a grid pattern
grid_size = 64
(0...2048).step(grid_size) do |x|
  RL.draw_line(x, 0, x, 1536, RL::Color.new(r: 100, g: 100, b: 100, a: 100))
end
(0...1536).step(grid_size) do |y|
  RL.draw_line(0, y, 2048, y, RL::Color.new(r: 100, g: 100, b: 100, a: 100))
end

# Draw markers at different positions
RL.draw_text("LEFT", 100, 768, 48, RL::WHITE)
RL.draw_text("CENTER", 1000, 768, 48, RL::WHITE)
RL.draw_text("RIGHT", 1800, 768, 48, RL::WHITE)

# Draw position indicators
(0...2048).step(256) do |x|
  RL.draw_text("X:#{x}", x + 10, 10, 20, RL::WHITE)
end

RL.end_texture_mode

# Set the texture as the scene background
test_scene.background = test_texture.texture
test_scene.background_path = "test_texture"

# Create player
player = PointClickEngine::Characters::Player.new("Player", RL::Vector2.new(x: 512.0, y: 768.0), RL::Vector2.new(x: 32, y: 64))
test_scene.set_player(player)

# Add some hotspots
left_hotspot = PointClickEngine::Scenes::Hotspot.new("left_area", RL::Vector2.new(x: 100, y: 600), RL::Vector2.new(x: 200, y: 300))
left_hotspot.on_click = -> { puts "Clicked left area!" }

center_hotspot = PointClickEngine::Scenes::Hotspot.new("center_area", RL::Vector2.new(x: 900, y: 600), RL::Vector2.new(x: 200, y: 300))
center_hotspot.on_click = -> { puts "Clicked center area!" }

right_hotspot = PointClickEngine::Scenes::Hotspot.new("right_area", RL::Vector2.new(x: 1700, y: 600), RL::Vector2.new(x: 200, y: 300))
right_hotspot.on_click = -> { puts "Clicked right area!" }

test_scene.add_hotspot(left_hotspot)
test_scene.add_hotspot(center_hotspot)
test_scene.add_hotspot(right_hotspot)

# Add scene to engine and set as current
engine.add_scene(test_scene)
engine.change_scene("test_scroll")

# Add help text
engine.on_update = ->(dt : Float32) do
  # Draw help text (in screen coordinates, not world)
  RL.draw_text("Move mouse to edges to scroll | F5: Toggle edge scroll | Click to move player", 10, 40, 20, RL::WHITE)
  if camera = engine.camera
    RL.draw_text("Camera: #{camera.position.x.to_i}, #{camera.position.y.to_i} | Edge scroll: #{camera.edge_scroll_enabled}", 10, 65, 20, RL::WHITE)
  end
end

# Run the game
engine.run

# Cleanup
RL.unload_render_texture(test_texture)
