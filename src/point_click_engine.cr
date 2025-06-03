# Point & Click Game Engine
# A Crystal shard for creating pixel art point-and-click adventure games using raylib-cr

require "raylib-cr"
require "yaml" # Added for YAML serialization

# Alias for convenience
alias RL = Raylib

# YAML Converters for Raylib types
# =================================
module RaylibYAMLConverters
  struct Vector2Converter
    def self.to_yaml(vec : RL::Vector2, builder : YAML::Nodes::Builder)
      builder.mapping do |map|
        map.entry "x", vec.x
        map.entry "y", vec.y
      end
    end

    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
      x = node["x"].as(Float32)
      y = node["y"].as(Float32)
      RL::Vector2.new(x: x, y: y)
    end
  end

  struct ColorConverter
    def self.to_yaml(color : RL::Color, builder : YAML::Nodes::Builder)
      builder.mapping do |map|
        map.entry "r", color.r
        map.entry "g", color.g
        map.entry "b", color.b
        map.entry "a", color.a
      end
    end

    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
      r = node["r"].as(UInt8)
      g = node["g"].as(UInt8)
      b = node["b"].as(UInt8)
      a = node["a"].as(UInt8)
      RL::Color.new(r: r, g: g, b: b, a: a)
    end
  end

  struct RectangleConverter
    def self.to_yaml(rect : RL::Rectangle, builder : YAML::Nodes::Builder)
      builder.mapping do |map|
        map.entry "x", rect.x
        map.entry "y", rect.y
        map.entry "width", rect.width
        map.entry "height", rect.height
      end
    end

    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
      x = node["x"].as(Float32)
      y = node["y"].as(Float32)
      width = node["width"].as(Float32)
      height = node["height"].as(Float32)
      RL::Rectangle.new(x: x, y: y, width: width, height: height)
    end
  end
end

module PointClickEngine
  VERSION = "0.2.1" # Bumped version

  module Drawable

    property visible : Bool = true
    @[YAML::Field(converter: RaylibYAMLConverters::Vector2Converter)]
    property position : RL::Vector2
    @[YAML::Field(converter: RaylibYAMLConverters::Vector2Converter)]
    property size : RL::Vector2 = RL::Vector2.new

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

    # Called after YAML deserialization
    def after_yaml_deserialize(ctx : YAML::ParseContext)
      # Placeholder, specific drawables might need to reload assets
    end
  end

  # Base class for all game objects
  abstract class GameObject
    include YAML::Serializable # Make it serializable
    include Drawable

    property active : Bool = true

    # Default constructor for YAML
    def initialize
      @position = RL::Vector2.new # Default
      @size = RL::Vector2.new     # Default
    end

    def initialize(@position : RL::Vector2, @size : RL::Vector2)
    end

    abstract def update(dt : Float32)
  end

  # Clickable hotspot in the game
  class Hotspot < GameObject
    property name : String
    property cursor_type : CursorType = CursorType::Hand
    @[YAML::Field(ignore: true)] # Procs cannot be serialized directly
    property on_click : Proc(Nil)?
    @[YAML::Field(ignore: true)] # Procs cannot be serialized directly
    property on_hover : Proc(Nil)?
    @[YAML::Field(converter: RaylibYAMLConverters::ColorConverter)]
    property debug_color : RL::Color = RL::Color.new(r: 255, g: 0, b: 0, a: 100)

    enum CursorType
      Default
      Hand
      Look
      Talk
      Use
    end

    # For YAML deserialization
    def initialize
      super(RL::Vector2.new, RL::Vector2.new) # Provide default values or ensure properties are set
      @name = ""
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
      if Game.debug_mode && @visible
        RL.draw_rectangle_rec(bounds, @debug_color)
      end
    end
  end

  # Represents a game scene/room
  class Scene
    include YAML::Serializable

    property name : String
    property background_path : String? # Store path instead of texture
    @[YAML::Field(ignore: true)]
    property background : RL::Texture2D?
    property hotspots : Array(Hotspot) = [] of Hotspot
    property objects : Array(GameObject) = [] of GameObject # Will store concrete types
    @[YAML::Field(ignore: true)]
    property on_enter : Proc(Nil)?
    @[YAML::Field(ignore: true)]
    property on_exit : Proc(Nil)?
    property scale : Float32 = 1.0

    # For YAML
    def initialize
      @name = ""
      @objects = [] of GameObject # Important for polymorphism
      @hotspots = [] of Hotspot
      @characters = [] of Character
    end

    def initialize(@name : String)
      @objects = [] of GameObject
      @hotspots = [] of Hotspot
      @characters = [] of Character
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
      if path = @background_path
        load_background(path, @scale) # Reload texture
      end
      # Re-populate objects from characters and hotspots if necessary, or ensure they are distinct
      # The current setup adds hotspots/characters to @objects, which should be fine.
      # We might need to re-link player if it was serialized by name/ID
    end

    def load_background(path : String, scale : Float32 = 1.0)
      @background_path = path # Store path for serialization
      @background = RL.load_texture(path)
      @scale = scale
    end

    def add_hotspot(hotspot : Hotspot)
      @hotspots << hotspot
      @objects << hotspot unless @objects.includes?(hotspot)
    end

    def add_object(object : GameObject)
      @objects << object unless @objects.includes?(object)
    end

    def update(dt : Float32)
      @objects.each(&.update(dt))
    end

    def draw
      if bg = @background
        RL.draw_texture_ex(bg, RL::Vector2.new(x: 0, y: 0), 0.0, @scale, RL::WHITE)
      end
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
    include YAML::Serializable

    property name : String
    property description : String
    property icon_path : String? # Store path
    @[YAML::Field(ignore: true)]
    property icon : RL::Texture2D?
    property combinable_with : Array(String) = [] of String

    # For YAML
    def initialize
      @name = ""
      @description = ""
    end

    def initialize(@name : String, @description : String)
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
      if path = @icon_path
        load_icon(path) # Reload texture
      end
    end

    def load_icon(path : String)
      @icon_path = path # Store path
      @icon = RL.load_texture(path)
    end
  end

  # Player inventory system
  class Inventory
    include YAML::Serializable # Make it serializable

    include Drawable # Already includes YAML::Serializable

    property items : Array(InventoryItem) = [] of InventoryItem
    property slot_size : Float32 = 64.0
    property padding : Float32 = 8.0
    @[YAML::Field(converter: RaylibYAMLConverters::ColorConverter)]
    property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 200)

    property selected_item_name : String? # For serialization
    @[YAML::Field(ignore: true)]
    property selected_item : InventoryItem?

    # For YAML
    def initialize
      @position = RL::Vector2.new(x: 10, y: 10) # Default
      @visible = false
      @items = [] of InventoryItem
    end

    def initialize(@position : RL::Vector2 = RL::Vector2.new(x: 10, y: 10))
      @visible = false
      @items = [] of InventoryItem
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
      @items.each &.after_yaml_deserialize(ctx) # Ensure items reload their icons
      if name = @selected_item_name
        @selected_item = get_item(name)
      end
    end

    def add_item(item : InventoryItem)
      @items << item unless @items.any? { |existing_item| existing_item.name == item.name }
    end

    def remove_item(item_name : String)
      @items.reject! { |i| i.name == item_name }
      if @selected_item.try(&.name) == item_name
        @selected_item = nil
        @selected_item_name = nil
      end
    end

    def remove_item(item : InventoryItem)
      remove_item(item.name)
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
      if RL::MouseButton::Left.pressed?
        @items.each_with_index do |item, index|
          item_rect = get_item_rect(index)
          if RL.check_collision_point_rec?(mouse_pos, item_rect)
            @selected_item = item
            @selected_item_name = item.name # For serialization
            break
          end
        end
      end
    end

    def draw
      return unless @visible
      total_width = (@items.size * (@slot_size + @padding)) + @padding
      bg_rect = RL::Rectangle.new(x: @position.x, y: @position.y, width: total_width, height: @slot_size + @padding * 2)
      RL.draw_rectangle_rec(bg_rect, @background_color)

      @items.each_with_index do |item, index|
        item_rect = get_item_rect(index)
        RL.draw_rectangle_rec(item_rect, RL::Color.new(r: 50, g: 50, b: 50, a: 255))
        if icon = item.icon
          RL.draw_texture_ex(icon, RL::Vector2.new(x: item_rect.x, y: item_rect.y), 0.0,
            @slot_size / icon.width.to_f, RL::WHITE)
        end
        if item == @selected_item
          RL.draw_rectangle_lines_ex(item_rect, 2, RL::YELLOW)
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
    include YAML::Serializable # Make it serializable

    include Drawable # Already includes YAML::Serializable

    property text : String
    property character_name : String? # Use name for serialization
    property choices : Array(DialogChoice) = [] of DialogChoice
    @[YAML::Field(ignore: true)]
    property on_complete : Proc(Nil)?
    property padding : Float32 = 20.0
    property font_size : Int32 = 20
    @[YAML::Field(converter: RaylibYAMLConverters::ColorConverter)]
    property background_color : RL::Color = RL::Color.new(r: 0, g: 0, b: 0, a: 220)
    @[YAML::Field(converter: RaylibYAMLConverters::ColorConverter)]
    property text_color : RL::Color = RL::WHITE
    property ready_to_process_input : Bool = false


    struct DialogChoice
      include YAML::Serializable # Make it serializable
      property text : String
      @[YAML::Field(ignore: true)] # Procs cannot be serialized
      property action : Proc(Nil)

      # For YAML (action will be lost)
      def initialize
        @text = ""
        @action = ->{} # Dummy proc
      end

      def initialize(@text : String, @action : Proc(Nil))
      end
    end

    # For YAML
    def initialize
      @text = ""
      @position = RL::Vector2.new # Default
      @size = RL::Vector2.new(x:300, y:100)     # Default
      @visible = false
      @choices = [] of DialogChoice
    end

    def initialize(@text : String, @position : RL::Vector2, @size : RL::Vector2)
      @visible = false
      @choices = [] of DialogChoice
    end

    def add_choice(text : String, &action : -> Nil)
      @choices << DialogChoice.new(text, action)
    end

    def show
      @visible = true
      @ready_to_process_input = false
    end

    def hide
      @visible = false
      @on_complete.try &.call
    end

    def update(dt : Float32)
      return unless @visible
      unless @ready_to_process_input
        @ready_to_process_input = true
        return
      end

      if @choices.empty?
        if RL::MouseButton::Left.pressed? || RL::KeyboardKey::Space.pressed?
          hide
        end
      else
        mouse_pos = RL.get_mouse_position
        if RL::MouseButton::Left.pressed?
          @choices.each_with_index do |choice, index|
            choice_rect = get_choice_rect(index)
            if RL.check_collision_point_rec?(mouse_pos, choice_rect)
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
      bg_rect = RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y)
      RL.draw_rectangle_rec(bg_rect, @background_color)
      RL.draw_rectangle_lines_ex(bg_rect, 2, RL::WHITE)

      y_offset = @padding
      if char_name = @character_name
        RL.draw_text(char_name, @position.x.to_i + @padding.to_i,
          @position.y.to_i + y_offset.to_i, @font_size + 4, RL::YELLOW)
        y_offset += @font_size + 10
      end

      RL.draw_text(@text, @position.x.to_i + @padding.to_i,
        @position.y.to_i + y_offset.to_i, @font_size, @text_color)

      if !@choices.empty?
        base_choice_y = @position.y + @size.y - (@choices.size * 30) - @padding # Adjusted for clarity
        @choices.each_with_index do |choice, index|
          choice_rect = get_choice_rect(index, base_choice_y) # Pass base_choice_y
          mouse_pos = RL.get_mouse_position
          color = RL.check_collision_point_rec?(mouse_pos, choice_rect) ? RL::YELLOW : RL::WHITE
          RL.draw_text("> #{choice.text}", choice_rect.x.to_i, choice_rect.y.to_i, @font_size, color)
        end
      end
    end

    private def get_choice_rect(index : Int32, base_y_offset : Float32? = nil) : RL::Rectangle
      # Use a calculated base offset if provided, otherwise calculate as before
      # This is to ensure consistency if the number of choices changes how y_offset is calculated in draw
      y = base_y_offset.nil? ? (@position.y + @size.y - ((@choices.size - index) * 30) - @padding) : (base_y_offset + index * 30)

      RL::Rectangle.new(x: @position.x + @padding, y: y, width: @size.x - @padding * 2, height: 25)
    end
  end

  # Main game class
  class Game
    include YAML::Serializable

    class_property debug_mode : Bool = false

    @[YAML::Field(ignore: true)] # Runtime state
    property initialized : Bool = false
    property window_width : Int32
    property window_height : Int32
    property title : String
    property target_fps : Int32 = 60

    property current_scene_name : String? # For serialization
    @[YAML::Field(ignore: true)]
    property current_scene : Scene?

    property scenes : Hash(String, Scene) = {} of String => Scene
    property inventory : Inventory
    property dialogs : Array(Dialog) = [] of Dialog # Active dialogs; careful with serialization
    @[YAML::Field(ignore: true)] # Runtime state
    property running : Bool = false

    property cursor_texture_path : String? # For serialization
    @[YAML::Field(ignore: true)]
    property cursor_texture : RL::Texture2D?
    property default_cursor : RL::MouseCursor = RL::MouseCursor::Default

    # For YAML
    def initialize
      @window_width = 800 # Default
      @window_height = 600 # Default
      @title = "Game"      # Default
      @inventory = Inventory.new(RL::Vector2.new(x: 10, y: @window_height - 80)) # Initialize with a default
      @scenes = {} of String => Scene
      @dialogs = [] of Dialog
    end

    def initialize(@window_width : Int32, @window_height : Int32, @title : String)
      @inventory = Inventory.new(RL::Vector2.new(x: 10, y: @window_height - 80))
      @scenes = {} of String => Scene
      @dialogs = [] of Dialog
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
      # Reload assets and re-establish links
      @scenes.each_value &.after_yaml_deserialize(ctx)
      @inventory.after_yaml_deserialize(ctx)
      # Dialogs are tricky as they are often temporary.
      # If you save a game with an active dialog, its state (text, choices) would be saved.
      # However, the 'on_complete' and 'choice.action' Procs would be lost.
      # For simplicity, active dialogs might not be fully restored, or you might choose not to serialize them.
      # Here, we assume they are serialized if they were in the array.
      @dialogs.each &.after_yaml_deserialize(ctx)


      if path = @cursor_texture_path
        # `init` might not have been called yet if loading from editor
        # Ensure Raylib is initialized before loading textures
        # This is a bit tricky. For save/load in-game, Raylib is up.
        # For an editor, you load data then init Raylib.
        if RL.window_ready? # check if window is initialized
            load_cursor(path)
        end
      end

      if name = @current_scene_name
        @current_scene = @scenes[name]?
        # @current_scene.try &.enter # Be careful with calling enter automatically on load
      end

      # Re-initialize player reference in scenes if it's stored by name
      @scenes.each_value do |scene|
          if scene.player_name_for_serialization
              player_char = scene.get_character(scene.player_name_for_serialization)
              if player_char.is_a?(Player)
                  scene.player = player_char.as(Player)
              end
          end
      end
    end

    def init
      return if @initialized
      RL.init_window(@window_width, @window_height, @title)
      RL.set_target_fps(@target_fps)
      # Load cursor if path exists (moved from after_yaml_deserialize for editor loading)
      if path = @cursor_texture_path
          load_cursor(path)
      else
          RL.set_mouse_cursor(@default_cursor) # Ensure default cursor is set if no custom one
      end
      @initialized = true
    end

    def load_cursor(path : String)
      @cursor_texture_path = path # Store path
      @cursor_texture = RL.load_texture(path)
      RL.hide_cursor if @initialized # Hide only if window is up
    end

    def add_scene(scene : Scene)
      @scenes[scene.name] = scene
    end

    def change_scene(name : String)
      if new_scene = @scenes[name]?
        @current_scene.try &.exit
        @current_scene = new_scene
        @current_scene_name = name # For serialization
        new_scene.enter
      end
    end

    def show_dialog(dialog : Dialog)
      dialog.show
      @dialogs << dialog unless @dialogs.includes?(dialog)
    end

    def run
      init
      @running = true
      @current_scene.try &.enter # Enter initial scene

      while @running && !RL.close_window?
        update(RL.get_frame_time)
        draw
      end
      cleanup
    end

    def stop
      @running = false
    end

    private def update(dt : Float32)
      @current_scene.try &.update(dt)
      @inventory.update(dt)
      @dialogs.each(&.update(dt))
      @dialogs.reject! { |d| !d.visible }

      if RL::KeyboardKey::I.pressed?
        @inventory.visible = !@inventory.visible
      end
      if RL::KeyboardKey::F1.pressed?
        Game.debug_mode = !Game.debug_mode
      end
      update_cursor
    end

    private def draw
      RL.begin_drawing
      RL.clear_background(RL::BLACK)
      @current_scene.try &.draw
      @inventory.draw
      @dialogs.each(&.draw)
      if cursor = @cursor_texture
        mouse_pos = RL.get_mouse_position
        RL.draw_texture_v(cursor, mouse_pos, RL::WHITE)
      end
      if Game.debug_mode
        RL.draw_text("FPS: #{RL.get_fps}", 10, 10, 20, RL::GREEN)
        mouse_pos = RL.get_mouse_position
        RL.draw_text("Mouse: #{mouse_pos.x.to_i}, #{mouse_pos.y.to_i}", 10, 35, 20, RL::GREEN)
      end
      RL.end_drawing
    end

    private def update_cursor
      return if @cursor_texture # Using custom texture cursor
      mouse_pos = RL.get_mouse_position
      if scene = @current_scene
        if hotspot = scene.get_hotspot_at(mouse_pos)
          case hotspot.cursor_type
          when Hotspot::CursorType::Hand          then RL.set_mouse_cursor(RL::MouseCursor::PointingHand)
          when Hotspot::CursorType::Default       then RL.set_mouse_cursor(RL::MouseCursor::Default)
          # Add other cursor types if needed
          else RL.set_mouse_cursor(RL::MouseCursor::Crosshair) # Default for other types for now
          end
        else
          RL.set_mouse_cursor(@default_cursor)
        end
      else
        RL.set_mouse_cursor(@default_cursor)
      end
    end

    private def cleanup
      @scenes.each_value do |scene|
        if bg = scene.background
          RL.unload_texture(bg)
        end
        scene.objects.each do |obj|
          if obj.is_a?(AnimatedSprite) && (tex = obj.as(AnimatedSprite).texture)
            RL.unload_texture(tex)
          end
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
      RL.close_window if @initialized && RL.window_ready?
    end

    # Save and Load Game Logic
    def save_game(filepath : String)
      begin
        File.write(filepath, self.to_yaml)
        puts "Game saved to #{filepath}"
      rescue ex
        STDERR.puts "Error saving game: #{ex}"
      end
    end

    def self.load_game(filepath : String) : Game?
      begin
        yaml_string = File.read(filepath)
        game = Game.from_yaml(yaml_string)
        # `after_yaml_deserialize` is called automatically by `from_yaml` for each object.
        # Additional top-level re-linking or setup can be done here if needed.
        # Crucially, Raylib (window, graphics context) needs to be initialized *after* loading
        # data if this is used for an editor or starting the game from a file.
        # If loading mid-game, Raylib is already up.
        # The `game.init` call will handle Raylib initialization and texture loading for cursor
        # if `cursor_texture_path` was loaded.
        # Other textures are reloaded in their respective `after_yaml_deserialize` methods,
        # but they assume Raylib is ready. This order is important.

        # For loading a game, it's typical to initialize raylib *then* load textures.
        # The `after_yaml_deserialize` methods for objects with textures should be
        # robust enough or called after `game.init`.

        # A simple approach: init raylib if not already, then ensure textures are loaded.
        # However, `from_yaml` already calls `after_yaml_deserialize`.
        # This means textures might try to load before `RL.init_window`.
        # This is a classic chicken-and-egg.
        # One way:
        # 1. Load YAML string.
        # 2. Parse into a raw YAML structure (not directly into objects yet).
        # 3. Initialize Raylib.
        # 4. Then, fully deserialize from the raw structure into game objects, allowing textures to load.
        # OR, ensure `after_yaml_deserialize` only stores paths, and a separate `game.load_all_assets` is called after `game.init`.

        # For now, the `after_yaml_deserialize` in `Game` calls `init` if cursor path is set,
        # and other `after_yaml_deserialize` methods will load their textures.
        # This implies that if loading a full game state (not just editor data),
        # you'd call `Game.load_game` and then `game.run` which calls `game.init`.
        # This is a bit tangled. Let's assume for now that `RL.window_ready?` checks in
        # `after_yaml_deserialize` are sufficient.

        puts "Game loaded from #{filepath}"
        return game
      rescue ex
        STDERR.puts "Error loading game: #{ex}"
        return nil
      end
    end

  end

  # Sprite animation for characters/objects
  class AnimatedSprite < GameObject
    property texture_path : String? # Store path
    @[YAML::Field(ignore: true)]
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

    # For YAML
    def initialize
      super(RL::Vector2.new, RL::Vector2.new) # Default position and size
      @frame_width = 0
      @frame_height = 0
      @frame_count = 0
    end

    def initialize(position : RL::Vector2, @frame_width : Int32, @frame_height : Int32, @frame_count : Int32)
      scaled_width = @frame_width * @scale
      scaled_height = @frame_height * @scale
      super(position, RL::Vector2.new(x: scaled_width, y: scaled_height))
    end

    # Override to update size based on scale after deserialization
    def after_yaml_deserialize(ctx : YAML::ParseContext)
      super(ctx) # Call parent's after_yaml_deserialize
      if path = @texture_path
          if RL.window_ready? # Ensure Raylib is initialized
            load_texture(path)
          end
      end
      # Update size based on potentially deserialized scale and frame dimensions
      @size = RL::Vector2.new(x: @frame_width * @scale, y: @frame_height * @scale)
    end

    def load_texture(path : String)
      @texture_path = path
      @texture = RL.load_texture(path)
    end

    def play
      @playing = true
      # @current_frame = 0 # Keep current frame if already playing, reset if new play command
      @frame_timer = 0.0
    end

    def stop
      @playing = false
    end

    def update(dt : Float32)
      return unless @playing && @active
      @frame_timer += dt
      if @frame_timer >= @frame_speed
        @frame_timer = 0.0
        @current_frame += 1
        if @current_frame >= @frame_count # This should be start_frame + frame_count for specific animations
          if @loop
            @current_frame = 0 # Or specific start_frame of current animation
          else
            @current_frame = @frame_count - 1 # Or start_frame + frame_count - 1
            @playing = false
          end
        end
      end
    end

    def draw
      return unless @visible
      return unless tex = @texture
      source_rect = RL::Rectangle.new(
        x: (@current_frame * @frame_width).to_f, # current_frame should be offset by anim_data.start_frame
        y: 0.0,
        width: @frame_width.to_f,
        height: @frame_height.to_f
      )
      dest_rect = RL::Rectangle.new(
        x: @position.x,
        y: @position.y,
        width: @frame_width * @scale,
        height: @frame_height * @scale
      )
      RL.draw_texture_pro(tex, source_rect, dest_rect, RL::Vector2.new(x: 0, y: 0), 0.0, RL::WHITE)
    end
  end

  # Particle effect for visual feedback (Skipping YAML for Particles for brevity, often transient)
  class Particle
    property position : RL::Vector2
    property size : Float64 = 0.0
    property velocity : RL::Vector2
    property color : RL::Color
    property lifetime : Float64
    property age : Float64 = 0.0

    def initialize(@position : RL::Vector2, @velocity : RL::Vector2, @color : RL::Color,
      @size : Float64, @lifetime : Float64)
    end
    def update(dt : Float32)
      @age += dt
      @position.x += @velocity.x * dt
      @position.y += @velocity.y * dt
    end
    def draw
      alpha = (1.0 - @age / @lifetime) * 255
      color = RL::Color.new(r: @color.r, g: @color.g, b: @color.b, a: alpha.to_u8.clamp(0, 255))
      RL.draw_circle(@position.x.to_i, @position.y.to_i, @size, color)
    end
    def alive? : Bool; @age < @lifetime; end
  end

  class ParticleSystem < GameObject
    # Not making this YAML::Serializable for now, as particles are often dynamic
    # and not part of persistent game state unless specifically designed to be.
    property particles : Array(Particle) = [] of Particle
    property emit_rate : Float64 = 10.0
    property emit_timer : Float64 = 0.0
    property particle_lifetime : Float64 = 1.0
    property particle_size : Float64 = 3.0
    property particle_speed : Float64 = 100.0
    property particle_color : RL::Color = RL::WHITE
    property emitting : Bool = true

    def initialize(position : RL::Vector2)
      super(position, RL::Vector2.new(x: 0, y: 0)) # Zero size, it's an emitter
    end

    def emit_particle
      angle = Random.rand * Math::PI * 2
      vel_x = Math.cos(angle) * @particle_speed * (0.5 + Random.rand * 0.5)
      vel_y = Math.sin(angle) * @particle_speed * (0.5 + Random.rand * 0.5)
      velocity = RL::Vector2.new(x: vel_x.to_f, y: vel_y.to_f)
      p_size = @particle_size * (0.5 + Random.rand * 0.5)
      p_lifetime = @particle_lifetime * (0.5 + Random.rand * 0.5)
      @particles << Particle.new(@position, velocity, @particle_color, p_size.to_f, p_lifetime.to_f)
    end

    def update(dt : Float32)
      if @emitting
        @emit_timer += dt
        while @emit_timer >= (1.0 / @emit_rate)
          emit_particle
          @emit_timer -= (1.0 / @emit_rate)
        end
      end
      @particles.each(&.update(dt))
      @particles.reject! { |p| !p.alive? }
    end
    def draw; @particles.each(&.draw); end
  end
end

# Extension module for Characters
# ================================
module PointClickEngine
  # ... (Character related enums: CharacterState, Direction) ...
  enum CharacterState; Idle; Walking; Talking; Interacting; Thinking; end
  enum Direction; Left; Right; Up; Down; end

  module Talkable
      # Trait for objects that can be talked to by characters.
      # Could hold common dialogue initiation logic or properties.
      # For now, it's a marker.
  end

  abstract class Character < GameObject
    property name : String
    property description : String
    property state : CharacterState = CharacterState::Idle
    property direction : Direction = Direction::Right
    property walking_speed : Float32 = 100.0

    @[YAML::Field(converter: RaylibYAMLConverters::Vector2Converter, nilable: true)]
    property target_position : RL::Vector2?

    property dialogue_system_data : CharacterDialogue? # Serialize the data container
    @[YAML::Field(ignore: true)]
    delegate dialogue_system, to: @dialogue_system_data # For runtime access

    property sprite_data : AnimatedSprite? # Serialize the data container
    @[YAML::Field(ignore: true)]
    delegate sprite, to: @sprite_data # For runtime access

    property current_animation : String = "idle"
    property animations : Hash(String, AnimationData) = {} of String => AnimationData

    property conversation_partner_name : String? # For serialization
    @[YAML::Field(ignore: true)]
    property conversation_partner : Character?


    struct AnimationData
      include YAML::Serializable
      property start_frame : Int32
      property frame_count : Int32
      property frame_speed : Float32
      property loop : Bool

      def initialize(@start_frame : Int32 = 0, @frame_count : Int32 = 1,
                     @frame_speed : Float32 = 0.1, @loop : Bool = true)
      end
    end

    # For YAML
    def initialize
      super(RL::Vector2.new, RL::Vector2.new) # Default position and size
      @name = ""
      @description = ""
      @animations = {} of String => AnimationData
      @dialogue_system_data = CharacterDialogue.new(self) # Initialize for safety
    end

    def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
      super(position, size)
      @description = "A character named #{@name}"
      @dialogue_system_data = CharacterDialogue.new(self)
      @animations = {} of String => AnimationData
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
      super(ctx) # Call GameObject's after_yaml_deserialize
      @sprite_data.try &.after_yaml_deserialize(ctx)
      @dialogue_system_data.try &.character = self # Re-link self to dialogue system
      # Re-linking conversation_partner would need a Game-level pass after all characters are loaded
      # For now, this will remain nil unless explicitly set post-load.
      # Play initial animation if needed
      play_animation(@current_animation, force_restart: false)
    end

    def load_spritesheet(path : String, frame_width : Int32, frame_height : Int32)
      @sprite_data = AnimatedSprite.new(@position, frame_width, frame_height, 1) # Base 1 frame initially
      @sprite_data.not_nil!.load_texture(path)
      @sprite_data.not_nil!.scale = calculate_scale(frame_width, frame_height)
      # Update character's own size based on the scaled sprite
      @size = RL::Vector2.new(x: frame_width * @sprite_data.not_nil!.scale, y: frame_height * @sprite_data.not_nil!.scale)
      @sprite_data.not_nil!.size = @size # Ensure sprite's size reflects this too.
    end

    def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                      frame_speed : Float32 = 0.1, loop : Bool = true)
      @animations[name] = AnimationData.new(start_frame, frame_count, frame_speed, loop)
    end

    def play_animation(name : String, force_restart : Bool = true)
      return unless @animations.has_key?(name)
      return if !force_restart && @current_animation == name && @sprite_data.try(&.playing)


      @current_animation = name
      anim_data = @animations[name]

      if sprite = @sprite_data
        sprite.current_frame = anim_data.start_frame # This is the index within the spritesheet
        # The AnimatedSprite's frame_count should be the total frames in the sheet,
        # or it needs to understand animation segments.
        # Let's adjust AnimatedSprite to better handle this:
        # We'll make AnimatedSprite take a start_frame for an animation segment.
        # OR, AnimatedSprite's current_frame refers to the visual frame of the animation,
        # and its draw method uses anim_data.start_frame + sprite.current_frame.

        # Simpler: AnimatedSprite.current_frame is index INTO the current animation strip.
        # The draw call in AnimatedSprite needs to use (animation_start_frame_on_sheet + current_anim_frame_index) * frame_width.
        # For now, let's assume AnimatedSprite.current_frame is the absolute frame on the spritesheet.
        # And AnimatedSprite.frame_count is the number of frames for THIS specific animation.
        # This means AnimatedSprite's texture drawing logic needs adjustment if `current_frame` is 0-indexed for the *animation* vs the *spritesheet*.

        # Current `AnimatedSprite` draw logic: `x: @current_frame * @frame_width`
        # This implies `current_frame` should be the actual frame index on the spritesheet.
        # So, when playing an animation, we set `sprite.current_frame_offset = anim_data.start_frame`
        # and `sprite.num_anim_frames = anim_data.frame_count`.
        # Then `AnimatedSprite` update would do: `display_frame = @current_frame_offset + @anim_timer_frame`

        # Let's refine `AnimatedSprite` slightly for this:
        # Add `animation_start_offset` to `AnimatedSprite`
        # `sprite.animation_start_offset = anim_data.start_frame`
        # `sprite.frame_count = anim_data.frame_count` (frames in this specific animation)
        # `sprite.current_animation_frame = 0` (frame index for the current animation, 0 to frame_count-1)
        # Then in `AnimatedSprite.draw`, `source_rect.x = (@animation_start_offset + @current_animation_frame) * @frame_width`

        # For now, keeping it simple as per original `AnimatedSprite`:
        # `sprite.current_frame` is the direct frame number in the spritesheet.
        # `sprite.frame_count` must be the total frames in the spritesheet if `current_frame` is to loop through all of them.
        # This means `Character.play_animation` should manage `AnimatedSprite.current_frame` and its looping
        # relative to `anim_data.start_frame` and `anim_data.frame_count`.

        # Re-thinking: `AnimatedSprite` should be dumber. `Character` tells it what range of frames to play.
        # Let's add `min_frame` and `max_frame` to `AnimatedSprite` that `Character` sets.
        if sprite = @sprite_data
            sprite.current_frame = anim_data.start_frame # Start at the first frame of the animation
            # We need to modify AnimatedSprite's update to respect this start_frame
            # and loop within anim_data.frame_count
            # Let's keep AnimatedSprite as is for now and manage this in Character or a dedicated AnimationPlayer
            # For now, we assume AnimatedSprite.play will use its existing properties correctly if set.
            # This part is a bit tricky with the current AnimatedSprite design.
            # A quick fix:
            # sprite.current_frame = anim_data.start_frame
            # sprite.frame_count = anim_data.frame_count  <-- This is the problem. AnimatedSprite expects this to be total frames in sheet for its logic.

            # The cleanest way is for AnimatedSprite to handle segments.
            # Add to AnimatedSprite:
            #   property animation_start_frame_index : Int32 = 0
            #   property animation_num_frames : Int32 = 1
            # And modify its update/draw to use these.
            # For now, this is a TODO for perfect animation segment handling.
            # We'll assume `sprite.frame_count` is set to the total sheet frames,
            # and `Character` is responsible for more complex animation logic if needed,
            # or AnimatedSprite is only ever used for single-strip animations.
            # Given `AnimatedSprite` has `loop` and `playing`, it should manage its own progression.
            # The `play_animation` in Character should set the *bounds* for AnimatedSprite.
            #
            # Let's assume `AnimatedSprite` is for a *single strip* for now, and each character animation
            # might require a *different AnimatedSprite instance* or re-init of its texture/frame_count.
            # The current design `sprite.frame_count = anim_data.frame_count` makes `AnimatedSprite` only play that segment.
            sprite.frame_count = anim_data.frame_count # Number of frames in THIS animation
            sprite.frame_speed = anim_data.frame_speed
            sprite.loop = anim_data.loop
            sprite.play # Resets current_frame to 0 within its context
        end
      end
    end

    def walk_to(target : RL::Vector2)
      @target_position = target
      @state = CharacterState::Walking
      if target.x < @position.x
        @direction = Direction::Left
        play_animation("walk_left") if @animations.has_key?("walk_left")
      else
        @direction = Direction::Right
        play_animation("walk_right") if @animations.has_key?("walk_right")
      end
    end

    def stop_walking
      @target_position = nil
      @state = CharacterState::Idle
      # Determine idle animation based on direction
      base_idle_anim = @direction == Direction::Left ? "idle_left" : "idle_right"
      play_animation(base_idle_anim) if @animations.has_key?(base_idle_anim)
      play_animation("idle") if !@animations.has_key?(base_idle_anim) && @animations.has_key?("idle")
    end

    def say(text : String, &block : -> Nil)
      @state = CharacterState::Talking
      play_animation("talk") if @animations.has_key?("talk")

      if dialogue = @dialogue_system_data
        dialogue.say(text) do
          @state = CharacterState::Idle
          stop_walking # Go to idle animation
          block.call
        end
      else
          block.call # No dialogue system, call block immediately
      end
    end

    def ask(question : String, choices : Array(Tuple(String, Proc(Nil))))
        @state = CharacterState::Talking
        play_animation("talk") if @animations.has_key?("talk")

        if dialogue = @dialogue_system_data
            dialogue.ask(question, choices) do # The on_complete for the whole dialog
                @state = CharacterState::Idle
                stop_walking # Go to idle animation
                # The block passed to `ask` is not directly used here,
                # individual choice actions handle logic.
                # If there was an overall on_complete for the ask itself, it would go here.
            end
        end
    end


    def update(dt : Float32)
      return unless @active
      update_movement(dt)
      update_animation(dt) # This should call sprite_data.update
      @dialogue_system_data.try &.update(dt)
    end

    def draw
      return unless @visible
      @sprite_data.try &.draw
      @dialogue_system_data.try &.draw # Draw character's current dialog bubble

      if Game.debug_mode
        RL.draw_text(@name, @position.x.to_i, (@position.y - 25).to_i, 16, RL::WHITE)
        if @target_position
            RL.draw_line_v(@position, @target_position.not_nil!, RL::GREEN)
            RL.draw_circle_v(@target_position.not_nil!, 5.0, RL::GREEN)
        end
      end
    end

    abstract def on_interact(interactor : Character)
    abstract def on_look
    abstract def on_talk

    private def update_movement(dt : Float32)
      return unless @state == CharacterState::Walking
      return unless target = @target_position

      direction_vec = RL::Vector2.new(x: target.x - @position.x, y: target.y - @position.y)
      distance = Math.sqrt(direction_vec.x ** 2 + direction_vec.y ** 2).to_f

      if distance < 5.0 # Arrival threshold
        @position = target # Snap to target
        stop_walking
        # TODO: Here you would trigger any pending interaction if walk_to_and_interact was called
        # For example, by checking a `pending_interaction_target` property.
        return
      end

      # Normalize and move
      normalized_dir_x = direction_vec.x / distance
      normalized_dir_y = direction_vec.y / distance

      @position.x += normalized_dir_x * @walking_speed * dt
      @position.y += normalized_dir_y * @walking_speed * dt

      # Update sprite position if it's separate (it's linked via character.position now)
      @sprite_data.try &.position = @position
    end

    private def update_animation(dt : Float32)
        if @sprite_data && @animations.has_key?(@current_animation)
            anim_data = @animations[@current_animation]
            current_sprite = @sprite_data.not_nil!

            # This logic needs to be inside AnimatedSprite or a dedicated AnimationPlayer.
            # For now, a simplified Character-driven animation update:
            if current_sprite.playing
                current_sprite.frame_timer += dt
                if current_sprite.frame_timer >= current_sprite.frame_speed
                    current_sprite.frame_timer = 0.0

                    # current_sprite.current_frame is the frame *within the animation strip*
                    # The actual frame on the spritesheet is anim_data.start_frame + current_sprite.current_frame

                    # Let's assume AnimatedSprite's current_frame is its internal animation frame (0 to anim_data.frame_count -1)
                    # And its draw method uses: (anim_data.start_frame + current_sprite.current_frame)
                    # This requires AnimatedSprite to be smarter or Character to pass more info.

                    # For the current AnimatedSprite: current_frame is absolute sheet index.
                    # frame_count is number of frames FOR THIS ANIMATION.
                    # So, it should advance from anim_data.start_frame up to anim_data.start_frame + anim_data.frame_count - 1.

                    current_sprite.current_frame += 1 # Advance frame

                    # Check if animation segment ended
                    if current_sprite.current_frame >= anim_data.start_frame + anim_data.frame_count
                        if anim_data.loop
                            current_sprite.current_frame = anim_data.start_frame # Loop back
                        else
                            current_sprite.current_frame = anim_data.start_frame + anim_data.frame_count - 1 # Stay on last frame
                            current_sprite.stop # Stop playing
                            # Potentially transition to idle or another state
                            if @state != CharacterState::Talking # Don't override talking animation end
                                stop_walking # Default to idle after non-looping animation if walking
                            end
                        end
                    end
                end
            end
        end
    end


    private def calculate_scale(frame_width : Int32, frame_height : Int32) : Float32
      return 1.0 if frame_width == 0 || frame_height == 0 # Avoid division by zero
      # @size is the desired character display size on screen
      scale_x = @size.x / frame_width
      scale_y = @size.y / frame_height
      Math.min(scale_x, scale_y) # Maintain aspect ratio, fit within @size
    end
  end

  class Player < Character
    property inventory_access : Bool = true
    property movement_enabled : Bool = true

    @[YAML::Field(ignore: true)] # Callback, not easily serializable
    property interaction_callback : Tuple(Hotspot | Character, Symbol)? # e.g. {hotspot_obj, :on_click} or {char_obj, :on_interact}

    # For YAML
    def initialize
      super() # Calls Character's YAML initializer
    end

    def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
      super(name, position, size)
      setup_default_animations # This should be called after potential deserialization too
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        setup_default_animations # Ensure animations are set up after loading
    end

    def on_interact(interactor : Character)
      # Player is being interacted with. Could have specific lines.
      say("Someone's trying to interact with me, #{@name}.") {}
    end
    def on_look
      say("That's me, #{@name}.") {}
    end
    def on_talk
      say("I'd rather talk to someone else if I'm initiating.") {}
    end

    def handle_click(target_pos : RL::Vector2, scene : Scene)
        return unless @movement_enabled
        return if @state == CharacterState::Talking # Don't interrupt self

        @interaction_callback = nil # Clear previous pending interaction

        # Determine interaction target
        clicked_on = scene.get_hotspot_at(target_pos) || scene.get_character_at(target_pos)

        if clicked_on
            interaction_target = clicked_on
            # Simplified: walk to the object's position.
            # More complex: walk to an "interaction point" near the object.
            walk_to(interaction_target.position)

            # Set up what to do upon arrival
            # This needs to be checked in `update_movement` when destination is reached.
            case interaction_target
            when Hotspot
                @interaction_callback = {interaction_target, :on_click}
            when Character
                @interaction_callback = {interaction_target, :on_interact} # Or :on_talk
            end
        else
            # Simple movement
            walk_to(target_pos)
        end
    end

    # Override update_movement to handle interaction callback
    private def update_movement(dt : Float32)
        previous_state = @state
        super(dt) # Call Character's update_movement

        # If super changed state from Walking to Idle (meaning arrived)
        if previous_state == CharacterState::Walking && @state == CharacterState::Idle
            if callback_data = @interaction_callback
                target_object, action_method = callback_data
                case target_object
                when Hotspot
                    target_object.on_click.try &.call # Hotspot's on_click Proc
                when Character
                    # Player interacting with an NPC
                    if action_method == :on_interact
                        target_object.on_interact(self) # NPC's on_interact method
                    elsif action_method == :on_talk
                         target_object.on_talk # NPC's on_talk method
                    end
                end
                @interaction_callback = nil # Clear after execution
            end
        end
    end


    private def setup_default_animations
      # Ensure these are not re-added if already present from serialization
      unless @animations.has_key?("idle")
        add_animation("idle", 0, 1, 1.0, true) # Default generic idle
      end
      unless @animations.has_key?("idle_right")
        add_animation("idle_right", 0, 1, 1.0, true) # Assumes frame 0 is idle right
      end
      unless @animations.has_key?("idle_left")
        add_animation("idle_left", 1, 1, 1.0, true) # Assumes frame 1 is idle left (example)
      end
      unless @animations.has_key?("walk_right")
        add_animation("walk_right", 2, 4, 0.15, true) # e.g. frames 2-5
      end
      unless @animations.has_key?("walk_left")
        add_animation("walk_left", 6, 4, 0.15, true) # e.g. frames 6-9
      end
      unless @animations.has_key?("talk")
        add_animation("talk", 10, 2, 0.3, true) # e.g. frames 10-11
      end
      play_animation("idle_right") # Default starting animation
    end
  end

  class NPC < Character
    property dialogues : Array(String) = [] of String
    property current_dialogue_index : Int32 = 0
    property can_repeat_dialogues : Bool = true
    property interaction_distance : Float32 = 50.0 # TODO: Use this for interaction checks

    property ai_behavior_data : NPCBehavior? # For serialization
    @[YAML::Field(ignore: true)]
    delegate ai_behavior, to: @ai_behavior_data

    property mood : NPCMood = NPCMood::Neutral

    enum NPCMood; Friendly; Neutral; Hostile; Sad; Happy; Angry; end

    # For YAML
    def initialize
      super() # Calls Character's YAML initializer
      @dialogues = [] of String
    end

    def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
      super(name, position, size)
      @dialogues = [] of String
      setup_default_animations # Call after super and property init
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        setup_default_animations # Ensure animations are set up after loading
        @ai_behavior_data.try &.after_yaml_deserialize(ctx, self) # Pass self to AI behavior
        update_mood_animation # Apply mood animation
    end

    def add_dialogue(text : String); @dialogues << text; end
    def set_dialogues(dialogues : Array(String)); @dialogues = dialogues; end

    def on_interact(interactor : Character)
      return if @state == CharacterState::Talking
      face_character(interactor)
      start_conversation(interactor)
    end
    def on_look
      # Player is looking at NPC. NPC says their description or a specific "looked_at" line.
      # For simplicity, let the player's say command handle this, or NPC can say it via game.show_dialog
      # Game.instance.show_dialog(Dialog.new(@description, ...))
      # Or, if the NPC should speak it:
      say(@description){}
    end
    def on_talk
      # Player initiated talk. Similar to on_interact for NPCs.
      return if @state == CharacterState::Talking
      # Assume interactor is the player, which might be Game.instance.player
      # For now, don't require interactor if just starting talk.
      start_conversation(nil) # No specific interactor if just 'on_talk'
    end

    def set_ai_behavior(behavior : NPCBehavior); @ai_behavior_data = behavior; end
    def set_mood(mood : NPCMood); @mood = mood; update_mood_animation; end

    def update(dt : Float32)
      super(dt) # Character update (movement, base animation)
      @ai_behavior_data.try &.update(self, dt) # AI behavior update
    end

    private def face_character(character : Character)
      if character.position.x < @position.x
        @direction = Direction::Left
        play_animation("idle_left", force_restart: false) if @animations.has_key?("idle_left")
      else
        @direction = Direction::Right
        play_animation("idle_right", force_restart: false) if @animations.has_key?("idle_right")
      end
    end
    private def start_conversation(interactor : Character?)
      return if @dialogues.empty?
      dialogue_text = @dialogues[@current_dialogue_index]
      @conversation_partner = interactor
      @conversation_partner_name = interactor.try(&.name)

      say(dialogue_text) { advance_dialogue }
    end
    private def advance_dialogue
      @current_dialogue_index += 1
      if @current_dialogue_index >= @dialogues.size
        @current_dialogue_index = @can_repeat_dialogues ? 0 : (@dialogues.size - 1)
      end
      @conversation_partner = nil # End conversation partner link after dialog line
      @conversation_partner_name = nil
    end
    private def update_mood_animation
      mood_anim = case @mood
                  when NPCMood::Happy then "happy"
                  when NPCMood::Sad   then "sad"
                  when NPCMood::Angry then "angry"
                  else "idle" # Default to idle or specific directional idle
                  end

      # If directional idle exists for current direction, prefer that over generic "idle"
      directional_idle = if mood_anim == "idle"
          @direction == Direction::Left ? "idle_left" : "idle_right"
      else
          nil # Not an idle mood, so no directional override needed for "happy", "sad", etc.
      end

      if directional_idle && @animations.has_key?(directional_idle)
          play_animation(directional_idle, force_restart: false)
      elsif @animations.has_key?(mood_anim)
          play_animation(mood_anim, force_restart: false)
      end
    end
    private def setup_default_animations
      # Default animations for NPC - customize as needed
      # Assumes spritesheet layout: idle_right, idle_left, talk_right, talk_left, etc.
      unless @animations.has_key?("idle_right")
        add_animation("idle_right", 0, 1, 1.0, true)
      end
      unless @animations.has_key?("idle_left")
        add_animation("idle_left", 1, 1, 1.0, true) # Example: frame 1 for facing left
      end
      unless @animations.has_key?("walk_right")
        add_animation("walk_right", 2, 2, 0.25, true) # Example
      end
      unless @animations.has_key?("walk_left")
        add_animation("walk_left", 4, 2, 0.25, true) # Example
      end
      unless @animations.has_key?("talk") # Generic talk, or make directional talk_right/talk_left
        add_animation("talk", 6, 2, 0.3, true) # Example
      end
      unless @animations.has_key?("happy")
        add_animation("happy", 8, 2, 0.5, true) # Example
      end
      # ... other moods
      play_animation("idle_right") # Default starting animation
    end
  end

  class CharacterDialogue
    include YAML::Serializable # Make it serializable

    @[YAML::Field(ignore: true)] # This will be re-linked
    property character : Character
    property current_dialog_data : Dialog? # Serialize the dialog data if active
    @[YAML::Field(ignore: true)]
    delegate current_dialog, to: @current_dialog_data

    @[YAML::Field(converter: RaylibYAMLConverters::Vector2Converter)]
    property dialog_offset : RL::Vector2 = RL::Vector2.new(x: 0, y: -100) # Offset from character's head

    # For YAML - character needs to be re-linked in Character's after_yaml_deserialize
    def initialize(@character : Character)
    end

    # YAML might create an instance without a character temporarily
    def initialize
        # This is a bit problematic. CharacterDialogue needs a Character.
        # We'll rely on Character's after_yaml_deserialize to fix the `character` reference.
        # For safety, let's use a placeholder or make `character` nilable if that's feasible.
        # For now, assume `character` will be non-nil after full deserialization.
        # This dummy character is just to satisfy the non-nilable type during init.
        @character = Player.new # Dummy, will be replaced
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
        @current_dialog_data.try &.after_yaml_deserialize(ctx)
        # The `character` property must be re-assigned by the owning Character object after it's deserialized.
    end

    def say(text : String, &on_complete : -> Nil)
      dialog_pos, dialog_size = calculate_dialog_rect(text)

      @current_dialog_data = Dialog.new(text, dialog_pos, dialog_size)
      @current_dialog_data.not_nil!.character_name = @character.name
      @current_dialog_data.not_nil!.on_complete = on_complete # This Proc won't survive serialization
      Game.instance.show_dialog(@current_dialog_data.not_nil!) # Use game instance to manage dialogs
    end

    def ask(question : String, choices : Array(Tuple(String, Proc(Nil))), &on_overall_complete : -> Nil)
      dialog_pos, dialog_size = calculate_dialog_rect(question, choices.size)

      @current_dialog_data = Dialog.new(question, dialog_pos, dialog_size)
      @current_dialog_data.not_nil!.character_name = @character.name

      choices.each do |choice_text, action|
        @current_dialog_data.not_nil!.add_choice(choice_text) do
          action.call
          # on_overall_complete.call # This should be called when the dialog itself is hidden
        end
      end
      # The main on_complete for the dialog (after any choice is made and it hides)
      @current_dialog_data.not_nil!.on_complete = on_overall_complete

      Game.instance.show_dialog(@current_dialog_data.not_nil!)
    end

    private def calculate_dialog_rect(text : String, num_choices : Int = 0) : Tuple(RL::Vector2, RL::Vector2)
        # Position relative to character, clamped to screen
        game = Game.instance # Assuming Game.instance is available
        screen_w = game.window_width
        screen_h = game.window_height

        # Basic size estimation
        dialog_w = (text.size * 8).clamp(200, screen_w - 20).to_f # Rough width
        dialog_h = 80.0 + (num_choices * 30) # Base height + choices

        # Position above character
        pos_x = @character.position.x + @dialog_offset.x - (dialog_w / 2)
        pos_y = @character.position.y + @dialog_offset.y - dialog_h

        # Clamp to screen
        pos_x = pos_x.clamp(10.0, screen_w - dialog_w - 10.0)
        pos_y = pos_y.clamp(10.0, screen_h - dialog_h - 10.0)

        return RL::Vector2.new(x: pos_x, y: pos_y), RL::Vector2.new(x: dialog_w, y: dialog_h)
    end


    def update(dt : Float32)
      # Dialogs are now managed by the Game's @dialogs array for update and draw.
      # This CharacterDialogue class is more for initiating dialogs tied to this character.
      # If current_dialog_data is set, it means this character is 'speaking'.
      # We need to clear it if the game's dialog instance is no longer visible.
      if cd = @current_dialog_data
        unless cd.visible # Check if the dialog is still active in the game
          @current_dialog_data = nil
        end
      end
    end

    def draw
      # Dialogs are drawn by the Game's main draw loop from its @dialogs array.
      # This draw method is not strictly necessary if Game handles all dialog drawing.
      # @current_dialog_data.try &.draw
    end
  end


  abstract class NPCBehavior
    abstract def update(npc : NPC, dt : Float32)
    # Called after YAML deserialization, npc reference might be needed
    def after_yaml_deserialize(ctx : YAML::ParseContext, npc : NPC); end
  end

  class PatrolBehavior < NPCBehavior
    include YAML::Serializable
    @[YAML::Field(converter: RaylibYAMLConverters::Vector2ConverterArrayConverter)] # Custom converter for Array(RL::Vector2)
    property waypoints : Array(RL::Vector2) = [] of RL::Vector2
    property current_waypoint_index : Int32 = 0
    property wait_time : Float32 = 2.0
    property current_wait_timer : Float32 = 0.0
    property patrol_speed : Float32 = 30.0

    # For YAML
    def initialize
        @waypoints = [] of RL::Vector2
    end
    def initialize(@waypoints : Array(RL::Vector2)); end

    def after_yaml_deserialize(ctx : YAML::ParseContext, npc : NPC)
        super(ctx, npc)
        # If npc was idle on load, and has waypoints, start patrolling
        if npc.state == CharacterState::Idle && !@waypoints.empty?
            npc.walking_speed = @patrol_speed
            npc.walk_to(@waypoints[@current_waypoint_index])
        end
    end

    def update(npc : NPC, dt : Float32)
      return if npc.state == CharacterState::Talking || @waypoints.empty?

      if npc.state == CharacterState::Idle # Arrived at waypoint or finished talking
        @current_wait_timer += dt
        if @current_wait_timer >= @wait_time
          @current_wait_timer = 0.0
          @current_waypoint_index = (@current_waypoint_index + 1) % @waypoints.size
          next_target = @waypoints[@current_waypoint_index]
          npc.walking_speed = @patrol_speed
          npc.walk_to(next_target)
        end
      elsif npc.state == CharacterState::Walking
        # Check if target matches current waypoint, if not, AI was overridden.
        # For simplicity, assume if it's walking, it's towards its AI target.
        # No specific action needed here, Character movement handles reaching target.
      end
    end
  end

  # Need a converter for Array(RL::Vector2) for PatrolBehavior
  module RaylibYAMLConverters
    struct Vector2ArrayConverter
      def self.to_yaml(array : Array(RL::Vector2), builder : YAML::Nodes::Builder)
        builder.sequence do |seq|
          array.each do |vec|
            seq.node do |node_builder|
              RaylibYAMLConverters::Vector2Converter.to_yaml(vec, node_builder)
            end
          end
        end
      end

      def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
        node.as_sequence.map do |item_node|
          RaylibYAMLConverters::Vector2Converter.from_yaml(ctx, item_node)
        end
      end
    end
  end


  class RandomWalkBehavior < NPCBehavior
    include YAML::Serializable
    @[YAML::Field(converter: RaylibYAMLConverters::RectangleConverter)]
    property bounds : RL::Rectangle
    property walk_interval : Float32 = 5.0
    property walk_timer : Float32 = 0.0
    property walk_distance : Float32 = 100.0

    # For YAML
    def initialize
        @bounds = RL::Rectangle.new # Default
    end
    def initialize(@bounds : RL::Rectangle); end

    def after_yaml_deserialize(ctx : YAML::ParseContext, npc : NPC)
        super(ctx, npc)
        @walk_timer = Random.rand(@walk_interval) # Randomize initial walk timer
    end

    def update(npc : NPC, dt : Float32)
      return if npc.state == CharacterState::Talking
      @walk_timer += dt
      if @walk_timer >= @walk_interval && npc.state == CharacterState::Idle
        angle = Random.rand * Math::PI * 2
        distance = Random.rand * @walk_distance
        new_x = npc.position.x + Math.cos(angle) * distance
        new_y = npc.position.y + Math.sin(angle) * distance
        # Clamp to bounds
        new_x = new_x.clamp(@bounds.x, @bounds.x + @bounds.width)
        new_y = new_y.clamp(@bounds.y, @bounds.y + @bounds.height)

        npc.walk_to(RL::Vector2.new(x: new_x.to_f, y: new_y.to_f))
        @walk_timer = 0.0
      end
    end
  end

  class Scene
    # (already defined, just adding character specific parts)
    property characters : Array(Character) = [] of Character

    # For serializing/deserializing player reference by name
    property player_name_for_serialization : String?
    @[YAML::Field(ignore: true)]
    property player : Player?

    def after_yaml_deserialize(ctx : YAML::ParseContext)
      super(ctx) # Call Scene's original after_yaml_deserialize
      @characters.each &.after_yaml_deserialize(ctx)

      # Re-link player
      if name = @player_name_for_serialization
      found_player = @characters.find { |char| char.name == name }.as?(Player)
          @player = found_player if found_player
      end

      # Re-link character conversation partners (needs all characters in all scenes to be loaded first,
      # so this is better done at the Game level after all scenes are deserialized)
      # For now, character.conversation_partner_name will be populated,
      # and a Game-level relink step would iterate characters and find their partners by name.
    end

    def add_character(character : Character)
      @characters << character unless @characters.includes?(character)
      add_object(character) unless @objects.includes?(character) # Also add to generic objects
    end

    def set_player(player : Player)
      @player = player
      @player_name_for_serialization = player.name # For serialization
      add_character(player) unless @characters.includes?(player)
    end

    def get_character_at(point : RL::Vector2) : Character?
      @characters.find { |c| c.active && c.contains_point?(point) && c != @player } # Don't target self with generic click
    end
    def get_character(name : String) : Character?
      @characters.find { |c| c.name == name }
    end
  end

  # Make Game a singleton for easier access from CharacterDialogue and other places if needed
  class Game
    @@instance : Game?

    def self.instance : Game
        raise "Game not initialized" unless @@instance
        @@instance.not_nil!
    end

    def initialize(@window_width : Int32, @window_height : Int32, @title : String)
      # ... (existing constructor code)
      @inventory = Inventory.new(RL::Vector2.new(x: 10, y: @window_height - 80))
      @scenes = {} of String => Scene
      @dialogs = [] of Dialog
      @@instance = self
    end

    # YAML constructor needs to also set instance
    def initialize # For YAML
      @window_width = 800
      @window_height = 600
      @title = "Game"
      @inventory = Inventory.new(RL::Vector2.new(x:10, y:520)) # Default inv
      @scenes = {} of String => Scene
      @dialogs = [] of Dialog
      @@instance = self
    end

    def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx) # Call original Game's after_yaml_deserialize
        @@instance = self # Ensure singleton instance is set after deserialization

        # Post-deserialization relinking for elements that span across scenes or need full game context
        # Example: Character conversation partners
        all_characters = Hash(String, Character).new
        @scenes.each_value do |scene|
            scene.characters.each { |char| all_characters[char.name] = char }
        end

        all_characters.each_value do |char|
            if partner_name = char.conversation_partner_name
                char.conversation_partner = all_characters[partner_name]?
            end
        end
    end

  end

end
