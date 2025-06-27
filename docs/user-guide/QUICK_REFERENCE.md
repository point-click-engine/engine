# Point & Click Engine Quick Reference

## File Structure
```
game/
├── game_config.yaml    # Main configuration
├── main.cr            # Entry point (~45 lines)
├── scenes/*.yaml      # Scene definitions
├── scripts/*.lua      # Scene logic
├── dialogs/*.yaml     # Dialog trees
├── quests/*.yaml      # Quest definitions
├── items/*.yaml       # Item definitions
└── assets/           # Images, sounds, etc.
```

## Minimal game_config.yaml
```yaml
game:
  title: "My Game"

window:
  width: 1024
  height: 768

player:
  sprite_path: "assets/sprites/player.png"
  sprite:
    frame_width: 64
    frame_height: 64
    columns: 8
    rows: 4

assets:
  scenes: ["scenes/*.yaml"]

start_scene: "intro"
```

## Minimal main.cr
```crystal
require "point_click_engine"

config = PointClickEngine::Core::GameConfig.from_file("game_config.yaml")
engine = config.create_engine
engine.show_main_menu
engine.run
```

## Scene YAML Structure
```yaml
name: room_name
background_path: assets/backgrounds/room.png
script_path: scripts/room.lua
enable_camera_scrolling: true  # For scenes larger than viewport (default: true)

hotspots:
  - name: object
    x: 100
    y: 200
    width: 50
    height: 50
    description: "An object"
    
  - name: exit_door
    type: exit
    target_scene: next_room
    target_position: {x: 100, y: 400}

characters:
  - name: npc
    position: {x: 300, y: 400}
    sprite_path: assets/sprites/npc.png
```

## Common Lua Script Functions

### Scene Lifecycle
```lua
function on_enter()
  -- Called when entering scene
end

function on_exit()
  -- Called when leaving scene
end
```

### Hotspot Handlers
```lua
hotspot.on_click("name", function()
  -- Handle click
end)

hotspot.on_verb("name", "look", function()
  -- Handle look action
end)
```

### Character Handlers
```lua
character.on_interact("npc", function()
  start_dialog("npc_dialog")
end)
```

## Lua API Quick Reference

### Scene Management
```lua
change_scene("scene_name")
get_current_scene()
set_hotspot_visible("name", true/false)
set_hotspot_active("name", true/false)
```

### Dialog
```lua
show_message("text")
show_dialog("character", "text")
show_dialog_choices("prompt", {"Option 1", "Option 2"}, callback)
start_dialog("dialog_file")
```

### Inventory
```lua
add_to_inventory("item_name")
remove_from_inventory("item_name")
has_item("item_name")
get_selected_item()
```

### Game State
```lua
set_flag("name", true/false)
get_flag("name")
set_variable("name", value)
get_variable("name", default)
```

### Audio
```lua
play_sound("sound_name")
play_music("music_name", loop)
stop_music()
```

### Character Control
```lua
move_player(x, y)
player_walk_to(x, y)
play_character_animation("name", "anim")
```

## Dialog YAML Structure
```yaml
id: dialog_name
start_node: greeting

nodes:
  - id: greeting
    speaker: NPC
    text: "Hello!"
    choices:
      - text: "Hi there"
        next: response
      - text: "Goodbye"
        
  - id: response
    speaker: NPC
    text: "How are you?"
```

## Quest YAML Structure
```yaml
quests:
  - id: find_key
    name: "Find the Key"
    description: "Find the missing key"
    category: main
    objectives:
      - id: search_room
        description: "Search the room"
        completion_conditions:
          flag: found_key
```

## Item YAML Structure
```yaml
items:
  key:
    name: key
    display_name: "Brass Key"
    description: "An old brass key"
    icon_path: "assets/items/key.png"
    usable_on: ["door", "cabinet"]
```

## Common Patterns

### Door/Exit
```lua
hotspot.on_click("door", function()
  if has_item("key") then
    play_sound("unlock")
    change_scene("next_room")
  else
    show_message("The door is locked.")
  end
end)
```

### Item Pickup
```lua
hotspot.on_click("key", function()
  add_to_inventory("key")
  set_hotspot_visible("key", false)
  play_sound("pickup")
  show_message("You found a key!")
end)
```

### NPC Dialog
```lua
character.on_interact("guard", function()
  if get_flag("has_permission") then
    show_dialog("guard", "You may pass.")
    set_hotspot_active("gate", true)
  else
    start_dialog("guard_dialog")
  end
end)
```

### Conditional Visibility
```yaml
hotspots:
  - name: secret_door
    conditions:
      all_of:
        - flag: found_clue
        - variable: puzzle_solved
          value: true
```

## Debugging

### Enable Debug Mode
```yaml
settings:
  debug_mode: true
  show_fps: true
```

### Debug Hotkeys
- `F1` - Toggle debug overlay
- `Tab` - Highlight hotspots
- `F5` - Quick save
- `F9` - Quick load

## Performance Tips

1. Keep background images under 2MB
2. Use OGG for music, WAV for short sounds
3. Optimize sprite sheets (power of 2 dimensions)
4. Limit concurrent particle effects
5. Use `visible: false` instead of removing hotspots

## Build Commands

### Development
```bash
crystal build main.cr
```

### Release
```bash
crystal build main.cr --release
```

### With Debug Info
```bash
crystal build main.cr --debug
```

## Common Issues

### Scene Won't Load
- Check file path in game_config.yaml
- Verify YAML syntax
- Ensure background image exists

### Script Errors
- Check Lua syntax
- Verify function names
- Look for typos in hotspot names

### Dialog Not Working
- Validate YAML structure
- Check node IDs match
- Ensure start_node exists

## Keyboard Controls

### General
- `ESC` - Pause menu / Cancel
- `F1` - Toggle debug mode
- `F5` - Toggle camera edge scrolling
- `F11` - Toggle fullscreen
- `Tab` - Toggle hotspot highlights
- `I` - Show/hide inventory
- `Space` - Skip dialog

### Camera Controls (when scrolling enabled)
- Mouse to screen edges - Scroll camera
- Camera automatically follows player character

### Camera Effects (via CameraManager)
The engine provides advanced camera effects:
- **Shake** - Screen shake for earthquakes/impacts
- **Zoom** - Smooth zoom in/out
- **Pan** - Smooth camera movement
- **Follow** - Follow characters with deadzone
- **Sway** - Sea-like motion for boat scenes

See `docs/features/camera_system.md` for detailed camera documentation.

## Resources

- Full API: `GAME_FORMAT_SPECIFICATION.md` (in this directory)
- Editor Guide: `../tools/EDITOR_DEVELOPMENT.md`
- Examples: `crystal_mystery/` directory
- Templates: `templates/` directory