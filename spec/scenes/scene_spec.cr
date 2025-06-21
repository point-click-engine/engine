require "../spec_helper"

module PointClickEngine
  describe Scenes::Scene do
    describe "#initialize" do
      it "creates a scene with a name" do
        scene = Scenes::Scene.new("test_scene")
        scene.name.should eq("test_scene")
        scene.objects.should be_empty
        scene.hotspots.should be_empty
        scene.characters.should be_empty
      end
    end

    describe "#add_hotspot" do
      it "adds a hotspot to the scene" do
        scene = Scenes::Scene.new("test")
        hotspot = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )

        scene.add_hotspot(hotspot)
        scene.hotspots.size.should eq(1)
        scene.hotspots.first.should eq(hotspot)
      end
    end

    describe "#add_object" do
      it "adds a game object to the scene" do
        scene = Scenes::Scene.new("test")
        object = TestGameObject.new(
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 32f32, y: 32f32)
        )

        scene.add_object(object)
        scene.objects.size.should eq(1)
        scene.objects.first.should eq(object)
      end
    end

    describe "#enter and #exit" do
      it "calls enter and exit callbacks" do
        scene = Scenes::Scene.new("test")
        entered = false
        exited = false

        scene.on_enter = -> { entered = true }
        scene.on_exit = -> { exited = true }

        scene.enter
        entered.should be_true

        scene.exit
        exited.should be_true
      end
    end

    describe "#script_path" do
      it "sets the script path" do
        scene = Scenes::Scene.new("test")
        scene.script_path = "scripts/test.lua"
        scene.script_path.should eq("scripts/test.lua")
      end
    end
  end
end
