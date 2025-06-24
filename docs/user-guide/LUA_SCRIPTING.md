# Lua Scripting Guide for Point & Click Engine

The Point & Click Engine provides comprehensive Lua scripting support for creating dynamic, interactive games. This guide covers all aspects of the scripting system, from basic scene logic to advanced character behaviors.

## Table of Contents

1. [Overview](#overview)
2. [Scene Scripts](#scene-scripts)
3. [Hotspot and Character Handlers](#hotspot-and-character-handlers)
4. [Engine API Reference](#engine-api-reference)
5. [Event System](#event-system)
6. [Scriptable Characters](#scriptable-characters)
7. [Advanced Features](#advanced-features)
8. [Best Practices](#best-practices)
9. [Error Handling](#error-handling)
10. [Examples](#examples)

## Overview

The scripting system allows you to:
- Control scene logic and transitions
- Handle player interactions with hotspots and characters
- Manage game state, inventory, and quests
- Create dynamic character behaviors and AI
- Implement custom game mechanics
- React to engine events

Scripts are written in Lua and can be associated with scenes, characters, or loaded dynamically during gameplay.

## Scene Scripts

Each scene can have an associated Lua script that controls its behavior. Scene scripts use lifecycle functions to manage scene logic.

### Scene Lifecycle Functions

```lua
-- Called when entering the scene
function on_enter()
    -- Initialize scene state
    -- Set up hotspots
    -- Start ambient sounds
end

-- Called when leaving the scene  
function on_exit()
    -- Clean up scene resources
    -- Stop sounds
    -- Save scene state
end

-- Called every frame (dt = delta time in seconds)
function on_update(dt)
    -- Update scene logic
    -- Check conditions
    -- Handle animations
end
```

### Example Scene Script

```lua
-- kitchen_scene.lua
function on_enter()
    -- Start ambient kitchen sounds
    play_ambient("kitchen_ambience", 0.5)
    
    -- Check if quest is active
    if is_quest_active("find_recipe") then
        set_hotspot_visible("recipe_book", true)
    end
end

function on_exit()
    stop_ambient("kitchen_ambience")
end

function on_update(dt)
    -- Check if player has all ingredients
    if has_item("flour") and has_item("eggs") and has_item("milk") then
        set_hotspot_active("mixing_bowl", true)
    end
end
```

## Hotspot and Character Handlers

### Hotspot Handlers

Register handlers for player interactions with hotspots:

```lua
-- Register click handler for hotspot
hotspot.on_click("hotspot_name", function()
    -- Handle click
    show_message("You clicked the hotspot!")
end)

-- Register verb handler for specific action
hotspot.on_verb("hotspot_name", "look", function()
    -- Handle look action
    show_message("It's a mysterious object.")
end)

-- Available verbs: "walk", "look", "talk", "use", "take", "open"

-- Example: Complex door interaction
hotspot.on_verb("door", "open", function()
    if has_item("key") then
        play_sound("door_open")
        change_scene("next_room")
    else
        show_message("The door is locked.")
    end
end)

-- Example: Item interaction
hotspot.on_verb("painting", "use", function()
    if has_selected_item("magnifying_glass") then
        show_message("You notice a hidden safe behind the painting!")
        set_hotspot_visible("hidden_safe", true)
    else
        show_message("It's a beautiful painting.")
    end
end)
```

### Character Handlers

Register handlers for character interactions:

```lua
-- Register general character interaction
character.on_interact("character_name", function()
    -- Handle character interaction
    start_dialog("character_dialog.yaml")
end)

-- Register character verb handler
character.on_verb("character_name", "talk", function()
    -- Handle talk action
    if get_flag("met_character") then
        show_dialog("character_name", "Hello again!")
    else
        set_flag("met_character", true)
        show_dialog("character_name", "Nice to meet you!")
    end
end)

-- Example: Give item to character
character.on_verb("merchant", "use", function()
    if has_selected_item("gold_coin") then
        remove_from_inventory("gold_coin")
        add_to_inventory("magic_potion")
        show_dialog("merchant", "Here's your potion!")
    else
        show_dialog("merchant", "What do you want to trade?")
    end
end)
```

## Engine API Reference

### Global Objects

The following objects are available in all Lua scripts:

```lua
-- Core objects
engine          -- Engine instance
scene           -- Current scene
player          -- Player character
inventory       -- Inventory system
dialog_manager  -- Dialog system
quest_manager   -- Quest system
audio_manager   -- Audio system

-- Helper objects
hotspot         -- Hotspot registration
character       -- Character management
game_state      -- State management
```

### Scene Management

```lua
change_scene(scene_name)              -- Change to another scene
get_current_scene()                   -- Get current scene name
add_hotspot(hotspot_data)            -- Add dynamic hotspot
remove_hotspot(name)                 -- Remove hotspot
set_hotspot_visible(name, visible)   -- Show/hide hotspot
set_hotspot_active(name, active)     -- Enable/disable hotspot
get_hotspot_state(name)              -- Get current hotspot state
set_hotspot_state(name, state_name)  -- Change hotspot state

-- Example: Dynamic hotspot creation
add_hotspot({
    name = "treasure_chest",
    x = 100,
    y = 200,
    width = 64,
    height = 48,
    state = "closed"
})
```

### Character Control

```lua
move_character(name, x, y)           -- Move character to position
play_character_animation(name, anim) -- Play character animation
get_character_position(name)         -- Get character position {x, y}
set_character_visible(name, visible) -- Show/hide character
has_character(name)                  -- Check if character exists

-- Example: Character movement sequence
function move_guard_patrol()
    move_character("guard", 100, 300)
    add_timer(2.0, function()
        move_character("guard", 400, 300)
    end)
end
```

### Player Control

```lua
get_player_position()                -- Get player position {x, y}
move_player(x, y)                    -- Move player to position
player_walk_to(x, y)                 -- Pathfind player to position
set_player_controllable(enabled)     -- Enable/disable player control

-- Example: Cutscene with player movement
function start_cutscene()
    set_player_controllable(false)
    player_walk_to(200, 300)
    add_timer(3.0, function()
        show_dialog("player", "What's that noise?")
        set_player_controllable(true)
    end)
end
```

### Dialog System

```lua
show_message(text)                   -- Show simple message
show_dialog(character, text)         -- Show character dialog
show_dialog_choices(prompt, choices, callback) -- Show choice dialog
show_floating_dialog(character, text, position, duration, style)
start_dialog(dialog_file)            -- Start dialog tree from file
show_character_dialog(name, text, position) -- Show dialog at position

-- Example: Dialog with choices
show_dialog_choices("What should I say?", 
    {"Tell the truth", "Lie", "Say nothing"}, 
    function(choice_index)
        if choice_index == 1 then
            set_flag("told_truth", true)
            show_dialog("npc", "Thank you for your honesty.")
        elseif choice_index == 2 then
            set_flag("lied_to_npc", true)
            show_dialog("npc", "I don't believe you...")
        else
            show_dialog("npc", "Why won't you speak?")
        end
    end
)
```

### Inventory Management

```lua
add_to_inventory(item_name)          -- Add item by name
remove_from_inventory(item_name)     -- Remove item
has_item(item_name)                  -- Check if has item
get_selected_item()                  -- Get currently selected item
has_selected_item(item_name)         -- Check if item is selected
get_inventory_items()                -- Get all items array

-- Example: Item combination
hotspot.on_verb("cauldron", "use", function()
    if has_selected_item("water") and has_item("herbs") then
        remove_from_inventory("water")
        remove_from_inventory("herbs")
        add_to_inventory("potion")
        show_message("You created a healing potion!")
    end
end)
```

### Game State Management

```lua
set_flag(name, value)                -- Set boolean flag
get_flag(name)                       -- Get boolean flag (default: false)
set_variable(name, value)            -- Set variable (number/string)
get_variable(name, default)          -- Get variable with default
increase_variable(name, amount)      -- Increment numeric variable

-- Example: Score tracking
function add_score(points)
    increase_variable("score", points)
    local total = get_variable("score", 0)
    show_message("Score: " .. total)
end
```

### Quest Management

```lua
start_quest(quest_id)                -- Start a quest
complete_quest(quest_id)             -- Complete entire quest
fail_quest(quest_id)                 -- Fail a quest
complete_quest_objective(quest_id, objective_id) -- Complete objective
is_quest_active(quest_id)            -- Check if quest is active
is_quest_completed(quest_id)         -- Check if quest is done
get_quest_status(quest_id)           -- Get quest status string

-- Example: Quest progression
function found_artifact()
    complete_quest_objective("ancient_mystery", "find_artifact")
    
    if get_quest_status("ancient_mystery") == "completed" then
        show_message("Quest completed!")
        add_to_inventory("ancient_key")
    end
end
```

### Audio Control

```lua
play_sound(sound_name)               -- Play sound effect
play_music(music_name, loop)         -- Play background music
stop_music()                         -- Stop current music
play_ambient(sound_name, volume)     -- Play ambient sound
stop_ambient(sound_name)             -- Stop ambient sound
set_music_volume(volume)             -- Set music volume (0-1)
set_sound_volume(volume)             -- Set SFX volume (0-1)

-- Example: Dynamic music
function enter_boss_room()
    stop_music()
    play_music("boss_theme", true)
    set_music_volume(0.8)
end
```

### Visual Effects

```lua
fade_in(duration)                    -- Fade from black
fade_out(duration)                   -- Fade to black
shake_screen(intensity, duration)    -- Screen shake effect
flash_screen(color, duration)        -- Screen flash
show_particle_effect(name, x, y)     -- Spawn particles

-- Example: Dramatic effect
function explosion_sequence()
    play_sound("explosion")
    shake_screen(10, 1.0)
    flash_screen({255, 255, 255}, 0.2)
    show_particle_effect("explosion", 300, 200)
end
```

### Timer Management

```lua
add_timer(duration, callback)        -- One-shot timer
add_repeating_timer(interval, callback) -- Repeating timer
cancel_timer(timer_id)               -- Cancel a timer

-- Example: Timed puzzle
function start_timed_puzzle()
    local timer_id = add_timer(30.0, function()
        show_message("Time's up!")
        fail_quest("timed_puzzle")
    end)
    
    -- Store timer ID in case we need to cancel
    set_variable("puzzle_timer", timer_id)
end
```

### Utility Functions

```lua
print(message)                       -- Debug print to console
random(min, max)                     -- Random number (inclusive)
distance(x1, y1, x2, y2)            -- Calculate distance between points
lerp(start, end, t)                 -- Linear interpolation (t: 0-1)
log(message)                        -- Log message to console

-- Example: Proximity check
function check_player_near_trap()
    local player_pos = get_player_position()
    local trap_x, trap_y = 200, 300
    
    if distance(player_pos.x, player_pos.y, trap_x, trap_y) < 50 then
        trigger_trap()
    end
end
```

## Event System

The engine uses an event-driven architecture for communication between systems.

### Triggering Events

```lua
trigger_event(event_name, data)      -- Trigger custom event
on_event(event_name, callback)       -- Listen for event

-- Example: Custom event
trigger_event("treasure_found", {item = "golden_idol", value = 1000})

on_event("treasure_found", function(data)
    add_to_inventory(data.item)
    increase_variable("gold", data.value)
end)
```

### Standard Engine Events

The engine automatically triggers these events:

- `scene:entered` - Scene was entered (data: {scene_name})
- `scene:exited` - Scene was exited (data: {scene_name})
- `quest:started` - Quest started (data: {quest_id})
- `quest:completed` - Quest completed (data: {quest_id})
- `quest:failed` - Quest failed (data: {quest_id})
- `objective:completed` - Quest objective completed (data: {quest_id, objective_id})
- `item:added` - Item added to inventory (data: {item_name})
- `item:removed` - Item removed from inventory (data: {item_name})
- `item:used` - Item was used (data: {item_name, target})
- `dialog:started` - Dialog tree started (data: {dialog_file})
- `dialog:ended` - Dialog tree ended (data: {dialog_file})
- `cutscene:started` - Cutscene started (data: {cutscene_id})
- `cutscene:ended` - Cutscene ended (data: {cutscene_id})
- `game:saved` - Game was saved (data: {save_file})
- `game:loaded` - Game was loaded (data: {save_file})
- `player_moved` - Player moved (data: {x, y})
- `player_interact` - Player interacted (data: {target})
- `character_speak` - Character spoke (data: {character, text})
- `character_animation_complete` - Animation finished (data: {character, animation})
- `character_reached_target` - Character reached position (data: {character, x, y})

### Event Handling Example

```lua
-- Listen for quest completion
on_event("quest:completed", function(data)
    if data.quest_id == "main_story" then
        -- Unlock new area
        set_hotspot_visible("secret_passage", true)
        show_message("A secret passage has been revealed!")
    end
end)

-- React to item usage
on_event("item:used", function(data)
    if data.item_name == "magic_wand" and data.target == "crystal" then
        play_sound("magic_sparkle")
        show_particle_effect("magic", data.x, data.y)
    end
end)
```

## Scriptable Characters

Create dynamic characters with custom AI and behaviors.

### Creating a Scriptable Character

```crystal
# In Crystal code
character = PointClickEngine::ScriptableCharacter.new(
  "wizard",
  RL::Vector2.new(x: 300, y: 400),
  RL::Vector2.new(x: 64, y: 64)
)

# Load script from file
character.load_script("scripts/wizard_behavior.lua")

# Or set script directly
character.set_script(lua_script_content)
```

### Character Script Structure

```lua
-- wizard_behavior.lua

-- Character initialization
function on_init()
    log("Wizard character initialized")
    -- Set initial state
    this_character.custom_properties["mood"] = "neutral"
    this_character.update_interval = 2.0  -- Update every 2 seconds
end

-- Called every update interval
function on_update(dt)
    -- Check player distance
    local player_pos = get_player_position()
    local my_pos = character.get_position(character_name)
    local dist = distance(player_pos.x, player_pos.y, my_pos.x, my_pos.y)
    
    if dist < 100 then
        -- Player is near
        if not get_flag("wizard_greeted") then
            character.say(character_name, "Welcome, traveler!")
            set_flag("wizard_greeted", true)
        end
    end
end

-- Player interaction
function on_interact(player_name)
    local mood = this_character.custom_properties["mood"] or "neutral"
    
    if mood == "happy" then
        character.say(character_name, "What a wonderful day!")
    elseif mood == "angry" then
        character.say(character_name, "Leave me alone!")
    else
        start_dialog("wizard_dialog.yaml")
    end
end

-- When player looks at character
function on_look()
    dialog.show("A wise old wizard with a long beard.")
end

-- When player talks to character
function on_talk()
    if has_item("spell_book") then
        character.say(character_name, "Ah, you found my spell book!")
        this_character.custom_properties["mood"] = "happy"
    else
        character.say(character_name, "Have you seen my spell book?")
    end
end

-- Handle movement completion
function on_movement_complete()
    character.set_animation(character_name, "idle")
end

-- Handle animation completion
function on_animation_complete(animation_name)
    if animation_name == "cast_spell" then
        show_particle_effect("magic", this_character.x, this_character.y)
    end
end
```

### Character API Functions

Available within character scripts:

```lua
-- Character-specific functions
character.say(character_name, text)           -- Make character speak
character.move_to(character_name, x, y)       -- Move to position
character.get_position(character_name)        -- Get position {x, y}
character.set_animation(character_name, anim) -- Play animation

-- Access character properties
this_character.name                           -- Character's name
this_character.x, this_character.y           -- Current position
this_character.custom_properties[key]        -- Custom properties
this_character.update_interval               -- Update frequency (seconds)

-- Event registration
register_event_handler("event_name", function(data)
    -- Handle event
end)
```

## Advanced Features

### Custom Properties

Store custom data on characters:

```lua
-- Set properties
this_character.custom_properties["health"] = 100
this_character.custom_properties["inventory"] = {"sword", "shield"}
this_character.custom_properties["quest_stage"] = 2

-- Read properties
local health = this_character.custom_properties["health"] or 100
local items = this_character.custom_properties["inventory"] or {}
```

### State Machines

Implement character AI with state machines:

```lua
-- Character states
local states = {
    idle = {
        enter = function()
            character.set_animation(character_name, "idle")
        end,
        update = function(dt)
            -- Check for player
            if player_nearby() then
                change_state("alert")
            end
        end
    },
    alert = {
        enter = function()
            character.set_animation(character_name, "alert")
            character.say(character_name, "Who goes there?")
        end,
        update = function(dt)
            if not player_nearby() then
                change_state("idle")
            end
        end
    }
}

local current_state = "idle"

function change_state(new_state)
    if states[new_state] then
        current_state = new_state
        states[new_state].enter()
    end
end

function on_update(dt)
    if states[current_state] then
        states[current_state].update(dt)
    end
end
```

### Dynamic Scene Modification

Create scenes that change based on game state:

```lua
function on_enter()
    -- Modify scene based on time of day
    local hour = get_variable("game_hour", 12)
    
    if hour >= 20 or hour <= 6 then
        -- Night time
        play_music("night_ambience", true)
        set_hotspot_visible("sleeping_guard", true)
        set_hotspot_visible("alert_guard", false)
    else
        -- Day time
        play_music("day_ambience", true)
        set_hotspot_visible("sleeping_guard", false)
        set_hotspot_visible("alert_guard", true)
    end
end
```

## Best Practices

### Performance Optimization

1. **Update Intervals**: Set appropriate update intervals for characters
```lua
this_character.update_interval = 1.0  -- Update once per second
```

2. **Local Variables**: Use local variables for better performance
```lua
local player_pos = get_player_position()  -- Cache frequently used values
local my_pos = character.get_position(character_name)
```

3. **Event-Driven Logic**: Prefer events over polling
```lua
-- Good: React to events
on_event("item:added", function(data)
    if data.item_name == "key" then
        update_door_state()
    end
end)

-- Avoid: Constant checking in update
function on_update(dt)
    if has_item("key") then  -- This runs every frame
        -- ...
    end
end
```

### Code Organization

1. **Modular Functions**: Break complex logic into functions
```lua
function check_puzzle_solution()
    return has_item("red_gem") and 
           has_item("blue_gem") and 
           has_item("green_gem")
end

function on_update(dt)
    if check_puzzle_solution() then
        complete_puzzle()
    end
end
```

2. **Constants**: Define constants for clarity
```lua
local PLAYER_DETECTION_RANGE = 150
local DIALOGUE_COOLDOWN = 5.0
local MAX_HEALTH = 100
```

3. **Comments**: Document complex logic
```lua
-- Check if player has completed the prerequisite quests
-- before allowing access to the final boss area
if is_quest_completed("gather_artifacts") and 
   is_quest_completed("defeat_minions") then
    set_hotspot_active("boss_door", true)
end
```

## Error Handling

The scripting system includes robust error handling:

### Safe Execution

Scripts run in a protected environment. Errors are logged but won't crash the game:

```
Script error: attempt to call nil value
Script function error: undefined function 'invalid_function'
```

### Debugging

Use logging for debugging:

```lua
log("Debug: Player position = " .. get_player_position().x .. ", " .. get_player_position().y)
print("Variable value: " .. get_variable("test", "default"))

-- Conditional debugging
if get_flag("debug_mode") then
    log("Entering combat state")
end
```

### Common Errors and Solutions

1. **Nil Values**: Always check for nil
```lua
local pos = get_character_position("npc")
if pos then
    log("NPC at: " .. pos.x .. ", " .. pos.y)
end
```

2. **Missing Functions**: Define all callback functions
```lua
-- Even if empty, define required functions
function on_update(dt)
    -- Will be called every frame
end
```

3. **Type Errors**: Ensure correct types
```lua
-- Convert to string when concatenating
log("Score: " .. tostring(get_variable("score", 0)))
```

## Examples

### Complete Scene Script Example

```lua
-- haunted_mansion_entrance.lua

-- Constants
local GHOST_APPEAR_CHANCE = 0.1
local DOOR_UNLOCK_CODE = "1834"

-- Scene state
local ghost_timer = 0
local code_entered = ""

function on_enter()
    -- Set atmosphere
    play_music("spooky_ambience", true)
    set_music_volume(0.6)
    
    -- Initialize based on game state
    if get_flag("mansion_unlocked") then
        set_hotspot_state("main_door", "open")
    else
        set_hotspot_state("main_door", "locked")
    end
    
    -- Random lightning
    add_repeating_timer(random(5, 15), function()
        flash_screen({200, 200, 255}, 0.1)
        play_sound("thunder")
    end)
end

function on_exit()
    stop_music()
end

function on_update(dt)
    -- Random ghost appearances
    ghost_timer = ghost_timer + dt
    if ghost_timer > 10.0 then
        ghost_timer = 0
        if random(0, 1) < GHOST_APPEAR_CHANCE then
            spawn_ghost()
        end
    end
end

function spawn_ghost()
    local x = random(100, 700)
    set_character_visible("ghost", true)
    move_character("ghost", x, 300)
    play_sound("ghost_moan")
    
    add_timer(3.0, function()
        set_character_visible("ghost", false)
    end)
end

-- Hotspot handlers
hotspot.on_verb("main_door", "open", function()
    if get_hotspot_state("main_door") == "locked" then
        show_message("The door is locked. There's a keypad next to it.")
    else
        change_scene("mansion_interior")
    end
end)

hotspot.on_verb("keypad", "use", function()
    show_dialog_choices("Enter code:", 
        {"1834", "1923", "1756", "Cancel"}, 
        function(choice)
            if choice == 1 then
                -- Correct code
                play_sound("unlock")
                set_hotspot_state("main_door", "open")
                set_flag("mansion_unlocked", true)
                show_message("The door unlocks with a loud click!")
            elseif choice < 4 then
                -- Wrong code
                play_sound("error")
                show_message("Nothing happens.")
                shake_screen(2, 0.5)
            end
        end
    )
end)

hotspot.on_verb("window", "look", function()
    show_message("Through the dusty window, you see shadows moving inside.")
    if random(0, 1) < 0.3 then
        -- Jumpscare
        set_character_visible("ghost_face", true)
        play_sound("scream")
        add_timer(0.5, function()
            set_character_visible("ghost_face", false)
        end)
    end
end)

-- Character handlers
character.on_verb("groundskeeper", "talk", function()
    if not get_flag("talked_to_groundskeeper") then
        set_flag("talked_to_groundskeeper", true)
        show_dialog("groundskeeper", "This place has been abandoned for years...")
        add_timer(2.0, function()
            show_dialog("groundskeeper", "They say the last owner left a code: the year he disappeared.")
            start_quest("find_mansion_code")
        end)
    else
        show_dialog("groundskeeper", "Be careful in there.")
    end
end)
```

### Integration with Crystal Code

```crystal
# In your Crystal application
engine = PointClickEngine::Engine.new(config)

# Access script engine
if script_engine = engine.script_engine
  # Execute Lua code
  script_engine.execute_script("log('Game started!')")
  
  # Set global variables accessible from Lua
  script_engine.set_global("game_difficulty", "hard")
  script_engine.set_global("player_level", 5)
  
  # Call Lua functions
  script_engine.call_function("initialize_game")
  
  # Register Crystal functions callable from Lua
  script_engine.register_function("save_game") do |filename|
    engine.save_game(filename.as(String))
  end
end

# Trigger events from Crystal
engine.event_system.trigger_event("level_started", {
  "level" => 1,
  "difficulty" => "hard"
})
```

This comprehensive guide covers all aspects of Lua scripting in the Point & Click Engine. Use these features to create rich, interactive experiences with dynamic gameplay, engaging characters, and complex game logic!