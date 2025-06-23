require "./src/point_click_engine"

# Create engine
engine = PointClickEngine::Core::Engine.new(1024, 768, "Test Game")
engine.init

# Create a test scene
scene = PointClickEngine::Scenes::Scene.new("test_scene")

# Create player with proper size
player = PointClickEngine::Characters::Player.new(
  "TestPlayer", 
  Raylib::Vector2.new(x: 500f32, y: 400f32),
  Raylib::Vector2.new(x: 84f32, y: 84f32)  # 1.5x the 56x56 sprite size
)

# Add player to engine and scene
engine.player = player
scene.set_player(player)

# Add scene to engine
engine.add_scene(scene)
engine.change_scene("test_scene")

# Enable verb input
engine.enable_verb_input

# Run the game
engine.run