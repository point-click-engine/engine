require "../spec_helper"
require "../../src/inventory/inventory_item"

module PointClickEngine::Inventory
  describe InventoryItem do
    describe "#initialize" do
      it "creates item with name and description" do
        item = InventoryItem.new("sword", "A sharp blade")
        item.name.should eq("sword")
        item.description.should eq("A sharp blade")
      end

      it "validates on initialization" do
        expect_raises(ItemValidationError) do
          InventoryItem.new("", "Empty name should fail")
        end
      end

      it "allows valid names with underscores and dashes" do
        item = InventoryItem.new("magic_sword-01", "A magic sword")
        item.name.should eq("magic_sword-01")
      end
    end

    describe "#validate!" do
      it "raises ItemValidationError for invalid items" do
        item = InventoryItem.new
        item.name = ""

        expect_raises(ItemValidationError) do
          item.validate!
        end
      end

      it "passes for valid items" do
        item = InventoryItem.new
        item.name = "valid_name"
        item.description = "Valid description"

        item.validate! # Should not raise
      end
    end

    describe "#validate" do
      it "returns empty array for valid items" do
        item = InventoryItem.new
        item.name = "valid_name"
        item.description = "A valid item"

        errors = item.validate
        errors.should be_empty
      end

      describe "name validation" do
        it "catches empty name" do
          item = InventoryItem.new
          item.name = ""

          errors = item.validate
          errors.should contain("Item name cannot be empty")
        end

        it "catches too long name" do
          item = InventoryItem.new
          item.name = "a" * 65

          errors = item.validate
          errors.any? { |e| e.includes?("too long") }.should be_true
        end

        it "catches invalid characters" do
          item = InventoryItem.new
          item.name = "invalid name!"

          errors = item.validate
          errors.any? { |e| e.includes?("must start with a letter") }.should be_true
        end

        it "catches name starting with number" do
          item = InventoryItem.new
          item.name = "123item"

          errors = item.validate
          errors.any? { |e| e.includes?("must start with a letter") }.should be_true
        end

        it "catches name starting with underscore" do
          item = InventoryItem.new
          item.name = "_item"

          errors = item.validate
          errors.any? { |e| e.includes?("must start with a letter") }.should be_true
        end
      end

      describe "description validation" do
        it "catches too long description" do
          item = InventoryItem.new
          item.name = "item"
          item.description = "a" * 501

          errors = item.validate
          errors.any? { |e| e.includes?("description too long") }.should be_true
        end
      end

      describe "array limit validation" do
        it "catches too many combinable items" do
          item = InventoryItem.new
          item.name = "item"
          51.times { |i| item.combinable_with << "item#{i}" }

          errors = item.validate
          errors.any? { |e| e.includes?("Too many combinable") }.should be_true
        end

        it "catches too many usable_on targets" do
          item = InventoryItem.new
          item.name = "item"
          51.times { |i| item.usable_on << "target#{i}" }

          errors = item.validate
          errors.any? { |e| e.includes?("Too many usable_on") }.should be_true
        end

        it "catches too many combine actions" do
          item = InventoryItem.new
          item.name = "item"
          51.times { |i| item.combine_actions["item#{i}"] = "action#{i}" }

          errors = item.validate
          errors.any? { |e| e.includes?("Too many combine") }.should be_true
        end
      end

      describe "combinable_with validation" do
        it "catches invalid combinable item names" do
          item = InventoryItem.new
          item.name = "item"
          item.combinable_with << "invalid name!"

          errors = item.validate
          errors.any? { |e| e.includes?("Invalid combinable item name") }.should be_true
        end
      end

      describe "usable_on validation" do
        it "catches empty target names" do
          item = InventoryItem.new
          item.name = "item"
          item.usable_on << ""

          errors = item.validate
          errors.any? { |e| e.includes?("Empty target name") }.should be_true
        end
      end
    end

    describe "#valid?" do
      it "returns true for valid items" do
        item = InventoryItem.new
        item.name = "valid_item"
        item.description = "A valid item"

        item.valid?.should be_true
      end

      it "returns false for invalid items" do
        item = InventoryItem.new
        item.name = ""

        item.valid?.should be_false
      end
    end

    describe "#can_combine_with?" do
      it "returns true for combinable items" do
        item1 = InventoryItem.new("item1", "First item")
        item2 = InventoryItem.new("item2", "Second item")
        item1.combinable_with << "item2"

        item1.can_combine_with?(item2).should be_true
      end

      it "returns false for non-combinable items" do
        item1 = InventoryItem.new("item1", "First item")
        item2 = InventoryItem.new("item2", "Second item")

        item1.can_combine_with?(item2).should be_false
      end
    end

    describe "#can_use_on?" do
      it "returns true for usable targets" do
        item = InventoryItem.new("key", "A key")
        item.usable_on << "door"

        item.can_use_on?("door").should be_true
      end

      it "returns false for non-usable targets" do
        item = InventoryItem.new("key", "A key")

        item.can_use_on?("rock").should be_false
      end
    end

    describe "#get_combine_action" do
      it "returns action for combinable items" do
        item = InventoryItem.new("item1", "First item")
        item.combine_actions["item2"] = "merge_items"

        item.get_combine_action("item2").should eq("merge_items")
      end

      it "returns nil for non-combinable items" do
        item = InventoryItem.new("item1", "First item")

        item.get_combine_action("item2").should be_nil
      end
    end

    describe "defaults" do
      it "has empty defaults" do
        item = InventoryItem.new
        item.combinable_with.should be_empty
        item.usable_on.should be_empty
        item.combine_actions.should be_empty
        item.consumable.should be_false
        item.use_action.should be_nil
        item.icon_path.should be_nil
        item.icon.should be_nil
      end
    end

    describe ItemValidationError do
      it "stores item name" do
        error = ItemValidationError.new("Test error", "test_item")
        error.message.should eq("Validation failed: Test error")
        error.item_name.should eq("test_item")
        error.errors.should eq(["Test error"])
      end

      it "works without item name" do
        error = ItemValidationError.new("Test error")
        error.message.should eq("Validation failed: Test error")
        error.item_name.should be_nil
      end

      it "accepts array of errors" do
        errors = ["Error 1", "Error 2"]
        error = ItemValidationError.new(errors, "test_item")
        error.errors.should eq(errors)
        error.item_name.should eq("test_item")
      end
    end

    describe "NAME_PATTERN" do
      it "matches valid names" do
        InventoryItem::NAME_PATTERN.matches?("item").should be_true
        InventoryItem::NAME_PATTERN.matches?("Item").should be_true
        InventoryItem::NAME_PATTERN.matches?("item123").should be_true
        InventoryItem::NAME_PATTERN.matches?("my_item").should be_true
        InventoryItem::NAME_PATTERN.matches?("my-item").should be_true
        InventoryItem::NAME_PATTERN.matches?("a").should be_true
      end

      it "rejects invalid names" do
        InventoryItem::NAME_PATTERN.matches?("").should be_false
        InventoryItem::NAME_PATTERN.matches?("123item").should be_false
        InventoryItem::NAME_PATTERN.matches?("_item").should be_false
        InventoryItem::NAME_PATTERN.matches?("-item").should be_false
        InventoryItem::NAME_PATTERN.matches?("item name").should be_false
        InventoryItem::NAME_PATTERN.matches?("item!").should be_false
      end
    end
  end
end
