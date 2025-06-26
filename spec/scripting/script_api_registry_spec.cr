require "../spec_helper"
require "luajit"

module PointClickEngine::Scripting
  describe ScriptAPIRegistry do
    describe "#initialize" do
      it "creates registry with lua state" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.should_not be_nil
        registry.registered_functions.should be_empty
      end
    end

    describe "#register_function" do
      it "registers a Crystal function to Lua" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.register_function("test_func") do |state|
          state.push(42)
          1 # Return 1 value
        end

        registry.function_registered?("test_func").should be_true

        # Test calling from Lua
        lua.execute!("return test_func()")
        lua.to_i32(-1).should eq(42)
        lua.pop(1)
      end

      it "tracks registered function names" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.register_function("func1") { |state| 0 }
        registry.register_function("func2") { |state| 0 }

        registry.registered_functions.should eq(["func1", "func2"])
      end
    end

    describe "#create_module" do
      it "creates a Lua table module" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.create_module("mymodule")

        lua.execute!("return type(mymodule)")
        lua.to_string(-1).should eq("table")
        lua.pop(1)
      end
    end

    describe "#add_module_function" do
      it "adds a function to a module" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.create_module("math_utils")
        registry.add_module_function("math_utils", "double", "function(x) return x * 2 end")

        lua.execute!("return math_utils.double(21)")
        lua.to_i32(-1).should eq(42)
        lua.pop(1)
      end
    end

    describe "#register_value_function" do
      it "registers a function that returns values" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.register_value_function("get_position", 2) do |state|
          state.push(100)
          state.push(200)
        end

        lua.execute!("x, y = get_position()")
        lua.execute!("return x")
        lua.to_i32(-1).should eq(100)
        lua.pop(1)

        lua.execute!("return y")
        lua.to_i32(-1).should eq(200)
        lua.pop(1)
      end

      it "handles single return value" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.register_value_function("get_name", 1) do |state|
          state.push("test_name")
        end

        lua.execute!("return get_name()")
        lua.to_string(-1).should eq("test_name")
        lua.pop(1)
      end
    end

    describe "#register_void_function" do
      it "registers a function with no return value" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        called = false
        registry.register_void_function("do_something") do |state|
          called = true
        end

        lua.execute!("do_something()")
        called.should be_true

        # Void function should not push anything
        # lua.get_top.should eq(0) # Method not available in current luajit binding
      end

      it "can access parameters" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        received_value = 0
        registry.register_void_function("set_value") do |state|
          if state.size >= 1
            received_value = state.to_i32(1)
          end
        end

        lua.execute!("set_value(123)")
        received_value.should eq(123)
      end
    end

    describe "#create_wrapper" do
      it "creates a Lua wrapper function" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        # First register the Crystal function
        registry.register_function("_internal_add") do |state|
          a = state.to_i32(1)
          b = state.to_i32(2)
          state.push(a + b)
          1
        end

        # Create wrapper
        registry.create_wrapper("add", "_internal_add", "a", "b")

        lua.execute!("return add(5, 7)")
        lua.to_i32(-1).should eq(12)
        lua.pop(1)
      end

      it "handles functions with no arguments" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.register_function("_get_version") do |state|
          state.push("1.0.0")
          1
        end

        registry.create_wrapper("get_version", "_get_version")

        lua.execute!("return get_version()")
        lua.to_string(-1).should eq("1.0.0")
        lua.pop(1)
      end
    end

    describe "#function_registered?" do
      it "checks if function is registered" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.function_registered?("nonexistent").should be_false

        registry.register_function("exists") { |state| 0 }

        registry.function_registered?("exists").should be_true
        registry.function_registered?("nonexistent").should be_false
      end
    end

    describe "#clear_registrations" do
      it "clears the registration list" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        registry.register_function("func1") { |state| 0 }
        registry.register_function("func2") { |state| 0 }

        registry.registered_functions.size.should eq(2)

        registry.clear_registrations

        registry.registered_functions.should be_empty

        # Note: Functions are still callable in Lua
        lua.execute!("return func1()")
        # This should not crash
      end
    end

    describe "complex example" do
      it "works with multiple modules and functions" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)

        # Create player module
        registry.create_module("player")

        # Add direct Lua functions
        registry.add_module_function("player", "get_health", "function() return 100 end")

        # Add Crystal-backed functions
        registry.register_value_function("_player_get_position", 2) do |state|
          state.push(50.0)
          state.push(75.0)
        end

        registry.register_void_function("_player_set_name") do |state|
          # In real implementation, would set player name
        end

        # Add wrappers
        lua.execute! <<-LUA
          function player.get_position()
            return _player_get_position()
          end
          
          function player.set_name(name)
            _player_set_name(name)
          end
        LUA

        # Test the module
        lua.execute!("return player.get_health()")
        lua.to_i32(-1).should eq(100)
        lua.pop(1)

        lua.execute!("x, y = player.get_position()")
        lua.execute!("return x")
        lua.to_f32(-1).should eq(50.0f32)
        lua.pop(1)

        lua.execute!("return y")
        lua.to_f32(-1).should eq(75.0f32)
        lua.pop(1)
      end
    end
  end
end
