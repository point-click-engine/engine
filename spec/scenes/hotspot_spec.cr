require "../spec_helper"

module PointClickEngine
  describe Scenes::Hotspot do
    describe "#initialize" do
      it "creates a hotspot with position and size" do
        hotspot = Scenes::Hotspot.new(
          "test_hotspot",
          Raylib::Vector2.new(x: 100f32, y: 200f32),
          Raylib::Vector2.new(x: 50f32, y: 75f32)
        )

        hotspot.name.should eq("test_hotspot")
        hotspot.position.x.should eq(100f32)
        hotspot.position.y.should eq(200f32)
        hotspot.size.x.should eq(50f32)
        hotspot.size.y.should eq(75f32)
        hotspot.visible.should be_true
      end
    end

    describe "#bounds" do
      it "returns the correct bounding rectangle" do
        hotspot = Scenes::Hotspot.new(
          "test",
          Raylib::Vector2.new(x: 10f32, y: 20f32),
          Raylib::Vector2.new(x: 30f32, y: 40f32)
        )

        # Hotspot position and size
        hotspot.position.x.should eq(10f32)
        hotspot.position.y.should eq(20f32)
        hotspot.size.x.should eq(30f32)
        hotspot.size.y.should eq(40f32)
      end
    end

    describe "#contains_point?" do
      it "returns true when point is inside" do
        # Hotspot at center (50,50) with size 100x100
        # This creates bounds from (0,0) to (100,100)
        hotspot = Scenes::Hotspot.new(
          "test",
          Raylib::Vector2.new(x: 50f32, y: 50f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        hotspot.contains_point?(Raylib::Vector2.new(x: 50f32, y: 50f32)).should be_true
        hotspot.contains_point?(Raylib::Vector2.new(x: 0f32, y: 0f32)).should be_true
        hotspot.contains_point?(Raylib::Vector2.new(x: 99f32, y: 99f32)).should be_true
      end

      it "returns false when point is outside" do
        # Hotspot at center (50,50) with size 100x100
        # This creates bounds from (0,0) to (100,100)
        hotspot = Scenes::Hotspot.new(
          "test",
          Raylib::Vector2.new(x: 50f32, y: 50f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        hotspot.contains_point?(Raylib::Vector2.new(x: -1f32, y: 50f32)).should be_false
        hotspot.contains_point?(Raylib::Vector2.new(x: 101f32, y: 50f32)).should be_false
        hotspot.contains_point?(Raylib::Vector2.new(x: 50f32, y: 101f32)).should be_false
      end
    end

    describe "#on_click" do
      it "executes click callback" do
        hotspot = Scenes::Hotspot.new(
          "test",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 10f32, y: 10f32)
        )

        clicked = false
        hotspot.on_click = -> { clicked = true }

        hotspot.on_click.try(&.call)
        clicked.should be_true
      end
    end
  end
end
