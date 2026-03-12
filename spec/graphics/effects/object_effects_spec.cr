require "../../spec_helper"

# Tests for object effects factory and shader implementations
describe PointClickEngine::Graphics::Effects::ObjectEffects do
  describe ".create" do
    pending "creates color shift effects" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      # Tint effect
      effect = PointClickEngine::Graphics::Effects::ObjectEffects.create("tint",
        color: "red", duration: 1.0f32)
      effect.should_not be_nil
      effect.should be_a(PointClickEngine::Graphics::Effects::Effect)

      # Rainbow effect
      rainbow = PointClickEngine::Graphics::Effects::ObjectEffects.create("rainbow",
        speed: 2.0f32)
      rainbow.should_not be_nil

      # Flash effect
      flash = PointClickEngine::Graphics::Effects::ObjectEffects.create("flash",
        color: [255, 255, 255], duration: 0.5f32)
      flash.should_not be_nil

      # Grayscale effect
      gray = PointClickEngine::Graphics::Effects::ObjectEffects.create("color",
        mode: "grayscale", intensity: 0.8f32)
      gray.should_not be_nil
    end
    
    it "creates dissolve effects" do
      # Dissolve out
      dissolve_out = PointClickEngine::Graphics::Effects::ObjectEffects.create("dissolve",
        mode: "out", duration: 2.0f32, edge_color: "orange")
      dissolve_out.should_not be_nil
      
      # Dissolve in
      dissolve_in = PointClickEngine::Graphics::Effects::ObjectEffects.create("dissolve",
        mode: "in", duration: 1.5f32)
      dissolve_in.should_not be_nil
    end
    
    it "creates float effects" do
      # Simple float
      float = PointClickEngine::Graphics::Effects::ObjectEffects.create("float",
        amplitude: 20.0f32, speed: 1.0f32)
      float.should_not be_nil
      
      # Float with sway
      sway = PointClickEngine::Graphics::Effects::ObjectEffects.create("float",
        amplitude: 15.0f32, sway: true, sway_amplitude: 10.0f32)
      sway.should_not be_nil
      
      # Hover effect
      hover = PointClickEngine::Graphics::Effects::ObjectEffects.create("hover",
        amplitude: 5.0f32, speed: 2.0f32)
      hover.should_not be_nil
    end
    
    it "creates highlight effects" do
      # Glow
      glow = PointClickEngine::Graphics::Effects::ObjectEffects.create("highlight",
        type: "glow", color: "yellow", intensity: 2.0f32)
      glow.should_not be_nil
      
      # Outline
      outline = PointClickEngine::Graphics::Effects::ObjectEffects.create("glow",
        type: "outline", color: "#FF0000", thickness: 3.0f32)
      outline.should_not be_nil
    end
    
    it "creates pulse effects" do
      # Breathe
      breathe = PointClickEngine::Graphics::Effects::ObjectEffects.create("pulse",
        scale_amount: 0.2f32, speed: 1.0f32)
      breathe.should_not be_nil
      
      # Heartbeat
      heartbeat = PointClickEngine::Graphics::Effects::ObjectEffects.create("pulse",
        mode: "heartbeat", scale_amount: 0.15f32)
      heartbeat.should_not be_nil
    end
    
    it "creates shake effects" do
      # Basic shake
      shake = PointClickEngine::Graphics::Effects::ObjectEffects.create("shake",
        amplitude: 10.0f32, frequency: 15.0f32, duration: 0.5f32)
      shake.should_not be_nil
      
      # Directional shake
      h_shake = PointClickEngine::Graphics::Effects::ObjectEffects.create("shake",
        amplitude: 5.0f32, direction: "horizontal", chromatic: 0.005f32)
      h_shake.should_not be_nil
    end
    
    it "handles invalid effect names" do
      effect = PointClickEngine::Graphics::Effects::ObjectEffects.create("nonexistent")
      effect.should be_nil
    end
    
    it "handles missing parameters with defaults" do
      # Should create with default parameters
      effect = PointClickEngine::Graphics::Effects::ObjectEffects.create("tint")
      effect.should_not be_nil
    end
  end
  
  describe ".parse_color" do
    it "parses color from various formats" do
      # Named colors
      red = PointClickEngine::Graphics::Effects::ObjectEffects.parse_color("red")
      red.should eq(RL::RED)
      
      # Hex colors
      hex_color = PointClickEngine::Graphics::Effects::ObjectEffects.parse_color("#FF00FF")
      hex_color.should_not be_nil
      hex_color.try do |c|
        c.r.should eq(255)
        c.g.should eq(0)
        c.b.should eq(255)
        c.a.should eq(255)
      end
      
      # Array format
      array_color = PointClickEngine::Graphics::Effects::ObjectEffects.parse_color([128, 64, 32])
      array_color.should_not be_nil
      array_color.try do |c|
        c.r.should eq(128)
        c.g.should eq(64)
        c.b.should eq(32)
        c.a.should eq(255)
      end
      
      # Array with alpha
      rgba_color = PointClickEngine::Graphics::Effects::ObjectEffects.parse_color([255, 0, 0, 128])
      rgba_color.should_not be_nil
      rgba_color.try do |c|
        c.a.should eq(128)
      end
      
      # Invalid input
      invalid = PointClickEngine::Graphics::Effects::ObjectEffects.parse_color("notacolor")
      invalid.should be_nil
    end
  end
end