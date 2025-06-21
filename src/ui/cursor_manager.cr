# Cursor management system for context-sensitive interactions

require "raylib-cr"
require "../scenes/hotspot"

module PointClickEngine
  module UI
    # Verb types for different actions
    enum VerbType
      Walk
      Look
      Talk
      Use
      Take
      Open
      Close
      Push
      Pull
      Give
    end

    # Object types for smart verb detection
    enum ObjectType
      Background
      Item
      Character
      Door
      Container
      Device
      Exit
    end

    # Manages context-sensitive cursors
    class CursorManager
      property cursors : Hash(VerbType, RL::Texture2D)
      property current_verb : VerbType = VerbType::Walk
      property current_hotspot : Hotspot? = nil
      property show_tooltip : Bool = true
      property tooltip_offset : RL::Vector2 = RL::Vector2.new(x: 20, y: 20)

      @default_cursor : RL::Texture2D?
      @cursor_hotspot : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)

      def initialize
        @cursors = {} of VerbType => RL::Texture2D
        load_cursors
      end

      # Load cursor textures from assets
      private def load_cursors
        cursor_paths = {
          VerbType::Walk  => "assets/cursors/walk.png",
          VerbType::Look  => "assets/cursors/look.png",
          VerbType::Talk  => "assets/cursors/talk.png",
          VerbType::Use   => "assets/cursors/use.png",
          VerbType::Take  => "assets/cursors/take.png",
          VerbType::Open  => "assets/cursors/open.png",
          VerbType::Close => "assets/cursors/close.png",
          VerbType::Push  => "assets/cursors/push.png",
          VerbType::Pull  => "assets/cursors/pull.png",
          VerbType::Give  => "assets/cursors/give.png",
        }

        cursor_paths.each do |verb, path|
          if File.exists?(path)
            @cursors[verb] = RL.load_texture(path)
          end
        end

        # Load default cursor as fallback
        if File.exists?("assets/cursors/default.png")
          @default_cursor = RL.load_texture("assets/cursors/default.png")
        end
      end

      # Update cursor based on what's under the mouse
      def update(mouse_pos : RL::Vector2, scene : Scenes::Scene, inventory : Inventory::InventorySystem? = nil)
        @current_hotspot = nil

        # Check if we're over inventory
        if inventory && inventory.visible
          if inventory.get_item_at_position(mouse_pos)
            @current_verb = VerbType::Use
            return
          end
        end

        # Check hotspots in scene
        if hotspot = scene.get_hotspot_at(mouse_pos)
          @current_hotspot = hotspot
          @current_verb = determine_verb_for_hotspot(hotspot)
        else
          # Default to walk on background
          @current_verb = VerbType::Walk
        end
      end

      # Determine appropriate verb for a hotspot
      private def determine_verb_for_hotspot(hotspot : Hotspot) : VerbType
        # Check if hotspot has explicit default verb
        if hotspot.responds_to?(:default_verb)
          if verb = hotspot.default_verb
            return verb
          end
        end

        # Use object type if available
        if hotspot.responds_to?(:object_type)
          case hotspot.object_type
          when .item?      then VerbType::Take
          when .character? then VerbType::Talk
          when .door?      then VerbType::Open
          when .container? then VerbType::Open
          when .device?    then VerbType::Use
          when .exit?      then VerbType::Walk
          else                  VerbType::Look
          end
        else
          # Fallback detection based on hotspot properties
          detect_verb_from_properties(hotspot)
        end
      end

      # Smart detection based on hotspot properties
      private def detect_verb_from_properties(hotspot : Hotspot) : VerbType
        name = hotspot.name.downcase
        desc = hotspot.description.downcase

        # Exit zones
        if hotspot.is_a?(Scenes::ExitZone)
          return VerbType::Walk
        end

        # Character detection
        if name.includes?("butler") || name.includes?("guard") ||
           desc.includes?("person") || desc.includes?("character")
          return VerbType::Talk
        end

        # Door detection
        if name.includes?("door") || desc.includes?("door")
          return VerbType::Open
        end

        # Item detection
        if name.includes?("key") || name.includes?("book") ||
           name.includes?("crystal") || desc.includes?("pick up")
          return VerbType::Take
        end

        # Container detection
        if name.includes?("chest") || name.includes?("cabinet") ||
           name.includes?("drawer") || desc.includes?("open")
          return VerbType::Open
        end

        # Default to look
        VerbType::Look
      end

      # Draw the current cursor
      def draw(mouse_pos : RL::Vector2)
        # Hide system cursor
        RL.hide_cursor

        # Get current cursor texture
        cursor_texture = @cursors[@current_verb]? || @default_cursor

        if cursor_texture
          # Draw cursor centered on hotspot
          RL.draw_texture_v(
            cursor_texture,
            RL::Vector2.new(
              x: mouse_pos.x - @cursor_hotspot.x,
              y: mouse_pos.y - @cursor_hotspot.y
            ),
            RL::WHITE
          )
        else
          # Fallback: draw simple crosshair
          draw_fallback_cursor(mouse_pos)
        end

        # Draw tooltip if enabled
        if @show_tooltip
          if hotspot = @current_hotspot
            draw_tooltip(mouse_pos, hotspot)
          end
        end
      end

      # Draw simple cursor when textures aren't loaded
      private def draw_fallback_cursor(pos : RL::Vector2)
        color = case @current_verb
                when .walk? then RL::GREEN
                when .look? then RL::BLUE
                when .talk? then RL::YELLOW
                when .take? then RL::ORANGE
                when .use?  then RL::PURPLE
                else             RL::WHITE
                end

        # Draw crosshair
        RL.draw_line(pos.x - 10, pos.y, pos.x + 10, pos.y, color)
        RL.draw_line(pos.x, pos.y - 10, pos.x, pos.y + 10, color)

        # Draw verb indicator
        verb_char = case @current_verb
                    when .walk? then "W"
                    when .look? then "L"
                    when .talk? then "T"
                    when .take? then "G"
                    when .use?  then "U"
                    when .open? then "O"
                    else             "?"
                    end

        RL.draw_text(verb_char, pos.x + 15, pos.y - 10, 20, color)
      end

      # Draw tooltip showing verb and object
      private def draw_tooltip(mouse_pos : RL::Vector2, hotspot : Hotspot)
        verb_text = @current_verb.to_s.capitalize
        object_text = hotspot.name
        tooltip_text = "#{verb_text} #{object_text}"

        text_width = RL.measure_text(tooltip_text, 16)
        padding = 4

        # Position tooltip
        tooltip_x = mouse_pos.x + @tooltip_offset.x
        tooltip_y = mouse_pos.y + @tooltip_offset.y

        # Keep tooltip on screen
        if tooltip_x + text_width + padding * 2 > RL.get_screen_width
          tooltip_x = mouse_pos.x - text_width - padding * 2 - @tooltip_offset.x
        end

        if tooltip_y + 20 + padding * 2 > RL.get_screen_height
          tooltip_y = mouse_pos.y - 20 - padding * 2 - @tooltip_offset.y
        end

        # Draw background
        RL.draw_rectangle(
          tooltip_x - padding,
          tooltip_y - padding,
          text_width + padding * 2,
          20 + padding * 2,
          RL::Color.new(r: 0, g: 0, b: 0, a: 200)
        )

        # Draw text
        RL.draw_text(tooltip_text, tooltip_x, tooltip_y, 16, RL::WHITE)
      end

      # Get the current action verb
      def get_current_action : VerbType
        @current_verb
      end

      # Check if a specific verb is active
      def is_verb_active?(verb : VerbType) : Bool
        @current_verb == verb
      end

      # Clean up
      def cleanup
        @cursors.values.each do |texture|
          RL.unload_texture(texture)
        end
        @cursors.clear

        if cursor = @default_cursor
          RL.unload_texture(cursor)
        end
      end
    end
  end
end
