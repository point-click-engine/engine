require "../src/point_click_engine"

# Example demonstrating cutscenes
class CutsceneExample < PointClickEngine::Core::Game
  def initialize
    super(title: "Cutscene Example", width: 1280, height: 960)
  end

  def load_content
    # Create scenes
    create_intro_scene
    create_main_scene

    # Create cutscenes
    create_intro_cutscene
    create_interaction_cutscene

    # Start with intro cutscene
    PointClickEngine::Core::Engine.instance.change_scene("intro")
    PointClickEngine::Core::Engine.instance.cutscene_manager.play_cutscene("intro")
  end

  private def create_intro_scene
    scene = PointClickEngine::Scenes::Scene.new("intro")

    # Add background
    bg_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/room.png")
    scene.set_background(bg_texture)

    # Add player off-screen
    player = PointClickEngine::Characters::Player.new("hero", -100, 400, 32, 48)
    player_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/character.png")
    player.sprite = PointClickEngine::Graphics::AnimatedSprite.new(player_texture, 32, 48)
    player.sprite.not_nil!.add_animation("idle", [0])
    player.sprite.not_nil!.add_animation("walk", [0, 1, 2, 3])
    player.sprite.not_nil!.play("idle")
    player.walking_speed = 150.0
    scene.add_character(player)
    scene.player = player

    PointClickEngine::Core::Engine.instance.add_scene(scene)
  end

  private def create_main_scene
    scene = PointClickEngine::Scenes::Scene.new("main")

    # Add background
    bg_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/room.png")
    scene.set_background(bg_texture)

    # Add player
    player = PointClickEngine::Characters::Player.new("hero", 400, 400, 32, 48)
    player_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/character.png")
    player.sprite = PointClickEngine::Graphics::AnimatedSprite.new(player_texture, 32, 48)
    player.sprite.not_nil!.add_animation("idle", [0])
    player.sprite.not_nil!.add_animation("walk", [0, 1, 2, 3])
    player.sprite.not_nil!.play("idle")
    scene.add_character(player)
    scene.player = player

    # Add NPC
    npc = PointClickEngine::Characters::NPC.new("guide", 600, 400, 32, 48)
    npc.sprite = PointClickEngine::Graphics::AnimatedSprite.new(player_texture, 32, 48)
    npc.sprite.not_nil!.add_animation("idle", [0])
    npc.sprite.not_nil!.play("idle")
    npc.on_interact = ->(interactor : PointClickEngine::Characters::Character) {
      # Play interaction cutscene
      PointClickEngine::Core::Engine.instance.cutscene_manager.play_cutscene("interaction")
    }
    scene.add_character(npc)

    # Add interactive door
    door = PointClickEngine::Scenes::Hotspot.new("door",
      Raylib::Vector2.new(x: 200, y: 300),
      Raylib::Vector2.new(x: 80, y: 120))
    door.description = "A mysterious door"
    door.on_click = -> {
      puts "The door is locked. You need to talk to the guide first."
    }
    scene.add_hotspot(door)

    PointClickEngine::Core::Engine.instance.add_scene(scene)
  end

  private def create_intro_cutscene
    engine = PointClickEngine::Core::Engine.instance
    manager = engine.cutscene_manager

    # Get references
    intro_scene = engine.scenes["intro"]
    return unless intro_scene

    player = intro_scene.player
    return unless player

    # Create intro cutscene
    manager.create_cutscene("intro") do
      # Fade in from black
      fade_in(2.0f32)

      # Move player into scene
      move_character(player, Raylib::Vector2.new(400, 400), false)

      # Player speaks
      dialog(player, "Where am I? This place looks familiar...", 3.0f32)
      wait(0.5f32)

      dialog(player, "I should look around and see if anyone can help me.", 3.0f32)

      # Fade out
      fade_out(1.0f32)

      # Change to main scene
      change_scene("main")

      # Fade back in
      fade_in(1.0f32)

      # Show UI
      show_ui

      # Tutorial message
      run {
        puts "Tutorial: Click to move, click on characters to interact"
      }
    end
  end

  private def create_interaction_cutscene
    engine = PointClickEngine::Core::Engine.instance
    manager = engine.cutscene_manager

    # Create interaction cutscene
    manager.create_cutscene("interaction") do
      # Hide UI during conversation
      hide_ui

      # Get characters from current scene
      run {
        if scene = engine.current_scene
          if player = scene.player
            if npc = scene.get_character("guide")
              # Face each other
              player.direction = PointClickEngine::Characters::Direction::Right
              npc.direction = PointClickEngine::Characters::Direction::Left

              # Start conversation
              npc.say("Welcome, traveler! I've been expecting you.") { }
            end
          end
        end
      }

      wait(3.0f32)

      run {
        if scene = engine.current_scene
          if player = scene.player
            player.say("Expecting me? But I don't even know where I am!") { }
          end
        end
      }

      wait(3.0f32)

      run {
        if scene = engine.current_scene
          if npc = scene.get_character("guide")
            npc.say("All will be revealed in time. First, you must prove yourself worthy.") { }
          end
        end
      }

      wait(3.0f32)

      run {
        if scene = engine.current_scene
          if npc = scene.get_character("guide")
            npc.say("The door behind me leads to the trials. Are you ready?") { }
          end
        end
      }

      wait(3.0f32)

      # Parallel actions - both characters move
      parallel do
        run {
          if scene = engine.current_scene
            if player = scene.player
              player.walk_to(Raylib::Vector2.new(300, 400))
            end
          end
        }

        run {
          if scene = engine.current_scene
            if npc = scene.get_character("guide")
              npc.walk_to(Raylib::Vector2.new(500, 300))
            end
          end
        }
      end

      wait(2.0f32)

      # Show UI again
      show_ui

      run {
        puts "The guide has moved aside. You can now interact with the door."
      }
    end
  end

  def update(dt : Float32)
    super(dt)

    # Show cutscene status
    if PointClickEngine::Core::Engine.instance.cutscene_manager.is_playing?
      Raylib.draw_text("Cutscene Playing", 10, 50, 24, Raylib::YELLOW)
    else
      Raylib.draw_text("Cutscene Example", 10, 50, 24, Raylib::WHITE)
      Raylib.draw_text("Click on the guide to trigger a cutscene", 10, 80, 16, Raylib::WHITE)
    end
  end
end

# Run the example
example = CutsceneExample.new
example.run
