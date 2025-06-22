require "../spec_helper"

describe "Minimal Game Example" do
  it "creates a working game with minimal configuration" do
    # Create the absolute minimal game
    minimal_config = <<-YAML
    game:
      title: "Minimal Adventure"
    YAML
    
    File.write("minimal_game.yaml", minimal_config)
    
    # The minimal game code
    config = PointClickEngine::Core::GameConfig.from_file("minimal_game.yaml")
    
    RL.init_window(1024, 768, "Minimal Adventure")
    engine = config.create_engine
    
    # Engine should be created with defaults
    engine.should_not be_nil
    engine.title.should eq("Minimal Adventure")
    engine.window_width.should eq(1024)
    engine.window_height.should eq(768)
    
    # Cleanup
    RL.close_window
    File.delete("minimal_game.yaml")
  end
  
  it "demonstrates the template usage" do
    # Use template-like configuration
    template_config = <<-YAML
    game:
      title: "My First Adventure"
      version: "1.0.0"
      author: "Game Developer"
    
    window:
      width: 1280
      height: 720
      fullscreen: false
      target_fps: 60
    
    features:
      - verbs
      - floating_dialogs
    
    assets:
      scenes: ["scenes/*.yaml"]
    
    start_scene: "intro"
    
    ui:
      hints:
        - text: "Click to move your character"
          duration: 5.0
        - text: "Press I for inventory"
          duration: 5.0
      opening_message: "Welcome to the adventure!"
    YAML
    
    File.write("template_game.yaml", template_config)
    config = PointClickEngine::Core::GameConfig.from_file("template_game.yaml")
    
    RL.init_window(1280, 720, "My First Adventure")
    engine = config.create_engine
    
    # Verify template configuration
    engine.title.should eq("My First Adventure")
    engine.window_width.should eq(1280)
    engine.window_height.should eq(720)
    engine.target_fps.should eq(60)
    
    # Features should be enabled
    engine.verb_input_system.should_not be_nil
    engine.dialog_manager.try(&.enable_floating).should be_true
    
    # Cleanup
    RL.close_window
    File.delete("template_game.yaml")
  end
  
  it "shows complete game setup in under 50 lines" do
    # Complete game directory structure
    Dir.mkdir_p("mini_game/scenes")
    Dir.mkdir_p("mini_game/scripts")
    
    # Game config
    game_config = <<-YAML
    game:
      title: "Mini Adventure"
    
    player:
      name: "Hero"
      sprite_path: "assets/hero.png"
      sprite:
        frame_width: 32
        frame_height: 32
        columns: 4
        rows: 1
    
    features:
      - verbs
    
    assets:
      scenes: ["mini_game/scenes/*.yaml"]
    
    start_scene: "start"
    YAML
    
    # Scene file
    scene_yaml = <<-YAML
    name: start
    background_path: assets/bg.png
    script_path: mini_game/scripts/start.lua
    
    hotspots:
      - name: door
        type: exit
        x: 400
        y: 200
        width: 100
        height: 200
        target_scene: next_room
        description: "A mysterious door"
    YAML
    
    # Script file
    lua_script = <<-LUA
    function on_enter()
      show_message("You stand before a mysterious door...")
    end
    
    hotspot.on_click("door", function()
      if has_item("key") then
        play_sound("unlock")
        change_scene("next_room")
      else
        show_message("The door is locked. You need a key.")
      end
    end)
    LUA
    
    # Main game file (Crystal)
    main_cr = <<-CRYSTAL
    require "point_click_engine"
    
    # Load configuration
    config = PointClickEngine::Core::GameConfig.from_file("mini_game.yaml")
    
    # Create and run game
    engine = config.create_engine
    engine.show_main_menu
    engine.run
    CRYSTAL
    
    # Save files
    File.write("mini_game.yaml", game_config)
    File.write("mini_game/scenes/start.yaml", scene_yaml)
    File.write("mini_game/scripts/start.lua", lua_script)
    File.write("mini_game_main.cr", main_cr)
    
    # Count lines
    total_lines = game_config.lines.size + 
                  scene_yaml.lines.size + 
                  lua_script.lines.size + 
                  main_cr.lines.size
    
    total_lines.should be < 50 # Complete game in under 50 lines!
    
    # Test it works
    config = PointClickEngine::Core::GameConfig.from_file("mini_game.yaml")
    RL.init_window(1024, 768, "Mini Adventure")
    engine = config.create_engine
    
    engine.scenes.has_key?("start").should be_true
    
    # Cleanup
    RL.close_window
    File.delete("mini_game.yaml")
    File.delete("mini_game/scenes/start.yaml")
    File.delete("mini_game/scripts/start.lua")
    File.delete("mini_game_main.cr")
    Dir.delete("mini_game/scenes")
    Dir.delete("mini_game/scripts")
    Dir.delete("mini_game")
  end
  
  it "demonstrates the power of data-driven design" do
    # Show how easy it is to modify without recompiling
    config_v1 = <<-YAML
    game:
      title: "Adventure v1"
    
    window:
      width: 800
      height: 600
    
    settings:
      master_volume: 0.5
    YAML
    
    File.write("game_v1.yaml", config_v1)
    config = PointClickEngine::Core::GameConfig.from_file("game_v1.yaml")
    
    RL.init_window(800, 600, "Adventure v1")
    engine1 = config.create_engine
    
    engine1.window_width.should eq(800)
    engine1.audio_manager.try(&.master_volume).should eq(0.5)
    
    RL.close_window
    
    # Now "modify" the game without changing code
    config_v2 = <<-YAML
    game:
      title: "Adventure v2 Enhanced"
    
    window:
      width: 1920
      height: 1080
    
    features:
      - shaders
      - portraits
    
    settings:
      master_volume: 0.8
      show_fps: true
    YAML
    
    File.write("game_v2.yaml", config_v2)
    config2 = PointClickEngine::Core::GameConfig.from_file("game_v2.yaml")
    
    RL.init_window(1920, 1080, "Adventure v2 Enhanced")
    engine2 = config2.create_engine
    
    # Everything changed without touching code!
    engine2.window_width.should eq(1920)
    engine2.audio_manager.try(&.master_volume).should eq(0.8)
    engine2.show_fps.should be_true
    engine2.shader_system.should_not be_nil
    
    # Cleanup
    RL.close_window
    File.delete("game_v1.yaml")
    File.delete("game_v2.yaml")
  end
end