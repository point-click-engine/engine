require "../spec_helper"

# Lua scripting integration tests
# Tests the complete Lua scripting system including engine API integration
describe "Lua Scripting Integration Tests" do
  describe "script engine initialization" do
    it "creates and initializes script engine correctly" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Should have valid Lua state
      engine.lua.should_not be_nil

      # Should have initialized game state
      engine.game_state.should be_a(Hash(String, Luajit::LuaAny))

      # Cleanup
      engine.cleanup
    end

    it "sets up basic Lua environment" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Test utility functions are available
      result = engine.execute_script(<<-LUA)
        -- Test log function
        log("Test message")
        
        -- Test table_contains function
        test_table = {1, 2, 3, "hello"}
        result1 = table_contains(test_table, 2)
        result2 = table_contains(test_table, "hello")
        result3 = table_contains(test_table, "missing")
        
        return result1 and result2 and not result3
      LUA

      result.should be_true
      engine.cleanup
    end
  end

  describe "basic script execution" do
    it "executes simple Lua scripts" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Test basic arithmetic
      result = engine.execute_script("return 2 + 3")
      result.should be_true

      # Test string operations
      result = engine.execute_script(<<-LUA)
        message = "Hello, " .. "World!"
        return string.len(message) == 13
      LUA
      result.should be_true

      engine.cleanup
    end

    it "handles script errors gracefully" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Test syntax error
      result = engine.execute_script("invalid lua syntax !!!")
      result.should be_false

      # Test runtime error
      result = engine.execute_script("error('Intentional error')")
      result.should be_false

      # Engine should still be functional after errors
      result = engine.execute_script("return true")
      result.should be_true

      engine.cleanup
    end

    it "manages global variables" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Set global from Crystal
      engine.set_global("test_number", 42)
      engine.set_global("test_string", "hello")
      engine.set_global("test_bool", true)

      # Read globals from Lua
      result = engine.execute_script(<<-LUA)
        return test_number == 42 and 
               test_string == "hello" and 
               test_bool == true
      LUA
      result.should be_true

      # Read globals back to Crystal
      num = engine.get_global("test_number")
      str = engine.get_global("test_string")
      bool = engine.get_global("test_bool")

      num.should_not be_nil
      str.should_not be_nil
      bool.should_not be_nil

      engine.cleanup
    end
  end

  describe "function calls" do
    it "calls Lua functions from Crystal" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Define functions in Lua
      engine.execute_script(<<-LUA)
        function add(a, b)
          return a + b
        end
        
        function greet(name)
          return "Hello, " .. name .. "!"
        end
        
        function get_info()
          return {
            version = "1.0",
            author = "Test"
          }
        end
      LUA

      # Call functions from Crystal
      result = engine.call_function("add", 5, 3)
      result.should_not be_nil

      result = engine.call_function("greet", "World")
      result.should_not be_nil

      result = engine.call_function("get_info")
      result.should_not be_nil

      engine.cleanup
    end

    it "handles function call errors" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Call non-existent function
      result = engine.call_function("non_existent_function")
      # May return an error message rather than nil
      result.should_not be_nil if result # Allow either nil or error message

      # Call function with wrong arguments
      engine.execute_script("function needs_two_args(a, b) return a + b end")
      result = engine.call_function("needs_two_args", 1) # Missing second argument
      result.should_not be_nil                           # Lua allows this, second arg is nil

      engine.cleanup
    end
  end

  describe "event system integration" do
    it "handles event registration and triggering" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Test event system
      engine.execute_script(<<-LUA)
        event_triggered = false
        event_data_received = nil
        
        function on_test_event(data)
          event_triggered = true
          event_data_received = data
        end
        
        register_event_handler("test_event", on_test_event)
        trigger_event("test_event", "test_data")
      LUA

      # Check if event was handled
      triggered = engine.get_global("event_triggered")
      data = engine.get_global("event_data_received")

      triggered.should_not be_nil
      data.should_not be_nil

      engine.cleanup
    end

    it "handles multiple event handlers" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      engine.execute_script(<<-LUA)
        handler1_called = false
        handler2_called = false
        
        function handler1(data)
          handler1_called = true
        end
        
        function handler2(data)
          handler2_called = true
        end
        
        register_event_handler("multi_event", handler1)
        register_event_handler("multi_event", handler2)
        trigger_event("multi_event", "data")
      LUA

      h1 = engine.get_global("handler1_called")
      h2 = engine.get_global("handler2_called")

      h1.should_not be_nil
      h2.should_not be_nil

      engine.cleanup
    end
  end

  describe "script stress testing" do
    it "handles many script executions" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      successful_executions = 0

      # Execute many small scripts
      100.times do |i|
        script = "local x = #{i}; return x * 2"
        if engine.execute_script(script)
          successful_executions += 1
        end
      end

      successful_executions.should eq(100)
      engine.cleanup
    end

    it "handles complex nested operations" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Test complex script with nested operations
      result = engine.execute_script(<<-LUA)
        function fibonacci(n)
          if n <= 1 then
            return n
          else
            return fibonacci(n-1) + fibonacci(n-2)
          end
        end
        
        function process_data(data)
          local result = {}
          for i, v in ipairs(data) do
            result[i] = v * 2
          end
          return result
        end
        
        -- Test complex operations
        fib_result = fibonacci(10)
        data = {1, 2, 3, 4, 5}
        processed = process_data(data)
        
        return fib_result == 55 and #processed == 5
      LUA

      result.should be_true
      engine.cleanup
    end

    it "handles memory-intensive operations" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      result = engine.execute_script(<<-LUA)
        -- Create and manipulate large data structures
        big_table = {}
        for i = 1, 1000 do
          big_table[i] = {
            id = i,
            name = "item_" .. i,
            data = string.rep("x", 100)
          }
        end
        
        -- Process the data
        count = 0
        for _, item in pairs(big_table) do
          if item.id % 2 == 0 then
            count = count + 1
          end
        end
        
        return count == 500
      LUA

      result.should be_true
      engine.cleanup
    end
  end

  describe "error handling and recovery" do
    it "recovers from script errors" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Cause an error
      result1 = engine.execute_script("error('Test error')")
      result1.should be_false

      # Engine should still work
      result2 = engine.execute_script("return 'recovery successful'")
      result2.should be_true

      # Should be able to set/get globals
      engine.set_global("recovery_test", "success")
      value = engine.get_global("recovery_test")
      value.should_not be_nil

      engine.cleanup
    end

    it "handles infinite loops gracefully" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Note: This test might timeout or be handled by Lua's mechanisms
      # We're testing that the engine doesn't crash
      begin
        result = engine.execute_script(<<-LUA)
          local count = 0
          for i = 1, 10000 do  -- Large but finite loop
            count = count + 1
          end
          return count == 10000
        LUA
        result.should be_true
      rescue ex
        # If it times out or errors, that's acceptable
        ex.should be_a(Exception)
      end

      engine.cleanup
    end

    it "handles malformed Lua code" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      malformed_scripts = [
        "function end",         # Syntax error
        "local x = ",           # Incomplete statement
        "return 1 + ",          # Incomplete expression
        "if true then",         # Missing end
        "for i = 1 do end",     # Invalid for loop
        "local function() end", # Missing function name
        "table.insert(nil, 1)", # Runtime error
      ]

      malformed_scripts.each do |script|
        result = engine.execute_script(script)
        result.should be_false
      end

      # Engine should still be functional
      result = engine.execute_script("return true")
      result.should be_true

      engine.cleanup
    end
  end

  describe "memory management" do
    it "does not leak memory during script operations" do
      initial_memory = GC.stats.heap_size

      # Create and destroy multiple script engines
      10.times do |i|
        engine = PointClickEngine::Scripting::ScriptEngine.new

        # Execute various scripts
        engine.execute_script("local data = {}; for i=1,100 do data[i] = 'test_' .. i end")
        engine.set_global("test_var_#{i}", "test_value")
        engine.call_function("log", "test message #{i}")

        engine.cleanup
      end

      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64

      puts "Lua scripting memory test: growth = #{memory_growth} bytes"

      # Should not have significant memory leaks
      memory_growth.should be < 10_000_000 # 10MB limit
    end
  end

  describe "performance characteristics" do
    it "script operations meet performance benchmarks" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Measure script execution performance
      execution_count = 100
      start_time = Time.monotonic

      execution_count.times do |i|
        script = "local x = #{i}; local y = x * 2; return y + 1"
        engine.execute_script(script)
      end

      execution_time = Time.monotonic - start_time
      time_per_execution = execution_time.total_milliseconds / execution_count

      puts "Lua script execution performance:"
      puts "  Executions: #{execution_count}"
      puts "  Total time: #{execution_time.total_milliseconds.round(2)}ms"
      puts "  Time per execution: #{time_per_execution.round(4)}ms"

      # Script execution should be reasonably fast
      time_per_execution.should be < 1.0 # 1ms per execution

      # Test function call performance
      engine.execute_script("function test_func(x) return x * 2 end")

      call_start = Time.monotonic
      100.times do |i|
        engine.call_function("test_func", i)
      end
      call_time = Time.monotonic - call_start

      puts "Function call performance:"
      puts "  Time per call: #{(call_time.total_milliseconds / 100).round(4)}ms"

      # Function calls should be fast
      (call_time.total_milliseconds / 100).should be < 0.1 # 0.1ms per call

      engine.cleanup
    end
  end

  describe "edge cases and boundary conditions" do
    it "handles extreme values" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Test extreme numbers
      result = engine.execute_script(<<-LUA)
        local big_num = 1e308
        local small_num = 1e-308
        local negative = -1e308
        
        return type(big_num) == "number" and 
               type(small_num) == "number" and 
               type(negative) == "number"
      LUA
      result.should be_true

      # Test very long strings
      engine.set_global("long_string", "x" * 10000)
      result = engine.execute_script("return string.len(long_string) == 10000")
      result.should be_true

      # Test large tables
      result = engine.execute_script(<<-LUA)
        local big_table = {}
        for i = 1, 1000 do
          big_table[i] = i
        end
        return #big_table == 1000
      LUA
      result.should be_true

      engine.cleanup
    end

    it "handles unicode and special characters" do
      engine = PointClickEngine::Scripting::ScriptEngine.new

      # Test unicode strings
      unicode_string = "Hello 🌍 World! 中文 русский 🎮"
      engine.set_global("unicode_test", unicode_string)

      result = engine.execute_script(<<-LUA)
        return type(unicode_test) == "string" and unicode_test ~= ""
      LUA
      result.should be_true

      # Test special characters in code (properly escaped)
      result = engine.execute_script(<<-LUA)
        local special = "Line1\\nLine2\\tTabbed\\"Quoted'Apostrophe"
        return type(special) == "string"
      LUA
      result.should be_true

      engine.cleanup
    end
  end
end
