require "../spec_helper"

# Set headless mode before requiring the game
ENV["HEADLESS_MODE"] = "true"

require "../../crystal_mystery/main"

describe "Crystal Mystery Game Integration" do
  before_each do
    # Reset mock state between tests
    {% if env("HEADLESS_MODE") == "true" %}
      RaylibMock::MockRaylib.reset_mock_state
    {% end %}
  end

  describe "Game Initialization" do
    it "creates the game successfully" do
      game = CrystalMysteryGame.new
      game.should_not be_nil
      game.engine.should_not be_nil
    end

    it "initializes all required managers" do
      game = CrystalMysteryGame.new
      game.engine.script_engine.should_not be_nil
      game.engine.dialog_manager.should_not be_nil
      game.engine.achievement_manager.should_not be_nil
      game.engine.audio_manager.should_not be_nil
      game.engine.gui.should_not be_nil
      game.engine.config.should_not be_nil
      game.engine.player.should_not be_nil
    end

    it "creates all game scenes" do
      game = CrystalMysteryGame.new
      game.engine.scenes.keys.should contain("main_menu")
      game.engine.scenes.keys.should contain("library")
      game.engine.scenes.keys.should contain("laboratory")
      game.engine.scenes.keys.should contain("garden")
    end

    it "starts with main menu scene" do
      game = CrystalMysteryGame.new
      game.engine.current_scene.try(&.name).should eq("main_menu")
    end
  end

  describe "Save/Load System" do
    it "can save and load game state" do
      game = CrystalMysteryGame.new

      # Change to a game scene
      game.engine.change_scene("library")

      # Modify some state
      game.engine.player.try do |player|
        player.position = Raylib::Vector2.new(x: 123f32, y: 456f32)
      end

      # Save the game
      save_success = PointClickEngine::Core::SaveSystem.save_game(game.engine, "test_save")
      save_success.should be_true

      # Reset player position
      game.engine.player.try do |player|
        player.position = Raylib::Vector2.new(x: 0f32, y: 0f32)
      end

      # Load the game
      load_success = PointClickEngine::Core::SaveSystem.load_game(game.engine, "test_save")
      load_success.should be_true

      # Verify position was restored
      game.engine.player.try do |player|
        player.position.x.should be_close(123f32, 0.1f32)
        player.position.y.should be_close(456f32, 0.1f32)
      end

      # Clean up
      PointClickEngine::Core::SaveSystem.delete_save("test_save")
    end
  end

  describe "Options Menu" do
    it "handles volume changes" do
      game = CrystalMysteryGame.new

      # Test volume configuration
      config = game.engine.config
      config.should_not be_nil

      if cfg = config
        cfg.set("audio.master_volume", "0.5")
        volume = cfg.get("audio.master_volume", "0.8").to_f32
        volume.should eq(0.5f32)
      end
    end

    it "handles graphics settings" do
      game = CrystalMysteryGame.new

      config = game.engine.config
      if cfg = config
        cfg.set("graphics.fullscreen", "true")
        fullscreen = cfg.get("graphics.fullscreen", "false")
        fullscreen.should eq("true")
      end
    end
  end
end
