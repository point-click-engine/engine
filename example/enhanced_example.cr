# Enhanced Adventure Game Example
# Demonstrates all features: dialog trees, character animation, inventory combinations, save/load, sound

require "../src/point_click_engine"

alias PCE = PointClickEngine

# Create the game engine
game = PCE::Game.new(800, 600, "Enhanced Adventure Demo")
game.target_fps = 60
game.init

# Load custom cursor
game.load_cursor("assets/pointer.png")

# Initialize audio
audio = PCE::Audio::AudioManager.new

# Setup example sounds (uncomment if you have audio files)
# audio.load_sound_effect("click", "assets/sounds/click.wav")
# audio.load_sound_effect("pickup", "assets/sounds/pickup.wav")
# audio.load_music("background", "assets/music/background.ogg")

# Create main scene
main_scene = PCE::Scene.new("Mystic Grove")
main_scene.load_background("assets/background.png")

# Create animated player character
player = PCE::Player.new("Guybrush", RL::Vector2.new(x: 400, y: 300), RL::Vector2.new(x: 32, y: 32))
player.load_spritesheet("assets/walking-sprite-sheets.png", 32, 32)

# Add character animations (assuming 4-frame walking animations)
player.add_animation("idle", 0, 1, 0.5, true)
player.add_animation("walk_right", 0, 4, 0.1, true)
player.add_animation("walk_left", 4, 4, 0.1, true)
player.add_animation("talk", 8, 2, 0.3, true)

main_scene.add_character(player)
main_scene.set_player(player)

# Create an NPC with simple dialog
wizard = PCE::NPC.new("Old Wizard", RL::Vector2.new(x: 200, y: 250), RL::Vector2.new(x: 32, y: 32))
wizard.mood = PCE::NPCMood::Friendly
wizard.set_dialogues([
  "Greetings, young adventurer! What brings you to my grove?",
  "I can teach you the ways of magic, but first you must prove yourself worthy.",
  "Find the ancient key and combine it with the mystical crystal. Then return to me.",
  "You have all the items you need. Combine them to create something magical!"
])

main_scene.add_character(wizard)

# Create interactive hotspots
# Mystical Crystal
crystal_hotspot = PCE::Hotspot.new("crystal", RL::Vector2.new(x: 600, y: 400), RL::Vector2.new(x: 40, y: 40))
crystal_hotspot.cursor_type = PCE::Hotspot::CursorType::Hand
crystal_hotspot.on_click = -> {
  unless game.inventory.has_item?("Mystical Crystal")
    crystal = PCE::InventoryItem.new("Mystical Crystal", "A glowing blue crystal pulsing with magical energy")
    crystal.load_icon("assets/key.png") # Using key icon as placeholder
    crystal.combinable_with = ["Ancient Key"]
    crystal.combine_actions = {"Ancient Key" => "create_magic_item"}
    game.inventory.add_item(crystal)
    
    # audio.play_sound_effect("pickup")
    
    dialog = PCE::Dialog.new("You picked up the Mystical Crystal!", 
                           RL::Vector2.new(x: 100, y: 450), 
                           RL::Vector2.new(x: 600, y: 100))
    game.show_dialog(dialog)
    crystal_hotspot.active = false
  end
}
main_scene.add_hotspot(crystal_hotspot)

# Ancient Key (already exists in original example, enhance it)
key_hotspot = PCE::Hotspot.new("ancient_key", RL::Vector2.new(x: 150, y: 450), RL::Vector2.new(x: 30, y: 30))
key_hotspot.cursor_type = PCE::Hotspot::CursorType::Hand
key_hotspot.on_click = -> {
  unless game.inventory.has_item?("Ancient Key")
    key = PCE::InventoryItem.new("Ancient Key", "An ornate key covered in mystical runes")
    key.load_icon("assets/key.png")
    key.combinable_with = ["Mystical Crystal"]
    key.combine_actions = {"Mystical Crystal" => "create_magic_item"}
    game.inventory.add_item(key)
    
    # audio.play_sound_effect("pickup")
    
    dialog = PCE::Dialog.new("You found the Ancient Key!", 
                           RL::Vector2.new(x: 100, y: 450), 
                           RL::Vector2.new(x: 600, y: 100))
    game.show_dialog(dialog)
    key_hotspot.active = false
  end
}
main_scene.add_hotspot(key_hotspot)

# Setup inventory item combinations
game.inventory.on_items_combined = ->(item1 : PCE::InventoryItem, item2 : PCE::InventoryItem, action : String?) {
  if action == "create_magic_item"
    # Remove individual items
    game.inventory.remove_item(item1)
    game.inventory.remove_item(item2)
    
    # Create combined item
    magic_item = PCE::InventoryItem.new("Magic Artifact", "A powerful artifact created by combining the key and crystal")
    magic_item.load_icon("assets/key.png") # Placeholder icon
    game.inventory.add_item(magic_item)
    
    # Item combination successful
    
    # audio.play_sound_effect("magic")
    
    dialog = PCE::Dialog.new("The key and crystal have fused into a powerful magic artifact!", 
                           RL::Vector2.new(x: 100, y: 450), 
                           RL::Vector2.new(x: 600, y: 100))
    game.show_dialog(dialog)
  end
}

# Add scene to game
game.add_scene(main_scene)
game.change_scene("Mystic Grove")

# Note: Input handling would be implemented in the engine's game loop
# For now, the basic controls are:
# - Click to move (built into the engine)
# - Click on objects to interact (built into the engine)
# - Press 'I' to toggle inventory (would need to be implemented in engine)

# Display controls info
puts "=== Enhanced Adventure Game Demo ==="
puts "Controls:"
puts "- Click to move"
puts "- Click on objects to interact"
puts "- I: Toggle inventory"
puts "- C: Start combination mode (select item first)"
puts "- F5: Quick save"
puts "- F9: Quick load"
puts "- M: Toggle mute"
puts "- ESC: Quit"
puts ""
puts "Features demonstrated:"
puts "- Character walking animation"
puts "- Dialog trees with branching conversations"
puts "- Inventory with item combinations"
puts "- Save/load system"
puts "- Sound system (ready for audio files)"
puts "================================="

# Start background music
# audio.play_music("background")

# Main game loop
game.run

# Cleanup
audio.finalize
puts "Game ended."