require "../src/point_click_engine"

# Example demonstrating localization
class LocalizationExample < PointClickEngine::Core::Game
  @current_locale_index : Int32 = 0
  @available_locales : Array(PointClickEngine::Localization::Locale)
  
  def initialize
    super(title: "Localization Example", width: 1280, height: 960)
    @available_locales = [] of PointClickEngine::Localization::Locale
  end
  
  def load_content
    # Load translations
    localization = PointClickEngine::Localization::LocalizationManager.instance
    localization.load_from_directory("example/locales")
    
    @available_locales = localization.available_locales
    
    # Create a simple scene
    scene = PointClickEngine::Scenes::Scene.new("localization_demo")
    
    # Add background
    bg_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/room.png")
    scene.set_background(bg_texture)
    
    # Add player with localized name
    player = PointClickEngine::Characters::Player.new(
      t("character.player.name", default: "Hero"), 
      400, 400, 32, 48
    )
    player_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/character.png")
    player.sprite = PointClickEngine::Graphics::AnimatedSprite.new(player_texture, 32, 48)
    player.sprite.not_nil!.add_animation("idle", [0])
    player.sprite.not_nil!.add_animation("walk", [0, 1, 2, 3])
    player.sprite.not_nil!.play("idle")
    scene.add_character(player)
    scene.player = player
    
    # Add NPC
    npc = PointClickEngine::Characters::NPC.new(
      t("character.npc.guard", default: "Guard"),
      600, 400, 32, 48
    )
    npc.sprite = PointClickEngine::Graphics::AnimatedSprite.new(player_texture, 32, 48)
    npc.sprite.not_nil!.add_animation("idle", [0])
    npc.sprite.not_nil!.play("idle")
    npc.on_talk = -> {
      messages = [
        "Hello! This text should be localized.",
        "Try pressing L to change language.",
        "Current language: #{localization.current_locale.display_name}"
      ]
      npc.say(messages.sample) {}
    }
    scene.add_character(npc)
    
    # Add interactive items with localized descriptions
    key = PointClickEngine::Scenes::Hotspot.new(
      t("item.key", default: "Key"),
      Raylib::Vector2.new(x: 300, y: 350),
      Raylib::Vector2.new(x: 32, y: 32)
    )
    key.description = t("item.key.description", default: "A rusty old key")
    key.on_click = -> {
      puts t("action.pickup", default: "Pick up") + " " + t("item.key", default: "Key")
      
      # Add to inventory with pluralization example
      count = Random.rand(1..5)
      puts t("inventory.items", count: count, count: count.to_s)
    }
    scene.add_hotspot(key)
    
    # Add locked door
    door = PointClickEngine::Scenes::Hotspot.new(
      "door",
      Raylib::Vector2.new(x: 800, y: 300),
      Raylib::Vector2.new(x: 80, y: 120)
    )
    door.description = "A wooden door"
    door.on_click = -> {
      puts t("message.locked", default: "It's locked")
    }
    scene.add_hotspot(door)
    
    PointClickEngine::Core::Engine.instance.add_scene(scene)
    PointClickEngine::Core::Engine.instance.change_scene("localization_demo")
  end
  
  def update(dt : Float32)
    super(dt)
    
    # Change language with L key
    if Raylib.is_key_pressed(Raylib::KeyboardKey::L)
      @current_locale_index = (@current_locale_index + 1) % @available_locales.size
      new_locale = @available_locales[@current_locale_index]
      PointClickEngine::Localization::LocalizationManager.instance.set_locale(new_locale)
      
      # Update UI elements
      update_localized_content
    end
  end
  
  def draw
    super
    
    localization = PointClickEngine::Localization::LocalizationManager.instance
    
    # Draw title
    Raylib.draw_text("Localization Example", 10, 10, 24, Raylib::WHITE)
    
    # Draw current language
    lang_text = "#{t("settings.language", default: "Language")}: #{localization.current_locale.display_name}"
    Raylib.draw_text(lang_text, 10, 40, 20, Raylib::YELLOW)
    
    # Draw instructions
    Raylib.draw_text("Press L to change language", 10, 70, 16, Raylib::WHITE)
    Raylib.draw_text("Click on objects to see localized messages", 10, 90, 16, Raylib::WHITE)
    
    # Draw menu mockup
    draw_menu_mockup
    
    # Draw inventory mockup
    draw_inventory_mockup
  end
  
  private def draw_menu_mockup
    x = 1000
    y = 200
    
    Raylib.draw_text("Menu Example:", x, y, 18, Raylib::WHITE)
    y += 30
    
    menu_items = ["menu.new_game", "menu.continue", "menu.options", "menu.quit"]
    menu_items.each do |key|
      Raylib.draw_text("• " + t(key, default: key), x + 10, y, 16, Raylib::LIGHTGRAY)
      y += 25
    end
  end
  
  private def draw_inventory_mockup
    x = 1000
    y = 400
    
    title = t("inventory.title", default: "Inventory")
    Raylib.draw_text(title + ":", x, y, 18, Raylib::WHITE)
    y += 30
    
    # Show item count with pluralization
    (1..3).each do |count|
      text = t("inventory.items", count: count, count: count.to_s)
      Raylib.draw_text(text, x + 10, y, 16, Raylib::LIGHTGRAY)
      y += 25
    end
  end
  
  private def update_localized_content
    # In a real game, you would update all UI elements here
    puts "Language changed to: #{PointClickEngine::Localization::LocalizationManager.instance.current_locale.display_name}"
  end
end

# Run the example
example = LocalizationExample.new
example.run