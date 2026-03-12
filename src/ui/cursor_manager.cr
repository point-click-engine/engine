# Cursor management system for context-sensitive interactions

require "../scenes/hotspot"
require "../characters/character"

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
      property current_hotspot : Scenes::Hotspot? = nil
      property current_character : Characters::Character? = nil
      property show_tooltip : Bool = true
      property tooltip_offset : RL::Vector2 = RL::Vector2.new(x: 20, y: 20)
      property manual_verb_mode : Bool = false
      property asset_base_dir : String = ""

      @default_cursor : RL::Texture2D?
      @default_cursor_hotspot : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)
      @cursor_hotspots : Hash(VerbType, RL::Vector2) = {} of VerbType => RL::Vector2
      @available_verbs = [VerbType::Walk, VerbType::Look, VerbType::Talk, VerbType::Use, VerbType::Take, VerbType::Open]
      @cursor_root : String? = nil
      @custom_cursor_paths : Hash(VerbType, String) = {} of VerbType => String
      @custom_default_cursor_path : String? = nil

      def initialize
        @cursors = {} of VerbType => RL::Texture2D
        load_cursors
      end

      def configure(asset_base_dir : String = "", cursor_root : String? = nil,
                    cursor_paths : Hash(VerbType, String)? = nil,
                    default_cursor_path : String? = nil)
        cleanup
        @asset_base_dir = asset_base_dir
        @cursor_root = cursor_root
        @custom_cursor_paths = cursor_paths ? cursor_paths.dup : {} of VerbType => String
        @custom_default_cursor_path = default_cursor_path
        load_cursors
      end

      def custom_cursor_available? : Bool
        !@cursors.empty? || !@default_cursor.nil?
      end

      # Load cursor textures from assets
      private def load_cursors
        @cursors.clear
        @cursor_hotspots.clear
        @default_cursor = nil

        VerbType.each do |verb|
          if path = resolve_cursor_path(verb)
            texture, hotspot = load_cursor_texture(path)
            @cursors[verb] = texture
            @cursor_hotspots[verb] = hotspot
          end
        end

        if path = resolve_default_cursor_path
          texture, hotspot = load_cursor_texture(path)
          @default_cursor = texture
          @default_cursor_hotspot = hotspot
        end
      end

      # Update cursor based on what's under the mouse
      def update(mouse_pos : RL::Vector2, scene : Scenes::Scene, inventory : Inventory::InventorySystem? = nil)
        @current_hotspot = nil
        @current_character = nil

        # Check if we're over inventory
        if inventory && inventory.visible
          if inventory.get_item_at_position(mouse_pos)
            if !@manual_verb_mode
              @current_verb = VerbType::Use
            end
            return
          end
        end

        # Check hotspots in scene
        if hotspot = scene.get_hotspot_at(mouse_pos)
          @current_hotspot = hotspot
          if !@manual_verb_mode
            @current_verb = determine_verb_for_hotspot(hotspot)
          end
        elsif character = scene.get_character_at(mouse_pos)
          # Check if we're over a character
          @current_character = character
          if !@manual_verb_mode
            @current_verb = VerbType::Talk
          end
        else
          # Default to walk on background if not in manual mode
          if !@manual_verb_mode
            @current_verb = VerbType::Walk
          end
        end
      end

      # Determine appropriate verb for a hotspot
      private def determine_verb_for_hotspot(hotspot : Hotspot) : VerbType
        # Always use property-based detection for now
        # (Crystal doesn't have runtime responds_to? like Ruby)
        detect_verb_from_properties(hotspot)
      end

      # Smart detection based on hotspot properties
      private def detect_verb_from_properties(hotspot : Hotspot) : VerbType
        # First check if hotspot has a default verb set
        if verb = hotspot.default_verb
          return verb
        end

        name = hotspot.name.downcase
        desc = hotspot.description.downcase

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
        if name.includes?("key") || (name == "book") ||
           name.includes?("crystal") || desc.includes?("pick up")
          return VerbType::Take
        end

        # Container detection
        if name.includes?("chest") || name.includes?("cabinet") ||
           name.includes?("drawer") || name.includes?("desk") || desc.includes?("open")
          return VerbType::Open
        end

        # Default to look
        VerbType::Look
      end

      # Draw the current cursor
      def draw(mouse_pos : RL::Vector2)
        # Get current cursor texture
        cursor_texture = @cursors[@current_verb]? || @default_cursor
        cursor_hotspot = @cursors[@current_verb]? ? (@cursor_hotspots[@current_verb]? || @default_cursor_hotspot) : @default_cursor_hotspot

        if cursor_texture
          RL.hide_cursor
          # Draw the custom cursor so its configured hotspot matches the real mouse point.
          RL.draw_texture_v(
            cursor_texture,
            RL::Vector2.new(
              x: mouse_pos.x - cursor_hotspot.x,
              y: mouse_pos.y - cursor_hotspot.y
            ),
            RL::WHITE
          )
        else
          RL.show_cursor
        end

        # Draw tooltip if enabled
        if @show_tooltip
          if hotspot = @current_hotspot
            draw_tooltip(mouse_pos, hotspot.name)
          elsif character = @current_character
            draw_tooltip(mouse_pos, character.name)
          end
        end

        # Draw current verb indicator if in manual mode
        if @manual_verb_mode
          verb_text = @current_verb.to_s.capitalize
          RL.draw_text(verb_text, 10, RL.get_screen_height - 30, 20, RL::YELLOW)
        end
      end

      # Draw tooltip showing verb and object
      private def draw_tooltip(mouse_pos : RL::Vector2, object_name : String)
        verb_text = @current_verb.to_s.capitalize
        object_text = object_name
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

      # Set verb manually
      def set_verb(verb : VerbType)
        @current_verb = verb
        @manual_verb_mode = true
      end

      # Cycle to next verb
      def cycle_verb_forward
        current_index = @available_verbs.index(@current_verb) || 0
        next_index = (current_index + 1) % @available_verbs.size
        @current_verb = @available_verbs[next_index]
        @manual_verb_mode = true
      end

      # Cycle to previous verb
      def cycle_verb_backward
        current_index = @available_verbs.index(@current_verb) || 0
        prev_index = (current_index - 1 + @available_verbs.size) % @available_verbs.size
        @current_verb = @available_verbs[prev_index]
        @manual_verb_mode = true
      end

      # Reset to automatic verb selection
      def reset_manual_mode
        @manual_verb_mode = false
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
        @default_cursor = nil
      end

      private def resolve_cursor_path(verb : VerbType) : String?
        if custom_path = @custom_cursor_paths[verb]?
          return resolve_asset_path(custom_path)
        end

        cursor_candidates_for(verb).each do |candidate|
          if path = resolve_in_search_roots(candidate)
            return path
          end
        end

        nil
      end

      private def resolve_default_cursor_path : String?
        if path = @custom_default_cursor_path
          return resolve_asset_path(path)
        end

        default_cursor_candidates.each do |candidate|
          if path = resolve_in_search_roots(candidate)
            return path
          end
        end

        nil
      end

      private def resolve_in_search_roots(candidate : String) : String?
        search_roots.each do |root|
          path = root.empty? ? resolve_asset_path(candidate) : resolve_asset_path(File.join(root, candidate))
          return path if File.exists?(path)
        end

        nil
      end

      private def resolve_asset_path(path : String) : String
        return path if path.starts_with?("/")
        return path if @asset_base_dir.empty?
        File.join(@asset_base_dir, path)
      end

      private def load_cursor_texture(path : String) : Tuple(RL::Texture2D, RL::Vector2)
        image = RL.load_image(path)
        hotspot = detect_cursor_hotspot(image, path)
        texture = RL.load_texture_from_image(image)
        RL.unload_image(image)
        {texture, hotspot}
      end

      private def detect_cursor_hotspot(image : RL::Image, path : String) : RL::Vector2
        border = RL.get_image_alpha_border(image, 0.1f32)
        basename = File.basename(path).downcase

        if basename.includes?("default") || basename.includes?("walk") || basename.includes?("arrow")
          RL::Vector2.new(x: border.x, y: border.y)
        else
          RL::Vector2.new(
            x: border.x + border.width / 2.0f32,
            y: border.y + border.height / 2.0f32
          )
        end
      end

      private def search_roots : Array(String)
        roots = [] of String
        roots << @cursor_root.not_nil! if @cursor_root
        roots << "assets/cursors"
        roots << "assets/ui/cursors"
        roots << "assets/ui"
        roots.uniq
      end

      private def default_cursor_candidates : Array(String)
        ["default.png", "cursor_default.png", "cursor.png"]
      end

      private def cursor_candidates_for(verb : VerbType) : Array(String)
        candidates = [] of String

        case verb
        when .walk?
          candidates.concat(["walk.png", "cursor_walk.png", "cursor_default.png", "cursor.png"])
        when .look?
          candidates.concat(["look.png", "cursor_look.png", "cursor_default.png", "cursor.png"])
        when .talk?
          candidates.concat(["talk.png", "cursor_talk.png", "cursor_hand.png", "cursor_default.png", "cursor.png"])
        when .use?, .take?, .open?, .close?, .push?, .pull?, .give?
          verb_name = verb.to_s.downcase
          candidates.concat([
            "#{verb_name}.png",
            "cursor_#{verb_name}.png",
            "cursor_hand.png",
            "cursor_default.png",
            "cursor.png",
          ])
        end

        candidates
      end
    end
  end
end
