require "../src/point_click_engine"

# Example demonstrating shader effects
class ShaderExample < PointClickEngine::Core::Game
  @current_effect : Symbol = :none
  @effects : Array(Symbol)
  @effect_index : Int32 = 0
  @time : Float32 = 0.0f32

  def initialize
    super(title: "Shader Effects Example", width: 1280, height: 960)
    @effects = [:none, :pixelate, :grayscale, :sepia, :vignette, :chromatic_aberration, :bloom, :crt, :wave]
  end

  def load_content
    # Create a scene
    scene = PointClickEngine::Scenes::Scene.new("shader_demo")

    # Add background
    bg_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/room.png")
    scene.set_background(bg_texture)

    # Add some animated sprites to demonstrate effects
    sprite_texture = PointClickEngine::Assets::AssetManager.instance.load_texture("example/assets/character.png")

    # Create walking character
    character = PointClickEngine::Characters::Player.new("hero", 400, 400, 32, 48)
    character.sprite = PointClickEngine::Graphics::AnimatedSprite.new(sprite_texture, 32, 48)
    character.sprite.not_nil!.add_animation("idle", [0])
    character.sprite.not_nil!.add_animation("walk", [0, 1, 2, 3])
    character.sprite.not_nil!.play("walk")
    scene.add_character(character)

    # Add NPC with patrol behavior
    npc = PointClickEngine::Characters::NPC.new("guard", 600, 400, 32, 48)
    npc.sprite = PointClickEngine::Graphics::AnimatedSprite.new(sprite_texture, 32, 48)
    npc.sprite.not_nil!.add_animation("idle", [0])
    npc.sprite.not_nil!.add_animation("walk", [0, 1, 2, 3])
    npc.sprite.not_nil!.play("walk")

    # Add patrol behavior
    patrol_points = [
      Raylib::Vector2.new(x: 600, y: 400),
      Raylib::Vector2.new(x: 800, y: 400),
      Raylib::Vector2.new(x: 800, y: 500),
      Raylib::Vector2.new(x: 600, y: 500),
    ]
    patrol = PointClickEngine::Characters::AI::PatrolBehavior.new(patrol_points, 50.0f32)
    npc.set_ai_behavior(patrol)
    scene.add_character(npc)

    # Add particle effect
    particle_system = PointClickEngine::Graphics::ParticleSystem.new(100)
    particle_system.set_spawn_area(Raylib::Rectangle.new(x: 512, y: 300, width: 10, height: 10))
    particle_system.set_particle_life(2.0f32, 3.0f32)
    particle_system.set_particle_size(3.0f32, 8.0f32)
    particle_system.set_particle_speed(20.0f32, 50.0f32)
    particle_system.set_particle_color(Raylib::ORANGE, Raylib::RED)
    particle_system.set_gravity(0.0f32, -30.0f32)
    scene.add_particle_system(particle_system)

    PointClickEngine::Core::Engine.instance.add_scene(scene)
    PointClickEngine::Core::Engine.instance.set_current_scene("shader_demo")
  end

  def update(dt : Float32)
    super(dt)
    @time += dt

    # Update time-based shader uniforms
    if display = PointClickEngine::Core::Engine.instance.display_manager
      case @current_effect
      when :wave
        display.update_shader_value(:wave, "time", @time)
      when :pixelate
        # Animate pixel size
        pixel_size = 2.0f32 + Math.sin(@time * 2.0f32).to_f32 * 2.0f32
        display.update_shader_value(:pixelate, "pixelSize", pixel_size)
      when :chromatic_aberration
        # Animate chromatic aberration offset
        offset = 0.002f32 + Math.sin(@time * 3.0f32).to_f32 * 0.003f32
        display.update_shader_value(:chromatic_aberration, "offset", offset)
      when :vignette
        # Pulse vignette
        radius = 0.7f32 + Math.sin(@time).to_f32 * 0.1f32
        display.update_shader_value(:vignette, "radius", radius)
      end
    end

    # Switch effects with keys 1-9
    if Raylib.is_key_pressed(Raylib::KeyboardKey::One)
      switch_effect(0)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Two)
      switch_effect(1)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Three)
      switch_effect(2)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Four)
      switch_effect(3)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Five)
      switch_effect(4)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Six)
      switch_effect(5)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Seven)
      switch_effect(6)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Eight)
      switch_effect(7)
    elsif Raylib.is_key_pressed(Raylib::KeyboardKey::Nine)
      switch_effect(8)
    end

    # Cycle through effects with space
    if Raylib.is_key_pressed(Raylib::KeyboardKey::Space)
      @effect_index = (@effect_index + 1) % @effects.size
      switch_effect(@effect_index)
    end
  end

  def draw
    super

    # Draw UI
    Raylib.draw_text("Shader Effects Demo", 10, 50, 24, Raylib::WHITE)
    Raylib.draw_text("Current Effect: #{@current_effect}", 10, 80, 20, Raylib::YELLOW)
    Raylib.draw_text("Press 1-9 to select effect, SPACE to cycle", 10, 110, 16, Raylib::WHITE)

    # Draw effect list
    y = 150
    @effects.each_with_index do |effect, i|
      color = effect == @current_effect ? Raylib::YELLOW : Raylib::WHITE
      prefix = effect == @current_effect ? "> " : "  "
      Raylib.draw_text("#{prefix}#{i + 1}. #{effect}", 10, y, 16, color)
      y += 20
    end
  end

  private def switch_effect(index : Int32)
    return if index < 0 || index >= @effects.size

    @effect_index = index
    @current_effect = @effects[index]

    if display = PointClickEngine::Core::Engine.instance.display_manager
      if @current_effect == :none
        display.disable_post_processing
      else
        display.enable_post_processing(@current_effect)
      end
    end
  end
end

# Run the example
example = ShaderExample.new
example.run
