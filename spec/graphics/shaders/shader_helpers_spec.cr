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
    PointClickEngine::Graphics::Shaders::ShaderHelpers::PIXELATE_FRAGMENT.should contain("#version 330")
    PointClickEngine::Graphics::Shaders::ShaderHelpers::DEFAULT_VERTEX.should contain("#version 330")
  end

  it "shader code contains required uniforms" do
    PointClickEngine::Graphics::Shaders::ShaderHelpers::PIXELATE_FRAGMENT.should contain("uniform float pixelSize")
    PointClickEngine::Graphics::Shaders::ShaderHelpers::GRAYSCALE_FRAGMENT.should contain("uniform float intensity")
    PointClickEngine::Graphics::Shaders::ShaderHelpers::VIGNETTE_FRAGMENT.should contain("uniform float radius")
    PointClickEngine::Graphics::Shaders::ShaderHelpers::WAVE_FRAGMENT.should contain("uniform float time")
  end
end
