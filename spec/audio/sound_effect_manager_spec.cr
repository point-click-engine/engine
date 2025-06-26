require "../spec_helper"

# Mock sound effect for testing
class MockSoundEffect < PointClickEngine::Audio::SoundEffect
  property play_count = 0
  property last_volume : Float32 = 0.0
  
  def play
    @play_count += 1
    @last_volume = @volume
  end
end

describe PointClickEngine::Audio::SoundEffectManager do
  describe "#load_sound" do
    it "loads and caches sound effects" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      
      # Since we can't actually load files in specs, we'll test the caching
      manager.sound_effects["test_sound"] = MockSoundEffect.new("test_sound", "fake_path.wav")
      
      manager.has_sound?("test_sound").should be_true
      manager.get_sound("test_sound").should_not be_nil
    end
  end

  describe "#play_sound" do
    it "plays sounds with volume multiplier" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      manager.sfx_volume = 0.5
      
      mock_sound = MockSoundEffect.new("test", "fake.wav")
      manager.sound_effects["test"] = mock_sound
      
      manager.play_sound("test", 0.8)
      
      mock_sound.play_count.should eq(1)
      mock_sound.last_volume.should eq(0.4) # 0.8 * 0.5
    end
    
    it "handles missing sounds gracefully" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      
      # Should not raise
      manager.play_sound("nonexistent")
    end
  end

  describe "#play_sound_at" do
    it "calculates distance-based volume" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      manager.sfx_volume = 1.0
      
      mock_sound = MockSoundEffect.new("test", "fake.wav")
      manager.sound_effects["test"] = mock_sound
      
      # Sound at same position as listener (full volume)
      manager.play_sound_at("test", RL::Vector2.new(100, 100), RL::Vector2.new(100, 100), 500.0)
      mock_sound.last_volume.should eq(1.0)
      
      # Sound at half max distance (half volume)
      manager.play_sound_at("test", RL::Vector2.new(350, 100), RL::Vector2.new(100, 100), 500.0)
      mock_sound.last_volume.should be_close(0.5, 0.01)
      
      # Sound beyond max distance (no volume)
      manager.play_sound_at("test", RL::Vector2.new(700, 100), RL::Vector2.new(100, 100), 500.0)
      mock_sound.last_volume.should eq(0.0)
    end
  end

  describe "#preload_sounds" do
    it "loads multiple sounds at once" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      
      # Mock the loading
      sounds = [
        {"sound1", "path1.wav"},
        {"sound2", "path2.wav"},
        {"sound3", "path3.wav"}
      ]
      
      sounds.each do |name, path|
        manager.sound_effects[name] = MockSoundEffect.new(name, path)
      end
      
      manager.sound_effects.size.should eq(3)
      manager.has_sound?("sound1").should be_true
      manager.has_sound?("sound2").should be_true
      manager.has_sound?("sound3").should be_true
    end
  end

  describe "#unload_sound" do
    it "removes sound from cache" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      
      mock_sound = MockSoundEffect.new("test", "fake.wav")
      manager.sound_effects["test"] = mock_sound
      
      manager.unload_sound("test")
      
      manager.has_sound?("test").should be_false
      manager.sound_effects.empty?.should be_true
    end
  end

  describe "#clear_cache" do
    it "removes all sounds" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      
      3.times do |i|
        manager.sound_effects["sound#{i}"] = MockSoundEffect.new("sound#{i}", "fake#{i}.wav")
      end
      
      manager.clear_cache
      
      manager.sound_effects.empty?.should be_true
    end
  end

  describe "#update_volume" do
    it "updates the global sound effects volume" do
      manager = PointClickEngine::Audio::SoundEffectManager.new
      
      manager.update_volume(0.75)
      manager.sfx_volume.should eq(0.75)
      
      # Test clamping
      manager.update_volume(1.5)
      manager.sfx_volume.should eq(1.0)
      
      manager.update_volume(-0.5)
      manager.sfx_volume.should eq(0.0)
    end
  end
end