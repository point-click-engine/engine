require "./menu_input_handler"
require "./menu_renderer"
require "./menu_navigator"
require "./configuration_manager"
require "./gui_manager"
require "../core/save_system"

module PointClickEngine
  module UI
    # Menu system using component-based architecture
    #
    # This MenuSystem delegates responsibilities to specialized components:
    # - MenuInputHandler: Processes all input (keyboard, mouse, gamepad)
    # - MenuRenderer: Handles all visual rendering and themes
    # - MenuNavigator: Manages navigation logic and item selection
    # - ConfigurationManager: Handles game settings and configuration
    class MenuSystem
      # Menu components
      property input_handler : MenuInputHandler
      property renderer : MenuRenderer
      property navigator : MenuNavigator
      property config_manager : ConfigurationManager

      # Menu state
      property current_menu : String = "main"
      property visible : Bool = false
      property in_game : Bool = false
      property game_paused : Bool = false

      # Menu definitions
      property menu_items : Hash(String, Array(String)) = {} of String => Array(String)
      property menu_titles : Hash(String, String) = {} of String => String
      property menu_enabled_items : Hash(String, Array(Bool)) = {} of String => Array(Bool)

      # Layout properties
      property menu_bounds : RL::Rectangle
      property auto_layout : Bool = true

      # Engine reference
      property engine : Core::Engine?

      # Callbacks for menu actions
      property on_new_game : Proc(Nil)?
      property on_load_game : Proc(Nil)?
      property on_save_game : Proc(Nil)?
      property on_options : Proc(Nil)?
      property on_quit : Proc(Nil)?
      property on_resume : Proc(Nil)?

      def initialize(@engine : Core::Engine? = nil)
        @input_handler = MenuInputHandler.new
        @renderer = MenuRenderer.new
        @navigator = MenuNavigator.new
        @config_manager = ConfigurationManager.new

        # Default menu bounds (will be auto-calculated if auto_layout is true)
        @menu_bounds = RL::Rectangle.new(x: 300, y: 200, width: 400, height: 300)

        setup_default_menus
        setup_input_callbacks
        setup_navigation_callbacks
      end

      # Shows the menu system
      def show(menu_name : String = "main")
        @current_menu = menu_name
        @visible = true

        # Setup navigator for current menu
        if items = @menu_items[@current_menu]?
          @navigator.set_total_items(items.size)
          if enabled = @menu_enabled_items[@current_menu]?
            @navigator.set_enabled_items(enabled)
          end
          @navigator.navigate_to_first
        end

        update_layout if @auto_layout
      end

      # Hides the menu system
      def hide
        @visible = false
      end

      # Toggles the pause menu
      def toggle_pause_menu
        if @visible && @current_menu == "pause"
          @game_paused = false
          hide
        else
          @game_paused = true
          show("pause")
        end
      end

      # Enters game mode (hides menu and sets in_game flag)
      def enter_game
        @in_game = true
        hide
      end

      # Exits game mode (shows main menu and clears in_game flag)
      def exit_game
        @in_game = false
        show("main")
      end

      # Shows the main menu
      def show_main_menu
        show("main")
      end

      # Updates the menu system (input and animations)
      def update(dt : Float64)
        return unless @visible

        # Process input
        action = @input_handler.process_input(dt)

        # Handle navigation based on input
        case action
        when MenuInputHandler::InputAction::NavigateUp
          @navigator.navigate_previous
        when MenuInputHandler::InputAction::NavigateDown
          @navigator.navigate_next
        when MenuInputHandler::InputAction::NavigateLeft
          @navigator.navigate_previous
        when MenuInputHandler::InputAction::NavigateRight
          @navigator.navigate_next
        when MenuInputHandler::InputAction::Select
          execute_current_action
        when MenuInputHandler::InputAction::Cancel
          handle_cancel_action
        when MenuInputHandler::InputAction::MouseHover
          handle_mouse_hover
        when MenuInputHandler::InputAction::MouseClick
          handle_mouse_click
        end

        # Update renderer animations
        @renderer.update_animations
      end

      # Renders the menu system
      def render
        return unless @visible

        items = @menu_items[@current_menu]? || [] of String
        title = @menu_titles[@current_menu]? || ""
        enabled_items = @menu_enabled_items[@current_menu]?
        selected_index = @navigator.get_selected_index

        @renderer.draw_menu(@menu_bounds, title, items, selected_index, enabled_items)
      end

      # Adds a menu to the system
      def add_menu(name : String, title : String, items : Array(String), enabled_items : Array(Bool)? = nil)
        @menu_items[name] = items
        @menu_titles[name] = title
        @menu_enabled_items[name] = enabled_items || Array.new(items.size, true)
      end

      # Sets menu item enabled state
      def set_menu_item_enabled(menu_name : String, item_index : Int32, enabled : Bool)
        if enabled_items = @menu_enabled_items[menu_name]?
          return unless item_index >= 0 && item_index < enabled_items.size
          enabled_items[item_index] = enabled

          # Update navigator if this is the current menu
          if @current_menu == menu_name
            @navigator.set_item_enabled(item_index, enabled)
          end
        end
      end

      # Gets current menu item text
      def get_current_item : String?
        items = @menu_items[@current_menu]?
        return nil unless items

        index = @navigator.get_selected_index
        return nil unless index >= 0 && index < items.size

        items[index]
      end

      # Executes the action for the currently selected menu item
      def execute_current_action
        item = get_current_item
        return unless item

        case @current_menu
        when "main"
          handle_main_menu_action(item)
        when "pause"
          handle_pause_menu_action(item)
        when "options"
          handle_options_menu_action(item)
        when "save"
          handle_save_menu_action(item)
        when "load"
          handle_load_menu_action(item)
        end
      end

      # Switches to a different menu
      def switch_to_menu(menu_name : String)
        return unless @menu_items.has_key?(menu_name)

        @current_menu = menu_name

        # Setup navigator for new menu
        if items = @menu_items[menu_name]?
          @navigator.set_total_items(items.size)
          if enabled = @menu_enabled_items[menu_name]?
            @navigator.set_enabled_items(enabled)
          end
          @navigator.navigate_to_first
        end

        update_layout if @auto_layout
      end

      # Updates layout based on current menu content
      def update_layout
        items = @menu_items[@current_menu]? || [] of String
        title = @menu_titles[@current_menu]? || ""

        # Calculate required size
        size = @renderer.calculate_menu_size(title, items)

        # Center on screen (assuming 1024x768 default)
        screen_width = 1024
        screen_height = 768

        @menu_bounds = RL::Rectangle.new(
          x: (screen_width - size.x) / 2,
          y: (screen_height - size.y) / 2,
          width: size.x,
          height: size.y
        )
      end

      # Handles mouse hover interactions
      private def handle_mouse_hover
        items = @menu_items[@current_menu]? || [] of String
        title = @menu_titles[@current_menu]? || ""

        items.each_with_index do |item, index|
          item_bounds = @renderer.get_item_bounds(@menu_bounds, title, index)
          if @input_handler.mouse_over_item?(item_bounds)
            enabled = @menu_enabled_items[@current_menu]?.try(&.[index]?) || true
            if enabled && @navigator.get_selected_index != index
              @navigator.navigate_to(index)
            end
            break
          end
        end
      end

      # Handles mouse click interactions
      private def handle_mouse_click
        items = @menu_items[@current_menu]? || [] of String
        title = @menu_titles[@current_menu]? || ""

        items.each_with_index do |item, index|
          item_bounds = @renderer.get_item_bounds(@menu_bounds, title, index)
          enabled = @menu_enabled_items[@current_menu]?.try(&.[index]?) || true

          if @input_handler.process_item_interaction(index, item_bounds, enabled)
            @navigator.navigate_to(index)
            execute_current_action
            break
          end
        end
      end

      # Handles cancel action (ESC key or back button)
      private def handle_cancel_action
        case @current_menu
        when "main"
          # Can't cancel from main menu
        when "pause"
          @on_resume.try(&.call)
        when "options", "save", "load"
          switch_to_menu(@in_game ? "pause" : "main")
        end
      end

      # Sets up default menu configurations
      private def setup_default_menus
        # Main menu
        add_menu("main", "Main Menu", [
          "New Game",
          "Load Game",
          "Options",
          "Quit",
        ])

        # Pause menu
        add_menu("pause", "Game Paused", [
          "Resume",
          "Save Game",
          "Load Game",
          "Options",
          "Main Menu",
          "Quit",
        ])

        # Options menu
        add_menu("options", "Options", [
          "Display Settings",
          "Audio Settings",
          "Controls",
          "Back",
        ])

        # Save menu (will be populated dynamically)
        add_menu("save", "Save Game", [
          "Save Slot 1",
          "Save Slot 2",
          "Save Slot 3",
          "Back",
        ])

        # Load menu (will be populated dynamically)
        add_menu("load", "Load Game", [
          "Load Slot 1",
          "Load Slot 2",
          "Load Slot 3",
          "Back",
        ])
      end

      # Sets up input handler callbacks
      private def setup_input_callbacks
        @input_handler.on_navigation do |action|
          # Navigation is handled in update method
        end

        @input_handler.on_selection do |index|
          @navigator.navigate_to(index)
          execute_current_action
        end

        @input_handler.on_cancellation do
          handle_cancel_action
        end

        @input_handler.on_hover do |index|
          @navigator.navigate_to(index)
        end
      end

      # Sets up navigation callbacks
      private def setup_navigation_callbacks
        @navigator.on_selection_changed = ->(old_index : Int32, new_index : Int32) {
          # Could add sound effects here
        }

        @navigator.on_wrap_around = ->(index : Int32) {
          # Could add visual feedback for wrap around
        }

        @navigator.on_invalid_navigation = -> {
          # Could add error feedback
        }
      end

      # Handles main menu actions
      private def handle_main_menu_action(item : String)
        case item
        when "New Game"
          @on_new_game.try(&.call)
        when "Load Game"
          switch_to_menu("load")
        when "Options"
          switch_to_menu("options")
        when "Quit"
          @on_quit.try(&.call)
        end
      end

      # Handles pause menu actions
      private def handle_pause_menu_action(item : String)
        case item
        when "Resume"
          @on_resume.try(&.call)
        when "Save Game"
          switch_to_menu("save")
        when "Load Game"
          switch_to_menu("load")
        when "Options"
          switch_to_menu("options")
        when "Main Menu"
          switch_to_menu("main")
          @in_game = false
        when "Quit"
          @on_quit.try(&.call)
        end
      end

      # Handles options menu actions
      private def handle_options_menu_action(item : String)
        case item
        when "Display Settings"
          # Could open display settings submenu
        when "Audio Settings"
          # Could open audio settings submenu
        when "Controls"
          # Could open controls configuration
        when "Back"
          switch_to_menu(@in_game ? "pause" : "main")
        end
      end

      # Handles save menu actions
      private def handle_save_menu_action(item : String)
        if item.starts_with?("Save Slot")
          slot_number = item.split.last
          @on_save_game.try(&.call)
          switch_to_menu("pause")
        elsif item == "Back"
          switch_to_menu("pause")
        end
      end

      # Handles load menu actions
      private def handle_load_menu_action(item : String)
        if item.starts_with?("Load Slot")
          slot_number = item.split.last
          @on_load_game.try(&.call)
          @in_game = true
        elsif item == "Back"
          switch_to_menu(@in_game ? "pause" : "main")
        end
      end

      # Gets current configuration manager
      def get_configuration_manager : ConfigurationManager
        @config_manager
      end

      # Applies configuration changes to components
      def apply_configuration
        # Update input handler from configuration
        @input_handler.set_keyboard_navigation(@config_manager.config.keyboard_navigation)

        # Update renderer theme from configuration
        if @config_manager.config.language != "en"
          # Could update text based on language
        end
      end

      # Validates all components
      def validate_system : Array(String)
        issues = [] of String

        issues.concat(@input_handler.validate_configuration)
        issues.concat(@renderer.validate_theme)
        issues.concat(@navigator.validate_configuration)
        issues.concat(@config_manager.validate_configuration)

        issues
      end
    end
  end
end
