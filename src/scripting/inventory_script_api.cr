# Inventory-related Lua API component
#
# Provides inventory management functions to Lua scripts:
# - Adding/removing items
# - Checking for items
# - Item selection
# - Getting all items

require "luajit"
require "../core/engine"
require "../inventory/inventory_item"

module PointClickEngine
  module Scripting
    # Provides inventory management functions to Lua scripts
    class InventoryScriptAPI
      @lua : Luajit::LuaState
      @registry : ScriptAPIRegistry

      def initialize(@lua : Luajit::LuaState, @registry : ScriptAPIRegistry)
      end

      # Register all inventory-related API functions
      def register
        @registry.create_module("inventory")

        @lua.execute! <<-LUA
          function inventory.add_item(item_name, description)
            _engine_inventory_add_item(item_name, description)
          end

          function inventory.remove_item(item_name)
            _engine_inventory_remove_item(item_name)
          end

          function inventory.has_item(item_name)
            return _engine_inventory_has_item(item_name)
          end

          function inventory.get_selected()
            return _engine_inventory_get_selected()
          end

          function inventory.select_item(item_name)
            _engine_inventory_select_item(item_name)
          end

          function inventory.clear_selection()
            _engine_inventory_clear_selection()
          end

          function inventory.get_all_items()
            return _engine_inventory_get_all_items()
          end

          -- Global convenience functions for common inventory operations
          function has_item(item_name)
            return inventory.has_item(item_name)
          end

          function add_item(item_name, description)
            inventory.add_item(item_name, description or "")
          end

          function remove_item(item_name)
            inventory.remove_item(item_name)
          end

          -- Aliases used by some scripts
          function add_to_inventory(item_name, description)
            add_item(item_name, description)
          end

          function remove_from_inventory(item_name)
            remove_item(item_name)
          end
        LUA

        register_callbacks
      end

      private def register_callbacks
        @registry.register_void_function("_engine_inventory_add_item") do |state|
          if state.size >= 2
            name = state.to_string(1)
            desc = state.to_string(2)

            item = Inventory::InventoryItem.new(name, desc)
            Core::Engine.instance.inventory.add_item(item)
          end
        end

        @registry.register_void_function("_engine_inventory_remove_item") do |state|
          if state.size >= 1
            name = state.to_string(1)
            Core::Engine.instance.inventory.remove_item(name)
          end
        end

        @registry.register_value_function("_engine_inventory_has_item", 1) do |state|
          if state.size >= 1
            name = state.to_string(1)
            has_item = Core::Engine.instance.inventory.has_item?(name)
            state.push(has_item)
          else
            state.push(false)
          end
        end

        @registry.register_value_function("_engine_inventory_get_selected", 1) do |state|
          selected_name = Core::Engine.instance.inventory.selected_item.try(&.name) || ""
          state.push(selected_name)
        end

        @registry.register_void_function("_engine_inventory_select_item") do |state|
          if state.size >= 1
            name = state.to_string(1)
            Core::Engine.instance.inventory.select_item(name)
          end
        end

        @registry.register_void_function("_engine_inventory_clear_selection") do |state|
          Core::Engine.instance.inventory.deselect_item
        end

        @registry.register_value_function("_engine_inventory_get_all_items", 1) do |state|
          items = Core::Engine.instance.inventory.items

          state.new_table
          items.each_with_index do |item, i|
            state.push(i + 1) # Lua arrays are 1-indexed

            state.new_table
            state.push("name")
            state.push(item.name)
            state.set_table(-3)

            state.push("description")
            state.push(item.description)
            state.set_table(-3)

            state.set_table(-3)
          end
        end
      end
    end
  end
end
