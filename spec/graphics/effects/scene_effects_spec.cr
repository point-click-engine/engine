require "../../spec_helper"

# Tests for scene effects
describe PointClickEngine::Graphics::Effects::SceneEffects do
  describe "SceneEffectFactory" do
    it "creates fog effects" do
      # Linear fog
      fog = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("fog",
        type: "linear", color: "gray", density: 0.02f32)
      fog.should_not be_nil
      fog.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::FogShader)
      
      # Exponential fog
      exp_fog = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("fog",
        type: "exponential", density: 0.05f32, start: 100.0f32, end: 500.0f32)
      exp_fog.should_not be_nil
      
      # Volumetric fog
      vol_fog = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("fog",
        type: "volumetric", color: [128, 128, 150, 200])
      vol_fog.should_not be_nil
    end
    
    it "creates rain effects" do
      # Light rain
      light_rain = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("rain",
        intensity: "light", wind: 0.1f32)
      light_rain.should_not be_nil
      light_rain.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::RainShader)
      
      # Heavy rain with splashes
      storm = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("rain",
        intensity: "storm", wind: 0.5f32, splashes: true, color: "#C8C8FF64")
      storm.should_not be_nil
    end
    
    it "creates darkness effects" do
      # Vignette
      vignette = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("darkness",
        type: "vignette", intensity: 0.8f32, inner_radius: 0.5f32, outer_radius: 1.2f32)
      vignette.should_not be_nil
      vignette.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::DarknessShader)
      
      # Gradient darkness
      gradient = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("darkness",
        type: "gradient", intensity: 0.6f32, color: "black")
      gradient.should_not be_nil
      
      # Spotlight
      spotlight = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("darkness",
        type: "spotlight", intensity: 0.9f32)
      spotlight.should_not be_nil
    end
    
    it "creates underwater effects" do
      # Low quality underwater
      low_water = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("underwater",
        quality: "low", color: [0, 80, 120, 100])
      low_water.should_not be_nil
      low_water.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::UnderwaterShader)
      
      # High quality with custom waves
      high_water = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("underwater",
        quality: "high", wave_amplitude: 0.02f32, wave_frequency: 15.0f32, wave_speed: 3.0f32)
      high_water.should_not be_nil
    end
    
    it "creates transition effects" do
      # Fade transition
      fade = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("transition",
        type: "fade", duration: 1.0f32)
      fade.should_not be_nil
      fade.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::TransitionEffect)
      
      # Swirl transition
      swirl = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("transition",
        type: "swirl", duration: 1.5f32, reverse: true)
      swirl.should_not be_nil
      
      # Heart wipe
      heart = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("transition",
        type: "heart_wipe", duration: 2.0f32)
      heart.should_not be_nil
    end
    
    it "handles screen shake effect" do
      shake = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("screen_shake",
        amplitude: 10.0f32, frequency: 10.0f32, duration: 0.5f32)
      shake.should_not be_nil
      shake.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::SceneShakeEffect)
    end
    
    it "handles flash effect" do
      flash = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("flash",
        color: "white", duration: 0.2f32)
      flash.should_not be_nil
      flash.should be_a(PointClickEngine::Graphics::Effects::SceneEffects::SceneColorEffect)
    end
    
    it "returns nil for unknown effects" do
      unknown = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("unknown_effect")
      unknown.should be_nil
    end
  end
  
  describe "effect configuration" do
    it "allows updating darkness effect lights" do
      darkness = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("darkness",
        type: "multilight")
      
      darkness.should_not be_nil
      if darkness.is_a?(PointClickEngine::Graphics::Effects::SceneEffects::DarknessShader)
        # Add light sources
        darkness.add_light(RL::Vector2.new(x: 100, y: 100), 150.0f32, 1.0f32, RL::YELLOW)
        darkness.add_light(RL::Vector2.new(x: 500, y: 300), 200.0f32, 0.8f32, RL::WHITE)
        
        darkness.light_sources.size.should eq(2)
        
        # Clear lights
        darkness.clear_lights
        darkness.light_sources.size.should eq(0)
      end
    end
    
    it "configures rain parameters" do
      rain = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("rain",
        intensity: "medium")
      
      rain.should_not be_nil
      if rain.is_a?(PointClickEngine::Graphics::Effects::SceneEffects::RainShader)
        # Update parameters
        rain.wind_strength = 0.8f32
        rain.splash_enabled = false
        rain.depth_layers = 5
        
        rain.wind_strength.should eq(0.8f32)
        rain.splash_enabled.should be_false
        rain.depth_layers.should eq(5)
      end
    end
  end
  
  describe "color parsing" do
    it "parses colors correctly" do
      # Test with hex color
      fog1 = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("fog",
        color: "#808096C8")
      fog1.should_not be_nil
      
      # Test with named color
      fog2 = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("fog",
        color: "white")
      fog2.should_not be_nil
      
      # Test with array
      fog3 = PointClickEngine::Graphics::Effects::SceneEffects::SceneEffectFactory.create("fog",
        color: [200, 200, 255, 150])
      fog3.should_not be_nil
    end
  end
end