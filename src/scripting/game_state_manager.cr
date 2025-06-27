# Game state management for scripts component

require "luajit"

module PointClickEngine
  module Scripting
    # Manages game state accessible from Lua scripts
    class GameStateManager
      @game_state : Hash(String, Luajit::LuaAny) = {} of String => Luajit::LuaAny
      @state_change_callbacks : Array(Proc(String, Luajit::LuaAny?, Nil)) = [] of Proc(String, Luajit::LuaAny?, Nil)

      # Set a game state value
      def set_state(key : String, value : Luajit::LuaAny?)
        old_value = @game_state[key]?

        if value
          @game_state[key] = value
        else
          @game_state.delete(key)
        end

        # Notify callbacks
        @state_change_callbacks.each do |callback|
          callback.call(key, value)
        end
      end

      # Get a game state value
      def get_state(key : String) : Luajit::LuaAny?
        @game_state[key]?
      end

      # Check if a state key exists
      def has_state?(key : String) : Bool
        @game_state.has_key?(key)
      end

      # Remove a state key
      def remove_state(key : String) : Bool
        if @game_state.has_key?(key)
          @game_state.delete(key)

          # Notify callbacks with nil value
          @state_change_callbacks.each do |callback|
            callback.call(key, nil)
          end

          true
        else
          false
        end
      end

      # Clear all state
      def clear_state
        @game_state.clear
      end

      # Get all state keys
      def state_keys : Array(String)
        @game_state.keys
      end

      # Get state as hash for serialization
      def to_hash : Hash(String, Luajit::LuaAny)
        @game_state.dup
      end

      # Load state from hash
      def from_hash(state : Hash(String, Luajit::LuaAny))
        @game_state = state.dup
      end

      # Register a callback for state changes
      def on_state_change(&block : String, Luajit::LuaAny? -> Nil)
        @state_change_callbacks << block
      end

      # Get state filtered by prefix
      def get_states_with_prefix(prefix : String) : Hash(String, Luajit::LuaAny)
        result = {} of String => Luajit::LuaAny

        @game_state.each do |key, value|
          if key.starts_with?(prefix)
            result[key] = value
          end
        end

        result
      end

      # Increment a numeric state value
      def increment_state(key : String, amount : Float64 = 1.0) : Float64?
        if value = @game_state[key]?
          case value
          when Float64
            new_value = value.as(Float64) + amount
            set_state(key, new_value)
            new_value
          when Int32
            new_value = value.as(Int32).to_f64 + amount
            set_state(key, new_value)
            new_value
          when Int64
            new_value = value.as(Int64).to_f64 + amount
            set_state(key, new_value)
            new_value
          else
            nil
          end
        else
          # Initialize to amount if doesn't exist
          set_state(key, amount)
          amount
        end
      end

      # Toggle a boolean state value
      def toggle_state(key : String) : Bool
        if value = @game_state[key]?
          case value
          when Bool
            new_value = !value.as(Bool)
            set_state(key, new_value)
            new_value
          else
            # Default to true if not a boolean
            set_state(key, true)
            true
          end
        else
          # Default to true if doesn't exist
          set_state(key, true)
          true
        end
      end

      # Merge another state hash into this one
      def merge_state(other_state : Hash(String, Luajit::LuaAny))
        other_state.each do |key, value|
          set_state(key, value)
        end
      end
    end
  end
end
