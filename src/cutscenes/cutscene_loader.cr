# Cutscene Loader - Loads cutscenes from YAML files
# Supports a comprehensive set of cinematic actions

require "yaml"
require "./cutscene"
require "./cutscene_action"
require "../assets/asset_loader"
require "../core/exceptions"

module PointClickEngine
  module Cutscenes
    class CutsceneLoader
      # Load a cutscene from a YAML file
      def self.load_from_yaml(path : String, engine : Core::Engine? = nil) : Cutscene
        cutscene_name = File.basename(path, ".yaml")

        begin
          yaml_content = PointClickEngine::AssetLoader.read_yaml(path)
          data = YAML.parse(yaml_content)
        rescue ex
          raise Core::LoadingError.new("Failed to load cutscene file '#{path}': #{ex.message}")
        end

        name = data["name"]?.try(&.as_s) || cutscene_name
        cutscene = Cutscene.new(name)

        # Set cutscene properties
        if skippable = data["skippable"]?
          cutscene.skippable = skippable.as_bool
        end

        # Parse actions
        if actions_data = data["actions"]?
          actions_data.as_a.each do |action_data|
            if action = parse_action(action_data, engine)
              cutscene.add_action(action)
            end
          end
        end

        cutscene
      end

      # Parse a single action from YAML data
      private def self.parse_action(data : YAML::Any, engine : Core::Engine?) : CutsceneAction?
        action_type = data["type"]?.try(&.as_s) || return nil

        case action_type.downcase
        # === TIMING ===
        when "wait"
          duration = get_float(data, "duration", 1.0f32)
          WaitAction.new(duration)

        # === FADING ===
        when "fade_in"
          duration = get_float(data, "duration", 1.0f32)
          color = parse_color(data["color"]?) || Raylib::BLACK
          FadeAction.new(true, color, duration)

        when "fade_out"
          duration = get_float(data, "duration", 1.0f32)
          color = parse_color(data["color"]?) || Raylib::BLACK
          FadeAction.new(false, color, duration)

        when "fade_to_color", "fade_to_black"
          duration = get_float(data, "duration", 1.0f32)
          color = parse_color(data["color"]?) || Raylib::BLACK
          FadeAction.new(false, color, duration)

        when "fade_from_color"
          duration = get_float(data, "duration", 1.0f32)
          color = parse_color(data["color"]?) || Raylib::BLACK
          FadeAction.new(true, color, duration)

        # === TEXT DISPLAY ===
        when "show_text"
          text = data["text"]?.try(&.as_s?) || ""
          font_size = get_int(data, "font_size", 24)
          color = parse_color(data["color"]?) || Raylib::WHITE
          position = data["position"]?.try(&.as_s?) || "center"
          duration = get_float(data, "duration", 3.0f32)
          fade_in = get_float(data, "fade_in", 0.5f32)
          fade_out = get_float(data, "fade_out", 0.5f32)
          glow = data["glow"]?.try(&.as_bool) || false
          glow_color = parse_color(data["glow_color"]?)

          ShowTextAction.new(
            text: text,
            font_size: font_size,
            color: color,
            position: position,
            duration: duration,
            fade_in: fade_in,
            fade_out: fade_out,
            glow: glow,
            glow_color: glow_color
          )

        # === AUDIO ===
        when "play_music"
          track = data["track"]?.try(&.as_s) || return nil
          volume = get_float(data, "volume", 0.7f32)
          fade_in = get_float(data, "fade_in", 0.0f32)
          loop_music = data["loop"]?.try(&.as_bool) != false
          crossfade = data["crossfade"]?.try(&.as_bool) || false

          PlayMusicAction.new(
            track: track,
            volume: volume,
            fade_in_duration: fade_in,
            loop: loop_music,
            crossfade: crossfade
          )

        when "stop_music"
          fade_out = get_float(data, "fade_out", 1.0f32)
          StopMusicAction.new(fade_out)

        when "play_ambient"
          sound = data["sound"]?.try(&.as_s) || return nil
          volume = get_float(data, "volume", 0.5f32)
          fade_in = get_float(data, "fade_in", 0.0f32)

          PlayAmbientAction.new(sound, volume, fade_in)

        when "stop_ambient"
          sound = data["sound"]?.try(&.as_s) || return nil
          fade_out = get_float(data, "fade_out", 1.0f32)

          StopAmbientAction.new(sound, fade_out)

        when "sound_effect"
          sound = data["sound"]?.try(&.as_s) || return nil
          volume = get_float(data, "volume", 1.0f32)
          delay = get_float(data, "delay", 0.0f32)

          SoundEffectAction.new(sound, volume, delay)

        # === SCENE MANAGEMENT ===
        when "change_scene"
          target = data["target"]?.try(&.as_s) || return nil
          transition = data["transition"]?.try(&.as_s) || "fade"
          duration = get_float(data, "duration", 1.0f32)
          ChangeSceneAction.new(target, transition, duration)

        # === CAMERA ===
        when "camera_shake"
          intensity = get_float(data, "intensity", 5.0f32)
          duration = get_float(data, "duration", 0.5f32)
          frequency = get_float(data, "frequency", 10.0f32)

          CameraShakeAction.new(intensity, duration, frequency)

        when "camera_pan"
          target = parse_vector2(data["target"]?) || parse_vector2(data["to"]?)
          from = parse_vector2(data["from"]?)
          duration = get_float(data, "duration", 2.0f32)
          easing = data["easing"]?.try(&.as_s) || "ease_in_out"

          CameraPanAction.new(target, duration, easing, from)

        when "camera_zoom"
          target_zoom = get_float(data, "target", 1.0f32)
          duration = get_float(data, "duration", 1.0f32)
          easing = data["easing"]?.try(&.as_s) || "ease_in_out"
          focus = parse_vector2(data["focus"]?)

          CameraZoomAction.new(target_zoom, duration, easing, focus)

        when "camera_follow"
          character_name = data["character"]?.try(&.as_s) || return nil
          smooth = data["smooth"]?.try(&.as_bool) != false
          offset = parse_vector2(data["offset"]?)

          CameraFollowAction.new(character_name, smooth, offset)

        when "camera_focus"
          target = data["target"]?.try(&.as_s) || return nil
          duration = get_float(data, "duration", 1.0f32)

          CameraFocusAction.new(target, duration)

        # === VISUAL EFFECTS ===
        when "screen_flash"
          color = parse_color(data["color"]?) || Raylib::WHITE
          duration = get_float(data, "duration", 0.1f32)

          ScreenFlashAction.new(color, duration)

        when "screen_effect"
          effect = data["effect"]?.try(&.as_s) || return nil
          intensity = get_float(data, "intensity", 1.0f32)
          duration = get_float(data, "duration", 1.0f32)
          frequency = get_float(data, "frequency", 5.0f32)

          ScreenEffectAction.new(effect, intensity, duration, frequency)

        when "particle_effect"
          effect_type = data["effect"]?.try(&.as_s) || return nil
          # Position can be a vector {x:, y:} or string "fullscreen"
          position_data = data["position"]?
          fullscreen = position_data.try(&.as_s?) == "fullscreen"
          position = if fullscreen
                       nil
                     elsif vec = parse_vector2(position_data)
                       vec
                     else
                       Raylib::Vector2.new(x: 0, y: 0)
                     end
          intensity = get_float(data, "intensity", 1.0f32)
          duration = get_float(data, "duration", 0.0f32)
          color = parse_color(data["color"]?)
          layer = data["layer"]?.try(&.as_s) || "foreground"

          ParticleEffectAction.new(
            effect_type: effect_type,
            position: position,
            fullscreen: fullscreen,
            intensity: intensity,
            duration: duration,
            color: color,
            layer: layer
          )

        when "stop_particle_effect"
          effect = data["effect"]?.try(&.as_s) || "all"
          StopParticleEffectAction.new(effect)

        # === SPRITES ===
        when "show_sprite"
          sprite = data["sprite"]?.try(&.as_s) || return nil
          position = parse_vector2(data["position"]?) || Raylib::Vector2.new(x: 0, y: 0)
          scale = get_float(data, "scale", 1.0f32)
          fade_in = get_float(data, "fade_in", 0.0f32)
          glow = data["glow"]?.try(&.as_bool) || false
          glow_color = parse_color(data["glow_color"]?)
          glow_intensity = get_float(data, "glow_intensity", 1.0f32)
          glow_pulse = data["glow_pulse"]?.try(&.as_bool) || false
          animate = data["animate"]?.try(&.as_bool) || false
          animation_frames = get_int(data, "animation_frames", 1)
          animation_fps = get_int(data, "animation_fps", 8)
          color_tint = parse_color(data["color_tint"]?)

          ShowSpriteAction.new(
            sprite_path: sprite,
            position: position,
            scale: scale,
            fade_in: fade_in,
            glow: glow,
            glow_color: glow_color,
            glow_intensity: glow_intensity,
            glow_pulse: glow_pulse,
            animate: animate,
            animation_frames: animation_frames,
            animation_fps: animation_fps,
            color_tint: color_tint
          )

        when "hide_sprite"
          sprite = data["sprite"]?.try(&.as_s) || return nil
          fade_out = get_float(data, "fade_out", 0.0f32)

          HideSpriteAction.new(sprite, fade_out)

        when "move_sprite"
          sprite = data["sprite"]?.try(&.as_s) || return nil
          target = parse_vector2(data["to"]?) || return nil
          duration = get_float(data, "duration", 1.0f32)
          easing = data["easing"]?.try(&.as_s) || "linear"

          MoveSpriteAction.new(sprite, target, duration, easing)

        when "show_background"
          image = data["image"]?.try(&.as_s) || return nil
          transition = data["transition"]?.try(&.as_s) || "cut"
          duration = get_float(data, "duration", 0.0f32)
          parallax_layer = get_int(data, "parallax_layer", 0)

          ShowBackgroundAction.new(image, transition, duration, parallax_layer)

        # === CHARACTERS ===
        when "character_enter"
          character_name = data["character"]?.try(&.as_s?) || return nil
          # from can be a direction string ("left", "right") or a position vector
          from_data = data["from"]?
          from = from_data.try(&.as_s?) || "left"
          from_position = parse_vector2(from_data)
          to = parse_vector2(data["to"]?) || Raylib::Vector2.new(x: 160, y: 140)
          animation = data["animation"]?.try(&.as_s?) || "walk"
          duration = get_float(data, "duration", 2.0f32)

          CharacterEnterAction.new(character_name, from, to, animation, duration, from_position)

        when "character_exit"
          character_name = data["character"]?.try(&.as_s) || return nil
          direction = data["direction"]?.try(&.as_s) || "left"
          duration = get_float(data, "duration", 2.0f32)

          CharacterExitAction.new(character_name, direction, duration)

        when "character_move"
          character_name = data["character"]?.try(&.as_s) || return nil
          target = parse_vector2(data["target"]?) || return nil
          animation = data["animation"]?.try(&.as_s) || "walk"
          duration = get_float(data, "duration", 0.0f32)

          CharacterMoveAction.new(character_name, target, animation, duration)

        when "character_face"
          character_name = data["character"]?.try(&.as_s) || return nil
          direction = data["direction"]?.try(&.as_s)
          target = data["target"]?.try(&.as_s)

          CharacterFaceAction.new(character_name, direction, target)

        when "character_animation"
          character_name = data["character"]?.try(&.as_s) || return nil
          animation = data["animation"]?.try(&.as_s) || return nil
          duration = get_float(data, "duration", 0.0f32)

          CharacterAnimationAction.new(character_name, animation, duration)

        # === DIALOG ===
        when "floating_dialog"
          character_name = data["character"]?.try(&.as_s) || return nil
          text = data["text"]?.try(&.as_s) || ""
          duration = get_float(data, "duration", 3.0f32)
          style = data["style"]?.try(&.as_s) || "normal"
          shake = data["shake"]?.try(&.as_bool) || false
          shake_intensity = get_float(data, "shake_intensity", 2.0f32)

          FloatingDialogAction.new(
            character_name: character_name,
            text: text,
            duration: duration,
            style: style,
            shake: shake,
            shake_intensity: shake_intensity
          )

        # === UI ===
        when "hide_ui"
          UIVisibilityAction.new(false)

        when "show_ui"
          UIVisibilityAction.new(true)

        when "set_letterbox"
          enabled = data["enabled"]?.try(&.as_bool) != false
          ratio = get_float(data, "ratio", 2.35f32)
          duration = get_float(data, "duration", 0.5f32)

          LetterboxAction.new(enabled, ratio, duration)

        when "enable_player_control"
          EnablePlayerControlAction.new(true)

        when "disable_player_control"
          EnablePlayerControlAction.new(false)

        # === GAME STATE ===
        when "set_game_state"
          flags = [] of String
          variables = {} of String => String | Int32 | Float32 | Bool

          if flags_data = data["flags"]?
            flags_data.as_a.each do |flag|
              flags << flag.as_s
            end
          end

          if vars_data = data["variables"]?
            vars_data.as_h.each do |key, value|
              case value.raw
              when String  then variables[key.as_s] = value.as_s
              when Int64   then variables[key.as_s] = value.as_i.to_i32
              when Float64 then variables[key.as_s] = value.as_f.to_f32
              when Bool    then variables[key.as_s] = value.as_bool
              end
            end
          end

          SetGameStateAction.new(flags, variables)

        else
          puts "[CutsceneLoader] Unknown action type: #{action_type}"
          nil
        end
      end

      # Helper to get a float value with default
      private def self.get_float(data : YAML::Any, key : String, default : Float32) : Float32
        data[key]?.try(&.as_f.to_f32) || default
      end

      # Helper to get an int value with default
      private def self.get_int(data : YAML::Any, key : String, default : Int32) : Int32
        data[key]?.try(&.as_i.to_i32) || default
      end

      # Parse a color from YAML (array of RGBA values)
      private def self.parse_color(data : YAML::Any?) : Raylib::Color?
        return nil unless data

        if data.as_a?
          arr = data.as_a
          return nil if arr.size < 3

          r = arr[0].as_i.to_u8
          g = arr[1].as_i.to_u8
          b = arr[2].as_i.to_u8
          a = arr.size >= 4 ? arr[3].as_i.to_u8 : 255u8

          Raylib::Color.new(r: r, g: g, b: b, a: a)
        else
          nil
        end
      end

      # Parse a Vector2 from YAML
      private def self.parse_vector2(data : YAML::Any?) : Raylib::Vector2?
        return nil unless data

        if data.as_h?
          x = data["x"]?.try(&.as_f.to_f32) || 0f32
          y = data["y"]?.try(&.as_f.to_f32) || 0f32
          Raylib::Vector2.new(x: x, y: y)
        else
          nil
        end
      end
    end
  end
end
