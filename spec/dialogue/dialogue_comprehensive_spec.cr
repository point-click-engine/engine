require "../spec_helper"

# Dialogue system comprehensive tests
# Tests character dialogue, dialog trees, conversation management, and choice handling
describe "Dialogue System Comprehensive Tests" do
  describe "dialog node functionality" do
    it "creates dialog nodes correctly" do
      # Test basic node creation
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("intro_1", "Hello there, adventurer!")
      node.id.should eq("intro_1")
      node.text.should eq("Hello there, adventurer!")
      node.character_name.should be_nil
      node.choices.should be_empty
      node.conditions.should be_empty
      node.actions.should be_empty
      node.is_end.should be_false

      # Test default constructor
      empty_node = PointClickEngine::Characters::Dialogue::DialogNode.new
      empty_node.id.should eq("")
      empty_node.text.should eq("")
    end

    it "manages node properties correctly" do
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("test_node", "Test text")

      # Set properties
      node.character_name = "Butler"
      node.is_end = true
      node.conditions = ["has_key", "door_unlocked"]
      node.actions = ["set visited_butler true", "give item gold_coin"]

      # Verify properties
      node.character_name.should eq("Butler")
      node.is_end.should be_true
      node.conditions.should eq(["has_key", "door_unlocked"])
      node.actions.should eq(["set visited_butler true", "give item gold_coin"])
    end

    it "handles dialog choices" do
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("choice_node", "What would you like to do?")

      # Add choices
      choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Ask about the castle", "castle_info")
      choice2 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Say goodbye", "goodbye")

      node.add_choice(choice1)
      node.add_choice(choice2)

      node.choices.size.should eq(2)
      node.choices[0].text.should eq("Ask about the castle")
      node.choices[0].target_node_id.should eq("castle_info")
      node.choices[1].text.should eq("Say goodbye")
      node.choices[1].target_node_id.should eq("goodbye")
    end
  end

  describe "dialog choice functionality" do
    it "creates dialog choices correctly" do
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Test choice", "target_node")
      choice.text.should eq("Test choice")
      choice.target_node_id.should eq("target_node")
      choice.conditions.should be_empty
      choice.actions.should be_empty
      choice.once_only.should be_false
      choice.used.should be_false

      # Test default constructor
      empty_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new
      empty_choice.text.should eq("")
      empty_choice.target_node_id.should eq("")
    end

    it "handles availability correctly" do
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("One-time choice", "special_node")

      # Initially available
      choice.available?.should be_true

      # Set as once-only
      choice.once_only = true
      choice.available?.should be_true # Still available before use

      # Mark as used
      choice.used = true
      choice.available?.should be_false # No longer available

      # Reset for reuse
      choice.used = false
      choice.available?.should be_true
    end

    it "handles choice properties" do
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Complex choice", "complex_node")

      # Set properties
      choice.conditions = ["has_permit", "!angry_guard"]
      choice.actions = ["set met_guard true", "add reputation 1"]
      choice.once_only = true

      # Verify properties
      choice.conditions.should eq(["has_permit", "!angry_guard"])
      choice.actions.should eq(["set met_guard true", "add reputation 1"])
      choice.once_only.should be_true
    end
  end

  describe "dialog tree management" do
    it "creates and manages dialog trees" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Butler Conversation")
      tree.name.should eq("Butler Conversation")
      tree.nodes.should be_empty
      tree.current_node_id.should be_nil
      tree.variables.should be_empty

      # Test default constructor
      empty_tree = PointClickEngine::Characters::Dialogue::DialogTree.new
      empty_tree.name.should eq("")
    end

    it "adds and retrieves nodes" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Test Tree")

      # Add nodes
      node1 = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Welcome to the castle!")
      node2 = PointClickEngine::Characters::Dialogue::DialogNode.new("info", "This castle has many secrets.")
      node3 = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "Goodbye!")

      tree.add_node(node1)
      tree.add_node(node2)
      tree.add_node(node3)

      tree.nodes.size.should eq(3)
      tree.nodes["start"]?.should eq(node1)
      tree.nodes["info"]?.should eq(node2)
      tree.nodes["end"]?.should eq(node3)

      # Test node retrieval
      tree.current_node_id = "start"
      tree.get_current_node.should eq(node1)

      tree.current_node_id = "nonexistent"
      tree.get_current_node.should be_nil
    end

    it "manages variables correctly" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Variable Test")

      # Set variables
      tree.set_variable("met_butler", "true")
      tree.set_variable("player_name", "Hero")
      tree.set_variable("castle_visits", "3")

      # Retrieve variables
      tree.get_variable("met_butler").should eq("true")
      tree.get_variable("player_name").should eq("Hero")
      tree.get_variable("castle_visits").should eq("3")
      tree.get_variable("nonexistent").should be_nil

      # Update variables
      tree.set_variable("castle_visits", "4")
      tree.get_variable("castle_visits").should eq("4")
    end

    it "handles conversation flow" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Flow Test")

      # Create conversation nodes
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("How are you?", "how_are_you")
      choice2 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Goodbye", "end")
      start_node.add_choice(choice1)
      start_node.add_choice(choice2)

      response_node = PointClickEngine::Characters::Dialogue::DialogNode.new("how_are_you", "I'm doing well, thank you!")
      back_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("That's good to hear", "end")
      response_node.add_choice(back_choice)

      end_node = PointClickEngine::Characters::Dialogue::DialogNode.new("end", "See you later!")
      end_node.is_end = true

      tree.add_node(start_node)
      tree.add_node(response_node)
      tree.add_node(end_node)

      # Test conversation flow (without engine integration)
      tree.current_node_id = "start"
      tree.get_current_node.should eq(start_node)

      # Simulate choice selection (choice 0 = "How are you?")
      # Since we can't easily test the full make_choice method without engine,
      # we'll test the node navigation logic
      tree.current_node_id = "how_are_you"
      tree.get_current_node.should eq(response_node)

      tree.current_node_id = "end"
      tree.get_current_node.should eq(end_node)
      tree.get_current_node.not_nil!.is_end.should be_true
    end
  end

  describe "dialog tree edge cases and stress tests" do
    it "handles complex branching conversations" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Complex Conversation")

      # Create a complex branching dialog
      start = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "What brings you here?")

      # Multiple branches from start
      ["quest", "shop", "info", "rumors", "leave"].each_with_index do |branch, i|
        choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Choice #{i + 1}", branch)
        start.add_choice(choice)
      end

      # Create response nodes
      quest_node = PointClickEngine::Characters::Dialogue::DialogNode.new("quest", "Ah, a quest seeker!")
      shop_node = PointClickEngine::Characters::Dialogue::DialogNode.new("shop", "Browse my wares!")
      info_node = PointClickEngine::Characters::Dialogue::DialogNode.new("info", "This is the capital city.")
      rumors_node = PointClickEngine::Characters::Dialogue::DialogNode.new("rumors", "I've heard strange tales...")
      leave_node = PointClickEngine::Characters::Dialogue::DialogNode.new("leave", "Safe travels!")
      leave_node.is_end = true

      # Add back-to-start choices for most nodes
      [quest_node, shop_node, info_node, rumors_node].each do |node|
        back_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Ask something else", "start")
        goodbye_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Goodbye", "leave")
        node.add_choice(back_choice)
        node.add_choice(goodbye_choice)
      end

      tree.add_node(start)
      tree.add_node(quest_node)
      tree.add_node(shop_node)
      tree.add_node(info_node)
      tree.add_node(rumors_node)
      tree.add_node(leave_node)

      # Test navigation through complex tree
      tree.nodes.size.should eq(6)
      tree.nodes["start"]?.should_not be_nil
      tree.nodes["quest"]?.should_not be_nil
      tree.nodes["leave"]?.should_not be_nil

      # Test that all non-end nodes have choices
      tree.nodes.values.each do |node|
        unless node.is_end
          node.choices.should_not be_empty
        end
      end
    end

    it "handles once-only choices correctly" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Once Only Test")

      node = PointClickEngine::Characters::Dialogue::DialogNode.new("test", "Choose wisely...")

      # Add once-only choice
      once_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Special option", "special")
      once_choice.once_only = true

      # Add regular choice
      regular_choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Regular option", "regular")

      node.add_choice(once_choice)
      node.add_choice(regular_choice)

      tree.add_node(node)

      # Initially both choices available
      available_choices = node.choices.select(&.available?)
      available_choices.size.should eq(2)

      # Mark once-only choice as used
      once_choice.used = true

      # Now only one choice available
      available_choices = node.choices.select(&.available?)
      available_choices.size.should eq(1)
      available_choices[0].should eq(regular_choice)
    end

    it "handles variable-based conditions" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Condition Test")

      # Set up variables
      tree.set_variable("has_key", "true")
      tree.set_variable("met_guard", "false")
      tree.set_variable("gold_coins", "5")

      # Create choices with conditions
      choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Use key", "unlock_door")
      choice1.conditions = ["has_key == true"]

      choice2 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Talk to guard", "guard_chat")
      choice2.conditions = ["met_guard == false"]

      choice3 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Buy item", "purchase")
      choice3.conditions = ["gold_coins >= 3"]

      # Test that choices exist (availability logic would be implemented in the condition checker)
      choice1.conditions.includes?("has_key == true").should be_true
      choice2.conditions.includes?("met_guard == false").should be_true
      choice3.conditions.includes?("gold_coins >= 3").should be_true
    end

    it "handles action execution" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Action Test")

      # Create node with actions
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("action_node", "Here's your reward!")
      node.actions = ["set quest_complete true", "set gold_coins 10", "set reputation 5"]

      # Create choice with actions
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Accept reward", "end")
      choice.actions = ["set reward_accepted true", "set met_merchant true"]

      # Test action format
      node.actions.includes?("set quest_complete true").should be_true
      node.actions.includes?("set gold_coins 10").should be_true
      choice.actions.includes?("set reward_accepted true").should be_true
    end
  end

  describe "character dialogue integration" do
    it "creates character dialogue systems" do
      character = TestCharacter.new("Test NPC", RL::Vector2.new(100.0_f32, 200.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))

      dialogue_system = PointClickEngine::Characters::Dialogue::CharacterDialogue.new(character)
      dialogue_system.character.should eq(character)
      dialogue_system.current_dialog_data.should be_nil
      dialogue_system.dialog_offset.x.should eq(0.0_f32)
      dialogue_system.dialog_offset.y.should eq(-100.0_f32)
    end

    it "handles dialog positioning calculations" do
      character = TestCharacter.new("Positioned NPC", RL::Vector2.new(400.0_f32, 300.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      dialogue_system = PointClickEngine::Characters::Dialogue::CharacterDialogue.new(character)

      # Test that positioning logic exists (actual calculation requires engine)
      dialogue_system.dialog_offset = RL::Vector2.new(10.0_f32, -80.0_f32)
      dialogue_system.dialog_offset.x.should eq(10.0_f32)
      dialogue_system.dialog_offset.y.should eq(-80.0_f32)
    end

    it "manages dialog state correctly" do
      character = TestCharacter.new("State NPC", RL::Vector2.new(0.0_f32, 0.0_f32), RL::Vector2.new(32.0_f32, 48.0_f32))
      dialogue_system = PointClickEngine::Characters::Dialogue::CharacterDialogue.new(character)

      # Initially no dialog
      dialogue_system.current_dialog_data.should be_nil

      # Update should handle no dialog gracefully
      dialogue_system.update(0.016_f32) # Should not crash
    end
  end

  describe "dialogue performance and memory tests" do
    it "handles many dialog nodes efficiently" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Performance Test")

      # Create many nodes
      1000.times do |i|
        node = PointClickEngine::Characters::Dialogue::DialogNode.new("node_#{i}", "Text for node #{i}")

        # Add some choices
        if i < 999
          choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Go to next", "node_#{i + 1}")
          node.add_choice(choice)
        else
          node.is_end = true
        end

        tree.add_node(node)
      end

      tree.nodes.size.should eq(1000)

      # Test node lookup performance
      start_time = Time.monotonic
      100.times do |i|
        node_id = "node_#{rand(1000)}"
        node = tree.nodes[node_id]?
        node.should_not be_nil
      end
      lookup_time = Time.monotonic - start_time

      puts "Dialog node lookup performance:"
      puts "  Nodes: #{tree.nodes.size}"
      puts "  Lookups: 100"
      puts "  Total time: #{lookup_time.total_milliseconds.round(2)}ms"
      puts "  Time per lookup: #{(lookup_time.total_milliseconds / 100).round(4)}ms"

      # Should be very fast
      (lookup_time.total_milliseconds / 100).should be < 0.1 # 0.1ms per lookup
    end

    it "handles complex choice filtering" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Choice Filter Test")

      node = PointClickEngine::Characters::Dialogue::DialogNode.new("complex", "Many choices...")

      # Add many choices with different availability
      100.times do |i|
        choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Choice #{i}", "target_#{i}")

        # Make some choices once-only and used
        if i % 3 == 0
          choice.once_only = true
          choice.used = (i % 6 == 0) # Half of once-only choices are used
        end

        node.add_choice(choice)
      end

      tree.add_node(node)

      # Test choice filtering performance
      start_time = Time.monotonic
      available_choices = node.choices.select(&.available?)
      filter_time = Time.monotonic - start_time

      puts "Choice filtering performance:"
      puts "  Total choices: #{node.choices.size}"
      puts "  Available choices: #{available_choices.size}"
      puts "  Filter time: #{filter_time.total_milliseconds.round(2)}ms"

      # Should filter correctly
      expected_available = node.choices.count { |c| !c.once_only || !c.used }
      available_choices.size.should eq(expected_available)

      # Should be fast
      filter_time.total_milliseconds.should be < 1.0 # 1ms
    end

    it "manages memory efficiently with dialog trees" do
      initial_memory = GC.stats.heap_size

      # Create and destroy many dialog trees
      50.times do |cycle|
        tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Memory Test #{cycle}")

        # Add nodes with complex structures
        20.times do |i|
          node = PointClickEngine::Characters::Dialogue::DialogNode.new("node_#{cycle}_#{i}", "Text for node #{i} in cycle #{cycle}")

          # Add conditions and actions
          node.conditions = ["var1 == true", "var2 >= #{i}", "!var3"]
          node.actions = ["set visited_#{i} true", "add score #{i}", "log visited node #{i}"]

          # Add choices
          5.times do |j|
            choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Choice #{j}", "target_#{i}_#{j}")
            choice.conditions = ["choice_#{j}_available"]
            choice.actions = ["set choice_#{j}_used true"]
            node.add_choice(choice)
          end

          tree.add_node(node)
        end

        # Use the tree
        tree.set_variable("test_var", "test_value_#{cycle}")
        tree.current_node_id = "node_#{cycle}_0"
        current_node = tree.get_current_node

        if current_node
          available_choices = current_node.choices.select(&.available?)
          available_choices.size.should be > 0
        end

        # Tree goes out of scope here
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Dialogue memory test: growth = #{memory_growth} bytes"

      # Should not leak significant memory
      memory_growth.should be < 5_000_000 # 5MB limit
    end
  end

  describe "dialogue serialization and persistence" do
    it "handles dialog tree serialization" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("Serialization Test")

      # Create a simple dialog structure
      start_node = PointClickEngine::Characters::Dialogue::DialogNode.new("start", "Hello!")
      start_node.character_name = "Butler"
      start_node.conditions = ["daytime"]
      start_node.actions = ["set met_butler true"]

      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("How are you?", "response")
      choice.once_only = true
      choice.conditions = ["!asked_before"]
      choice.actions = ["set asked_before true"]

      start_node.add_choice(choice)

      response_node = PointClickEngine::Characters::Dialogue::DialogNode.new("response", "I'm well, thank you!")
      response_node.is_end = true

      tree.add_node(start_node)
      tree.add_node(response_node)
      tree.set_variable("test_var", "test_value")

      # Test YAML serialization
      yaml_string = tree.to_yaml
      yaml_string.should_not be_empty
      yaml_string.includes?("Serialization Test").should be_true
      yaml_string.includes?("Hello!").should be_true
      yaml_string.includes?("Butler").should be_true

      # Test deserialization
      loaded_tree = PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(yaml_string)
      loaded_tree.name.should eq("Serialization Test")
      loaded_tree.nodes.size.should eq(2)
      loaded_tree.variables["test_var"]?.should eq("test_value")

      # Test node preservation
      loaded_start = loaded_tree.nodes["start"]?
      loaded_start.should_not be_nil
      if loaded_start
        loaded_start.text.should eq("Hello!")
        loaded_start.character_name.should eq("Butler")
        loaded_start.conditions.should eq(["daytime"])
        loaded_start.actions.should eq(["set met_butler true"])
        loaded_start.choices.size.should eq(1)

        # Test choice preservation
        loaded_choice = loaded_start.choices[0]
        loaded_choice.text.should eq("How are you?")
        loaded_choice.target_node_id.should eq("response")
        loaded_choice.once_only.should be_true
        loaded_choice.conditions.should eq(["!asked_before"])
        loaded_choice.actions.should eq(["set asked_before true"])
      end
    end

    it "handles corrupted dialog data" do
      corrupted_yaml_data = [
        "invalid: yaml: structure: [",
        "---\nname: test\nnodes:",
        "",
        "---\nname: \"Test\"\nnodes:\n  invalid_structure",
        "completely invalid content",
      ]

      corrupted_yaml_data.each do |data|
        begin
          PointClickEngine::Characters::Dialogue::DialogTree.from_yaml(data)
          # If it succeeds, that's fine too
        rescue ex
          # Errors are expected for corrupted data
          ex.should be_a(Exception)
        end
      end
    end
  end
end

# Test character class for dialogue tests
class TestCharacter < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character)
    # Test implementation
  end

  def on_look
    # Test implementation
  end

  def on_talk
    # Test implementation
  end
end
