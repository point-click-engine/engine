require "../src/point_click_engine"

# Example of using the Point & Click Engine with Lua scripting
module ScriptingExample
  # Create a basic game with scripting
  def self.run
    # Initialize the game engine
    engine = PointClickEngine::Engine.new(800, 600, "Scripting Example")
    
    # Create a scene
    scene = PointClickEngine::Scene.new("main_room")
    scene.description = "A room with magical properties"
    engine.add_scene(scene)
    
    # Create a scriptable character
    scriptable_char = PointClickEngine::ScriptableCharacter.new(
      "wizard", 
      RL::Vector2.new(x: 300, y: 400), 
      RL::Vector2.new(x: 64, y: 64)
    )
    scriptable_char.description = "A mysterious wizard"
    
    # Load the Lua script for this character
    scriptable_char.load_script("example/scripts/example_character.lua")
    
    # Add character to scene
    scene.add_character(scriptable_char)
    
    # Create a simple NPC that uses basic dialogue without scripting
    simple_npc = PointClickEngine::SimpleNPC.new(
      "guard",
      RL::Vector2.new(x: 500, y: 400),
      RL::Vector2.new(x: 64, y: 64)
    )
    simple_npc.description = "A castle guard"
    simple_npc.add_dialogue("Welcome to the castle!")
    simple_npc.add_dialogue("The wizard knows many secrets.")
    simple_npc.add_dialogue("Be careful in the dungeon.")
    scene.add_character(simple_npc)
    
    # Create a player character
    player = PointClickEngine::Player.new(
      "hero",
      RL::Vector2.new(x: 100, y: 400),
      RL::Vector2.new(x: 64, y: 64)
    )
    scene.player = player
    
    # Add some hotspots with script-triggered events
    door_hotspot = PointClickEngine::Hotspot.new(
      "door",
      RL::Vector2.new(x: 700, y: 350),
      RL::Vector2.new(x: 50, y: 100)
    )
    door_hotspot.on_click = ->{
      # Trigger custom event via scripting system
      engine.event_system.trigger_event("custom_event", {
        "message" => "The door creaks open..."
      })
      
      # Execute some Lua code directly
      if script_engine = engine.script_engine
        script_engine.execute_script(<<-LUA
          log("Door hotspot clicked!")
          if inventory.has_item("key") then
            scene.change("next_room")
            log("Player entered the next room")
          else
            dialog.show("The door is locked. You need a key.")
          end
        LUA
        )
      end
    }
    scene.add_hotspot(door_hotspot)
    
    # Add a key item that can be found
    key_hotspot = PointClickEngine::Hotspot.new(
      "key_spot",
      RL::Vector2.new(x: 200, y: 500),
      RL::Vector2.new(x: 32, y: 32)
    )
    key_hotspot.on_click = ->{
      # Add key to inventory via scripting
      if script_engine = engine.script_engine
        script_engine.execute_script(<<-LUA
          inventory.add_item("key", "A golden key that opens mysterious doors")
          dialog.show("You found a golden key!")
          log("Player found the key")
        LUA
        )
      end
      # Remove the hotspot after use
      scene.remove_hotspot("key_spot")
    }
    scene.add_hotspot(key_hotspot)
    
    # Set the initial scene
    engine.change_scene("main_room")
    
    puts "=== Point & Click Engine with Lua Scripting ==="
    puts "Features demonstrated:"
    puts "- Scriptable characters with Lua AI"
    puts "- Event-driven scripting system"
    puts "- Script-based hotspot interactions"
    puts "- Inventory management via scripts"
    puts "- Runtime Lua code execution"
    puts ""
    puts "Controls:"
    puts "- Click to move player"
    puts "- Click on characters to interact"
    puts "- Click on key area to pick up key"
    puts "- Click on door to try opening it"
    puts "- Press I to toggle inventory"
    puts "- Press F1 to toggle debug mode"
    puts ""
    
    # Start the game
    engine.run
  end
end

# Run the example if this file is executed directly
if PROGRAM_NAME.includes?("scripting_example")
  ScriptingExample.run
end