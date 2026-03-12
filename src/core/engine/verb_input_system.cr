# Verb-based input system for point-and-click interactions

require "../../ui/cursor_manager"
require "../../scenes/scene"
require "../../scenes/hotspot"
require "../../characters/character"
require "../../inventory/inventory_system"
require "../../ui/dialog_manager"
require "../../audio/audio_manager"
require "../../graphics/graphics"
require "../events/game_events"

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
        def process_input(scene : Scenes::Scene?, player : Characters::Character?, display_manager : Graphics::Display?, camera : Graphics::Camera? = nil)
          return unless @enabled
          return unless scene
          return unless display_manager

          # Always handle keyboard input for verb selection (this should work even during dialogs)
          handle_keyboard_input

          # Block mouse input if a dialog is active - let the dialog handle clicks
          if dm = @engine.dialog_manager
            return if dm.is_dialog_active?
          end

          raw_mouse = RL.get_mouse_position
          return unless display_manager.in_game_area?(raw_mouse)

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

          # Skip input processing if player control is disabled (during action sequences)
          return unless @engine.player_control_enabled

          # Handle left click - execute current verb
          if input_manager.mouse_button_pressed?(Raylib::MouseButton::Left)
            if !input_manager.mouse_consumed?
              handle_verb_click(scene, player, world_mouse)
              input_manager.consume_mouse_input
            end
          end

          # Handle right click - always look (this works even if dialogs are up)
          if input_manager.mouse_button_pressed?(Raylib::MouseButton::Right)
            # Right-click should work even during dialogs for examining things
            handle_look_click(scene, world_mouse)
            input_manager.consume_mouse_input
          end
        end

        # Draw cursor with verb indicator
        def draw(display_manager : Graphics::Display?, suppressed : Bool = false)
          return unless display_manager
          if suppressed
            RL.show_cursor
            return
          end

          raw_mouse = RL.get_mouse_position
          if display_manager.in_game_area?(raw_mouse)
            @cursor_manager.draw(raw_mouse)
          else
            RL.show_cursor
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

          # Check for hotspot
          if hotspot = scene.get_hotspot_at(pos)
            puts "[VerbInput] Found hotspot: #{hotspot.name}"
            execute_verb_on_hotspot(verb, hotspot, pos, player)
          elsif character = scene.get_character_at(pos)
            puts "[VerbInput] Found character: #{character.name}"
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
          verb_name = verb.to_s.downcase

          # Publish HotspotClickedEvent to EventBus for script handlers
          @engine.event_bus.publish(Events::HotspotClickedEvent.new(hotspot.name, verb_name, pos))

          # Check for action commands first (like scene transitions)
          puts "[VerbInput] Checking action for verb: #{verb_name} on hotspot: #{hotspot.name}"
          if command = hotspot.action_commands[verb_name]?
            puts "[VerbInput] Found action command: #{command}"
            
            # Parse command based on prefix
            # Supported prefixes:
            #   transition:scene:type:duration:x,y - Scene transition
            #   script: or lua: - Execute as Lua code
            #   (no prefix) - Display as plain text message
            if command.starts_with?("transition:")
              parts = command.split(":")
              if parts.size >= 2
                scene_name = parts[1]
                transition_type = parts.size > 2 ? parts[2] : "fade"
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

                # Use the scene manager's transition method
                @engine.scene_manager.change_scene_with_transition(scene_name, transition_type, duration, position)

                puts "[VerbInput] Transition executed successfully"
                return
              end
            elsif command.starts_with?("script:") || command.starts_with?("lua:")
              # Extract script code after prefix
              script_code = command.sub(/^(script|lua):/, "").strip
              puts "[VerbInput] Executing script: #{script_code}"
              @engine.system_manager.script_engine.try(&.execute_script(script_code))
            else
              # Plain text - display as message
              puts "[VerbInput] Displaying message: #{command}"
              show_message(command)
            end
          else
            puts "[VerbInput] No action command for verb #{verb_name}"
          end

          # Check for custom handler
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
          verb_name = verb.to_s.downcase

          # Publish CharacterInteractEvent to EventBus for script handlers
          target = player.try(&.name) || "player"
          @engine.event_bus.publish(Events::CharacterInteractEvent.new(character.name, target, verb_name))

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
          if player
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

          # Call hotspot's on_click handler
          hotspot.on_click.try &.call
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
          # Call hotspot's on_click handler if available
          if hotspot.on_click
            hotspot.on_click.try &.call
          else
            show_message("I can't open that.")
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
          puts "[VerbInput] handle_walk_to - player type: #{player.class.name}"
          # Always use handle_click if available, let it handle pathfinding
          if player.responds_to?(:handle_click)
            puts "[VerbInput] Player responds to handle_click, calling it"
            player.handle_click(target, scene)
          else
            puts "[VerbInput] Player doesn't respond to handle_click, calling walk_to"
            player.walk_to(target)
          end
        end

        private def show_message(text : String)
          @engine.dialog_manager.try &.show_message(text)
        end

        private def show_description(text : String)
          @engine.dialog_manager.try &.show_message(text)
        end

        private def setup_default_handlers
          # Default movement handler - allows click-to-move when no verb is selected
          # or when using a movement verb like Walk
          @verb_handlers[UI::VerbType::Walk] = ->(hotspot : Scenes::Hotspot, position : RL::Vector2) {
            # Movement is handled below in the main input processing
          }
        end

        # Handle keyboard input for debug and UI toggles
        private def handle_keyboard_input
          # Get the engine's input manager for consistent consumption checking
          input_manager = @engine.input_manager

          # Skip keyboard shortcuts that are handled by higher priority handlers
          # Only handle verb-specific keys and inventory toggle

          if input_manager.key_pressed?(Raylib::KeyboardKey::I)
            @engine.inventory.toggle_visibility
            puts "[VerbInput] Inventory toggled, visible: #{@engine.inventory.visible}, items: #{@engine.inventory.items.size}"
          end

          # Tab to highlight hotspots
          if input_manager.key_pressed?(Raylib::KeyboardKey::Tab)
            @engine.toggle_hotspot_highlight
          end

          # F1 for debug mode
          if input_manager.key_pressed?(Raylib::KeyboardKey::F1)
            Core::Engine.debug_mode = !Core::Engine.debug_mode
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
