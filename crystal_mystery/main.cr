require "yaml"
require "json"
require "../src/point_click_engine"

# The Crystal Mystery - A Point & Click Adventure Game
class CrystalMysteryGame
  property engine : PointClickEngine::Core::Engine
  property game_items : Hash(String, PointClickEngine::Inventory::InventoryItem) = {} of String => PointClickEngine::Inventory::InventoryItem
  property game_state_manager : PointClickEngine::GameStateManager
  property quest_manager : PointClickEngine::QuestManager

  def initialize
    @engine = PointClickEngine::Core::Engine.new(1024, 768, "The Crystal Mystery")
    @engine.init
    
    # Enable verb-based input system
    @engine.enable_verb_input

    # Enable all engine systems
    @engine.script_engine = PointClickEngine::Scripting::ScriptEngine.new
    @engine.dialog_manager = PointClickEngine::UI::DialogManager.new
    @engine.achievement_manager = PointClickEngine::Core::AchievementManager.new
    @engine.audio_manager = PointClickEngine::Audio::AudioManager.new
    @engine.config = PointClickEngine::Core::ConfigManager.new
    @engine.gui = PointClickEngine::UI::GUIManager.new
    @engine.shader_system = PointClickEngine::Graphics::Shaders::ShaderSystem.new
    @game_state_manager = PointClickEngine::GameStateManager.new
    @quest_manager = PointClickEngine::QuestManager.new

    # Enable floating dialogs
    @engine.dialog_manager.try do |dm|
      dm.enable_floating = true
      dm.enable_portraits = false
    end
    player = PointClickEngine::Characters::Player.new(
      "Detective",
      Raylib::Vector2.new(x: 500f32, y: 400f32),
      Raylib::Vector2.new(x: 64f32, y: 128f32)
    )
    player.load_enhanced_spritesheet("assets/sprites/player.png", 56, 56, 8, 4)
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

    # Create game scenes
    create_game_scenes

    # Initialize shaders
    setup_shaders

    # Set up game events
    setup_game_events

    # Initialize game state and quests
    setup_game_state_and_quests
    
    # Set up game update callback
    @engine.on_update = ->(dt : Float32) {
      # Update game-specific systems
      @game_state_manager.update_timers(dt)
      @game_state_manager.update_game_time(dt)
      @quest_manager.update_all_quests(@game_state_manager, dt)
    }
    
    # Load an initial scene (even if just for background during menu)
    @engine.change_scene("library")
    
    # Show main menu
    @engine.show_main_menu
  end

  def run
    # The engine handles the main game loop
    @engine.run
  end

  # Removed - now handled by engine's render system

  # Removed - now handled by engine's RenderCoordinator

  # Removed - now handled by engine's debug overlay

  private def load_configuration
    # Load game settings
    @engine.config.try do |config|
      config.set("game.version", "1.0.0")
      config.set("game.debug", "false")
      config.set("audio.master_volume", "0.8")
      config.set("graphics.fullscreen", "false")
    end
  end

  # Removed - now using engine's MenuSystem

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
        sprite_path: assets/sprites/butler.png
        sprite_info:
          frame_width: 100
          frame_height: 100
    YAML

    # Write YAML to temp file and load using SceneLoader
    File.write("temp_library.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("temp_library.yaml")
    File.delete("temp_library.yaml")

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
        sprite_path: assets/sprites/scientist.png
        sprite_info:
          frame_width: 100
          frame_height: 100
    YAML

    # Write YAML to temp file and load using SceneLoader  
    File.write("temp_laboratory.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("temp_laboratory.yaml")
    File.delete("temp_laboratory.yaml")

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

    # Write YAML to temp file and load using SceneLoader
    File.write("temp_garden.yaml", scene_yaml)
    scene = PointClickEngine::Scenes::SceneLoader.load_from_yaml("temp_garden.yaml")
    File.delete("temp_garden.yaml")

    setup_garden_interactions(scene)

    @engine.add_scene(scene)
  end

  private def setup_library_interactions(scene : PointClickEngine::Scenes::Scene)
    # Mark that player has visited the library
    @game_state_manager.set_flag("visited_library", true)

    # Debug: List all characters in scene
    puts "Characters in library scene:"
    scene.characters.each do |character|
      puts "  - #{character.name} at #{character.position}"
    end
    
    # Debug: List all hotspots in scene
    puts "Hotspots in library scene:"
    scene.hotspots.each do |hotspot|
      puts "  - #{hotspot.name} at #{hotspot.position} (#{hotspot.size})"
    end

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

      # Don't apply vignette by default - it might be causing rendering issues
      # shader_system.set_active(:vignette)
    end
  end

  private def start_new_game
    puts "=== STARTING NEW GAME ==="
    
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
    @game_state_manager = PointClickEngine::GameStateManager.new
    setup_game_state_and_quests

    # Start in library (but don't change if already there)
    if @engine.current_scene_name != "library"
      @engine.change_scene("library")
    end

    # Change music when entering library
    @engine.audio_manager.try &.play_music("castle_ambient", true)

    # Add player to the current scene (not from scenes hash)
    if current_scene = @engine.current_scene
      if player = @engine.player
        current_scene.set_player(player)
        puts "Player added to current scene (#{current_scene.name}) at position: #{player.position}"
      else
        puts "ERROR: No player found!"
      end
    else
      puts "ERROR: No current scene!"
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
    
    # Setup custom verb handlers
    setup_verb_handlers
    setup_character_handlers
    
    # Start the game
    @engine.start_game
  end

  # Removed - now handled by MenuSystem

  private def load_audio_assets
    return unless @engine.audio_manager

    audio = @engine.audio_manager.not_nil!

    # Load music tracks
    audio.load_music("main_theme", "assets/music/main_theme.ogg")
    audio.load_music("garden_theme", "assets/music/garden_theme.ogg")
    audio.load_music("castle_ambient", "assets/sounds/music/castle_ambient.ogg")

    # Load sound effects
    audio.load_sound_effect("click", "assets/sounds/effects/click.ogg")
    audio.load_sound_effect("door_open", "assets/sounds/effects/door_open.ogg")
    audio.load_sound_effect("footsteps", "assets/sounds/effects/footsteps.ogg")
    audio.load_sound_effect("pickup", "assets/sounds/effects/pickup.ogg")
    audio.load_sound_effect("success", "assets/sounds/effects/success.ogg")

    # Play main menu music
    audio.play_music("main_theme", true)
  end

  private def create_game_items
    # Create inventory items
    brass_key = PointClickEngine::Inventory::InventoryItem.new("brass_key", "An ornate brass key")
    brass_key.load_icon("assets/items/brass_key.png")
    brass_key.usable_on = ["cabinet"]

    crystal_item = PointClickEngine::Inventory::InventoryItem.new("crystal", "A mysterious glowing crystal")
    crystal_item.load_icon("assets/items/crystal.png")

    mysterious_note = PointClickEngine::Inventory::InventoryItem.new("mysterious_note", "A cryptic note with strange symbols")
    mysterious_note.load_icon("assets/items/mysterious_note.png")
    mysterious_note.usable_on = ["ancient_tome"]

    research_notes = PointClickEngine::Inventory::InventoryItem.new("research_notes", "Scientific research about crystal properties")
    research_notes.load_icon("assets/items/research_notes.png")
    research_notes.usable_on = ["microscope"]

    crystal_lens = PointClickEngine::Inventory::InventoryItem.new("crystal_lens", "A special lens for enhancing crystal energy")
    crystal_lens.load_icon("assets/items/crystal_lens.png")
    crystal_lens.usable_on = ["crystal", "statue"]

    lamp_item = PointClickEngine::Inventory::InventoryItem.new("lamp", "An ornate oil lamp")
    lamp_item.load_icon("assets/items/lamp.png")
    lamp_item.usable_on = ["painting", "ancient_tome"]

    sign_item = PointClickEngine::Inventory::InventoryItem.new("sign", "A wooden sign with directions")
    sign_item.load_icon("assets/items/sign.png")

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

  private def setup_game_events
    # Set up event handlers for menu system
    puts "Setting up game:new event handler"
    @engine.event_system.on("game:new") do
      puts "game:new event received!"
      start_new_game
    end
    
    @engine.event_system.on("game:main_menu") do
      # Clean up current game state
      @engine.gui.try &.clear_all
      @engine.change_scene("library") # Keep a scene loaded
    end
  end

  # Removed - now handled by engine's input systems

  # Removed - now handled by VerbInputSystem

  # Removed - now handled by VerbInputSystem

  # Custom verb handlers for game-specific interactions
  private def setup_verb_handlers
    return unless verb_system = @engine.verb_input_system
    
    # Register custom handlers for specific game logic
    verb_system.register_verb_handler(PointClickEngine::UI::VerbType::Use) do |hotspot, pos|
      case hotspot.name
      when "cabinet"
        if @engine.inventory.has_item?("brass_key")
          @engine.inventory.remove_item("brass_key")
          @engine.inventory.add_item(@game_items["crystal"])
          @engine.dialog_manager.try &.show_message("You unlock the cabinet with the key and find a glowing crystal!")
          @engine.audio_manager.try &.play_sound_effect("success")
          @game_state_manager.set_flag("cabinet_unlocked", true)
        else
          @engine.dialog_manager.try &.show_message("The cabinet is locked. You need a key.")
        end
      when "magical_plant"
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
      when "puzzle_button"
        # Solve the puzzle
        @game_state_manager.set_variable("puzzle_solved", true)
        @engine.dialog_manager.try &.show_message("You press the button and hear a click. Something has changed...")
      else
        # Default use behavior
        hotspot.on_click.try &.call
      end
    end
    
    verb_system.register_verb_handler(PointClickEngine::UI::VerbType::Take) do |hotspot, pos|
      case hotspot.name
      when "key_hotspot", "hidden_key"
        @engine.inventory.add_item(@game_items["brass_key"])
        hotspot.active = false # Hide the hotspot
        @engine.dialog_manager.try &.show_message("You found a brass key!")
        @engine.audio_manager.try &.play_sound_effect("pickup")
        @game_state_manager.set_flag("has_key", true)
      else
        @engine.dialog_manager.try &.show_message("I can't take that.")
      end
    end
  end

  # Custom character verb handlers
  private def setup_character_handlers
    return unless verb_system = @engine.verb_input_system
    
    verb_system.register_character_verb_handler(PointClickEngine::UI::VerbType::Talk) do |character|
      case character.name.downcase
      when "butler"
        show_butler_dialog(character)
      when "librarian"
        show_librarian_dialog(character)
      when "scientist"
        show_scientist_dialog(character)
      else
        # Default character interaction
        if player = @engine.player
          character.on_interact(player)
        end
      end
    end
  end
  
  private def show_butler_dialog(character : PointClickEngine::Characters::Character)
    # Butler dialog with floating text
    show_character_dialog("butler", "Welcome to the mansion, Detective. The master is quite concerned about the missing crystal.", character.position)

    # Show dialog choices after a delay
    spawn do
      sleep 3.seconds
      @engine.dialog_manager.try &.show_dialog_choices("What would you like to ask the butler?", [
        "Tell me about the crystal",
        "Who else is in the mansion?",
        "Where should I start looking?",
        "That's all for now",
      ]) do |choice|
        case choice
        when 0
          show_character_dialog("butler", "The crystal has been in the family for generations. It has... unusual properties.", character.position)
        when 1
          show_character_dialog("butler", "The scientist is in the laboratory, and the gardener tends to the plants outside.", character.position)
        when 2
          show_character_dialog("butler", "Perhaps you should check the library. The master keeps many secrets there.", character.position)
        when 3
          show_character_dialog("detective", "Thank you, that's helpful.", @engine.player.try(&.position) || Raylib::Vector2.new(x: 400, y: 400))
        end
      end
    end
  end
  
  private def show_librarian_dialog(character : PointClickEngine::Characters::Character)
    # Librarian dialog with floating text and choices
    show_character_dialog("librarian", "Ah, a visitor! Are you here about the mysterious crystal?", character.position)

    spawn do
      sleep 3.seconds
      @engine.dialog_manager.try &.show_dialog_choices("What would you like to discuss with the librarian?", [
        "What do you know about the crystal?",
        "Have you seen anything suspicious?",
        "Can I look at some books?",
        "Do you have a key to the cabinet?",
        "Goodbye",
      ]) do |choice|
        case choice
        when 0
          show_character_dialog("librarian", "The crystal is mentioned in several ancient texts. It's said to have the power to reveal hidden truths.", character.position)
          # Update quest state
          @game_state_manager.set_flag("learned_about_crystal", true)
        when 1
          show_character_dialog("librarian", "I did notice the butler acting strangely near the garden last night...", character.position)
        when 2
          show_character_dialog("librarian", "Of course! The ancient texts are on the top shelf. Be careful with them.", character.position)
          # Enable book interaction
          @game_state_manager.set_variable("can_read_books", true)
        when 3
          if @game_state_manager.get_variable("talked_to_gardener") == true
            show_character_dialog("librarian", "Ah yes, I do have a spare key. The gardener mentioned you might need it. Here you go.", character.position)
            @engine.inventory.add_item(@game_items["brass_key"])
            @engine.audio_manager.try &.play_sound_effect("pickup")
          else
            show_character_dialog("librarian", "A key? I might have one, but you should speak to the gardener first.", character.position)
          end
        when 4
          show_character_dialog("detective", "Thank you for your help.", @engine.player.try(&.position) || Raylib::Vector2.new(x: 400, y: 400))
        end
      end
    end
  end
  
  private def show_scientist_dialog(character : PointClickEngine::Characters::Character)
    show_character_dialog("scientist", "I've been studying the crystal's properties. It's quite fascinating!", character.position)
    
    spawn do
      sleep 3.seconds
      @engine.dialog_manager.try &.show_dialog_choices("What would you like to ask the scientist?", [
        "What have you discovered?",
        "Is the crystal dangerous?",
        "How does it work?",
        "That's all for now",
      ]) do |choice|
        case choice
        when 0
          show_character_dialog("scientist", "The crystal resonates with certain frequencies. It seems to respond to intentions.", character.position)
          @game_state_manager.set_flag("learned_crystal_science", true)
        when 1
          show_character_dialog("scientist", "Not dangerous per se, but it can be... unpredictable in the wrong hands.", character.position)
        when 2
          show_character_dialog("scientist", "It appears to amplify psychic energy. Quite remarkable, really!", character.position)
        when 3
          show_character_dialog("detective", "Thank you for the information.", @engine.player.try(&.position) || Raylib::Vector2.new(x: 400, y: 400))
        end
      end
    end
  end

  # Removed - now handled by engine's hotspot highlighting

  # Removed - now handled by menu system

  # Helper method to show floating dialog for a character
  private def show_character_dialog(character_name : String, text : String, position : Raylib::Vector2)
    if dm = @engine.dialog_manager
      dm.show_character_dialog(character_name, text, position)
    end
  end

  # Removed - now handled by VerbInputSystem

  private def setup_game_state_and_quests
    # Load quest definitions - use the new comprehensive quest file
    @quest_manager.load_quests_from_yaml("quests/main_quests.yaml")

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
