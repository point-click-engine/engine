require "../../spec_helper"

# Tests for scene effects
# NOTE: These tests require a graphics context (GPU) for shader/render texture creation.
# They may crash or hang in headless CI environments without proper GPU support.
# Run these tests locally with a display available.
#
# To run these tests specifically: crystal spec spec/graphics/effects/scene_effects_spec.cr
describe PointClickEngine::Graphics::Effects::SceneEffects do
  describe "SceneEffectFactory types" do
    # These tests verify factory method routing without requiring GPU
    it "returns nil for unknown effects" do
      unknown = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("unknown_effect")
      unknown.should be_nil
    end

    it "routes shake effects correctly" do
      shake = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("screen_shake",
        amplitude: 10.0f32, frequency: 10.0f32, duration: 0.5f32)
      shake.should_not be_nil
      shake.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::SceneShakeEffect)
    end
  end
end

# GPU-dependent tests are in a separate describe block
# These require a raylib window to be initialized
{% if flag?(:with_graphics_tests) %}
describe "PointClickEngine::Graphics::Effects::SceneEffects (GPU tests)" do
  before_all do
    RL.init_window(100, 100, "SceneEffect Tests")
  end

  after_all do
    RL.close_window
  end

  it "creates fog effects" do
    fog = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("fog",
      type: "linear", color: "gray", density: 0.02f32)
    fog.should_not be_nil
    fog.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::FogShader)
  end

  it "creates rain effects" do
    rain = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("rain",
      intensity: "light", wind: 0.1f32)
    rain.should_not be_nil
    rain.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::RainShader)
  end

  it "creates darkness effects" do
    darkness = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("darkness",
      type: "vignette", intensity: 0.8f32)
    darkness.should_not be_nil
    darkness.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::DarknessShader)
  end

  it "creates underwater effects" do
    underwater = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("underwater",
      quality: "low", color: [0, 80, 120, 100])
    underwater.should_not be_nil
    underwater.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::UnderwaterShader)
  end

  it "creates transition effects" do
    fade = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("transition",
      type: "fade", duration: 1.0f32)
    fade.should_not be_nil
    fade.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::TransitionEffect)
  end
end
{% end %}
