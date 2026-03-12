# Helper module for parsing and handling transition commands
#
# Transition command format: "transition:scene_name:effect_type:duration:x,y"
# Example: "transition:garden:swirl:1.5:100,300"

require "../graphics/effects/scene_effects/transition_effect"

module PointClickEngine
  module Scenes
    module TransitionHelper
      # Result of parsing a transition command
      alias TransitionResult = NamedTuple(
        scene: String,
        effect: Graphics::Effects::SceneEffects::TransitionType,
        duration: Float32,
        position: RL::Vector2?
      )

      # Parse a transition command string into its components
      # Returns nil if the command is not a valid transition command
      def self.parse_transition_command(command : String) : TransitionResult?
        return nil unless command.starts_with?("transition:")

        parts = command.split(":")
        return nil if parts.size < 2

        scene_name = parts[1]
        effect_name = parts.size > 2 ? parts[2] : "fade"
        duration = parts.size > 3 ? (parts[3].to_f32? || 1.0f32) : 1.0f32

        # Parse position if provided
        position = if parts.size > 4
          coords = parts[4].split(",")
          if coords.size == 2
            x = coords[0].to_f32?
            y = coords[1].to_f32?
            RL::Vector2.new(x: x || 0, y: y || 0) if x && y
          end
        end

        # Parse effect type
        effect = parse_effect_type(effect_name)

        {
          scene: scene_name,
          effect: effect,
          duration: duration,
          position: position
        }
      end

      # Check if a command is a transition command
      def self.transition_command?(command : String) : Bool
        command.starts_with?("transition:")
      end

      # Parse effect type name to enum
      def self.parse_effect_type(effect_name : String) : Graphics::Effects::SceneEffects::TransitionType
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
        when "checkerboard" then Graphics::Effects::SceneEffects::TransitionType::Checkerboard
        when "clock_wipe"   then Graphics::Effects::SceneEffects::TransitionType::ClockWipe
        when "barn_door"    then Graphics::Effects::SceneEffects::TransitionType::BarnDoor
        else Graphics::Effects::SceneEffects::TransitionType::Fade
        end
      end

      # Build a transition command string from components
      def self.build_command(scene : String,
                            effect : Graphics::Effects::SceneEffects::TransitionType = Graphics::Effects::SceneEffects::TransitionType::Fade,
                            duration : Float32 = 1.0f32,
                            position : RL::Vector2? = nil) : String
        effect_name = effect.to_s.downcase
        cmd = "transition:#{scene}:#{effect_name}:#{duration}"
        if pos = position
          cmd += ":#{pos.x.to_i},#{pos.y.to_i}"
        end
        cmd
      end
    end
  end
end
