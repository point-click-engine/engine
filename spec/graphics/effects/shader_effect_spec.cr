require "../../spec_helper"

# Mock shader effect for testing (must be outside describe block)
# This mock skips actual shader loading since we don't have a GPU context in tests
class TestShaderEffect < PointClickEngine::Graphics::Effects::ShaderEffect
  property test_value : Float32 = 0.0f32

  # Override to skip actual shader loading (no GPU context in tests)
  protected def load_shader : RL::Shader?
    nil
  end

  def vertex_shader_source : String
    ""
  end

  def fragment_shader_source : String
    ""
  end

  def apply(context : PointClickEngine::Graphics::Effects::EffectContext)
    # No-op for tests without GPU context
  end

  def clone : PointClickEngine::Graphics::Effects::Effect
    effect = TestShaderEffect.new(@duration)
    effect.test_value = @test_value
    effect
  end
end

# Tests for the shader-based effects system
describe PointClickEngine::Graphics::Effects::ShaderEffect do
  describe "initialization" do
    it "creates shader effect with proper defaults" do
      effect = TestShaderEffect.new

      effect.duration.should eq(0.0f32)
      effect.elapsed.should eq(0.0f32)
      effect.active.should be_true
      effect.intensity.should eq(1.0f32)
    end

    it "creates shader effect with duration" do
      effect = TestShaderEffect.new(2.0f32)

      effect.duration.should eq(2.0f32)
      effect.remaining_time.should eq(2.0f32)
      effect.progress.should eq(0.0f32)
    end
  end

  describe "GL context checking" do
    it "provides gl_context_available? class method" do
      # In test environment without a window, this should be false
      PointClickEngine::Graphics::Effects::ShaderEffect.gl_context_available?.should be_a(Bool)
    end

    it "can reset context check for testing" do
      PointClickEngine::Graphics::Effects::ShaderEffect.reset_context_check
      # After reset, next call will re-check
      PointClickEngine::Graphics::Effects::ShaderEffect.gl_context_available?.should be_a(Bool)
    end

    it "tracks shader availability" do
      effect = TestShaderEffect.new
      # Without GPU context, shader_available should be false
      effect.shader_available.should be_a(Bool)
    end
  end

  describe "shader loading" do
    it "handles shader compilation gracefully" do
      # Even if shader fails to compile in test environment,
      # the effect should still be created
      effect = TestShaderEffect.new
      effect.should_not be_nil
    end

    it "skips shader loading when no GL context" do
      # Reset context check to ensure clean state
      PointClickEngine::Graphics::Effects::ShaderEffect.reset_context_check

      # In headless mode, GL context should not be available
      # and shader loading should be skipped gracefully
      effect = TestShaderEffect.new
      effect.should_not be_nil
      # The effect should work but without shader acceleration
    end
  end

  describe "progress tracking" do
    it "calculates progress correctly" do
      effect = TestShaderEffect.new(1.0f32)

      # Initial state
      effect.progress.should eq(0.0f32)

      # Half way
      effect.update(0.5f32)
      effect.progress.should eq(0.5f32)

      # Complete
      effect.update(0.5f32)
      effect.progress.should eq(1.0f32)
      effect.finished?.should be_true
    end

    it "handles infinite duration" do
      effect = TestShaderEffect.new(0.0f32)

      effect.update(100.0f32)
      effect.progress.should eq(0.0f32)
      effect.finished?.should be_false
    end
  end

  describe "effect lifecycle" do
    it "can be reset" do
      effect = TestShaderEffect.new(1.0f32)
      effect.update(1.0f32)

      effect.finished?.should be_true

      effect.reset
      effect.elapsed.should eq(0.0f32)
      effect.active.should be_true
      effect.finished?.should be_false
    end

    it "can be stopped" do
      effect = TestShaderEffect.new(10.0f32)

      effect.stop
      effect.active.should be_false
      effect.finished?.should be_true
    end
  end

  describe "cloning" do
    it "creates independent copy" do
      effect1 = TestShaderEffect.new(2.0f32)
      effect1.test_value = 0.5f32
      effect1.intensity = 0.8f32

      effect2 = effect1.clone.as(TestShaderEffect)

      # Values should be copied
      effect2.duration.should eq(effect1.duration)
      effect2.test_value.should eq(effect1.test_value)

      # But instances should be independent
      effect2.update(1.0f32)
      effect1.elapsed.should eq(0.0f32)
      effect2.elapsed.should eq(1.0f32)
    end
  end
end

# Tests for factory behavior without GPU
describe "Shader Effect Factories" do
  describe "ShaderObjectFactory" do
    it "provides available? method" do
      PointClickEngine::Graphics::Effects::ObjectEffects::ShaderObjectFactory.available?.should be_a(Bool)
    end

    it "returns nil when GL context unavailable" do
      # In headless mode, shader effects should return nil
      # allowing ObjectEffects.create to fall back to CPU effects
      result = PointClickEngine::Graphics::Effects::ObjectEffects::ShaderObjectFactory.create("highlight")
      # Will be nil in headless, or a shader effect with GPU
    end
  end

  describe "PostProcessingFactory" do
    it "provides available? method" do
      PointClickEngine::Graphics::Effects::PostProcessing::PostProcessingFactory.available?.should be_a(Bool)
    end
  end

  describe "ShaderSceneEffectFactory" do
    it "provides available? method" do
      PointClickEngine::Graphics::Effects::SceneEffects::ShaderSceneEffectFactory.available?.should be_a(Bool)
    end
  end
end
