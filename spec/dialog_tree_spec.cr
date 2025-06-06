require "./spec_helper"

describe PointClickEngine::Characters::Dialogue::DialogTree do
  describe "#new" do
    it "creates a new dialog tree" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_tree")
      tree.name.should eq("test_tree")
      tree.nodes.should be_empty
    end
  end

  describe "#add_node" do
    it "adds a node to the tree" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_tree")
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("node1", "Hello!")
      
      tree.add_node(node)
      tree.nodes["node1"].should eq(node)
    end
  end

  describe "#set_variable and #get_variable" do
    it "stores and retrieves variables" do
      tree = PointClickEngine::Characters::Dialogue::DialogTree.new("test_tree")
      
      tree.set_variable("player_name", "Guybrush")
      tree.get_variable("player_name").should eq("Guybrush")
      tree.get_variable("nonexistent").should be_nil
    end
  end

  describe "DialogNode" do
    it "creates nodes with choices" do
      node = PointClickEngine::Characters::Dialogue::DialogNode.new("greeting", "Hello there!")
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Hi back!", "response1")
      
      node.add_choice(choice)
      node.choices.size.should eq(1)
      node.choices[0].text.should eq("Hi back!")
    end
  end

  describe "DialogChoice" do
    it "tracks usage for once-only choices" do
      choice = PointClickEngine::Characters::Dialogue::DialogChoice.new("Secret option", "secret")
      choice.once_only = true
      
      choice.available?.should be_true
      choice.used = true
      choice.available?.should be_false
    end
  end
end