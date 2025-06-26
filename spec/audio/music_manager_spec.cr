require "../spec_helper"

# Mock music for testing
class MockMusic < PointClickEngine::Audio::Music
  property play_count = 0
  property stop_count = 0
  property last_loop_setting = false
  
  def play(loop : Bool = true)
    @play_count += 1
    @last_loop_setting = loop
    @playing = true
  end
  
  def stop
    @stop_count += 1
    @playing = false
  end
end

describe PointClickEngine::Audio::MusicManager do
  describe "#load_music" do
    it "loads and caches music tracks" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      # Mock loading
      manager.music_tracks["theme"] = MockMusic.new("theme", "fake_theme.ogg")
      
      manager.music_tracks.has_key?("theme").should be_true
      manager.music_tracks["theme"].should_not be_nil
    end
  end

  describe "#play_music" do
    it "plays music and sets as current" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      mock_music = MockMusic.new("theme", "fake.ogg")
      manager.music_tracks["theme"] = mock_music
      
      manager.play_music("theme", loop: true)
      
      mock_music.play_count.should eq(1)
      mock_music.last_loop_setting.should be_true
      manager.current_music.should eq(mock_music)
    end
    
    it "stops previous music before playing new" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      mock_music1 = MockMusic.new("theme1", "fake1.ogg")
      mock_music2 = MockMusic.new("theme2", "fake2.ogg")
      
      manager.music_tracks["theme1"] = mock_music1
      manager.music_tracks["theme2"] = mock_music2
      
      manager.play_music("theme1")
      manager.play_music("theme2")
      
      mock_music1.stop_count.should eq(1)
      mock_music2.play_count.should eq(1)
      manager.current_music.should eq(mock_music2)
    end
  end

  describe "#crossfade_to" do
    it "initiates crossfade between tracks" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      mock_music1 = MockMusic.new("theme1", "fake1.ogg")
      mock_music2 = MockMusic.new("theme2", "fake2.ogg")
      
      manager.music_tracks["theme1"] = mock_music1
      manager.music_tracks["theme2"] = mock_music2
      
      # Start first music
      manager.play_music("theme1")
      
      # Start crossfade
      manager.crossfade_to("theme2", duration: 1.0)
      
      # Both should be playing during crossfade
      mock_music1.playing.should be_true
      mock_music2.playing.should be_true
      mock_music2.volume.should eq(0.0) # Starts at 0
    end
  end

  describe "#update" do
    it "processes crossfade over time" do
      manager = PointClickEngine::Audio::MusicManager.new
      manager.music_volume = 1.0
      
      mock_music1 = MockMusic.new("theme1", "fake1.ogg")
      mock_music2 = MockMusic.new("theme2", "fake2.ogg")
      
      manager.music_tracks["theme1"] = mock_music1
      manager.music_tracks["theme2"] = mock_music2
      
      manager.play_music("theme1")
      mock_music1.volume = 1.0
      
      manager.crossfade_to("theme2", duration: 1.0)
      
      # Update halfway through
      manager.update(0.5)
      
      # Volumes should be halfway
      mock_music1.volume.should be_close(0.5, 0.01)
      mock_music2.volume.should be_close(0.5, 0.01)
      
      # Complete the fade
      manager.update(0.5)
      
      # Old music should be stopped
      mock_music1.stop_count.should eq(1)
      mock_music2.volume.should eq(1.0)
      manager.current_music.should eq(mock_music2)
    end
  end

  describe "#stop_music" do
    it "stops current music" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      mock_music = MockMusic.new("theme", "fake.ogg")
      manager.music_tracks["theme"] = mock_music
      
      manager.play_music("theme")
      manager.stop_music
      
      mock_music.stop_count.should eq(1)
      manager.current_music.should be_nil
    end
  end

  describe "#set_volume" do
    it "updates music volume" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      manager.set_volume(0.7)
      manager.music_volume.should eq(0.7)
      
      # Test clamping
      manager.set_volume(1.5)
      manager.music_volume.should eq(1.0)
      
      manager.set_volume(-0.5)
      manager.music_volume.should eq(0.0)
    end
  end

  describe "#current_track_name" do
    it "returns name of current track" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      mock_music = MockMusic.new("battle_theme", "fake.ogg")
      manager.music_tracks["battle_theme"] = mock_music
      
      manager.current_track_name.should be_nil
      
      manager.play_music("battle_theme")
      manager.current_track_name.should eq("battle_theme")
    end
  end

  describe "#playing?" do
    it "returns playing state" do
      manager = PointClickEngine::Audio::MusicManager.new
      
      manager.playing?.should be_false
      
      mock_music = MockMusic.new("theme", "fake.ogg")
      manager.music_tracks["theme"] = mock_music
      
      manager.play_music("theme")
      manager.playing?.should be_true
      
      manager.stop_music
      manager.playing?.should be_false
    end
  end
end