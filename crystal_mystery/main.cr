require "yaml"
require "json"
require "../src/point_click_engine"

# The Crystal Mystery - A Point & Click Adventure Game
class CrystalMysteryGame
  property engine : PointClickEngine::Core::Engine
  property current_scene : String = "main_menu"
  property game_items : Hash(String, PointClickEngine::Inventory::InventoryItem) = {} of String => PointClickEngine::Inventory::InventoryItem
  property hotspot_highlight_enabled : Bool = false
  property cursor_manager : PointClickEngine::UI::CursorManager
  property ui_manager : PointClickEngine::UI::UIManager
  property game_state_manager : PointClickEngine::GameStateManager
  property quest_manager : PointClickEngine::QuestManager

  def initialize
    @engine = PointClickEngine::Core::Engine.new
    @engine.init(1024, 768, "The Crystal Mystery")
    @engine.handle_clicks = false # We handle clicks ourselves

    # Enable all engine systems
    @engine.script_engine = PointClickEngine::Scripting::ScriptEngine.new
    @engine.dialog_manager = PointClickEngine::UI::DialogManager.new
    @engine.achievement_manager = PointClickEngine::Core::AchievementManager.new
    @engine.audio_manager = PointClickEngine::Audio::AudioManager.new
    @engine.config = PointClickEngine::Core::ConfigManager.new
    @engine.gui = PointClickEngine::UI::GUIManager.new
    @engine.shader_system = PointClickEngine::Graphics::Shaders::ShaderSystem.new
    @cursor_manager = PointClickEngine::UI::CursorManager.new
    @ui_manager = PointClickEngine::UI::UIManager.new(1024, 768)
    @game_state_manager = PointClickEngine::GameStateManager.new
    @quest_manager = PointClickEngine::QuestManager.new
    player = PointClickEngine::Characters::Player.new(
      "Detective",
      Raylib::Vector2.new(x: 500f32, y: 400f32),
      Raylib::Vector2.new(x: 64f32, y: 128f32)
    )
    player.load_enhanced_spritesheet("crystal_mystery/assets/sprites/player.png", 56, 56, 8, 4)
    @engine.player = player

    # Configure display settings
    if dm = @engine.display_manager
      dm.scaling_mode = PointClickEngine::Graphics::DisplayManager::ScalingMode::FitWithBars
      dm.target_width = 1024
      dm.target_height = 768
    end

    # Load game configuration
    load_configuration

    # Load audio assets
    load_audio_assets

    # Create game items
    create_game_items

    # Create scenes
    create_main_menu
    create_game_scenes

    # Initialize shaders
    setup_shaders

    # Start with main menu
    @engine.change_scene("main_menu")

    # Set up global input handler
    setup_global_input

    # Initialize game state and quests
    setup_game_state_and_quests
  end

  def run
    @engine.init
    @engine.running = true
    @engine.current_scene.try &.enter

    while @engine.running && !Raylib.close_window?
      # Handle global input before engine update
      handle_global_input

      # Update cursor manager
      if scene = @engine.current_scene
        mouse_pos = Raylib.get_mouse_position
        # Convert screen coordinates to game coordinates
        if dm = @engine.display_manager
          game_mouse = dm.screen_to_game(mouse_pos)
          @cursor_manager.update(game_mouse, scene, @engine.inventory)
        end
      end

      # Update engine (let it handle its own timing)
      dt = Raylib.get_frame_time

      # Update game state and quests
      @game_state_manager.update_timers(dt)
      @game_state_manager.update_game_time(dt)
      @quest_manager.update_all_quests(@game_state_manager, dt)

      # Update transitions
      @engine.transition_manager.try(&.update(dt))

      # Draw with custom hotspot highlighting
      draw_with_highlighting
    end

    @cursor_manager.cleanup
    # Engine cleanup is handled automatically
  end

  private def draw_with_highlighting
    return unless dm = @engine.display_manager

    # Handle transitions if available
    # Note: Transition rendering is handled internally by the engine

    dm.begin_game_rendering

    # Draw the current scene
    @engine.current_scene.try &.draw

    # Draw highlighted hotspots if enabled (but not in main menu)
    if @hotspot_highlight_enabled && @engine.current_scene
      current_scene_name = @engine.current_scene.try(&.name)
      if current_scene_name && current_scene_name != "main_menu"
        draw_highlighted_hotspots
      end
    end

    # Draw UI elements
    @engine.inventory.draw
    @engine.dialog_manager.try &.draw
    @engine.gui.try &.draw

    # Draw other elements
    @engine.achievement_manager.try &.draw

    # Draw cursor with verb system
    raw_mouse = Raylib.get_mouse_position
    if dm.is_in_game_area(raw_mouse)
      game_mouse = dm.screen_to_game(raw_mouse)
      @cursor_manager.draw(game_mouse)
    end

    # Draw debug info
    if PointClickEngine::Core::Engine.debug_mode
      draw_debug_info
    end

    # Cutscene handling would go here if implemented

    dm.end_game_rendering

    # Transition effects are handled internally
  end

  private def draw_highlighted_hotspots
    return unless scene = @engine.current_scene

    # Calculate pulsing effect
    time = Raylib.get_time
    pulse = ((Math.sin(time * 3.0) + 1.0) / 2.0).to_f32
    outline_size = 2.0f32 + pulse * 2.0f32

    # Update shader parameters for pulsing effect
    if shader_system = @engine.shader_system
      shader_system.set_value(:outline, "outlineSize", outline_size)

      # Adjust alpha for pulsing
      golden_color = Raylib::Color.new(
        r: 255,
        g: 215,
        b: 0,
        a: (200 + pulse * 55).to_u8
      )
      color_array = [
        golden_color.r.to_f32 / 255.0f32,
        golden_color.g.to_f32 / 255.0f32,
        golden_color.b.to_f32 / 255.0f32,
        golden_color.a.to_f32 / 255.0f32,
      ]
      shader_system.set_value(:outline, "outlineColor", color_array)
    end

    # Draw hotspots with highlighting effect
    scene.hotspots.each do |hotspot|
      next unless hotspot.active && hotspot.visible

      # Different rendering for polygon vs rectangle hotspots
      if hotspot.is_a?(PointClickEngine::Scenes::PolygonHotspot)
        polygon_hotspot = hotspot.as(PointClickEngine::Scenes::PolygonHotspot)
        vertices = polygon_hotspot.get_outline_points

        if vertices.size >= 3
          # Draw filled polygon highlight
          highlight_color = Raylib::Color.new(r: 255, g: 215, b: 0, a: (80 + pulse * 40).to_u8)
          polygon_hotspot.draw_polygon(highlight_color)

          # Draw pulsing outline
          outline_color = Raylib::Color.new(r: 255, g: 255, b: 100, a: 255)
          polygon_hotspot.draw_polygon_outline(outline_color, outline_size.to_i)

          # Draw glow effect on vertices
          glow_color = Raylib::Color.new(r: 255, g: 215, b: 0, a: (50 * pulse).to_u8)
          vertices.each do |vertex|
            Raylib.draw_circle(vertex.x.to_i, vertex.y.to_i, outline_size * 2, glow_color)
          end
        end
      else
        # Rectangle hotspot (existing code)
        bounds = hotspot.bounds

        # Draw outer glow
        glow_color = Raylib::Color.new(r: 255, g: 215, b: 0, a: (30 * pulse).to_u8)
        expanded_bounds = Raylib::Rectangle.new(
          x: bounds.x - outline_size,
          y: bounds.y - outline_size,
          width: bounds.width + outline_size * 2,
          height: bounds.height + outline_size * 2
        )
        Raylib.draw_rectangle_rec(expanded_bounds, glow_color)

        # Draw the main highlight
        highlight_color = Raylib::Color.new(r: 255, g: 215, b: 0, a: (80 + pulse * 40).to_u8)
        Raylib.draw_rectangle_rec(bounds, highlight_color)

        # Draw outline
        outline_color = Raylib::Color.new(r: 255, g: 255, b: 100, a: 255)
        Raylib.draw_rectangle_lines_ex(bounds, outline_size.to_i, outline_color)
      end
    end
  end

  private def draw_debug_info
    Raylib.draw_text("FPS: #{Raylib.get_fps}", 10, 10, 20, Raylib::GREEN)
    if dm = @engine.display_manager
      raw_mouse = Raylib.get_mouse_position
      game_mouse = dm.screen_to_game(raw_mouse)
      Raylib.draw_text("Game Mouse: #{game_mouse.x.to_i}, #{game_mouse.y.to_i}", 10, 35, 20, Raylib::GREEN)
      Raylib.draw_text("Resolution: 1024x768", 10, 60, 20, Raylib::GREEN)
      Raylib.draw_text("Hotspot Highlight: #{@hotspot_highlight_enabled ? "ON" : "OFF"} (Tab to toggle)", 10, 85, 20, Raylib::GREEN)
    end
  end

  private def load_configuration
    # Load game settings
    @engine.config.try do |config|
      config.set("game.version", "1.0.0")
      config.set("game.debug", "false")
      config.set("audio.master_volume", "0.8")
      config.set("graphics.fullscreen", "false")
    end
  end

  private def create_main_menu
    menu_scene = PointClickEngine::Scenes::Scene.new("main_menu")

    # Create UI elements for main menu
    if gui = @engine.gui
      # Title
      title_pos = Raylib::Vector2.new(x: 512f32, y: 200f32)
      gui.add_label("title", "The Crystal Mystery", title_pos, 48, Raylib::WHITE)

      # Buttons
      new_game_pos = Raylib::Vector2.new(x: 412f32, y: 350f32)
      new_game_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

      gui.add_button("new_game", "New Game", new_game_pos, new_game_size) do
        @engine.audio_manager.try &.play_sound_effect("click")
        start_new_game
      end

      load_pos = Raylib::Vector2.new(x: 412f32, y: 420f32)

      gui.add_button("load_game", "Load Game", load_pos, new_game_size) do
        @engine.audio_manager.try &.play_sound_effect("click")
        show_load_menu
      end

      options_pos = Raylib::Vector2.new(x: 412f32, y: 490f32)

      gui.add_button("options", "Options", options_pos, new_game_size) do
        @engine.audio_manager.try &.play_sound_effect("click")
        show_options_menu
      end

      quit_pos = Raylib::Vector2.new(x: 412f32, y: 560f32)

      gui.add_button("quit", "Quit", quit_pos, new_game_size) do
        @engine.audio_manager.try &.play_sound_effect("click")
        @engine.running = false
      end
    end

    @engine.add_scene(menu_scene)
  end

  private def create_game_scenes
    # Create library scene
    create_library_scene

    # Create laboratory scene
    create_laboratory_scene

    # Create garden scene
    create_garden_scene
  end

  private def create_library_scene
    scene_yaml = <<-YAML
    name: library
    background_path: assets/backgrounds/library.png
    enable_pathfinding: true
    navigation_cell_size: 16
    script_path: scripts/library.lua
    walkable_areas:
      regions:
        - name: main_floor
          walkable: true
          vertices:
            - {x: 100, y: 350}
            - {x: 900, y: 350}
            - {x: 900, y: 700}
            - {x: 100, y: 700}
        - name: desk_area
          walkable: false
          vertices:
            - {x: 380, y: 380}
            - {x: 620, y: 380}
            - {x: 620, y: 550}
            - {x: 380, y: 550}
      walk_behind:
        - name: desk_front
          y_threshold: 450
          vertices:
            - {x: 400, y: 430}
            - {x: 600, y: 430}
            - {x: 600, y: 550}
            - {x: 400, y: 550}
      scale_zones:
        - min_y: 350
          max_y: 500
          min_scale: 0.8
          max_scale: 1.0
        - min_y: 500
          max_y: 700
          min_scale: 1.0
          max_scale: 1.2
    hotspots:
      - name: bookshelf
        x: 100
        y: 200
        width: 150
        height: 300
        description: "Ancient books line the shelves"
      - name: desk
        x: 400
        y: 400
        width: 200
        height: 150
        description: "A mahogany desk with scattered papers"
      - name: door_to_lab
        type: exit
        x: 850
        y: 300
        width: 100
        height: 200
        target_scene: laboratory
        target_position: {x: 100, y: 400}
        transition_type: fade
        auto_walk: true
        description: "Door to the laboratory"
      - name: painting
        type: polygon
        vertices:
          - {x: 500, y: 100}
          - {x: 620, y: 100}
          - {x: 620, y: 250}
          - {x: 560, y: 280}
          - {x: 500, y: 250}
        description: "A portrait of the mansion's founder"
    characters:
      - name: butler
        position:
          x: 300
          y: 450
        sprite_path: crystal_mystery/assets/sprites/butler.png
        sprite_info:
          frame_width: 100
          frame_height: 100
    YAML

    File.write("crystal_mystery/scenes/library.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("crystal_mystery/scenes/library.yaml")

    # Add scene-specific logic
    setup_library_interactions(scene)

    @engine.add_scene(scene)
  end

  private def create_laboratory_scene
    scene_yaml = <<-YAML
    name: laboratory
    background_path: assets/backgrounds/laboratory.png
    enable_pathfinding: true
    navigation_cell_size: 16
    script_path: scripts/laboratory.lua
    hotspots:
      - name: workbench
        x: 200
        y: 350
        width: 300
        height: 200
        description: "A cluttered workbench with beakers and tools"
      - name: cabinet
        x: 600
        y: 200
        width: 150
        height: 400
        description: "A locked cabinet with glass doors"
      - name: door_to_library
        type: exit
        x: 50
        y: 300
        width: 100
        height: 200
        target_scene: library
        target_position: {x: 800, y: 400}
        transition_type: fade
        auto_walk: true
        description: "Back to the library"
      - name: door_to_garden
        type: exit
        x: 850
        y: 300
        width: 100
        height: 200
        target_scene: garden
        target_position: {x: 100, y: 400}
        transition_type: iris
        auto_walk: true
        description: "Door to the garden"
    characters:
      - name: scientist
        position:
          x: 400
          y: 400
        sprite_path: crystal_mystery/assets/sprites/scientist.png
        sprite_info:
          frame_width: 100
          frame_height: 100
    YAML

    File.write("crystal_mystery/scenes/laboratory.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("crystal_mystery/scenes/laboratory.yaml")

    setup_laboratory_interactions(scene)

    @engine.add_scene(scene)
  end

  private def create_garden_scene
    scene_yaml = <<-YAML
    name: garden
    background_path: assets/backgrounds/garden.png
    enable_pathfinding: true
    navigation_cell_size: 16
    script_path: scripts/garden.lua
    hotspots:
      - name: fountain
        x: 400
        y: 300
        width: 200
        height: 200
        description: "An ornate fountain with crystal-clear water"
      - name: statue
        type: polygon
        vertices:
          - {x: 740, y: 200}  # top (head)
          - {x: 760, y: 220}  # right shoulder
          - {x: 780, y: 260}  # right arm
          - {x: 770, y: 400}  # right base
          - {x: 730, y: 450}  # bottom base
          - {x: 690, y: 400}  # left base
          - {x: 680, y: 260}  # left arm  
          - {x: 700, y: 220}  # left shoulder
        description: "A weathered statue holding something..."
      - name: flowerbed
        x: 150
        y: 450
        width: 250
        height: 100
        description: "Beautiful roses in full bloom"
      - name: door_to_lab
        type: exit
        x: 50
        y: 300
        width: 100
        height: 200
        target_scene: laboratory
        target_position: {x: 800, y: 400}
        transition_type: fade
        auto_walk: true
        description: "Back to the laboratory"
    YAML

    File.write("crystal_mystery/scenes/garden.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("crystal_mystery/scenes/garden.yaml")

    setup_garden_interactions(scene)

    @engine.add_scene(scene)
  end

  private def setup_library_interactions(scene : PointClickEngine::Scenes::Scene)
    # Mark that player has visited the library
    @game_state_manager.set_flag("visited_library", true)
    scene.hotspots.each do |hotspot|
      case hotspot.name
      when "door_to_lab"
        hotspot.on_click = -> do
          @engine.audio_manager.try &.play_sound_effect("door_open")
          @game_state_manager.set_flag("entered_laboratory", true)
          @engine.change_scene("laboratory")
        end
      when "bookshelf"
        hotspot.on_click = -> do
          # Mark that player has read the crystal book
          @game_state_manager.set_flag("read_crystal_book", true)

          # Show floating dialog above player when examining bookshelf
          if dialog_manager = @engine.dialog_manager
            if player = @engine.player
              player_pos = RL::Vector2.new(x: player.position.x, y: player.position.y - 20)
              dialog_manager.show_floating_dialog("Detective", "Interesting... ancient crystal magic...", player_pos, 3.0f32, PointClickEngine::UI::DialogStyle::Thought)
            else
              dialog_manager.show_message("You find a book about ancient crystals...")
            end
          end
        end
      when "desk"
        hotspot.on_click = -> do
          if !@game_state_manager.get_flag("has_key")
            if key_item = @game_items["key"]?
              @engine.inventory.add_item(key_item)
              @engine.audio_manager.try &.play_sound_effect("pickup")

              # Update game state
              @game_state_manager.set_flag("has_key", true)

              # Show floating dialog for key discovery
              if dialog_manager = @engine.dialog_manager
                if player = @engine.player
                  player_pos = RL::Vector2.new(x: player.position.x, y: player.position.y - 20)
                  dialog_manager.show_floating_dialog("Detective", "A brass key! This might be useful.", player_pos, 3.0f32, PointClickEngine::UI::DialogStyle::Bubble)
                else
                  dialog_manager.show_message("You found a brass key!")
                end
              end
            end
          else
            @engine.dialog_manager.try &.show_message("The desk has scattered papers but nothing else of interest.")
          end
        end
      when "painting"
        hotspot.on_click = -> do
          @engine.dialog_manager.try &.show_message("The founder's eyes seem to follow you...")
        end
      end
    end
  end

  private def setup_laboratory_interactions(scene : PointClickEngine::Scenes::Scene)
    scene.hotspots.each do |hotspot|
      case hotspot.name
      when "door_to_library"
        hotspot.on_click = -> do
          @engine.audio_manager.try &.play_sound_effect("door_open")
          @engine.change_scene("library")
        end
      when "door_to_garden"
        hotspot.on_click = -> do
          @engine.audio_manager.try &.play_sound_effect("door_open")
          @engine.change_scene("garden")
          @engine.audio_manager.try &.play_music("garden_theme", true)
        end
      when "cabinet"
        hotspot.on_click = -> do
          if @engine.inventory.selected_item.try(&.name) == "key"
            if @engine.script_engine.try(&.call_function("get_game_state", "cabinet_unlocked")) == false
              @engine.audio_manager.try &.play_sound_effect("click")
              @engine.dialog_manager.try &.show_message("You unlock the cabinet with the key!")
              @engine.script_engine.try(&.call_function("set_game_state", "cabinet_unlocked", true))
              @engine.inventory.remove_item("key")

              # Add crystal to inventory
              if crystal_item = @game_items["crystal"]?
                @engine.inventory.add_item(crystal_item)
                @engine.audio_manager.try &.play_sound_effect("success")
                @engine.dialog_manager.try &.show_message("You found the mysterious crystal!")
              end
            else
              @engine.dialog_manager.try &.show_message("The cabinet is already open.")
            end
          elsif @engine.script_engine.try(&.call_function("get_game_state", "cabinet_unlocked")) == true
            @engine.dialog_manager.try &.show_message("The cabinet is open and empty.")
          else
            @engine.dialog_manager.try &.show_message("The cabinet is locked. You need a key.")
          end
        end
      when "workbench"
        hotspot.on_click = -> do
          @engine.dialog_manager.try &.show_message("Scientific equipment and notes about crystal energy.")
        end
      end
    end
  end

  private def setup_garden_interactions(scene : PointClickEngine::Scenes::Scene)
    scene.hotspots.each do |hotspot|
      case hotspot.name
      when "door_to_lab"
        hotspot.on_click = -> do
          @engine.change_scene("laboratory")
        end
      when "fountain"
        hotspot.on_click = -> do
          @engine.dialog_manager.try &.show_message("The water sparkles mysteriously...")
        end
      end
    end
  end

  private def setup_shaders
    if shader_system = @engine.shader_system
      # Create atmospheric effects
      PointClickEngine::Graphics::Shaders::ShaderHelpers.create_vignette_shader(shader_system)
      PointClickEngine::Graphics::Shaders::ShaderHelpers.create_bloom_shader(shader_system)

      # Apply vignette to game scenes
      shader_system.set_active(:vignette)
    end
  end

  private def start_new_game
    # Play door sound effect when starting game
    @engine.audio_manager.try &.play_sound_effect("door_open")

    # Clear GUI from main menu
    @engine.gui.try &.clear_all

    # Initialize player
    if player = @engine.player
      player.name = "Detective"
      player.position = Raylib::Vector2.new(x: 200f32, y: 500f32) # Start in walkable area
    end

    # Clear inventory
    @engine.inventory.clear

    # Reset game state
    @engine.script_engine.try do |scripting|
      scripting.execute_script(<<-LUA)
        -- Initialize game state
        game_state = {
          has_key = false,
          cabinet_unlocked = false,
          crystal_found = false,
          talked_to_butler = false,
          talked_to_scientist = false,
          puzzle_solved = false
        }
        
        function get_game_state(key)
          return game_state[key]
        end
        
        function set_game_state(key, value)
          game_state[key] = value
        end
      LUA
    end

    # Start in library
    @engine.change_scene("library")

    # Change music when entering library
    @engine.audio_manager.try &.play_music("castle_ambient", true)

    # Add player to the library scene
    if library_scene = @engine.scenes["library"]?
      if player = @engine.player
        library_scene.set_player(player)
      end
    end

    # Show opening message
    @engine.dialog_manager.try &.show_message("You arrive at the mysterious mansion to investigate the missing crystal...")

    # Add UI hints
    if gui = @engine.gui
      gui.add_label("inventory_hint", "Press 'I' to toggle inventory", Raylib::Vector2.new(x: 10f32, y: 10f32), 16, Raylib::WHITE)
      gui.add_label("highlight_hint", "Press 'Tab' to highlight interactive areas", Raylib::Vector2.new(x: 10f32, y: 30f32), 16, Raylib::WHITE)
      gui.add_label("debug_hint", "Press 'F1' to toggle debug mode", Raylib::Vector2.new(x: 10f32, y: 50f32), 16, Raylib::WHITE)
      gui.add_label("usage_hint", "Select item in inventory, then click where to use it", Raylib::Vector2.new(x: 10f32, y: 70f32), 16, Raylib::WHITE)
    end
  end

  private def show_load_menu
    # Clear current GUI elements
    @engine.gui.try &.clear_all

    # Get available save files
    save_files = PointClickEngine::Core::SaveSystem.get_save_files

    if gui = @engine.gui
      # Title
      gui.add_label("load_title", "Load Game", Raylib::Vector2.new(x: 512f32, y: 150f32), 36, Raylib::WHITE)

      if save_files.empty?
        gui.add_label("no_saves", "No saved games found", Raylib::Vector2.new(x: 512f32, y: 300f32), 24, Raylib::GRAY)
      else
        y_offset = 250f32
        save_files.each_with_index do |save_name, i|
          button_pos = Raylib::Vector2.new(x: 412f32, y: y_offset + (i * 60f32))
          button_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

          gui.add_button("load_#{i}", save_name, button_pos, button_size) do
            load_game(save_name)
          end
        end
      end

      # Back button
      back_pos = Raylib::Vector2.new(x: 412f32, y: 600f32)
      back_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

      gui.add_button("back_to_menu", "Back to Menu", back_pos, back_size) do
        back_to_main_menu
      end
    end
  end

  private def show_options_menu
    # Clear current GUI elements
    @engine.gui.try &.clear_all

    if gui = @engine.gui
      # Title
      gui.add_label("options_title", "Options", Raylib::Vector2.new(x: 512f32, y: 150f32), 36, Raylib::WHITE)

      # Audio Settings
      gui.add_label("audio_label", "Audio Settings", Raylib::Vector2.new(x: 300f32, y: 250f32), 24, Raylib::WHITE)

      # Master Volume
      current_volume = @engine.config.try(&.get("audio.master_volume", "0.8").to_f32) || 0.8f32
      volume_text = "Master Volume: #{(current_volume * 100).to_i}%"
      gui.add_label("volume_label", volume_text, Raylib::Vector2.new(x: 300f32, y: 290f32), 20, Raylib::LIGHTGRAY)

      # Volume buttons
      vol_down_pos = Raylib::Vector2.new(x: 250f32, y: 320f32)
      vol_up_pos = Raylib::Vector2.new(x: 350f32, y: 320f32)
      vol_button_size = Raylib::Vector2.new(x: 50f32, y: 30f32)

      gui.add_button("vol_down", "- ", vol_down_pos, vol_button_size) do
        decrease_volume
      end

      gui.add_button("vol_up", "+ ", vol_up_pos, vol_button_size) do
        increase_volume
      end

      # Graphics Settings
      gui.add_label("graphics_label", "Graphics Settings", Raylib::Vector2.new(x: 300f32, y: 400f32), 24, Raylib::WHITE)

      # Fullscreen toggle
      is_fullscreen = @engine.config.try(&.get("graphics.fullscreen", "false")) == "true"
      fullscreen_text = "Fullscreen: #{is_fullscreen ? "ON" : "OFF"}"
      gui.add_label("fullscreen_label", fullscreen_text, Raylib::Vector2.new(x: 300f32, y: 440f32), 20, Raylib::LIGHTGRAY)

      fullscreen_pos = Raylib::Vector2.new(x: 300f32, y: 470f32)
      fullscreen_size = Raylib::Vector2.new(x: 150f32, y: 30f32)

      gui.add_button("toggle_fullscreen", "Toggle", fullscreen_pos, fullscreen_size) do
        toggle_fullscreen
      end

      # Debug Mode
      is_debug = PointClickEngine::Core::Engine.debug_mode
      debug_text = "Debug Mode: #{is_debug ? "ON" : "OFF"}"
      gui.add_label("debug_label", debug_text, Raylib::Vector2.new(x: 300f32, y: 520f32), 20, Raylib::LIGHTGRAY)

      debug_pos = Raylib::Vector2.new(x: 300f32, y: 550f32)
      debug_size = Raylib::Vector2.new(x: 150f32, y: 30f32)

      gui.add_button("toggle_debug", "Toggle", debug_pos, debug_size) do
        toggle_debug_mode
      end

      # Back button
      back_pos = Raylib::Vector2.new(x: 412f32, y: 650f32)
      back_size = Raylib::Vector2.new(x: 200f32, y: 50f32)

      gui.add_button("back_to_menu", "Back to Menu", back_pos, back_size) do
        back_to_main_menu
      end
    end
  end

  private def save_game(slot_name : String = "quicksave")
    success = PointClickEngine::Core::SaveSystem.save_game(@engine, slot_name)
    message = success ? "Game saved successfully!" : "Failed to save game."
    @engine.dialog_manager.try &.show_message(message)
  end

  private def load_game(slot_name : String)
    success = PointClickEngine::Core::SaveSystem.load_game(@engine, slot_name)
    if success
      @engine.dialog_manager.try &.show_message("Game loaded successfully!")
      @current_scene = @engine.current_scene.try(&.name) || "library"
    else
      @engine.dialog_manager.try &.show_message("Failed to load game.")
    end
  end

  private def back_to_main_menu
    @engine.gui.try &.clear_all
    @engine.change_scene("main_menu")
    create_main_menu # Recreate main menu GUI
  end

  private def decrease_volume
    if config = @engine.config
      current_volume = config.get("audio.master_volume", "0.8").to_f32
      new_volume = Math.max(0.0f32, current_volume - 0.1f32)
      config.set("audio.master_volume", new_volume.to_s)
      @engine.audio_manager.try &.set_master_volume(new_volume)
      update_options_display
    end
  end

  private def increase_volume
    if config = @engine.config
      current_volume = config.get("audio.master_volume", "0.8").to_f32
      new_volume = Math.min(1.0f32, current_volume + 0.1f32)
      config.set("audio.master_volume", new_volume.to_s)
      @engine.audio_manager.try &.set_master_volume(new_volume)
      update_options_display
    end
  end

  private def toggle_fullscreen
    if config = @engine.config
      is_fullscreen = config.get("graphics.fullscreen", "false") == "true"
      new_fullscreen = !is_fullscreen
      config.set("graphics.fullscreen", new_fullscreen.to_s)

      # Note: In a real implementation, you would toggle the window mode here
      # Raylib.toggle_fullscreen

      update_options_display
    end
  end

  private def toggle_debug_mode
    PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
    update_options_display
  end

  private def update_options_display
    # Update the option labels with new values
    if gui = @engine.gui
      # Update volume label
      if config = @engine.config
        current_volume = config.get("audio.master_volume", "0.8").to_f32
        volume_text = "Master Volume: #{(current_volume * 100).to_i}%"
        gui.update_label("volume_label", volume_text)

        # Update fullscreen label
        is_fullscreen = config.get("graphics.fullscreen", "false") == "true"
        fullscreen_text = "Fullscreen: #{is_fullscreen ? "ON" : "OFF"}"
        gui.update_label("fullscreen_label", fullscreen_text)
      end

      # Update debug label
      is_debug = PointClickEngine::Core::Engine.debug_mode
      debug_text = "Debug Mode: #{is_debug ? "ON" : "OFF"}"
      gui.update_label("debug_label", debug_text)
    end
  end

  private def load_audio_assets
    return unless @engine.audio_manager

    audio = @engine.audio_manager.not_nil!

    # Load music tracks
    audio.load_music("main_theme", "crystal_mystery/assets/music/main_theme.ogg")
    audio.load_music("garden_theme", "crystal_mystery/assets/music/garden_theme.ogg")
    audio.load_music("castle_ambient", "crystal_mystery/assets/sounds/music/castle_ambient.ogg")

    # Load sound effects
    audio.load_sound_effect("click", "crystal_mystery/assets/sounds/effects/click.ogg")
    audio.load_sound_effect("door_open", "crystal_mystery/assets/sounds/effects/door_open.ogg")
    audio.load_sound_effect("footsteps", "crystal_mystery/assets/sounds/effects/footsteps.ogg")
    audio.load_sound_effect("pickup", "crystal_mystery/assets/sounds/effects/pickup.ogg")
    audio.load_sound_effect("success", "crystal_mystery/assets/sounds/effects/success.ogg")

    # Play main menu music
    audio.play_music("main_theme", true)
  end

  private def create_game_items
    # Create inventory items
    brass_key = PointClickEngine::Inventory::InventoryItem.new("brass_key", "An ornate brass key")
    brass_key.load_icon("crystal_mystery/assets/items/brass_key.png")
    brass_key.usable_on = ["cabinet"]

    crystal_item = PointClickEngine::Inventory::InventoryItem.new("crystal", "A mysterious glowing crystal")
    crystal_item.load_icon("crystal_mystery/assets/items/crystal.png")

    mysterious_note = PointClickEngine::Inventory::InventoryItem.new("mysterious_note", "A cryptic note with strange symbols")
    mysterious_note.load_icon("crystal_mystery/assets/items/mysterious_note.png")
    mysterious_note.usable_on = ["ancient_tome"]

    research_notes = PointClickEngine::Inventory::InventoryItem.new("research_notes", "Scientific research about crystal properties")
    research_notes.load_icon("crystal_mystery/assets/items/research_notes.png")
    research_notes.usable_on = ["microscope"]

    crystal_lens = PointClickEngine::Inventory::InventoryItem.new("crystal_lens", "A special lens for enhancing crystal energy")
    crystal_lens.load_icon("crystal_mystery/assets/items/crystal_lens.png")
    crystal_lens.usable_on = ["crystal", "statue"]

    lamp_item = PointClickEngine::Inventory::InventoryItem.new("lamp", "An ornate oil lamp")
    lamp_item.load_icon("crystal_mystery/assets/items/lamp.png")
    lamp_item.usable_on = ["painting", "ancient_tome"]

    sign_item = PointClickEngine::Inventory::InventoryItem.new("sign", "A wooden sign with directions")
    sign_item.load_icon("crystal_mystery/assets/items/sign.png")

    # Store items for later use
    @game_items = {
      "brass_key"       => brass_key,
      "crystal"         => crystal_item,
      "mysterious_note" => mysterious_note,
      "research_notes"  => research_notes,
      "crystal_lens"    => crystal_lens,
      "lamp"            => lamp_item,
      "sign"            => sign_item,
    }
  end

  private def setup_global_input
    # Note: Global input handling would be implemented in the engine's main loop
    # For now, shortcuts are handled per-scene in the game logic
    # F5 = Quick Save, F9 = Quick Load, ESC = Main Menu
  end

  def handle_global_input
    # Handle verb-based mouse clicks
    if Raylib.mouse_button_pressed?(Raylib::MouseButton::Left.to_i)
      handle_verb_click
    elsif Raylib.mouse_button_pressed?(Raylib::MouseButton::Right.to_i)
      handle_look_click
    end

    # I = Toggle inventory
    if Raylib.key_pressed?(Raylib::KeyboardKey::I.to_i)
      @engine.inventory.visible = !@engine.inventory.visible
    end

    # F1 = Toggle debug mode
    if Raylib.key_pressed?(Raylib::KeyboardKey::F1.to_i)
      PointClickEngine::Core::Engine.debug_mode = !PointClickEngine::Core::Engine.debug_mode
    end

    # F2 = Toggle walkable area debug (when debug mode is on)
    if Raylib.key_pressed?(Raylib::KeyboardKey::F2.to_i) && PointClickEngine::Core::Engine.debug_mode
      # This is handled automatically by debug mode
    end

    # Tab = Toggle hotspot highlighting
    if Raylib.key_pressed?(Raylib::KeyboardKey::Tab.to_i)
      toggle_hotspot_highlight
    end

    # F5 = Quick Save
    if Raylib.key_pressed?(Raylib::KeyboardKey::F5.to_i)
      save_game("quicksave")
    end

    # F9 = Quick Load
    if Raylib.key_pressed?(Raylib::KeyboardKey::F9.to_i)
      if PointClickEngine::Core::SaveSystem.save_exists?("quicksave")
        load_game("quicksave")
      else
        @engine.dialog_manager.try &.show_message("No quicksave found!")
      end
    end

    # ESC = Back to main menu (if in game)
    if Raylib.key_pressed?(Raylib::KeyboardKey::Escape.to_i)
      current_scene_name = @engine.current_scene.try(&.name)
      if current_scene_name != "main_menu"
        back_to_main_menu
      end
    end
  end

  private def handle_verb_click
    return unless dm = @engine.display_manager
    return unless scene = @engine.current_scene

    mouse_pos = Raylib.get_mouse_position
    return unless dm.is_in_game_area(mouse_pos)

    game_mouse = dm.screen_to_game(mouse_pos)
    verb = @cursor_manager.get_current_action

    # Check inventory first
    if @engine.inventory.visible
      if item = @engine.inventory.get_item_at_position(game_mouse)
        # Handle inventory verb actions
        case verb
        when .look?
          @engine.dialog_manager.try &.show_message(item.description)
        when .use?
          # Use item - will be handled by inventory system
          return
        end
        return
      end
    end

    # Check hotspots
    if hotspot = scene.get_hotspot_at(game_mouse)
      # DEBUG: Found hotspot: #{hotspot.name} (#{hotspot.class})"
      execute_verb_on_hotspot(verb, hotspot, game_mouse)
    elsif character = scene.get_character_at(game_mouse)
      execute_verb_on_character(verb, character)
    else
      # No hotspot - handle walk
      if verb.walk?
        if player = scene.player
          puts "DEBUG: Walking to #{game_mouse}, player at #{player.position}"
          puts "DEBUG: Is target walkable? #{scene.is_walkable?(game_mouse)}"
          if player.use_pathfinding && scene.enable_pathfinding
            if path = scene.find_path(player.position.x, player.position.y, game_mouse.x, game_mouse.y)
              puts "DEBUG: Found path with #{path.size} waypoints"
              player.walk_to_with_path(path)
            else
              puts "DEBUG: No path found, direct walk"
              player.walk_to(game_mouse)
            end
          else
            puts "DEBUG: Using handle_click"
            if player.responds_to?(:handle_click)
              player.handle_click(game_mouse, scene)
            else
              player.walk_to(game_mouse)
            end
          end
        end
      end
    end
  end

  private def handle_look_click
    return unless dm = @engine.display_manager
    return unless scene = @engine.current_scene

    mouse_pos = Raylib.get_mouse_position
    return unless dm.is_in_game_area(mouse_pos)

    game_mouse = dm.screen_to_game(mouse_pos)

    # Always look, regardless of current verb
    if hotspot = scene.get_hotspot_at(game_mouse)
      @engine.dialog_manager.try &.show_message(hotspot.description)
    elsif character = scene.get_character_at(game_mouse)
      desc = "It's #{character.name}."
      @engine.dialog_manager.try &.show_message(desc)
    else
      @engine.dialog_manager.try &.show_message("Nothing interesting here.")
    end
  end

  private def execute_verb_on_hotspot(verb : PointClickEngine::UI::VerbType, hotspot : PointClickEngine::Scenes::Hotspot, pos : RL::Vector2)
    case verb
    when .walk?
      if hotspot.is_a?(PointClickEngine::Scenes::ExitZone)
        exit_zone = hotspot.as(PointClickEngine::Scenes::ExitZone)

        # Check if exit is accessible
        if !exit_zone.is_accessible?(@engine.inventory)
          if msg = exit_zone.locked_message
            @engine.dialog_manager.try &.show_message(msg)
          else
            @engine.dialog_manager.try &.show_message("You can't go there yet.")
          end
          return
        end

        # Perform the transition
        if exit_zone.auto_walk && (player = @engine.current_scene.try(&.player))
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
      elsif player = @engine.current_scene.try(&.player)
        player.walk_to(pos)
      end
    when .look?
      # Play examine animation
      if player = @engine.current_scene.try(&.player)
        if player.is_a?(PointClickEngine::Characters::Player)
          enhanced_player = player.as(PointClickEngine::Characters::Player)
          enhanced_player.examine_object(pos)
        end
      end

      @engine.dialog_manager.try &.show_message(hotspot.description)
    when .talk?
      @engine.dialog_manager.try &.show_message("I can't talk to that.")
    when .use?
      # Play use animation
      if player = @engine.current_scene.try(&.player)
        if player.is_a?(PointClickEngine::Characters::Player)
          enhanced_player = player.as(PointClickEngine::Characters::Player)
          enhanced_player.use_item_on_target(pos)
        end
      end

      # Check if it's an exit zone
      if hotspot.is_a?(PointClickEngine::Scenes::ExitZone)
        # Treat use on exit as walk
        execute_verb_on_hotspot(PointClickEngine::UI::VerbType::Walk, hotspot, pos)
        # Check if it's the cabinet and player has key
      elsif hotspot.name == "cabinet" && @engine.inventory.has_item?("key")
        @engine.inventory.remove_item("key")
        @engine.inventory.add_item(@game_items["crystal"])
        @engine.dialog_manager.try &.show_message("You unlock the cabinet with the key and find a glowing crystal!")
        @engine.audio_manager.try &.play_sound_effect("success")
      elsif hotspot.name == "magical_plant"
        # Water the plant
        state_val = @game_state_manager.get_variable("plant_watered")
        current_water = state_val.is_a?(Int32) ? state_val : 0
        @game_state_manager.set_variable("plant_watered", current_water + 1)

        case current_water
        when 0
          @engine.dialog_manager.try &.show_message("You water the seed. Something seems to be happening...")
        when 1
          @engine.dialog_manager.try &.show_message("The sprout grows taller!")
        when 2
          @engine.dialog_manager.try &.show_message("The plant is getting bigger!")
        else
          @engine.dialog_manager.try &.show_message("The plant is fully grown now.")
        end
      elsif hotspot.name == "puzzle_button"
        # Solve the puzzle
        @game_state_manager.set_variable("puzzle_solved", true)
        @engine.dialog_manager.try &.show_message("You press the button and hear a click. Something has changed...")
      else
        hotspot.on_click.try &.call
      end
    when .take?
      # Handle pickable items with animation
      if player = @engine.current_scene.try(&.player)
        if player.is_a?(PointClickEngine::Characters::Player)
          enhanced_player = player.as(PointClickEngine::Characters::Player)
          enhanced_player.pick_up_item(pos)
        end
      end

      if hotspot.name == "key_hotspot"
        @engine.inventory.add_item(@game_items["key"])
        hotspot.active = false # Hide the hotspot
        @engine.dialog_manager.try &.show_message("You picked up the key.")
        @engine.audio_manager.try &.play_sound_effect("pickup")
      elsif hotspot.name == "hidden_key"
        @engine.inventory.add_item(@game_items["key"])
        hotspot.active = false # Hide the hotspot
        @engine.dialog_manager.try &.show_message("You found a hidden key!")
        @engine.audio_manager.try &.play_sound_effect("pickup")
      else
        @engine.dialog_manager.try &.show_message("I can't take that.")
      end
    when .open?
      if hotspot.name == "cabinet"
        if @engine.inventory.has_item?("key")
          execute_verb_on_hotspot(PointClickEngine::UI::VerbType::Use, hotspot, pos)
        else
          @engine.dialog_manager.try &.show_message("It's locked. I need a key.")
        end
      else
        @engine.dialog_manager.try &.show_message("I can't open that.")
      end
    else
      @engine.dialog_manager.try &.show_message("I can't do that.")
    end
  end

  private def execute_verb_on_character(verb : PointClickEngine::UI::VerbType, character : PointClickEngine::Characters::Character)
    case verb
    when .talk?
      if player = @engine.current_scene.try(&.player)
        character.on_interact(player)
      end
    when .look?
      desc = "It's #{character.name}."
      @engine.dialog_manager.try &.show_message(desc)
    else
      @engine.dialog_manager.try &.show_message("I can't do that to #{character.name}.")
    end
  end

  private def toggle_hotspot_highlight
    @hotspot_highlight_enabled = !@hotspot_highlight_enabled

    if @hotspot_highlight_enabled
      # Create a pulsing outline shader effect for hotspots
      if shader_system = @engine.shader_system
        # Create outline shader with a nice golden color
        golden_color = Raylib::Color.new(r: 255, g: 215, b: 0, a: 255)
        PointClickEngine::Graphics::Shaders::ShaderHelpers.create_outline_shader(
          shader_system,
          golden_color,
          3.0f32
        )
      end
    end
  end

  private def back_to_main_menu
    @engine.change_scene("main_menu")
    @engine.audio_manager.try &.play_music("main_theme", true)
  end

  private def perform_exit_transition(exit_zone : PointClickEngine::Scenes::ExitZone)
    # DEBUG: Performing exit transition
    # Map transition types to graphics transition effects
    effect = case exit_zone.transition_type
             when .fade?
               PointClickEngine::Graphics::TransitionEffect::Fade
             when .slide?
               # Choose slide direction based on exit position
               if exit_zone.position.x < 100
                 PointClickEngine::Graphics::TransitionEffect::SlideLeft
               elsif exit_zone.position.x > 900
                 PointClickEngine::Graphics::TransitionEffect::SlideRight
               elsif exit_zone.position.y < 100
                 PointClickEngine::Graphics::TransitionEffect::SlideUp
               else
                 PointClickEngine::Graphics::TransitionEffect::SlideDown
               end
             when .iris?
               PointClickEngine::Graphics::TransitionEffect::Iris
             else
               PointClickEngine::Graphics::TransitionEffect::Fade
             end

    # Start the transition
    if tm = @engine.transition_manager
      tm.start_transition(effect, 0.5f32) do
        # This runs when transition reaches halfway
        @engine.change_scene(exit_zone.target_scene)

        # Set player position in new scene
        if (pos = exit_zone.target_position) && (player = @engine.player)
          player.position = pos
          player.stop_walking
        end
      end
    else
      # Fallback if no transition manager
      @engine.change_scene(exit_zone.target_scene)
      if (pos = exit_zone.target_position) && (player = @engine.player)
        player.position = pos
        player.stop_walking
      end
    end
  end

  private def setup_game_state_and_quests
    # Load quest definitions - use the new comprehensive quest file
    @quest_manager.load_quests_from_yaml("crystal_mystery/quests/main_quests.yaml")

    # Set up state change handlers for enhanced quest integration
    @game_state_manager.add_change_handler(->(name : String, value : PointClickEngine::GameValue) {
      # Update quest progress when state changes
      @quest_manager.update_all_quests(@game_state_manager, 0.0f32)

      # Handle specific state changes with detailed feedback
      case name
      when "lab_examined"
        if value == true
          @engine.dialog_manager.try &.show_floating_dialog(
            "Detective",
            "I've found some important clues here. Time to question the scientist.",
            @engine.player.try(&.position) || Raylib::Vector2.new(x: 400f32, y: 300f32),
            4.0f32,
            PointClickEngine::UI::DialogStyle::Thought
          )
        end
      when "scientist_questioned"
        if value == true
          @engine.dialog_manager.try &.show_floating_dialog(
            "Detective",
            "The scientist's story is suspicious. I should investigate the butler too.",
            @engine.player.try(&.position) || Raylib::Vector2.new(x: 400f32, y: 300f32),
            4.0f32,
            PointClickEngine::UI::DialogStyle::Thought
          )
        end
      when "butler_confronted"
        if value == true
          @engine.dialog_manager.try &.show_floating_dialog(
            "Detective",
            "The butler's confession changes everything. I need to check the library.",
            @engine.player.try(&.position) || Raylib::Vector2.new(x: 400f32, y: 300f32),
            4.0f32,
            PointClickEngine::UI::DialogStyle::Thought
          )
        end
      when "ancient_text_decoded"
        if value == true
          @engine.dialog_manager.try &.show_floating_dialog(
            "Detective",
            "These ancient symbols reveal the truth about the crystal's power!",
            @engine.player.try(&.position) || Raylib::Vector2.new(x: 400f32, y: 300f32),
            4.0f32,
            PointClickEngine::UI::DialogStyle::Shout
          )
        end
      when "crystal_restored"
        if value == true
          @engine.dialog_manager.try &.show_floating_dialog(
            "Detective",
            "The Crystal of Luminus is restored! The mystery is finally solved!",
            @engine.player.try(&.position) || Raylib::Vector2.new(x: 400f32, y: 300f32),
            5.0f32,
            PointClickEngine::UI::DialogStyle::Shout
          )

          # Trigger achievement and ending
          @engine.achievement_manager.try &.unlock("master_detective")
          start_ending_sequence
        end
      end
    })

    # Initialize starting game state with comprehensive flags
    @game_state_manager.set_flag("game_started", true)
    @game_state_manager.set_variable("investigation_progress", 0)
    @game_state_manager.set_flag("case_accepted", false)
    @game_state_manager.set_flag("workbench_examined", false)
    @game_state_manager.set_flag("cabinet_unlocked", false)
    @game_state_manager.set_flag("bookshelf_searched", false)
    @game_state_manager.set_flag("desk_searched", false)

    # Note: Quests will auto-activate based on their configuration

    # Update quests to check for auto-start
    @quest_manager.update_all_quests(@game_state_manager, 0.0f32)

    puts "Enhanced game state and quest system initialized!"
    puts @quest_manager.debug_dump
  end

  private def start_ending_sequence
    # Start final cutscene showing the crystal's restoration
    puts "Starting ending cutscene..."
    # TODO: Implement ending cutscene with particle effects and music
  end
end

# Run the game
game = CrystalMysteryGame.new
game.run
