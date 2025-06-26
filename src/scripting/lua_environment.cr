# Lua environment setup and utility functions component

require "luajit"

module PointClickEngine
  module Scripting
    # Sets up and manages the Lua scripting environment
    class LuaEnvironment
      @lua : Luajit::LuaState

      def initialize(@lua : Luajit::LuaState)
      end

      # Set up basic Lua environment with utility functions
      def setup
        @lua.execute! <<-LUA
          -- Utility functions for scripts
          function log(message)
            print("[Script] " .. tostring(message))
          end

          function table_contains(table, element)
            for _, value in pairs(table) do
              if value == element then
                return true
              end
            end
            return false
          end

          -- Game event system
          _event_handlers = {}
          
          function register_event_handler(event_type, handler)
            if not _event_handlers[event_type] then
              _event_handlers[event_type] = {}
            end
            table.insert(_event_handlers[event_type], handler)
          end

          function trigger_event(event_type, data)
            if _event_handlers[event_type] then
              for _, handler in ipairs(_event_handlers[event_type]) do
                handler(data)
              end
            end
          end

          -- Timer system
          _timers = {}
          _timer_id = 0

          function create_timer(delay, callback, repeating)
            _timer_id = _timer_id + 1
            local id = _timer_id
            _timers[id] = {
              delay = delay,
              callback = callback,
              repeating = repeating or false,
              elapsed = 0,
              active = true
            }
            return id
          end

          function cancel_timer(id)
            if _timers[id] then
              _timers[id].active = false
              _timers[id] = nil
            end
          end

          -- Coroutine helpers
          function wait(seconds)
            local start = os.clock()
            while os.clock() - start < seconds do
              coroutine.yield()
            end
          end

          -- Math helpers
          function lerp(a, b, t)
            return a + (b - a) * t
          end

          function clamp(value, min, max)
            if value < min then return min end
            if value > max then return max end
            return value
          end

          function distance(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return math.sqrt(dx * dx + dy * dy)
          end

          -- String helpers
          function split_string(str, delimiter)
            local result = {}
            local pattern = string.format("([^%s]+)", delimiter)
            for match in string.gmatch(str, pattern) do
              table.insert(result, match)
            end
            return result
          end

          function trim(str)
            return string.match(str, "^%s*(.-)%s*$")
          end

          -- Table helpers
          function deep_copy(orig)
            local orig_type = type(orig)
            local copy
            if orig_type == 'table' then
              copy = {}
              for orig_key, orig_value in next, orig, nil do
                copy[deep_copy(orig_key)] = deep_copy(orig_value)
              end
              setmetatable(copy, deep_copy(getmetatable(orig)))
            else
              copy = orig
            end
            return copy
          end

          function table_merge(t1, t2)
            for k, v in pairs(t2) do
              t1[k] = v
            end
            return t1
          end

          -- Debug helpers
          function dump_table(t, indent)
            indent = indent or 0
            local prefix = string.rep("  ", indent)
            
            if type(t) ~= "table" then
              print(prefix .. tostring(t))
              return
            end
            
            for k, v in pairs(t) do
              if type(v) == "table" then
                print(prefix .. k .. ":")
                dump_table(v, indent + 1)
              else
                print(prefix .. k .. ": " .. tostring(v))
              end
            end
          end
        LUA
      end

      # Execute a Lua script in the environment
      def execute(script : String) : Bool
        begin
          @lua.execute!(script)
          true
        rescue ex
          puts "Script error: #{ex.message}"
          false
        end
      end

      # Call a Lua function
      def call_function(name : String, *args) : Luajit::LuaAny?
        begin
          @lua.get_global(name)

          # Check if the function exists
          if @lua.is_nil?(-1)
            @lua.pop(1)
            return nil
          end

          args.each { |arg| @lua.push(arg) }

          # Use pcall and check for errors
          if @lua.pcall(args.size, 1, 0) != 0
            # Error occurred, get error message and return nil
            error_msg = @lua.to_string(-1)
            @lua.pop(1)
            puts "Lua function error: #{error_msg}"
            return nil
          end

          @lua.to_any?(-1).tap { @lua.pop(1) }
        rescue ex
          puts "Function call error: #{ex.message}"
          nil
        end
      end

      # Set a global variable
      def set_global(name : String, value)
        @lua.push(value)
        @lua.set_global(name)
      end

      # Get a global variable
      def get_global(name : String) : Luajit::LuaAny?
        @lua.get_global(name)
        @lua.to_any?(-1).tap { @lua.pop(1) }
      end

      # Check if a global exists
      def has_global?(name : String) : Bool
        @lua.get_global(name)
        exists = !@lua.is_nil?(-1)
        @lua.pop(1)
        exists
      end

      # Execute a file
      def execute_file(path : String) : Bool
        begin
          content = File.read(path)
          execute(content)
        rescue ex
          puts "Script file error: #{ex.message}"
          false
        end
      end
    end
  end
end
