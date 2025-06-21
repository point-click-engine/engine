# Quick Start Guide

Welcome to the Point & Click Engine! This guide will help you create your first adventure game in minutes.

## Installation

1. Add to your `shard.yml`:
```yaml
dependencies:
  point_click_engine:
    github: point-click-engine/engine
  raylib-cr:
    github: sol-vin/raylib-cr
```

2. Run:
```bash
shards install
```

## Your First Game

Create a file called `my_game.cr`:

```crystal
require "point_click_engine"

# Create the game window
game = PointClickEngine::Game.new(800, 600, "My First Adventure")

# Create the main scene
main_scene = PointClickEngine::Scene.new("main_room")
main_scene.load_background("assets/room.png")

# Add an interactive door
door = PointClickEngine::Hotspot.new(
  "door",
  RL::Vector2.new(x: 300, y: 200),
  RL::Vector2.new(x: 100, y: 150)
)
door.description = "A wooden door"
door.cursor_type = PointClickEngine::Hotspot::CursorType::Hand
door.on_click = ->{ puts "You clicked the door!" }
main_scene.add_hotspot(door)

# Create the player
player = PointClickEngine::Player.new(
  "Hero",
  RL::Vector2.new(x: 100, y: 400),
  RL::Vector2.new(x: 32, y: 48)
)
main_scene.add_character(player)

# Add the scene and start
game.add_scene(main_scene)
game.change_scene("main_room")
game.run
```

## Running Your Game

```bash
crystal run my_game.cr
```

## Next Steps

### 1. Add More Scenes

```crystal
hallway = PointClickEngine::Scene.new("hallway")
hallway.load_background("assets/hallway.png")

# Make the door lead to the hallway
door.on_click = ->{ game.change_scene("hallway") }

game.add_scene(hallway)
```

### 2. Add Inventory Items

```crystal
# Create an item
key = PointClickEngine::InventoryItem.new("Key", "A rusty old key")
key.icon_path = "assets/key_icon.png"

# Place it in the scene as a hotspot
key_hotspot = PointClickEngine::Hotspot.new(
  "key",
  RL::Vector2.new(x: 500, y: 450),
  RL::Vector2.new(x: 32, y: 32)
)
key_hotspot.on_click = ->{
  game.inventory.add_item(key)
  main_scene.remove_hotspot(key_hotspot)
  game.show_message("You found a key!")
}
main_scene.add_hotspot(key_hotspot)
```

### 3. Add Character Dialog

```crystal
# Create an NPC
guard = PointClickEngine::NPC.new(
  "Guard",
  RL::Vector2.new(x: 600, y: 400),
  RL::Vector2.new(x: 32, y: 48)
)

# Simple dialog
guard.on_interact = ->{
  dialog = PointClickEngine::Dialog.new(
    "Halt! No one passes without the key!",
    guard.position + RL::Vector2.new(x: 0, y: -60),
    RL::Vector2.new(x: 200, y: 60)
  )
  dialog.character_name = "Guard"
  game.show_dialog(dialog)
}

main_scene.add_character(guard)
```

### 4. Use the Scene Editor

Instead of coding everything, use the visual scene editor:

```bash
./editor.sh
```

1. Create a new project
2. Import your background images
3. Place hotspots visually
4. Set properties in the panel
5. Export to YAML
6. Load in your game:

```crystal
main_scene = PointClickEngine::Scene.from_yaml("scenes/main_room.yml")
```

## Common Patterns

### Door with Key

```crystal
door.on_click = ->{
  if game.inventory.has_item?("Key")
    game.inventory.remove_item("Key")
    game.change_scene("next_room")
    game.play_sound("door_open")
  else
    game.show_message("The door is locked")
  end
}
```

### Combinable Items

```crystal
rope = PointClickEngine::InventoryItem.new("Rope", "A sturdy rope")
hook = PointClickEngine::InventoryItem.new("Hook", "A metal hook")

rope.combinable_with = ["Hook"]
game.inventory.on_items_combined = ->(item1, item2, action) {
  grappling_hook = PointClickEngine::InventoryItem.new(
    "Grappling Hook",
    "Perfect for climbing"
  )
  game.inventory.add_item(grappling_hook)
  game.inventory.remove_item(item1)
  game.inventory.remove_item(item2)
}
```

### Save/Load

```crystal
# Enable quick save/load
game.on_key_pressed = ->(key) {
  case key
  when .f5
    PointClickEngine::SaveSystem.save_game(game, "quicksave")
    game.show_message("Game Saved")
  when .f9
    PointClickEngine::SaveSystem.load_game(game, "quicksave")
  end
}
```

## Tips

1. **Start Simple**: Make one room work before adding more
2. **Use the Editor**: Visual editing is faster for scene layout
3. **Test Often**: Run your game frequently to catch issues early
4. **Check Examples**: The `example/` folder has many demonstrations
5. **Read the Docs**: [FEATURES.md](FEATURES.md) has detailed information

## Getting Help

- 📖 [Full Documentation](FEATURES.md)
- 💡 [Example Games](example/)
- 🐛 [Report Issues](https://github.com/point-click-engine/engine/issues)
- 💬 [Discord Community](https://discord.gg/crystal-lang)

Happy game making! 🎮