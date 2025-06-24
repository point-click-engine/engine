require "../spec_helper"

describe "Transition Effects" do
  before_each do
    RL.init_window(800, 600, "Transition Test")
  end

  after_each do
    RL.close_window
  end

  it "creates transition manager successfully" do
    manager = PointClickEngine::Graphics::Transitions::TransitionManager.new(800, 600)
    manager.should_not be_nil
    manager.cleanup
  end

  it "supports all basic transition effects" do
    manager = PointClickEngine::Graphics::Transitions::TransitionManager.new(800, 600)

    # Test all basic effects can be started
    effects_to_test = [
      PointClickEngine::Graphics::Transitions::TransitionEffect::Fade,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Dissolve,
      PointClickEngine::Graphics::Transitions::TransitionEffect::CrossFade,
      PointClickEngine::Graphics::Transitions::TransitionEffect::SlideLeft,
      PointClickEngine::Graphics::Transitions::TransitionEffect::SlideRight,
      PointClickEngine::Graphics::Transitions::TransitionEffect::SlideUp,
      PointClickEngine::Graphics::Transitions::TransitionEffect::SlideDown,
    ]

    effects_to_test.each do |effect|
      manager.start_transition(effect, 0.1f32) { }
      manager.active.should be_true
      manager.stop_transition
      manager.active.should be_false
    end

    manager.cleanup
  end

  it "supports all geometric transition effects" do
    manager = PointClickEngine::Graphics::Transitions::TransitionManager.new(800, 600)

    # Test all geometric effects can be started
    effects_to_test = [
      PointClickEngine::Graphics::Transitions::TransitionEffect::Iris,
      PointClickEngine::Graphics::Transitions::TransitionEffect::StarWipe,
      PointClickEngine::Graphics::Transitions::TransitionEffect::HeartWipe,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Checkerboard,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Pixelate,
    ]

    effects_to_test.each do |effect|
      manager.start_transition(effect, 0.1f32) { }
      manager.active.should be_true
      manager.stop_transition
      manager.active.should be_false
    end

    manager.cleanup
  end

  it "supports all artistic transition effects" do
    manager = PointClickEngine::Graphics::Transitions::TransitionManager.new(800, 600)

    # Test all artistic effects can be started
    effects_to_test = [
      PointClickEngine::Graphics::Transitions::TransitionEffect::Swirl,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Curtain,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Ripple,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Glitch,
    ]

    effects_to_test.each do |effect|
      manager.start_transition(effect, 0.1f32) { }
      manager.active.should be_true
      manager.stop_transition
      manager.active.should be_false
    end

    manager.cleanup
  end

  it "supports all cinematic transition effects" do
    manager = PointClickEngine::Graphics::Transitions::TransitionManager.new(800, 600)

    # Test all cinematic effects can be started
    effects_to_test = [
      PointClickEngine::Graphics::Transitions::TransitionEffect::Warp,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Wave,
      PointClickEngine::Graphics::Transitions::TransitionEffect::FilmBurn,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Static,
      PointClickEngine::Graphics::Transitions::TransitionEffect::MatrixRain,
    ]

    effects_to_test.each do |effect|
      manager.start_transition(effect, 0.1f32) { }
      manager.active.should be_true
      manager.stop_transition
      manager.active.should be_false
    end

    manager.cleanup
  end

  it "supports all advanced transition effects" do
    manager = PointClickEngine::Graphics::Transitions::TransitionManager.new(800, 600)

    # Test all advanced effects can be started
    effects_to_test = [
      PointClickEngine::Graphics::Transitions::TransitionEffect::ZoomBlur,
      PointClickEngine::Graphics::Transitions::TransitionEffect::ClockWipe,
      PointClickEngine::Graphics::Transitions::TransitionEffect::BarnDoor,
      PointClickEngine::Graphics::Transitions::TransitionEffect::PageTurn,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Shatter,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Vortex,
      PointClickEngine::Graphics::Transitions::TransitionEffect::Fire,
    ]

    effects_to_test.each do |effect|
      manager.start_transition(effect, 0.1f32) { }
      manager.active.should be_true
      manager.stop_transition
      manager.active.should be_false
    end

    manager.cleanup
  end

  it "updates transition progress correctly" do
    manager = PointClickEngine::Graphics::Transitions::TransitionManager.new(800, 600)

    manager.start_transition(PointClickEngine::Graphics::Transitions::TransitionEffect::Fade, 1.0f32) { }
    manager.active.should be_true
    manager.current_progress.should eq(0.0f32)

    # Update halfway
    manager.update(0.5f32)
    manager.current_progress.should eq(0.5f32)
    manager.active.should be_true

    # Update to completion
    manager.update(0.5f32)
    manager.current_progress.should eq(1.0f32)
    manager.active.should be_false

    manager.cleanup
  end
end
