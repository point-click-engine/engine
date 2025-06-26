require "../spec_helper"
require "../../src/ui/menu_navigator"

describe PointClickEngine::UI::MenuNavigator do
  describe "initialization" do
    it "initializes with default settings" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.wrap_navigation.should be_true
      navigator.skip_disabled_items.should be_true
      navigator.allow_empty_selection.should be_false
    end

    it "sets total items and initializes enabled items" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.total_items.should eq(5)
      navigator.enabled_item_count.should eq(5)
      navigator.current_index.should eq(0)
    end

    it "starts with valid navigation state" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.has_valid_selection?.should be_true
      navigator.has_enabled_items?.should be_true
    end
  end

  describe "item management" do
    it "sets total items and resets enabled state" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.set_total_items(3)

      navigator.total_items.should eq(3)
      navigator.enabled_item_count.should eq(3)
      navigator.current_index.should eq(0)
    end

    it "sets enabled items from array" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)

      navigator.enabled_item_count.should eq(3)
      navigator.item_enabled?(0).should be_true
      navigator.item_enabled?(1).should be_false
      navigator.item_enabled?(2).should be_true
    end

    it "sets individual item enabled state" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.set_item_enabled(2, false)

      navigator.item_enabled?(2).should be_false
      navigator.enabled_item_count.should eq(4)
    end

    it "moves away from disabled current item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(2)
      navigator.current_index.should eq(2)

      navigator.set_item_enabled(2, false)

      # Should move to next enabled item
      navigator.current_index.should_not eq(2)
      navigator.has_valid_selection?.should be_true
    end

    it "validates index bounds" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.item_enabled?(10).should be_false
      navigator.item_enabled?(-1).should be_false
      navigator.item_enabled?(0).should be_true
    end
  end

  describe "navigation operations" do
    it "navigates to next item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(0)

      success = navigator.navigate_next
      success.should be_true
      navigator.current_index.should eq(1)
      navigator.get_previous_index.should eq(0)
    end

    it "navigates to previous item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(2)

      success = navigator.navigate_previous
      success.should be_true
      navigator.current_index.should eq(1)
      navigator.get_previous_index.should eq(2)
    end

    it "wraps around when navigating next from last item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(4)

      success = navigator.navigate_next
      success.should be_true
      navigator.current_index.should eq(0)
    end

    it "wraps around when navigating previous from first item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(0)

      success = navigator.navigate_previous
      success.should be_true
      navigator.current_index.should eq(4)
    end

    it "navigates to specific index" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)

      success = navigator.navigate_to(3)
      success.should be_true
      navigator.current_index.should eq(3)
    end

    it "fails to navigate to invalid index" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)

      success = navigator.navigate_to(10)
      success.should be_false
      navigator.current_index.should eq(0) # Should remain unchanged
    end

    it "navigates to first enabled item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(3)

      success = navigator.navigate_to_first
      success.should be_true
      navigator.current_index.should eq(0)
    end

    it "navigates to last enabled item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)

      success = navigator.navigate_to_last
      success.should be_true
      navigator.current_index.should eq(4)
    end
  end

  describe "disabled item navigation" do
    it "skips disabled items when navigating next" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      # Enable items 0, 2, 4 (disable 1, 3)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)
      navigator.navigate_to(0)

      navigator.navigate_next
      # Should skip index 1 (disabled) and go to 2
      navigator.current_index.should eq(2)
    end

    it "skips disabled items when navigating previous" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)
      navigator.navigate_to(2)

      navigator.navigate_previous
      # Should skip index 1 (disabled) and go to 0
      navigator.current_index.should eq(0)
    end

    it "wraps around skipping disabled items" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)
      navigator.navigate_to(4) # Last enabled

      navigator.navigate_next
      # Should wrap to first enabled (0), skipping disabled item 1
      navigator.current_index.should eq(0)
    end

    it "finds first enabled item correctly" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)

      navigator.navigate_to_first
      navigator.current_index.should eq(0)
    end

    it "finds last enabled item correctly" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)

      navigator.navigate_to_last
      navigator.current_index.should eq(4)
    end

    it "fails to navigate to disabled item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)

      success = navigator.navigate_to(1)
      success.should be_false
      navigator.current_index.should_not eq(1)
    end

    it "gets correct enabled indices" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)

      enabled_indices = navigator.get_enabled_indices
      enabled_indices.should eq([0, 2, 4])
    end
  end

  describe "wrap navigation disabled" do
    it "stops at boundaries when wrap disabled" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.wrap_navigation = false
      navigator.navigate_to(4)

      success = navigator.navigate_next
      success.should be_false
      navigator.current_index.should eq(4)
    end

    it "stops at beginning when wrap disabled" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.wrap_navigation = false
      navigator.navigate_to(0)

      success = navigator.navigate_previous
      success.should be_false
      navigator.current_index.should eq(0)
    end
  end

  describe "empty and edge cases" do
    it "handles zero items" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.set_total_items(0)

      navigator.has_enabled_items?.should be_false
      navigator.has_valid_selection?.should be_false
      navigator.navigate_next.should be_false
      navigator.navigate_previous.should be_false
    end

    it "handles all items disabled" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [false, false, false, false, false]
      navigator.set_enabled_items(enabled_items)

      navigator.has_enabled_items?.should be_false
      navigator.enabled_item_count.should eq(0)
    end

    it "allows empty selection when configured" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.allow_empty_selection = true
      enabled_items = [false, false, false, false, false]
      navigator.set_enabled_items(enabled_items)

      navigator.current_index.should eq(-1)
    end

    it "handles single enabled item" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      enabled_items = [false, false, true, false, false]
      navigator.set_enabled_items(enabled_items)

      navigator.current_index.should eq(2)
      navigator.navigate_next.should be_false # No other enabled items
      navigator.navigate_previous.should be_false
    end
  end

  describe "callbacks" do
    it "calls selection changed callback" do
      old_index = -1
      new_index = -1

      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.on_selection_changed = ->(old : Int32, new : Int32) {
        old_index = old
        new_index = new
      }

      navigator.navigate_next

      old_index.should eq(0)
      new_index.should eq(1)
    end

    it "calls wrap around callback" do
      wrapped_index = -1

      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.on_wrap_around = ->(index : Int32) {
        wrapped_index = index
      }

      navigator.navigate_to(4)
      navigator.navigate_next # Should wrap to 0

      wrapped_index.should eq(0)
    end

    it "calls invalid navigation callback" do
      invalid_called = false

      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.on_invalid_navigation = -> {
        invalid_called = true
      }

      navigator.wrap_navigation = false
      navigator.navigate_to(4)
      navigator.navigate_next # Should fail

      invalid_called.should be_true
    end
  end

  describe "state management" do
    it "resets navigation state" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(3)
      navigator.reset

      navigator.current_index.should eq(0)
      navigator.get_previous_index.should eq(-1)
    end

    it "creates and restores snapshots" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(2)
      navigator.set_item_enabled(1, false)

      snapshot = navigator.create_snapshot

      navigator.navigate_to(4)
      navigator.set_item_enabled(1, true)

      navigator.restore_from_snapshot(snapshot)

      navigator.current_index.should eq(2)
      navigator.item_enabled?(1).should be_false
    end

    it "provides navigation statistics" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      stats = navigator.get_navigation_stats

      stats["current_index"].should eq(0)
      stats["total_items"].should eq(5)
      stats["enabled_items"].should eq(5)
    end
  end

  describe "configuration validation" do
    it "validates correct configuration" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      issues = navigator.validate_configuration
      issues.should be_empty
    end

    it "detects negative total items" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.set_total_items(-1)
      issues = navigator.validate_configuration

      issues.should_not be_empty
      issues.any? { |issue| issue.includes?("negative") }.should be_true
    end

    it "detects no enabled items when empty selection not allowed" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.allow_empty_selection = false
      enabled_items = [false, false, false, false, false]
      navigator.set_enabled_items(enabled_items)

      issues = navigator.validate_configuration
      issues.any? { |issue| issue.includes?("No enabled items") }.should be_true
    end
  end

  describe "complex navigation scenarios" do
    it "handles complex disabled pattern" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      # Pattern: enabled, disabled, enabled, disabled, enabled
      enabled_items = [true, false, true, false, true]
      navigator.set_enabled_items(enabled_items)

      navigator.navigate_to(0)
      navigator.navigate_next
      navigator.current_index.should eq(2) # Skip index 1

      navigator.navigate_next
      navigator.current_index.should eq(4) # Skip index 3

      navigator.navigate_next
      navigator.current_index.should eq(0) # Wrap around, skip index 1
    end

    it "maintains navigation integrity with dynamic changes" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      navigator.navigate_to(2)

      # Disable current item
      navigator.set_item_enabled(2, false)
      navigator.current_index.should_not eq(2)
      navigator.has_valid_selection?.should be_true

      # Re-enable it
      navigator.set_item_enabled(2, true)

      # Should still have valid selection
      navigator.has_valid_selection?.should be_true
    end

    it "handles rapid navigation changes" do
      navigator = PointClickEngine::UI::MenuNavigator.new(5)
      10.times do
        navigator.navigate_next
      end

      # Should end up at index 0 (wrapped around twice)
      navigator.current_index.should eq(0)
      navigator.has_valid_selection?.should be_true
    end
  end
end
