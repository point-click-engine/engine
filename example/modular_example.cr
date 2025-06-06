# Example using the modular Point & Click Engine

require "../src/point_click_engine"

# Create a simple game using the modular engine
engine = PointClickEngine::Core::Engine.new(800, 600, "Modular Point & Click Game")

# Create a scene
scene = PointClickEngine::Scenes::Scene.new("Main Room")
scene.load_background("assets/background.png")

# Create a player
player = PointClickEngine::Characters::Player.new("Hero", RL::Vector2.new(x: 100, y: 300), RL::Vector2.new(x: 32, y: 48))
player.load_spritesheet("assets/player.png", 32, 48)

# Create an NPC
npc = PointClickEngine::Characters::NPC.new("Guard", RL::Vector2.new(x: 400, y: 300), RL::Vector2.new(x: 32, y: 48))
npc.add_dialogue("Hello there, traveler!")
npc.add_dialogue("Welcome to our town.")

# Add patrol behavior to NPC
waypoints = [
  RL::Vector2.new(x: 350, y: 300),
  RL::Vector2.new(x: 450, y: 300),
  RL::Vector2.new(x: 450, y: 250),
  RL::Vector2.new(x: 350, y: 250)
]
patrol_behavior = PointClickEngine::Characters::AI::PatrolBehavior.new(waypoints)
npc.set_ai_behavior(patrol_behavior)

# Create a hotspot
door_hotspot = PointClickEngine::Scenes::Hotspot.new("Door", RL::Vector2.new(x: 700, y: 200), RL::Vector2.new(x: 50, y: 100))
door_hotspot.on_click = ->{ puts "Door clicked!" }

# Add everything to the scene
scene.set_player(player)
scene.add_character(npc)
scene.add_hotspot(door_hotspot)

# Add scene to engine
engine.add_scene(scene)
engine.change_scene("Main Room")

# Save the game state to demonstrate YAML serialization
engine.save_game("example_save.yaml")

# Run the game
# engine.run