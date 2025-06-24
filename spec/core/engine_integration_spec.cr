require "../spec_helper"

describe "Engine Integration with YAML Configuration" do
  before_each do
    # Ensure clean state
    PointClickEngine::Core::Engine.debug_mode = false
  end

  it "creates a minimal game from YAML configuration" do
    # Clean up any existing test directories
    FileUtils.rm_rf("test_minimal_game") if Dir.exists?("test_minimal_game")

    # Create minimal game structure
    Dir.mkdir_p("test_minimal_game/scenes")
    Dir.mkdir_p("test_minimal_game/scripts")
    Dir.mkdir_p("test_minimal_game/assets/sprites")

    # Create minimal config
    config_yaml = <<-YAML
    game:
      title: "Minimal Test Game"
    
    window:
      width: 640
      height: 480
    
    player:
      name: "TestHero"
      sprite_path: "assets/sprites/hero.png"
      sprite:
        frame_width: 32
        frame_height: 32
        columns: 4
        rows: 1
    
    assets:
      scenes: ["scenes/*.yaml"]
    
    start_scene: "test_room"
    YAML

    # Create a test scene
    scene_yaml = <<-YAML
    name: test_room
    background_path: "assets/bg.png"
    script_path: "scripts/test_room.lua"
    
    hotspots:
      - name: test_object
        x: 100
        y: 100
        width: 50
        height: 50
        description: "A test object"
    YAML

    File.write("test_minimal_game/scenes/test_room.yaml", scene_yaml)

    # Create dummy assets
    File.write("test_minimal_game/assets/bg.png", "dummy")
    File.write("test_minimal_game/assets/sprites/hero.png", "dummy")

    # Create test script
    lua_script = <<-LUA
    function on_enter()
      print("Entered test room")
    end
    
    hotspot.on_click("test_object", function()
      show_message("You clicked the test object!")
    end)
    LUA

    File.write("test_minimal_game/scripts/test_room.lua", lua_script)

    # Write config after creating all required files
    File.write("test_minimal_game/game_config.yaml", config_yaml)

    # Load and create engine
    config = PointClickEngine::Core::GameConfig.from_file("test_minimal_game/game_config.yaml")

    RL.init_window(640, 480, "Minimal Test Game")
    engine = config.create_engine

    # Verify engine is properly configured
    engine.title.should eq("Minimal Test Game")
    engine.window_width.should eq(640)
    engine.window_height.should eq(480)

    # Verify player is configured
    player = engine.player
    player.should_not be_nil
    player.try(&.name).should eq("TestHero")

    # Verify scene was loaded
    engine.scenes.has_key?("test_room").should be_true
    scene = engine.scenes["test_room"]
    scene.name.should eq("test_room")
    scene.hotspots.size.should eq(1)
    scene.hotspots.first.name.should eq("test_object")

    # Trigger game start
    engine.event_system.trigger("game:new")
    engine.event_system.process_events

    # Verify start scene is set
    engine.current_scene_name.should eq("test_room")

    # Cleanup
    RL.close_window
    FileUtils.rm_rf("test_minimal_game")
  end

  it "handles multiple scenes with transitions" do
    # Clean up any existing test directories
    FileUtils.rm_rf("test_multi_scene") if Dir.exists?("test_multi_scene")

    Dir.mkdir_p("test_multi_scene/scenes")
    Dir.mkdir_p("test_multi_scene/assets")

    config_yaml = <<-YAML
    game:
      title: "Multi-Scene Test"
    
    assets:
      scenes: ["scenes/*.yaml"]
    
    start_scene: "room1"
    YAML

    File.write("test_multi_scene/game_config.yaml", config_yaml)

    # Create first scene
    room1_yaml = <<-YAML
    name: room1
    background_path: "assets/room1.png"
    
    hotspots:
      - name: door
        type: exit
        x: 400
        y: 200
        width: 80
        height: 160
        target_scene: room2
        target_position:
          x: 100
          y: 300
        transition_type: fade
        description: "Door to room 2"
    YAML

    File.write("test_multi_scene/scenes/room1.yaml", room1_yaml)

    # Create second scene
    room2_yaml = <<-YAML
    name: room2
    background_path: "assets/room2.png"
    
    hotspots:
      - name: door_back
        type: exit
        x: 50
        y: 200
        width: 80
        height: 160
        target_scene: room1
        target_position:
          x: 350
          y: 300
        transition_type: fade
        description: "Back to room 1"
    YAML

    File.write("test_multi_scene/scenes/room2.yaml", room2_yaml)

    # Create dummy assets
    File.write("test_multi_scene/assets/room1.png", "dummy")
    File.write("test_multi_scene/assets/room2.png", "dummy")

    # Load config and create engine
    config = PointClickEngine::Core::GameConfig.from_file("test_multi_scene/game_config.yaml")

    RL.init_window(800, 600, "Multi-Scene Test")
    engine = config.create_engine

    # Verify both scenes loaded
    engine.scenes.size.should eq(2)
    engine.scenes.has_key?("room1").should be_true
    engine.scenes.has_key?("room2").should be_true

    # Verify exit hotspots
    room1 = engine.scenes["room1"]
    exit_hotspot = room1.hotspots.find { |h| h.name == "door" }
    exit_hotspot.should_not be_nil

    if exit_hs = exit_hotspot.as?(PointClickEngine::Scenes::ExitZone)
      exit_hs.target_scene.should eq("room2")
      exit_hs.target_position.should_not be_nil
      if pos = exit_hs.target_position
        pos.x.should eq(100)
        pos.y.should eq(300)
      end
      exit_hs.transition_type.should eq(PointClickEngine::Scenes::TransitionType::Fade)
    end

    # Cleanup
    RL.close_window
    FileUtils.rm_rf("test_multi_scene")
  end

  it "integrates quest system from YAML" do
    # Clean up any existing test directories
    FileUtils.rm_rf("test_quest_game") if Dir.exists?("test_quest_game")

    Dir.mkdir_p("test_quest_game/quests")
    Dir.mkdir_p("test_quest_game/scenes")

    config_yaml = <<-YAML
    game:
      title: "Quest Test"
    
    assets:
      scenes: ["scenes/*.yaml"]
      quests: ["quests/*.yaml"]
    
    initial_state:
      flags:
        game_started: true
    
    start_scene: "test_scene"
    YAML

    File.write("test_quest_game/game_config.yaml", config_yaml)

    # Create quest file
    quest_yaml = <<-YAML
    - id: find_key
      name: "Find the Key"
      description: "Search for the missing key"
      category: main
      auto_start: true
      start_condition: "game_started"
      objectives:
        - id: search_desk
          description: "Search the desk"
          condition: "desk_searched"
        - id: take_key
          description: "Take the key"
          condition: "has_item:key"
      rewards:
        - type: flag
          identifier: quest_complete
          amount: 1
        - type: variable
          identifier: experience
          amount: 100
    YAML

    File.write("test_quest_game/quests/main_quests.yaml", quest_yaml)

    # Create a minimal scene
    scene_yaml = <<-YAML
    name: test_scene
    YAML
    File.write("test_quest_game/scenes/test_scene.yaml", scene_yaml)

    # Load config and create engine
    config = PointClickEngine::Core::GameConfig.from_file("test_quest_game/game_config.yaml")

    RL.init_window(800, 600, "Quest Test")
    engine = config.create_engine

    # Verify quest manager exists
    qm = engine.quest_manager
    qm.should_not be_nil

    quest_manager = qm.not_nil!

    # Verify quest was loaded
    quest = quest_manager.get_quest("find_key")
    quest.should_not be_nil
    quest.try(&.name).should eq("Find the Key")
    quest.try(&.objectives.size).should eq(2)

    # Verify auto-start works
    quest_manager.update_all_quests(engine.game_state_manager.not_nil!, 0.0f32)
    quest.try(&.active).should be_true

    # Cleanup
    RL.close_window
    FileUtils.rm_rf("test_quest_game")
  end

  it "handles complex initial state setup" do
    config_yaml = <<-YAML
    game:
      title: "State Setup Test"
    
    initial_state:
      flags:
        has_sword: true
        defeated_boss: false
        found_secret: true
      variables:
        player_level: 5
        gold: 1000
        player_name: "Adventurer"
        completion_percentage: 25.5
    
    start_scene: "town"
    start_music: "town_theme"
    
    ui:
      opening_message: "Welcome back, adventurer!"
    YAML

    File.write("state_setup_test.yaml", config_yaml)
    config = PointClickEngine::Core::GameConfig.from_file("state_setup_test.yaml")

    RL.init_window(800, 600, "State Setup Test")
    engine = config.create_engine

    # Trigger game start
    engine.event_system.trigger("game:new")

    # Verify state was set up correctly
    gsm = engine.game_state_manager.not_nil!

    # Check flags
    gsm.get_flag("has_sword").should be_true
    gsm.get_flag("defeated_boss").should be_false
    gsm.get_flag("found_secret").should be_true

    # Check variables
    gsm.get_variable("player_level").should eq(5)
    gsm.get_variable("gold").should eq(1000)
    gsm.get_variable("player_name").should eq("Adventurer")
    gsm.get_variable("completion_percentage").should eq(25.5)

    # Cleanup
    RL.close_window
    File.delete("state_setup_test.yaml")
  end

  it "properly handles missing optional configuration" do
    # Absolute minimal config
    config_yaml = <<-YAML
    game:
      title: "Bare Minimum"
    YAML

    File.write("bare_minimum.yaml", config_yaml)
    config = PointClickEngine::Core::GameConfig.from_file("bare_minimum.yaml")

    RL.init_window(1024, 768, "Bare Minimum")
    engine = config.create_engine

    # Should use all defaults
    engine.window_width.should eq(1024)
    engine.window_height.should eq(768)
    engine.target_fps.should eq(60)
    engine.show_fps.should be_false
    engine.auto_save_interval.should eq(0.0f32)

    # No features should be enabled by default
    engine.verb_input_system.should be_nil
    PointClickEngine::Core::Engine.debug_mode.should be_false

    # No player by default
    engine.player.should be_nil

    # Empty collections
    engine.scenes.size.should eq(0)

    # Cleanup
    RL.close_window
    File.delete("bare_minimum.yaml")
  end
end
