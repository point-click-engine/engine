require "./spec_helper"

describe PointClickEngine::Graphics do
  describe PointClickEngine::Graphics::DisplayManager do
    # Note: DisplayManager tests that require Raylib initialization are skipped in unit tests
    # These would be tested in integration tests with proper Raylib setup
    
    it "has reference resolution constants" do
      PointClickEngine::Graphics::DisplayManager::REFERENCE_WIDTH.should eq(1024)
      PointClickEngine::Graphics::DisplayManager::REFERENCE_HEIGHT.should eq(768)
    end
  end

  describe PointClickEngine::Graphics::AnimatedSprite do
    it "initializes with frame data" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(
        vec2(100, 100), 
        frame_width: 32, 
        frame_height: 32, 
        frame_count: 8
      )
      
      sprite.position.x.should eq(100)
      sprite.position.y.should eq(100)
      sprite.frame_width.should eq(32)
      sprite.frame_height.should eq(32)
      sprite.frame_count.should eq(8)
    end

    it "starts playing at frame 0" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(
        vec2(0, 0), 
        frame_width: 32, 
        frame_height: 32, 
        frame_count: 4
      )
      
      sprite.current_frame.should eq(0)
      sprite.playing.should be_true
      sprite.loop.should be_true
    end

    it "can be controlled" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(
        vec2(0, 0), 
        frame_width: 32, 
        frame_height: 32, 
        frame_count: 4
      )
      
      sprite.stop
      sprite.playing.should be_false
      
      sprite.play
      sprite.playing.should be_true
    end

    it "has configurable animation speed" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(
        vec2(0, 0), 
        frame_width: 32, 
        frame_height: 32, 
        frame_count: 4
      )
      
      sprite.frame_speed = 0.2_f32
      sprite.frame_speed.should eq(0.2_f32)
    end

    it "has configurable scale" do
      sprite = PointClickEngine::Graphics::AnimatedSprite.new(
        vec2(0, 0), 
        frame_width: 32, 
        frame_height: 32, 
        frame_count: 4
      )
      
      sprite.scale = 2.0_f32
      sprite.scale.should eq(2.0_f32)
    end
  end

  describe PointClickEngine::Graphics::Particle do
    it "initializes with all properties" do
      particle = PointClickEngine::Graphics::Particle.new(
        position: vec2(100, 100),
        velocity: vec2(50, -25),
        color: RL::RED,
        size: 5.0,
        lifetime: 2.0
      )
      
      particle.position.x.should eq(100)
      particle.position.y.should eq(100)
      particle.velocity.x.should eq(50)
      particle.velocity.y.should eq(-25)
      particle.size.should eq(5.0)
      particle.lifetime.should eq(2.0)
      particle.age.should eq(0.0)
    end

    it "starts alive" do
      particle = PointClickEngine::Graphics::Particle.new(
        position: vec2(0, 0),
        velocity: vec2(0, 0),
        color: RL::WHITE,
        size: 1.0,
        lifetime: 1.0
      )
      
      particle.alive?.should be_true
    end

    it "updates position and age" do
      particle = PointClickEngine::Graphics::Particle.new(
        position: vec2(100, 100),
        velocity: vec2(50, -25),
        color: RL::WHITE,
        size: 1.0,
        lifetime: 2.0
      )
      
      particle.update(0.1_f32)
      
      particle.position.x.should eq(105.0_f32)  # 100 + 50 * 0.1
      particle.position.y.should eq(97.5_f32)   # 100 + (-25) * 0.1
      particle.age.should eq(0.1_f32)
    end

    it "dies when lifetime exceeded" do
      particle = PointClickEngine::Graphics::Particle.new(
        position: vec2(0, 0),
        velocity: vec2(0, 0),
        color: RL::WHITE,
        size: 1.0,
        lifetime: 1.0
      )
      
      particle.update(1.5_f32)  # Age now 1.5, lifetime is 1.0
      particle.alive?.should be_false
    end
  end

  describe PointClickEngine::Graphics::ParticleSystem do
    it "initializes at position" do
      system = PointClickEngine::Graphics::ParticleSystem.new(vec2(200, 200))
      system.position.x.should eq(200)
      system.position.y.should eq(200)
    end

    it "starts with default properties" do
      system = PointClickEngine::Graphics::ParticleSystem.new(vec2(0, 0))
      
      system.particles.should be_empty
      system.emitting.should be_true
      system.emit_rate.should eq(10.0)
      system.particle_lifetime.should eq(1.0)
      system.particle_size.should eq(3.0)
      system.particle_speed.should eq(100.0)
      system.particle_color.should eq(RL::WHITE)
    end

    it "has configurable properties" do
      system = PointClickEngine::Graphics::ParticleSystem.new(vec2(0, 0))
      
      system.emit_rate = 20.0
      system.particle_lifetime = 2.0
      system.particle_size = 5.0
      system.particle_speed = 150.0
      system.particle_color = RL::BLUE
      
      system.emit_rate.should eq(20.0)
      system.particle_lifetime.should eq(2.0)
      system.particle_size.should eq(5.0)
      system.particle_speed.should eq(150.0)
      system.particle_color.should eq(RL::BLUE)
    end

    it "can be turned on and off" do
      system = PointClickEngine::Graphics::ParticleSystem.new(vec2(0, 0))
      
      system.emitting = false
      system.emitting.should be_false
      
      system.emitting = true
      system.emitting.should be_true
    end
  end
end