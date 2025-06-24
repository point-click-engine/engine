# Getting Started with Point & Click Engine

This guide will walk you through installing the Point & Click Engine and creating your first adventure game.

## Prerequisites

Before you begin, you'll need:
- **Crystal** (version 1.0 or higher)
- **Git** (for cloning the repository)
- **A text editor** (VS Code, Sublime Text, or similar)
- **Basic command line knowledge**

## Installation

### 1. Install Crystal

Visit [crystal-lang.org](https://crystal-lang.org) and follow the installation instructions for your platform:

- **macOS**: `brew install crystal`
- **Ubuntu/Debian**: Use the official APT repository
- **Windows**: Use WSL (Windows Subsystem for Linux)

### 2. Clone the Engine

```bash
git clone https://github.com/yourusername/point_click_engine.git
cd point_click_engine
```

### 3. Install Dependencies

```bash
shards install
```

This will install all required dependencies including Raylib for graphics and LuaJIT for scripting.

### 4. Verify Installation

Run the example game to make sure everything is working:

```bash
./run.sh crystal_mystery/main.cr
```

You should see the Crystal Mystery demo game launch.

## Important: Audio Library Setup

The Point & Click Engine uses raylib-cr which requires the miniaudiohelpers library for audio support. 

**Always use the `./run.sh` script instead of calling `crystal` directly:**

```bash
# ✅ Correct way:
./run.sh main.cr

# ❌ This may fail with audio library errors:
crystal main.cr
```

The `run.sh` script automatically sets up the correct library paths for audio support.

## Your First Game

Let's create a simple two-room adventure game.

### Step 1: Create Project Structure

```bash
mkdir my_first_game
cd my_first_game

# Create directories
mkdir -p scenes scripts assets/backgrounds assets/sprites
```

### Step 2: Create Game Configuration

Create `game_config.yaml`:

```yaml
game:
  title: "My First Adventure"
  version: "1.0.0"
  author: "Your Name"

window:
  width: 1024
  height: 768
  fullscreen: false

player:
  name: "Hero"
  sprite_path: "assets/sprites/player.png"
  sprite:
    frame_width: 32
    frame_height: 64
    columns: 4
    rows: 4
  start_position:
    x: 200.0
    y: 400.0

features:
  - verbs        # Enable verb-based interactions
  - auto_save    # Enable automatic saving

assets:
  scenes: ["scenes/*.yaml"]

start_scene: "room1"
```

### Step 3: Create Your First Scene

Create `scenes/room1.yaml`:

```yaml
name: room1
background_path: "assets/backgrounds/room1.png"
script_path: "scripts/room1.lua"

# Define where the player can walk
walkable_areas:
  regions:
    - name: "floor"
      walkable: true
      vertices:
        - {x: 100, y: 350}
        - {x: 900, y: 350}
        - {x: 900, y: 700}
        - {x: 100, y: 700}

# Interactive objects
hotspots:
  - name: "table"
    type: "rectangle"
    x: 400
    y: 300
    width: 200
    height: 100
    description: "A wooden table"
    default_verb: "look"
    
  - name: "door"
    type: "exit"
    x: 850
    y: 200
    width: 100
    height: 200
    target_scene: "room2"
    target_position:
      x: 150
      y: 400
    description: "Door to the next room"
```

### Step 4: Add Scene Logic

Create `scripts/room1.lua`:

```lua
-- This function runs when the player enters the scene
function on_enter()
  if not get_flag("game_started") then
    show_message("Welcome to your first adventure game!")
    show_message("Click on objects to interact with them.")
    set_flag("game_started", true)
  end
end

-- Handle interactions with the table
hotspot.on_use("table", "look", function()
  show_message("It's a sturdy wooden table.")
  
  if not get_flag("found_key") then
    show_message("There's something shiny underneath...")
    add_item("silver_key")
    set_flag("found_key", true)
    show_message("You found a silver key!")
  end
end)

-- Optional: Character idle behavior
function on_idle()
  -- Called when player hasn't interacted for a while
  if math.random() < 0.01 then
    character.say(player, "I should explore this room.")
  end
end
```

### Step 5: Create the Second Room

Create `scenes/room2.yaml`:

```yaml
name: room2
background_path: "assets/backgrounds/room2.png"
script_path: "scripts/room2.lua"

walkable_areas:
  regions:
    - name: "floor"
      walkable: true
      vertices:
        - {x: 50, y: 400}
        - {x: 950, y: 400}
        - {x: 950, y: 700}
        - {x: 50, y: 700}

hotspots:
  - name: "door_back"
    type: "exit"
    x: 50
    y: 200
    width: 100
    height: 200
    target_scene: "room1"
    target_position:
      x: 800
      y: 400
    description: "Back to the first room"
    
  - name: "treasure_chest"
    type: "rectangle"
    x: 500
    y: 350
    width: 150
    height: 100
    description: "A locked treasure chest"
    default_verb: "use"
```

### Step 6: Add Logic for Room 2

Create `scripts/room2.lua`:

```lua
function on_enter()
  show_message("You enter the treasure room!")
end

hotspot.on_use("treasure_chest", "look", function()
  show_message("A magnificent treasure chest with a silver lock.")
end)

hotspot.on_use("treasure_chest", "use", function()
  if has_item("silver_key") then
    show_message("You use the silver key...")
    play_sound("unlock")
    remove_item("silver_key")
    
    show_message("The chest opens revealing ancient treasures!")
    set_flag("game_complete", true)
    
    -- End the game
    show_message("Congratulations! You've completed your first adventure!")
  else
    show_message("The chest is locked. You need a key.")
  end
end)
```

### Step 7: Create the Main Entry Point

Create `main.cr`:

```crystal
require "point_click_engine"

# Load the game configuration
config = PointClickEngine::Core::GameConfig.from_file("game_config.yaml")

# Create the engine
engine = config.create_engine

# Optional: Show main menu
# engine.show_main_menu

# Start the game
engine.run
```

### Step 8: Add Placeholder Assets

For testing, create simple placeholder images:

1. Create 1024x768 PNG images for:
   - `assets/backgrounds/room1.png`
   - `assets/backgrounds/room2.png`

2. Create a 128x256 sprite sheet for:
   - `assets/sprites/player.png`

You can use any image editor or download free assets from [OpenGameArt.org](https://opengameart.org).

### Step 9: Run Your Game

From your game directory:

```bash
# Copy the run.sh script from the engine
cp ../point_click_engine/run.sh .

# Run your game
./run.sh main.cr
```

## Common Issues and Solutions

### "Library 'miniaudiohelpers' not found"
**Solution**: Use `./run.sh` instead of running `crystal` directly.

### "Scene not found"
**Solution**: Check that your scene files are in the correct directory and the paths in `game_config.yaml` are correct.

### "Invalid YAML"
**Solution**: YAML is sensitive to indentation. Use spaces (not tabs) and maintain consistent indentation.

### Game crashes on startup
**Solution**: Run with debug output:
```bash
DEBUG=1 ./run.sh main.cr
```

## Next Steps

Now that you have a working game:

1. **Add more content**:
   - Create additional rooms
   - Add NPCs with dialog trees
   - Implement puzzles and quests

2. **Enhance visuals**:
   - Add proper artwork
   - Implement animations
   - Use particle effects

3. **Add audio**:
   - Background music
   - Sound effects
   - Voice acting

4. **Study the example game**:
   - Explore `crystal_mystery/` for advanced techniques
   - See how dialogs, quests, and cutscenes work

5. **Read the documentation**:
   - [Quick Reference](QUICK_REFERENCE.md) - Common tasks
   - [YAML Formats](YAML_FORMATS.md) - All configuration options
   - [Lua Scripting](LUA_SCRIPTING.md) - Complete API reference

## Tips for Success

1. **Start small**: Build one room at a time and test frequently
2. **Use placeholder assets**: Don't wait for final art to start development
3. **Comment your scripts**: Document complex logic in your Lua files
4. **Save often**: Use version control (git) for your game files
5. **Test on friends**: Get feedback early and often

## Getting Help

- Check the [Quick Reference](QUICK_REFERENCE.md) for common tasks
- Read the full documentation in the `docs/` directory
- Look at the `crystal_mystery` example game
- Join our Discord community for support

---

Congratulations! You're now ready to create your own point & click adventure games. Happy game making!