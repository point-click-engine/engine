# Comprehensive menu system for point-and-click games

require "./gui_manager"
require "../core/save_system"

module PointClickEngine
  module UI
    # Menu item class (changed from struct to class for mutable properties)
    class MenuItem
      property text : String
      property action : Proc(Nil)?
      property enabled : Bool = true
      property highlighted : Bool = false

      def initialize(@text : String, @action : Proc(Nil)? = nil)
      end
    end

    # Base menu class
    abstract class BaseMenu
      property visible : Bool = false
      property items : Array(MenuItem) = [] of MenuItem
      property selected_index : Int32 = 0
      property position : RL::Vector2
      property size : RL::Vector2
      property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 200)
      property text_color : RL::Color = RL::WHITE
      property highlight_color : RL::Color = RL::YELLOW
      property font_size : Int32 = 24
      property item_spacing : Float32 = 40f32
      property title : String = ""
      property title_font_size : Int32 = 36

      def initialize(@position : RL::Vector2, @size : RL::Vector2)
      end

      def add_item(text : String, &action : ->)
        @items << MenuItem.new(text, action)
      end

      def add_item(text : String, action : Proc(Nil)? = nil)
        @items << MenuItem.new(text, action)
      end

      def show
        @visible = true
        @selected_index = 0
        update_highlights
      end

      def hide
        @visible = false
      end

      def toggle
        if @visible
          hide
        else
          show
        end
      end

      def update(dt : Float32)
        return unless @visible

        # Keyboard navigation
        if RL.key_pressed?(RL::KeyboardKey::Up)
          navigate_up
        elsif RL.key_pressed?(RL::KeyboardKey::Down)
          navigate_down
        elsif RL.key_pressed?(RL::KeyboardKey::Enter) || RL.key_pressed?(RL::KeyboardKey::Space)
          select_current
        elsif RL.key_pressed?(RL::KeyboardKey::Escape)
          on_escape
        end

        # Mouse navigation
        mouse_pos = RL.get_mouse_position
        item_y = @position.y + 80f32 # Account for title

        @items.each_with_index do |item, index|
          item_rect = RL::Rectangle.new(
            x: @position.x,
            y: item_y + (index * @item_spacing),
            width: @size.x,
            height: @font_size + 10
          )

          if RL.check_collision_point_rec?(mouse_pos, item_rect)
            if @selected_index != index
              @selected_index = index
              update_highlights
            end

            if RL.mouse_button_pressed?(RL::MouseButton::Left) && item.enabled
              item.action.try &.call
            end
          end
        end
      end

      def draw
        return unless @visible

        # Draw background
        RL.draw_rectangle_rec(
          RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y),
          @background_color
        )

        # Draw border
        RL.draw_rectangle_lines_ex(
          RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y),
          2,
          RL::WHITE
        )

        # Draw title
        if !@title.empty?
          title_width = RL.measure_text(@title, @title_font_size)
          title_x = @position.x + (@size.x - title_width) / 2
          RL.draw_text(@title, title_x.to_i, (@position.y + 20).to_i, @title_font_size, RL::WHITE)
        end

        # Draw menu items
        item_y = @position.y + 80f32
        @items.each_with_index do |item, index|
          # Draw highlight background for selected item
          if item.highlighted
            highlight_rect = RL::Rectangle.new(
              x: @position.x + 20,
              y: item_y - 5,
              width: @size.x - 40,
              height: @font_size + 10
            )
            # Draw glowing background
            RL.draw_rectangle_rec(highlight_rect, RL::Color.new(r: 255, g: 215, b: 0, a: 30))
            RL.draw_rectangle_lines_ex(highlight_rect, 2, RL::Color.new(r: 255, g: 215, b: 0, a: 100))
          end

          color = if !item.enabled
                    RL::GRAY
                  elsif item.highlighted
                    @highlight_color
                  else
                    @text_color
                  end

          text = item.highlighted ? "> #{item.text} <" : "  #{item.text}"
          text_width = RL.measure_text(text, @font_size)
          text_x = @position.x + (@size.x - text_width) / 2

          # Add subtle animation for highlighted item
          if item.highlighted
            offset = (Math.sin(RL.get_time * 3) * 2).to_f32
            text_x += offset
          end

          RL.draw_text(text, text_x.to_i, item_y.to_i, @font_size, color)
          item_y += @item_spacing
        end
      end

      protected def navigate_up
        return if @items.empty?

        # Find previous enabled item
        new_index = @selected_index - 1
        while new_index >= 0 && !@items[new_index].enabled
          new_index -= 1
        end

        if new_index < 0
          # Wrap to bottom
          new_index = @items.size - 1
          while new_index > @selected_index && !@items[new_index].enabled
            new_index -= 1
          end
        end

        if new_index >= 0 && new_index < @items.size && @items[new_index].enabled
          @selected_index = new_index
          update_highlights
        end
      end

      protected def navigate_down
        return if @items.empty?

        # Find next enabled item
        new_index = @selected_index + 1
        while new_index < @items.size && !@items[new_index].enabled
          new_index += 1
        end

        if new_index >= @items.size
          # Wrap to top
          new_index = 0
          while new_index < @selected_index && !@items[new_index].enabled
            new_index += 1
          end
        end

        if new_index >= 0 && new_index < @items.size && @items[new_index].enabled
          @selected_index = new_index
          update_highlights
        end
      end

      protected def select_current
        if @selected_index >= 0 && @selected_index < @items.size
          item = @items[@selected_index]
          puts "Menu: Selecting item #{@selected_index}: #{item.text}"
          if item.enabled && item.action
            puts "Menu: Calling action for #{item.text}"
            item.action.not_nil!.call
          else
            puts "Menu: Item disabled or no action"
          end
        end
      end

      protected def update_highlights
        @items.each_with_index do |item, index|
          item.highlighted = (index == @selected_index)
        end
      end

      # Override in subclasses for custom escape behavior
      protected def on_escape
        hide
      end
    end

    # Main menu implementation
    class MainMenu < BaseMenu
      property on_new_game : Proc(Nil)?
      property on_load_game : Proc(Nil)?
      property on_options : Proc(Nil)?
      property on_quit : Proc(Nil)?

      def initialize(position : RL::Vector2, size : RL::Vector2)
        super
        @title = "Main Menu"
        setup_menu_items
      end

      private def setup_menu_items
        add_item("New Game") { @on_new_game.try &.call }
        add_item("Load Game") { @on_load_game.try &.call }
        add_item("Options") { @on_options.try &.call }
        add_item("Quit") { @on_quit.try &.call }
      end
    end

    # Pause menu (shown during gameplay)
    class PauseMenu < BaseMenu
      property on_resume : Proc(Nil)?
      property on_save : Proc(Nil)?
      property on_load : Proc(Nil)?
      property on_options : Proc(Nil)?
      property on_main_menu : Proc(Nil)?
      property on_quit : Proc(Nil)?

      def initialize(position : RL::Vector2, size : RL::Vector2)
        super
        @title = "Paused"
        setup_menu_items
      end

      private def setup_menu_items
        add_item("Resume") { on_escape }
        add_item("Save Game") { @on_save.try &.call }
        add_item("Load Game") { @on_load.try &.call }
        add_item("Options") { @on_options.try &.call }
        add_item("Main Menu") { @on_main_menu.try &.call }
        add_item("Quit Game") { @on_quit.try &.call }
      end

      protected def on_escape
        hide
        @on_resume.try &.call
      end
    end

    # Options menu
    class OptionsMenu < BaseMenu
      property on_back : Proc(Nil)?

      @current_resolution_index : Int32 = 0

      RESOLUTION_OPTIONS = [
        {800, 600},
        {1024, 768},
        {1280, 720},
        {1280, 960},
        {1366, 768},
        {1600, 900},
        {1920, 1080},
      ]

      def initialize(position : RL::Vector2, size : RL::Vector2, engine : Core::Engine)
        super(position, size)
        @engine = engine
        @title = "Options"
        @current_resolution_index = find_current_resolution_index
        setup_menu_items
      end

      private def setup_menu_items
        # Volume controls
        add_item("Master Volume: ") { } # This will be updated dynamically
        add_item("Volume -") { decrease_volume }
        add_item("Volume +") { increase_volume }

        # Resolution controls
        add_item("Resolution: ") { } # This will be updated dynamically
        add_item("Resolution -") { previous_resolution }
        add_item("Resolution +") { next_resolution }

        # Display options
        add_item("Fullscreen") { toggle_fullscreen }
        add_item("Debug Mode") { toggle_debug }

        # Back button
        add_item("Back") { on_escape }

        update_labels
      end

      def update(dt : Float32)
        super
        update_labels # Keep labels current
      end

      private def update_labels
        if @engine.config
          volume = @engine.config.not_nil!.get("audio.master_volume", "0.8").to_f32
          @items[0].text = "Master Volume: #{(volume * 100).to_i}%"
        end

        # Update resolution label
        if @current_resolution_index >= 0 && @current_resolution_index < RESOLUTION_OPTIONS.size
          res = RESOLUTION_OPTIONS[@current_resolution_index]
          @items[3].text = "Resolution: #{res[0]}x#{res[1]}"
        else
          @items[3].text = "Resolution: Custom"
        end

        @items[6].text = "Fullscreen: #{@engine.fullscreen ? "ON" : "OFF"}"
        @items[7].text = "Debug Mode: #{Core::Engine.debug_mode ? "ON" : "OFF"}"
      end

      private def decrease_volume
        if config = @engine.config
          current = config.get("audio.master_volume", "0.8").to_f32
          new_vol = Math.max(0.0f32, current - 0.1f32)
          config.set("audio.master_volume", new_vol.to_s)
          @engine.audio_manager.try &.set_master_volume(new_vol)
        end
      end

      private def increase_volume
        if config = @engine.config
          current = config.get("audio.master_volume", "0.8").to_f32
          new_vol = Math.min(1.0f32, current + 0.1f32)
          config.set("audio.master_volume", new_vol.to_s)
          @engine.audio_manager.try &.set_master_volume(new_vol)
        end
      end

      private def toggle_fullscreen
        @engine.toggle_fullscreen
      end

      private def toggle_debug
        Core::Engine.debug_mode = !Core::Engine.debug_mode
      end

      private def find_current_resolution_index : Int32
        current_width = RL.get_screen_width
        current_height = RL.get_screen_height

        RESOLUTION_OPTIONS.each_with_index do |res, index|
          if res[0] == current_width && res[1] == current_height
            return index
          end
        end

        return -1 # Custom resolution
      end

      private def previous_resolution
        if @current_resolution_index > 0
          @current_resolution_index -= 1
          apply_resolution
        elsif @current_resolution_index == -1 && RESOLUTION_OPTIONS.size > 0
          @current_resolution_index = RESOLUTION_OPTIONS.size - 1
          apply_resolution
        end
      end

      private def next_resolution
        if @current_resolution_index >= 0 && @current_resolution_index < RESOLUTION_OPTIONS.size - 1
          @current_resolution_index += 1
          apply_resolution
        end
      end

      private def apply_resolution
        return if @engine.fullscreen # Don't change resolution in fullscreen

        if @current_resolution_index >= 0 && @current_resolution_index < RESOLUTION_OPTIONS.size
          res = RESOLUTION_OPTIONS[@current_resolution_index]
          width = res[0]
          height = res[1]

          # Set window size
          RL.set_window_size(width, height)

          # Update engine window dimensions
          @engine.window_width = width
          @engine.window_height = height

          # Update display manager
          if dm = @engine.display_manager
            dm.resize(width, height)
          end

          # Save to config
          if config = @engine.config
            config.set("graphics.resolution_width", width.to_s)
            config.set("graphics.resolution_height", height.to_s)
          end

          # Center window on screen
          monitor_width = RL.get_monitor_width(0)
          monitor_height = RL.get_monitor_height(0)
          RL.set_window_position((monitor_width - width) // 2, (monitor_height - height) // 2)
        end
      end

      protected def on_escape
        hide
        @on_back.try &.call
      end
    end

    # Save/Load menu
    class SaveLoadMenu < BaseMenu
      property is_save_mode : Bool
      property on_back : Proc(Nil)?
      property on_save_slot : Proc(String, Nil)?
      property on_load_slot : Proc(String, Nil)?

      def initialize(position : RL::Vector2, size : RL::Vector2, @is_save_mode : Bool)
        super(position, size)
        @title = @is_save_mode ? "Save Game" : "Load Game"
      end

      def refresh_slots
        @items.clear

        # Add save slots
        if @is_save_mode
          # For saving, always show slots
          (1..5).each do |i|
            slot_name = "save_slot_#{i}"
            if Core::SaveSystem.save_exists?(slot_name)
              # TODO: Get save info (date, scene, etc.)
              add_item("Slot #{i} - [Used]") { @on_save_slot.try &.call(slot_name) }
            else
              add_item("Slot #{i} - [Empty]") { @on_save_slot.try &.call(slot_name) }
            end
          end
        else
          # For loading, only show used slots
          saves_found = false
          (1..5).each do |i|
            slot_name = "save_slot_#{i}"
            if Core::SaveSystem.save_exists?(slot_name)
              saves_found = true
              add_item("Slot #{i}") { @on_load_slot.try &.call(slot_name) }
            end
          end

          if !saves_found
            add_item("No saved games found") { }
            @items.last.enabled = false
          end
        end

        # Add quick save/load slot
        if @is_save_mode
          add_item("Quick Save") { @on_save_slot.try &.call("quicksave") }
        elsif Core::SaveSystem.save_exists?("quicksave")
          add_item("Quick Load") { @on_load_slot.try &.call("quicksave") }
        end

        # Back button
        add_item("Back") { on_escape }

        @selected_index = 0
        update_highlights
      end

      def show
        super
        refresh_slots
      end

      protected def on_escape
        hide
        @on_back.try &.call
      end
    end

    # Menu system manager
    class MenuSystem
      property main_menu : MainMenu
      property pause_menu : PauseMenu
      property options_menu : OptionsMenu
      property save_menu : SaveLoadMenu
      property load_menu : SaveLoadMenu
      property current_menu : BaseMenu?
      property game_paused : Bool = false

      @engine : Core::Engine
      @in_game : Bool = false

      def initialize(@engine : Core::Engine)
        # Calculate centered menu position
        window_width = @engine.window_width
        window_height = @engine.window_height
        menu_width = 400f32
        menu_height = 500f32
        menu_pos = RL::Vector2.new(
          x: (window_width - menu_width) / 2,
          y: (window_height - menu_height) / 2
        )
        menu_size = RL::Vector2.new(x: menu_width, y: menu_height)

        # Create menus
        @main_menu = MainMenu.new(menu_pos, menu_size)
        @pause_menu = PauseMenu.new(menu_pos, menu_size)
        @options_menu = OptionsMenu.new(menu_pos, menu_size, @engine)
        @save_menu = SaveLoadMenu.new(menu_pos, menu_size, true)
        @load_menu = SaveLoadMenu.new(menu_pos, menu_size, false)

        setup_menu_callbacks
      end

      def update(dt : Float32)
        @current_menu.try &.update(dt)
      end

      def draw
        @current_menu.try &.draw
      end

      def show_main_menu
        @in_game = false
        @current_menu = @main_menu
        @main_menu.show
      end

      def show_pause_menu
        return unless @in_game
        @game_paused = true
        @current_menu = @pause_menu
        @pause_menu.show
      end

      def hide_current_menu
        @current_menu.try &.hide
        @current_menu = nil
        @game_paused = false
      end

      def toggle_pause_menu
        if @in_game
          if @current_menu == @pause_menu
            hide_current_menu
          else
            show_pause_menu
          end
        end
      end

      def enter_game
        puts "MenuSystem: Entering game"
        @in_game = true
        hide_current_menu
      end

      def exit_to_main_menu
        @in_game = false
        show_main_menu
      end

      private def setup_menu_callbacks
        # Main menu callbacks
        @main_menu.on_new_game = -> {
          puts "MainMenu: New Game selected"
          enter_game
          puts "MainMenu: Triggering game:new event"
          @engine.event_system.trigger("game:new")
        }

        @main_menu.on_load_game = -> {
          @current_menu = @load_menu
          @load_menu.show
        }

        @main_menu.on_options = -> {
          @current_menu = @options_menu
          @options_menu.show
        }

        @main_menu.on_quit = -> {
          @engine.stop
        }

        # Pause menu callbacks
        @pause_menu.on_resume = -> {
          hide_current_menu
        }

        @pause_menu.on_save = -> {
          @current_menu = @save_menu
          @save_menu.show
        }

        @pause_menu.on_load = -> {
          @current_menu = @load_menu
          @load_menu.show
        }

        @pause_menu.on_options = -> {
          @current_menu = @options_menu
          @options_menu.show
        }

        @pause_menu.on_main_menu = -> {
          exit_to_main_menu
          @engine.event_system.trigger("game:main_menu")
        }

        @pause_menu.on_quit = -> {
          @engine.stop
        }

        # Options menu callbacks
        @options_menu.on_back = -> {
          @current_menu = @in_game ? @pause_menu : @main_menu
          @current_menu.not_nil!.show
        }

        # Save menu callbacks
        @save_menu.on_save_slot = ->(slot : String) {
          if Core::SaveSystem.save_game(@engine, slot)
            @engine.dialog_manager.try &.show_message("Game saved!")
          else
            @engine.dialog_manager.try &.show_message("Failed to save game.")
          end
          @current_menu = @pause_menu
          @pause_menu.show
        }

        @save_menu.on_back = -> {
          @current_menu = @pause_menu
          @pause_menu.show
        }

        # Load menu callbacks
        @load_menu.on_load_slot = ->(slot : String) {
          if Core::SaveSystem.load_game(@engine, slot)
            enter_game
            @engine.dialog_manager.try &.show_message("Game loaded!")
            @engine.event_system.trigger("game:loaded")
          else
            @engine.dialog_manager.try &.show_message("Failed to load game.")
          end
        }

        @load_menu.on_back = -> {
          @current_menu = @in_game ? @pause_menu : @main_menu
          @current_menu.not_nil!.show
        }
      end
    end
  end
end
