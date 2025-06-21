# Engine input processing and click handling

require "raylib-cr"
require "../../scenes/scene"
require "../../characters/character"

module PointClickEngine
  module Core
    module EngineComponents
      # Handles input processing and click coordination
      class InputHandler
        property handle_clicks : Bool = true

        def initialize
        end

        # Process mouse clicks in the current scene
        def handle_click(scene : Scenes::Scene?, player : Characters::Character?)
          return unless @handle_clicks
          return unless scene
          return unless RL.mouse_button_pressed?(RL::MouseButton::Left)

          mouse_pos = RL.get_mouse_position

          # Check if any hotspot was clicked
          clicked_hotspot = scene.get_hotspot_at_position(mouse_pos)

          if clicked_hotspot
            clicked_hotspot.on_click.try(&.call)
          else
            # Move player to clicked position if no hotspot
            if player
              if player.responds_to?(:handle_click)
                player.handle_click(mouse_pos, scene)
              end
            end
          end
        end

        # Process keyboard input
        def handle_keyboard_input
          # Handle common keyboard shortcuts
          if RL.key_pressed?(RL::Key::Escape)
            handle_escape_key
          end

          if RL.key_pressed?(RL::Key::F11)
            handle_fullscreen_toggle
          end

          if RL.key_pressed?(RL::Key::F1)
            handle_debug_toggle
          end
        end

        # Handle right-click for context menu/verb selection
        def handle_right_click(scene : Scenes::Scene?)
          return unless scene
          return unless RL.mouse_button_pressed?(RL::MouseButton::Right)

          mouse_pos = RL.get_mouse_position
          clicked_hotspot = scene.get_hotspot_at_position(mouse_pos)

          if clicked_hotspot
            # Show context menu or verb selection for hotspot
            handle_hotspot_context_menu(clicked_hotspot, mouse_pos)
          end
        end

        # Process all input types
        def process_input(scene : Scenes::Scene?, player : Characters::Character?)
          handle_keyboard_input
          handle_click(scene, player)
          handle_right_click(scene)
        end

        private def handle_escape_key
          # Could open pause menu, exit dialog, etc.
          puts "Escape key pressed"
        end

        private def handle_fullscreen_toggle
          # Toggle fullscreen mode
          puts "F11 - Fullscreen toggle requested"
        end

        private def handle_debug_toggle
          # Toggle debug mode
          PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
          puts "Debug mode: #{PointClickEngine::Core::Engine.debug_mode}"
        end

        private def handle_hotspot_context_menu(hotspot, position : RL::Vector2)
          # Show context menu for hotspot
          puts "Right-clicked on hotspot: #{hotspot.name}"
        end
      end
    end
  end
end
