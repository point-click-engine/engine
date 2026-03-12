require "../spec_helper"

describe PointClickEngine::Graphics::Display do
  describe "reference resolution contract" do
    it "uses the configured reference resolution for the active game area" do
      display = PointClickEngine::Graphics::Display.new(1920, 1200, 1280, 720)

      display.reference_width.should eq(1280)
      display.reference_height.should eq(720)

      rect = display.active_game_area_rect
      rect.x.should eq(0.0f32)
      rect.y.should be_close(60.0f32, 0.01f32)
      rect.width.should be_close(1920.0f32, 0.01f32)
      rect.height.should be_close(1080.0f32, 0.01f32)
    end

    it "maps screen coordinates back into the configured logical space" do
      display = PointClickEngine::Graphics::Display.new(1920, 1200, 1280, 720)

      game_center = display.screen_to_game(RL::Vector2.new(x: 960.0f32, y: 600.0f32))
      game_center.x.should be_close(640.0f32, 0.01f32)
      game_center.y.should be_close(360.0f32, 0.01f32)
    end

    it "refreshes fullscreen dimensions from the monitor instead of the logical render size" do
      display = PointClickEngine::Graphics::Display.new(1024, 768, 1024, 768)

      RL.init_window(1024, 768, "Display spec")
      RL.toggle_fullscreen
      display.refresh_from_window
      monitor = RL.get_current_monitor
      monitor_width = RL.get_monitor_width(monitor)
      monitor_height = RL.get_monitor_height(monitor)

      rect = display.active_game_area_rect
      display.window_width.should eq(monitor_width)
      display.window_height.should eq(monitor_height)
      expected_scale = Math.min(monitor_width.to_f32 / 1024.0f32, monitor_height.to_f32 / 768.0f32)
      rect.width.should be_close(1024.0f32 * expected_scale, 0.01f32)
      rect.height.should be_close(768.0f32 * expected_scale, 0.01f32)
      rect.x.should be_close((monitor_width.to_f32 - rect.width) / 2.0f32, 0.01f32)
      rect.y.should be_close((monitor_height.to_f32 - rect.height) / 2.0f32, 0.01f32)

      RL.toggle_fullscreen
      RL.close_window if RL.window_ready?
    end
  end
end
