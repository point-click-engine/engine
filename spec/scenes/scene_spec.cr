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

      it "initializes with default transition duration of 1.0" do
        scene = Scenes::Scene.new("test_scene")
        scene.default_transition_duration.should eq(1.0f32)
      end
    end

    describe "#default_transition_duration" do
      it "can be set to a custom value" do
        scene = Scenes::Scene.new("test_scene")
        scene.default_transition_duration = 4.5f32
        scene.default_transition_duration.should eq(4.5f32)
      end

      it "is preserved through YAML serialization" do
        scene = Scenes::Scene.new("test_scene")
        scene.default_transition_duration = 3.0f32

        yaml = scene.to_yaml
        loaded_scene = Scenes::Scene.from_yaml(yaml)

        loaded_scene.default_transition_duration.should eq(3.0f32)
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

      it "adds hotspot to both hotspots and objects arrays" do
        scene = Scenes::Scene.new("test")
        hotspot = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )

        scene.add_hotspot(hotspot)
        scene.hotspots.includes?(hotspot).should be_true
        scene.objects.includes?(hotspot).should be_true
      end

      it "prevents duplicate hotspots" do
        scene = Scenes::Scene.new("test")
        hotspot = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )

        scene.add_hotspot(hotspot)
        scene.add_hotspot(hotspot) # Add same hotspot again

        scene.hotspots.size.should eq(1)
        scene.objects.size.should eq(1)
      end
    end

    describe "#remove_hotspot" do
      it "removes a hotspot by name" do
        scene = Scenes::Scene.new("test")
        hotspot1 = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )
        hotspot2 = Scenes::Hotspot.new(
          "window",
          Raylib::Vector2.new(x: 200f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )

        scene.add_hotspot(hotspot1)
        scene.add_hotspot(hotspot2)

        result = scene.remove_hotspot("door")
        result.should be_true

        scene.hotspots.size.should eq(1)
        scene.hotspots.includes?(hotspot1).should be_false
        scene.hotspots.includes?(hotspot2).should be_true
        scene.objects.includes?(hotspot1).should be_false
      end

      it "returns false when hotspot name not found" do
        scene = Scenes::Scene.new("test")
        result = scene.remove_hotspot("nonexistent")
        result.should be_false
      end

      it "removes a hotspot by object reference" do
        scene = Scenes::Scene.new("test")
        hotspot1 = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )
        hotspot2 = Scenes::Hotspot.new(
          "window",
          Raylib::Vector2.new(x: 200f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )

        scene.add_hotspot(hotspot1)
        scene.add_hotspot(hotspot2)

        result = scene.remove_hotspot(hotspot1)
        result.should be_true

        scene.hotspots.size.should eq(1)
        scene.hotspots.includes?(hotspot1).should be_false
        scene.hotspots.includes?(hotspot2).should be_true
        scene.objects.includes?(hotspot1).should be_false
      end

      it "returns false when hotspot object not found" do
        scene = Scenes::Scene.new("test")
        hotspot = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )

        result = scene.remove_hotspot(hotspot)
        result.should be_false
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

    describe "#get_hotspot_at" do
      it "returns hotspot at given position" do
        scene = Scenes::Scene.new("test")
        hotspot = Scenes::Hotspot.new(
          "door",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )
        scene.add_hotspot(hotspot)

        # Point inside hotspot
        found = scene.get_hotspot_at(Raylib::Vector2.new(x: 125f32, y: 125f32))
        found.should eq(hotspot)

        # Point outside hotspot
        not_found = scene.get_hotspot_at(Raylib::Vector2.new(x: 200f32, y: 200f32))
        not_found.should be_nil
      end

      it "returns front-most hotspot when multiple overlap" do
        scene = Scenes::Scene.new("test")
        back_hotspot = Scenes::Hotspot.new(
          "back",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 100f32, y: 100f32)
        )
        front_hotspot = Scenes::Hotspot.new(
          "front",
          Raylib::Vector2.new(x: 125f32, y: 125f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )

        scene.add_hotspot(back_hotspot)
        scene.add_hotspot(front_hotspot)

        # Point in overlapping area
        found = scene.get_hotspot_at(Raylib::Vector2.new(x: 140f32, y: 140f32))
        found.should eq(front_hotspot) # Should return the one added last (front-most)
      end

      it "only returns visible hotspots" do
        scene = Scenes::Scene.new("test")
        hotspot = Scenes::Hotspot.new(
          "hidden",
          Raylib::Vector2.new(x: 100f32, y: 100f32),
          Raylib::Vector2.new(x: 50f32, y: 50f32)
        )
        hotspot.visible = false
        scene.add_hotspot(hotspot)

        found = scene.get_hotspot_at(Raylib::Vector2.new(x: 125f32, y: 125f32))
        found.should be_nil
      end
    end

    describe "#add_character" do
      it "adds character to both characters and objects arrays" do
        scene = Scenes::Scene.new("test")
        character = TestCharacter.new(
          "npc",
          Raylib::Vector2.new(x: 200f32, y: 200f32),
          Raylib::Vector2.new(x: 64f32, y: 96f32)
        )

        scene.add_character(character)
        scene.characters.includes?(character).should be_true
        scene.objects.includes?(character).should be_true
      end

      it "prevents duplicate characters" do
        scene = Scenes::Scene.new("test")
        character = TestCharacter.new(
          "npc",
          Raylib::Vector2.new(x: 200f32, y: 200f32),
          Raylib::Vector2.new(x: 64f32, y: 96f32)
        )

        scene.add_character(character)
        scene.add_character(character) # Add same character again

        scene.characters.size.should eq(1)
        scene.objects.select { |o| o == character }.size.should eq(1)
      end
    end

    describe "#set_player" do
      it "sets the player and adds to scene if not present" do
        scene = Scenes::Scene.new("test")
        player = TestCharacter.new(
          "player",
          Raylib::Vector2.new(x: 400f32, y: 300f32),
          Raylib::Vector2.new(x: 56f32, y: 56f32)
        )

        scene.set_player(player)
        scene.player.should eq(player)
        scene.characters.includes?(player).should be_true
      end
    end

    describe "#get_character_at" do
      it "returns character at given position" do
        scene = Scenes::Scene.new("test")
        character = TestCharacter.new(
          "npc",
          Raylib::Vector2.new(x: 200f32, y: 200f32),
          Raylib::Vector2.new(x: 64f32, y: 96f32)
        )
        scene.add_character(character)

        # Point inside character bounds
        # Character at (200, 200) with size (64, 96) has bounds from (168, 104) to (232, 200)
        found = scene.get_character_at(Raylib::Vector2.new(x: 200f32, y: 150f32))
        found.should eq(character)

        # Point outside character bounds
        not_found = scene.get_character_at(Raylib::Vector2.new(x: 400f32, y: 400f32))
        not_found.should be_nil
      end

      it "excludes the player from results" do
        scene = Scenes::Scene.new("test")
        player = TestCharacter.new(
          "player",
          Raylib::Vector2.new(x: 200f32, y: 200f32),
          Raylib::Vector2.new(x: 64f32, y: 96f32)
        )
        scene.set_player(player)

        # Point inside player bounds
        # Player at (200, 200) with size (64, 96) has bounds from (168, 104) to (232, 200)
        found = scene.get_character_at(Raylib::Vector2.new(x: 200f32, y: 150f32))
        found.should be_nil # Player should be excluded
      end
    end

    describe "update and draw" do
      it "updates all objects when active" do
        scene = Scenes::Scene.new("test")
        object = TestGameObject.new(
          Raylib::Vector2.new(x: 0f32, y: 0f32),
          Raylib::Vector2.new(x: 32f32, y: 32f32)
        )
        scene.add_object(object)

        scene.update(0.016f32)
        object.update_called.should be_true
      end

      # TODO: Re-enable when Scene has active property
      # it "skips update when inactive" do
      #   scene = Scenes::Scene.new("test")
      #   object = TestGameObject.new(
      #     Raylib::Vector2.new(x: 0f32, y: 0f32),
      #     Raylib::Vector2.new(x: 32f32, y: 32f32)
      #   )
      #   scene.add_object(object)
      #   scene.active = false

      #   scene.update(0.016f32)
      #   object.update_called.should be_false
      # end
    end

    describe "properties" do
      it "has configurable background scale" do
        scene = Scenes::Scene.new("test")
        scene.scale = 2.0f32
        scene.scale.should eq(2.0f32)
      end

      it "has configurable navigation settings" do
        scene = Scenes::Scene.new("test")
        scene.enable_pathfinding = true
        scene.navigation_cell_size = 32

        scene.enable_pathfinding.should be_true
        scene.navigation_cell_size.should eq(32)
      end

      it "has configurable camera scrolling" do
        scene = Scenes::Scene.new("test")
        scene.enable_camera_scrolling = true
        scene.enable_camera_scrolling.should be_true
      end
    end
  end

  # Test helper classes
  class TestGameObject < Core::GameObject
    property update_called = false
    property draw_called = false

    def update(dt : Float32)
      @update_called = true
    end

    def draw
      @draw_called = true
    end
  end

  class TestCharacter < Characters::Character
    def on_interact(interactor : Character)
      # Test implementation
    end

    def on_look
      # Test implementation
    end

    def on_talk
      # Test implementation
    end
  end
end
