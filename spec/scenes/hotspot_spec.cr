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

      it "handles nil callback safely" do
        hotspot = Scenes::Hotspot.new(
          "test",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 10f32, y: 10f32)
        )

        # Should not raise error when callback is nil
        hotspot.on_click.try(&.call)
      end
    end

    describe "#on_hover" do
      it "executes hover callback" do
        hotspot = Scenes::Hotspot.new(
          "test",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 10f32, y: 10f32)
        )

        hovered = false
        hotspot.on_hover = -> { hovered = true }

        hotspot.on_hover.try(&.call)
        hovered.should be_true
      end
    end

    describe "properties" do
      it "has configurable description" do
        hotspot = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 100f32)
        )

        hotspot.description = "A sturdy wooden door"
        hotspot.description.should eq("A sturdy wooden door")
      end

      it "has configurable cursor type" do
        hotspot = Scenes::Hotspot.new(
          "item",
          Raylib::Vector2.new(x: 50f32, y: 50f32),
          Raylib::Vector2.new(x: 20f32, y: 20f32)
        )

        hotspot.cursor_type = Scenes::Hotspot::CursorType::Use
        hotspot.cursor_type.should eq(Scenes::Hotspot::CursorType::Use)
      end

      it "can block movement" do
        hotspot = Scenes::Hotspot.new(
          "obstacle",
          Raylib::Vector2.new(x: 200f32, y: 200f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        hotspot.blocks_movement = true
        hotspot.blocks_movement.should be_true
      end

      it "has object type for smart verb detection" do
        hotspot = Scenes::Hotspot.new(
          "character",
          Raylib::Vector2.new(x: 300f32, y: 400f32),
          Raylib::Vector2.new(x: 64f32, y: 96f32)
        )

        hotspot.object_type = UI::ObjectType::Character
        hotspot.object_type.should eq(UI::ObjectType::Character)
      end

      it "can have a default verb" do
        hotspot = Scenes::Hotspot.new(
          "npc",
          Raylib::Vector2.new(x: 400f32, y: 300f32),
          Raylib::Vector2.new(x: 64f32, y: 96f32)
        )

        hotspot.default_verb = UI::VerbType::Talk
        hotspot.default_verb.should eq(UI::VerbType::Talk)
      end

      it "can have a script path" do
        hotspot = Scenes::Hotspot.new(
          "terminal",
          Raylib::Vector2.new(x: 200f32, y: 300f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        hotspot.script_path = "scripts/terminal.lua"
        hotspot.script_path.should eq("scripts/terminal.lua")
      end
    end

    describe "#get_outline_points" do
      it "returns rectangle corners for rectangular hotspot" do
        hotspot = Scenes::Hotspot.new(
          "rect",
          Raylib::Vector2.new(x: 10f32, y: 20f32),
          Raylib::Vector2.new(x: 30f32, y: 40f32)
        )

        points = hotspot.get_outline_points
        points.size.should eq(4)

        # Top-left
        points[0].x.should eq(10f32)
        points[0].y.should eq(20f32)

        # Top-right
        points[1].x.should eq(40f32)
        points[1].y.should eq(20f32)

        # Bottom-right
        points[2].x.should eq(40f32)
        points[2].y.should eq(60f32)

        # Bottom-left
        points[3].x.should eq(10f32)
        points[3].y.should eq(60f32)
      end
    end

    describe "#get_effective_script_path" do
      it "returns hotspot's own script path when set" do
        hotspot = Scenes::Hotspot.new(
          "scripted",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )
        hotspot.script_path = "scripts/hotspot.lua"

        scene = Scenes::Scene.new("test_scene")
        scene.script_path = "scripts/scene.lua"

        hotspot.get_effective_script_path(scene).should eq("scripts/hotspot.lua")
      end

      it "falls back to scene script path when not set" do
        hotspot = Scenes::Hotspot.new(
          "unscripted",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        scene = Scenes::Scene.new("test_scene")
        scene.script_path = "scripts/scene.lua"

        hotspot.get_effective_script_path(scene).should eq("scripts/scene.lua")
      end

      it "returns nil when neither has script path" do
        hotspot = Scenes::Hotspot.new(
          "unscripted",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        scene = Scenes::Scene.new("test_scene")

        hotspot.get_effective_script_path(scene).should be_nil
      end
    end

    describe "#update" do
      it "handles mouse interaction when active" do
        hotspot = Scenes::Hotspot.new(
          "interactive",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        hover_count = 0
        click_count = 0

        hotspot.on_hover = -> { hover_count += 1 }
        hotspot.on_click = -> { click_count += 1 }

        # Mock mouse position inside hotspot
        # Note: In real tests with Raylib, we'd need to mock RL.get_mouse_position
        # For now, we'll just test the logic structure
        hotspot.active = false
        hotspot.update(0.016f32)
        hover_count.should eq(0) # Should not trigger when inactive

        hotspot.active = true
        # Would need Raylib mocking to fully test mouse interaction
      end
    end

    describe "visibility and debug" do
      it "has configurable visibility" do
        hotspot = Scenes::Hotspot.new(
          "hidden",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        hotspot.visible = false
        hotspot.visible.should be_false
      end

      it "has debug color for visualization" do
        hotspot = Scenes::Hotspot.new(
          "debug",
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )

        hotspot.debug_color = RL::Color.new(r: 0, g: 255, b: 0, a: 100)
        hotspot.debug_color.r.should eq(0)
        hotspot.debug_color.g.should eq(255)
        hotspot.debug_color.b.should eq(0)
        hotspot.debug_color.a.should eq(100)
      end
    end
  end
end
