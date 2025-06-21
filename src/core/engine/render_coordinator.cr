# Engine rendering coordination and debug visualization

require "../../scenes/scene"
require "../../ui/dialog"
require "../../cutscenes/cutscene_manager"

module PointClickEngine
  module Core
    module EngineComponents
      # Coordinates rendering of all game elements
      class RenderCoordinator
        property ui_visible : Bool = true

        def initialize
        end

        # Main rendering method
        def render(scene : Scenes::Scene?,
                   dialogs : Array(UI::Dialog),
                   cutscene_manager : Cutscenes::CutsceneManager,
                   transition_manager : Graphics::TransitionManager?)
          # Use transition manager if available and active
          if transition_manager && transition_manager.transitioning?
            transition_manager.render_with_transition do
              render_scene_content(scene, dialogs, cutscene_manager)
            end
          else
            render_scene_content(scene, dialogs, cutscene_manager)
          end

          # Render UI overlay (always on top)
          render_ui_overlay if @ui_visible
        end

        # Render scene and game content
        private def render_scene_content(scene : Scenes::Scene?,
                                         dialogs : Array(UI::Dialog),
                                         cutscene_manager : Cutscenes::CutsceneManager)
          # Clear background
          RL.clear_background(RL::BLACK)

          # Render current scene
          scene.try(&.draw)

          # Render cutscenes
          cutscene_manager.render

          # Render dialogs
          dialogs.each(&.draw)

          # Render debug information if enabled
          render_debug_info(scene) if PointClickEngine::Core::Engine.debug_mode
        end

        # Render UI elements that should always be visible
        private def render_ui_overlay
          # This would render things like:
          # - Inventory UI
          # - Status bars
          # - Menu buttons
          # - Cursor
        end

        # Render debug visualization
        private def render_debug_info(scene : Scenes::Scene?)
          return unless scene

          # Draw hotspot outlines
          scene.hotspots.each do |hotspot|
            RL.draw_rectangle_lines(
              hotspot.position.x.to_i,
              hotspot.position.y.to_i,
              hotspot.size.x.to_i,
              hotspot.size.y.to_i,
              RL::GREEN
            )

            # Draw hotspot name
            RL.draw_text(
              hotspot.name,
              hotspot.position.x.to_i,
              hotspot.position.y.to_i - 20,
              12,
              RL::WHITE
            )
          end

          # Draw walkable areas if available
          if scene.responds_to?(:walkable_areas)
            scene.walkable_areas.each do |area|
              RL.draw_rectangle_lines(
                area.position.x.to_i,
                area.position.y.to_i,
                area.size.x.to_i,
                area.size.y.to_i,
                RL::BLUE
              )
            end
          end

          # Draw characters
          scene.characters.each do |character|
            RL.draw_circle(
              character.position.x.to_i,
              character.position.y.to_i,
              5,
              RL::RED
            )

            RL.draw_text(
              character.name,
              character.position.x.to_i + 10,
              character.position.y.to_i - 10,
              10,
              RL::WHITE
            )
          end

          # Draw performance info
          render_performance_info
        end

        # Render performance statistics
        private def render_performance_info
          fps = RL.get_fps
          frame_time = RL.get_frame_time

          y_offset = 10
          RL.draw_text("FPS: #{fps}", 10, y_offset, 16, RL::YELLOW)
          y_offset += 20
          RL.draw_text("Frame Time: #{(frame_time * 1000).round(2)}ms", 10, y_offset, 16, RL::YELLOW)
          y_offset += 20
          RL.draw_text("Debug Mode: ON", 10, y_offset, 16, RL::GREEN)
        end

        # Set cursor based on current context
        def update_cursor(scene : Scenes::Scene?)
          return unless scene

          mouse_pos = RL.get_mouse_position
          hotspot = scene.get_hotspot_at(mouse_pos)

          if hotspot
            # Set cursor based on hotspot type
            cursor = case hotspot.cursor_type
                     when .hand? then RL::MouseCursor::PointingHand
                     when .look? then RL::MouseCursor::Crosshair
                     when .talk? then RL::MouseCursor::Ibeam
                     else             RL::MouseCursor::Default
                     end
            RL.set_mouse_cursor(cursor)
          else
            RL.set_mouse_cursor(RL::MouseCursor::Default)
          end
        end
      end
    end
  end
end
