require "../spec_helper"

describe PointClickEngine::Graphics::FrameContext do
  it "tracks logical, scene, and screen rects separately" do
    display = PointClickEngine::Graphics::Display.new(1920, 1200, 1280, 720)
    camera = PointClickEngine::Graphics::Camera.new
    context = PointClickEngine::Graphics::FrameContext.new(display, camera, 1280, 720, 2048, 1024, 320, 180)

    context.logical_rect.width.should eq(1280.0f32)
    context.logical_rect.height.should eq(720.0f32)
    context.scene_rect.width.should eq(2048.0f32)
    context.scene_rect.height.should eq(1024.0f32)
    context.screen_rect.width.should be_close(1920.0f32, 0.01f32)
    context.screen_rect.height.should be_close(1080.0f32, 0.01f32)
    context.cinematic_rect.width.should eq(320.0f32)
    context.cinematic_rect.height.should eq(180.0f32)
  end

  it "converts world coordinates into logical UI coordinates through the camera" do
    display = PointClickEngine::Graphics::Display.new(1024, 768, 1024, 768)
    camera = PointClickEngine::Graphics::Camera.new(120.0f32, 80.0f32)
    context = PointClickEngine::Graphics::FrameContext.new(display, camera, 1024, 768, 2048, 1536)

    ui_pos = context.world_to_ui(RL::Vector2.new(x: 220.0f32, y: 180.0f32))
    ui_pos.x.should eq(100.0f32)
    ui_pos.y.should eq(100.0f32)
  end
end
