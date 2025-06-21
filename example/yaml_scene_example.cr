require "../src/point_click_engine"

# Example scene YAML file
scene_yaml = <<-YAML
name: example_room
background_path: assets/room_bg.png
scale: 1.0
enable_pathfinding: true
navigation_cell_size: 16
script_path: scripts/room_logic.lua
hotspots:
  - name: door
    x: 500
    y: 100
    width: 80
    height: 150
    description: "Exit to hallway"
  - name: desk
    x: 200
    y: 300
    width: 150
    height: 100
    description: "A cluttered desk"
  - name: bookshelf
    x: 50
    y: 150
    width: 100
    height: 200
    description: "Books on Crystal programming"
characters:
  - name: librarian
    position:
      x: 150
      y: 250
    sprite_path: assets/librarian.png
  - name: student
    position:
      x: 400
      y: 350
YAML

# Example Lua script for the scene
lua_script = <<-LUA
-- Room logic script
print("Room script loaded!")

room_visited = false
door_locked = true
key_found = false

function on_room_enter()
  if not room_visited then
    show_dialog("librarian", "Welcome to the library! The door is locked for now.")
    room_visited = true
  end
end

function on_hotspot_click(hotspot_name)
  if hotspot_name == "door" then
    if door_locked then
      show_dialog("player", "The door is locked.")
    else
      change_scene("hallway")
    end
  elseif hotspot_name == "desk" then
    if not key_found then
      show_dialog("player", "I found a key in the desk drawer!")
      key_found = true
      add_to_inventory("key")
    else
      show_dialog("player", "Nothing else of interest here.")
    end
  elseif hotspot_name == "bookshelf" then
    show_dialog("player", "Lots of programming books. I see 'Crystal for Beginners'!")
  end
end

function on_character_interact(char_name)
  if char_name == "librarian" then
    if key_found then
      show_dialog("librarian", "Ah, you found the key! You may leave now.")
      door_locked = false
    else
      show_dialog("librarian", "Looking for something? Check the desk.")
    end
  elseif char_name == "student" then
    show_dialog("student", "I'm studying for my game dev exam!")
  end
end

function use_item(item_name, target)
  if item_name == "key" and target == "door" then
    door_locked = false
    show_dialog("player", "The door is now unlocked!")
    remove_from_inventory("key")
  end
end
LUA

# Create example files
Dir.mkdir_p("assets")
Dir.mkdir_p("scripts")
File.write("example_scene.yaml", scene_yaml)
File.write("scripts/room_logic.lua", lua_script)

# Main game using YAML scene loading
engine = PointClickEngine::Core::Engine.new
engine.init(800, 600, "YAML Scene Loading Example")

# Enable scripting
engine.script_engine = PointClickEngine::Scripting::ScriptEngine.new

# Load scene from YAML
scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("example_scene.yaml")

# Load background texture
if bg_path = scene.background_path
  scene.background = PointClickEngine::Assets::AssetLoader.load_texture(bg_path)
end

# Load the scene's Lua script
scene.load_script(engine)

# Setup pathfinding if background is loaded
if bg = scene.background
  scene.setup_navigation
end

# Add scene to engine
engine.add_scene(scene)
engine.change_scene(scene.name)

# Setup hotspot callbacks
scene.hotspots.each do |hotspot|
  hotspot.on_click = -> do
    engine.script_engine.try do |scripting|
      scripting.call_function("on_hotspot_click", [hotspot.name])
    end
  end

  hotspot.on_hover = -> do
    engine.gui.cursor.set_state(:hover)
  end
end

# Setup character interaction callbacks
scene.characters.each do |character|
  # Simulate character sprites with colored rectangles for this example
  character.on_interact = -> do
    engine.script_engine.try do |scripting|
      scripting.call_function("on_character_interact", [character.name])
    end
  end
end

# Call scene enter function
engine.script_engine.try do |scripting|
  scripting.call_function("on_room_enter", [] of String)
end

# Main game loop
engine.run do
  # Update logic handled by engine

  # Custom rendering if needed
  if engine.debug_mode
    scene.draw_navigation_debug
  end
end

# Cleanup
engine.cleanup

# Remove example files
File.delete("example_scene.yaml")
File.delete("scripts/room_logic.lua")
Dir.rmdir("scripts") rescue nil
Dir.rmdir("assets") rescue nil

puts "YAML scene example completed!"
