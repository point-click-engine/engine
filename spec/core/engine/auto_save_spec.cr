require "../../spec_helper"

describe "Engine Auto-Save Functionality" do
  describe "#enable_auto_save" do
    it "sets the auto-save interval" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Auto-Save Test")
      
      engine.auto_save_interval.should eq(0.0f32)
      engine.enable_auto_save(300.0f32)
      engine.auto_save_interval.should eq(300.0f32)
      engine.auto_save_timer.should eq(0.0f32)
    end
    
    it "disables auto-save when interval is 0" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Auto-Save Test")
      
      engine.enable_auto_save(300.0f32)
      engine.auto_save_interval.should eq(300.0f32)
      
      engine.enable_auto_save(0.0f32)
      engine.auto_save_interval.should eq(0.0f32)
    end
  end
  
  describe "auto-save during update" do
    it "saves game when timer reaches interval" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Auto-Save Test")
      RL.init_window(800, 600, "Auto-Save Test")
      engine.init
      
      # Enable auto-save with 2 second interval
      engine.enable_auto_save(2.0f32)
      
      # Create saves directory for test
      Dir.mkdir_p("saves")
      
      # Simulate updates
      10.times do
        engine.update(0.3f32) # 0.3 seconds per update
      end
      
      # Should have saved after 2 seconds
      File.exists?("saves/autosave.yml").should be_true
      
      # Check save content
      saved_content = File.read("saves/autosave.yml")
      saved_content.should contain("title: Auto-Save Test")
      
      # Cleanup
      RL.close_window
      File.delete("saves/autosave.yml") if File.exists?("saves/autosave.yml")
      Dir.delete("saves") if Dir.empty?("saves")
    end
    
    it "resets timer after auto-save" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Timer Reset Test")
      RL.init_window(800, 600, "Timer Reset Test")
      engine.init
      
      engine.enable_auto_save(1.0f32) # 1 second interval
      
      Dir.mkdir_p("saves")
      
      # First save
      engine.update(1.1f32)
      engine.auto_save_timer.should be_close(0.0f32, 0.01f32)
      
      # Timer should accumulate again
      engine.update(0.5f32)
      engine.auto_save_timer.should be_close(0.5f32, 0.01f32)
      
      # Second save
      engine.update(0.6f32)
      engine.auto_save_timer.should be_close(0.0f32, 0.01f32)
      
      # Cleanup
      RL.close_window
      File.delete("saves/autosave.yml") if File.exists?("saves/autosave.yml")
      Dir.delete("saves") if Dir.empty?("saves")
    end
    
    it "does not save when auto-save is disabled" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "No Save Test")
      RL.init_window(800, 600, "No Save Test")
      engine.init
      
      # Auto-save disabled by default
      engine.auto_save_interval.should eq(0.0f32)
      
      # Delete any existing autosave
      File.delete("saves/autosave.yml") if File.exists?("saves/autosave.yml")
      
      # Update should not trigger save
      engine.update(10.0f32)
      
      File.exists?("saves/autosave.yml").should be_false
      
      # Cleanup
      RL.close_window
    end
    
    it "creates saves directory if it doesn't exist" do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Dir Creation Test")
      RL.init_window(800, 600, "Dir Creation Test")
      engine.init
      
      # Ensure saves directory doesn't exist
      if Dir.exists?("saves")
        Dir.each_child("saves") { |f| File.delete("saves/#{f}") }
        Dir.delete("saves")
      end
      
      engine.enable_auto_save(0.1f32) # Quick save
      
      Dir.exists?("saves").should be_false
      
      engine.update(0.15f32)
      
      Dir.exists?("saves").should be_true
      File.exists?("saves/autosave.yml").should be_true
      
      # Cleanup
      RL.close_window
      File.delete("saves/autosave.yml")
      Dir.delete("saves")
    end
  end
  
  describe "integration with game config" do
    it "enables auto-save from YAML config" do
      config_yaml = <<-YAML
      game:
        title: "Config Auto-Save Test"
      
      features:
        - auto_save
      YAML
      
      File.write("autosave_config.yaml", config_yaml)
      config = PointClickEngine::Core::GameConfig.from_file("autosave_config.yaml")
      
      RL.init_window(800, 600, "Config Auto-Save Test")
      engine = config.create_engine
      
      # Should be enabled with default 5 minute interval
      engine.auto_save_interval.should eq(300.0f32)
      
      # Cleanup
      RL.close_window
      File.delete("autosave_config.yaml")
    end
  end
end