# Helper module for parsing and executing scene transitions
require "../graphics/transitions/transition_effect"

module PointClickEngine
  module Scenes
    module TransitionHelper
      # Parse transition command from action string
      # Format: "transition:scene_name:effect:duration:x,y"
      # Example: "transition:garden:swirl:4.5:300,400"
      # If duration is omitted or "default", it will return -1.0 to signal use of scene's default
      def self.parse_transition_command(command : String) : NamedTuple(scene: String, effect: Graphics::TransitionEffect?, duration: Float32, position: RL::Vector2?)?
        return nil unless command.starts_with?("transition:")

        parts = command.split(":")
        return nil if parts.size < 2

        scene_name = parts[1]

        # Parse optional effect (default to fade)
        effect = if parts.size > 2 && !parts[2].empty?
                   parse_effect(parts[2])
                 else
                   Graphics::TransitionEffect::Fade
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

      # Execute a transition command
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

      private def self.parse_effect(effect_name : String) : Graphics::TransitionEffect?
        case effect_name.downcase
        when "fade"         then Graphics::TransitionEffect::Fade
        when "dissolve"     then Graphics::TransitionEffect::Dissolve
        when "slide_left"   then Graphics::TransitionEffect::SlideLeft
        when "slide_right"  then Graphics::TransitionEffect::SlideRight
        when "slide_up"     then Graphics::TransitionEffect::SlideUp
        when "slide_down"   then Graphics::TransitionEffect::SlideDown
        when "iris"         then Graphics::TransitionEffect::Iris
        when "swirl"        then Graphics::TransitionEffect::Swirl
        when "star_wipe"    then Graphics::TransitionEffect::StarWipe
        when "heart_wipe"   then Graphics::TransitionEffect::HeartWipe
        when "curtain"      then Graphics::TransitionEffect::Curtain
        when "ripple"       then Graphics::TransitionEffect::Ripple
        when "checkerboard" then Graphics::TransitionEffect::Checkerboard
        when "pixelate"     then Graphics::TransitionEffect::Pixelate
        when "warp"         then Graphics::TransitionEffect::Warp
        when "wave"         then Graphics::TransitionEffect::Wave
        when "glitch"       then Graphics::TransitionEffect::Glitch
        when "film_burn"    then Graphics::TransitionEffect::FilmBurn
        when "static"       then Graphics::TransitionEffect::Static
        when "matrix_rain"  then Graphics::TransitionEffect::MatrixRain
        when "zoom_blur"    then Graphics::TransitionEffect::ZoomBlur
        when "clock_wipe"   then Graphics::TransitionEffect::ClockWipe
        when "barn_door"    then Graphics::TransitionEffect::BarnDoor
        when "page_turn"    then Graphics::TransitionEffect::PageTurn
        when "shatter"      then Graphics::TransitionEffect::Shatter
        when "vortex"       then Graphics::TransitionEffect::Vortex
        when "fire"         then Graphics::TransitionEffect::Fire
        else
          nil
        end
      end
    end
  end
end
