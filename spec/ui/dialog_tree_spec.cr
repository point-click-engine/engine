require "../spec_helper"

describe PointClickEngine::Characters::Dialogue::DialogTree do
  it "advances to next node when choice is made" do
    # Create a simple dialog tree
    tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_tree")

    # Add nodes
    greeting = PointClickEngine::Characters::Dialogue::DialogNode.new("greeting", "Hello!")
    greeting.add_choice(PointClickEngine::Characters::Dialogue::DialogChoice.new("Hi there", "response"))

    response = PointClickEngine::Characters::Dialogue::DialogNode.new("response", "How are you?")
    response.is_end = true

    tree.add_node(greeting)
    tree.add_node(response)

    # Start conversation
    tree.current_node_id = "greeting" # Set directly to avoid Engine dependency
    tree.current_node_id.should eq("greeting")

    # Make a choice manually to avoid Engine dependency
    if current_node = tree.get_current_node
      available_choices = current_node.choices.select(&.available?)
      if choice = available_choices[0]?
        tree.current_node_id = choice.target_node_id
      end
    end
    tree.current_node_id.should eq("response")
  end

  it "filters available choices correctly" do
    tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_tree")

    node = PointClickEngine::Characters::Dialogue::DialogNode.new("test", "Choose:")

    # Add choices with different availability
    choice1 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Always available", "next1")
    choice2 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Once only", "next2")
    choice2.once_only = true
    choice3 = PointClickEngine::Characters::Dialogue::DialogChoice.new("Also available", "next3")

    node.add_choice(choice1)
    node.add_choice(choice2)
    node.add_choice(choice3)

    tree.add_node(node)
    tree.add_node(PointClickEngine::Characters::Dialogue::DialogNode.new("next1", "End"))
    tree.add_node(PointClickEngine::Characters::Dialogue::DialogNode.new("next2", "End"))
    tree.add_node(PointClickEngine::Characters::Dialogue::DialogNode.new("next3", "End"))

    tree.current_node_id = "test" # Set directly to avoid Engine dependency

    # First time: all choices available
    current = tree.get_current_node.not_nil!
    available = current.choices.select(&.available?)
    available.size.should eq(3)

    # Choose the once-only option manually
    if choice = available[1]?
      choice.used = true if choice.once_only
      tree.current_node_id = choice.target_node_id
    end
    tree.current_node_id.should eq("next2")

    # Go back to test node
    tree.current_node_id = "test"

    # Now only 2 choices should be available
    current = tree.get_current_node.not_nil!
    available = current.choices.select(&.available?)
    available.size.should eq(2)
    available[0].text.should eq("Always available")
    available[1].text.should eq("Also available")
  end
end

describe PointClickEngine::UI::DialogManager do
  it "shows dialog choices without closing prematurely" do
    dm = PointClickEngine::UI::DialogManager.new
    dialog_closed = false
    choice_made = false

    # Show dialog with choices
    dm.show_dialog_choices("Pick one:", ["Option A", "Option B"]) do |index|
      choice_made = true
      # Simulate showing next dialog
      dm.show_dialog_choices("Next dialog", ["Continue"]) do |_|
        dialog_closed = true
      end
    end

    # Dialog should be active
    dm.is_dialog_active?.should be_true

    # Simulate clicking first choice
    if dialog = dm.current_dialog
      dialog.choices[0].action.call
    end

    # Choice callback should have been called
    choice_made.should be_true

    # New dialog should be active (not closed)
    dm.is_dialog_active?.should be_true
    dm.current_dialog.not_nil!.text.should eq("Next dialog")
  end

  it "properly converts screen coordinates to game coordinates" do
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    dm = engine.dialog_manager.not_nil!

    # Create a dialog
    dm.show_dialog_choices("Test", ["Choice 1", "Choice 2"]) { |_| }

    dialog = dm.current_dialog.not_nil!

    # Dialog should be positioned in game space (1024x768)
    dialog.position.y.should be < 768
    dialog.size.x.should eq(984) # 1024 - 40 (margins)
  end
end
