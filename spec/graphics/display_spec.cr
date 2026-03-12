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
  end
end
