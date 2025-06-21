require "../spec_helper"
require "../../src/audio/footstep_system"

describe PointClickEngine::Audio::SurfaceType do
  it "has all surface types" do
    surfaces = [
      PointClickEngine::Audio::SurfaceType::Stone,
      PointClickEngine::Audio::SurfaceType::Wood,
      PointClickEngine::Audio::SurfaceType::Grass,
      PointClickEngine::Audio::SurfaceType::Sand,
      PointClickEngine::Audio::SurfaceType::Water,
      PointClickEngine::Audio::SurfaceType::Metal,
      PointClickEngine::Audio::SurfaceType::Carpet,
      PointClickEngine::Audio::SurfaceType::Gravel,
      PointClickEngine::Audio::SurfaceType::Snow,
      PointClickEngine::Audio::SurfaceType::Mud,
      PointClickEngine::Audio::SurfaceType::Tile,
    ]

    surfaces.each do |surface|
      surface.should be_a(PointClickEngine::Audio::SurfaceType)
    end
  end
end

describe PointClickEngine::Audio::FootstepConfig do
  it "initializes with surface and sound files" do
    files = ["step1.wav", "step2.wav", "step3.wav"]
    config = PointClickEngine::Audio::FootstepConfig.new(
      PointClickEngine::Audio::SurfaceType::Stone,
      files
    )

    config.surface.should eq PointClickEngine::Audio::SurfaceType::Stone
    config.sound_files.should eq files
    config.volume_range.should eq({0.8f32, 1.0f32})
    config.pitch_range.should eq({0.9f32, 1.1f32})
    config.step_interval.should eq 0.5f32
  end

  it "supports custom volume and pitch ranges" do
    config = PointClickEngine::Audio::FootstepConfig.new(
      PointClickEngine::Audio::SurfaceType::Water,
      ["splash.wav"]
    )
    config.volume_range = {0.5f32, 0.7f32}
    config.pitch_range = {0.8f32, 1.2f32}

    config.volume_range.should eq({0.5f32, 0.7f32})
    config.pitch_range.should eq({0.8f32, 1.2f32})
  end
end

describe PointClickEngine::Audio::SurfaceArea do
  it "initializes with bounds and surface type" do
    bounds = RL::Rectangle.new(x: 0, y: 0, width: 100, height: 100)
    area = PointClickEngine::Audio::SurfaceArea.new(bounds, PointClickEngine::Audio::SurfaceType::Grass)

    area.bounds.should eq bounds
    area.surface.should eq PointClickEngine::Audio::SurfaceType::Grass
  end

  it "checks if position is contained" do
    bounds = RL::Rectangle.new(x: 10, y: 10, width: 80, height: 80)
    area = PointClickEngine::Audio::SurfaceArea.new(bounds, PointClickEngine::Audio::SurfaceType::Wood)

    # Position inside
    inside = RL::Vector2.new(x: 50f32, y: 50f32)
    area.contains?(inside).should be_true

    # Position outside
    outside = RL::Vector2.new(x: 5f32, y: 5f32)
    area.contains?(outside).should be_false

    # Position on edge
    edge = RL::Vector2.new(x: 10f32, y: 10f32)
    area.contains?(edge).should be_true
  end
end

describe PointClickEngine::Audio::CharacterFootsteps do
  it "initializes with character" do
    character = MockCharacter.new(RL::Vector2.new(x: 100f32, y: 100f32))
    footsteps = PointClickEngine::Audio::CharacterFootsteps.new(character)

    footsteps.character.should eq character
    footsteps.step_timer.should eq 0.0f32
    footsteps.last_position.should eq character.position
    footsteps.current_surface.should eq PointClickEngine::Audio::SurfaceType::Stone
    footsteps.moving.should be_false
  end

  it "detects character movement" do
    character = MockCharacter.new(RL::Vector2.new(x: 100f32, y: 100f32))
    footsteps = PointClickEngine::Audio::CharacterFootsteps.new(character)
    system = PointClickEngine::Audio::FootstepSystem.new

    # Verify initial position
    character.position.x.should eq 100f32
    character.position.y.should eq 100f32
    footsteps.last_position.x.should eq 100f32
    footsteps.last_position.y.should eq 100f32

    # Move character
    character.position = RL::Vector2.new(x: 150f32, y: 100f32)

    # Verify position changed
    character.position.x.should eq 150f32
    character.position.y.should eq 100f32

    # Store initial accumulated distance
    initial_distance = footsteps.accumulated_distance

    footsteps.update(0.1f32, system)

    footsteps.moving.should be_true
    # Since the character moved 50 pixels and threshold is 32, a footstep should have played
    # and accumulated_distance should have been reset to 0
    footsteps.accumulated_distance.should eq 0.0f32
  end

  it "tracks surface changes" do
    character = MockCharacter.new(RL::Vector2.new(x: 0f32, y: 0f32))
    footsteps = PointClickEngine::Audio::CharacterFootsteps.new(character)

    footsteps.set_surface(PointClickEngine::Audio::SurfaceType::Water)

    footsteps.current_surface.should eq PointClickEngine::Audio::SurfaceType::Water
  end
end

describe PointClickEngine::Audio::FootstepSystem do
  it "initializes with default surface configurations" do
    system = PointClickEngine::Audio::FootstepSystem.new

    # Should have some default surfaces
    system.surface_configs.size.should be > 0
    system.surface_configs.has_key?(PointClickEngine::Audio::SurfaceType::Stone).should be_true
    system.surface_configs.has_key?(PointClickEngine::Audio::SurfaceType::Wood).should be_true
    system.surface_configs.has_key?(PointClickEngine::Audio::SurfaceType::Grass).should be_true
  end

  it "registers and manages characters" do
    system = PointClickEngine::Audio::FootstepSystem.new
    character = MockCharacter.new(RL::Vector2.new(x: 0f32, y: 0f32))

    system.register_character(character)

    system.character_footsteps.has_key?(character.name).should be_true

    system.unregister_character(character.name)

    system.character_footsteps.has_key?(character.name).should be_false
  end

  it "adds surface configurations" do
    system = PointClickEngine::Audio::FootstepSystem.new
    config = PointClickEngine::Audio::FootstepConfig.new(
      PointClickEngine::Audio::SurfaceType::Snow,
      ["snow1.wav", "snow2.wav"]
    )

    system.add_surface_config(config)

    system.get_surface_config(PointClickEngine::Audio::SurfaceType::Snow).should eq config
  end

  it "manages surface areas" do
    system = PointClickEngine::Audio::FootstepSystem.new
    bounds = RL::Rectangle.new(x: 0, y: 0, width: 100, height: 100)
    area = PointClickEngine::Audio::SurfaceArea.new(bounds, PointClickEngine::Audio::SurfaceType::Water)

    system.add_surface_area(area)

    # Test detection
    water_pos = RL::Vector2.new(x: 50f32, y: 50f32)
    stone_pos = RL::Vector2.new(x: 150f32, y: 150f32)

    system.detect_surface_at_position(water_pos).should eq PointClickEngine::Audio::SurfaceType::Water
    system.detect_surface_at_position(stone_pos).should eq PointClickEngine::Audio::SurfaceType::Stone
  end

  it "sets up room surfaces" do
    system = PointClickEngine::Audio::FootstepSystem.new
    room_bounds = RL::Rectangle.new(x: 0, y: 0, width: 800, height: 600)

    system.setup_room_surfaces(room_bounds, PointClickEngine::Audio::SurfaceType::Wood)

    # Should have cleared old areas and added new one
    center_pos = RL::Vector2.new(x: 400f32, y: 300f32)
    system.detect_surface_at_position(center_pos).should eq PointClickEngine::Audio::SurfaceType::Wood
  end

  it "controls global volume" do
    system = PointClickEngine::Audio::FootstepSystem.new

    system.set_volume(0.5f32)
    system.global_volume.should eq 0.5f32

    # Test clamping
    system.set_volume(1.5f32)
    system.global_volume.should eq 1.0f32

    system.set_volume(-0.5f32)
    system.global_volume.should eq 0.0f32
  end

  it "can be enabled and disabled" do
    system = PointClickEngine::Audio::FootstepSystem.new

    system.enabled.should be_true

    system.set_enabled(false)
    system.enabled.should be_false

    system.set_enabled(true)
    system.enabled.should be_true
  end

  it "updates character footsteps" do
    system = PointClickEngine::Audio::FootstepSystem.new
    character = MockCharacter.new(RL::Vector2.new(x: 100f32, y: 100f32))

    system.register_character(character)

    # Move character
    character.position = RL::Vector2.new(x: 150f32, y: 100f32)

    # Update system
    system.update(0.1f32)

    # Character footsteps should be updated
    char_footsteps = system.character_footsteps[character.name]
    char_footsteps.moving.should be_true
  end

  it "clears surface areas" do
    system = PointClickEngine::Audio::FootstepSystem.new
    area = PointClickEngine::Audio::SurfaceArea.new(
      RL::Rectangle.new(x: 0, y: 0, width: 100, height: 100),
      PointClickEngine::Audio::SurfaceType::Grass
    )

    system.add_surface_area(area)
    system.surface_areas.size.should eq 1

    system.clear_surface_areas
    system.surface_areas.size.should eq 0
  end
end

# Mock character for testing
class MockCharacter < PointClickEngine::Characters::Character
  def initialize(position : RL::Vector2)
    super("MockCharacter", position, RL::Vector2.new(x: 32, y: 32))
  end

  def on_interact(interactor : PointClickEngine::Characters::Character)
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
