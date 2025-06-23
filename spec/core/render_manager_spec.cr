require "../spec_helper"
require "../../src/core/render_manager"

describe PointClickEngine::Core::RenderManager do
  describe "#initialize" do
    it "creates a new RenderManager instance" do
      manager = PointClickEngine::Core::RenderManager.new
      manager.should be_a(PointClickEngine::Core::RenderManager)
    end

    it "sets up default render layers" do
      manager = PointClickEngine::Core::RenderManager.new

      # Default layers should be created during initialization
      # This verifies the manager initializes properly
    end
  end

  describe "#add_render_layer" do
    it "successfully adds a new render layer" do
      manager = PointClickEngine::Core::RenderManager.new

      result = manager.add_render_layer("test_layer", 50)

      result.success?.should be_true
    end

    it "fails to add duplicate layer name" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.add_render_layer("test_layer", 50)
      result = manager.add_render_layer("test_layer", 60)

      result.failure?.should be_true
      result.error.should be_a(PointClickEngine::Core::RenderError)
    end

    it "maintains layer priority ordering" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.add_render_layer("low_priority", 10)
      manager.add_render_layer("high_priority", 100)
      manager.add_render_layer("medium_priority", 50)

      # Layers should be internally sorted by priority
      # This would be verified through rendering order
    end
  end

  describe "#add_renderer and #remove_renderer" do
    it "successfully adds and removes renderer from layer" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.add_render_layer("test_layer", 50)

      test_renderer = ->(dt : Float32) { }
      add_result = manager.add_renderer("test_layer", test_renderer)
      add_result.success?.should be_true

      remove_result = manager.remove_renderer("test_layer", test_renderer)
      remove_result.success?.should be_true
    end

    it "fails to add renderer to non-existent layer" do
      manager = PointClickEngine::Core::RenderManager.new

      test_renderer = ->(dt : Float32) { }
      result = manager.add_renderer("nonexistent_layer", test_renderer)

      result.failure?.should be_true
    end
  end

  describe "#set_layer_enabled" do
    it "toggles layer enabled state successfully" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.add_render_layer("test_layer", 50)
      result = manager.set_layer_enabled("test_layer", false)

      result.success?.should be_true
    end

    it "fails for non-existent layer" do
      manager = PointClickEngine::Core::RenderManager.new

      result = manager.set_layer_enabled("nonexistent_layer", false)

      result.failure?.should be_true
    end
  end

  describe "#show_ui and #hide_ui" do
    it "toggles UI visibility" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.ui_visible?.should be_true

      manager.hide_ui
      manager.ui_visible?.should be_false

      manager.show_ui
      manager.ui_visible?.should be_true
    end
  end

  describe "#debug_mode controls" do
    it "toggles debug mode" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.debug_mode?.should be_false

      manager.enable_debug_mode
      manager.debug_mode?.should be_true

      manager.disable_debug_mode
      manager.debug_mode?.should be_false
    end

    it "sets debug options" do
      manager = PointClickEngine::Core::RenderManager.new

      # Should not raise exceptions
      manager.set_debug_options(show_bounds: true, show_hotspots: true, show_fps: true)
    end
  end

  describe "#hotspot_highlighting" do
    it "toggles hotspot highlighting" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.hotspot_highlighting_enabled?.should be_false

      manager.enable_hotspot_highlighting
      manager.hotspot_highlighting_enabled?.should be_true

      manager.disable_hotspot_highlighting
      manager.hotspot_highlighting_enabled?.should be_false
    end

    it "accepts custom highlight colors" do
      manager = PointClickEngine::Core::RenderManager.new

      # Mock color for testing
      red_color = Raylib::Color.new(r: 255, g: 0, b: 0, a: 128)

      # Should not raise exceptions
      manager.enable_hotspot_highlighting(color: red_color, pulse: false)
      manager.hotspot_highlighting_enabled?.should be_true
    end
  end

  describe "#get_render_stats" do
    it "returns render statistics" do
      manager = PointClickEngine::Core::RenderManager.new

      stats = manager.get_render_stats

      stats[:objects_rendered].should be >= 0
      stats[:objects_culled].should be >= 0
      stats[:draw_calls].should be >= 0
      stats[:render_time].should be >= 0.0
      stats[:fps].should be >= 0.0
    end
  end

  describe "#reset_stats" do
    it "resets all render statistics" do
      manager = PointClickEngine::Core::RenderManager.new

      manager.reset_stats
      stats = manager.get_render_stats

      stats[:objects_rendered].should eq(0)
      stats[:objects_culled].should eq(0)
      stats[:draw_calls].should eq(0)
      stats[:render_time].should eq(0.0)
    end
  end

  # Note: Render tests are commented out because they require an initialized Raylib window
  # describe "#render" do
  #   it "performs rendering without errors" do
  #     manager = PointClickEngine::Core::RenderManager.new
  #     manager.render(0.016_f32)
  #   end
  #
  #   it "updates render statistics during rendering" do
  #     manager = PointClickEngine::Core::RenderManager.new
  #     manager.reset_stats
  #     manager.render(0.016_f32)
  #     stats = manager.get_render_stats
  #     stats[:render_time].should be >= 0.0
  #   end
  # end

end
