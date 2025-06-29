# Engine input processing and click handling

require "../../scenes/scene"
require "../../characters/character"
require "../../graphics/camera"

module PointClickEngine
  module Core
    module EngineComponents
      # Handles input processing and click coordination
      class InputHandler
        property handle_clicks : Bool = true

        def initialize
        end

        # Process mouse clicks in the current scene
        def handle_click(scene : Scenes::Scene?, player : Characters::Character?, camera : Graphics::Camera? = nil)
          return unless @handle_clicks
          return unless scene
          return unless RL.mouse_button_pressed?(RL::MouseButton::Left)

          mouse_pos = RL.get_mouse_position

          # Convert screen coordinates to world coordinates if camera exists
          world_pos = if camera
                        camera.screen_to_world(mouse_pos.x.to_i, mouse_pos.y.to_i)
                      else
                        mouse_pos
                      end

          # Check if any hotspot was clicked (using world coordinates)
          clicked_hotspot = scene.get_hotspot_at(world_pos)

          if clicked_hotspot
            clicked_hotspot.on_click.try(&.call)
          else
            # Check if any character was clicked (using world coordinates)
            clicked_character = scene.get_character_at(world_pos)

            if clicked_character
              # Handle character interaction (e.g., talk to character)
              if player && clicked_character.responds_to?(:on_interact)
                # Character interaction with player as interactor
                clicked_character.on_interact(player)
              elsif clicked_character.responds_to?(:on_talk)
                # Fallback to talk interaction
                clicked_character.on_talk
              else
                # Default character interaction - show dialog or description
                if engine = Engine.instance
                  # Check if character has a dialog tree
                  if dialog_manager = engine.system_manager.dialog_manager
                    if dialog_manager.has_dialog?(clicked_character.name)
                      # Start character's dialog tree
                      dialog_manager.start_dialog(clicked_character.name)
                    else
                      # Show default interaction message
                      dialog_manager.show_message(
                        "#{player.try(&.name) || "You"}: I should talk to #{clicked_character.name}."
                      )
                    end
                  else
                    # Fallback: just log the interaction
                    puts "Clicked on character: #{clicked_character.name}"
                  end
                end
              end
            else
              # Move player to clicked position if no hotspot or character (using world coordinates)
              if player
                if player.responds_to?(:handle_click)
                  player.handle_click(world_pos, scene)
                end
              end
            end
          end
        end

        # Process keyboard input
        def handle_keyboard_input
          # Handle common keyboard shortcuts
          if RL.key_pressed?(RL::KeyboardKey::Escape)
            handle_escape_key
          end

          if RL.key_pressed?(RL::KeyboardKey::F11)
            handle_fullscreen_toggle
          end

          if RL.key_pressed?(RL::KeyboardKey::F1)
            handle_debug_toggle
          end

          if RL.key_pressed?(RL::KeyboardKey::Tab)
            handle_hotspot_highlight_toggle
          end

          # Camera edge scrolling toggle (F5)
          if RL.key_pressed?(RL::KeyboardKey::F5)
            handle_edge_scroll_toggle
          end
        end

        # Handle right-click for context menu/verb selection
        def handle_right_click(scene : Scenes::Scene?, camera : Graphics::Camera? = nil)
          return unless scene
          return unless RL.mouse_button_pressed?(RL::MouseButton::Right)

          mouse_pos = RL.get_mouse_position

          # Convert screen coordinates to world coordinates if camera exists
          world_pos = if camera
                        camera.screen_to_world(mouse_pos.x.to_i, mouse_pos.y.to_i)
                      else
                        mouse_pos
                      end

          clicked_hotspot = scene.get_hotspot_at(world_pos)

          if clicked_hotspot
            # Show context menu or verb selection for hotspot
            handle_hotspot_context_menu(clicked_hotspot, mouse_pos)
          end
        end

        # Process all input types
        def process_input(scene : Scenes::Scene?, player : Characters::Character?, camera : Graphics::Camera? = nil)
          handle_keyboard_input
          handle_click(scene, player, camera)
          handle_right_click(scene, camera)
        end

        private def handle_escape_key
          # Toggle pause menu instead of exiting
          if menu_system = Engine.instance.menu_system
            menu_system.toggle_pause_menu
          end
        end

        private def handle_fullscreen_toggle
          # Toggle fullscreen mode
          puts "F11 - Fullscreen toggle requested"
        end

        private def handle_debug_toggle
          # Toggle debug mode
          PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
          puts "F1 pressed - Debug mode: #{PointClickEngine::Core::Engine.debug_mode}"
        end

        private def handle_hotspot_context_menu(hotspot, position : RL::Vector2)
          # Show context menu for hotspot
          puts "Right-clicked on hotspot: #{hotspot.name}"
        end

        private def handle_hotspot_highlight_toggle
          # Toggle hotspot highlighting
          puts "Tab pressed - Toggling hotspot highlighting"
          Engine.instance.toggle_hotspot_highlight
        end

        private def handle_edge_scroll_toggle
          if engine = Engine.instance
            if camera = engine.camera_manager.current_camera
              camera.edge_scroll_enabled = !camera.edge_scroll_enabled
              puts "Camera edge scrolling: #{camera.edge_scroll_enabled ? "enabled" : "disabled"}"
            end
          end
        end
      end
    end
  end
end
