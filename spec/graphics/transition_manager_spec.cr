require "../spec_helper"

describe PointClickEngine::Graphics::TransitionManager do
  describe "initialization" do
    it "creates a transition manager with specified dimensions" do
      manager = PointClickEngine::Graphics::TransitionManager.new(800, 600)
      manager.should_not be_nil
      manager.active.should be_false
      manager.progress.should eq(0.0f32)
      manager.cleanup
    end
  end

  describe "starting transitions" do
    it "starts a fade transition" do
      manager = PointClickEngine::Graphics::TransitionManager.new(800, 600)

      completed = false
      manager.start_transition(
        PointClickEngine::Graphics::TransitionEffect::Fade,
        1.0f32
      ) do
        completed = true
      end

      manager.active.should be_true
      manager.current_effect_type.should eq(PointClickEngine::Graphics::TransitionEffect::Fade)
      manager.duration.should eq(1.0f32)

      manager.cleanup
    end

    it "starts a cheesy heart wipe transition" do
      manager = PointClickEngine::Graphics::TransitionManager.new(800, 600)

      manager.start_transition(
        PointClickEngine::Graphics::TransitionEffect::HeartWipe,
        4.5f32
      ) { }

      manager.active.should be_true
      manager.current_effect_type.should eq(PointClickEngine::Graphics::TransitionEffect::HeartWipe)
      manager.duration.should eq(4.5f32)

      manager.cleanup
    end
  end

  describe "transition progress" do
    it "updates transition progress over time" do
      manager = PointClickEngine::Graphics::TransitionManager.new(800, 600)

      manager.start_transition(
        PointClickEngine::Graphics::TransitionEffect::Fade,
        2.0f32
      ) { }

      # Simulate 1 second passing
      manager.update(1.0f32)
      manager.progress.should eq(0.5f32)
      manager.active.should be_true

      # Simulate another second
      manager.update(1.0f32)
      manager.progress.should eq(1.0f32)
      manager.active.should be_false

      manager.cleanup
    end

    it "calls completion callback when transition ends" do
      manager = PointClickEngine::Graphics::TransitionManager.new(800, 600)

      completed = false
      manager.start_transition(
        PointClickEngine::Graphics::TransitionEffect::Fade,
        1.0f32
      ) do
        completed = true
      end

      completed.should be_false

      # Complete the transition
      manager.update(1.5f32)

      completed.should be_true
      manager.active.should be_false

      manager.cleanup
    end
  end

  describe "transition effects" do
    it "creates different effect instances for each transition type" do
      manager = PointClickEngine::Graphics::TransitionManager.new(800, 600)

      # Test each effect separately to avoid shader overload
      manager.start_transition(PointClickEngine::Graphics::TransitionEffect::Fade, 0.1f32) { }
      manager.current_effect_type.should eq(PointClickEngine::Graphics::TransitionEffect::Fade)
      manager.stop_transition

      manager.start_transition(PointClickEngine::Graphics::TransitionEffect::HeartWipe, 0.1f32) { }
      manager.current_effect_type.should eq(PointClickEngine::Graphics::TransitionEffect::HeartWipe)
      manager.stop_transition

      manager.cleanup
    end
  end

  describe "stopping transitions" do
    it "can stop an active transition" do
      manager = PointClickEngine::Graphics::TransitionManager.new(800, 600)

      manager.start_transition(
        PointClickEngine::Graphics::TransitionEffect::Fade,
        5.0f32
      ) { }

      manager.active.should be_true

      manager.stop_transition

      manager.active.should be_false
      manager.progress.should eq(0.0f32)

      manager.cleanup
    end
  end
end

describe "Engine transition integration" do
  it "transition manager is accessible through engine systems" do
    # Use existing window
    engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
    engine.init

    # Transition manager should be initialized
    engine.system_manager.should_not be_nil
    engine.system_manager.transition_manager.should_not be_nil

    # Access through convenience method
    engine.system_manager.transition_manager.should_not be_nil
  end
end
