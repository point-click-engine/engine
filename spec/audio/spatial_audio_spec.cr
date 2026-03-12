require "../spec_helper"
require "../../src/audio/spatial_audio"

module PointClickEngine::Audio
  describe SpatialAudio do
    describe ".calculate_distance" do
      it "calculates distance between two points" do
        pos1 = RL::Vector2.new(x: 0.0f32, y: 0.0f32)
        pos2 = RL::Vector2.new(x: 3.0f32, y: 4.0f32)

        distance = SpatialAudio.calculate_distance(pos1, pos2)
        distance.should eq(5.0f32)
      end

      it "returns 0 for same position" do
        pos = RL::Vector2.new(x: 100.0f32, y: 200.0f32)

        distance = SpatialAudio.calculate_distance(pos, pos)
        distance.should eq(0.0f32)
      end

      it "handles negative coordinates" do
        pos1 = RL::Vector2.new(x: -10.0f32, y: -10.0f32)
        pos2 = RL::Vector2.new(x: 10.0f32, y: 10.0f32)

        # Distance should be sqrt(20^2 + 20^2) = sqrt(800) ≈ 28.28
        distance = SpatialAudio.calculate_distance(pos1, pos2)
        distance.should be_close(28.28f32, 0.01)
      end
    end

    describe ".calculate_volume_factor" do
      it "returns 1.0 at listener position" do
        pos = RL::Vector2.new(x: 100.0f32, y: 100.0f32)

        volume = SpatialAudio.calculate_volume_factor(pos, pos, 500.0f32)
        volume.should eq(1.0f32)
      end

      it "returns 0.0 at max distance" do
        source = RL::Vector2.new(x: 0.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 500.0f32, y: 0.0f32)

        volume = SpatialAudio.calculate_volume_factor(source, listener, 500.0f32)
        volume.should eq(0.0f32)
      end

      it "returns 0.0 beyond max distance" do
        source = RL::Vector2.new(x: 0.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 600.0f32, y: 0.0f32)

        volume = SpatialAudio.calculate_volume_factor(source, listener, 500.0f32)
        volume.should eq(0.0f32)
      end

      it "returns 0.5 at half max distance with linear falloff" do
        source = RL::Vector2.new(x: 0.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 250.0f32, y: 0.0f32)

        volume = SpatialAudio.calculate_volume_factor(source, listener, 500.0f32, 1.0f32)
        volume.should eq(0.5f32)
      end

      it "applies non-linear falloff" do
        source = RL::Vector2.new(x: 0.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 250.0f32, y: 0.0f32)

        # With falloff of 2.0, volume = (0.5)^2 = 0.25
        volume = SpatialAudio.calculate_volume_factor(source, listener, 500.0f32, 2.0f32)
        volume.should eq(0.25f32)
      end

      it "clamps to valid range" do
        source = RL::Vector2.new(x: 0.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        volume = SpatialAudio.calculate_volume_factor(source, listener, 500.0f32)
        volume.should be >= 0.0f32
        volume.should be <= 1.0f32
      end
    end

    describe ".calculate_pan" do
      it "returns 0.0 when source is directly at listener" do
        pos = RL::Vector2.new(x: 100.0f32, y: 100.0f32)

        pan = SpatialAudio.calculate_pan(pos, pos)
        pan.should eq(0.0f32)
      end

      it "returns positive pan for source to the right" do
        source = RL::Vector2.new(x: 300.0f32, y: 100.0f32)
        listener = RL::Vector2.new(x: 100.0f32, y: 100.0f32)

        pan = SpatialAudio.calculate_pan(source, listener, 400.0f32)
        pan.should eq(0.5f32)
      end

      it "returns negative pan for source to the left" do
        source = RL::Vector2.new(x: -100.0f32, y: 100.0f32)
        listener = RL::Vector2.new(x: 100.0f32, y: 100.0f32)

        pan = SpatialAudio.calculate_pan(source, listener, 400.0f32)
        pan.should eq(-0.5f32)
      end

      it "clamps to -1.0 for far left" do
        source = RL::Vector2.new(x: -1000.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        pan = SpatialAudio.calculate_pan(source, listener, 400.0f32)
        pan.should eq(-1.0f32)
      end

      it "clamps to 1.0 for far right" do
        source = RL::Vector2.new(x: 1000.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        pan = SpatialAudio.calculate_pan(source, listener, 400.0f32)
        pan.should eq(1.0f32)
      end

      it "ignores vertical position" do
        source = RL::Vector2.new(x: 200.0f32, y: 1000.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        pan = SpatialAudio.calculate_pan(source, listener, 400.0f32)
        pan.should eq(0.5f32)
      end
    end

    describe ".calculate_spatial_params" do
      it "returns both volume and pan" do
        source = RL::Vector2.new(x: 200.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        params = SpatialAudio.calculate_spatial_params(source, listener, 500.0f32, 400.0f32)

        params[:volume].should be_close(0.6f32, 0.01)
        params[:pan].should eq(0.5f32)
      end

      it "uses default values" do
        source = RL::Vector2.new(x: 250.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        params = SpatialAudio.calculate_spatial_params(source, listener)

        # Default max_distance is 500, pan_width is 400
        params[:volume].should eq(0.5f32)
        params[:pan].should be_close(0.625f32, 0.01)
      end
    end

    describe ".in_range?" do
      it "returns true when source is within range" do
        source = RL::Vector2.new(x: 100.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        SpatialAudio.in_range?(source, listener, 500.0f32).should be_true
      end

      it "returns false when source is out of range" do
        source = RL::Vector2.new(x: 600.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        SpatialAudio.in_range?(source, listener, 500.0f32).should be_false
      end

      it "returns false when exactly at max distance" do
        source = RL::Vector2.new(x: 500.0f32, y: 0.0f32)
        listener = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        SpatialAudio.in_range?(source, listener, 500.0f32).should be_false
      end

      it "returns true at same position" do
        pos = RL::Vector2.new(x: 0.0f32, y: 0.0f32)

        SpatialAudio.in_range?(pos, pos, 500.0f32).should be_true
      end
    end
  end
end
