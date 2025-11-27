require "./cutscene"

module PointClickEngine
  module Cutscenes
    # Sprite data for cutscene rendering
    struct CutsceneSprite
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

    # Manages cutscenes in the game
    class CutsceneManager
      property current_cutscene : Cutscene?
      property cutscenes : Hash(String, Cutscene)

      # Cutscene sprites for rendering
      @sprites : Hash(String, CutsceneSprite) = {} of String => CutsceneSprite

      # Current background path and loaded texture
      @background : String?
      @background_texture : Raylib::Texture2D?

      # Loaded sprite textures cache
      @sprite_textures : Hash(String, Raylib::Texture2D) = {} of String => Raylib::Texture2D

      # Base directory for asset loading
      property base_dir : String = ""

      def initialize
        @cutscenes = {} of String => Cutscene
      end

      def add_cutscene(cutscene : Cutscene)
        @cutscenes[cutscene.name] = cutscene
      end

      def play_cutscene(name : String, on_complete : Proc(Nil)? = nil)
        if cutscene = @cutscenes[name]?
          puts "[CutsceneManager] Starting cutscene '#{name}' with #{cutscene.actions.size} actions"
          @current_cutscene = cutscene
          cutscene.on_complete = on_complete
          cutscene.play
          true
        else
          puts "[CutsceneManager] Cutscene '#{name}' not found!"
          false
        end
      end

      def stop_current
        @current_cutscene.try(&.stop)
        @current_cutscene = nil
      end

      def skip_current
        @current_cutscene.try(&.skip)
        @current_cutscene = nil
      end

      def is_playing? : Bool
        @current_cutscene.try(&.playing) || false
      end

      def update(dt : Float32)
        if cutscene = @current_cutscene
          cutscene.update(dt)

          # Clear current cutscene if completed
          if cutscene.completed
            puts "[CutsceneManager] Cutscene '#{cutscene.name}' completed"
            @current_cutscene = nil
          end
        end
      end

      def draw
        return unless is_playing?

        # Draw background if set
        if bg_tex = @background_texture
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

        # Draw sprites
        @sprites.each do |path, sprite|
          if texture = get_or_load_texture(path)
            tint = Raylib::WHITE
            tint.a = (sprite.alpha * 255).to_u8
            Raylib.draw_texture_ex(texture, sprite.position, 0.0f32, sprite.scale, tint)
          end
        end

        # Draw current cutscene action overlays
        @current_cutscene.try(&.draw)
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

      # Create cutscene with DSL
      def create_cutscene(name : String, &block) : Cutscene
        cutscene = Cutscene.new(name)
        with cutscene yield
        add_cutscene(cutscene)
        cutscene
      end

      # ============================================================
      # SPRITE MANAGEMENT
      # ============================================================

      # Add a sprite to the cutscene
      def add_sprite(path : String, position : Raylib::Vector2, scale : Float32 = 1.0f32,
                     glow : Bool = false, glow_color : Raylib::Color? = nil)
        @sprites[path] = CutsceneSprite.new(path, position, scale, glow, glow_color)
      end

      # Remove a sprite
      def remove_sprite(path : String)
        @sprites.delete(path)
      end

      # Move a sprite (interpolate position)
      def move_sprite(path : String, target : Raylib::Vector2, progress : Float32)
        if sprite = @sprites[path]?
          if start = sprite.start_position
            new_pos = Raylib::Vector2.new(
              x: start.x + (target.x - start.x) * progress,
              y: start.y + (target.y - start.y) * progress
            )
            updated = CutsceneSprite.new(sprite.path, new_pos, sprite.scale, sprite.glow, sprite.glow_color)
            updated.start_position = start
            @sprites[path] = updated
          end
        end
      end

      # Clear all sprites
      def clear_sprites
        @sprites.clear
      end

      # Get all sprites for rendering
      def sprites : Hash(String, CutsceneSprite)
        @sprites
      end

      # ============================================================
      # BACKGROUND MANAGEMENT
      # ============================================================

      # Set the cutscene background
      def set_background(image_path : String)
        # Don't reload if same background
        return if @background == image_path

        # Unload previous background texture
        if old_tex = @background_texture
          Raylib.unload_texture(old_tex)
        end

        @background = image_path

        # Load new background texture
        full_path = resolve_path(image_path)
        if File.exists?(full_path)
          @background_texture = Raylib.load_texture(full_path)
          puts "[CutsceneManager] Loaded background: #{full_path}"
        else
          puts "[CutsceneManager] Background not found: #{full_path}"
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
      end

      # Get current background
      def background : String?
        @background
      end

      # Clear all cutscene visuals (sprites, background)
      def clear_visuals
        clear_sprites
        clear_background
      end

      # Cleanup all loaded textures (call on engine shutdown)
      def cleanup
        clear_background
        @sprite_textures.each_value do |tex|
          Raylib.unload_texture(tex)
        end
        @sprite_textures.clear
        @sprites.clear
      end
    end
  end
end
