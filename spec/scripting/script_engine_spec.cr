require "../spec_helper"

module PointClickEngine
  describe Scripting::ScriptEngine do
    describe "#initialize" do
      it "creates a Lua state" do
        engine = Scripting::ScriptEngine.new
        engine.lua.should_not be_nil
      end
    end

    describe "#execute_script" do
      it "executes Lua code successfully" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return 2 + 2")
        result.should be_true
      end

      it "handles script errors gracefully" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("invalid lua code [][")
        result.should be_false
      end
    end

    describe "#set_global and #get_global" do
      it "can set and get Lua values" do
        engine = Scripting::ScriptEngine.new

        engine.set_global("test_number", 42.0)
        engine.get_global("test_number").should eq(42.0)

        engine.set_global("test_string", "hello")
        engine.get_global("test_string").should eq("hello")

        engine.set_global("test_bool", true)
        engine.get_global("test_bool").should eq(true)
      end
    end

    describe "game state management" do
      it "stores and retrieves game state" do
        engine = Scripting::ScriptEngine.new

        # Set state through Lua
        engine.execute_script(<<-LUA)
          set_game_state("player_level", "5")
          set_game_state("has_sword", "true")
        LUA

        # Verify state is stored
        engine.game_state.size.should eq(2)
        engine.game_state["player_level"].should_not be_nil
        engine.game_state["has_sword"].should_not be_nil
      end
    end
  end
end
