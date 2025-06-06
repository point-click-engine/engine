# Lua Scripting in Point & Click Engine

The Point & Click Engine now supports Lua scripting for dynamic game behavior, allowing you to create interactive characters, complex game logic, and event-driven gameplay without recompiling your Crystal code.

## Features

- **Runtime Script Execution**: Load and execute Lua scripts during gameplay
- **Character AI**: Create scriptable characters with custom behaviors
- **Event System**: Event-driven programming with custom events
- **Game API**: Comprehensive Lua API for engine functionality
- **Hot Reloading**: Scripts can be modified and reloaded during development

## Quick Start

### 1. Creating a Scriptable Character

```crystal
# Create a character that can be controlled by Lua scripts
character = PointClickEngine::ScriptableCharacter.new(
  "wizard",
  RL::Vector2.new(x: 300, y: 400),
  RL::Vector2.new(x: 64, y: 64)
)

# Load a script file
character.load_script("scripts/wizard_behavior.lua")

# Or set script content directly
character.set_script(<<-LUA
  function on_interact(player_name)
    character.say(character_name, "Hello, adventurer!")
  end
LUA
)
```

### 2. Basic Script Structure

```lua
-- Character initialization
function on_init()
    log("Character initialized")
end

-- Called every update cycle
function on_update(dt)
    -- Custom update logic
end

-- Player interaction
function on_interact(player_name)
    character.say(character_name, "Hello!")
end

-- When player looks at character
function on_look()
    dialog.show("This is a mysterious character.")
end

-- When player talks to character
function on_talk()
    character.say(character_name, "How can I help you?")
end
```

## Lua API Reference

### Character API

```lua
-- Make character speak
character.say(character_name, "Hello!")

-- Move character to position
character.move_to(character_name, x, y)

-- Get character position
local pos = character.get_position(character_name)
print(pos.x, pos.y)

-- Play animation
character.set_animation(character_name, "walk")
```

### Scene API

```lua
-- Change to different scene
scene.change("next_room")

-- Get current scene name
local current = scene.get_current()

-- Add hotspot to current scene
scene.add_hotspot("treasure", x, y, width, height)
```

### Inventory API

```lua
-- Add item to inventory
inventory.add_item("key", "A golden key")

-- Remove item
inventory.remove_item("key")

-- Check if player has item
if inventory.has_item("key") then
    -- Player has the key
end

-- Get currently selected item
local selected = inventory.get_selected()
```

### Dialog API

```lua
-- Show simple dialog
dialog.show("Welcome to the castle!")

-- Show dialog with character name
dialog.show("How can I help you?", "wizard")

-- Show choices (TODO: Implementation pending)
dialog.show_choices("What would you like?", {"Option 1", "Option 2"}, "merchant")
```

### Game Utility API

```lua
-- Save game
game.save("savegame.yaml")

-- Load game
game.load("savegame.yaml")

-- Debug logging
game.debug_log("Debug message here")

-- Get current time
local time = game.get_time()

-- General logging
log("This message appears in console")
```

### Event System

```lua
-- Register event handler
register_event_handler("player_moved", function(data)
    log("Player moved to " .. data.x .. ", " .. data.y)
end)

-- Trigger custom event (from Crystal code)
engine.event_system.trigger_event("custom_event", {
    "message" => "Something happened!"
})
```

## Built-in Events

The engine automatically triggers these events:

- `player_moved` - When player moves
- `player_interact` - When player interacts with something
- `character_speak` - When character says something
- `character_animation_complete` - When animation finishes
- `character_reached_target` - When character finishes moving
- `scene_entered` - When entering a scene
- `scene_exited` - When leaving a scene
- `item_added` - When item added to inventory
- `item_removed` - When item removed from inventory
- `dialog_started` - When dialog begins
- `dialog_ended` - When dialog ends

## Advanced Usage

### Custom Properties

```lua
-- Set custom property on character
this_character.custom_properties["mood"] = "happy"

-- Read custom property
local mood = this_character.custom_properties["mood"] or "neutral"
```

### Event Handlers in Scripts

```lua
-- Handle movement completion
function on_movement_complete()
    log("Character reached destination")
    character.set_animation(character_name, "idle")
end

-- Handle animation completion
function on_animation_complete(animation_name)
    log("Animation completed: " .. animation_name)
end
```

### Simple NPC vs Scriptable Character

```crystal
# Simple NPC - uses basic dialogue system
simple_npc = PointClickEngine::SimpleNPC.new("guard", position, size)
simple_npc.add_dialogue("Hello!")
simple_npc.add_dialogue("How can I help you?")

# Scriptable Character - full Lua control
scriptable_char = PointClickEngine::ScriptableCharacter.new("wizard", position, size)
scriptable_char.load_script("wizard.lua")
```

## Error Handling

Scripts are executed in a safe environment. If a script error occurs, it will be logged to the console but won't crash the game:

```
Script error: attempt to call nil value
Script function error: undefined function 'invalid_function'
```

## Performance Tips

1. **Update Intervals**: Use `update_interval` property to control how often `on_update` is called
2. **Event Handlers**: Prefer event-driven logic over polling in `on_update`
3. **Local Variables**: Use local variables in Lua for better performance
4. **Minimize API Calls**: Cache frequently accessed data

```lua
-- Set update interval to 2 seconds instead of every frame
this_character.update_interval = 2.0

-- Use local variables
local function handle_interaction()
    local player_pos = character.get_position("player")
    -- Process interaction
end
```

## Example Projects

See the `example/` directory for complete examples:

- `scripting_example.cr` - Basic scripting integration
- `scripts/example_character.lua` - Comprehensive character script
- `scripts/` - Additional script examples

## Integration with Crystal Code

The scripting system is fully integrated with the Crystal engine:

```crystal
# Access the script engine
if script_engine = engine.script_engine
  # Execute arbitrary Lua code
  script_engine.execute_script("log('Hello from Crystal!')")
  
  # Call Lua function with arguments
  script_engine.call_function("custom_function", arg1, arg2)
  
  # Set global variables
  script_engine.set_global("player_health", 100)
end

# Trigger events from Crystal
engine.event_system.trigger_event("custom_event", {
  "data" => "value"
})
```

This powerful scripting system allows you to create dynamic, interactive games where behavior can be modified without recompiling the engine!