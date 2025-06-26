require "../spec_helper"
require "luajit"

module PointClickEngine::Scripting
  describe LuaEnvironment do
    describe "#initialize" do
      it "creates environment with lua state" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.should_not be_nil
      end
    end

    describe "#setup" do
      it "sets up utility functions" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        # Check log function exists
        lua.get_global("log")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        # Check table_contains exists
        lua.get_global("table_contains")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        # Check math helpers exist
        lua.get_global("lerp")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        lua.get_global("clamp")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        lua.get_global("distance")
        lua.is_function?(-1).should be_true
        lua.pop(1)
      end

      it "sets up event system" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        # Check event functions exist
        lua.get_global("register_event_handler")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        lua.get_global("trigger_event")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        # Test event system
        lua.execute! <<-LUA
          local test_value = 0
          register_event_handler("test_event", function(data)
            test_value = data.value
          end)
          trigger_event("test_event", {value = 42})
          return test_value
        LUA

        lua.to_i32(-1).should eq(42)
        lua.pop(1)
      end

      it "sets up timer system" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        # Check timer functions exist
        lua.get_global("create_timer")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        lua.get_global("cancel_timer")
        lua.is_function?(-1).should be_true
        lua.pop(1)

        # Test timer creation
        lua.execute!("return create_timer(1.0, function() end, false)")
        lua.to_i32(-1).should eq(1) # First timer ID
        lua.pop(1)
      end

      it "sets up string helpers" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        # Test split_string
        lua.execute!(<<-LUA)
          result = split_string("a,b,c", ",")
          return #result
        LUA
        lua.to_i32(-1).should eq(3)
        lua.pop(1)

        # Test trim
        lua.execute!(<<-LUA)
          return trim("  hello  ")
        LUA
        lua.to_string(-1).should eq("hello")
        lua.pop(1)
      end

      it "sets up table helpers" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        # Test deep_copy
        lua.execute! <<-LUA
          local orig = {a = 1, b = {c = 2}}
          local copy = deep_copy(orig)
          copy.b.c = 3
          return orig.b.c
        LUA
        lua.to_i32(-1).should eq(2) # Original unchanged
        lua.pop(1)

        # Test table_merge
        lua.execute! <<-LUA
          local t1 = {a = 1}
          local t2 = {b = 2}
          table_merge(t1, t2)
          return t1.b
        LUA
        lua.to_i32(-1).should eq(2)
        lua.pop(1)
      end
    end

    describe "#execute" do
      it "executes valid Lua code" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        result = env.execute("test_var = 42")
        result.should be_true

        lua.get_global("test_var")
        lua.to_i32(-1).should eq(42)
        lua.pop(1)
      end

      it "returns false for invalid Lua code" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        result = env.execute("invalid syntax {{")
        result.should be_false
      end
    end

    describe "#call_function" do
      it "calls Lua function with arguments" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        lua.execute!("function add(a, b) return a + b end")

        result = env.call_function("add", 5, 3)
        result.should eq(8)
      end

      it "returns nil for non-existent function" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        result = env.call_function("nonexistent")
        result.should be_nil
      end

      it "handles function errors gracefully" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        lua.execute!("function error_func() error('test error') end")

        result = env.call_function("error_func")
        result.should be_nil
      end
    end

    describe "#set_global and #get_global" do
      it "sets and gets global variables" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        env.set_global("my_number", 42)
        env.set_global("my_string", "hello")
        env.set_global("my_bool", true)

        env.get_global("my_number").should eq(42)
        env.get_global("my_string").should eq("hello")
        env.get_global("my_bool").should eq(true)
      end

      it "returns nil for non-existent global" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        env.get_global("nonexistent").should be_nil
      end
    end

    describe "#has_global?" do
      it "checks if global exists" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        env.set_global("exists", 123)

        env.has_global?("exists").should be_true
        env.has_global?("does_not_exist").should be_false
      end
    end

    describe "#execute_file" do
      it "executes Lua file content" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        # Create temp file
        temp_file = File.tempfile("test_script", ".lua") do |file|
          file.print("file_var = 999")
        end

        result = env.execute_file(temp_file.path)
        result.should be_true

        env.get_global("file_var").should eq(999)

        File.delete(temp_file.path)
      end

      it "returns false for non-existent file" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)

        result = env.execute_file("/nonexistent/file.lua")
        result.should be_false
      end
    end

    describe "utility functions" do
      it "lerp function works correctly" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        lua.execute!("return lerp(0, 100, 0.5)")
        lua.to_f32(-1).should eq(50.0f32)
        lua.pop(1)
      end

      it "clamp function works correctly" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        lua.execute!("return clamp(150, 0, 100)")
        lua.to_i32(-1).should eq(100)
        lua.pop(1)

        lua.execute!("return clamp(-50, 0, 100)")
        lua.to_i32(-1).should eq(0)
        lua.pop(1)

        lua.execute!("return clamp(50, 0, 100)")
        lua.to_i32(-1).should eq(50)
        lua.pop(1)
      end

      it "distance function works correctly" do
        lua = Luajit.new_with_defaults
        env = LuaEnvironment.new(lua)
        env.setup

        lua.execute!("return distance(0, 0, 3, 4)")
        lua.to_f32(-1).should eq(5.0f32)
        lua.pop(1)
      end
    end
  end
end
