require "../spec_helper"

describe PointClickEngine::Audio::VolumeController do
  describe "#set_master_volume" do
    it "sets master volume with clamping" do
      controller = PointClickEngine::Audio::VolumeController.new
      
      controller.set_master_volume(0.8)
      controller.master_volume.should eq(0.8)
      
      # Test clamping
      controller.set_master_volume(1.5)
      controller.master_volume.should eq(1.0)
      
      controller.set_master_volume(-0.5)
      controller.master_volume.should eq(0.0)
    end
  end

  describe "#toggle_mute" do
    it "toggles global mute state" do
      controller = PointClickEngine::Audio::VolumeController.new
      
      controller.muted.should be_false
      
      result = controller.toggle_mute
      result.should be_true
      controller.muted.should be_true
      
      result = controller.toggle_mute
      result.should be_false
      controller.muted.should be_false
    end
  end

  describe "#effective_volumes" do
    it "calculates effective music volume" do
      controller = PointClickEngine::Audio::VolumeController.new
      controller.master_volume = 0.8
      controller.music_volume = 0.5
      
      controller.effective_music_volume.should eq(0.4) # 0.8 * 0.5
      
      # Test with mute
      controller.muted = true
      controller.effective_music_volume.should eq(0.0)
      
      controller.muted = false
      controller.music_muted = true
      controller.effective_music_volume.should eq(0.0)
    end
    
    it "calculates effective sfx volume" do
      controller = PointClickEngine::Audio::VolumeController.new
      controller.master_volume = 0.8
      controller.sfx_volume = 0.6
      
      controller.effective_sfx_volume.should eq(0.48) # 0.8 * 0.6
      
      # Test with mute
      controller.muted = true
      controller.effective_sfx_volume.should eq(0.0)
      
      controller.muted = false
      controller.sfx_muted = true
      controller.effective_sfx_volume.should eq(0.0)
    end
    
    it "calculates effective ambient volume" do
      controller = PointClickEngine::Audio::VolumeController.new
      controller.master_volume = 1.0
      controller.ambient_volume = 0.3
      
      controller.effective_ambient_volume.should eq(0.3)
      
      controller.muted = true
      controller.effective_ambient_volume.should eq(0.0)
    end
    
    it "calculates effective voice volume" do
      controller = PointClickEngine::Audio::VolumeController.new
      controller.master_volume = 0.9
      controller.voice_volume = 0.8
      
      controller.effective_voice_volume.should eq(0.72) # 0.9 * 0.8
      
      controller.muted = true
      controller.effective_voice_volume.should eq(0.0)
    end
  end

  describe "#on_volume_change" do
    it "notifies volume changes" do
      controller = PointClickEngine::Audio::VolumeController.new
      
      changes = [] of Tuple(Symbol, Float32)
      
      controller.on_volume_change do |type, volume|
        changes << {type, volume}
      end
      
      controller.set_master_volume(0.7)
      controller.set_music_volume(0.5)
      controller.set_sfx_volume(0.9)
      
      changes.size.should eq(3)
      changes[0].should eq({:master, 0.7})
      changes[1].should eq({:music, 0.35}) # 0.5 * 0.7
      changes[2].should eq({:sfx, 0.63})   # 0.9 * 0.7
    end
  end

  describe "#to_settings and #from_settings" do
    it "saves and loads settings" do
      controller = PointClickEngine::Audio::VolumeController.new
      
      # Set custom values
      controller.master_volume = 0.8
      controller.music_volume = 0.6
      controller.sfx_volume = 0.9
      controller.ambient_volume = 0.4
      controller.voice_volume = 0.7
      controller.muted = true
      controller.music_muted = true
      controller.sfx_muted = false
      
      # Save settings
      settings = controller.to_settings
      
      # Create new controller and load settings
      new_controller = PointClickEngine::Audio::VolumeController.new
      new_controller.from_settings(settings)
      
      # Verify all settings loaded correctly
      new_controller.master_volume.should eq(0.8)
      new_controller.music_volume.should eq(0.6)
      new_controller.sfx_volume.should eq(0.9)
      new_controller.ambient_volume.should eq(0.4)
      new_controller.voice_volume.should eq(0.7)
      new_controller.muted.should be_true
      new_controller.music_muted.should be_true
      new_controller.sfx_muted.should be_false
    end
  end

  describe "#toggle_music_mute" do
    it "toggles music-specific mute" do
      controller = PointClickEngine::Audio::VolumeController.new
      
      controller.music_muted.should be_false
      
      result = controller.toggle_music_mute
      result.should be_true
      controller.music_muted.should be_true
      
      # Music should be muted but other sounds not
      controller.effective_music_volume.should eq(0.0)
      controller.effective_sfx_volume.should_not eq(0.0)
    end
  end

  describe "#toggle_sfx_mute" do
    it "toggles sfx-specific mute" do
      controller = PointClickEngine::Audio::VolumeController.new
      
      controller.sfx_muted.should be_false
      
      result = controller.toggle_sfx_mute
      result.should be_true
      controller.sfx_muted.should be_true
      
      # SFX should be muted but music not
      controller.effective_sfx_volume.should eq(0.0)
      controller.effective_music_volume.should_not eq(0.0)
    end
  end
end