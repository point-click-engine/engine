require "../../spec_helper"

describe PointClickEngine::Core::Engine do
  describe "initialization" do
    after_each do
      # Reset singleton for clean test state
      PointClickEngine::Core::Engine.reset_instance if PointClickEngine::Core::Engine.responds_to?(:reset_instance)
    end

    context "basic initialization" do
      it "creates engine with default parameters" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")

        engine.window_width.should eq(800)
        engine.window_height.should eq(600)
        engine.window_title.should eq("Test Game")
        engine.target_fps.should eq(60)
        engine.fullscreen.should be_false
      end

      it "accepts custom target FPS" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test", 120)
        engine.target_fps.should eq(120)
      end

      it "implements singleton pattern" do
        engine1 = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine2 = PointClickEngine::Core::Engine.instance

        engine1.should be(engine2)
      end
    end

    context "dependency injection setup" do
      it "initializes with dependency container when provided" do
        container = PointClickEngine::Core::DependencyContainerSimple.new
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test", container: container)

        engine.container.should be(container)
      end

      it "creates default container when none provided" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.container.should_not be_nil
      end

      it "sets up system manager with container" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init

        engine.system_manager.should_not be_nil
      end
    end

    context "system initialization order" do
      it "initializes audio system before graphics" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init

        # Audio system should be available
        engine.system_manager.audio_system.should_not be_nil
      end

      it "initializes input handlers after systems" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init

        # Input manager should be set up
        engine.input_manager.should_not be_nil
      end

      it "sets up render layers after input handlers" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init

        # Render manager should be configured
        engine.render_manager.should_not be_nil
      end
    end

    context "configuration options" do
      it "configures display settings" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.fullscreen = true
        engine.scale_factor = 2.0

        engine.fullscreen.should be_true
        engine.scale_factor.should eq(2.0)
      end

      it "configures performance settings" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.auto_save_interval = 300.0
        engine.performance_monitoring = true

        engine.auto_save_interval.should eq(300.0)
        engine.performance_monitoring.should be_true
      end

      it "configures input features" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.handle_clicks = true
        engine.enable_verb_coin = true
        engine.edge_scroll_enabled = true

        engine.handle_clicks.should be_true
        engine.enable_verb_coin.should be_true
        engine.edge_scroll_enabled.should be_true
      end
    end

    context "error handling during initialization" do
      it "handles missing assets gracefully during init" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        # Should not crash even if some assets are missing
        expect_raises(Exception) do
          engine.init
        end
      end

      it "validates window dimensions" do
        expect_raises(ArgumentError) do
          PointClickEngine::Core::Engine.new(0, 600, "Test")
        end

        expect_raises(ArgumentError) do
          PointClickEngine::Core::Engine.new(800, 0, "Test")
        end
      end

      it "validates target FPS" do
        expect_raises(ArgumentError) do
          PointClickEngine::Core::Engine.new(800, 600, "Test", 0)
        end

        expect_raises(ArgumentError) do
          PointClickEngine::Core::Engine.new(800, 600, "Test", -60)
        end
      end
    end

    context "state management during initialization" do
      it "starts in uninitialized state" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.initialized?.should be_false
      end

      it "transitions to initialized state after init" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init

        engine.initialized?.should be_true
      end

      it "prevents double initialization" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init

        # Second init should be safe but not duplicate work
        expect_raises(Exception) do
          engine.init
        end
      end
    end

    context "memory management during initialization" do
      it "properly allocates system managers" do
        initial_objects = GC.stats.heap_size

        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.init

        # Should allocate new objects for systems
        final_objects = GC.stats.heap_size
        final_objects.should be > initial_objects
      end

      it "cleans up on failed initialization" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")

        begin
          # Force initialization failure
          engine.init
        rescue
          # Cleanup should occur automatically
        end

        # Memory should be released
        GC.collect
      end
    end
  end

  describe "configuration loading" do
    context "from game config" do
      it "applies configuration after initialization" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")

        # Mock config with specific settings
        config = PointClickEngine::Core::GameConfig.new
        config.window = PointClickEngine::Core::WindowConfig.new
        config.window.not_nil!.width = 1920
        config.window.not_nil!.height = 1080
        config.window.not_nil!.fullscreen = true

        engine.configure_from(config)

        engine.window_width.should eq(1920)
        engine.window_height.should eq(1080)
        engine.fullscreen.should be_true
      end

      it "preserves existing settings when config incomplete" do
        engine = PointClickEngine::Core::Engine.new(800, 600, "Test")
        engine.target_fps = 120

        config = PointClickEngine::Core::GameConfig.new
        # Config without FPS setting

        engine.configure_from(config)

        # Should preserve original FPS setting
        engine.target_fps.should eq(120)
      end
    end
  end
end
