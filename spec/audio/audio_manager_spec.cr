require "../spec_helper"

describe "Audio::AudioManager" do
  it "initializes without requiring audio device to be ready" do
    # The audio manager should initialize successfully even if audio device is not ready
    audio_manager = PointClickEngine::Audio::AudioManager.new
    audio_manager.should_not be_nil
  end

  it "can load sounds without crashing" do
    audio_manager = PointClickEngine::Audio::AudioManager.new

    # Should handle loading gracefully even without valid files
    # These methods exist but files don't - should not crash
    audio_manager.load_sound_effect("test_sound", "nonexistent.wav")
    audio_manager.load_music("test_music", "nonexistent.ogg")

    # These operations should not crash
    audio_manager.play_sound_effect("test_sound")
    audio_manager.play_music("test_music")
    audio_manager.stop_music
    audio_manager.pause_music
    audio_manager.resume_music
  end

  it "respects volume settings" do
    audio_manager = PointClickEngine::Audio::AudioManager.new

    # Set volumes
    audio_manager.sfx_volume = 0.5_f32
    audio_manager.music_volume = 0.3_f32
    audio_manager.master_volume = 0.8_f32

    # Get volumes
    audio_manager.sfx_volume.should eq(0.5_f32)
    audio_manager.music_volume.should eq(0.3_f32)
    audio_manager.master_volume.should eq(0.8_f32)
  end

  it "handles mute functionality" do
    audio_manager = PointClickEngine::Audio::AudioManager.new

    # Initially not muted
    audio_manager.muted.should be_false

    # Mute
    audio_manager.muted = true
    audio_manager.muted.should be_true

    # Unmute
    audio_manager.muted = false
    audio_manager.muted.should be_false

    # Toggle
    audio_manager.toggle_mute
    audio_manager.muted.should be_true
    audio_manager.toggle_mute
    audio_manager.muted.should be_false
  end

  it "checks if audio is available" do
    # This is a class method
    available = PointClickEngine::Audio::AudioManager.available?
    # Should be true or false, not nil
    (available == true || available == false).should be_true
  end
end
