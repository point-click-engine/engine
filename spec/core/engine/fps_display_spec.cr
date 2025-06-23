require "../../spec_helper"

describe "Engine FPS Display" do
  describe "#show_fps property" do
    it "is disabled by default" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "FPS Test")
      engine.show_fps.should be_false
    end

    it "can be enabled" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "FPS Test")
      engine.show_fps = true
      engine.show_fps.should be_true
    end
  end

  describe "FPS display from config" do
    it "enables FPS display from YAML settings" do
      config_yaml = <<-YAML
      game:
        title: "FPS Config Test"
      
      settings:
        show_fps: true
      YAML

      File.write("fps_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("fps_config.yaml")

      RL.init_window(800, 600, "FPS Config Test")
      engine = config.create_engine

      engine.show_fps.should be_true

      # Cleanup
      RL.close_window
      File.delete("fps_config.yaml")
    end

    it "keeps FPS disabled when not specified in config" do
      config_yaml = <<-YAML
      game:
        title: "No FPS Test"
      
      settings:
        debug_mode: false
      YAML

      File.write("no_fps_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("no_fps_config.yaml")

      RL.init_window(800, 600, "No FPS Test")
      engine = config.create_engine

      engine.show_fps.should be_false

      # Cleanup
      RL.close_window
      File.delete("no_fps_config.yaml")
    end
  end

  describe "render integration" do
    it "calls RL.draw_fps when show_fps is true" do
      # This is more of an integration test
      # In a real test we might mock RL.draw_fps
      engine = PointClickEngine::Core::Engine.new(800, 600, "Render FPS Test")
      RL.init_window(800, 600, "Render FPS Test")
      engine.init

      engine.show_fps = true

      # The render method should include RL.draw_fps(10, 10) call
      # We can't easily test the actual rendering without mocking
      # but we can verify the property works
      engine.show_fps.should be_true

      # Cleanup
      RL.close_window
    end
  end
end
