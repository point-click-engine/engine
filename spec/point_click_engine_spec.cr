require "spec"
require "../src/point_click_engine"

# Helper to create test vectors
def vec2(x, y)
  RL::Vector2.new(x: x, y: y)
end

# Helper to create test rectangles
def rect(x, y, w, h)
  RL::Rectangle.new(x: x, y: y, width: w, height: h)
end

# Helper to check point in rectangle (since Raylib function not available in tests)
def point_in_rect?(point : RL::Vector2, rect : RL::Rectangle) : Bool
  point.x >= rect.x &&
  point.x <= rect.x + rect.width &&
  point.y >= rect.y &&
  point.y <= rect.y + rect.height
end

# Test implementation of GameObject
class TestGameObject < PointClickEngine::GameObject
  property update_called = false
  property draw_called = false

  def update(dt : Float32)
    @update_called = true
  end

  def draw
    @draw_called = true
  end
end

describe PointClickEngine do
  describe PointClickEngine::GameObject do
    it "initializes with position and size" do
      obj = TestGameObject.new(vec2(10, 20), vec2(30, 40))
      obj.position.x.should eq(10)
      obj.position.y.should eq(20)
      obj.size.x.should eq(30)
      obj.size.y.should eq(40)
    end

    it "is visible and active by default" do
      obj = TestGameObject.new(vec2(0, 0), vec2(10, 10))
      obj.visible.should be_true
      obj.active.should be_true
    end

    it "calculates bounds correctly" do
      obj = TestGameObject.new(vec2(10, 20), vec2(30, 40))
      bounds = obj.bounds
      bounds.x.should eq(10)
      bounds.y.should eq(20)
      bounds.width.should eq(30)
      bounds.height.should eq(40)
    end

    it "checks point containment" do
      obj = TestGameObject.new(vec2(10, 10), vec2(20, 20))

      # Points inside
      obj.contains_point?(vec2(15, 15)).should be_true
      obj.contains_point?(vec2(10, 10)).should be_true
      obj.contains_point?(vec2(29, 29)).should be_true

      # Points outside
      obj.contains_point?(vec2(5, 15)).should be_false
      obj.contains_point?(vec2(35, 15)).should be_false
      obj.contains_point?(vec2(15, 35)).should be_false
    end
  end

  describe PointClickEngine::Hotspot do
    it "initializes with name, position and size" do
      hotspot = PointClickEngine::Hotspot.new("door", vec2(100, 200), vec2(50, 100))
      hotspot.name.should eq("door")
      hotspot.position.x.should eq(100)
      hotspot.position.y.should eq(200)
      hotspot.size.x.should eq(50)
      hotspot.size.y.should eq(100)
    end

    it "has default cursor type of Hand" do
      hotspot = PointClickEngine::Hotspot.new("test", vec2(0, 0), vec2(10, 10))
      hotspot.cursor_type.should eq(PointClickEngine::Hotspot::CursorType::Hand)
    end

    it "can set cursor type" do
      hotspot = PointClickEngine::Hotspot.new("test", vec2(0, 0), vec2(10, 10))
      hotspot.cursor_type = PointClickEngine::Hotspot::CursorType::Look
      hotspot.cursor_type.should eq(PointClickEngine::Hotspot::CursorType::Look)
    end

    it "triggers callbacks on interaction" do
      hotspot = PointClickEngine::Hotspot.new("button", vec2(10, 10), vec2(20, 20))

      click_triggered = false
      hover_triggered = false

      hotspot.on_click = ->{ click_triggered = true }
      hotspot.on_hover = ->{ hover_triggered = true }

      # Simulate mouse over hotspot
      # Note: In real tests, we'd need to mock RL.get_mouse_position and RL.is_mouse_button_pressed
      # For unit tests, we test the callback mechanism exists

      hotspot.on_click.should_not be_nil
      hotspot.on_hover.should_not be_nil

      # Manually trigger callbacks to test they work
      hotspot.on_click.try &.call
      hotspot.on_hover.try &.call

      click_triggered.should be_true
      hover_triggered.should be_true
    end

    it "respects active state" do
      hotspot = PointClickEngine::Hotspot.new("test", vec2(0, 0), vec2(10, 10))
      hotspot.active = false

      # When inactive, update should return early
      # In a real test, we'd verify no callbacks are triggered
      hotspot.active.should be_false
    end
  end

  describe PointClickEngine::Scene do
    it "initializes with a name" do
      scene = PointClickEngine::Scene.new("main_room")
      scene.name.should eq("main_room")
    end

    it "starts with empty collections" do
      scene = PointClickEngine::Scene.new("test")
      scene.hotspots.should be_empty
      scene.objects.should be_empty
    end

    it "can add hotspots" do
      scene = PointClickEngine::Scene.new("test")
      hotspot = PointClickEngine::Hotspot.new("door", vec2(0, 0), vec2(10, 10))

      scene.add_hotspot(hotspot)

      scene.hotspots.size.should eq(1)
      scene.objects.size.should eq(1)
      scene.hotspots.first.should eq(hotspot)
    end

    it "can add generic objects" do
      scene = PointClickEngine::Scene.new("test")
      obj = TestGameObject.new(vec2(0, 0), vec2(10, 10))

      scene.add_object(obj)

      scene.objects.size.should eq(1)
      scene.objects.first.should eq(obj)
    end

    it "updates all objects" do
      scene = PointClickEngine::Scene.new("test")
      obj1 = TestGameObject.new(vec2(0, 0), vec2(10, 10))
      obj2 = TestGameObject.new(vec2(20, 20), vec2(10, 10))

      scene.add_object(obj1)
      scene.add_object(obj2)

      scene.update(0.016_f32)

      obj1.update_called.should be_true
      obj2.update_called.should be_true
    end

    it "triggers enter/exit callbacks" do
      scene = PointClickEngine::Scene.new("test")

      entered = false
      exited = false

      scene.on_enter = ->{ entered = true }
      scene.on_exit = ->{ exited = true }

      scene.enter
      entered.should be_true

      scene.exit
      exited.should be_true
    end

    it "finds hotspot at point" do
      scene = PointClickEngine::Scene.new("test")
      hotspot1 = PointClickEngine::Hotspot.new("h1", vec2(0, 0), vec2(20, 20))
      hotspot2 = PointClickEngine::Hotspot.new("h2", vec2(30, 30), vec2(20, 20))

      scene.add_hotspot(hotspot1)
      scene.add_hotspot(hotspot2)

      # Test finding hotspots
      scene.get_hotspot_at(vec2(10, 10)).should eq(hotspot1)
      scene.get_hotspot_at(vec2(40, 40)).should eq(hotspot2)
      scene.get_hotspot_at(vec2(100, 100)).should be_nil

      # Test inactive hotspot is not found
      hotspot1.active = false
      scene.get_hotspot_at(vec2(10, 10)).should be_nil
    end

    it "has configurable scale" do
      scene = PointClickEngine::Scene.new("test")
      scene.scale = 2.0_f32
      scene.scale.should eq(2.0_f32)
    end
  end

  describe PointClickEngine::InventoryItem do
    it "initializes with name and description" do
      item = PointClickEngine::InventoryItem.new("key", "A rusty old key")
      item.name.should eq("key")
      item.description.should eq("A rusty old key")
    end

    it "can have combinable items" do
      item = PointClickEngine::InventoryItem.new("key", "A key")
      item.combinable_with = ["lock", "door"]

      item.combinable_with.should contain("lock")
      item.combinable_with.should contain("door")
      item.combinable_with.size.should eq(2)
    end
  end

  describe PointClickEngine::Inventory do
    it "initializes with default position" do
      inventory = PointClickEngine::Inventory.new
      inventory.position.x.should eq(10)
      inventory.position.y.should eq(10)
    end

    it "starts hidden and empty" do
      inventory = PointClickEngine::Inventory.new
      inventory.visible.should be_false
      inventory.items.should be_empty
      inventory.selected_item.should be_nil
    end

    it "can add items" do
      inventory = PointClickEngine::Inventory.new
      item = PointClickEngine::InventoryItem.new("key", "A key")

      inventory.add_item(item)

      inventory.items.size.should eq(1)
      inventory.items.first.should eq(item)
    end

    it "prevents duplicate items" do
      inventory = PointClickEngine::Inventory.new
      item = PointClickEngine::InventoryItem.new("key", "A key")

      inventory.add_item(item)
      inventory.add_item(item) # Try to add again

      inventory.items.size.should eq(1)
    end

    it "can remove items" do
      inventory = PointClickEngine::Inventory.new
      item = PointClickEngine::InventoryItem.new("key", "A key")

      inventory.add_item(item)
      inventory.remove_item(item)

      inventory.items.should be_empty
    end

    it "checks if item exists by name" do
      inventory = PointClickEngine::Inventory.new
      item = PointClickEngine::InventoryItem.new("key", "A key")

      inventory.add_item(item)

      inventory.has_item?("key").should be_true
      inventory.has_item?("sword").should be_false
    end

    it "gets item by name" do
      inventory = PointClickEngine::Inventory.new
      item = PointClickEngine::InventoryItem.new("key", "A key")

      inventory.add_item(item)

      inventory.get_item("key").should eq(item)
      inventory.get_item("sword").should be_nil
    end

    it "has configurable appearance" do
      inventory = PointClickEngine::Inventory.new(vec2(100, 200))

      inventory.position.x.should eq(100)
      inventory.position.y.should eq(200)

      inventory.slot_size = 80.0_f32
      inventory.padding = 10.0_f32

      inventory.slot_size.should eq(80.0_f32)
      inventory.padding.should eq(10.0_f32)
    end
  end

  describe PointClickEngine::Dialog do
    it "initializes with text, position and size" do
      dialog = PointClickEngine::Dialog.new(
        "Hello, world!",
        vec2(100, 100),
        vec2(400, 200)
      )

      dialog.text.should eq("Hello, world!")
      dialog.position.x.should eq(100)
      dialog.position.y.should eq(100)
      dialog.size.x.should eq(400)
      dialog.size.y.should eq(200)
    end

    it "starts hidden" do
      dialog = PointClickEngine::Dialog.new("Test", vec2(0, 0), vec2(100, 100))
      dialog.visible.should be_false
    end

    it "can be shown and hidden" do
      dialog = PointClickEngine::Dialog.new("Test", vec2(0, 0), vec2(100, 100))

      dialog.show
      dialog.visible.should be_true

      dialog.hide
      dialog.visible.should be_false
    end

    it "triggers completion callback on hide" do
      dialog = PointClickEngine::Dialog.new("Test", vec2(0, 0), vec2(100, 100))

      completed = false
      dialog.on_complete = ->{ completed = true }

      dialog.hide
      completed.should be_true
    end

    it "can have character name" do
      dialog = PointClickEngine::Dialog.new("Hello!", vec2(0, 0), vec2(100, 100))
      dialog.character_name = "Bob"
      dialog.character_name.should eq("Bob")
    end

    it "can add choices" do
      dialog = PointClickEngine::Dialog.new("What now?", vec2(0, 0), vec2(100, 100))

      choice1_selected = false
      choice2_selected = false

      dialog.add_choice("Option 1") { choice1_selected = true }
      dialog.add_choice("Option 2") { choice2_selected = true }

      dialog.choices.size.should eq(2)
      dialog.choices[0].text.should eq("Option 1")
      dialog.choices[1].text.should eq("Option 2")

      # Test choice actions
      dialog.choices[0].action.call
      choice1_selected.should be_true

      dialog.choices[1].action.call
      choice2_selected.should be_true
    end

    it "has configurable appearance" do
      dialog = PointClickEngine::Dialog.new("Test", vec2(0, 0), vec2(100, 100))

      dialog.padding = 30.0_f32
      dialog.font_size = 24
      dialog.background_color = RL::Color.new(r: 50, g: 50, b: 50, a: 255)
      dialog.text_color = RL::RED #RL::Color.new(200, 200, 200, 255)

      dialog.padding.should eq(30.0_f32)
      dialog.font_size.should eq(24)
    end
  end

  describe PointClickEngine::AnimatedSprite do
    it "initializes with frame dimensions" do
      sprite = PointClickEngine::AnimatedSprite.new(
        vec2(100, 100),
        frame_width: 32,
        frame_height: 32,
        frame_count: 8
      )

      sprite.position.x.should eq(100)
      sprite.position.y.should eq(100)
      sprite.frame_width.should eq(32)
      sprite.frame_height.should eq(32)
      sprite.frame_count.should eq(8)
    end

    it "starts at frame 0 and playing" do
      sprite = PointClickEngine::AnimatedSprite.new(
        vec2(0, 0),
        frame_width: 32,
        frame_height: 32,
        frame_count: 4
      )

      sprite.current_frame.should eq(0)
      sprite.playing.should be_true
    end

    it "can be controlled" do
      sprite = PointClickEngine::AnimatedSprite.new(
        vec2(0, 0),
        frame_width: 32,
        frame_height: 32,
        frame_count: 4
      )

      sprite.stop
      sprite.playing.should be_false

      sprite.play
      sprite.playing.should be_true
      sprite.current_frame.should eq(0)
    end

    it "advances frames based on time" do
      sprite = PointClickEngine::AnimatedSprite.new(
        vec2(0, 0),
        frame_width: 32,
        frame_height: 32,
        frame_count: 4
      )
      sprite.frame_speed = 0.1_f32

      # Advance time but not enough for next frame
      sprite.update(0.05_f32)
      sprite.current_frame.should eq(0)

      # Advance enough for next frame
      sprite.update(0.06_f32)
      sprite.current_frame.should eq(1)

      # Continue advancing
      sprite.update(0.1_f32)
      sprite.current_frame.should eq(2)
    end

    it "loops by default" do
      sprite = PointClickEngine::AnimatedSprite.new(
        vec2(0, 0),
        frame_width: 32,
        frame_height: 32,
        frame_count: 3
      )
      sprite.frame_speed = 0.1_f32
      sprite.loop = true

      # Advance to last frame
      sprite.update(0.1_f32) # frame 1
      sprite.update(0.1_f32) # frame 2
      sprite.update(0.1_f32) # should loop to frame 0

      sprite.current_frame.should eq(0)
      sprite.playing.should be_true
    end

    it "stops at last frame when not looping" do
      sprite = PointClickEngine::AnimatedSprite.new(
        vec2(0, 0),
        frame_width: 32,
        frame_height: 32,
        frame_count: 3
      )
      sprite.frame_speed = 0.1_f32
      sprite.loop = false

      # Advance to last frame
      sprite.update(0.1_f32) # frame 1
      sprite.update(0.1_f32) # frame 2
      sprite.update(0.1_f32) # should stay at frame 2

      sprite.current_frame.should eq(2)
      sprite.playing.should be_false
    end

    it "has configurable scale" do
      sprite = PointClickEngine::AnimatedSprite.new(
        vec2(0, 0),
        frame_width: 32,
        frame_height: 32,
        frame_count: 4
      )

      sprite.scale = 2.0_f32
      sprite.scale.should eq(2.0_f32)
    end
  end

  describe PointClickEngine::Particle do
    it "initializes with properties" do
      particle = PointClickEngine::Particle.new(
        position: vec2(100, 100),
        velocity: vec2(50, -50),
        color: RL::RED,
        size: 5.0_f32,
        lifetime: 2.0_f32
      )

      particle.position.x.should eq(100)
      particle.position.y.should eq(100)
      particle.velocity.x.should eq(50)
      particle.velocity.y.should eq(-50)
      particle.size.should eq(5.0_f32)
      particle.lifetime.should eq(2.0_f32)
      particle.age.should eq(0.0_f32)
    end

    it "updates position based on velocity" do
      particle = PointClickEngine::Particle.new(
        position: vec2(100, 100),
        velocity: vec2(50, -50),
        color: RL::RED,
        size: 5.0_f32,
        lifetime: 2.0_f32
      )

      particle.update(0.1_f32)

      particle.position.x.should eq(105.0_f32) # 100 + 50 * 0.1
      particle.position.y.should eq(95.0_f32)  # 100 + (-50) * 0.1
      particle.age.should eq(0.1_f32)
    end

    it "tracks if alive based on age" do
      particle = PointClickEngine::Particle.new(
        position: vec2(0, 0),
        velocity: vec2(0, 0),
        color: RL::RED,
        size: 5.0_f32,
        lifetime: 1.0_f32
      )

      particle.alive?.should be_true

      particle.update(0.5_f32)
      particle.alive?.should be_true

      particle.update(0.6_f32) # Total age now 1.1
      particle.alive?.should be_false
    end
  end

  describe PointClickEngine::ParticleSystem do
    it "initializes at position" do
      system = PointClickEngine::ParticleSystem.new(vec2(200, 200))
      system.position.x.should eq(200)
      system.position.y.should eq(200)
    end

    it "starts with default properties" do
      system = PointClickEngine::ParticleSystem.new(vec2(0, 0))

      system.particles.should be_empty
      system.emitting.should be_true
      system.emit_rate.should eq(10.0_f32)
      system.particle_lifetime.should eq(1.0_f32)
      system.particle_size.should eq(3.0_f32)
      system.particle_speed.should eq(100.0_f32)
    end

    it "emits particles over time" do
      system = PointClickEngine::ParticleSystem.new(vec2(0, 0))
      system.emit_rate = 10.0_f32 # 10 particles per second

      # Update for 0.1 seconds (should emit 1 particle)
      system.update(0.1_f32)
      system.particles.size.should eq(1)

      # Update for another 0.2 seconds (should emit 2 more)
      system.update(0.2_f32)
      system.particles.size.should eq(3)
    end

    it "respects emitting flag" do
      system = PointClickEngine::ParticleSystem.new(vec2(0, 0))
      system.emitting = false

      system.update(0.5_f32)
      system.particles.should be_empty
    end

    it "removes dead particles" do
      system = PointClickEngine::ParticleSystem.new(vec2(0, 0))
      system.particle_lifetime = 0.5_f32
      system.emit_rate = 10.0_f32

      # Emit some particles
      system.update(0.2_f32) # Should have 2 particles
      initial_count = system.particles.size
      initial_count.should eq(2)

      # Wait for them to die
      system.emitting = false # Stop emitting new ones
      system.update(0.6_f32) # Particles should be dead now

      system.particles.should be_empty
    end

    it "has configurable particle properties" do
      system = PointClickEngine::ParticleSystem.new(vec2(0, 0))

      system.particle_color = RL::BLUE
      system.particle_size = 10.0_f32
      system.particle_speed = 200.0_f32
      system.particle_lifetime = 3.0_f32

      system.particle_color.should eq(RL::BLUE)
      system.particle_size.should eq(10.0_f32)
      system.particle_speed.should eq(200.0_f32)
      system.particle_lifetime.should eq(3.0_f32)
    end
  end

  describe PointClickEngine::Game do
    it "initializes with window properties" do
      game = PointClickEngine::Game.new(800, 600, "Test Game")

      game.window_width.should eq(800)
      game.window_height.should eq(600)
      game.title.should eq("Test Game")
      game.target_fps.should eq(60)
    end

    it "starts with no current scene" do
      game = PointClickEngine::Game.new(800, 600, "Test")

      game.current_scene.should be_nil
      game.scenes.should be_empty
    end

    it "creates inventory at bottom of screen" do
      game = PointClickEngine::Game.new(800, 600, "Test")

      game.inventory.should_not be_nil
      game.inventory.position.x.should eq(10)
      game.inventory.position.y.should eq(520) # 600 - 80
    end

    it "can add and change scenes" do
      game = PointClickEngine::Game.new(800, 600, "Test")

      scene1 = PointClickEngine::Scene.new("scene1")
      scene2 = PointClickEngine::Scene.new("scene2")

      game.add_scene(scene1)
      game.add_scene(scene2)

      game.scenes.size.should eq(2)

      # Track scene transitions
      scene1_entered = false
      scene1_exited = false
      scene2_entered = false

      scene1.on_enter = ->{ scene1_entered = true }
      scene1.on_exit = ->{ scene1_exited = true }
      scene2.on_enter = ->{ scene2_entered = true }

      # Change to scene1
      game.change_scene("scene1")
      game.current_scene.should eq(scene1)
      scene1_entered.should be_true

      # Change to scene2
      game.change_scene("scene2")
      game.current_scene.should eq(scene2)
      scene1_exited.should be_true
      scene2_entered.should be_true
    end

    it "handles non-existent scene gracefully" do
      game = PointClickEngine::Game.new(800, 600, "Test")
      scene = PointClickEngine::Scene.new("exists")
      game.add_scene(scene)
      game.change_scene("exists")

      current = game.current_scene
      game.change_scene("does_not_exist")

      # Should not change scene
      game.current_scene.should eq(current)
    end

    it "manages dialogs" do
      game = PointClickEngine::Game.new(800, 600, "Test")

      dialog = PointClickEngine::Dialog.new(
        "Test dialog",
        vec2(100, 100),
        vec2(400, 200)
      )

      game.dialogs.should be_empty

      game.show_dialog(dialog)

      game.dialogs.size.should eq(1)
      game.dialogs.first.should eq(dialog)
      dialog.visible.should be_true
    end

    it "has debug mode" do
      PointClickEngine::Game.debug_mode.should be_false

      PointClickEngine::Game.debug_mode = true
      PointClickEngine::Game.debug_mode.should be_true

      # Reset for other tests
      PointClickEngine::Game.debug_mode = false
    end

    it "has configurable default cursor" do
      game = PointClickEngine::Game.new(800, 600, "Test")

      game.default_cursor = RL::MouseCursor::Crosshair
      game.default_cursor.should eq(RL::MouseCursor::Crosshair)
    end
  end
end

# Integration test example
describe "Integration" do
  it "creates a working point-and-click scene" do
    # Create game
    game = PointClickEngine::Game.new(800, 600, "Integration Test")

    # Create main scene
    main_scene = PointClickEngine::Scene.new("main")

    # Add interactive hotspot
    door = PointClickEngine::Hotspot.new("door", vec2(300, 200), vec2(100, 150))
    door_clicked = false
    door.on_click = ->{ door_clicked = true }
    main_scene.add_hotspot(door)

    # Add inventory item
    key = PointClickEngine::InventoryItem.new("key", "A golden key")
    game.inventory.add_item(key)

    # Setup scene
    game.add_scene(main_scene)
    game.change_scene("main")

    # Verify setup
    game.current_scene.should eq(main_scene)
    game.inventory.has_item?("key").should be_true
    main_scene.hotspots.size.should eq(1)

    # Test hotspot callback
    door.on_click.try &.call
    door_clicked.should be_true
  end
end
