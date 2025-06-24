# Verb-based input system for point-and-click interactions

require "../../ui/cursor_manager"
require "../../scenes/scene"
require "../../scenes/hotspot"
require "../../characters/character"
require "../../inventory/inventory_system"
require "../../ui/dialog_manager"
require "../../audio/sound_system"
require "../../graphics/camera"

module PointClickEngine
  module Core
    module EngineComponents
      # Handles verb-based interactions in point-and-click games
      class VerbInputSystem
        property cursor_manager : UI::CursorManager
        property enabled : Bool = true
        property right_click_verb : UI::VerbType = UI::VerbType::Look

        @engine : Engine
        @verb_handlers : Hash(UI::VerbType, Proc(Scenes::Hotspot, RL::Vector2, Nil))
        @character_verb_handlers : Hash(UI::VerbType, Proc(Characters::Character, Nil))

        def initialize(@engine : Engine)
          @cursor_manager = UI::CursorManager.new
          @verb_handlers = {} of UI::VerbType => Proc(Scenes::Hotspot, RL::Vector2, Nil)
          @character_verb_handlers = {} of UI::VerbType => Proc(Characters::Character, Nil)

          setup_default_handlers
        end

        # Process verb-based input
        def process_input(scene : Scenes::Scene?, player : Characters::Character?, display_manager : Graphics::DisplayManager?, camera : Graphics::Camera? = nil)
          return unless @enabled
          return unless scene
          return unless display_manager

          # Always handle keyboard input for verb selection (this should work even during dialogs)
          handle_keyboard_input

          # Additional safety check: ensure no dialog is consuming mouse input
          if dm = @engine.dialog_manager
            return if dm.dialog_consumed_input?
          end

          raw_mouse = RL.get_mouse_position
          return unless display_manager.is_in_game_area(raw_mouse)

          game_mouse = display_manager.screen_to_game(raw_mouse)

          # Convert to world coordinates if camera exists
          world_mouse = if camera
                          camera.screen_to_world(game_mouse.x.to_i, game_mouse.y.to_i)
                        else
                          game_mouse
                        end

          # Update cursor manager (use screen coordinates for UI)
          @cursor_manager.update(game_mouse, scene, @engine.inventory)

          # Get engine's input manager for consistent consumption checking
          input_manager = @engine.input_manager

          # Handle left click - execute current verb
          if !input_manager.mouse_consumed? && input_manager.mouse_button_pressed?(Raylib::MouseButton::Left)
            handle_verb_click(scene, player, world_mouse)
            input_manager.consume_mouse_input
          end

          # Handle right click - always look (this works even if dialogs are up)
          if input_manager.mouse_button_pressed?(Raylib::MouseButton::Right)
            # Right-click should work even during dialogs for examining things
            handle_look_click(scene, world_mouse)
            input_manager.consume_mouse_input
          end
        end

        # Draw cursor with verb indicator
        def draw(display_manager : Graphics::DisplayManager?)
          return unless display_manager

          raw_mouse = RL.get_mouse_position
          if display_manager.is_in_game_area(raw_mouse)
            game_mouse = display_manager.screen_to_game(raw_mouse)
            @cursor_manager.draw(game_mouse)
          end
        end

        # Register custom verb handler for hotspots
        def register_verb_handler(verb : UI::VerbType, &handler : Scenes::Hotspot, RL::Vector2 ->)
          @verb_handlers[verb] = handler
        end

        # Register custom verb handler for characters
        def register_character_verb_handler(verb : UI::VerbType, &handler : Characters::Character ->)
          @character_verb_handlers[verb] = handler
        end

        private def handle_verb_click(scene : Scenes::Scene, player : Characters::Character?, pos : RL::Vector2)
          verb = @cursor_manager.get_current_action

          # Check inventory first if visible
          if @engine.inventory.visible
            if item = @engine.inventory.get_item_at_position(pos)
              handle_inventory_verb(verb, item)
              return
            end
          end

          # For open verb, prioritize ExitZones (doors should open/transition)
          if verb.open?
            # Look for ExitZones at the clicked position
            exit_zone = scene.hotspots.find { |h| h.is_a?(Scenes::ExitZone) && h.active && h.visible && h.contains_point?(pos) }
            if exit_zone
              execute_verb_on_hotspot(verb, exit_zone, pos, player)
              return
            end
          end

          # Check for hotspot
          if hotspot = scene.get_hotspot_at(pos)
            execute_verb_on_hotspot(verb, hotspot, pos, player)
          elsif character = scene.get_character_at(pos)
            execute_verb_on_character(verb, character, player)
          else
            # No hotspot or character - handle walk
            if verb.walk? && player
              handle_walk_to(player, scene, pos)
            end
          end
        end

        private def handle_look_click(scene : Scenes::Scene, pos : RL::Vector2)
          if hotspot = scene.get_hotspot_at(pos)
            show_description(hotspot.description)
          elsif character = scene.get_character_at(pos)
            show_description("It's #{character.name}.")
          else
            show_description("Nothing interesting here.")
          end
        end

        private def execute_verb_on_hotspot(verb : UI::VerbType, hotspot : Scenes::Hotspot, pos : RL::Vector2, player : Characters::Character?)
          # Check for custom handler first
          if handler = @verb_handlers[verb]?
            handler.call(hotspot, pos)
            return
          end

          # Default verb handling
          case verb
          when .walk?
            handle_walk_verb(hotspot, pos, player)
          when .look?
            handle_look_verb(hotspot, player)
          when .talk?
            show_message("I can't talk to that.")
          when .use?
            handle_use_verb(hotspot, player)
          when .take?
            handle_take_verb(hotspot, player)
          when .open?
            handle_open_verb(hotspot, player)
          else
            show_message("I can't do that.")
          end
        end

        private def execute_verb_on_character(verb : UI::VerbType, character : Characters::Character, player : Characters::Character?)
          # Check for custom handler first
          if handler = @character_verb_handlers[verb]?
            handler.call(character)
            return
          end

          # Default character verb handling
          case verb
          when .talk?
            if character.responds_to?(:on_talk)
              character.on_talk
            elsif player
              character.on_interact(player)
            end
          when .look?
            if character.responds_to?(:on_look)
              character.on_look
            else
              show_description("It's #{character.name}.")
            end
          when .use?
            if character.responds_to?(:on_use)
              character.on_use
            else
              show_message("I can't do that to #{character.name}.")
            end
          else
            show_message("I can't do that to #{character.name}.")
          end
        end

        private def handle_walk_verb(hotspot : Scenes::Hotspot, pos : RL::Vector2, player : Characters::Character?)
          if hotspot.is_a?(Scenes::ExitZone)
            exit_zone = hotspot.as(Scenes::ExitZone)

            # Check if exit is accessible
            if !exit_zone.is_accessible?(@engine.inventory)
              msg = exit_zone.locked_message || "You can't go there yet."
              show_message(msg)
              return
            end

            # Perform the transition
            if exit_zone.auto_walk && player
              # Walk to exit position first
              walk_target = exit_zone.get_walk_target
              player.walk_to(walk_target)

              # Set up callback for when walking is complete
              player.on_walk_complete = -> {
                perform_exit_transition(exit_zone)
              }
            else
              # Immediate transition
              perform_exit_transition(exit_zone)
            end
          elsif player
            handle_walk_to(player, @engine.current_scene.not_nil!, pos)
          end
        end

        private def handle_look_verb(hotspot : Scenes::Hotspot, player : Characters::Character?)
          # Play examine animation if player supports it
          if player && player.responds_to?(:examine_object)
            player.examine_object(hotspot.position)
          end

          show_description(hotspot.description)
        end

        private def handle_use_verb(hotspot : Scenes::Hotspot, player : Characters::Character?)
          # Play use animation if player supports it
          if player && player.responds_to?(:use_item_on_target)
            player.use_item_on_target(hotspot.position)
          end

          # Check if it's an exit zone (treat use as walk)
          if hotspot.is_a?(Scenes::ExitZone)
            handle_walk_verb(hotspot, hotspot.position, player)
          else
            # Call hotspot's on_click handler
            hotspot.on_click.try &.call
          end
        end

        private def handle_take_verb(hotspot : Scenes::Hotspot, player : Characters::Character?)
          # Play pickup animation if player supports it
          if player && player.responds_to?(:pick_up_item)
            player.pick_up_item(hotspot.position)
          end

          # Default take behavior
          show_message("I can't take that.")
        end

        private def handle_open_verb(hotspot : Scenes::Hotspot, player : Characters::Character?)
          # Check if it's an exit zone (like a door)
          if hotspot.is_a?(Scenes::ExitZone)
            handle_walk_verb(hotspot, hotspot.position, player)
          else
            # Call hotspot's on_click handler if available
            if hotspot.on_click
              hotspot.on_click.try &.call
            else
              show_message("I can't open that.")
            end
          end
        end

        private def handle_inventory_verb(verb : UI::VerbType, item : Inventory::InventoryItem)
          case verb
          when .look?
            show_description(item.description)
          when .use?
            # Inventory system will handle item use
          end
        end

        private def handle_walk_to(player : Characters::Character, scene : Scenes::Scene, target : RL::Vector2)
          if player.responds_to?(:use_pathfinding) && player.use_pathfinding && scene.enable_pathfinding
            if path = scene.find_path(player.position.x, player.position.y, target.x, target.y)
              player.walk_to_with_path(path)
            else
              player.walk_to(target)
            end
          elsif player.responds_to?(:handle_click)
            player.handle_click(target, scene)
          else
            player.walk_to(target)
          end
        end

        private def perform_exit_transition(exit_zone : Scenes::ExitZone)
          # Use the integrated transition system with enhanced scene change handling
          if tm = @engine.transition_manager
            effect = map_transition_type(exit_zone.transition_type, exit_zone.position)

            # Use VERY long transition duration for super cheesy dramatic effect!
            transition_duration = 4.5f32

            # Start the transition
            tm.start_transition(effect, transition_duration) do
              # This callback runs at the halfway point of the transition
              # Perfect time to change scenes while screen is obscured

              # Change to the target scene
              @engine.change_scene(exit_zone.target_scene)

              # Set player position in new scene
              if (pos = exit_zone.target_position) && (player = @engine.player)
                player.position = pos
                if player.responds_to?(:stop_walking)
                  player.stop_walking
                end
              end

              # Add player to the new scene
              if new_scene = @engine.current_scene
                if player = @engine.player
                  new_scene.set_player(player)
                end
              end

              # Trigger scene enter callbacks
              @engine.current_scene.try(&.on_enter.try(&.call))

              # Play transition sound if available
              @engine.audio_manager.try &.play_sound_effect("transition")
            end
          else
            # Fallback to immediate scene change
            @engine.change_scene(exit_zone.target_scene)
            if (pos = exit_zone.target_position) && (player = @engine.player)
              player.position = pos
            end
          end
        end

        private def map_transition_type(transition_type : Scenes::TransitionType, position : RL::Vector2) : Graphics::TransitionEffect
          case transition_type
          when .fade?
            Graphics::TransitionEffect::Fade
          when .slide?
            # Choose slide direction based on exit position
            if position.x < 100
              Graphics::TransitionEffect::SlideLeft
            elsif position.x > 900
              Graphics::TransitionEffect::SlideRight
            elsif position.y < 100
              Graphics::TransitionEffect::SlideUp
            else
              Graphics::TransitionEffect::SlideDown
            end
          when .iris?
            Graphics::TransitionEffect::Iris
          when .swirl?
            Graphics::TransitionEffect::Swirl
          when .star_wipe?
            Graphics::TransitionEffect::StarWipe
          when .heart_wipe?
            Graphics::TransitionEffect::HeartWipe
          when .curtain?
            Graphics::TransitionEffect::Curtain
          when .ripple?
            Graphics::TransitionEffect::Ripple
          when .checkerboard?
            Graphics::TransitionEffect::Checkerboard
          when .warp?
            Graphics::TransitionEffect::Warp
          when .matrix_rain?
            Graphics::TransitionEffect::MatrixRain
          when .vortex?
            Graphics::TransitionEffect::Vortex
          when .page_turn?
            Graphics::TransitionEffect::PageTurn
          when .fire?
            Graphics::TransitionEffect::Fire
          else
            Graphics::TransitionEffect::Fade
          end
        end

        private def show_message(text : String)
          @engine.dialog_manager.try &.show_message(text)
        end

        private def show_description(text : String)
          @engine.dialog_manager.try &.show_message(text)
        end

        private def setup_default_handlers
          # Games can override these handlers as needed
        end

        # Handle keyboard input for debug and UI toggles
        private def handle_keyboard_input
          # Get the engine's input manager for consistent consumption checking
          input_manager = @engine.input_manager

          # Skip keyboard shortcuts that are handled by higher priority handlers
          # Only handle verb-specific keys and inventory toggle

          if input_manager.key_pressed?(Raylib::KeyboardKey::I)
            @engine.inventory.toggle_visibility
          end

          # Verb selection with number keys (these are verb-specific, not global shortcuts)
          if input_manager.key_pressed?(Raylib::KeyboardKey::One)
            @cursor_manager.set_verb(UI::VerbType::Walk)
          elsif input_manager.key_pressed?(Raylib::KeyboardKey::Two)
            @cursor_manager.set_verb(UI::VerbType::Look)
          elsif input_manager.key_pressed?(Raylib::KeyboardKey::Three)
            @cursor_manager.set_verb(UI::VerbType::Talk)
          elsif input_manager.key_pressed?(Raylib::KeyboardKey::Four)
            @cursor_manager.set_verb(UI::VerbType::Use)
          elsif input_manager.key_pressed?(Raylib::KeyboardKey::Five)
            @cursor_manager.set_verb(UI::VerbType::Take)
          elsif input_manager.key_pressed?(Raylib::KeyboardKey::Six)
            @cursor_manager.set_verb(UI::VerbType::Open)
          end

          # Mouse wheel to cycle through verbs (this is verb-specific)
          if RL.get_mouse_wheel_move > 0
            @cursor_manager.cycle_verb_forward
          elsif RL.get_mouse_wheel_move < 0
            @cursor_manager.cycle_verb_backward
          end
        end

        # Clean up resources
        def cleanup
          @cursor_manager.cleanup
        end
      end
    end
  end
end
