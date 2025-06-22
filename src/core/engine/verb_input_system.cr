# Verb-based input system for point-and-click interactions

require "../../ui/cursor_manager"
require "../../scenes/scene"
require "../../scenes/hotspot"
require "../../characters/character"
require "../../inventory/inventory_system"
require "../../ui/dialog_manager"
require "../../audio/sound_system"

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
        def process_input(scene : Scenes::Scene?, player : Characters::Character?, display_manager : Graphics::DisplayManager?)
          return unless @enabled
          return unless scene
          return unless display_manager
          
          # Handle keyboard input first
          handle_keyboard_input
          
          raw_mouse = RL.get_mouse_position
          return unless display_manager.is_in_game_area(raw_mouse)
          
          game_mouse = display_manager.screen_to_game(raw_mouse)
          
          # Update cursor manager
          @cursor_manager.update(game_mouse, scene, @engine.inventory)
          
          # Handle left click - execute current verb
          if RL.mouse_button_pressed?(RL::MouseButton::Left)
            handle_verb_click(scene, player, game_mouse)
          end
          
          # Handle right click - always look
          if RL.mouse_button_pressed?(RL::MouseButton::Right)
            handle_look_click(scene, game_mouse)
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
            if player
              character.on_interact(player)
            end
          when .look?
            show_description("It's #{character.name}.")
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
          show_message("I can't open that.")
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
          @engine.transition_manager.try do |tm|
            effect = map_transition_type(exit_zone.transition_type, exit_zone.position)
            
            # Use longer transition duration for dramatic effect
            transition_duration = 2.5f32
            
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
          # Handle common keyboard shortcuts
          if RL.key_pressed?(RL::KeyboardKey::Escape)
            # Toggle pause menu instead of exiting game
            if menu_system = @engine.system_manager.menu_system
              menu_system.toggle_pause_menu
            end
          end

          if RL.key_pressed?(RL::KeyboardKey::F11)
            @engine.toggle_fullscreen
          end

          if RL.key_pressed?(RL::KeyboardKey::F1)
            # Toggle debug mode
            PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
            puts "Debug mode: #{PointClickEngine::Core::Engine.debug_mode}"
          end

          if RL.key_pressed?(RL::KeyboardKey::Tab)
            @engine.toggle_hotspot_highlight
            puts "Hotspot highlight: #{@engine.render_coordinator.hotspot_highlight_enabled}"
          end
          
          if RL.key_pressed?(RL::KeyboardKey::I)
            @engine.inventory.toggle_visibility
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