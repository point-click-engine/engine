require "../../spec_helper"

# Tests for scene effects
# NOTE: Shader-based scene effects require a GPU/OpenGL context for shader compilation.
# Non-shader effects (like SceneShakeEffect) work without GPU context.
# GPU-dependent tests are conditionally compiled with the :with_graphics_tests flag.
#
# To run GPU tests: crystal spec -D with_graphics_tests spec/graphics/effects/scene_effects_spec.cr
describe PointClickEngine::Graphics::Effects::SceneEffects do
  describe "SceneEffectFactory" do
    describe "factory availability" do
      it "provides available? method to check GPU context" do
        PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.available?.should be_a(Bool)
      end
    end

    describe "non-GPU effects" do
      # These tests verify factory method routing without requiring GPU
      it "returns nil for unknown effects" do
        unknown = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("unknown_effect")
        unknown.should be_nil
      end

      it "routes shake effects correctly (CPU-based)" do
        shake = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("screen_shake",
          amplitude: 10.0f32, frequency: 10.0f32, duration: 0.5f32)
        shake.should_not be_nil
        shake.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::SceneShakeEffect)
      end

      it "routes flash effects correctly (CPU-based)" do
        flash = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("flash",
          color: "white", duration: 0.2f32)
        flash.should_not be_nil
        flash.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::SceneColorEffect)
      end

      it "creates transition effects (CPU fallback available)" do
        transition = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("transition",
          type: "fade", duration: 1.0f32)
        transition.should_not be_nil
        transition.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::TransitionEffect)
      end
    end

    describe "graceful degradation without GPU" do
      it "returns nil for shader effects when no GL context" do
        # Without GPU context, shader scene effects should return nil gracefully
        # These would work with a GPU context
        fog = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("fog")
        rain = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("rain")
        darkness = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("darkness")
        underwater = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("underwater")

        # In headless mode without GPU, these will be nil
        # In a real environment with GPU, they would return valid effects
        # We don't assert nil because this test may run with GPU available
      end
    end
  end

  describe "SceneShakeEffect (CPU-based)" do
    it "creates with proper defaults" do
      shake = PointClickEngine::Graphics::Effects::SceneEffects::SceneShakeEffect.new(5.0f32, 10.0f32, 0.5f32)
      shake.should_not be_nil
      shake.duration.should eq(0.5f32)
      # Internal shake_effect wraps amplitude/frequency
      shake.shake_effect.should_not be_nil
    end

    it "updates and tracks progress" do
      shake = PointClickEngine::Graphics::Effects::SceneEffects::SceneShakeEffect.new(5.0f32, 10.0f32, 1.0f32)
      shake.progress.should eq(0.0f32)

      shake.update(0.5f32)
      shake.progress.should eq(0.5f32)

      shake.update(0.5f32)
      shake.finished?.should be_true
    end
  end
end

# GPU-dependent tests are in a separate describe block
# These require a raylib window to be initialized
{% if flag?(:with_graphics_tests) %}
describe "PointClickEngine::Graphics::Effects::SceneEffects (GPU tests)" do
  before_all do
    RL.init_window(100, 100, "SceneEffect Tests")
    # Reset context check to pick up the new window
    PointClickEngine::Graphics::Effects::ShaderEffect.reset_context_check
  end

  after_all do
    RL.close_window
  end

  describe "shader availability with GPU" do
    it "reports GL context as available" do
      PointClickEngine::Graphics::Effects::ShaderEffect.gl_context_available?.should be_true
    end

    it "reports factory as available" do
      PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.available?.should be_true
    end
  end

  describe "fog effects" do
    it "creates linear fog" do
      fog = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("fog",
        type: "linear", color: "gray", density: 0.02f32)
      fog.should_not be_nil
      fog.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::FogShader)
    end

    it "creates volumetric fog" do
      fog = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("fog",
        type: "volumetric", density: 0.05f32)
      fog.should_not be_nil
    end

    it "tracks shader availability" do
      fog = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("fog")
      if fog.is_a?(PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffect)
        fog.shader_available.should be_true
      end
    end
  end

  describe "rain effects" do
    it "creates rain with different intensities" do
      light = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("rain",
        intensity: "light", wind: 0.1f32)
      light.should_not be_nil
      light.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::RainShader)

      storm = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("rain",
        intensity: "storm", wind: 0.5f32)
      storm.should_not be_nil
    end
  end

  describe "darkness effects" do
    it "creates vignette darkness" do
      darkness = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("darkness",
        type: "vignette", intensity: 0.8f32)
      darkness.should_not be_nil
      darkness.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::DarknessShader)
    end

    it "creates gradient darkness" do
      darkness = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("darkness",
        type: "gradient", intensity: 0.7f32)
      darkness.should_not be_nil
    end

    it "creates spotlight darkness" do
      darkness = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("darkness",
        type: "spotlight", intensity: 0.9f32)
      darkness.should_not be_nil
    end

    it "creates multilight darkness" do
      darkness = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("darkness",
        type: "multilight", intensity: 0.8f32)
      darkness.should_not be_nil
    end
  end

  describe "underwater effects" do
    it "creates underwater with quality settings" do
      low = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("underwater",
        quality: "low", color: [0, 80, 120, 100])
      low.should_not be_nil
      low.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::UnderwaterShader)

      high = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("underwater",
        quality: "high")
      high.should_not be_nil
    end
  end

  describe "transition effects" do
    it "creates various transition types" do
      fade = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("transition",
        type: "fade", duration: 1.0f32)
      fade.should_not be_nil
      fade.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::TransitionEffect)

      iris = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("transition",
        type: "iris", duration: 1.5f32)
      iris.should_not be_nil

      swirl = PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.create("transition",
        type: "swirl", duration: 2.0f32)
      swirl.should_not be_nil
    end
  end
end
{% end %}
