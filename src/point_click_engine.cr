# Point & Click Game Engine
# A Crystal shard for creating pixel art point-and-click adventure games using raylib-cr

require "raylib-cr"

# Alias for convenience
alias RL = Raylib

module PointClickEngine
  VERSION = "0.1.0"

  # Base class for all game objects
  abstract class GameObject
    property position : RL::Vector2
    property size : RL::Vector2
    property visible : Bool = true
    property active : Bool = true

    def initialize(@position : RL::Vector2, @size : RL::Vector2)
    end

    abstract def update(dt : Float32)
    abstract def draw

    def bounds : RL::Rectangle
      RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y)
    end

    def contains_point?(point : RL::Vector2) : Bool
      bounds = self.bounds
      point.x >= bounds.x &&
      point.x <= bounds.x + bounds.width &&
      point.y >= bounds.y &&
      point.y <= bounds.y + bounds.height
    end
  end

  # Clickable hotspot in the game
  class Hotspot < GameObject
    property name : String
    property cursor_type : CursorType = CursorType::Hand
    property on_click : Proc(Nil)?
    property on_hover : Proc(Nil)?
    property debug_color : RL::Color = RL::Color.new(r: 255, g: 0, b: 0, a: 100)

    enum CursorType
      Default
      Hand
      Look
      Talk
      Use
    end

    def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
      super(position, size)
    end

    def update(dt : Float32)
      return unless @active

      mouse_pos = RL.get_mouse_position
      if contains_point?(mouse_pos)
        @on_hover.try &.call
        if RL::MouseButton::Left.pressed?
          @on_click.try &.call
        end
      end
    end

    def draw
      # Draw debug rectangle in debug mode
      if Game.debug_mode && @visible
        RL.draw_rectangle_rec(bounds, @debug_color)
      end
    end
  end

  # Represents a game scene/room
  class Scene
    property name : String
    property background : RL::Texture2D?
    property hotspots : Array(Hotspot) = [] of Hotspot
    property objects : Array(GameObject) = [] of GameObject
    property on_enter : Proc(Nil)?
    property on_exit : Proc(Nil)?
    property scale : Float32 = 1.0

    def initialize(@name : String)
    end

    def load_background(path : String, scale : Float32 = 1.0)
      @background = RL.load_texture(path)
      @scale = scale
    end

    def add_hotspot(hotspot : Hotspot)
      @hotspots << hotspot
      @objects << hotspot
    end

    def add_object(object : GameObject)
      @objects << object
    end

    def update(dt : Float32)
      @objects.each(&.update(dt))
    end

    def draw
      # Draw background
      if bg = @background
        RL.draw_texture_ex(bg, RL::Vector2.new(x: 0, y: 0), 0.0, @scale, RL::Color::White)
      end

      # Draw objects
      @objects.each(&.draw)
    end

    def enter
      @on_enter.try &.call
    end

    def exit
      @on_exit.try &.call
    end

    def get_hotspot_at(point : RL::Vector2) : Hotspot?
      @hotspots.find { |h| h.active && h.contains_point?(point) }
    end
  end

  # Inventory item
  class InventoryItem
    property name : String
    property description : String
    property icon : RL::Texture2D?
    property combinable_with : Array(String) = [] of String

    def initialize(@name : String, @description : String)
    end

    def load_icon(path : String)
      @icon = RL.load_texture(path)
    end
  end

  # Player inventory system
  class Inventory
    property items : Array(InventoryItem) = [] of InventoryItem
    property visible : Bool = false
    property position : RL::Vector2
    property slot_size : Float32 = 64.0
    property padding : Float32 = 8.0
    property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 200)
    property selected_item : InventoryItem?

    def initialize(@position : RL::Vector2 = RL::Vector2.new(x: 10, y: 10))
    end

    def add_item(item : InventoryItem)
      @items << item unless @items.includes?(item)
    end

    def remove_item(item : InventoryItem)
      @items.delete(item)
    end

    def has_item?(name : String) : Bool
      @items.any? { |i| i.name == name }
    end

    def get_item(name : String) : InventoryItem?
      @items.find { |i| i.name == name }
    end

    def update(dt : Float32)
      return unless @visible

      mouse_pos = RL.get_mouse_position
      if RL.is_mouse_button_pressed(RL::MouseButton::Left)
        # Check if clicking on an item
        @items.each_with_index do |item, index|
          item_rect = get_item_rect(index)
          if RL.check_collision_point_rec(mouse_pos, item_rect)
            @selected_item = item
            break
          end
        end
      end
    end

    def draw
      return unless @visible

      # Draw background
      total_width = (@items.size * (@slot_size + @padding)) + @padding
      bg_rect = RL::Rectangle.new(x: @position.x, y: @position.y, width: total_width, height: @slot_size + @padding * 2)
      RL.draw_rectangle_rec(bg_rect, @background_color)

      # Draw items
      @items.each_with_index do |item, index|
        item_rect = get_item_rect(index)

        # Draw slot
        RL.draw_rectangle_rec(item_rect, RL::Color.new(r: 50, g: 50, b: 50, a: 255))

        # Draw item icon if available
        if icon = item.icon
          RL.draw_texture_ex(icon, RL::Vector2.new(x: item_rect.x, y: item_rect.y), 0.0,
                            @slot_size / icon.width.to_f, RL::Color::White)
        end

        # Highlight selected item
        if item == @selected_item
          RL.draw_rectangle_lines_ex(item_rect, 2, RL::Color::Yellow)
        end
      end
    end

    private def get_item_rect(index : Int32) : RL::Rectangle
      x = @position.x + @padding + (index * (@slot_size + @padding))
      y = @position.y + @padding
      RL::Rectangle.new(x: x, y: y, width: @slot_size, height: @slot_size)
    end
  end

  # Dialog system
  class Dialog
    property text : String
    property character : String?
    property choices : Array(DialogChoice) = [] of DialogChoice
    property on_complete : Proc(Nil)?
    property visible : Bool = false
    property position : RL::Vector2
    property size : RL::Vector2
    property padding : Float32 = 20.0
    property font_size : Int32 = 20
    property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 220)
    property text_color : RL::Color = RL::WHITE

    struct DialogChoice
      property text : String
      property action : Proc(Nil)

      def initialize(@text : String, @action : Proc(Nil))
      end
    end

    def initialize(@text : String, @position : RL::Vector2, @size : RL::Vector2)
    end

    def add_choice(text : String, &action : -> Nil)
      @choices << DialogChoice.new(text, action)
    end

    def show
      @visible = true
    end

    def hide
      @visible = false
      @on_complete.try &.call
    end

    def update(dt : Float32)
      return unless @visible

      if @choices.empty?
        # Skip dialog on click/key press
        if RL.is_mouse_button_pressed(RL::MouseButton::Left) || RL.is_key_pressed(RL::Key::Space)
          hide
        end
      else
        # Handle choice selection
        mouse_pos = RL.get_mouse_position
        if RL.is_mouse_button_pressed(RL::MouseButton::Left)
          @choices.each_with_index do |choice, index|
            choice_rect = get_choice_rect(index)
            if RL.check_collision_point_rec(mouse_pos, choice_rect)
              choice.action.call
              hide
              break
            end
          end
        end
      end
    end

    def draw
      return unless @visible

      # Draw background
      bg_rect = RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y)
      RL.draw_rectangle_rec(bg_rect, @background_color)
      RL.draw_rectangle_lines_ex(bg_rect, 2, RL::Color::White)

      # Draw character name if present
      y_offset = @padding
      if char = @character
        RL.draw_text(char, @position.x.to_i + @padding.to_i,
                     @position.y.to_i + y_offset.to_i, @font_size + 4, RL::Color::Yellow)
        y_offset += @font_size + 10
      end

      # Draw text
      RL.draw_text(@text, @position.x.to_i + @padding.to_i,
                   @position.y.to_i + y_offset.to_i, @font_size, @text_color)

      # Draw choices
      if !@choices.empty?
        y_offset = @position.y + @size.y - (@choices.size * 30) - @padding
        @choices.each_with_index do |choice, index|
          choice_rect = get_choice_rect(index)

          # Highlight on hover
          mouse_pos = RL.get_mouse_position
          color = RL.check_collision_point_rec(mouse_pos, choice_rect) ?
                  RL::Color::Yellow : RL::Color::White

          RL.draw_text("> #{choice.text}", choice_rect.x.to_i, choice_rect.y.to_i,
                      @font_size, color)
        end
      end
    end

    private def get_choice_rect(index : Int32) : RL::Rectangle
      y = @position.y + @size.y - ((@choices.size - index) * 30) - @padding
      RL::Rectangle.new(x: @position.x + @padding, y: y, width: @size.x - @padding * 2, height: 25)
    end
  end

  # Main game class
  class Game
    class_property debug_mode : Bool = false

    property window_width : Int32
    property window_height : Int32
    property title : String
    property target_fps : Int32 = 60
    property current_scene : Scene?
    property scenes : Hash(String, Scene) = {} of String => Scene
    property inventory : Inventory
    property dialogs : Array(Dialog) = [] of Dialog
    property running : Bool = false
    property cursor_texture : RL::Texture2D?
    property default_cursor : RL::MouseCursor = RL::MouseCursor::Default

    def initialize(@window_width : Int32, @window_height : Int32, @title : String)
      @inventory = Inventory.new(RL::Vector2.new(x: 10, y: @window_height - 80))
    end

    def init
      RL.init_window(@window_width, @window_height, @title)
      RL.set_target_fps(@target_fps)
      RL.hide_cursor if @cursor_texture
    end

    def load_cursor(path : String)
      @cursor_texture = RL.load_texture(path)
      RL.hide_cursor
    end

    def add_scene(scene : Scene)
      @scenes[scene.name] = scene
    end

    def change_scene(name : String)
      if new_scene = @scenes[name]?
        @current_scene.try &.exit
        @current_scene = new_scene
        new_scene.enter
      end
    end

    def show_dialog(dialog : Dialog)
      dialog.show
      @dialogs << dialog
    end

    def run
      init
      @running = true

      while @running && !RL.window_should_close
        update(RL.get_frame_time)
        draw
      end

      cleanup
    end

    def stop
      @running = false
    end

    private def update(dt : Float32)
      # Update current scene
      @current_scene.try &.update(dt)

      # Update inventory
      @inventory.update(dt)

      # Update dialogs
      @dialogs.each(&.update(dt))
      @dialogs.reject! { |d| !d.visible }

      # Toggle inventory
      if RL.is_key_pressed(RL::Key::I)
        @inventory.visible = !@inventory.visible
      end

      # Toggle debug mode
      if RL.is_key_pressed(RL::Key::F1)
        Game.debug_mode = !Game.debug_mode
      end

      # Update cursor
      update_cursor
    end

    private def draw
      RL.begin_drawing
      RL.clear_background(RL::Color::Black)

      # Draw current scene
      @current_scene.try &.draw

      # Draw inventory
      @inventory.draw

      # Draw dialogs
      @dialogs.each(&.draw)

      # Draw custom cursor
      if cursor = @cursor_texture
        mouse_pos = RL.get_mouse_position
        RL.draw_texture_v(cursor, mouse_pos, RL::Color::White)
      end

      # Draw debug info
      if Game.debug_mode
        RL.draw_text("FPS: #{RL.get_fps}", 10, 10, 20, RL::Color::Green)
        mouse_pos = RL.get_mouse_position
        RL.draw_text("Mouse: #{mouse_pos.x.to_i}, #{mouse_pos.y.to_i}", 10, 35, 20, RL::Color::Green)
      end

      RL.end_drawing
    end

    private def update_cursor
      return if @cursor_texture

      mouse_pos = RL.get_mouse_position
      if scene = @current_scene
        if hotspot = scene.get_hotspot_at(mouse_pos)
          case hotspot.cursor_type
          when Hotspot::CursorType::Hand
            RL.set_mouse_cursor(RL::MouseCursor::PointingHand)
          when Hotspot::CursorType::Default
            RL.set_mouse_cursor(RL::MouseCursor::Default)
          else
            RL.set_mouse_cursor(RL::MouseCursor::Crosshair)
          end
        else
          RL.set_mouse_cursor(@default_cursor)
        end
      end
    end

    private def cleanup
      # Unload textures
      @scenes.each_value do |scene|
        if bg = scene.background
          RL.unload_texture(bg)
        end
      end

      @inventory.items.each do |item|
        if icon = item.icon
          RL.unload_texture(icon)
        end
      end

      if cursor = @cursor_texture
        RL.unload_texture(cursor)
      end

      RL.close_window
    end
  end

  # Sprite animation for characters/objects
  class AnimatedSprite < GameObject
    property texture : RL::Texture2D?
    property frame_width : Int32
    property frame_height : Int32
    property current_frame : Int32 = 0
    property frame_count : Int32
    property frame_speed : Float32 = 0.1
    property frame_timer : Float32 = 0.0
    property loop : Bool = true
    property playing : Bool = true
    property scale : Float32 = 1.0

    def initialize(position : RL::Vector2, @frame_width : Int32, @frame_height : Int32, @frame_count : Int32)
      super(position, RL::Vector2.new(x: @frame_width * @scale, y: @frame_height * @scale))
    end

    def load_texture(path : String)
      @texture = RL.load_texture(path)
    end

    def play
      @playing = true
      @current_frame = 0
      @frame_timer = 0.0
    end

    def stop
      @playing = false
    end

    def update(dt : Float32)
      return unless @playing

      @frame_timer += dt
      if @frame_timer >= @frame_speed
        @frame_timer = 0.0
        @current_frame += 1

        if @current_frame >= @frame_count
          if @loop
            @current_frame = 0
          else
            @current_frame = @frame_count - 1
            @playing = false
          end
        end
      end
    end

    def draw
      return unless @visible
      return unless tex = @texture

      source_rect = RL::Rectangle.new(
        x: @current_frame * @frame_width,
        y: 0,
        width: @frame_width,
        height: @frame_height
      )

      dest_rect = RL::Rectangle.new(
        x: @position.x,
        y: @position.y,
        width: @frame_width * @scale,
        height: @frame_height * @scale
      )

      RL.draw_texture_pro(tex, source_rect, dest_rect, RL::Vector2.new(x: 0, y: 0), 0.0, RL::Color::White)
    end
  end

  # Particle effect for visual feedback
  class Particle
    property position : RL::Vector2
    property velocity : RL::Vector2
    property color : RL::Color
    property size : Float32
    property lifetime : Float32
    property age : Float32 = 0.0

    def initialize(@position : RL::Vector2, @velocity : RL::Vector2, @color : RL::Color,
                   @size : Float32, @lifetime : Float32)
    end

    def update(dt : Float32)
      @age += dt
      @position.x += @velocity.x * dt
      @position.y += @velocity.y * dt
    end

    def draw
      alpha = (1.0 - @age / @lifetime) * 255
      color = RL::Color.new(r: @color.r, g: @color.g, b: @color.b, a: alpha.to_u8)
      RL.draw_circle(@position.x.to_i, @position.y.to_i, @size, color)
    end

    def alive? : Bool
      @age < @lifetime
    end
  end

  class ParticleSystem < GameObject
    property particles : Array(Particle) = [] of Particle
    property emit_rate : Float32 = 10.0
    property emit_timer : Float32 = 0.0
    property particle_lifetime : Float32 = 1.0
    property particle_size : Float32 = 3.0
    property particle_speed : Float32 = 100.0
    property particle_color : RL::Color = RL::WHITE
    property emitting : Bool = true

    def initialize(position : RL::Vector2)
      super(position, RL::Vector2.new(x: 0, y: 0))
    end

    def emit_particle
      angle = Random.rand * Math::PI * 2
      velocity = RL::Vector2.new(
        x: Math.cos(angle) * @particle_speed * (0.5 + Random.rand * 0.5),
        y: Math.sin(angle) * @particle_speed * (0.5 + Random.rand * 0.5)
      )

      particle = Particle.new(
        @position,
        velocity,
        @particle_color,
        @particle_size * (0.5 + Random.rand * 0.5),
        @particle_lifetime * (0.5 + Random.rand * 0.5)
      )

      @particles << particle
    end

    def update(dt : Float32)
      # Emit new particles
      if @emitting
        @emit_timer += dt
        while @emit_timer >= 1.0 / @emit_rate
          emit_particle
          @emit_timer -= 1.0 / @emit_rate
        end
      end

      # Update existing particles
      @particles.each(&.update(dt))
      @particles.reject! { |p| !p.alive? }
    end

    def draw
      @particles.each(&.draw)
    end
  end
end

# Example usage:
# require "point_click_engine"
#
# game = PointClickEngine::Game.new(800, 600, "My Point & Click Adventure")
#
# # Create a scene
# scene = PointClickEngine::Scene.new("main_room")
# scene.load_background("assets/room.png")
#
# # Add a hotspot
# door = PointClickEngine::Hotspot.new("door", RL::Vector2.new(x: 300, y: 200), RL::Vector2.new(x: 100, y: 150))
# door.on_click = ->{ game.change_scene("hallway") }
# scene.add_hotspot(door)
#
# # Add scene to game
# game.add_scene(scene)
# game.change_scene("main_room")
#
# # Run the game
# game.run
