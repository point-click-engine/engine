require "../spec_helper"
require "luajit"

describe PointClickEngine::Scripting::GameStateManager do
  describe "#set_state and #get_state" do
    pending "stores and retrieves values" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      # String value
      manager.set_state("player_name", "Alice")
      manager.get_state("player_name").should eq("Alice")

      # Numeric value
      manager.set_state("score", 100.0)
      manager.get_state("score").should eq(100.0)

      # Boolean value
      manager.set_state("has_key", true)
      manager.get_state("has_key").should eq(true)

      # Nil removes the key
      manager.set_state("temp", "value")
      manager.has_state?("temp").should be_true
      manager.set_state("temp", nil)
      manager.has_state?("temp").should be_false
    end
  end

  describe "#has_state?" do
    pending "checks if state exists" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.has_state?("nonexistent").should be_false

      manager.set_state("exists", "yes")
      manager.has_state?("exists").should be_true
    end
  end

  describe "#remove_state" do
    pending "removes state keys" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("to_remove", "value")
      manager.has_state?("to_remove").should be_true

      result = manager.remove_state("to_remove")
      result.should be_true
      manager.has_state?("to_remove").should be_false

      # Removing non-existent key returns false
      result = manager.remove_state("nonexistent")
      result.should be_false
    end
  end

  describe "#clear_state" do
    pending "removes all state" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("key1", "value1")
      manager.set_state("key2", "value2")
      manager.set_state("key3", "value3")

      manager.state_keys.size.should eq(3)

      manager.clear_state

      manager.state_keys.size.should eq(0)
      manager.has_state?("key1").should be_false
    end
  end

  describe "#state_keys" do
    pending "returns all state keys" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("apple", 1)
      manager.set_state("banana", 2)
      manager.set_state("cherry", 3)

      keys = manager.state_keys
      keys.size.should eq(3)
      keys.should contain("apple")
      keys.should contain("banana")
      keys.should contain("cherry")
    end
  end

  describe "#get_states_with_prefix" do
    pending "filters states by prefix" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("player_name", "Alice")
      manager.set_state("player_health", 100.0)
      manager.set_state("player_level", 5)
      manager.set_state("enemy_count", 3)
      manager.set_state("game_time", 120.0)

      player_states = manager.get_states_with_prefix("player_")
      player_states.size.should eq(3)
      player_states.keys.should contain("player_name")
      player_states.keys.should contain("player_health")
      player_states.keys.should contain("player_level")
      player_states.keys.should_not contain("enemy_count")
    end
  end

  describe "#increment_state" do
    pending "increments numeric values" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      # Initialize and increment
      result = manager.increment_state("score", 10.0)
      result.should eq(10.0)

      # Increment existing
      result = manager.increment_state("score", 5.0)
      result.should eq(15.0)

      # Default increment of 1
      manager.set_state("count", 5.0)
      result = manager.increment_state("count")
      result.should eq(6.0)

      # Works with integers
      manager.set_state("int_value", 10)
      result = manager.increment_state("int_value", 2.5)
      result.should eq(12.5)
    end

    pending "returns nil for non-numeric values" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("name", "Alice")
      result = manager.increment_state("name")
      result.should be_nil
      manager.get_state("name").should eq("Alice") # Unchanged
    end
  end

  describe "#toggle_state" do
    pending "toggles boolean values" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      # Initialize to true if doesn't exist
      result = manager.toggle_state("door_open")
      result.should be_true

      # Toggle existing
      result = manager.toggle_state("door_open")
      result.should be_false

      result = manager.toggle_state("door_open")
      result.should be_true
    end

    pending "converts non-boolean to true" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("weird", "string")
      result = manager.toggle_state("weird")
      result.should be_true
      manager.get_state("weird").should eq(true)
    end
  end

  describe "#on_state_change" do
    pending "notifies callbacks on state changes" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      changes = [] of {String, Luajit::LuaAny?}

      manager.on_state_change do |key, value|
        changes << {key, value}
      end

      manager.set_state("test", "value")
      manager.set_state("test", "new_value")
      manager.remove_state("test")

      changes.size.should eq(3)
      changes[0].should eq({"test", "value"})
      changes[1].should eq({"test", "new_value"})
      changes[2].should eq({"test", nil})
    end
  end

  describe "#to_hash and #from_hash" do
    pending "serializes and deserializes state" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("string", "value")
      manager.set_state("number", 42.0)
      manager.set_state("bool", true)

      # Export state
      hash = manager.to_hash
      hash.size.should eq(3)

      # Import into new manager
      new_manager = PointClickEngine::Scripting::GameStateManager.new
      new_manager.from_hash(hash)

      new_manager.get_state("string").should eq("value")
      new_manager.get_state("number").should eq(42.0)
      new_manager.get_state("bool").should eq(true)
    end
  end

  describe "#merge_state" do
    pending "merges another state hash" do
      manager = PointClickEngine::Scripting::GameStateManager.new

      manager.set_state("existing", "old")
      manager.set_state("keep", "this")

      new_state = {
        "existing" => "new",
        "added"    => "value",
      } of String => Luajit::LuaAny

      manager.merge_state(new_state)

      manager.get_state("existing").should eq("new") # Updated
      manager.get_state("keep").should eq("this")    # Unchanged
      manager.get_state("added").should eq("value")  # Added
    end
  end
end
