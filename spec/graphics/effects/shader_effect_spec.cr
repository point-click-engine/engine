require "../../spec_helper"

# Tests for the shader-based effects system
describe PointClickEngine::Graphics::Effects::ShaderEffect do
  # Mock shader effect for testing
  class TestShaderEffect < PointClickEngine::Graphics::Effects::ShaderEffect
    property test_value : Float32 = 0.0f32
    
    def vertex_shader_source : String
      <<-SHADER
      #version 330 core
      in vec3 vertexPosition;
      in vec2 vertexTexCoord;
      in vec4 vertexColor;
      out vec2 fragTexCoord;
      out vec4 fragColor;
      uniform mat4 mvp;
      void main() {
          fragTexCoord = vertexTexCoord;
          fragColor = vertexColor;
          gl_Position = mvp * vec4(vertexPosition, 1.0);
      }
      SHADER
    end
    
    def fragment_shader_source : String
      <<-SHADER
      #version 330 core
      in vec2 fragTexCoord;
      in vec4 fragColor;
      out vec4 finalColor;
      uniform sampler2D texture0;
      uniform float time;
      uniform float progress;
      uniform vec2 resolution;
      uniform float testValue;
      void main() {
          vec4 color = texture(texture0, fragTexCoord) * fragColor;
          color.rgb *= testValue;
          finalColor = color;
      }
      SHADER
    end
    
    def apply(context : PointClickEngine::Graphics::Effects::EffectContext)
      return unless shader = @shader
      
      context.active_shader = shader
      update_common_uniforms(shader)
      set_shader_value("testValue", @test_value)
    end
    
    def clone : PointClickEngine::Graphics::Effects::Effect
      effect = TestShaderEffect.new(@duration)
      effect.test_value = @test_value
      effect
    end
  end
  
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
  
  describe "shader loading" do
    it "handles shader compilation gracefully" do
      # Even if shader fails to compile in test environment,
      # the effect should still be created
      effect = TestShaderEffect.new
      effect.should_not be_nil
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