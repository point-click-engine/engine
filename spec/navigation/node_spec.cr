require "../spec_helper"
require "../../src/navigation/node"

describe PointClickEngine::Navigation::Node do
  describe "initialization" do
    it "initializes with coordinates" do
      node = PointClickEngine::Navigation::Node.new(5, 10)

      node.x.should eq(5)
      node.y.should eq(10)
      node.g_cost.should eq(0.0f32)
      node.h_cost.should eq(0.0f32)
      node.parent.should be_nil
    end

    it "initializes with costs and parent" do
      parent = PointClickEngine::Navigation::Node.new(1, 1)
      node = PointClickEngine::Navigation::Node.new(2, 3, 5.5f32, 3.2f32, parent)

      node.x.should eq(2)
      node.y.should eq(3)
      node.g_cost.should eq(5.5f32)
      node.h_cost.should eq(3.2f32)
      node.parent.should eq(parent)
    end
  end

  describe "f_cost calculation" do
    it "calculates f_cost as sum of g_cost and h_cost" do
      node = PointClickEngine::Navigation::Node.new(0, 0, 4.0f32, 6.0f32)

      node.f_cost.should eq(10.0f32)
    end

    it "handles zero costs" do
      node = PointClickEngine::Navigation::Node.new(0, 0, 0.0f32, 0.0f32)

      node.f_cost.should eq(0.0f32)
    end

    it "updates when costs change" do
      node = PointClickEngine::Navigation::Node.new(0, 0, 2.0f32, 3.0f32)

      node.f_cost.should eq(5.0f32)

      node.g_cost = 1.0f32
      node.h_cost = 4.0f32

      node.f_cost.should eq(5.0f32)
    end
  end

  describe "equality and hashing" do
    it "considers nodes equal with same coordinates" do
      node1 = PointClickEngine::Navigation::Node.new(5, 10)
      node2 = PointClickEngine::Navigation::Node.new(5, 10)

      node1.should eq(node2)
    end

    it "considers nodes unequal with different coordinates" do
      node1 = PointClickEngine::Navigation::Node.new(5, 10)
      node2 = PointClickEngine::Navigation::Node.new(5, 11)
      node3 = PointClickEngine::Navigation::Node.new(6, 10)

      node1.should_not eq(node2)
      node1.should_not eq(node3)
    end

    it "ignores costs and parent for equality" do
      parent = PointClickEngine::Navigation::Node.new(1, 1)
      node1 = PointClickEngine::Navigation::Node.new(5, 10, 2.0f32, 3.0f32, parent)
      node2 = PointClickEngine::Navigation::Node.new(5, 10, 5.0f32, 7.0f32, nil)

      node1.should eq(node2)
    end

    it "generates same hash for equal nodes" do
      node1 = PointClickEngine::Navigation::Node.new(5, 10)
      node2 = PointClickEngine::Navigation::Node.new(5, 10)

      node1.hash.should eq(node2.hash)
    end

    it "generates different hash for different nodes" do
      node1 = PointClickEngine::Navigation::Node.new(5, 10)
      node2 = PointClickEngine::Navigation::Node.new(5, 11)

      node1.hash.should_not eq(node2.hash)
    end
  end

  describe "utility methods" do
    it "creates copy with updated costs" do
      original = PointClickEngine::Navigation::Node.new(5, 10, 1.0f32, 2.0f32)
      parent = PointClickEngine::Navigation::Node.new(4, 9)

      copy = original.with_costs(3.0f32, 4.0f32, parent)

      copy.x.should eq(5)
      copy.y.should eq(10)
      copy.g_cost.should eq(3.0f32)
      copy.h_cost.should eq(4.0f32)
      copy.parent.should eq(parent)

      # Original should be unchanged
      original.g_cost.should eq(1.0f32)
      original.h_cost.should eq(2.0f32)
      original.parent.should be_nil
    end

    it "calculates distance to another node" do
      node1 = PointClickEngine::Navigation::Node.new(0, 0)
      node2 = PointClickEngine::Navigation::Node.new(3, 4)

      distance = node1.distance_to(node2)
      distance.should be_close(5.0f32, 0.001f32)
    end

    it "calculates manhattan distance" do
      node1 = PointClickEngine::Navigation::Node.new(0, 0)
      node2 = PointClickEngine::Navigation::Node.new(3, 4)

      manhattan = node1.manhattan_distance_to(node2)
      manhattan.should eq(7)
    end

    it "calculates manhattan distance with negative coordinates" do
      node1 = PointClickEngine::Navigation::Node.new(-2, -3)
      node2 = PointClickEngine::Navigation::Node.new(1, 2)

      manhattan = node1.manhattan_distance_to(node2)
      manhattan.should eq(8)
    end
  end

  describe "adjacency checking" do
    let(center) { PointClickEngine::Navigation::Node.new(5, 5) }

    it "detects adjacent nodes including diagonals" do
      adjacent_positions = [
        {4, 4}, {4, 5}, {4, 6}, # Left column
        {5, 4}, {5, 6},         # Above and below center
        {6, 4}, {6, 5}, {6, 6}, # Right column
      ]

      adjacent_positions.each do |x, y|
        adjacent = PointClickEngine::Navigation::Node.new(x, y)
        center.adjacent_to?(adjacent).should be_true
      end
    end

    it "rejects non-adjacent nodes" do
      non_adjacent_positions = [
        {3, 5}, {7, 5}, {5, 3}, {5, 7}, # Two steps away
        {3, 3}, {3, 7}, {7, 3}, {7, 7}, # Two steps diagonally
        {0, 0}, {10, 10},               # Far away
      ]

      non_adjacent_positions.each do |x, y|
        non_adjacent = PointClickEngine::Navigation::Node.new(x, y)
        center.adjacent_to?(non_adjacent).should be_false
      end
    end

    it "rejects same position as adjacent" do
      same = PointClickEngine::Navigation::Node.new(5, 5)
      center.adjacent_to?(same).should be_false
    end

    it "detects orthogonally adjacent nodes" do
      orthogonal_positions = [
        {4, 5}, {6, 5}, {5, 4}, {5, 6},
      ]

      orthogonal_positions.each do |x, y|
        orthogonal = PointClickEngine::Navigation::Node.new(x, y)
        center.orthogonally_adjacent_to?(orthogonal).should be_true
      end
    end

    it "rejects diagonal nodes as orthogonally adjacent" do
      diagonal_positions = [
        {4, 4}, {4, 6}, {6, 4}, {6, 6},
      ]

      diagonal_positions.each do |x, y|
        diagonal = PointClickEngine::Navigation::Node.new(x, y)
        center.orthogonally_adjacent_to?(diagonal).should be_false
      end
    end

    it "detects diagonally adjacent nodes" do
      diagonal_positions = [
        {4, 4}, {4, 6}, {6, 4}, {6, 6},
      ]

      diagonal_positions.each do |x, y|
        diagonal = PointClickEngine::Navigation::Node.new(x, y)
        center.diagonally_adjacent_to?(diagonal).should be_true
      end
    end

    it "rejects orthogonal nodes as diagonally adjacent" do
      orthogonal_positions = [
        {4, 5}, {6, 5}, {5, 4}, {5, 6},
      ]

      orthogonal_positions.each do |x, y|
        orthogonal = PointClickEngine::Navigation::Node.new(x, y)
        center.diagonally_adjacent_to?(orthogonal).should be_false
      end
    end
  end

  describe "string representation" do
    it "provides readable string representation" do
      node = PointClickEngine::Navigation::Node.new(5, 10, 2.5f32, 3.7f32)

      str = node.to_s
      str.should contain("Node")
      str.should contain("5")
      str.should contain("10")
      str.should contain("2.5")
      str.should contain("3.7")
      str.should contain("6.2") # f_cost
    end
  end

  describe "edge cases" do
    it "handles zero coordinates" do
      node = PointClickEngine::Navigation::Node.new(0, 0)

      node.x.should eq(0)
      node.y.should eq(0)
    end

    it "handles negative coordinates" do
      node = PointClickEngine::Navigation::Node.new(-5, -10)

      node.x.should eq(-5)
      node.y.should eq(-10)
    end

    it "handles large coordinates" do
      node = PointClickEngine::Navigation::Node.new(1000000, 2000000)

      node.x.should eq(1000000)
      node.y.should eq(2000000)
    end

    it "handles very small costs" do
      node = PointClickEngine::Navigation::Node.new(0, 0, 0.001f32, 0.002f32)

      node.f_cost.should be_close(0.003f32, 0.0001f32)
    end

    it "handles very large costs" do
      node = PointClickEngine::Navigation::Node.new(0, 0, 1000000.0f32, 2000000.0f32)

      node.f_cost.should eq(3000000.0f32)
    end
  end

  describe "usage in collections" do
    it "works in arrays" do
      nodes = [
        PointClickEngine::Navigation::Node.new(1, 1),
        PointClickEngine::Navigation::Node.new(2, 2),
        PointClickEngine::Navigation::Node.new(3, 3),
      ]

      nodes.size.should eq(3)
      nodes[1].x.should eq(2)
    end

    it "works in sets" do
      node1 = PointClickEngine::Navigation::Node.new(1, 1)
      node2 = PointClickEngine::Navigation::Node.new(2, 2)
      node3 = PointClickEngine::Navigation::Node.new(1, 1) # Same as node1

      node_set = Set{node1, node2, node3}

      node_set.size.should eq(2) # node3 should be deduplicated
      node_set.should contain(node1)
      node_set.should contain(node2)
    end

    it "works in hashes as keys" do
      node1 = PointClickEngine::Navigation::Node.new(1, 1)
      node2 = PointClickEngine::Navigation::Node.new(2, 2)

      hash = {node1 => "first", node2 => "second"}

      hash[node1].should eq("first")
      hash[node2].should eq("second")
    end
  end
end
