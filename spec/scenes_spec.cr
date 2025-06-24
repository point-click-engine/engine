require "./spec_helper"

# Test character for scene testing
class TestCharacter < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character); end

  def on_look; end

  def on_talk; end
end

describe PointClickEngine::Scenes do
  describe PointClickEngine::Scenes::Hotspot do
    it "initializes with name, position and size" do
      hotspot = PointClickEngine::Scenes::Hotspot.new("door", vec2(100, 200), vec2(50, 100))
      hotspot.name.should eq("door")
      hotspot.position.x.should eq(100)
      hotspot.position.y.should eq(200)
      hotspot.size.x.should eq(50)
      hotspot.size.y.should eq(100)
    end

    it "has default cursor type of Hand" do
      hotspot = PointClickEngine::Scenes::Hotspot.new("test", vec2(0, 0), vec2(10, 10))
      hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Hand)
    end

    it "can set different cursor types" do
      hotspot = PointClickEngine::Scenes::Hotspot.new("test", vec2(0, 0), vec2(10, 10))

      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Look
      hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Look)

      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Talk
      hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Talk)

      hotspot.cursor_type = PointClickEngine::Scenes::Hotspot::CursorType::Use
      hotspot.cursor_type.should eq(PointClickEngine::Scenes::Hotspot::CursorType::Use)
    end

    it "can assign callback functions" do
      hotspot = PointClickEngine::Scenes::Hotspot.new("button", vec2(10, 10), vec2(20, 20))

      click_triggered = false
      hover_triggered = false

      hotspot.on_click = -> { click_triggered = true }
      hotspot.on_hover = -> { hover_triggered = true }

      hotspot.on_click.should_not be_nil
      hotspot.on_hover.should_not be_nil

      # Test callbacks work
      hotspot.on_click.try &.call
      hotspot.on_hover.try &.call

      click_triggered.should be_true
      hover_triggered.should be_true
    end

    it "has configurable debug color" do
      hotspot = PointClickEngine::Scenes::Hotspot.new("test", vec2(0, 0), vec2(10, 10))

      blue_debug = RL::Color.new(r: 0, g: 0, b: 255, a: 100)
      hotspot.debug_color = blue_debug
      hotspot.debug_color.should eq(blue_debug)
    end

    it "starts active and visible" do
      hotspot = PointClickEngine::Scenes::Hotspot.new("test", vec2(0, 0), vec2(10, 10))
      hotspot.active.should be_true
      hotspot.visible.should be_true
    end
  end

  describe PointClickEngine::Scenes::Scene do
    it "initializes with a name" do
      scene = PointClickEngine::Scenes::Scene.new("main_room")
      scene.name.should eq("main_room")
    end

    it "starts with empty collections" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.hotspots.should be_empty
      scene.objects.should be_empty
      scene.characters.should be_empty
    end

    it "has no player initially" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.player.should be_nil
    end

    it "has default scale of 1.0" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.scale.should eq(1.0_f32)
    end

    it "can set custom scale" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      scene.scale = 2.5_f32
      scene.scale.should eq(2.5_f32)
    end

    it "can add hotspots" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      hotspot = PointClickEngine::Scenes::Hotspot.new("door", vec2(0, 0), vec2(10, 10))

      scene.add_hotspot(hotspot)

      scene.hotspots.size.should eq(1)
      scene.objects.size.should eq(1) # Should also be added to objects
      scene.hotspots.first.should eq(hotspot)
    end

    it "can add generic objects" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      obj = TestGameObject.new(vec2(0, 0), vec2(10, 10))

      scene.add_object(obj)

      scene.objects.size.should eq(1)
      scene.objects.first.should eq(obj)
    end

    it "can add characters" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      char = TestCharacter.new("Hero", vec2(100, 100), vec2(32, 48))
      scene.add_character(char)

      scene.characters.size.should eq(1)
      scene.objects.size.should eq(1) # Should also be added to objects
      scene.characters.first.should eq(char)
    end

    it "can set a player" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      player = PointClickEngine::Characters::Player.new("Hero", vec2(0, 0), vec2(32, 48))

      scene.set_player(player)

      scene.player.should eq(player)
      scene.player_name_for_serialization.should eq("Hero")
      scene.characters.should contain(player)
    end

    it "can find hotspot at point" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      hotspot1 = PointClickEngine::Scenes::Hotspot.new("h1", vec2(0, 0), vec2(20, 20))
      hotspot2 = PointClickEngine::Scenes::Hotspot.new("h2", vec2(30, 30), vec2(20, 20))

      scene.add_hotspot(hotspot1)
      scene.add_hotspot(hotspot2)

      # Test finding hotspots
      scene.get_hotspot_at(vec2(10, 10)).should eq(hotspot1)
      scene.get_hotspot_at(vec2(40, 40)).should eq(hotspot2)
      scene.get_hotspot_at(vec2(100, 100)).should be_nil
    end

    it "ignores inactive hotspots when searching" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      hotspot = PointClickEngine::Scenes::Hotspot.new("test", vec2(0, 0), vec2(20, 20))
      scene.add_hotspot(hotspot)

      # Should find active hotspot
      scene.get_hotspot_at(vec2(10, 10)).should eq(hotspot)

      # Should not find inactive hotspot
      hotspot.active = false
      scene.get_hotspot_at(vec2(10, 10)).should be_nil
    end

    it "can find character by name" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      char1 = TestCharacter.new("Hero", vec2(0, 0), vec2(32, 48))
      char2 = TestCharacter.new("Guard", vec2(100, 100), vec2(32, 48))

      scene.add_character(char1)
      scene.add_character(char2)

      scene.get_character("Hero").should eq(char1)
      scene.get_character("Guard").should eq(char2)
      scene.get_character("Nobody").should be_nil
    end

    it "can find character at point" do
      scene = PointClickEngine::Scenes::Scene.new("test")
      player = PointClickEngine::Characters::Player.new("Hero", vec2(0, 0), vec2(32, 48))
      npc = TestCharacter.new("Guard", vec2(100, 100), vec2(32, 48))

      scene.set_player(player)
      scene.add_character(npc)

      # Should find NPC but not player (player excluded from search)
      # Character at (100,100) with size (32,48) has bounds:
      # x: 84-116, y: 52-100
      scene.get_character_at(vec2(100, 80)).should eq(npc) # Within bounds
      scene.get_character_at(vec2(10, 10)).should be_nil   # Player excluded
      scene.get_character_at(vec2(200, 200)).should be_nil # No character there
    end

    it "has configurable enter/exit callbacks" do
      scene = PointClickEngine::Scenes::Scene.new("test")

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
end
