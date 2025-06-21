require "../../spec_helper"

describe PointClickEngine::Graphics::Shaders::ShaderSystem do
  it "initializes with empty shader collection" do
    system = PointClickEngine::Graphics::Shaders::ShaderSystem.new
    system.shaders.should be_empty
    system.active_shader.should be_nil
  end

  it "stores shaders by name" do
    system = PointClickEngine::Graphics::Shaders::ShaderSystem.new
    # We can't actually load shaders in tests without OpenGL context
    # So we'll test the structure
    system.shaders[:test] = Raylib::Shader.new
    system.shaders.has_key?(:test).should be_true
  end

  it "raises error when setting non-existent shader as active" do
    system = PointClickEngine::Graphics::Shaders::ShaderSystem.new
    expect_raises(Exception, "Shader nonexistent not found") do
      system.set_active(:nonexistent)
    end
  end

  it "returns nil for non-existent shader" do
    system = PointClickEngine::Graphics::Shaders::ShaderSystem.new
    system.get_shader(:nonexistent).should be_nil
  end
end
