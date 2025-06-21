module PointClickEngine
  module Scripting
    module EnhancedAPI
      def register_enhanced_api
        register_enhanced_dialog_api
        register_enhanced_audio_api
        register_enhanced_scene_api
        register_achievement_api
        register_cutscene_api
      end

      private def register_enhanced_dialog_api
        @lua.execute! <<-LUA
          -- Enhanced dialog functions
          function show_dialog(character, text)
            dialog.show(text, character)
          end
          
          function show_message(text)
            _engine_show_message(text)
          end
          
          function show_choice(prompt, options, callback)
            _engine_show_choice(prompt, options, callback)
          end
          
          function start_dialog_tree(tree_id)
            _engine_start_dialog_tree(tree_id)
          end
          
          -- Dialog trees storage
          dialog_trees = {}
          
          -- Inventory aliases
          function add_to_inventory(item_name, description)
            inventory.add_item(item_name, description or "")
          end
          
          function remove_from_inventory(item_name)
            inventory.remove_item(item_name)
          end
          
          function has_item(item_name)
            return inventory.has_item(item_name)
          end
        LUA

        @lua.register_fn_global("_engine_show_message") do |state|
          if state.size >= 1
            text = state.to_string(1)
            begin
              engine = Core::Engine.instance
              engine.dialog_manager.try &.show_message(text)
            rescue
              # Engine not initialized yet
            end
          end
          0
        end

        @lua.register_fn_global("_engine_show_choice") do |state|
          if state.size >= 3
            prompt = state.to_string(1)
            # TODO: Parse options table at index 2
            # TODO: Store callback function at index 3

            begin
              engine = Core::Engine.instance
              # For now, create a simple two-choice dialog
              engine.dialog_manager.try do |dm|
                dm.show_choice(prompt, ["Option 1", "Option 2"], ->(choice : Int32) {
                  # TODO: Call Lua callback with choice
                })
              end
            rescue
              # Engine not initialized yet
            end
          end
          0
        end

        @lua.register_fn_global("_engine_start_dialog_tree") do |state|
          if state.size >= 1
            tree_id = state.to_string(1)
            # TODO: Implement dialog tree system
          end
          0
        end
      end

      private def register_enhanced_audio_api
        @lua.execute! <<-LUA
          -- Audio functions
          function play_sound(sound_name)
            _engine_play_sound(sound_name)
          end
          
          function play_music(music_name)
            _engine_play_music(music_name)
          end
          
          function stop_music()
            _engine_stop_music()
          end
          
          function set_volume(volume_type, level)
            _engine_set_volume(volume_type, level)
          end
        LUA

        @lua.register_fn_global("_engine_play_sound") do |state|
          if state.size >= 1
            sound_name = state.to_string(1)
            begin
              engine = Core::Engine.instance
              engine.audio_manager.try &.play_sound_effect(sound_name)
            rescue
              # Engine not initialized yet
            end
          end
          0
        end

        @lua.register_fn_global("_engine_play_music") do |state|
          if state.size >= 1
            music_name = state.to_string(1)
            begin
              engine = Core::Engine.instance
              engine.audio_manager.try &.play_music(music_name)
            rescue
              # Engine not initialized yet
            end
          end
          0
        end

        @lua.register_fn_global("_engine_stop_music") do |state|
          begin
            engine = Core::Engine.instance
            engine.audio_manager.try &.stop_music
          rescue
            # Engine not initialized yet
          end
          0
        end

        @lua.register_fn_global("_engine_set_volume") do |state|
          if state.size >= 2
            volume_type = state.to_string(1)
            level = state.to_f32(2)

            begin
              engine = Core::Engine.instance
              engine.audio_manager.try do |am|
                case volume_type
                when "master"
                  am.master_volume = level
                when "music"
                  am.music_volume = level
                when "sfx"
                  am.sfx_volume = level
                end
              end
            rescue
              # Engine not initialized yet
            end
          end
          0
        end
      end

      private def register_enhanced_scene_api
        @lua.execute! <<-LUA
          -- Enhanced scene functions
          function change_scene(scene_name)
            scene.change(scene_name)
          end
          
          function get_game_state(key)
            return _engine_get_game_state(key)
          end
          
          function set_game_state(key, value)
            _engine_set_game_state(key, value)
          end
          
          function wait_seconds(seconds)
            _engine_wait_seconds(seconds)
          end
          
          function set_shader(shader_name, intensity)
            _engine_set_shader(shader_name, intensity or 1.0)
          end
        LUA

        @lua.register_fn_global("_engine_get_game_state") do |state|
          if state.size >= 1
            key = state.to_string(1)
            if value = @game_state[key]?
              # Push the value back to Lua
              case value
              when String
                state.push(value.as(String))
              when Float64
                state.push(value.as(Float64))
              when Bool
                state.push(value.as(Bool))
              when Nil
                state.push(nil)
              else
                state.push(nil)
              end
            else
              state.push(nil)
            end
          else
            state.push(nil)
          end
          1
        end

        @lua.register_fn_global("_engine_set_game_state") do |state|
          if state.size >= 2
            key = state.to_string(1)
            if value = state.to_any?(2)
              @game_state[key] = value
            end
          end
          0
        end

        @lua.register_fn_global("_engine_wait_seconds") do |state|
          if state.size >= 1
            seconds = state.to_f32(1)
            # TODO: Implement async wait system
            # For now, just sleep (blocks the game - not ideal)
            # sleep seconds
          end
          0
        end

        @lua.register_fn_global("_engine_set_shader") do |state|
          if state.size >= 1
            shader_name = state.to_string(1)
            intensity = state.size >= 2 ? state.to_f32(2) : 1.0f32

            begin
              engine = Core::Engine.instance
              engine.shader_system.try do |ss|
                # Convert string to symbol for shader name
                case shader_name
                when "vignette"
                  ss.set_active(:vignette)
                when "bloom"
                  ss.set_active(:bloom)
                when "pixelate"
                  ss.set_active(:pixelate)
                when "grayscale"
                  ss.set_active(:grayscale)
                else
                  # Try to set custom shader if exists
                  puts "Unknown shader: #{shader_name}"
                end
                # TODO: Set shader intensity parameter
              end
            rescue
              # Engine not initialized yet
            end
          end
          0
        end
      end

      private def register_achievement_api
        @lua.execute! <<-LUA
          -- Achievement functions
          function trigger_achievement(achievement_id)
            _engine_trigger_achievement(achievement_id)
          end
          
          function is_achievement_unlocked(achievement_id)
            return _engine_is_achievement_unlocked(achievement_id)
          end
        LUA

        @lua.register_fn_global("_engine_trigger_achievement") do |state|
          if state.size >= 1
            achievement_id = state.to_string(1)
            begin
              engine = Core::Engine.instance
              engine.achievement_manager.try &.unlock(achievement_id)
            rescue
              # Engine not initialized yet
            end
          end
          0
        end

        @lua.register_fn_global("_engine_is_achievement_unlocked") do |state|
          if state.size >= 1
            achievement_id = state.to_string(1)
            begin
              engine = Core::Engine.instance
              unlocked = engine.achievement_manager.try(&.is_unlocked?(achievement_id)) || false
              state.push(unlocked)
            rescue
              state.push(false)
            end
          else
            state.push(false)
          end
          1
        end
      end

      private def register_cutscene_api
        @lua.execute! <<-LUA
          -- Cutscene functions
          function start_cutscene(cutscene_id)
            _engine_start_cutscene(cutscene_id)
          end
          
          function end_cutscene()
            _engine_end_cutscene()
          end
          
          function is_cutscene_playing()
            return _engine_is_cutscene_playing()
          end
        LUA

        @lua.register_fn_global("_engine_start_cutscene") do |state|
          if state.size >= 1
            cutscene_id = state.to_string(1)
            begin
              engine = Core::Engine.instance
              engine.cutscene_manager.play_cutscene(cutscene_id)
            rescue
              # Engine not initialized yet
            end
          end
          0
        end

        @lua.register_fn_global("_engine_end_cutscene") do |state|
          begin
            engine = Core::Engine.instance
            engine.cutscene_manager.stop_current
          rescue
            # Engine not initialized yet
          end
          0
        end

        @lua.register_fn_global("_engine_is_cutscene_playing") do |state|
          begin
            engine = Core::Engine.instance
            playing = engine.cutscene_manager.is_playing?
            state.push(playing)
          rescue
            state.push(false)
          end
          1
        end
      end
    end
  end
end
