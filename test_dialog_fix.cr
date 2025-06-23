require "./src/point_click_engine"

# Test the dialog exhaustion fix
engine = PointClickEngine::Core::Engine.new(800, 600, "Dialog Fix Test")
engine.init

# Create a test scene
scene = PointClickEngine::Scenes::Scene.new("test_scene")
engine.add_scene(scene)
engine.change_scene("test_scene")

# Enable verb input
engine.enable_verb_input

# Create a dialog tree with exhaustible choices
dialog_tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_npc")

# Create greeting node with once-only choices
greeting_node = PointClickEngine::Characters::Dialogue::DialogNode.new("greeting", "Hello there!")
choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Tell me about yourself", "info")
choice1.once_only = true
choice2 = PointClickEngine::Characters::Dialogue::DialogChoice.new("What do you do here?", "job")
choice2.once_only = true
greeting_node.add_choice(choice1)
greeting_node.add_choice(choice2)

# Create response nodes that loop back to greeting
info_node = PointClickEngine::Characters::Dialogue::DialogNode.new("info", "I'm just a test character.")
info_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("I see...", "greeting")
info_node.add_choice(info_choice)

job_node = PointClickEngine::Characters::Dialogue::DialogNode.new("job", "I help test dialog systems.")
job_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Interesting...", "greeting")
job_node.add_choice(job_choice)

dialog_tree.add_node(greeting_node)
dialog_tree.add_node(info_node)
dialog_tree.add_node(job_node)

# Add the dialog tree to the engine
engine.dialog_manager.try(&.add_dialog_tree(dialog_tree))

# Create a test NPC
npc = PointClickEngine::Characters::NPC.new(
  "Test NPC",
  RL::Vector2.new(x: 400, y: 300),
  RL::Vector2.new(x: 64, y: 64)
)

# Set up the NPC to use the dialog tree
npc.on_talk = -> {
  puts "Starting dialog with Test NPC"
  dialog_tree.start_conversation("greeting")
}

scene.add_character(npc)

puts "Test setup complete!"
puts "Instructions:"
puts "1. Right-click on the NPC to talk"
puts "2. Exhaust both dialog choices by selecting them"
puts "3. Try right-clicking again to test verb input"
puts "4. Try number keys 1-6 to change verbs"
puts "5. Use mouse wheel to cycle verbs"
puts "6. Press ESC to exit"

# Start the test
engine.run
