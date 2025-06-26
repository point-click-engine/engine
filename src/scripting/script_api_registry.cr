# Script API registration component

require "luajit"

module PointClickEngine
  module Scripting
    # Manages registration of Crystal functions into Lua
    class ScriptAPIRegistry
      @lua : Luajit::LuaState
      @registered_functions : Array(String) = [] of String

      def initialize(@lua : Luajit::LuaState)
      end

      # Register a Crystal function to be callable from Lua
      def register_function(lua_name : String, &block : Luajit::LuaState -> Int32)
        @lua.register_fn_global(lua_name, &block)
        @registered_functions << lua_name
      end

      # Create a Lua table/module
      def create_module(module_name : String)
        @lua.execute!("#{module_name} = {}")
      end

      # Add a function to a module
      def add_module_function(module_name : String, function_name : String, lua_code : String)
        @lua.execute! <<-LUA
          #{module_name}.#{function_name} = #{lua_code}
        LUA
      end

      # Register a callback that returns values
      def register_value_function(lua_name : String, return_count : Int32, &block : Luajit::LuaState -> Nil)
        register_function(lua_name) do |state|
          block.call(state)
          return_count
        end
      end

      # Register a void callback (no return values)
      def register_void_function(lua_name : String, &block : Luajit::LuaState -> Nil)
        register_function(lua_name) do |state|
          block.call(state)
          0
        end
      end

      # Create a Lua wrapper function that calls a Crystal function
      def create_wrapper(lua_function : String, crystal_function : String, *args)
        arg_list = args.join(", ")
        @lua.execute! <<-LUA
          function #{lua_function}(#{arg_list})
            return #{crystal_function}(#{arg_list})
          end
        LUA
      end

      # Get list of all registered functions
      def registered_functions : Array(String)
        @registered_functions.dup
      end

      # Check if a function is registered
      def function_registered?(name : String) : Bool
        @registered_functions.includes?(name)
      end

      # Clear all registrations (note: doesn't unregister from Lua)
      def clear_registrations
        @registered_functions.clear
      end
    end
  end
end