require "../spec_helper"

describe "New Transition System" do
  it "creates transition effects" do
    # Test that we can create a transition effect
    transition = PointClickEngine::Graphics::TransitionSceneEffect.new(
      PointClickEngine::Graphics::TransitionEffect::Fade,
      1.0f32
    )
    
    transition.should_not be_nil
    transition.duration.should eq(1.0f32)
    transition.finished?.should be_false
  end

  it "updates transition progress" do
    transition = PointClickEngine::Graphics::TransitionSceneEffect.new(
      PointClickEngine::Graphics::TransitionEffect::Fade,
      1.0f32
    )
    
    # Update halfway
    transition.update(0.5f32)
    transition.progress.should be_close(0.5f32, 0.01)
    transition.finished?.should be_false
    
    # Complete transition
    transition.update(0.6f32)
    transition.progress.should be >= 1.0f32
    transition.finished?.should be_true
  end

  it "triggers midpoint callback" do
    callback_triggered = false
    
    transition = PointClickEngine::Graphics::TransitionSceneEffect.new(
      PointClickEngine::Graphics::TransitionEffect::Fade,
      1.0f32
    )
    
    transition.on_midpoint do
      callback_triggered = true
    end
    
    # Update to before midpoint
    transition.update(0.4f32)
    callback_triggered.should be_false
    
    # Update past midpoint
    transition.update(0.2f32)
    callback_triggered.should be_true
  end

  it "supports all transition types" do
    # Test that all transition types can be created
    {% for transition_type in %w[Fade Dissolve SlideLeft SlideRight SlideUp SlideDown] %}
      transition = PointClickEngine::Graphics::TransitionSceneEffect.new(
        PointClickEngine::Graphics::TransitionEffect::{{transition_type.id}},
        1.0f32
      )
      transition.should_not be_nil
    {% end %}
  end
end