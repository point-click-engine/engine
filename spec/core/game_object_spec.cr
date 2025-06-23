require "../spec_helper"

module PointClickEngine
  describe Core::GameObject do
    describe "#initialize" do
      it "creates a game object with position and size" do
        obj = TestGameObject.new(
          Raylib::Vector2.new(x: 10f32, y: 20f32),
          Raylib::Vector2.new(x: 30f32, y: 40f32)
        )

        obj.position.x.should eq(10f32)
        obj.position.y.should eq(20f32)
        obj.size.x.should eq(30f32)
        obj.size.y.should eq(40f32)
        obj.visible.should be_true # Drawable defaults to visible=true
      end
    end

    describe "#bounds" do
      it "returns the bounding rectangle" do
        obj = TestGameObject.new(
          Raylib::Vector2.new(x: 100f32, y: 200f32),
          Raylib::Vector2.new(x: 50f32, y: 75f32)
        )

        bounds = obj.bounds
        # Bounds are centered on position
        bounds.x.should eq(75f32)    # 100 - 50/2
        bounds.y.should eq(162.5f32) # 200 - 75/2
        bounds.width.should eq(50f32)
        bounds.height.should eq(75f32)
      end
    end

    describe "#visible" do
      it "can be toggled" do
        obj = TestGameObject.new(
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 10f32, y: 10f32)
        )

        obj.visible.should be_true
        obj.visible = false
        obj.visible.should be_false
      end
    end
  end
end
