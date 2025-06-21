require "../spec_helper"
require "../../src/cutscenes/cutscene_camera"

describe PointClickEngine::Cutscenes::EasingFunctions do
  it "provides easing functions" do
    # Test basic easing function behavior
    PointClickEngine::Cutscenes::EasingFunctions.ease_in_out_cubic(0.0f32).should eq 0.0f32
    PointClickEngine::Cutscenes::EasingFunctions.ease_in_out_cubic(1.0f32).should eq 1.0f32
    PointClickEngine::Cutscenes::EasingFunctions.ease_in_out_cubic(0.5f32).should eq 0.5f32

    PointClickEngine::Cutscenes::EasingFunctions.ease_out_quad(0.0f32).should eq 0.0f32
    PointClickEngine::Cutscenes::EasingFunctions.ease_out_quad(1.0f32).should eq 1.0f32
  end
end

describe PointClickEngine::Cutscenes::CameraTransition do
  it "has all transition types" do
    transitions = [
      PointClickEngine::Cutscenes::CameraTransition::Linear,
      PointClickEngine::Cutscenes::CameraTransition::EaseInOut,
      PointClickEngine::Cutscenes::CameraTransition::EaseIn,
      PointClickEngine::Cutscenes::CameraTransition::EaseOut,
      PointClickEngine::Cutscenes::CameraTransition::Bounce,
      PointClickEngine::Cutscenes::CameraTransition::Sine,
    ]

    transitions.each do |transition|
      transition.should be_a(PointClickEngine::Cutscenes::CameraTransition)
    end
  end
end

describe PointClickEngine::Cutscenes::CutsceneCamera do
  it "initializes with position" do
    start_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(start_pos)

    camera.position.should eq start_pos
    camera.zoom.should eq 1.0f32
    camera.rotation.should eq 0.0f32
    camera.shake_intensity.should eq 0.0f32
    camera.target_character.should be_nil
  end

  it "pans to target position" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))
    target = RL::Vector2.new(x: 100f32, y: 100f32)

    camera.pan_to(target, 2.0f32)

    camera.pan_active.should be_true
    camera.pan_target.should eq target
    camera.pan_duration.should eq 2.0f32
    camera.target_character.should be_nil # Stop following during pan
  end

  it "zooms to target level" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))

    camera.zoom_to(2.0f32, 1.5f32)

    camera.zoom_active.should be_true
    camera.zoom_target.should eq 2.0f32
    camera.zoom_duration.should eq 1.5f32
  end

  it "shakes with intensity and duration" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))

    camera.shake(10.0f32, 1.0f32, 15.0f32)

    camera.shake_active.should be_true
    camera.shake_intensity.should eq 10.0f32
    camera.shake_duration.should eq 1.0f32
    camera.shake_frequency.should eq 15.0f32
  end

  it "follows character smoothly" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))
    character = MockCharacter.new(RL::Vector2.new(x: 100f32, y: 100f32))

    camera.follow(character, true, 30.0f32)

    camera.target_character.should eq character
    camera.follow_smooth.should be_true
    camera.follow_deadzone.should eq 30.0f32
    camera.pan_active.should be_false # Stop pan when following
  end

  it "stops following character" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))
    character = MockCharacter.new(RL::Vector2.new(x: 100f32, y: 100f32))

    camera.follow(character)
    camera.target_character.should eq character

    camera.stop_following
    camera.target_character.should be_nil
  end

  it "sets and removes bounds" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))
    bounds = RL::Rectangle.new(x: 0, y: 0, width: 800, height: 600)

    camera.set_bounds(bounds)
    camera.constrain_to_bounds.should be_true
    camera.screen_bounds.should eq bounds

    camera.remove_bounds
    camera.constrain_to_bounds.should be_false
  end

  it "updates pan animation" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))
    target = RL::Vector2.new(x: 100f32, y: 100f32)

    camera.pan_to(target, 1.0f32)

    # Update halfway through animation
    camera.update(0.5f32)
    camera.pan_active.should be_true
    camera.position.x.should be > 0f32
    camera.position.x.should be < 100f32

    # Complete animation
    camera.update(0.6f32) # Total 1.1s > 1.0s duration
    camera.pan_active.should be_false
    camera.position.should eq target
  end

  it "updates zoom animation" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))

    camera.zoom_to(2.0f32, 1.0f32)

    # Update halfway
    camera.update(0.5f32)
    camera.zoom_active.should be_true
    camera.zoom.should be > 1.0f32
    camera.zoom.should be < 2.0f32

    # Complete animation
    camera.update(0.6f32)
    camera.zoom_active.should be_false
    camera.zoom.should eq 2.0f32
  end

  it "updates shake effect" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))

    camera.shake(5.0f32, 1.0f32)

    # Update during shake
    camera.update(0.3f32)
    camera.shake_active.should be_true
    # Shake offset should be non-zero (random, so we can't test exact values)

    # Complete shake
    camera.update(0.8f32)
    camera.shake_active.should be_false
    camera.shake_offset.x.should eq 0f32
    camera.shake_offset.y.should eq 0f32
  end

  it "gets final position with offsets" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 100f32, y: 100f32))
    camera.offset = RL::Vector2.new(x: 10f32, y: 20f32)
    camera.shake_offset = RL::Vector2.new(x: 5f32, y: -5f32)

    final_pos = camera.get_final_position
    final_pos.x.should eq 115f32 # 100 + 10 + 5
    final_pos.y.should eq 115f32 # 100 + 20 + (-5)
  end

  it "converts between screen and world coordinates" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 100f32, y: 100f32))
    camera.zoom = 2.0f32

    # Screen to world
    screen_pos = RL::Vector2.new(x: 200f32, y: 200f32)
    world_pos = camera.screen_to_world(screen_pos)
    world_pos.x.should eq 200f32 # (200 / 2) + 100
    world_pos.y.should eq 200f32

    # World to screen
    world_pos2 = RL::Vector2.new(x: 150f32, y: 150f32)
    screen_pos2 = camera.world_to_screen(world_pos2)
    screen_pos2.x.should eq 100f32 # (150 - 100) * 2
    screen_pos2.y.should eq 100f32
  end

  it "reports animation status" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 0f32, y: 0f32))

    camera.is_animating?.should be_false

    camera.pan_to(RL::Vector2.new(x: 100f32, y: 100f32), 1.0f32)
    camera.is_animating?.should be_true

    camera.stop_all_animations
    camera.is_animating?.should be_false
  end

  it "resets to default state" do
    camera = PointClickEngine::Cutscenes::CutsceneCamera.new(RL::Vector2.new(x: 100f32, y: 100f32))
    character = MockCharacter.new(RL::Vector2.new(x: 200f32, y: 200f32))

    camera.zoom = 2.0f32
    camera.rotation = 45.0f32
    camera.follow(character)
    camera.shake(5.0f32, 1.0f32)

    camera.reset

    camera.target_character.should be_nil
    camera.zoom.should eq 1.0f32
    camera.rotation.should eq 0.0f32
    camera.is_animating?.should be_false
  end
end

# Mock character for testing
class MockCharacter < PointClickEngine::Characters::Character
  def initialize(position : RL::Vector2)
    super("MockCharacter", position, RL::Vector2.new(x: 32, y: 32))
  end

  def on_interact(interactor : Character)
    # Mock implementation
  end

  def on_look
    # Mock implementation
  end

  def on_talk
    # Mock implementation
  end

  def on_use_item(item)
    # Mock implementation
  end
end
