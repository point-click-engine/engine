# Lua scripting engine for runtime game scripting - Refactored with components
#
# Uses EventBus pattern: Crystal publishes events, ScriptEngine subscribes and
# dispatches to Lua handlers registered via the Lua API.

require "luajit"
require "./lua_environment"
require "./script_api_registry"
require "./scene_script_api"
require "./character_script_api"
require "./inventory_script_api"
require "./dialog_script_api"
require "./utility_script_api"
require "./camera_script_api"
require "./audio_script_api"
require "./hotspot_script_api"
require "./lua_state_manager"
require "../core/events/event_bus"
require "../core/events/game_events"

module PointClickEngine
  module Scripting
    # Main script engine using component-based architecture
    #
    # This refactored ScriptEngine delegates responsibilities to specialized components:
    # - LuaEnvironment: Lua setup and utility functions
    # - ScriptAPIRegistry: Crystal function registration
    # - SceneScriptAPI: Scene-related Lua API
    # - CharacterScriptAPI: Character-related Lua API
    # - InventoryScriptAPI: Inventory management Lua API
    # - DialogScriptAPI: Dialog system Lua API
    # - UtilityScriptAPI: Game state, timers, cutscenes, quests Lua API
    # - CameraScriptAPI: Camera control Lua API
    # - AudioScriptAPI: Audio control Lua API
    # - HotspotScriptAPI: Hotspot interaction Lua API
    # - LuaStateManager: Script-accessible Lua state
    #
    # EventBus Integration:
    # Scripts register Lua handlers (e.g., scene.on_enter, hotspot.on_click)
    # ScriptEngine subscribes to EventBus events and calls the Lua handlers
    class ScriptEngine
      getter lua : Luajit::LuaState

      # Component managers
      @environment : LuaEnvironment
      @registry : ScriptAPIRegistry
      @scene_api : SceneScriptAPI
      @character_api : CharacterScriptAPI
      @inventory_api : InventoryScriptAPI
      @dialog_api : DialogScriptAPI
      @utility_api : UtilityScriptAPI
      @camera_api : CameraScriptAPI
      @audio_api : AudioScriptAPI
      @hotspot_api : HotspotScriptAPI
      @state_manager : LuaStateManager

      # EventBus subscription IDs for cleanup
      @subscription_ids : Array(UInt64) = [] of UInt64

      # Legacy property for compatibility
      def game_state : Hash(String, Luajit::LuaAny)
        @state_manager.to_hash
      end

      def initialize
        @lua = Luajit.new_with_defaults

        # Initialize components
        @environment = LuaEnvironment.new(@lua)
        @registry = ScriptAPIRegistry.new(@lua)
        @state_manager = LuaStateManager.new

        # Initialize API components
        @scene_api = SceneScriptAPI.new(@lua, @registry)
        @character_api = CharacterScriptAPI.new(@lua, @registry)
        @inventory_api = InventoryScriptAPI.new(@lua, @registry)
        @dialog_api = DialogScriptAPI.new(@lua, @registry)
        @utility_api = UtilityScriptAPI.new(@lua, @registry, @state_manager)
        @camera_api = CameraScriptAPI.new(@lua, @registry)
        @audio_api = AudioScriptAPI.new(@lua, @registry)
        @hotspot_api = HotspotScriptAPI.new(@lua, @registry)

        # Setup environment and register APIs
        setup_engine
      end

      # Subscribe to EventBus events - call this after engine is initialized
      def subscribe_to_events(event_bus : Core::Events::EventBus)
        # Scene events
        @subscription_ids << event_bus.subscribe(Core::Events::SceneEnteredEvent) do |event|
          dispatch_scene_event("enter", event.scene_name, event.previous_scene)
        end

        @subscription_ids << event_bus.subscribe(Core::Events::SceneExitedEvent) do |event|
          dispatch_scene_event("exit", event.scene_name)
        end

        # Hotspot events
        @subscription_ids << event_bus.subscribe(Core::Events::HotspotClickedEvent) do |event|
          dispatch_hotspot_event(event.hotspot_name, event.verb)
        end

        # Character interaction events
        @subscription_ids << event_bus.subscribe(Core::Events::CharacterInteractEvent) do |event|
          dispatch_character_event("interact", event.character_name, event.target, event.verb)
        end

        # Item use events (for scene.on_item_use)
        @subscription_ids << event_bus.subscribe(Core::Events::ItemUsedEvent) do |event|
          if target = event.target
            dispatch_scene_event("item_use", event.item_id, target)
          end
        end

        # Timer events - execute Lua callback when timer fires
        @subscription_ids << event_bus.subscribe(Core::Events::TimerFiredEvent) do |event|
          dispatch_timer_event(event.timer_id, event.callback_code)
        end

        # Cutscene events
        @subscription_ids << event_bus.subscribe(Core::Events::CutsceneEndedEvent) do |event|
          dispatch_cutscene_event("ended", event.cutscene_id, event.skipped)
        end

        puts "[ScriptEngine] Subscribed to EventBus events"
      end

      # Unsubscribe from all events
      def unsubscribe_from_events(event_bus : Core::Events::EventBus)
        @subscription_ids.each { |id| event_bus.unsubscribe(id) }
        @subscription_ids.clear
      end

      # Execute a script string
      def execute_script(script_content : String) : Bool
        @environment.execute(script_content)
      end

      # Execute a script file
      def execute_script_file(file_path : String) : Bool
        begin
          content = AssetLoader.read_script(file_path)
          execute_script(content)
        rescue ex
          puts "Script file error: #{ex.message}"
          false
        end
      end

      # Call a Lua function
      def call_function(function_name : String, *args) : Luajit::LuaAny?
        @environment.call_function(function_name, *args)
      end

      # Set a global variable
      def set_global(name : String, value)
        @environment.set_global(name, value)
      end

      # Get a global variable
      def get_global(name : String) : Luajit::LuaAny?
        @environment.get_global(name)
      end

      # Clean up Lua state
      def cleanup
        Luajit.close(@lua)
      end

      private def setup_engine
        # Setup Lua environment
        @environment.setup

        # Register all API modules
        @scene_api.register
        @character_api.register
        @inventory_api.register
        @dialog_api.register
        @utility_api.register
        @camera_api.register
        @audio_api.register
        @hotspot_api.register
      end

      # ================================
      # EventBus Dispatch Methods
      # These call Lua handlers when events arrive from EventBus
      # ================================

      # Dispatch scene events to Lua handlers
      # event_type: "enter", "exit", "item_use"
      private def dispatch_scene_event(event_type : String, scene_name : String, extra : String? = nil)
        puts "[ScriptEngine] Dispatching scene event: #{event_type} (scene: #{scene_name})"

        # Call scene._handle_event(event_type, scene_name, extra)
        lua_code = if extra
                     "return scene._handle_event('#{event_type}', '#{scene_name}', '#{extra}')"
                   else
                     "return scene._handle_event('#{event_type}', '#{scene_name}')"
                   end

        begin
          @lua.execute!(lua_code)
        rescue ex
          puts "[ScriptEngine] Scene event dispatch error: #{ex.message}"
        end
      end

      # Dispatch hotspot events to Lua handlers
      private def dispatch_hotspot_event(hotspot_name : String, verb : String)
        puts "[ScriptEngine] Dispatching hotspot event: #{hotspot_name} (verb: #{verb})"

        # Call hotspot._handle_event(hotspot_name, verb)
        lua_code = "return hotspot._handle_event('#{hotspot_name}', '#{verb}')"

        begin
          @lua.execute!(lua_code)
        rescue ex
          puts "[ScriptEngine] Hotspot event dispatch error: #{ex.message}"
        end
      end

      # Dispatch character events to Lua handlers
      # event_type: "interact"
      private def dispatch_character_event(event_type : String, character_name : String, target : String, verb : String)
        puts "[ScriptEngine] Dispatching character event: #{event_type} (character: #{character_name}, target: #{target})"

        # Call character._handle_event(event_type, character_name, target, verb)
        lua_code = "return character._handle_event('#{event_type}', '#{character_name}', '#{target}', '#{verb}')"

        begin
          @lua.execute!(lua_code)
        rescue ex
          puts "[ScriptEngine] Character event dispatch error: #{ex.message}"
        end
      end

      # Dispatch timer events to execute Lua callback code
      private def dispatch_timer_event(timer_id : String, callback_code : String?)
        puts "[ScriptEngine] Timer fired: #{timer_id}"

        if code = callback_code
          begin
            @lua.execute!(code)
          rescue ex
            puts "[ScriptEngine] Timer callback error: #{ex.message}"
          end
        end

        # Also call any registered Lua handler
        lua_code = "if _timer_callbacks and _timer_callbacks['#{timer_id}'] then _timer_callbacks['#{timer_id}']() end"
        begin
          @lua.execute!(lua_code)
        rescue ex
          # Ignore if no handler registered
        end
      end

      # Dispatch cutscene events to Lua handlers
      private def dispatch_cutscene_event(event_type : String, cutscene_id : String, skipped : Bool)
        puts "[ScriptEngine] Cutscene event: #{event_type} (id: #{cutscene_id}, skipped: #{skipped})"

        lua_code = "if _cutscene_callbacks and _cutscene_callbacks['#{cutscene_id}'] then _cutscene_callbacks['#{cutscene_id}']('#{event_type}', #{skipped}) end"
        begin
          @lua.execute!(lua_code)
        rescue ex
          # Ignore if no handler registered
        end
      end
    end
  end
end
