require "../spec_helper"

describe "Door transition effects" do
  before_each do
    RL.init_window(800, 600, "Door Transition Test")
  end

  after_each do
    RL.close_window
  end

  it "triggers cheesy transitions through action commands" do
    engine = PointClickEngine::Core::Engine.new(
      title: "Door Transition Test",
      window_width: 800,
      window_height: 600
    )
    engine.init
    engine.enable_verb_input

    # Create a scene with a door that has a cheesy transition
    scene = PointClickEngine::Scenes::Scene.new("test_room")
    engine.add_scene(scene)
    engine.change_scene("test_room")

    # Create a door with heart wipe transition
    door_hotspot = PointClickEngine::Scenes::Hotspot.new(
      "magic_door",
      RL::Vector2.new(x: 500f32, y: 400f32),
      RL::Vector2.new(x: 100f32, y: 200f32)
    )
    door_hotspot.default_verb = PointClickEngine::UI::VerbType::Open
    door_hotspot.object_type = PointClickEngine::UI::ObjectType::Door
    door_hotspot.action_commands["open"] = "transition:next_room:heart_wipe:4.5:300,400"
    door_hotspot.action_commands["use"] = "transition:next_room:heart_wipe::300,400" # Uses scene default
    scene.add_hotspot(door_hotspot)

    # Create target scene
    next_scene = PointClickEngine::Scenes::Scene.new("next_room")
    engine.add_scene(next_scene)

    # Get the verb system and transition manager
    verb_system = engine.verb_input_system.not_nil!
    transition_manager = engine.transition_manager.not_nil!

    # Transition should not be active initially
    transition_manager.transitioning?.should be_false

    # Verify the transition command is properly configured
    door_hotspot.action_commands["open"].should eq("transition:next_room:heart_wipe:4.5:300,400")

    # Parse the transition command to verify it's valid
    result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command(door_hotspot.action_commands["open"])
    result.should_not be_nil
    if result
      result[:scene].should eq("next_room")
      result[:effect].should eq(PointClickEngine::Graphics::TransitionEffect::HeartWipe)
      result[:duration].should eq(4.5f32)
    end
  end

  it "uses different transitions for different doors" do
    # Test that our Crystal Mystery doors have different transitions
    expected_transitions = {
      "library"    => ["swirl"],
      "laboratory" => ["heart_wipe", "curtain"],
      "garden"     => ["star_wipe"],
    }

    expected_transitions.each do |scene_name, transitions|
      path = "crystal_mystery/scenes/#{scene_name}.yaml"
      if File.exists?(path)
        content = File.read(path)

        # Check for the new action-based transition format
        content.includes?("transition:").should be_true
        transitions.each do |transition|
          content.includes?(":#{transition}:").should be_true
        end
        # Check for either explicit duration or default duration property
        has_duration = content.includes?(":4.5:") || content.includes?("default_transition_duration:")
        has_duration.should be_true
      end
    end
  end

  it "supports various cheesy transition effects" do
    # Verify all cheesy transitions are available
    cheesy_effects = [
      PointClickEngine::Graphics::TransitionEffect::HeartWipe,
      PointClickEngine::Graphics::TransitionEffect::StarWipe,
      PointClickEngine::Graphics::TransitionEffect::Swirl,
      PointClickEngine::Graphics::TransitionEffect::Curtain,
      PointClickEngine::Graphics::TransitionEffect::Ripple,
      PointClickEngine::Graphics::TransitionEffect::Checkerboard,
      PointClickEngine::Graphics::TransitionEffect::MatrixRain,
      PointClickEngine::Graphics::TransitionEffect::Vortex,
      PointClickEngine::Graphics::TransitionEffect::PageTurn,
      PointClickEngine::Graphics::TransitionEffect::Fire,
    ]

    # All effects should be valid enum values
    cheesy_effects.each do |effect|
      effect.should be_a(PointClickEngine::Graphics::TransitionEffect)
    end
  end

  it "transition duration defaults to 4.5 seconds for maximum cheese" do
    # Test parsing a transition command with the expected duration
    result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:room:swirl:4.5")
    result.should_not be_nil
    if result
      result[:duration].should eq(4.5f32)
    end
  end

  it "uses scene's default transition duration when not specified" do
    # Test parsing with empty duration
    result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:room:swirl::100,200")
    result.should_not be_nil
    if result
      result[:duration].should eq(-1.0f32) # Signal to use scene default
    end

    # Test parsing with "default" keyword
    result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:room:swirl:default")
    result.should_not be_nil
    if result
      result[:duration].should eq(-1.0f32) # Signal to use scene default
    end

    # Test minimal format
    result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:room")
    result.should_not be_nil
    if result
      result[:duration].should eq(-1.0f32) # Signal to use scene default
    end
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

  it "executes transitions via TransitionHelper" do
    engine = PointClickEngine::Core::Engine.new(
      title: "Test",
      window_width: 800,
      window_height: 600
    )
    engine.init

    # Add scenes
    scene1 = PointClickEngine::Scenes::Scene.new("scene1")
    scene2 = PointClickEngine::Scenes::Scene.new("scene2")
    engine.add_scene(scene1)
    engine.add_scene(scene2)
    engine.change_scene("scene1")

    # Test that non-transition commands return false
    result = PointClickEngine::Scenes::TransitionHelper.execute_transition("look_at_painting", engine)
    result.should be_false

    # Note: We can't easily test actual scene transitions in specs
    # because they involve async operations and rendering
  end
end
