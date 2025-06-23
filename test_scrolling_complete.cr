require "./src/point_click_engine"

# Create engine
engine = PointClickEngine::Core::Engine.new(1024, 768, "Complete Scrolling Test")
engine.init

# Create a test scene with a larger background
test_scene = PointClickEngine::Scenes::Scene.new("test_scroll")
test_scene.enable_camera_scrolling = true

# Create a large colored background texture
test_texture = RL.load_render_texture(2048, 1536)
RL.begin_texture_mode(test_texture)

# Gradient background
(0...1536).each do |y|
  color = RL::Color.new(
    r: (50 + y * 0.1).to_u8,
    g: (100 + y * 0.05).to_u8, 
    b: (150 - y * 0.05).to_u8,
    a: 255
  )
  RL.draw_line(0, y, 2048, y, color)
end

# Draw a grid pattern
grid_size = 64
(0...2048).step(grid_size) do |x|
  RL.draw_line(x, 0, x, 1536, RL::Color.new(r: 100, g: 100, b: 100, a: 100))
end
(0...1536).step(grid_size) do |y|
  RL.draw_line(0, y, 2048, y, RL::Color.new(r: 100, g: 100, b: 100, a: 100))
end

# Draw reference markers
markers = [
  {x: 200, y: 768, text: "LEFT", color: RL::RED},
  {x: 1024, y: 768, text: "CENTER", color: RL::GREEN},
  {x: 1848, y: 768, text: "RIGHT", color: RL::BLUE},
  {x: 1024, y: 200, text: "TOP", color: RL::YELLOW},
  {x: 1024, y: 1336, text: "BOTTOM", color: RL::PURPLE}
]

markers.each do |marker|
  # Draw marker circle
  RL.draw_circle(marker[:x], marker[:y], 50.0, marker[:color])
  # Draw text
  text_width = RL.measure_text(marker[:text], 32)
  RL.draw_text(marker[:text], marker[:x] - text_width/2, marker[:y] - 16, 32, RL::WHITE)
end

# Draw coordinate labels
(0...2048).step(256) do |x|
  RL.draw_text("X:#{x}", x + 10, 10, 20, RL::WHITE)
end
(0...1536).step(256) do |y|
  RL.draw_text("Y:#{y}", 10, y + 10, 20, RL::WHITE)
end

RL.end_texture_mode

# Set the texture as the scene background
test_scene.background = test_texture.texture
test_scene.background_path = "test_texture"

# Create player with animated sprite
player = PointClickEngine::Characters::Player.new("Player", RL::Vector2.new(x: 1024.0, y: 768.0), RL::Vector2.new(x: 48, y: 96))
player.visible = true

# Create a simple animated sprite for the player
player_texture = RL.load_render_texture(48, 96)
RL.begin_texture_mode(player_texture)
RL.clear_background(RL::BLANK)
# Draw a simple character shape
RL.draw_rectangle(12, 0, 24, 48, RL::DARKBLUE)  # Body
RL.draw_circle(24, 24, 12.0, RL::BEIGE)        # Head
RL.draw_rectangle(16, 48, 8, 48, RL::DARKBLUE) # Left leg
RL.draw_rectangle(24, 48, 8, 48, RL::DARKBLUE) # Right leg
RL.end_texture_mode

# Create sprite for player
player_sprite = PointClickEngine::Graphics::AnimatedSprite.new(player.position, 48, 96, 1)
player_sprite.texture = player_texture.texture
player.sprite = player_sprite

test_scene.set_player(player)

# Add interactive hotspots at each marker
markers.each_with_index do |marker, i|
  hotspot = PointClickEngine::Scenes::Hotspot.new(
    "marker_#{i}", 
    RL::Vector2.new(x: marker[:x] - 75, y: marker[:y] - 75), 
    RL::Vector2.new(x: 150, y: 150)
  )
  hotspot.on_click = ->{ 
    dialog = PointClickEngine::UI::Dialog.new(
      "You clicked the #{marker[:text]} marker at (#{marker[:x]}, #{marker[:y]})",
      RL::Vector2.new(x: 50, y: 600),
      RL::Vector2.new(x: 900, y: 100)
    )
    engine.show_dialog(dialog)
  }
  test_scene.add_hotspot(hotspot)
end

# Create walkable area for the entire scene
walkable_area = PointClickEngine::Scenes::WalkableArea.new
walkable_region = PointClickEngine::Scenes::PolygonRegion.new("main_area", true)
walkable_region.vertices = [
  RL::Vector2.new(x: 50, y: 400),
  RL::Vector2.new(x: 2000, y: 400),
  RL::Vector2.new(x: 2000, y: 1400),
  RL::Vector2.new(x: 50, y: 1400)
]
walkable_area.regions << walkable_region
test_scene.walkable_area = walkable_area

# Add scene to engine and set as current
engine.add_scene(test_scene)
engine.change_scene("test_scroll")

# Set debug mode on by default
PointClickEngine::Core::Engine.debug_mode = true

# Create UI overlay for help text
help_visible = true
help_text = [
  "=== CAMERA SCROLLING TEST ===",
  "Mouse to edges: Scroll camera",
  "Click: Move player to position", 
  "F1: Toggle debug mode",
  "F5: Toggle edge scrolling",
  "Tab: Toggle hotspot highlights",
  "H: Toggle this help",
  "ESC: Pause menu"
]

# Main update callback
engine.on_update = ->(dt : Float32) do
  # Toggle help with H key
  if RL.key_pressed?(RL::KeyboardKey::H)
    help_visible = !help_visible
  end
  
  # Draw help text (screen space, not affected by camera)
  if help_visible
    # Draw help background
    RL.draw_rectangle(10, 10, 350, help_text.size * 25 + 20, RL::Color.new(r: 0, g: 0, b: 0, a: 200))
    
    # Draw help text
    help_text.each_with_index do |line, i|
      RL.draw_text(line, 20, 20 + i * 25, 20, RL::WHITE)
    end
  end
  
  # Draw camera info
  if camera = engine.camera
    info_text = [
      "Camera: #{camera.position.x.to_i}, #{camera.position.y.to_i}",
      "Player: #{player.position.x.to_i}, #{player.position.y.to_i}",
      "Edge scroll: #{camera.edge_scroll_enabled ? "ON" : "OFF"}",
      "Scene size: #{test_scene.background.try(&.width) || 0} x #{test_scene.background.try(&.height) || 0}"
    ]
    
    y_offset = help_visible ? (help_text.size * 25 + 40) : 10
    
    # Draw info background
    RL.draw_rectangle(10, y_offset, 350, info_text.size * 20 + 10, RL::Color.new(r: 0, g: 0, b: 0, a: 150))
    
    # Draw info text
    info_text.each_with_index do |line, i|
      RL.draw_text(line, 20, y_offset + 5 + i * 20, 16, RL::LIGHTGRAY)
    end
  end
end

# Run the game
engine.run

# Cleanup
RL.unload_render_texture(test_texture)
RL.unload_render_texture(player_texture)