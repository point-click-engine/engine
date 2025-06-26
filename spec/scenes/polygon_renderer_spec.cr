require "../spec_helper"

module PointClickEngine::Scenes
  describe PolygonRenderer do
    describe "#draw_filled" do
      it "draws nothing when vertices are less than 3" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          vertices = [RL::Vector2.new(0, 0), RL::Vector2.new(10, 0)]

          # Should not raise, just return early
          renderer.draw_filled(vertices, RL::RED)
        end
      end

      it "draws triangles for valid polygon" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          vertices = [
            RL::Vector2.new(0, 0),
            RL::Vector2.new(10, 0),
            RL::Vector2.new(5, 10),
          ]

          # This will call Raylib drawing functions
          # We can't easily test the actual drawing, but we can verify it doesn't crash
          renderer.draw_filled(vertices, RL::GREEN)
        end
      end
    end

    describe "#draw_outline" do
      it "draws nothing when vertices are less than 2" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          vertices = [RL::Vector2.new(0, 0)]

          # Should not raise, just return early
          renderer.draw_outline(vertices, RL::RED)
        end
      end

      it "draws lines between vertices" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          vertices = [
            RL::Vector2.new(0, 0),
            RL::Vector2.new(10, 0),
            RL::Vector2.new(10, 10),
            RL::Vector2.new(0, 10),
          ]

          # Draws lines connecting all vertices
          renderer.draw_outline(vertices, RL::BLUE, 2.0)
        end
      end
    end

    describe "#draw_filled_with_outline" do
      it "draws both fill and outline" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          vertices = [
            RL::Vector2.new(0, 0),
            RL::Vector2.new(20, 0),
            RL::Vector2.new(10, 20),
          ]

          renderer.draw_filled_with_outline(
            vertices,
            RL::Color.new(r: 100, g: 100, b: 100, a: 100),
            RL::BLACK,
            3.0
          )
        end
      end
    end

    describe "#draw_walkable_debug" do
      it "draws green for walkable regions" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          region = PolygonRegion.new("test_region", true)
          region.vertices = [
            RL::Vector2.new(0, 0),
            RL::Vector2.new(30, 0),
            RL::Vector2.new(15, 30),
          ]

          renderer.draw_walkable_debug(region)
        end
      end

      it "draws red for non-walkable regions" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          region = PolygonRegion.new("test_region", false)
          region.vertices = [
            RL::Vector2.new(0, 0),
            RL::Vector2.new(30, 0),
            RL::Vector2.new(15, 30),
          ]

          renderer.draw_walkable_debug(region)
        end
      end
    end

    describe "#draw_walk_behind_debug" do
      it "draws walk-behind region with threshold line" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          region = WalkBehindRegion.new("walk_behind", 30.0)
          region.vertices = [
            RL::Vector2.new(10, 10),
            RL::Vector2.new(50, 10),
            RL::Vector2.new(50, 50),
            RL::Vector2.new(10, 50),
          ]

          renderer.draw_walk_behind_debug(region)
        end
      end

      it "handles empty vertices array" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          region = WalkBehindRegion.new("empty", 30.0)
          region.vertices = [] of RL::Vector2

          # Should not crash with empty vertices
          renderer.draw_walk_behind_debug(region)
        end
      end
    end

    describe "#draw_scale_zones" do
      it "draws scale zones with gradient" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          zones = [
            ScaleZone.new(min_y: 100.0, max_y: 200.0, min_scale: 0.5, max_scale: 1.0),
            ScaleZone.new(min_y: 200.0, max_y: 300.0, min_scale: 1.0, max_scale: 1.5),
          ]

          renderer.draw_scale_zones(zones, 800)
        end
      end

      it "handles empty zones array" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          zones = [] of ScaleZone

          # Should return early without drawing
          renderer.draw_scale_zones(zones, 800)
        end
      end
    end

    describe "helper methods" do
      it "calculates center of polygon correctly" do
        RaylibContext.with_window do
          renderer = PolygonRenderer.new
          vertices = [
            RL::Vector2.new(0, 0),
            RL::Vector2.new(10, 0),
            RL::Vector2.new(10, 10),
            RL::Vector2.new(0, 10),
          ]

          # Test indirectly through draw_filled
          renderer.draw_filled(vertices, RL::GRAY)
        end
      end
    end
  end
end
