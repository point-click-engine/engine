# Engine rendering coordination and debug visualization

require "../../scenes/scene"
require "../../ui/dialog"
require "../../cutscenes/cutscene_manager"
require "../../graphics/camera"

module PointClickEngine
  module Core
    module EngineComponents
      # Coordinates rendering of all game elements
      class RenderCoordinator
        property ui_visible : Bool = true
        property hotspot_highlight_enabled : Bool = false
        property hotspot_highlight_color : RL::Color = RL::Color.new(r: 255, g: 215, b: 0, a: 255)
        property hotspot_highlight_pulse : Bool = true

        def initialize
        end

        # Main rendering method
        def render(scene : Scenes::Scene?,
                   dialogs : Array(UI::Dialog),
                   cutscene_manager : Cutscenes::CutsceneManager,
                   transition_manager : Graphics::TransitionManager?,
                   camera : Graphics::Camera? = nil)
          # Get display manager from engine
          if engine = Engine.instance
            if display_manager = engine.display_manager
              # Begin rendering to game render texture
              display_manager.begin_game_rendering

              # Use transition manager if available and active
              if transition_manager && transition_manager.transitioning?
                puts "[RenderCoordinator] Rendering with transition"
                transition_manager.render_with_transition do
                  render_scene_content(scene, dialogs, cutscene_manager, camera)
                end
              else
                render_scene_content(scene, dialogs, cutscene_manager, camera)
              end

              # End game rendering
              display_manager.end_game_rendering

              # Now draw the render texture to screen
              display_manager.draw_to_screen

              # Render UI overlay (always on top of display manager output)
              render_ui_overlay if @ui_visible
            else
              # Fallback if no display manager
              render_scene_content(scene, dialogs, cutscene_manager, camera)
              render_ui_overlay if @ui_visible
            end
          end
        end

        # Render scene and game content
        private def render_scene_content(scene : Scenes::Scene?,
                                         dialogs : Array(UI::Dialog),
                                         cutscene_manager : Cutscenes::CutsceneManager,
                                         camera : Graphics::Camera? = nil)
          # Clear background
          RL.clear_background(RL::BLACK)

          # Render current scene
          scene.try(&.draw(camera))

          # Render highlighted hotspots if enabled
          render_highlighted_hotspots(scene) if @hotspot_highlight_enabled && scene

          # Render cutscenes
          cutscene_manager.draw

          # Render dialogs
          dialogs.each(&.draw)

          # Render floating dialogs from dialog manager
          if engine = Core::Engine.instance
            engine.system_manager.dialog_manager.try(&.draw)
          end

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

          # FPS and Frame Time
          RL.draw_text("FPS: #{fps}", 10, y_offset, 20, RL::GREEN)
          y_offset += 25

          RL.draw_text("Frame Time: #{(frame_time * 1000).round(2)}ms", 10, y_offset, 20, RL::GREEN)
          y_offset += 25

          # Mouse coordinates
          raw_mouse = RL.get_mouse_position
          RL.draw_text("Screen Mouse: #{raw_mouse.x.to_i}, #{raw_mouse.y.to_i}", 10, y_offset, 20, RL::GREEN)
          y_offset += 25

          # Game coordinates if display manager is available
          if engine = Engine.instance
            if dm = engine.display_manager
              game_mouse = dm.screen_to_game(raw_mouse)
              RL.draw_text("Game Mouse: #{game_mouse.x.to_i}, #{game_mouse.y.to_i}", 10, y_offset, 20, RL::GREEN)
              y_offset += 25
            end

            # Resolution and window info
            RL.draw_text("Window: #{RL.get_screen_width}x#{RL.get_screen_height}", 10, y_offset, 20, RL::GREEN)
            y_offset += 25
            RL.draw_text("Game Resolution: #{engine.window_width}x#{engine.window_height}", 10, y_offset, 20, RL::GREEN)
            y_offset += 25

            # Current scene
            if scene = engine.current_scene
              RL.draw_text("Scene: #{scene.name}", 10, y_offset, 20, RL::GREEN)
              y_offset += 25

              # Number of hotspots and characters
              active_hotspots = scene.hotspots.count { |h| h.active && h.visible }
              RL.draw_text("Hotspots: #{active_hotspots}/#{scene.hotspots.size}", 10, y_offset, 20, RL::GREEN)
              y_offset += 25

              active_chars = scene.characters.count { |c| c.active && c.visible }
              RL.draw_text("Characters: #{active_chars}/#{scene.characters.size}", 10, y_offset, 20, RL::GREEN)
              y_offset += 25

              # Player position
              if player = engine.player
                RL.draw_text("Player: #{player.position.x.to_i}, #{player.position.y.to_i}", 10, y_offset, 20, RL::GREEN)
                y_offset += 25

                # Player state if available
                if player.responds_to?(:state)
                  RL.draw_text("Player State: #{player.state}", 10, y_offset, 20, RL::GREEN)
                  y_offset += 25
                end
              end
            end

            # System states
            y_offset += 10
            RL.draw_text("--- System States ---", 10, y_offset, 20, RL::YELLOW)
            y_offset += 25

            # Hotspot highlight state
            RL.draw_text("Hotspot Highlight: #{@hotspot_highlight_enabled ? "ON" : "OFF"} (Tab)", 10, y_offset, 20, RL::GREEN)
            y_offset += 25

            # Verb input state
            if engine.verb_input_system
              verb = engine.verb_input_system.not_nil!.cursor_manager.get_current_action
              RL.draw_text("Current Verb: #{verb}", 10, y_offset, 20, RL::GREEN)
              y_offset += 25
            end

            # Inventory state
            if engine.inventory.visible
              item_count = engine.inventory.items.size
              RL.draw_text("Inventory: OPEN (#{item_count} items)", 10, y_offset, 20, RL::GREEN)
              y_offset += 25
            end

            # Dialog state
            if engine.system_manager.dialog_manager && engine.system_manager.dialog_manager.not_nil!.current_dialog
              RL.draw_text("Dialog: ACTIVE", 10, y_offset, 20, RL::GREEN)
              y_offset += 25
            end
          end

          # Debug mode indicator
          y_offset += 10
          RL.draw_text("Debug Mode: ON (F1 to toggle)", 10, y_offset, 20, RL::GREEN)
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

        # Render highlighted hotspots for better visibility
        private def render_highlighted_hotspots(scene : Scenes::Scene)
          # Calculate pulsing effect if enabled
          pulse_alpha = if @hotspot_highlight_pulse
                          time = RL.get_time
                          pulse = ((Math.sin(time * 3.0) + 1.0) / 2.0).to_f32
                          (80 + pulse * 40).to_u8
                        else
                          100u8
                        end

          outline_size = if @hotspot_highlight_pulse
                           time = RL.get_time
                           pulse = ((Math.sin(time * 3.0) + 1.0) / 2.0).to_f32
                           2.0f32 + pulse * 2.0f32
                         else
                           3.0f32
                         end

          # Draw hotspots with highlighting effect
          scene.hotspots.each do |hotspot|
            next unless hotspot.active && hotspot.visible

            # Different rendering for polygon vs rectangle hotspots
            if hotspot.responds_to?(:vertices) && hotspot.responds_to?(:draw_polygon)
              # Polygon hotspot
              vertices = hotspot.vertices

              if vertices.size >= 3
                # Draw filled polygon highlight
                highlight_color = RL::Color.new(
                  r: @hotspot_highlight_color.r,
                  g: @hotspot_highlight_color.g,
                  b: @hotspot_highlight_color.b,
                  a: pulse_alpha
                )
                hotspot.draw_polygon(highlight_color)

                # Draw pulsing outline
                outline_color = RL::Color.new(
                  r: @hotspot_highlight_color.r,
                  g: @hotspot_highlight_color.g,
                  b: @hotspot_highlight_color.b,
                  a: 255
                )
                hotspot.draw_polygon_outline(outline_color, outline_size.to_i)

                # Draw glow effect on vertices
                if @hotspot_highlight_pulse
                  glow_color = RL::Color.new(
                    r: @hotspot_highlight_color.r,
                    g: @hotspot_highlight_color.g,
                    b: @hotspot_highlight_color.b,
                    a: (50 * (pulse_alpha / 120.0)).to_u8
                  )
                  vertices.each do |vertex|
                    RL.draw_circle(vertex.x.to_i, vertex.y.to_i, outline_size * 2, glow_color)
                  end
                end
              end
            else
              # Rectangle hotspot
              bounds = hotspot.bounds

              # Draw outer glow
              if @hotspot_highlight_pulse
                glow_color = RL::Color.new(
                  r: @hotspot_highlight_color.r,
                  g: @hotspot_highlight_color.g,
                  b: @hotspot_highlight_color.b,
                  a: (30 * (pulse_alpha / 120.0)).to_u8
                )
                expanded_bounds = RL::Rectangle.new(
                  x: bounds.x - outline_size,
                  y: bounds.y - outline_size,
                  width: bounds.width + outline_size * 2,
                  height: bounds.height + outline_size * 2
                )
                RL.draw_rectangle_rec(expanded_bounds, glow_color)
              end

              # Draw the main highlight
              highlight_color = RL::Color.new(
                r: @hotspot_highlight_color.r,
                g: @hotspot_highlight_color.g,
                b: @hotspot_highlight_color.b,
                a: pulse_alpha
              )
              RL.draw_rectangle_rec(bounds, highlight_color)

              # Draw outline
              outline_color = RL::Color.new(
                r: @hotspot_highlight_color.r,
                g: @hotspot_highlight_color.g,
                b: @hotspot_highlight_color.b,
                a: 255
              )
              RL.draw_rectangle_lines_ex(bounds, outline_size.to_i, outline_color)
            end
          end

          # Also highlight characters
          scene.characters.each do |character|
            next unless character.visible && character.active

            # Create bounds around character
            char_bounds = RL::Rectangle.new(
              x: character.position.x - character.size.x / 2,
              y: character.position.y - character.size.y,
              width: character.size.x,
              height: character.size.y
            )

            # Draw character highlight with different color (blue-ish)
            char_color = RL::Color.new(r: 100, g: 200, b: 255, a: 255)
            char_highlight_color = RL::Color.new(
              r: char_color.r,
              g: char_color.g,
              b: char_color.b,
              a: pulse_alpha
            )
            RL.draw_rectangle_rec(char_bounds, char_highlight_color)

            # Draw character outline
            RL.draw_rectangle_lines_ex(char_bounds, outline_size.to_i, char_color)

            # Draw character name above
            name_text = character.name
            text_width = RL.measure_text(name_text, 16)
            text_x = character.position.x - text_width / 2
            text_y = character.position.y - character.size.y - 20

            # Draw text background
            text_bg = RL::Rectangle.new(
              x: text_x - 4,
              y: text_y - 2,
              width: text_width + 8,
              height: 20
            )
            RL.draw_rectangle_rec(text_bg, RL::Color.new(r: 0, g: 0, b: 0, a: 180))

            # Draw character name
            RL.draw_text(name_text, text_x.to_i, text_y.to_i, 16, RL::WHITE)
          end
        end
      end
    end
  end
end
