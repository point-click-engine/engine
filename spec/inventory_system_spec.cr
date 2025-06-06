require "./spec_helper"

describe PointClickEngine::Inventory::InventorySystem do
  describe "#new" do
    it "creates a new inventory system" do
      inventory = PointClickEngine::Inventory::InventorySystem.new
      inventory.items.should be_empty
      inventory.visible.should be_false
    end
  end

  describe "#add_item and #has_item?" do
    it "adds items and checks for existence" do
      inventory = PointClickEngine::Inventory::InventorySystem.new
      item = PointClickEngine::Inventory::InventoryItem.new("key", "A rusty key")

      inventory.add_item(item)
      inventory.has_item?("key").should be_true
      inventory.has_item?("sword").should be_false
    end

    it "prevents duplicate items" do
      inventory = PointClickEngine::Inventory::InventorySystem.new
      item1 = PointClickEngine::Inventory::InventoryItem.new("key", "A rusty key")
      item2 = PointClickEngine::Inventory::InventoryItem.new("key", "Another key")

      inventory.add_item(item1)
      inventory.add_item(item2)
      inventory.items.size.should eq(1)
    end
  end

  describe "#remove_item" do
    it "removes items from inventory" do
      inventory = PointClickEngine::Inventory::InventorySystem.new
      item = PointClickEngine::Inventory::InventoryItem.new("key", "A rusty key")

      inventory.add_item(item)
      inventory.remove_item("key")
      inventory.has_item?("key").should be_false
    end
  end

  describe "#get_item" do
    it "retrieves items by name" do
      inventory = PointClickEngine::Inventory::InventorySystem.new
      item = PointClickEngine::Inventory::InventoryItem.new("key", "A rusty key")

      inventory.add_item(item)
      retrieved = inventory.get_item("key")
      retrieved.should eq(item)
      inventory.get_item("nonexistent").should be_nil
    end
  end
end

describe PointClickEngine::Inventory::InventoryItem do
  describe "#new" do
    it "creates a new inventory item" do
      item = PointClickEngine::Inventory::InventoryItem.new("sword", "A sharp blade")
      item.name.should eq("sword")
      item.description.should eq("A sharp blade")
    end
  end

  describe "#can_combine_with?" do
    it "checks if items can be combined" do
      key = PointClickEngine::Inventory::InventoryItem.new("key", "A key")
      lock = PointClickEngine::Inventory::InventoryItem.new("lock", "A lock")

      key.combinable_with = ["lock"]
      key.can_combine_with?(lock).should be_true
      lock.can_combine_with?(key).should be_false
    end
  end

  describe "#can_use_on?" do
    it "checks if item can be used on target" do
      key = PointClickEngine::Inventory::InventoryItem.new("key", "A key")
      key.usable_on = ["door", "chest"]

      key.can_use_on?("door").should be_true
      key.can_use_on?("window").should be_false
    end
  end

  describe "#get_combine_action" do
    it "returns combine action for specific items" do
      glue = PointClickEngine::Inventory::InventoryItem.new("glue", "Sticky glue")
      glue.combine_actions = {"paper" => "create_sticky_note"}

      glue.get_combine_action("paper").should eq("create_sticky_note")
      glue.get_combine_action("rock").should be_nil
    end
  end
end
