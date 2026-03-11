# ActionOverlayManager - Manages visual overlays for action sequences
# Handles sprites, backgrounds, and other visual elements during sequences

require "../graphics/effects/object_effects/glow"

module PointClickEngine
  module Actions
    # Sprite data for sequence rendering
    struct OverlaySprite
      property path : String
      property position : Raylib::Vector2
      property scale : Float32
      property glow : Bool
      property glow_color : Raylib::Color?
      property alpha : Float32 = 1.0f32
      property start_position : Raylib::Vector2?

      def initialize(@path : String, @position : Raylib::Vector2, @scale : Float32 = 1.0f32,
                     @glow : Bool = false, @glow_color : Raylib::Color? = nil)
        @start_position = @position.dup
      end
    end

    # Manages visual overlays for action sequences
    class ActionOverlayManager
      # Sprites for rendering
      @sprites : Hash(String, OverlaySprite) = {} of String => OverlaySprite

      # Current background path and loaded texture
      @background : String?
      @background_texture : Raylib::Texture2D?

      # Loaded sprite textures cache
      @sprite_textures : Hash(String, Raylib::Texture2D) = {} of String => Raylib::Texture2D

      # Base directory for asset loading
      property base_dir : String = ""

      # Whether overlays are currently active
      property active : Bool = false

      def initialize
      end

      # ============================================================
      # SPRITE MANAGEMENT
      # ============================================================

      # Add a sprite to the overlay
      def add_sprite(path : String, position : Raylib::Vector2, scale : Float32 = 1.0f32,
                     glow : Bool = false, glow_color : Raylib::Color? = nil)
        @sprites[path] = OverlaySprite.new(path, position, scale, glow, glow_color)
        @active = true
      end

      # Remove a sprite
      def remove_sprite(path : String)
        @sprites.delete(path)
        check_active_state
      end

      # Move a sprite (interpolate position)
      def move_sprite(path : String, target : Raylib::Vector2, progress : Float32)
        if sprite = @sprites[path]?
          if start = sprite.start_position
            new_pos = Raylib::Vector2.new(
              x: start.x + (target.x - start.x) * progress,
              y: start.y + (target.y - start.y) * progress
            )
            updated = OverlaySprite.new(sprite.path, new_pos, sprite.scale, sprite.glow, sprite.glow_color)
            updated.start_position = start
            @sprites[path] = updated
          end
        end
      end

      # Clear all sprites
      def clear_sprites
        @sprites.clear
        check_active_state
      end

      # Get all sprites for rendering
      def sprites : Hash(String, OverlaySprite)
        @sprites
      end

      # ============================================================
      # BACKGROUND MANAGEMENT
      # ============================================================

      # Set the overlay background
      def set_background(image_path : String)
        # Don't reload if same background
        return if @background == image_path

        # Unload previous background texture
        if old_tex = @background_texture
          Raylib.unload_texture(old_tex)
        end

        @background = image_path
        @active = true

        # Load new background texture
        full_path = resolve_path(image_path)
        if File.exists?(full_path)
          @background_texture = Raylib.load_texture(full_path)
          puts "[ActionOverlayManager] Loaded background: #{full_path}"
        else
          puts "[ActionOverlayManager] Background not found: #{full_path}"
          @background_texture = nil
        end
      end

      # Clear the background
      def clear_background
        if old_tex = @background_texture
          Raylib.unload_texture(old_tex)
        end
        @background = nil
        @background_texture = nil
        check_active_state
      end

      # Get current background
      def background : String?
        @background
      end

      # Clear all overlays (sprites, background)
      def clear_all
        clear_sprites
        clear_background
        @active = false
      end

      # ============================================================
      # RENDERING
      # ============================================================

      def draw
        return unless @active

        # Draw background if set
        if bg_tex = @background_texture
          draw_background(bg_tex)
        end

        # Draw sprites
        @sprites.each do |path, sprite|
          if texture = get_or_load_texture(path)
            # Draw glow effect if enabled
            if sprite.glow
              draw_sprite_glow(texture, sprite)
            end

            # Draw main sprite
            tint = Raylib::WHITE
            tint = Raylib::Color.new(r: tint.r, g: tint.g, b: tint.b, a: (sprite.alpha * 255).to_u8)
            Raylib.draw_texture_ex(texture, sprite.position, 0.0f32, sprite.scale, tint)
          end
        end
      end

      # ============================================================
      # CLEANUP
      # ============================================================

      # Cleanup all loaded textures (call on engine shutdown)
      def cleanup
        clear_background
        @sprite_textures.each_value do |tex|
          Raylib.unload_texture(tex)
        end
        @sprite_textures.clear
        @sprites.clear
        @active = false
      end

      # ============================================================
      # PRIVATE HELPERS
      # ============================================================

      private def draw_background(bg_tex : Raylib::Texture2D)
        # Scale background to fill screen
        screen_width = Raylib.get_screen_width.to_f32
        screen_height = Raylib.get_screen_height.to_f32
        scale_x = screen_width / bg_tex.width.to_f32
        scale_y = screen_height / bg_tex.height.to_f32
        scale = Math.max(scale_x, scale_y)

        dest_width = bg_tex.width.to_f32 * scale
        dest_height = bg_tex.height.to_f32 * scale
        dest_x = (screen_width - dest_width) / 2
        dest_y = (screen_height - dest_height) / 2

        source = Raylib::Rectangle.new(
          x: 0, y: 0,
          width: bg_tex.width.to_f32,
          height: bg_tex.height.to_f32
        )
        dest = Raylib::Rectangle.new(
          x: dest_x, y: dest_y,
          width: dest_width, height: dest_height
        )
        Raylib.draw_texture_pro(bg_tex, source, dest, Raylib::Vector2.new(x: 0, y: 0), 0.0f32, Raylib::WHITE)
      end

      # Load or get cached texture
      private def get_or_load_texture(path : String) : Raylib::Texture2D?
        return @sprite_textures[path] if @sprite_textures.has_key?(path)

        full_path = resolve_path(path)
        return nil unless File.exists?(full_path)

        texture = Raylib.load_texture(full_path)
        @sprite_textures[path] = texture
        texture
      end

      # Resolve asset path relative to base_dir
      private def resolve_path(path : String) : String
        return path if path.starts_with?("/") || @base_dir.empty?
        File.join(@base_dir, path)
      end

      # Draw glow effect around a sprite
      private def draw_sprite_glow(texture : Raylib::Texture2D, sprite : OverlaySprite)
        glow_color = sprite.glow_color || Raylib::Color.new(r: 255, g: 255, b: 200, a: 255)
        glow_effect = Graphics::Effects::ObjectEffects::GlowEffect.new(glow_color, radius: 10.0f32)
        glow_effect.draw_glow_for_texture(texture, sprite.position, sprite.scale, sprite.alpha)
      end

      # Check if overlays are still active
      private def check_active_state
        @active = !@sprites.empty? || @background != nil
      end
    end
  end
end
