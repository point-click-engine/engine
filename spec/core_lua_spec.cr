require "spec"
require "luajit"

# Test the core Lua scripting functionality without engine dependencies
describe "Core Lua Scripting" do
  describe "Basic LuaJIT Integration" do
    it "initializes and cleans up properly" do
      lua = Luajit.new_with_defaults
      lua.should_not be_nil
      Luajit.close(lua)
    end

    it "executes simple Lua scripts" do
      lua = Luajit.new_with_defaults
      
      # Test basic Lua execution
      status = lua.execute("local x = 5 + 3")
      status.ok?.should be_true
      
      Luajit.close(lua)
    end

    it "handles Lua syntax errors gracefully" do
      lua = Luajit.new_with_defaults
      
      # Test invalid Lua syntax
      status = lua.execute("local x = 5 +")
      status.ok?.should be_false
      
      Luajit.close(lua)
    end

    it "can set and get global variables" do
      lua = Luajit.new_with_defaults
      
      # Set a global variable
      lua.push(42)
      lua.set_global("test_value")
      
      # Get the global variable back
      lua.get_global("test_value")
      value = lua.to_i32(-1)
      lua.pop(1)
      
      value.should eq(42)
      Luajit.close(lua)
    end

    it "can call Lua functions from Crystal" do
      lua = Luajit.new_with_defaults
      
      # Define a function in Lua
      lua.execute!(<<-LUA
        function add_numbers(a, b)
          return a + b
        end
      LUA
      )
      
      # Call the function from Crystal
      lua.get_global("add_numbers")
      lua.push(10)
      lua.push(20)
      lua.pcall(2, 1, 0)
      result = lua.to_i32(-1)
      lua.pop(1)
      
      result.should eq(30)
      Luajit.close(lua)
    end

    it "supports string operations" do
      lua = Luajit.new_with_defaults
      
      # Test string handling
      lua.execute!(<<-LUA
        greeting = "Hello, World!"
        function get_greeting()
          return greeting
        end
      LUA
      )
      
      lua.get_global("get_greeting")
      lua.pcall(0, 1, 0)
      result = lua.to_string(-1)
      lua.pop(1)
      
      result.should eq("Hello, World!")
      Luajit.close(lua)
    end

    it "supports table operations" do
      lua = Luajit.new_with_defaults
      
      # Test Lua table handling
      lua.execute!(<<-LUA
        function table_contains(table, element)
          for _, value in pairs(table) do
            if value == element then
              return true
            end
          end
          return false
        end
        
        fruits = {"apple", "banana", "orange"}
        result = table_contains(fruits, "banana")
      LUA
      )
      
      lua.get_global("result")
      result = lua.to_boolean(-1)
      lua.pop(1)
      
      result.should be_true
      Luajit.close(lua)
    end

    it "can register Crystal functions callable from Lua" do
      lua = Luajit.new_with_defaults
      
      # Register a Crystal function
      callback_called = false
      callback_value = 0
      
      lua.register_fn_global("crystal_function") do |state|
        callback_called = true
        if state.size >= 1
          callback_value = state.to_i32(1)
        end
        0
      end
      
      # Call it from Lua
      lua.execute!("crystal_function(123)")
      
      callback_called.should be_true
      callback_value.should eq(123)
      Luajit.close(lua)
    end

    it "handles complex data exchange" do
      lua = Luajit.new_with_defaults
      
      # Test bidirectional data flow
      received_data = ""
      
      lua.register_fn_global("receive_data") do |state|
        if state.size >= 1
          received_data = state.to_string(1)
        end
        0
      end
      
      lua.execute!(<<-LUA
        function process_data(input)
          local processed = "Processed: " .. input
          receive_data(processed)
          return processed
        end
      LUA
      )
      
      # Call Lua function that calls back to Crystal
      lua.get_global("process_data")
      lua.push("test input")
      lua.pcall(1, 1, 0)
      result = lua.to_string(-1)
      lua.pop(1)
      
      result.should eq("Processed: test input")
      received_data.should eq("Processed: test input")
      Luajit.close(lua)
    end

    it "loads and executes script files" do
      # Create a temporary script file
      script_content = <<-LUA
        function calculate_area(width, height)
          return width * height
        end
        
        function get_version()
          return "1.0.0"
        end
      LUA
      
      File.write("/tmp/test_lua_script.lua", script_content)
      
      lua = Luajit.new_with_defaults
      status = lua.execute(Path.new("/tmp/test_lua_script.lua"))
      status.ok?.should be_true
      
      # Test that functions were loaded
      lua.get_global("calculate_area")
      lua.push(10)
      lua.push(20)
      lua.pcall(2, 1, 0)
      area = lua.to_i32(-1)
      lua.pop(1)
      
      area.should eq(200)
      
      lua.get_global("get_version")
      lua.pcall(0, 1, 0)
      version = lua.to_string(-1)
      lua.pop(1)
      
      version.should eq("1.0.0")
      
      Luajit.close(lua)
      File.delete("/tmp/test_lua_script.lua")
    end

    it "handles errors in script files gracefully" do
      lua = Luajit.new_with_defaults
      status = lua.execute(Path.new("/nonexistent/script.lua"))
      status.ok?.should be_false
      Luajit.close(lua)
    end
  end
end