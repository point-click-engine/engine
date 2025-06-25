require "../../spec_helper"

describe PointClickEngine::Graphics::Shaders::ShaderHelpers do
  it "defines all shader constants" do
    PointClickEngine::Graphics::Shaders::ShaderHelpers::PIXELATE_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::GRAYSCALE_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::SEPIA_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::VIGNETTE_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::CHROMATIC_ABERRATION_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::BLOOM_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::CRT_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::WAVE_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::OUTLINE_FRAGMENT.should_not be_empty
    PointClickEngine::Graphics::Shaders::ShaderHelpers::DEFAULT_VERTEX.should_not be_empty
  end

  it "shader code contains proper GLSL version" do
    PointClickEngine::Graphics::Shaders::ShaderHelpers::PIXELATE_FRAGMENT.includes?("#version 330").should be_true
    PointClickEngine::Graphics::Shaders::ShaderHelpers::DEFAULT_VERTEX.includes?("#version 330").should be_true
  end

  it "shader code contains required uniforms" do
    PointClickEngine::Graphics::Shaders::ShaderHelpers::PIXELATE_FRAGMENT.includes?("uniform float pixelSize").should be_true
    PointClickEngine::Graphics::Shaders::ShaderHelpers::GRAYSCALE_FRAGMENT.includes?("uniform float intensity").should be_true
    PointClickEngine::Graphics::Shaders::ShaderHelpers::VIGNETTE_FRAGMENT.includes?("uniform float radius").should be_true
    PointClickEngine::Graphics::Shaders::ShaderHelpers::WAVE_FRAGMENT.includes?("uniform float time").should be_true
  end
end
