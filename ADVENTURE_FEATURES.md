# Adventure Game Features

This document describes the advanced features added to the Point & Click Engine to support complex adventure games like Simon the Sorcerer and Monkey Island.

## 🎭 Dialog Tree System

The engine now supports complex branching conversations with multiple choice options, conditions, and once-only dialogs.

### Features
- **Branching conversations** with multiple choice paths
- **Conditional choices** based on game state
- **Once-only dialog options** that disappear after selection
- **Variable system** for tracking conversation state
- **YAML serialization** for easy dialog authoring
- **Script integration** for complex dialog logic

### Usage
```crystal
# Create a dialog tree
tree = PCE::DialogTree.new("wizard_conversation")

# Create dialog nodes
greeting = PCE::DialogNode.new("greeting", "Hello, adventurer!")
greeting.character_name = "Wizard"

# Add choices
choice = PCE::DialogChoice.new("Tell me about magic", "magic_info")
choice.conditions = ["player_level >= 5"]  # Conditional choice
greeting.add_choice(choice)

tree.add_node(greeting)
tree.start_conversation("greeting")
```

## 🏃 Character Animation System

Characters now support sprite-based animations for walking, talking, and idle states.

### Features
- **Sprite sheet support** with configurable frame dimensions
- **Multiple animation states** (idle, walking, talking)
- **Directional animations** (walk_left, walk_right, etc.)
- **Smooth frame interpolation** with configurable timing
- **Automatic state transitions** based on character actions

### Usage
```crystal
# Load character spritesheet
character.load_spritesheet("hero_sprites.png", 32, 32)

# Add animations
character.add_animation("idle", 0, 1, 0.5, true)
character.add_animation("walk_right", 0, 4, 0.1, true)
character.add_animation("walk_left", 4, 4, 0.1, true)
character.add_animation("talk", 8, 2, 0.3, true)

# Animations play automatically based on character state
character.walk_to(target_position)  # Plays walking animation
character.say("Hello!")            # Plays talking animation
```

## 🎒 Enhanced Inventory System

The inventory system now supports item combinations, usage on objects, and complex item interactions.

### Features
- **Item combinations** with custom result items
- **Item usage** on scene objects and other items
- **Consumable items** that disappear after use
- **Visual combination mode** with UI feedback
- **Custom combination actions** via script system

### Usage
```crystal
# Create combinable items
rope = PCE::InventoryItem.new("Rope", "A sturdy rope")
hook = PCE::InventoryItem.new("Hook", "A metal hook")

# Set up combinations
rope.combinable_with = ["Hook"]
rope.combine_actions = {"Hook" => "create_grappling_hook"}

# Handle combinations
inventory.on_items_combined = ->(item1, item2, action) {
  if action == "create_grappling_hook"
    inventory.remove_item(item1)
    inventory.remove_item(item2)
    grappling_hook = PCE::InventoryItem.new("Grappling Hook", "Rope + Hook")
    inventory.add_item(grappling_hook)
  end
}

# Usage on objects
key.usable_on = ["door", "chest"]
inventory.use_selected_item_on("door")
```

## 💾 Save/Load System

Complete game state persistence for save files and automatic quicksave functionality.

### Features
- **Complete game state** saving (position, inventory, dialog progress)
- **Multiple save slots** with custom naming
- **Scene state preservation** (hotspot states, object visibility)
- **Variable and flag persistence** for complex game logic
- **YAML format** for human-readable save files

### Usage
```crystal
# Save game
PCE::SaveSystem.save_game(game, "my_save")

# Load game
PCE::SaveSystem.load_game(game, "my_save")

# Check for existing saves
saves = PCE::SaveSystem.get_save_files
puts "Available saves: #{saves}"

# Quick save/load
game.on_key_pressed = ->(key) {
  case key
  when .f5
    PCE::SaveSystem.save_game(game, "quicksave")
  when .f9
    PCE::SaveSystem.load_game(game, "quicksave")
  end
}
```

## 🔊 Audio System

Comprehensive sound effects and background music system with automatic fallback.

### Features
- **Sound effects** with volume control
- **Background music** with looping
- **Audio manager** for centralized control
- **Master volume** and category-specific volumes
- **Mute functionality** for accessibility
- **Automatic fallback** to stub implementation when audio libraries aren't available

### Audio Support
By default, the engine uses stub audio implementations (no sound). To enable full audio support:

```bash
# Install audio dependencies (if needed)
# On macOS with Homebrew:
brew install raylib

# Compile with audio support
crystal run your_game.cr -Dwith_audio

# Or for specs with audio
crystal spec -Dwith_audio
```

### Usage
```crystal
# Initialize audio (works with or without audio libraries)
audio = PCE::AudioManager.new

# Load sounds (silently ignored if audio not available)
audio.load_sound_effect("footstep", "sounds/footstep.wav")
audio.load_music("background", "music/background.ogg")

# Play sounds (silently ignored if audio not available)
audio.play_sound_effect("footstep")
audio.play_music("background", loop: true)

# Volume control (always works)
audio.set_master_volume(0.8)
audio.set_sfx_volume(0.6)
audio.toggle_mute
```

The audio system gracefully degrades when audio libraries aren't available, so your games will always run.

## 🎮 Enhanced Example Game

The `enhanced_example.cr` demonstrates all features in a complete mini-adventure:

### Features Demonstrated
- **Animated character movement** with click-to-walk
- **NPC with dialog tree** including branching conversations
- **Item collection and combination** to create new items
- **Quest progression** through dialog conditions
- **Save/load functionality** with F5/F9 keys
- **Sound integration** (ready for audio files)

### Controls
- **Mouse click**: Move character
- **I key**: Toggle inventory
- **C key**: Start combination mode
- **F5**: Quick save
- **F9**: Quick load
- **M**: Toggle mute
- **ESC**: Quit game

## 🧪 Testing

Comprehensive specs are included for all new features:

```bash
crystal spec spec/dialog_tree_spec.cr
crystal spec spec/inventory_system_spec.cr
crystal spec spec/character_animation_spec.cr
```

## 📁 Project Structure

```
src/
├── characters/
│   └── dialogue/
│       ├── character_dialogue.cr
│       └── dialog_tree.cr        # NEW: Dialog tree system
├── inventory/
│   ├── inventory_item.cr         # ENHANCED: Combinations
│   └── inventory_system.cr       # ENHANCED: Item usage
├── core/
│   └── save_system.cr            # NEW: Save/load functionality
├── audio/
│   └── sound_system.cr           # NEW: Audio management
└── graphics/
    └── animated_sprite.cr        # ENHANCED: Character animations

example/
├── enhanced_example.cr           # NEW: Complete demo
└── dialog_trees/
    └── wizard_dialog.yml         # NEW: YAML dialog example
```

## 🚀 Getting Started

1. **Run the enhanced example**:
   ```bash
   cd example
   crystal run enhanced_example.cr
   ```

2. **Create your own adventure**:
   - Design your dialog trees in YAML
   - Create character sprite sheets
   - Set up item combinations
   - Add save points throughout your game

The engine now provides all the core features needed to create complex point-and-click adventure games like the classics!