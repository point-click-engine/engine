# ActionExecutor - Executes action instances
# All action logic consolidated in one place
#
# Optimizations:
# - Action handler registry for O(1) type lookup
# - Cached parameter values at action start
# - Reusable vector/color structs

require "./action"
require "../graphics/effects/scene_effects/ambient_effects"

module PointClickEngine
  module Actions
    # Handler type aliases for action callbacks
    alias ActionStartHandler = ActionInstance, Scenes::Scene, ActionExecutor -> Nil
    alias ActionUpdateHandler = ActionInstance, Scenes::Scene, Float32, ActionExecutor -> Bool
    alias ActionFinishHandler = ActionInstance, Scenes::Scene, ActionExecutor -> Nil
    alias ActionDrawHandler = ActionInstance, ActionExecutor -> Nil

    # Executes action instances - all action logic in one place
    class ActionExecutor
      @engine : Core::Engine

      # Custom action handlers registry (for extensibility)
      @custom_start_handlers : Hash(String, ActionStartHandler) = {} of String => ActionStartHandler
      @custom_update_handlers : Hash(String, ActionUpdateHandler) = {} of String => ActionUpdateHandler
      @custom_finish_handlers : Hash(String, ActionFinishHandler) = {} of String => ActionFinishHandler
      @custom_draw_handlers : Hash(String, ActionDrawHandler) = {} of String => ActionDrawHandler

      # Cached reusable objects to reduce allocations
      @temp_vector : Raylib::Vector2 = Raylib::Vector2.new(x: 0, y: 0)

      def initialize(@engine : Core::Engine)
      end

      # Register a custom action handler
      def register_action(type : String,
                          start : ActionStartHandler? = nil,
                          update : ActionUpdateHandler? = nil,
                          finish : ActionFinishHandler? = nil,
                          draw : ActionDrawHandler? = nil)
        type_lower = type.downcase
        @custom_start_handlers[type_lower] = start if start
        @custom_update_handlers[type_lower] = update if update
        @custom_finish_handlers[type_lower] = finish if finish
        @custom_draw_handlers[type_lower] = draw if draw
      end

      # Unregister a custom action handler
      def unregister_action(type : String)
        type_lower = type.downcase
        @custom_start_handlers.delete(type_lower)
        @custom_update_handlers.delete(type_lower)
        @custom_finish_handlers.delete(type_lower)
        @custom_draw_handlers.delete(type_lower)
      end

      # Start an action - called once when action begins
      def start(action : ActionInstance, scene : Scenes::Scene)
        type_lower = action.data.type.downcase

        # Check custom handlers first (O(1) lookup)
        if handler = @custom_start_handlers[type_lower]?
          handler.call(action, scene, self)
          action.start!
          return
        end

        case type_lower
        # === TIMING ===
        when "wait"
          # No-op, just waits for duration

          # === CHARACTER MOVEMENT ===
        when "character_move", "move_character"
          start_character_move(action, scene)
        when "character_enter"
          start_character_enter(action, scene)
        when "character_exit"
          start_character_exit(action, scene)
        when "character_face"
          start_character_face(action, scene)
        when "character_animation"
          start_character_animation(action, scene)
          # === DIALOG ===
        when "dialog", "floating_dialog"
          start_dialog(action, scene)
          # === CAMERA ===
        when "camera_shake"
          start_camera_shake(action)
        when "camera_pan"
          start_camera_pan(action)
        when "camera_zoom"
          start_camera_zoom(action)
        when "camera_follow"
          start_camera_follow(action, scene)
        when "camera_focus"
          start_camera_focus(action, scene)
          # === VISUAL EFFECTS ===
        when "fade_in"
          start_fade(action, direction: "in")
        when "fade_out", "fade_to_color", "fade_to_black"
          start_fade(action, direction: "out")
        when "screen_flash"
          start_screen_flash(action)
        when "screen_effect"
          start_screen_effect(action)
        when "particle_effect", "weather_effect"
          start_particle_effect(action)
        when "stop_particle_effect"
          @engine.effect_manager.clear_scene_effects
        when "letterbox", "set_letterbox"
          start_letterbox(action)
          # === SPRITES (for sequence visuals) ===
        when "show_sprite"
          start_show_sprite(action)
        when "hide_sprite"
          start_hide_sprite(action)
        when "move_sprite"
          # Movement handled in update

        when "show_background"
          start_show_background(action)
          # === AUDIO ===
        when "play_music"
          start_play_music(action)
        when "stop_music"
          start_stop_music(action)
        when "play_ambient"
          start_play_ambient(action)
        when "stop_ambient"
          # Ambient stop handled by audio manager

        when "sound_effect", "play_sound"
          start_sound_effect(action)
          # === UI ===
        when "hide_ui"
          @engine.render_manager.hide_ui
        when "show_ui"
          @engine.render_manager.show_ui
        when "show_text"
          start_show_text(action)
          # === GAME STATE ===
        when "set_game_state", "set_flag", "set_variable"
          start_set_game_state(action)
          # === SCENE ===
        when "change_scene"
          start_change_scene(action)
          # === CONTROL ===
        when "enable_player_control"
          @engine.player_control_enabled = true
        when "disable_player_control"
          @engine.player_control_enabled = false
        when "hide_player"
          if player = @engine.player
            player.visible = false
          end
        when "show_player"
          if player = @engine.player
            player.visible = true
          end
          # === CALLBACK ===
        when "callback", "run"
          action.callback.try(&.call)
          # === CREDITS/MENU ===
        when "show_credits"
          start_show_credits(action)
        when "return_to_menu"
          # Handled in finish

          # === INTERNAL ===
        when "_parallel_marker"
          # Handled by ActionRunner

        else
          puts "[ActionExecutor] Unknown action type: #{action.data.type}"
        end

        action.start!
      end

      # Update an action - called every frame while running
      # Returns true if action is complete
      def update(action : ActionInstance, scene : Scenes::Scene, dt : Float32) : Bool
        action.elapsed += dt
        progress = action.progress
        type_lower = action.data.type.downcase

        # Check custom handlers first (O(1) lookup)
        if handler = @custom_update_handlers[type_lower]?
          return handler.call(action, scene, dt, self)
        end

        case type_lower
        when "character_move", "move_character", "character_enter"
          char_name = get_string(action, "character")
          if char = scene.get_character(char_name)
            return char.state != Characters::CharacterState::Walking
          end
          return true
        when "character_exit"
          char_name = get_string(action, "character")
          if char = scene.get_character(char_name)
            return char.state != Characters::CharacterState::Walking
          end
          return true
        when "dialog", "floating_dialog"
          if action.get_custom("dialog_complete").try(&.as_bool)
            return true
          end
          return action.data.duration > 0 && progress >= 1.0
        when "sound_effect", "play_sound"
          delay = get_float(action, "delay", 0.0f32)
          if delay > 0
            unless action.get_custom("sound_played").try(&.as_bool)
              if action.elapsed < delay
                return false
              end

              play_sound_effect_now(action)
              action.set_custom("sound_played", true)
            end
          end
          return true
        when "stop_music"
          if action.data.duration > 0
            if audio = @engine.system_manager.audio_manager
              start_vol = action.get_custom("start_volume").try(&.as_f.to_f32) || 1.0f32
              audio.set_music_volume(start_vol * (1.0f32 - progress))
            end
          end
          return progress >= 1.0
        when "show_text"
          update_show_text(action)
          return progress >= 1.0
        when "move_sprite"
          update_move_sprite(action, progress)
          return progress >= 1.0
        when "show_credits"
          return update_show_credits(action, dt)
        when "return_to_menu"
          delay = get_float(action, "delay", 0.0f32)
          return action.elapsed >= delay
        else
          # Most actions complete based on duration
          return action.data.duration <= 0 || progress >= 1.0
        end
      end

      # Finish an action - called once when action completes
      def finish(action : ActionInstance, scene : Scenes::Scene)
        type_lower = action.data.type.downcase

        # Check custom handlers first (O(1) lookup)
        if handler = @custom_finish_handlers[type_lower]?
          handler.call(action, scene, self)
          action.complete!
          return
        end

        case type_lower
        when "character_exit"
          char_name = get_string(action, "character")
          if char = scene.get_character(char_name)
            char.visible = false
          end
        when "stop_music"
          if audio = @engine.system_manager.audio_manager
            audio.stop_music
            start_vol = action.get_custom("start_volume").try(&.as_f.to_f32) || 1.0f32
            audio.set_music_volume(start_vol)
          end
        when "hide_sprite"
          # Removal starts in start_hide_sprite so fade-outs can continue asynchronously.
        when "return_to_menu"
          @engine.return_to_menu
        end

        action.complete!
      end

      # Draw action overlays (for text, custom visuals)
      def draw(action : ActionInstance)
        type_lower = action.data.type.downcase

        # Check custom handlers first (O(1) lookup)
        if handler = @custom_draw_handlers[type_lower]?
          handler.call(action, self)
          return
        end

        case type_lower
        when "show_text"
          draw_show_text(action)
        when "show_credits"
          draw_show_credits(action)
        end
      end

      # ============================================================
      # ACTION START HELPERS
      # ============================================================

      private def start_character_move(action : ActionInstance, scene : Scenes::Scene)
        char_name = get_string(action, "character")
        target = get_scene_vector2(action, "target", scene) || get_scene_vector2(action, "to", scene)
        return unless target

        if char = scene.get_character(char_name)
          use_pathfinding = get_bool(action, "pathfinding", true)
          if use_pathfinding
            if path = scene.find_path(char.position.x, char.position.y, target.x, target.y)
              char.walk_to_with_path(path)
            else
              char.walk_to(target)
            end
          else
            char.walk_to(target)
          end
        end
      end

      private def start_character_enter(action : ActionInstance, scene : Scenes::Scene)
        char_name = get_string(action, "character")
        from = get_string(action, "from", "left")
        to = get_scene_vector2(action, "to", scene)
        from_position = get_scene_vector2(action, "from_position", scene)

        if char = scene.get_character(char_name)
          start_pos = from_position || calculate_entry_position(from, to, scene)
          char.position = start_pos
          char.visible = true
          char.walk_to(to) if to
        end
      end

      private def start_character_exit(action : ActionInstance, scene : Scenes::Scene)
        char_name = get_string(action, "character")
        direction = get_string(action, "direction", "left")

        if char = scene.get_character(char_name)
          exit_pos = calculate_exit_position(direction, char.position, scene)
          char.walk_to(exit_pos)
        end
      end

      private def start_character_face(action : ActionInstance, scene : Scenes::Scene)
        char_name = get_string(action, "character")
        direction = get_string(action, "direction")
        target_name = get_string(action, "target")

        if char = scene.get_character(char_name)
          if !direction.empty?
            char.direction = parse_direction(direction)
          elsif !target_name.empty?
            if target_char = scene.get_character(target_name)
              if target_char.position.x < char.position.x
                char.direction = Characters::Direction::Left
              else
                char.direction = Characters::Direction::Right
              end
            end
          end
        end
      end

      private def start_character_animation(action : ActionInstance, scene : Scenes::Scene)
        char_name = get_string(action, "character")
        anim = get_string(action, "animation")

        if char = scene.get_character(char_name)
          char.play_animation(anim)
        end
      end

      private def start_dialog(action : ActionInstance, scene : Scenes::Scene)
        char_name = get_string(action, "character")
        text = get_string(action, "text")

        if char = scene.get_character(char_name)
          action.set_custom("dialog_complete", false)
          char.say(text) do
            action.set_custom("dialog_complete", true)
            nil
          end
        else
          # No character found, mark as complete immediately
          action.set_custom("dialog_complete", true)
        end
      end

      private def start_camera_shake(action : ActionInstance)
        intensity = get_float(action, "intensity", 5.0f32)
        frequency = get_float(action, "frequency", 10.0f32)
        @engine.effect_manager.add_camera_effect("shake",
          amplitude: intensity,
          frequency: frequency,
          duration: action.data.duration
        )
      end

      private def start_camera_pan(action : ActionInstance)
        scene = @engine.current_scene
        target = get_scene_vector2(action, "target", scene) || get_scene_vector2(action, "to", scene)
        return unless target

        easing = get_string(action, "easing", "ease_in_out")
        @engine.effect_manager.add_camera_effect("pan",
          target: [target.x, target.y],
          duration: action.data.duration,
          easing: easing
        )
      end

      private def start_camera_zoom(action : ActionInstance)
        target_zoom = action.data.params["target_zoom"]?.try(&.as_f.to_f32) || get_float(action, "target", 1.0f32)
        easing = get_string(action, "easing", "ease_in_out")

        if scene = @engine.current_scene
          if focus_target = resolve_focus_target(action, scene)
            @engine.camera.center_on(focus_target)
          end
        end

        @engine.effect_manager.add_camera_effect("zoom",
          target: target_zoom,
          duration: action.data.duration,
          easing: easing
        )
      end

      private def start_camera_follow(action : ActionInstance, scene : Scenes::Scene)
        char_name = get_string(action, "character")
        if char = scene.get_character(char_name)
          @engine.camera.center_on(char.position)
        end
      end

      private def start_camera_focus(action : ActionInstance, scene : Scenes::Scene)
        target = get_string(action, "target")
        return if target.empty?

        focus_point = if character = scene.get_character(target)
                        character.position
                      elsif hotspot = scene.hotspot_manager.try(&.get_hotspot_by_name(target))
                        Raylib::Vector2.new(
                          x: hotspot.position.x + hotspot.size.x / 2.0f32,
                          y: hotspot.position.y + hotspot.size.y / 2.0f32
                        )
                      else
                        nil
                      end

        return unless focus_point

        easing = get_string(action, "easing", "ease_in_out")
        @engine.effect_manager.add_camera_effect("pan",
          target: [focus_point.x, focus_point.y],
          duration: action.data.duration,
          easing: easing
        )
      end

      private def start_fade(action : ActionInstance, direction : String)
        color = get_color(action, "color") || Raylib::BLACK
        @engine.effect_manager.add_scene_effect("transition",
          type: "fade",
          direction: direction,
          color: [color.r.to_i, color.g.to_i, color.b.to_i, color.a.to_i],
          duration: action.data.duration
        )
      end

      private def start_screen_flash(action : ActionInstance)
        color = get_color(action, "color") || Raylib::WHITE
        @engine.effect_manager.add_scene_effect("flash",
          color: [color.r.to_i, color.g.to_i, color.b.to_i, color.a.to_i],
          duration: action.data.duration
        )
      end

      private def start_screen_effect(action : ActionInstance)
        effect = get_string(action, "effect")
        intensity = get_float(action, "intensity", 1.0f32)

        case effect.downcase
        when "flicker"
          frequency = get_float(action, "frequency", 8.0f32)
          @engine.effect_manager.add_scene_effect(
            Graphics::Effects::SceneEffects::FlickerEffect.new(intensity, frequency, action.data.duration)
          )
        when "vignette", "darkness"
          @engine.effect_manager.add_scene_effect("darkness",
            type: "vignette",
            intensity: intensity,
            duration: action.data.duration
          )
        when "rain"
          intensity_name = intensity > 0.7 ? "heavy" : (intensity > 0.4 ? "medium" : "light")
          @engine.effect_manager.add_scene_effect("rain",
            intensity: intensity_name,
            duration: action.data.duration
          )
        when "fog"
          @engine.effect_manager.add_scene_effect("fog",
            density: intensity * 0.05,
            duration: action.data.duration
          )
        when "underwater"
          @engine.effect_manager.add_scene_effect("underwater",
            duration: action.data.duration
          )
        end
      end

      private def start_particle_effect(action : ActionInstance)
        effect_type = get_string(action, "effect")
        intensity = get_float(action, "intensity", 1.0f32)
        duration = action.data.duration
        color = get_color(action, "color")

        case effect_type.downcase
        when "sparkles", "magic", "crystal_energy", "magical_sparkles"
          count = (intensity * 50).to_i
          if c = color
            @engine.effect_manager.add_scene_effect("sparkles", count: count, duration: duration,
              color: [c.r.to_i, c.g.to_i, c.b.to_i, c.a.to_i])
          else
            @engine.effect_manager.add_scene_effect("sparkles", count: count, duration: duration)
          end
        when "rain"
          intensity_name = intensity > 0.7 ? "heavy" : (intensity > 0.4 ? "medium" : "light")
          @engine.effect_manager.add_scene_effect("rain", intensity: intensity_name, duration: duration)
        when "fog", "mist"
          @engine.effect_manager.add_scene_effect("fog", density: intensity * 0.03, duration: duration)
        when "snow"
          count = (intensity * 100).to_i
          @engine.effect_manager.add_scene_effect("snow", count: count, duration: duration)
        when "smoke"
          count = (intensity * 30).to_i
          if c = color
            @engine.effect_manager.add_scene_effect("smoke", count: count, duration: duration,
              color: [c.r.to_i, c.g.to_i, c.b.to_i, c.a.to_i])
          else
            @engine.effect_manager.add_scene_effect("smoke", count: count, duration: duration)
          end
        when "fire"
          count = (intensity * 12).to_i
          @engine.effect_manager.add_scene_effect("smoke", count: count, duration: duration,
            speed: 18.0, color: [255, 180, 100, 90])
        when "dust"
          count = (intensity * 20).to_i
          @engine.effect_manager.add_scene_effect("smoke", count: count, duration: duration,
            speed: 10.0, color: [150, 140, 120, 60])
        end
      end

      private def start_letterbox(action : ActionInstance)
        enabled = get_bool(action, "enabled", true)
        ratio = get_float(action, "ratio", 2.35f32)

        if enabled
          effect = Graphics::Effects::SceneEffects::LetterboxEffect.new(ratio, 0.0f32, true)
          effect.enable(action.data.duration)
          @engine.effect_manager.add_scene_effect(effect)
        else
          @engine.effect_manager.scene_effects.each do |effect|
            if lb = effect.as?(Graphics::Effects::SceneEffects::LetterboxEffect)
              lb.disable(action.data.duration)
            end
          end
        end
      end

      private def start_show_sprite(action : ActionInstance)
        sprite_path = get_string(action, "sprite")
        position = get_vector2(action, "position") || Raylib::Vector2.new(x: 0, y: 0)
        scale = get_float(action, "scale", 1.0f32)
        glow = get_bool(action, "glow", false)
        glow_color = get_color(action, "glow_color")
        fade_in = get_float(action, "fade_in", 0.0f32)
        tint = get_color(action, "color_tint") || Raylib::WHITE
        animate = get_bool(action, "animate", false)
        animation_frames = get_int(action, "animation_frames", 1)
        animation_fps = get_float(action, "animation_fps", 0.0f32)
        glow_pulse = get_bool(action, "glow_pulse", false)
        glow_pulse_speed = get_float(action, "glow_pulse_speed", 1.0f32)

        if overlay_mgr = @engine.action_overlay_manager
          configure_overlay_canvas(overlay_mgr)
          # Resolve path using scene's base_dir
          full_path = if scene = @engine.current_scene
                        base = scene.base_dir
                        base.empty? ? sprite_path : File.join(base, sprite_path)
                      else
                        sprite_path
                      end
          overlay_mgr.add_sprite(full_path, position, scale, glow, glow_color, tint, fade_in,
            animate, animation_frames, animation_fps, glow_pulse, glow_pulse_speed)
        end
      end

      private def start_hide_sprite(action : ActionInstance)
        sprite_path = get_string(action, "sprite")
        fade_out = get_float(action, "fade_out", 0.0f32)

        if overlay_mgr = @engine.action_overlay_manager
          full_path = resolve_scene_path(sprite_path)
          overlay_mgr.remove_sprite(full_path, fade_out)
        end
      end

      private def start_show_background(action : ActionInstance)
        image = get_string(action, "image")
        layer = get_int(action, "parallax_layer", 0)
        if overlay_mgr = @engine.action_overlay_manager
          configure_overlay_canvas(overlay_mgr)
          # Resolve path using scene's base_dir
          full_path = resolve_scene_path(image)
          overlay_mgr.set_background(full_path, layer)
        end
      end

      private def start_play_music(action : ActionInstance)
        track = get_string(action, "track")
        volume = get_float(action, "volume", 0.7f32)
        loop_music = get_bool(action, "loop", true)

        if audio = @engine.system_manager.audio_manager
          audio.play_music(track, loop_music)
          audio.set_music_volume(volume)
        end
      end

      private def start_stop_music(action : ActionInstance)
        if action.data.duration <= 0
          if audio = @engine.system_manager.audio_manager
            audio.stop_music
          end
        else
          if audio = @engine.system_manager.audio_manager
            action.set_custom("start_volume", audio.music_volume)
          end
        end
      end

      private def start_play_ambient(action : ActionInstance)
        sound = get_string(action, "sound")
        if audio = @engine.system_manager.audio_manager
          audio.play_sound_effect(sound)
        end
      end

      private def start_sound_effect(action : ActionInstance)
        delay = get_float(action, "delay", 0.0f32)
        if delay > 0
          action.set_custom("sound_played", false)
        else
          play_sound_effect_now(action)
        end
      end

      private def start_show_text(action : ActionInstance)
        text = get_string(action, "text")
        font_size = get_int(action, "font_size", 24)
        color = get_color(action, "color") || Raylib::WHITE
        position = get_string(action, "position", "center")
        fade_in = get_float(action, "fade_in", 0.5f32)
        fade_out = get_float(action, "fade_out", 0.5f32)
        glow = get_bool(action, "glow", false)
        glow_color = get_color(action, "glow_color")

        action.set_custom("text", text)
        action.set_custom("font_size", font_size)
        action.set_custom("color_r", color.r.to_i)
        action.set_custom("color_g", color.g.to_i)
        action.set_custom("color_b", color.b.to_i)
        action.set_custom("position", position)
        action.set_custom("fade_in", fade_in)
        action.set_custom("fade_out", fade_out)
        action.set_custom("glow", glow)
        if gc = glow_color
          action.set_custom("glow_color_r", gc.r.to_i)
          action.set_custom("glow_color_g", gc.g.to_i)
          action.set_custom("glow_color_b", gc.b.to_i)
        end
        action.set_custom("alpha", 0.0)
      end

      private def start_set_game_state(action : ActionInstance)
        if state = @engine.game_state_manager
          if flags = action.data.params["flags"]?.try(&.as_a?)
            flags.each { |f| state.set_flag(f.as_s, true) }
          end

          if vars = action.data.params["variables"]?.try(&.as_h?)
            vars.each do |k, v|
              key = k.to_s
              case v.raw
              when Bool    then state.set_flag(key, v.as_bool)
              when Int64   then state.set_variable(key, v.as_i.to_i32)
              when Float64 then state.set_variable(key, v.as_f.to_f32)
              when String  then state.set_variable(key, v.as_s)
              end
            end
          end
        end
      end

      private def start_change_scene(action : ActionInstance)
        target = get_string(action, "target")
        transition = get_string(action, "transition", "fade")
        duration = action.data.duration
        if duration <= 0
          duration = @engine.current_scene.try(&.default_transition_duration) || 1.0f32
        end

        @engine.action_overlay_manager.clear_all
        @engine.change_scene_with_transition(target, transition, duration)
      end

      private def start_show_credits(action : ActionInstance)
        scroll_speed = get_float(action, "scroll_speed", 1.0f32)
        music = get_string(action, "background_music")

        if !music.empty?
          if audio = @engine.system_manager.audio_manager
            audio.play_music(music, true)
          end
        end

        credits_text = [
          "THE CRYSTAL MYSTERY",
          "",
          "Created with",
          "Point Click Engine",
          "",
          "Programming",
          "Your Name Here",
          "",
          "Art & Design",
          "Your Name Here",
          "",
          "Music",
          "Your Name Here",
          "",
          "Special Thanks",
          "Crystal Lang Team",
          "Raylib Team",
          "",
          "Thank you for playing!",
        ]

        action.set_custom("scroll_speed", scroll_speed)
        action.set_custom("credits_y", Raylib.get_screen_height.to_f32)
        action.set_custom("credits_text", credits_text.join("\n"))
      end

      private def play_sound_effect_now(action : ActionInstance)
        sound = get_string(action, "sound")
        if audio = @engine.system_manager.audio_manager
          audio.play_sound_effect(sound)
        end
      end

      # ============================================================
      # ACTION UPDATE HELPERS
      # ============================================================

      private def update_show_text(action : ActionInstance)
        fade_in = action.get_custom("fade_in").try(&.as_f.to_f32) || 0.5f32
        fade_out = action.get_custom("fade_out").try(&.as_f.to_f32) || 0.5f32
        total = action.data.duration

        alpha = if action.elapsed < fade_in
                  action.elapsed / fade_in
                elsif action.elapsed > total - fade_out
                  (total - action.elapsed) / fade_out
                else
                  1.0f32
                end

        action.set_custom("alpha", alpha.clamp(0.0f32, 1.0f32))
      end

      private def update_move_sprite(action : ActionInstance, progress : Float32)
        sprite_path = get_string(action, "sprite")
        target = get_vector2(action, "to") || get_vector2(action, "target")
        return unless target

        if overlay_mgr = @engine.action_overlay_manager
          full_path = resolve_scene_path(sprite_path)
          overlay_mgr.move_sprite(full_path, target, progress)
        end
      end

      private def update_show_credits(action : ActionInstance, dt : Float32) : Bool
        scroll_speed = action.get_custom("scroll_speed").try(&.as_f.to_f32) || 1.0f32
        credits_y = action.get_custom("credits_y").try(&.as_f.to_f32) || 0.0f32

        # Scroll upward
        new_y = credits_y - scroll_speed * 60.0f32 * dt
        action.set_custom("credits_y", new_y)

        credits_text = action.get_custom("credits_text").try(&.as_s) || ""
        line_count = credits_text.count('\n') + 1
        total_height = line_count * 40

        # Check if credits have scrolled off screen
        new_y < -total_height
      end

      # ============================================================
      # ACTION DRAW HELPERS
      # ============================================================

      private def draw_show_text(action : ActionInstance)
        alpha = action.get_custom("alpha").try(&.as_f.to_f32) || 0.0f32
        return if alpha <= 0

        text = action.get_custom("text").try(&.as_s) || ""
        font_size = action.get_custom("font_size").try(&.as_i) || 24
        color_r = action.get_custom("color_r").try(&.as_i.to_u8) || 255u8
        color_g = action.get_custom("color_g").try(&.as_i.to_u8) || 255u8
        color_b = action.get_custom("color_b").try(&.as_i.to_u8) || 255u8
        position = action.get_custom("position").try(&.as_s) || "center"
        glow = action.get_custom("glow").try(&.as_bool) || false

        color = Raylib::Color.new(r: color_r, g: color_g, b: color_b, a: (alpha * 255).to_u8)

        screen_width = Raylib.get_screen_width
        screen_height = Raylib.get_screen_height
        text_width = Raylib.measure_text(text, font_size)

        x, y = case position
               when "center"
                 {(screen_width - text_width) // 2, screen_height // 2}
               when "top", "center_top"
                 {(screen_width - text_width) // 2, screen_height // 6}
               when "bottom", "center_bottom"
                 {(screen_width - text_width) // 2, (screen_height * 5) // 6}
               else
                 {(screen_width - text_width) // 2, screen_height // 2}
               end

        if glow
          glow_r = action.get_custom("glow_color_r").try(&.as_i.to_u8) || 255u8
          glow_g = action.get_custom("glow_color_g").try(&.as_i.to_u8) || 255u8
          glow_b = action.get_custom("glow_color_b").try(&.as_i.to_u8) || 200u8
          glow_color = Raylib::Color.new(r: glow_r, g: glow_g, b: glow_b, a: (alpha * 100).to_u8)
          Raylib.draw_text(text, x - 2, y - 2, font_size, glow_color)
          Raylib.draw_text(text, x + 2, y + 2, font_size, glow_color)
        end

        Raylib.draw_text(text, x, y, font_size, color)
      end

      private def draw_show_credits(action : ActionInstance)
        credits_y = action.get_custom("credits_y").try(&.as_f.to_f32) || 0.0f32
        credits_text = action.get_custom("credits_text").try(&.as_s) || ""
        lines = credits_text.split('\n')

        screen_width = Raylib.get_screen_width
        y = credits_y.to_i

        lines.each_with_index do |line, i|
          font_size = line.empty? ? 20 : (i == 0 ? 48 : 24)
          text_width = Raylib.measure_text(line, font_size)
          x = (screen_width - text_width) // 2
          color = i == 0 ? Raylib::GOLD : Raylib::WHITE
          Raylib.draw_text(line, x, y + i * 40, font_size, color)
        end
      end

      # ============================================================
      # PARAMETER HELPERS
      # ============================================================

      private def get_string(action : ActionInstance, key : String, default : String = "") : String
        action.data.params[key]?.try(&.as_s?) || default
      end

      private def get_float(action : ActionInstance, key : String, default : Float32 = 0.0f32) : Float32
        if val = action.data.params[key]?
          case val.raw
          when Int64   then val.as_i.to_f32
          when Float64 then val.as_f.to_f32
          else              default
          end
        else
          default
        end
      end

      private def get_int(action : ActionInstance, key : String, default : Int32 = 0) : Int32
        if val = action.data.params[key]?
          case val.raw
          when Int64   then val.as_i.to_i32
          when Float64 then val.as_f.to_i32
          else              default
          end
        else
          default
        end
      end

      private def get_bool(action : ActionInstance, key : String, default : Bool = false) : Bool
        action.data.params[key]?.try(&.as_bool?) || default
      end

      private def get_vector2(action : ActionInstance, key : String) : Raylib::Vector2?
        if data = action.data.params[key]?
          if data.as_h?
            x = data["x"]?.try { |v| v.raw.is_a?(Int64) ? v.as_i.to_f32 : v.as_f.to_f32 } || 0f32
            y = data["y"]?.try { |v| v.raw.is_a?(Int64) ? v.as_i.to_f32 : v.as_f.to_f32 } || 0f32
            return Raylib::Vector2.new(x: x, y: y)
          end
        end
        nil
      end

      private def get_scene_vector2(action : ActionInstance, key : String, scene : Scenes::Scene?) : Raylib::Vector2?
        vector = get_vector2(action, key)
        return unless vector
        return vector unless scene

        if canvas = sequence_canvas_size(scene)
          return Raylib::Vector2.new(
            x: vector.x * scene.logical_width.to_f32 / canvas[0].to_f32,
            y: vector.y * scene.logical_height.to_f32 / canvas[1].to_f32
          )
        end

        vector
      end

      private def get_color(action : ActionInstance, key : String) : Raylib::Color?
        if data = action.data.params[key]?
          if arr = data.as_a?
            return Raylib::Color.new(
              r: arr[0]?.try(&.as_i.to_u8) || 0u8,
              g: arr[1]?.try(&.as_i.to_u8) || 0u8,
              b: arr[2]?.try(&.as_i.to_u8) || 0u8,
              a: arr[3]?.try(&.as_i.to_u8) || 255u8
            )
          end
        end
        nil
      end

      private def sequence_canvas_size(scene : Scenes::Scene) : Tuple(Int32, Int32)?
        variables = @engine.active_script_runner.try(&.variables) || scene.script_runner.try(&.variables)
        return unless variables

        width = yaml_any_to_int(variables["sequence_canvas_width"]?)
        height = yaml_any_to_int(variables["sequence_canvas_height"]?)
        return unless width && height
        return if width <= 0 || height <= 0

        {width, height}
      end

      private def yaml_any_to_int(value : YAML::Any?) : Int32?
        return unless value

        case value.raw
        when Int64
          value.as_i.to_i32
        when Float64
          value.as_f.to_i32
        else
          nil
        end
      end

      private def configure_overlay_canvas(overlay_mgr : ActionOverlayManager)
        if scene = @engine.current_scene
          if canvas = sequence_canvas_size(scene)
            overlay_mgr.set_canvas(canvas[0], canvas[1])
            return
          end
        end

        overlay_mgr.set_canvas(Raylib.get_screen_width, Raylib.get_screen_height)
      end

      private def resolve_scene_path(path : String) : String
        if scene = @engine.current_scene
          base = scene.base_dir
          base.empty? ? path : File.join(base, path)
        else
          path
        end
      end

      private def parse_direction(dir : String) : Characters::Direction
        case dir.downcase
        when "left"  then Characters::Direction::Left
        when "right" then Characters::Direction::Right
        when "up"    then Characters::Direction::Up
        when "down"  then Characters::Direction::Down
        else              Characters::Direction::Right
        end
      end

      private def calculate_entry_position(from : String, to : Raylib::Vector2?, scene : Scenes::Scene) : Raylib::Vector2
        target_y = to.try(&.y) || 300f32
        if hotspot = scene.hotspot_manager.try(&.get_hotspot_by_name(from))
          return Raylib::Vector2.new(
            x: hotspot.position.x + hotspot.size.x / 2.0f32,
            y: hotspot.position.y + hotspot.size.y
          )
        end

        case from.downcase
        when "left"   then Raylib::Vector2.new(x: -50f32, y: target_y)
        when "right"  then Raylib::Vector2.new(x: scene.logical_width.to_f32 + 50, y: target_y)
        when "top"    then Raylib::Vector2.new(x: to.try(&.x) || 400f32, y: -50f32)
        when "bottom" then Raylib::Vector2.new(x: to.try(&.x) || 400f32, y: scene.logical_height.to_f32 + 50)
        else               Raylib::Vector2.new(x: -50f32, y: target_y)
        end
      end

      private def calculate_exit_position(direction : String, current : Raylib::Vector2, scene : Scenes::Scene) : Raylib::Vector2
        case direction.downcase
        when "left"   then Raylib::Vector2.new(x: -50f32, y: current.y)
        when "right"  then Raylib::Vector2.new(x: scene.logical_width.to_f32 + 50, y: current.y)
        when "top"    then Raylib::Vector2.new(x: current.x, y: -50f32)
        when "bottom" then Raylib::Vector2.new(x: current.x, y: scene.logical_height.to_f32 + 50)
        else               Raylib::Vector2.new(x: -50f32, y: current.y)
        end
      end

      private def resolve_focus_target(action : ActionInstance, scene : Scenes::Scene) : Raylib::Vector2?
        if focus = get_scene_vector2(action, "focus", scene)
          return focus
        end

        focus_name = get_string(action, "focus")
        return if focus_name.empty?

        if character = scene.get_character(focus_name)
          character.position
        elsif hotspot = scene.hotspot_manager.try(&.get_hotspot_by_name(focus_name))
          Raylib::Vector2.new(
            x: hotspot.position.x + hotspot.size.x / 2.0f32,
            y: hotspot.position.y + hotspot.size.y / 2.0f32
          )
        end
      end
    end
  end
end
