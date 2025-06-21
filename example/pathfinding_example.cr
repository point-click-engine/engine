require "../src/point_click_engine"

# Example demonstrating pathfinding
class PathfindingExample < PointClickEngine::Core::Game
  def initialize
    super(title: "Pathfinding Example", width: 1280, height: 960)
  end

  def load_content
    # Create a scene
    scene = PointClickEngine::Scenes::Scene.new("pathfinding_demo")
    scene.enable_pathfinding = true
    scene.navigation_cell_size = 32

    # Add background
    bg_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/room.png")
    scene.set_background(bg_texture)

    # Add player
    player = PointClickEngine::Characters::Player.new("hero", 100, 400, 32, 48)
    player_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/character.png")
    player.sprite = PointClickEngine::Graphics::AnimatedSprite.new(player_texture, 32, 48)
    player.sprite.not_nil!.add_animation("idle", [0])
    player.sprite.not_nil!.add_animation("walk", [0, 1, 2, 3])
    player.sprite.not_nil!.play("idle")
    player.walking_speed = 150.0
    player.use_pathfinding = true
    scene.add_character(player)
    scene.player = player

    # Add obstacles (furniture that blocks movement)
    # Table
    table = PointClickEngine::Scenes::Hotspot.new("table",
      Raylib::Vector2.new(x: 400, y: 300),
      Raylib::Vector2.new(x: 120, y: 80))
    table.description = "A sturdy wooden table"
    table.blocks_movement = true
    table.debug_color = Raylib::BROWN
    table.on_click = -> { puts "You examine the table." }
    scene.add_hotspot(table)

    # Bookshelf
    bookshelf = PointClickEngine::Scenes::Hotspot.new("bookshelf",
      Raylib::Vector2.new(x: 600, y: 100),
      Raylib::Vector2.new(x: 100, y: 200))
    bookshelf.description = "A tall bookshelf filled with books"
    bookshelf.blocks_movement = true
    bookshelf.debug_color = Raylib::DARKBROWN
    bookshelf.on_click = -> { puts "The bookshelf contains many interesting titles." }
    scene.add_hotspot(bookshelf)

    # Couch
    couch = PointClickEngine::Scenes::Hotspot.new("couch",
      Raylib::Vector2.new(x: 200, y: 500),
      Raylib::Vector2.new(x: 180, y: 80))
    couch.description = "A comfortable looking couch"
    couch.blocks_movement = true
    couch.debug_color = Raylib::DARKGREEN
    couch.on_click = -> { puts "The couch looks very comfortable." }
    scene.add_hotspot(couch)

    # Plant
    plant = PointClickEngine::Scenes::Hotspot.new("plant",
      Raylib::Vector2.new(x: 750, y: 450),
      Raylib::Vector2.new(x: 60, y: 60))
    plant.description = "A healthy potted plant"
    plant.blocks_movement = true
    plant.debug_color = Raylib::GREEN
    plant.on_click = -> { puts "A beautiful ficus plant." }
    scene.add_hotspot(plant)

    # Add NPCs that wander around
    npc1 = PointClickEngine::Characters::NPC.new("guard", 300, 200, 32, 48)
    npc1.sprite = PointClickEngine::Graphics::AnimatedSprite.new(player_texture, 32, 48)
    npc1.sprite.not_nil!.add_animation("idle", [0])
    npc1.sprite.not_nil!.add_animation("walk", [0, 1, 2, 3])
    npc1.sprite.not_nil!.play("idle")

    # Create patrol behavior with pathfinding
    patrol_points = [
      Raylib::Vector2.new(x: 300, y: 200),
      Raylib::Vector2.new(x: 700, y: 200),
      Raylib::Vector2.new(x: 700, y: 500),
      Raylib::Vector2.new(x: 300, y: 500),
    ]
    patrol = PointClickEngine::Characters::AI::PatrolBehavior.new(patrol_points, 80.0f32)
    npc1.set_ai_behavior(patrol)
    npc1.use_pathfinding = true
    scene.add_character(npc1)

    # Add interactive exit
    door = PointClickEngine::Scenes::Hotspot.new("door",
      Raylib::Vector2.new(x: 900, y: 350),
      Raylib::Vector2.new(x: 80, y: 120))
    door.description = "A door leading outside"
    door.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Hand
    door.on_click = -> { puts "The door is locked." }
    scene.add_hotspot(door)

    PointClickEngine::Core::Engine.instance.add_scene(scene)
    PointClickEngine::Core::Engine.instance.change_scene("pathfinding_demo")
  end

  def update(dt : Float32)
    super(dt)

    # Toggle debug mode with F1
    if Raylib.is_key_pressed(Raylib::KeyboardKey::F1)
      PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
    end

    # Show pathfinding instructions
    if PointClickEngine::Core::Engine.debug_mode
      Raylib.draw_text("Pathfinding Demo - Click to move", 10, 85, 20, Raylib::WHITE)
      Raylib.draw_text("F1: Toggle Debug | N: Show Navigation Grid", 10, 110, 16, Raylib::WHITE)
      Raylib.draw_text("The character will automatically navigate around obstacles", 10, 130, 16, Raylib::WHITE)
    end
  end
end

# Run the example
example = PathfindingExample.new
example.run
