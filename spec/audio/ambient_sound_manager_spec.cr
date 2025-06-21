require "../spec_helper"
require "../../src/audio/ambient_sound_manager"

describe PointClickEngine::Audio::AmbientSoundConfig do
  it "initializes with name and file path" do
    config = PointClickEngine::Audio::AmbientSoundConfig.new("forest", "assets/sounds/forest.wav")

    config.name.should eq "forest"
    config.file_path.should eq "assets/sounds/forest.wav"
    config.volume.should eq 1.0f32
    config.loop.should be_true
    config.fade_in_duration.should eq 2.0f32
    config.fade_out_duration.should eq 2.0f32
    config.spatial.should be_false
  end

  it "supports spatial audio configuration" do
    config = PointClickEngine::Audio::AmbientSoundConfig.new("water", "assets/sounds/water.wav")
    config.spatial = true
    config.position = RL::Vector2.new(x: 100f32, y: 200f32)
    config.max_distance = 300f32

    config.spatial.should be_true
    config.position.x.should eq 100f32
    config.position.y.should eq 200f32
    config.max_distance.should eq 300f32
  end
end

describe PointClickEngine::Audio::AmbientSound do
  it "initializes with configuration" do
    config = PointClickEngine::Audio::AmbientSoundConfig.new("test", "test.wav")
    sound = PointClickEngine::Audio::AmbientSound.new(config)

    sound.config.should eq config
    sound.playing.should be_false
    sound.current_volume.should eq 0.0f32
    sound.target_volume.should eq 1.0f32
  end

  it "handles volume changes with fading" do
    config = PointClickEngine::Audio::AmbientSoundConfig.new("test", "test.wav")
    sound = PointClickEngine::Audio::AmbientSound.new(config)

    sound.set_volume(0.5f32, 1.0f32)

    sound.target_volume.should eq 0.5f32
    sound.fade_duration.should eq 1.0f32
  end

  it "updates fade effects over time" do
    config = PointClickEngine::Audio::AmbientSoundConfig.new("test", "test.wav")
    sound = PointClickEngine::Audio::AmbientSound.new(config)

    # Start with some volume and fade
    sound.current_volume = 1.0f32
    sound.set_volume(0.0f32, 2.0f32)

    # Update halfway through fade
    sound.update(1.0f32)

    # Should be between original and target
    sound.current_volume.should be < 1.0f32
    sound.current_volume.should be > 0.0f32
  end
end

describe PointClickEngine::Audio::AmbientSoundManager do
  it "registers and manages ambient sounds" do
    manager = PointClickEngine::Audio::AmbientSoundManager.new
    config = PointClickEngine::Audio::AmbientSoundConfig.new("forest", "forest.wav")

    manager.register_sound(config)

    manager.sounds.has_key?("forest").should be_true
    manager.sounds["forest"].config.name.should eq "forest"
  end

  it "manages room ambience" do
    manager = PointClickEngine::Audio::AmbientSoundManager.new

    forest_config = PointClickEngine::Audio::AmbientSoundConfig.new("forest", "forest.wav")
    cave_config = PointClickEngine::Audio::AmbientSoundConfig.new("cave", "cave.wav")

    manager.register_sound(forest_config)
    manager.register_sound(cave_config)

    manager.set_room_ambience("forest")
    manager.current_room_ambience.should eq "forest"

    manager.set_room_ambience("cave")
    manager.current_room_ambience.should eq "cave"
  end

  it "tracks listener position for spatial audio" do
    manager = PointClickEngine::Audio::AmbientSoundManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.set_listener_position(position)

    manager.listener_position.should eq position
  end

  it "controls global volume" do
    manager = PointClickEngine::Audio::AmbientSoundManager.new

    manager.set_global_volume(0.5f32)
    manager.global_volume.should eq 0.5f32

    # Test clamping
    manager.set_global_volume(1.5f32)
    manager.global_volume.should eq 1.0f32

    manager.set_global_volume(-0.5f32)
    manager.global_volume.should eq 0.0f32
  end

  it "stops all sounds" do
    manager = PointClickEngine::Audio::AmbientSoundManager.new

    forest_config = PointClickEngine::Audio::AmbientSoundConfig.new("forest", "forest.wav")
    manager.register_sound(forest_config)
    manager.set_room_ambience("forest")

    manager.stop_all(true)
    manager.current_room_ambience.should be_nil
  end

  it "reports playing sounds status" do
    manager = PointClickEngine::Audio::AmbientSoundManager.new

    config = PointClickEngine::Audio::AmbientSoundConfig.new("test", "test.wav")
    manager.register_sound(config)

    manager.is_playing?("test").should be_false
    manager.get_playing_sounds.should be_empty
  end
end
