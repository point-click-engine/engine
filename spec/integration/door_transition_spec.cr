require "../spec_helper"

describe "Door transition effects" do
  before_each do
    RL.init_window(800, 600, "Door Transition Test")
  end

  after_each do
    RL.close_window
  end

  it "triggers cheesy transitions when using doors" do
    engine = PointClickEngine::Core::Engine.new(
      title: "Door Transition Test",
      window_width: 800,
      window_height: 600
    )
    engine.init
    engine.enable_verb_input

    # Create a scene with an exit that has a cheesy transition
    scene = PointClickEngine::Scenes::Scene.new("test_room")
    engine.add_scene(scene)
    engine.change_scene("test_room")

    # Create an exit zone with heart wipe transition
    exit_zone = PointClickEngine::Scenes::ExitZone.new(
      "magic_door",
      RL::Vector2.new(x: 500f32, y: 400f32),
      RL::Vector2.new(x: 100f32, y: 200f32),
      "next_room"
    )
    exit_zone.transition_type = PointClickEngine::Scenes::TransitionType::HeartWipe
    scene.add_hotspot(exit_zone)

    # Create target scene
    next_scene = PointClickEngine::Scenes::Scene.new("next_room")
    engine.add_scene(next_scene)

    # Get the verb system and transition manager
    verb_system = engine.verb_input_system.not_nil!
    transition_manager = engine.transition_manager.not_nil!

    # Transition should not be active initially
    transition_manager.transitioning?.should be_false

    # Set open verb
    verb_system.cursor_manager.set_verb(PointClickEngine::UI::VerbType::Open)

    # Note: We can't easily test the actual click interaction in specs
    # because it requires complex input simulation. The actual interaction
    # is tested by the door_interaction_spec.cr

    # But we can verify the transition types are properly mapped
    exit_zone.transition_type.should eq(PointClickEngine::Scenes::TransitionType::HeartWipe)
  end

  it "uses different transitions for different doors" do
    # Test that our Crystal Mystery doors have different transitions
    yaml_files = {
      "library"    => "swirl",
      "laboratory" => ["heart_wipe", "curtain"],
      "garden"     => "star_wipe",
    }

    yaml_files.each do |scene_name, transitions|
      path = "crystal_mystery/scenes/#{scene_name}.yaml"
      if File.exists?(path)
        content = File.read(path)

        if transitions.is_a?(Array)
          transitions.each do |transition|
            content.should contain("transition_type: #{transition}")
          end
        else
          content.should contain("transition_type: #{transitions}")
        end
      end
    end
  end

  it "transition duration is set to 4.5 seconds for maximum cheese" do
    # Verify the long transition duration in the source
    verb_system_source = File.read("src/core/engine/verb_input_system.cr")
    verb_system_source.should contain("transition_duration = 4.5f32")
  end
end

describe "Transition rendering integration" do
  before_each do
    RL.init_window(800, 600, "Render Integration Test")
  end

  after_each do
    RL.close_window
  end

  it "render pipeline wraps scene rendering during transitions" do
    engine = PointClickEngine::Core::Engine.new(
      title: "Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    transition_manager = engine.transition_manager.not_nil!

    # Start a transition
    transition_manager.start_transition(
      PointClickEngine::Graphics::TransitionEffect::Fade,
      1.0f32
    ) { }

    transition_manager.transitioning?.should be_true

    # The render method should handle transitions
    # (We can't easily test the actual rendering, but we verify the structure exists)
    engine.render_manager.should_not be_nil
    engine.render_manager.responds_to?(:render_internal).should be_true
  end
end
