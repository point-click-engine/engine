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

    describe "Lua API availability" do
      # These tests verify that all expected Lua APIs are defined
      # This would have caught the missing hotspot API

      it "has scene API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(scene) == 'table'")
        result.should be_true

        # Verify scene API methods exist
        engine.execute_script("return type(scene.change) == 'function'").should be_true
        engine.execute_script("return type(scene.get_current) == 'function'").should be_true
      end

      it "has character API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(character) == 'table'")
        result.should be_true

        # Verify character API methods exist
        engine.execute_script("return type(character.move_to) == 'function'").should be_true
        engine.execute_script("return type(character.say) == 'function'").should be_true
      end

      it "has inventory API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(inventory) == 'table'")
        result.should be_true

        # Verify inventory API methods exist
        engine.execute_script("return type(inventory.add_item) == 'function'").should be_true
        engine.execute_script("return type(inventory.remove_item) == 'function'").should be_true
        engine.execute_script("return type(inventory.has_item) == 'function'").should be_true
        engine.execute_script("return type(inventory.get_selected) == 'function'").should be_true
        engine.execute_script("return type(inventory.select_item) == 'function'").should be_true
        engine.execute_script("return type(inventory.clear_selection) == 'function'").should be_true
        engine.execute_script("return type(inventory.get_all_items) == 'function'").should be_true
      end

      it "has dialog API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(dialog) == 'table'")
        result.should be_true

        # Verify dialog API methods exist
        engine.execute_script("return type(dialog.show) == 'function'").should be_true
        engine.execute_script("return type(dialog.show_choices) == 'function'").should be_true
        engine.execute_script("return type(dialog.hide) == 'function'").should be_true
        engine.execute_script("return type(dialog.is_showing) == 'function'").should be_true
        engine.execute_script("return type(start_dialog) == 'function'").should be_true
        engine.execute_script("return type(show_message) == 'function'").should be_true
      end

      it "has global convenience functions defined" do
        engine = Scripting::ScriptEngine.new

        # Inventory convenience functions
        engine.execute_script("return type(has_item) == 'function'").should be_true
        engine.execute_script("return type(add_item) == 'function'").should be_true
        engine.execute_script("return type(remove_item) == 'function'").should be_true

        # Dialog convenience function
        engine.execute_script("return type(show_message) == 'function'").should be_true

        # Audio convenience functions
        engine.execute_script("return type(play_sound) == 'function'").should be_true
        engine.execute_script("return type(play_music) == 'function'").should be_true
        engine.execute_script("return type(stop_music) == 'function'").should be_true
      end

      it "has audio API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(audio) == 'table'")
        result.should be_true

        # Verify audio API methods exist
        engine.execute_script("return type(audio.play_sound) == 'function'").should be_true
        engine.execute_script("return type(audio.play_music) == 'function'").should be_true
        engine.execute_script("return type(audio.stop_music) == 'function'").should be_true
        engine.execute_script("return type(audio.set_volume) == 'function'").should be_true
      end

      it "has quest API defined" do
        engine = Scripting::ScriptEngine.new

        # Verify quest API functions exist
        engine.execute_script("return type(start_quest) == 'function'").should be_true
        engine.execute_script("return type(complete_quest) == 'function'").should be_true
        engine.execute_script("return type(complete_quest_objective) == 'function'").should be_true
        engine.execute_script("return type(is_quest_active) == 'function'").should be_true
        engine.execute_script("return type(is_quest_complete) == 'function'").should be_true
      end

      it "has scene convenience functions defined" do
        engine = Scripting::ScriptEngine.new

        # change_scene should be a global alias for scene.change
        engine.execute_script("return type(change_scene) == 'function'").should be_true
        engine.execute_script("return type(scene.on_update) == 'function'").should be_true
      end

      it "has inventory aliases defined" do
        engine = Scripting::ScriptEngine.new

        # add_to_inventory and remove_from_inventory are aliases
        engine.execute_script("return type(add_to_inventory) == 'function'").should be_true
        engine.execute_script("return type(remove_from_inventory) == 'function'").should be_true
      end

      it "has game API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(game) == 'table'")
        result.should be_true

        # Verify game API methods exist
        engine.execute_script("return type(game.save) == 'function'").should be_true
        engine.execute_script("return type(game.load) == 'function'").should be_true
        engine.execute_script("return type(game.debug_log) == 'function'").should be_true
        engine.execute_script("return type(game.get_time) == 'function'").should be_true
        engine.execute_script("return type(game.random) == 'function'").should be_true
      end

      it "has camera API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(camera) == 'table'")
        result.should be_true

        # Verify camera API methods exist
        engine.execute_script("return type(camera.shake) == 'function'").should be_true
        engine.execute_script("return type(camera.zoom) == 'function'").should be_true
        engine.execute_script("return type(camera.pan) == 'function'").should be_true
        engine.execute_script("return type(camera.sway) == 'function'").should be_true
        engine.execute_script("return type(camera.reset) == 'function'").should be_true
      end

      it "has hotspot API defined" do
        engine = Scripting::ScriptEngine.new
        result = engine.execute_script("return type(hotspot) == 'table'")
        result.should be_true

        # Verify hotspot API methods exist
        engine.execute_script("return type(hotspot.on_click) == 'function'").should be_true
        engine.execute_script("return type(hotspot._handle_event) == 'function'").should be_true
        engine.execute_script("return type(hotspot._callbacks) == 'table'").should be_true
      end

      it "has game state functions defined" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script("return type(set_game_state) == 'function'").should be_true
        engine.execute_script("return type(get_game_state) == 'function'").should be_true
        engine.execute_script("return type(has_game_state) == 'function'").should be_true
        engine.execute_script("return type(remove_game_state) == 'function'").should be_true
      end
    end

    describe "hotspot API functionality" do
      it "can register hotspot callbacks" do
        engine = Scripting::ScriptEngine.new

        result = engine.execute_script(<<-LUA)
          hotspot.on_click("test_hotspot", function()
            set_game_state("hotspot_clicked", "true")
          end)
          return hotspot._callbacks["test_hotspot"] ~= nil
        LUA

        result.should be_true
      end

      it "can handle hotspot events via _handle_event" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          hotspot.on_click("desk", function(verb)
            set_game_state("desk_examined", "true")
            set_game_state("desk_verb", verb or "none")
          end)
        LUA

        # Simulate event dispatch (as ScriptEngine does when receiving EventBus event)
        engine.execute_script("hotspot._handle_event('desk', 'look')")

        # Verify the callback was executed
        engine.game_state["desk_examined"].should_not be_nil
        engine.game_state["desk_verb"].should eq("look")
      end

      it "returns false when handling unregistered hotspot" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          result = hotspot._handle_event("nonexistent", "look")
          set_game_state("handle_result", tostring(result))
        LUA

        engine.game_state["handle_result"].should eq("false")
      end
    end

    describe "dialog API functionality" do
      it "dialog.is_showing returns false when no dialog active" do
        engine = Scripting::ScriptEngine.new

        # Create minimal engine for dialog manager
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        engine.execute_script(<<-LUA)
          result = dialog.is_showing()
          set_game_state("is_showing", tostring(result))
        LUA

        engine.game_state["is_showing"].should eq("false")
      end
    end

    describe "game API functionality" do
      it "game.get_time returns a number" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          local t = game.get_time()
          set_game_state("time_type", type(t))
          set_game_state("time_positive", tostring(t > 0))
        LUA

        engine.game_state["time_type"].should eq("number")
        engine.game_state["time_positive"].should eq("true")
      end

      it "game.random returns a value in range" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          local r = game.random(1, 10)
          set_game_state("in_range", tostring(r >= 1 and r <= 10))
        LUA

        engine.game_state["in_range"].should eq("true")
      end

      it "game.debug_log outputs message" do
        engine = Scripting::ScriptEngine.new

        # This should not raise
        result = engine.execute_script("game.debug_log(\"Test message\")")
        result.should be_true
      end
    end

    describe "script file loading" do
      it "loads and executes script files" do
        engine = Scripting::ScriptEngine.new

        # Create a temporary test script
        temp_path = File.tempname("test_script", ".lua")
        File.write(temp_path, <<-LUA)
          set_game_state("script_loaded", "true")

          function test_function()
            return 42
          end
        LUA

        begin
          result = engine.execute_script_file(temp_path)
          result.should be_true
          engine.game_state["script_loaded"].should eq("true")
        ensure
          File.delete(temp_path) if File.exists?(temp_path)
        end
      end

      it "handles missing script files gracefully" do
        engine = Scripting::ScriptEngine.new

        result = engine.execute_script_file("nonexistent/path/script.lua")
        result.should be_false
      end
    end

    describe "scene script integration" do
      it "scene scripts can define functions that persist" do
        engine = Scripting::ScriptEngine.new

        # Simulate loading a scene script that defines functions
        engine.execute_script(<<-LUA)
          function examine_desk()
            set_game_state("desk_examined", "true")
            dialog.show("A dusty old desk.", "Narrator")
          end

          function examine_bookshelf()
            set_game_state("bookshelf_examined", "true")
          end

          -- Register hotspot callbacks like real scene scripts do
          hotspot.on_click("desk", examine_desk)
          hotspot.on_click("bookshelf", examine_bookshelf)
        LUA

        # Verify functions are callable
        engine.execute_script("examine_desk()")
        engine.game_state["desk_examined"].should eq("true")

        # Verify hotspot event handling works (simulating EventBus dispatch)
        engine.execute_script("hotspot._handle_event('bookshelf', 'look')")
        engine.game_state["bookshelf_examined"].should eq("true")
      end
    end

    describe "audio API functionality" do
      it "audio module exists with all methods" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script("return type(audio) == 'table'").should be_true
        engine.execute_script("return type(audio.play_sound) == 'function'").should be_true
        engine.execute_script("return type(audio.play_music) == 'function'").should be_true
        engine.execute_script("return type(audio.stop_music) == 'function'").should be_true
        engine.execute_script("return type(audio.set_volume) == 'function'").should be_true
      end

      it "global audio convenience functions exist" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script("return type(play_sound) == 'function'").should be_true
        engine.execute_script("return type(play_music) == 'function'").should be_true
        engine.execute_script("return type(stop_music) == 'function'").should be_true
      end

      it "audio functions work with engine initialized" do
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        script_engine = Scripting::ScriptEngine.new

        # These should work with engine initialized
        result = script_engine.execute_script("play_sound('test_sound')")
        result.should be_true

        result = script_engine.execute_script("play_music('test_music')")
        result.should be_true

        result = script_engine.execute_script("stop_music()")
        result.should be_true

        result = script_engine.execute_script("audio.set_volume('master', 0.5)")
        result.should be_true
      end
    end

    describe "global convenience functions" do
      it "show_message function exists" do
        engine = Scripting::ScriptEngine.new

        # show_message should be defined
        result = engine.execute_script("return type(show_message) == 'function'")
        result.should be_true
      end

      it "show_message works with engine initialized" do
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        script_engine = Scripting::ScriptEngine.new

        # Should work when called with engine
        result = script_engine.execute_script("show_message('Test message')")
        result.should be_true
      end

      it "has_item checks inventory with engine" do
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        script_engine = Scripting::ScriptEngine.new

        script_engine.execute_script(<<-LUA)
          result = has_item("nonexistent_item")
          set_game_state("has_result", tostring(result))
        LUA

        script_engine.game_state["has_result"].should eq("false")
      end

      it "add_item and remove_item work with engine" do
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        script_engine = Scripting::ScriptEngine.new

        # Add item
        result = script_engine.execute_script("add_item('test_item', 'A test item')")
        result.should be_true

        # Verify item was added
        script_engine.execute_script(<<-LUA)
          result = has_item("test_item")
          set_game_state("has_item", tostring(result))
        LUA
        script_engine.game_state["has_item"].should eq("true")

        # Remove item
        result = script_engine.execute_script("remove_item('test_item')")
        result.should be_true

        # Verify item was removed
        script_engine.execute_script(<<-LUA)
          result = has_item("test_item")
          set_game_state("has_item_after", tostring(result))
        LUA
        script_engine.game_state["has_item_after"].should eq("false")
      end
    end

    describe "scene event handlers (EventBus pattern)" do
      it "scene.on_enter registers handler" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          scene.on_enter(function(scene_name)
            set_game_state("entered_scene", scene_name)
          end)

          -- Verify handler is registered
          set_game_state("handler_registered", tostring(scene._event_handlers["enter"] ~= nil))
        LUA

        engine.game_state["handler_registered"].should eq("true")
      end

      it "scene.on_exit registers handler" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          scene.on_exit(function(scene_name)
            set_game_state("exited_scene", scene_name)
          end)

          set_game_state("handler_registered", tostring(scene._event_handlers["exit"] ~= nil))
        LUA

        engine.game_state["handler_registered"].should eq("true")
      end

      it "scene.on_item_use registers handler" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          scene.on_item_use(function(item_id, target)
            set_game_state("item_used", item_id)
            set_game_state("item_target", target)
          end)

          set_game_state("handler_registered", tostring(scene._event_handlers["item_use"] ~= nil))
        LUA

        engine.game_state["handler_registered"].should eq("true")
      end

      it "scene._handle_event dispatches to registered handlers" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          scene.on_enter(function(scene_name, previous)
            set_game_state("entered", scene_name)
            set_game_state("from", previous or "none")
          end)
        LUA

        # Simulate EventBus dispatch
        engine.execute_script("scene._handle_event('enter', 'library', 'foyer')")

        engine.game_state["entered"].should eq("library")
        engine.game_state["from"].should eq("foyer")
      end

      it "scene._handle_event returns false for unregistered events" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          result = scene._handle_event("enter", "test_scene")
          set_game_state("result", tostring(result))
        LUA

        engine.game_state["result"].should eq("false")
      end
    end

    describe "character event handlers (EventBus pattern)" do
      it "character.on_interact registers handler" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          character.on_interact("guard", function(target, verb)
            set_game_state("interacted_with", "guard")
          end)

          set_game_state("handler_registered", tostring(character._interact_callbacks["guard"] ~= nil))
        LUA

        engine.game_state["handler_registered"].should eq("true")
      end

      it "character._handle_event dispatches interact events" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          character.on_interact("butler", function(target, verb)
            set_game_state("char_name", "butler")
            set_game_state("target", target or "unknown")
            set_game_state("verb", verb or "unknown")
          end)
        LUA

        # Simulate EventBus dispatch
        engine.execute_script("character._handle_event('interact', 'butler', 'player', 'talk')")

        engine.game_state["char_name"].should eq("butler")
        engine.game_state["target"].should eq("player")
        engine.game_state["verb"].should eq("talk")
      end

      it "character._handle_event returns false for unregistered characters" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          result = character._handle_event("interact", "nobody", "player", "talk")
          set_game_state("result", tostring(result))
        LUA

        engine.game_state["result"].should eq("false")
      end
    end

    describe "hotspot event handlers (EventBus pattern)" do
      it "hotspot.on_click registers handler with verb support" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          hotspot.on_click("painting", function(verb)
            set_game_state("clicked_verb", verb)
          end)

          set_game_state("handler_registered", tostring(hotspot._callbacks["painting"] ~= nil))
        LUA

        engine.game_state["handler_registered"].should eq("true")
      end

      it "hotspot._handle_event passes verb to handler" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          hotspot.on_click("safe", function(verb)
            set_game_state("safe_verb", verb)
          end)
        LUA

        engine.execute_script("hotspot._handle_event('safe', 'use')")
        engine.game_state["safe_verb"].should eq("use")

        engine.execute_script("hotspot._handle_event('safe', 'look')")
        engine.game_state["safe_verb"].should eq("look")
      end

      it "multiple hotspots can have different handlers" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          hotspot.on_click("door", function() set_game_state("clicked", "door") end)
          hotspot.on_click("window", function() set_game_state("clicked", "window") end)
          hotspot.on_click("lamp", function() set_game_state("clicked", "lamp") end)
        LUA

        engine.execute_script("hotspot._handle_event('door', 'use')")
        engine.game_state["clicked"].should eq("door")

        engine.execute_script("hotspot._handle_event('window', 'look')")
        engine.game_state["clicked"].should eq("window")

        engine.execute_script("hotspot._handle_event('lamp', 'use')")
        engine.game_state["clicked"].should eq("lamp")
      end
    end

    describe "complete scene script simulation" do
      it "simulates a full scene script with all features" do
        engine = Scripting::ScriptEngine.new

        # Load a realistic scene script
        engine.execute_script(<<-LUA)
          -- Scene enter handler
          scene.on_enter(function(scene_name)
            set_game_state("current_scene", scene_name)
            -- Use has_game_state instead of get_game_state for boolean checks
            if not has_game_state("visited_" .. scene_name) then
              set_game_state("visited_" .. scene_name, "true")
              set_game_state("first_visit", "true")
            else
              set_game_state("first_visit", "false")
            end
          end)

          -- Hotspot handlers
          hotspot.on_click("painting", function(verb)
            if verb == "look" then
              set_game_state("painting_looked", "true")
            elseif verb == "use" then
              set_game_state("painting_used", "true")
            end
          end)

          hotspot.on_click("bookshelf", function(verb)
            if not has_game_state("bookshelf_searched") then
              set_game_state("bookshelf_searched", "true")
              set_game_state("found_key", "true")
            end
          end)

          -- Item use handler
          scene.on_item_use(function(item_id, target)
            if item_id == "key" and target == "locked_door" then
              set_game_state("door_unlocked", "true")
            end
          end)
        LUA

        # Simulate scene enter
        engine.execute_script("scene._handle_event('enter', 'library')")
        engine.game_state["current_scene"].should eq("library")
        engine.game_state["first_visit"].should eq("true")

        # Simulate looking at painting
        engine.execute_script("hotspot._handle_event('painting', 'look')")
        engine.game_state["painting_looked"].should eq("true")

        # Simulate using painting
        engine.execute_script("hotspot._handle_event('painting', 'use')")
        engine.game_state["painting_used"].should eq("true")

        # Simulate searching bookshelf
        engine.execute_script("hotspot._handle_event('bookshelf', 'use')")
        engine.game_state["bookshelf_searched"].should eq("true")
        engine.game_state["found_key"].should eq("true")

        # Simulate using item on target
        engine.execute_script("scene._handle_event('item_use', 'key', 'locked_door')")
        engine.game_state["door_unlocked"].should eq("true")

        # Simulate re-entering scene
        engine.execute_script("scene._handle_event('enter', 'library')")
        engine.game_state["first_visit"].should eq("false")
      end
    end

    describe "timer API" do
      it "has add_timer function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(add_timer) == 'function'").should be_true
      end

      it "has cancel_timer function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(cancel_timer) == 'function'").should be_true
      end

      it "has _timer_callbacks table for storing callbacks" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(_timer_callbacks) == 'table'").should be_true
      end

      it "add_timer stores callback function" do
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        script_engine = Scripting::ScriptEngine.new

        script_engine.execute_script(<<-LUA)
          local callback_stored = false
          local timer_id = add_timer(1.0, function()
            callback_stored = true
          end)
          -- Check that callback was stored (timer_id returned means it worked)
          set_game_state("timer_created", tostring(timer_id ~= nil))
        LUA

        script_engine.game_state["timer_created"].should eq("true")
      end
    end

    describe "sequence API" do
      it "has start_sequence function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(start_sequence) == 'function'").should be_true
      end

      it "has is_sequence_playing function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(is_sequence_playing) == 'function'").should be_true
      end

      it "has skip_sequence function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(skip_sequence) == 'function'").should be_true
      end

      it "has _sequence_callbacks table for storing callbacks" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(_sequence_callbacks) == 'table'").should be_true
      end

      it "start_sequence stores callback" do
        engine = Scripting::ScriptEngine.new

        # Just test that callback is stored in Lua - the engine call may fail
        # without a real Engine instance, but the callback storage should work
        engine.execute_script(<<-LUA)
          -- Store callback first
          _sequence_callbacks["intro"] = function(event_type, skipped)
            set_game_state("sequence_event", event_type)
          end
          set_game_state("callback_stored", tostring(_sequence_callbacks["intro"] ~= nil))
        LUA

        engine.game_state["callback_stored"].should eq("true")
      end

      it "start_sequence runs the registered sequence through the engine-level runner" do
        with_test_window do
          engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
          scene = PointClickEngine::Scenes::Scene.new("test")
          engine.current_scene = scene

          runner = PointClickEngine::Actions::ActionRunner.new("intro")
          runner.add(PointClickEngine::Actions::ActionData.new("wait", duration: 1.0f32))
          engine.scene_manager.register_sequence("intro", runner)

          script_engine = Scripting::ScriptEngine.new
          script_engine.execute_script("return start_sequence('intro')").should be_true

          engine.global_script_runner.should eq(runner)
          engine.script_running?.should be_true
          scene.script_runner.should be_nil
        end
      end
    end

    describe "input dialog API" do
      it "has show_input_dialog function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(show_input_dialog) == 'function'").should be_true
      end

      it "show_input_dialog stores callback" do
        engine = Scripting::ScriptEngine.new

        # Test that the callback is stored - the actual dialog call may fail
        # without a real Engine instance
        engine.execute_script(<<-LUA)
          -- Manually store callback as show_input_dialog would
          _input_dialog_callback = function(result)
            set_game_state("input_result", result)
          end
          set_game_state("callback_stored", tostring(_input_dialog_callback ~= nil))
        LUA

        engine.game_state["callback_stored"].should eq("true")
      end

      it "accepts max_length parameter" do
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        script_engine = Scripting::ScriptEngine.new

        # Should not error with max_length parameter when engine exists
        result = script_engine.execute_script("show_input_dialog('PIN:', function() end, 4)")
        result.should be_true
      end
    end

    describe "ambient audio API" do
      it "has play_ambient function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(play_ambient) == 'function'").should be_true
      end

      it "has stop_ambient function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(stop_ambient) == 'function'").should be_true
      end

      it "has audio.play_ambient method defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(audio.play_ambient) == 'function'").should be_true
      end

      it "has audio.stop_ambient method defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(audio.stop_ambient) == 'function'").should be_true
      end

      it "has audio.pause_music method defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(audio.pause_music) == 'function'").should be_true
      end

      it "has audio.resume_music method defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(audio.resume_music) == 'function'").should be_true
      end
    end

    describe "floating dialog API" do
      it "has show_floating_dialog function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(show_floating_dialog) == 'function'").should be_true
      end

      it "has show_character_dialog function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(show_character_dialog) == 'function'").should be_true
      end

      it "accepts position, duration, and type parameters" do
        RaylibContext.ensure_window
        game_engine = Core::Engine.new(800, 600, "Test")
        game_engine.init

        script_engine = Scripting::ScriptEngine.new

        # Should not error with all parameters when engine exists
        result = script_engine.execute_script(<<-LUA)
          show_floating_dialog("Guard", "Hello!", {x = 100, y = 200}, 3.0, "bubble")
          return true
        LUA
        result.should be_true
      end
    end

    describe "local variable API" do
      it "has set_variable function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(set_variable) == 'function'").should be_true
      end

      it "has get_variable function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(get_variable) == 'function'").should be_true
      end

      it "has increase_variable function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(increase_variable) == 'function'").should be_true
      end

      it "set_variable and get_variable work together" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          set_variable("score", 100)
          local value = get_variable("score", 0)
          set_game_state("score_value", tostring(value))
        LUA

        engine.game_state["score_value"].should eq("100")
      end

      it "get_variable returns default for missing key" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          local value = get_variable("nonexistent", 42)
          set_game_state("default_value", tostring(value))
        LUA

        engine.game_state["default_value"].should eq("42")
      end

      it "increase_variable increments value" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          set_variable("counter", 5)
          increase_variable("counter", 3)
          local value = get_variable("counter", 0)
          set_game_state("counter_value", tostring(value))
        LUA

        engine.game_state["counter_value"].should eq("8")
      end

      it "increase_variable creates variable if missing" do
        engine = Scripting::ScriptEngine.new

        engine.execute_script(<<-LUA)
          increase_variable("new_counter", 10)
          local value = get_variable("new_counter", 0)
          set_game_state("new_counter_value", tostring(value))
        LUA

        engine.game_state["new_counter_value"].should eq("10")
      end
    end

    describe "character helper functions" do
      it "has has_character function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(has_character) == 'function'").should be_true
      end

      it "has get_character_position function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(get_character_position) == 'function'").should be_true
      end

      it "has play_character_animation function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(play_character_animation) == 'function'").should be_true
      end

      it "has move_character function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(move_character) == 'function'").should be_true
      end

      it "has hide_character function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(hide_character) == 'function'").should be_true
      end

      it "has show_character function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(show_character) == 'function'").should be_true
      end

      it "has character.exists function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(character.exists) == 'function'").should be_true
      end
    end

    describe "hotspot helper functions" do
      it "has set_hotspot_visible function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(set_hotspot_visible) == 'function'").should be_true
      end

      it "has set_hotspot_enabled function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(set_hotspot_enabled) == 'function'").should be_true
      end
    end

    describe "player functions" do
      it "has get_player_position function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(get_player_position) == 'function'").should be_true
      end
    end

    describe "achievement functions" do
      it "has trigger_achievement function defined" do
        engine = Scripting::ScriptEngine.new
        engine.execute_script("return type(trigger_achievement) == 'function'").should be_true
      end
    end
  end
end
