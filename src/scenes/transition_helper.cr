# Helper module for parsing and executing scene transitions using the new graphics system

module PointClickEngine
  module Scenes
    module TransitionHelper
      # Parse transition command from action string
      # Format: "transition:scene_name:effect:duration:x,y"
      # Example: "transition:garden:swirl:4.5:300,400"
      # If duration is omitted or "default", it will return -1.0 to signal use of scene's default
      def self.parse_transition_command(command : String) : NamedTuple(scene: String, effect: Graphics::Effects::SceneEffects::TransitionType?, duration: Float32, position: RL::Vector2?)?
        return nil unless command.starts_with?("transition:")

        parts = command.split(":")
        return nil if parts.size < 2

        scene_name = parts[1]

        # Parse optional effect (default to fade)
        effect = if parts.size > 2 && !parts[2].empty?
                   parse_effect(parts[2])
                 else
                   Graphics::Effects::SceneEffects::TransitionType::Fade
                 end

        # Parse optional duration
        # If omitted, empty, or "default", return -1.0 to signal scene default should be used
        duration = if parts.size > 3 && !parts[3].empty?
                     if parts[3] == "default"
                       -1.0f32
                     else
                       parts[3].to_f32? || -1.0f32
                     end
                   else
                     -1.0f32
                   end

        # Parse optional position
        position = if parts.size > 4 && !parts[4].empty?
                     if coords = parts[4].split(",")
                       if coords.size == 2
                         x = coords[0].to_f32?
                         y = coords[1].to_f32?
                         if x && y
                           RL::Vector2.new(x: x, y: y)
                         end
                       end
                     end
                   end

        {scene: scene_name, effect: effect, duration: duration, position: position}
      end

      # Execute a transition command using the new graphics system
      def self.execute_transition(command : String, engine : Core::Engine) : Bool
        puts "[TransitionHelper] Executing command: #{command}"
        if data = parse_transition_command(command)
          puts "[TransitionHelper] Parsed: scene=#{data[:scene]}, effect=#{data[:effect]}, duration=#{data[:duration]}, position=#{data[:position]}"
          duration = data[:duration]

          # If duration is -1.0, use the current scene's default duration
          if duration < 0 && (scene = engine.current_scene)
            duration = scene.default_transition_duration
            puts "[TransitionHelper] Using scene default duration: #{duration}"
          elsif duration < 0
            duration = 1.0f32 # Fallback if no scene
            puts "[TransitionHelper] Using fallback duration: #{duration}"
          end

          puts "[TransitionHelper] Calling engine.change_scene_with_transition"
          engine.change_scene_with_transition(data[:scene], data[:effect], duration, data[:position])
          true
        else
          puts "[TransitionHelper] Failed to parse command"
          false
        end
      end

      private def self.parse_effect(effect_name : String) : Graphics::Effects::SceneEffects::TransitionType?
        case effect_name.downcase
        when "fade"         then Graphics::Effects::SceneEffects::TransitionType::Fade
        when "dissolve"     then Graphics::Effects::SceneEffects::TransitionType::Dissolve
        when "slide_left"   then Graphics::Effects::SceneEffects::TransitionType::SlideLeft
        when "slide_right"  then Graphics::Effects::SceneEffects::TransitionType::SlideRight
        when "slide_up"     then Graphics::Effects::SceneEffects::TransitionType::SlideUp
        when "slide_down"   then Graphics::Effects::SceneEffects::TransitionType::SlideDown
        when "iris"         then Graphics::Effects::SceneEffects::TransitionType::Iris
        when "swirl"        then Graphics::Effects::SceneEffects::TransitionType::Swirl
        when "star_wipe"    then Graphics::Effects::SceneEffects::TransitionType::StarWipe
        when "heart_wipe"   then Graphics::Effects::SceneEffects::TransitionType::HeartWipe
        when "curtain"      then Graphics::Effects::SceneEffects::TransitionType::Curtain
        when "ripple"       then Graphics::Effects::SceneEffects::TransitionType::Ripple
        when "checkerboard" then Graphics::Effects::SceneEffects::TransitionType::Checkerboard
        when "pixelate"     then Graphics::Effects::SceneEffects::TransitionType::Pixelate
        when "warp"         then Graphics::Effects::SceneEffects::TransitionType::Warp
        when "wave"         then Graphics::Effects::SceneEffects::TransitionType::Wave
        when "glitch"       then Graphics::Effects::SceneEffects::TransitionType::Glitch
        when "film_burn"    then Graphics::Effects::SceneEffects::TransitionType::FilmBurn
        when "static"       then Graphics::Effects::SceneEffects::TransitionType::Static
        when "matrix_rain"  then Graphics::Effects::SceneEffects::TransitionType::MatrixRain
        when "zoom_blur"    then Graphics::Effects::SceneEffects::TransitionType::ZoomBlur
        when "clock_wipe"   then Graphics::Effects::SceneEffects::TransitionType::ClockWipe
        when "barn_door"    then Graphics::Effects::SceneEffects::TransitionType::BarnDoor
        when "page_turn"    then Graphics::Effects::SceneEffects::TransitionType::PageTurn
        when "shatter"      then Graphics::Effects::SceneEffects::TransitionType::Shatter
        when "vortex"       then Graphics::Effects::SceneEffects::TransitionType::Vortex
        when "fire"         then Graphics::Effects::SceneEffects::TransitionType::Fire
        else
          nil
        end
      end
    end
  end
end