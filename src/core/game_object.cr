# Base GameObject and Drawable module for all game entities
#
# This module provides the foundation for all visual game objects in the engine.
# It defines common properties like position, size, and visibility, as well as
# essential methods for rendering and spatial queries.

require "raylib-cr"
require "yaml"
require "../utils/yaml_converters"

module PointClickEngine
  module Core
    # Module for objects that can be rendered on screen
    #
    # The Drawable module provides common properties and methods for all visual
    # game objects. Any class that includes this module can be positioned,
    # scaled, and rendered on screen.
    #
    # ## Properties
    # - `position` - World coordinates (x, y)
    # - `size` - Dimensions (width, height)
    # - `scale` - Scaling factor for rendering
    # - `visible` - Whether the object should be drawn
    #
    # ## Example
    # ```
    # class MyObject
    #   include Drawable
    #
    #   def draw
    #     return unless visible
    #     # Custom drawing code here
    #   end
    # end
    # ```
    module Drawable
      # Whether this object should be rendered
      property visible : Bool = true

      # World position of the object (x, y coordinates)
      property position : RL::Vector2 = RL::Vector2.new

      # Size of the object (width, height)
      property size : RL::Vector2 = RL::Vector2.new

      # Scaling factor applied during rendering (1.0 = normal size)
      property scale : Float32 = 1.0f32

      # Abstract method that must be implemented by including classes
      #
      # This method should contain the actual rendering logic for the object.
      # It will be called automatically during the rendering phase if the
      # object is visible.
      abstract def draw

      # Returns the bounding rectangle of this object
      #
      # The bounding rectangle defines the rectangular area occupied by this
      # object in world coordinates. This is commonly used for collision
      # detection and spatial queries.
      #
      # Returns a Rectangle with the object's position and size
      def bounds : RL::Rectangle
        RL::Rectangle.new(x: @position.x, y: @position.y, width: @size.x, height: @size.y)
      end

      # Checks if a point is inside this object's bounds
      #
      # Performs a point-in-rectangle test to determine if the given point
      # falls within this object's bounding area. Useful for click detection
      # and spatial queries.
      #
      # *point* - The point to test (world coordinates)
      #
      # Returns `true` if the point is inside the bounds, `false` otherwise
      #
      # ```
      # if my_object.contains_point?(mouse_position)
      #   puts "Object clicked!"
      # end
      # ```
      def contains_point?(point : RL::Vector2) : Bool
        bounds = self.bounds
        point.x >= bounds.x &&
          point.x <= bounds.x + bounds.width &&
          point.y >= bounds.y &&
          point.y <= bounds.y + bounds.height
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        # Override in subclasses to reload assets
      end

      def draw_at_screen_pos(screen_pos : RL::Vector2)
        if engine = Core::Engine.instance
          if dm = engine.display_manager
            game_pos = dm.screen_to_game(screen_pos)
            # Draw at game_pos - implement in subclasses
          end
        end
      end

      def show
        @visible = true
      end

      def hide
        @visible = false
      end

      def toggle_visibility
        @visible = !@visible
      end
    end

    # Base class for all game objects
    abstract class GameObject
      include Drawable

      property active : Bool = true

      def initialize
        @position = RL::Vector2.new
        @size = RL::Vector2.new
      end

      def initialize(@position : RL::Vector2, @size : RL::Vector2)
      end

      abstract def update(dt : Float32)
    end
  end
end
