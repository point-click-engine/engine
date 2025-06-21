require "../spec_helper"

module PointClickEngine
  describe Inventory::InventorySystem do
    describe "#initialize" do
      it "creates an empty inventory" do
        inventory = Inventory::InventorySystem.new
        inventory.items.should be_empty
        inventory.selected_item.should be_nil
      end
    end

    describe "#add_item" do
      it "adds an item to inventory" do
        inventory = Inventory::InventorySystem.new
        item = Inventory::InventoryItem.new("key", "A rusty key")

        inventory.add_item(item)
        inventory.items.size.should eq(1)
        inventory.items.first.name.should eq("key")
      end

      it "doesn't add duplicate items" do
        inventory = Inventory::InventorySystem.new
        item1 = Inventory::InventoryItem.new("key", "A rusty key")
        item2 = Inventory::InventoryItem.new("key", "Another key")

        inventory.add_item(item1)
        inventory.add_item(item2)
        inventory.items.size.should eq(1)
      end
    end

    describe "#remove_item" do
      it "removes item by name" do
        inventory = Inventory::InventorySystem.new
        item = Inventory::InventoryItem.new("key", "A rusty key")
        inventory.add_item(item)

        inventory.remove_item("key")
        inventory.items.should be_empty
      end

      it "clears selected item if removed" do
        inventory = Inventory::InventorySystem.new
        item = Inventory::InventoryItem.new("key", "A rusty key")
        inventory.add_item(item)
        inventory.selected_item = item

        inventory.remove_item("key")
        inventory.selected_item.should be_nil
      end
    end

    describe "#has_item?" do
      it "returns true if item exists" do
        inventory = Inventory::InventorySystem.new
        item = Inventory::InventoryItem.new("key", "A rusty key")
        inventory.add_item(item)

        inventory.has_item?("key").should be_true
        inventory.has_item?("sword").should be_false
      end
    end

    describe "#clear" do
      it "removes all items from inventory" do
        inventory = Inventory::InventorySystem.new
        inventory.add_item(Inventory::InventoryItem.new("key", "A rusty key"))
        inventory.add_item(Inventory::InventoryItem.new("gem", "A sparkling gem"))

        inventory.items.size.should eq(2)
        inventory.clear
        inventory.items.size.should eq(0)
      end

      it "clears selected and combining items" do
        inventory = Inventory::InventorySystem.new
        item = Inventory::InventoryItem.new("key", "A rusty key")
        inventory.add_item(item)
        inventory.selected_item = item

        inventory.clear
        inventory.selected_item.should be_nil
      end
    end

    describe "#get_item" do
      it "returns item by name" do
        inventory = Inventory::InventorySystem.new
        item = Inventory::InventoryItem.new("key", "A rusty key")
        inventory.add_item(item)

        found_item = inventory.get_item("key")
        found_item.should_not be_nil
        found_item.try(&.name).should eq("key")
      end

      it "returns nil if item not found" do
        inventory = Inventory::InventorySystem.new
        inventory.get_item("sword").should be_nil
      end
    end
  end
end
