# ActionOverlayManager - Manages visual overlays for action sequences
# Handles sprites, backgrounds, and other visual elements during sequences

require "../graphics/effects/object_effects/glow"
require "../graphics/graphics"

module PointClickEngine
  module Actions
    # Sprite data for sequence rendering
    class OverlaySprite
      property path : String
      property position : Raylib::Vector2
      property scale : Float32
      property glow : Bool
      property glow_color : Raylib::Color?
      property alpha : Float32
      property start_position : Raylib::Vector2?
      property tint : Raylib::Color
      property fade_in_duration : Float32
      property fade_out_duration : Float32 = 0.0f32
      property fade_elapsed : Float32 = 0.0f32
      property removing : Bool = false
      property animate : Bool
      property animation_frames : Int32
      property animation_fps : Float32
      property animation_elapsed : Float32 = 0.0f32
      property glow_pulse : Bool
      property glow_pulse_speed : Float32

      def initialize(@path : String, @position : Raylib::Vector2, @scale : Float32 = 1.0f32,
                     @glow : Bool = false, @glow_color : Raylib::Color? = nil,
                     @tint : Raylib::Color = Raylib::WHITE, @fade_in_duration : Float32 = 0.0f32,
                     @animate : Bool = false, @animation_frames : Int32 = 1,
                     @animation_fps : Float32 = 0.0f32, @glow_pulse : Bool = false,
                     @glow_pulse_speed : Float32 = 1.0f32)
        @start_position = @position.dup
        @alpha = @fade_in_duration > 0 ? 0.0f32 : 1.0f32
      end

      def update(dt : Float32)
        @animation_elapsed += dt

        if @removing
          return if @fade_out_duration <= 0

          @fade_elapsed += dt
          @alpha = (1.0f32 - (@fade_elapsed / @fade_out_duration)).clamp(0.0f32, 1.0f32)
        elsif @fade_in_duration > 0 && @alpha < 1.0f32
          @fade_elapsed += dt
          @alpha = (@fade_elapsed / @fade_in_duration).clamp(0.0f32, 1.0f32)
        end
      end

      def begin_fade_out(duration : Float32)
        @removing = true
        @fade_out_duration = duration
        @fade_elapsed = 0.0f32
      end

      def ready_for_removal? : Bool
        @removing && (@fade_out_duration <= 0 || @fade_elapsed >= @fade_out_duration)
      end

      def current_frame_path : String
        return @path unless @animate && @animation_frames > 1 && @animation_fps > 0

        frame_index = ((@animation_elapsed * @animation_fps).to_i % @animation_frames) + 1
        if match = @path.match(/^(.*?)(\d+)(\.[^.]+)$/)
          "#{match[1]}#{frame_index}#{match[3]}"
        else
          @path
        end
      end
    end

    class BackgroundLayer
      property path : String
      property texture : Raylib::Texture2D?

      def initialize(@path : String, @texture : Raylib::Texture2D?)
      end
    end

    # Manages visual overlays for action sequences
    class ActionOverlayManager
      # Sprites for rendering
      @sprites : Hash(String, OverlaySprite) = {} of String => OverlaySprite

      # Layered backgrounds for cinematic compositions
      @background_layers : Hash(Int32, BackgroundLayer) = {} of Int32 => BackgroundLayer

      # Loaded sprite textures cache
      @sprite_textures : Hash(String, Raylib::Texture2D) = {} of String => Raylib::Texture2D

      # Base directory for asset loading
      property base_dir : String = ""

      # Canvas size used for authored sequence coordinates.
      property canvas_width : Int32 = Graphics::Display::REFERENCE_WIDTH
      property canvas_height : Int32 = Graphics::Display::REFERENCE_HEIGHT

      # Whether overlays are currently active
      property active : Bool = false

      def initialize
      end

      # ============================================================
      # SPRITE MANAGEMENT
      # ============================================================

      # Add a sprite to the overlay
      def add_sprite(path : String, position : Raylib::Vector2, scale : Float32 = 1.0f32,
                     glow : Bool = false, glow_color : Raylib::Color? = nil,
                     tint : Raylib::Color = Raylib::WHITE, fade_in : Float32 = 0.0f32,
                     animate : Bool = false, animation_frames : Int32 = 1,
                     animation_fps : Float32 = 0.0f32, glow_pulse : Bool = false,
                     glow_pulse_speed : Float32 = 1.0f32)
        @sprites[path] = OverlaySprite.new(path, position, scale, glow, glow_color, tint, fade_in,
          animate, animation_frames, animation_fps, glow_pulse, glow_pulse_speed)
        @active = true
      end

      # Remove a sprite
      def remove_sprite(identifier : String, fade_out : Float32 = 0.0f32)
        if key = resolve_sprite_key(identifier)
          if fade_out > 0
            @sprites[key]?.try(&.begin_fade_out(fade_out))
          else
            @sprites.delete(key)
          end
        end
        check_active_state
      end

      # Move a sprite (interpolate position)
      def move_sprite(identifier : String, target : Raylib::Vector2, progress : Float32)
        if key = resolve_sprite_key(identifier)
          if sprite = @sprites[key]?
            if start = sprite.start_position
              new_pos = Raylib::Vector2.new(
                x: start.x + (target.x - start.x) * progress,
                y: start.y + (target.y - start.y) * progress
              )
              updated = OverlaySprite.new(sprite.path, new_pos, sprite.scale, sprite.glow, sprite.glow_color,
                sprite.tint, sprite.fade_in_duration, sprite.animate, sprite.animation_frames,
                sprite.animation_fps, sprite.glow_pulse, sprite.glow_pulse_speed)
              updated.start_position = start
              updated.alpha = sprite.alpha
              updated.fade_out_duration = sprite.fade_out_duration
              updated.fade_elapsed = sprite.fade_elapsed
              updated.removing = sprite.removing
              updated.animation_elapsed = sprite.animation_elapsed
              @sprites[key] = updated
            end
          end
        end
      end

      # Check whether a sprite is currently registered.
      def has_sprite?(identifier : String) : Bool
        !resolve_sprite_key(identifier).nil?
      end

      # Resolve a sprite identifier to the canonical stored key.
      def resolve_sprite_key(identifier : String) : String?
        return identifier if @sprites.has_key?(identifier)

        basename = File.basename(identifier)
        stem = File.basename(identifier, File.extname(identifier))

        @sprites.each_key do |key|
          key_basename = File.basename(key)
          return key if key_basename == basename
          return key if File.basename(key, File.extname(key)) == stem
        end

        nil
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
      def set_background(image_path : String, layer : Int32 = 0)
        if existing = @background_layers[layer]?
          return if existing.path == image_path
          if old_tex = existing.texture
            Raylib.unload_texture(old_tex)
          end
        end

        @active = true

        full_path = resolve_path(image_path)
        if File.exists?(full_path)
          texture = Raylib.load_texture(full_path)
          @background_layers[layer] = BackgroundLayer.new(image_path, texture)
          puts "[ActionOverlayManager] Loaded background: #{full_path}"
        else
          puts "[ActionOverlayManager] Background not found: #{full_path}"
          @background_layers[layer] = BackgroundLayer.new(image_path, nil)
        end
      end

      # Clear the background
      def clear_background
        clear_backgrounds
      end

      def clear_backgrounds
        @background_layers.each_value do |layer|
          if old_tex = layer.texture
            Raylib.unload_texture(old_tex)
          end
        end
        @background_layers.clear
        check_active_state
      end

      # Get current background
      def background : String?
        top_layer = @background_layers.keys.max?
        top_layer ? @background_layers[top_layer].path : nil
      end

      # Clear all overlays (sprites, background)
      def clear_all
        clear_sprites
        clear_backgrounds
        @active = false
      end

      # Update active overlays
      def update(dt : Float32)
        @sprites.each_value(&.update(dt))
        @sprites.reject! { |_, sprite| sprite.ready_for_removal? }
        check_active_state
      end

      def set_canvas(width : Int32, height : Int32)
        return if width <= 0 || height <= 0

        @canvas_width = width
        @canvas_height = height
      end

      def render_position_for(position : Raylib::Vector2, screen_width : Int32, screen_height : Int32) : Raylib::Vector2
        scale_x = screen_width.to_f32 / @canvas_width.to_f32
        scale_y = screen_height.to_f32 / @canvas_height.to_f32
        Raylib::Vector2.new(x: position.x * scale_x, y: position.y * scale_y)
      end

      def render_scale_for(scale : Float32, screen_width : Int32, screen_height : Int32) : Float32
        scale_factor = Math.min(
          screen_width.to_f32 / @canvas_width.to_f32,
          screen_height.to_f32 / @canvas_height.to_f32
        ).to_f32
        scale * scale_factor
      end

      # ============================================================
      # RENDERING
      # ============================================================

      def draw
        return unless @active

        @background_layers.keys.sort.each do |layer|
          if bg_tex = @background_layers[layer].texture
            draw_background(bg_tex)
          end
        end

        # Draw sprites
        @sprites.each do |path, sprite|
          if texture = get_or_load_texture(sprite.current_frame_path)
            # Draw glow effect if enabled
            if sprite.glow
              draw_sprite_glow(texture, sprite)
            end

            # Draw main sprite
            draw_sprite(texture, sprite)
          elsif draw_builtin_sprite(path, sprite)
            next
          end
        end
      end

      # ============================================================
      # CLEANUP
      # ============================================================

      # Cleanup all loaded textures (call on engine shutdown)
      def cleanup
        clear_backgrounds
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

      private def draw_sprite(texture : Raylib::Texture2D, sprite : OverlaySprite)
        screen_width = Raylib.get_screen_width
        screen_height = Raylib.get_screen_height
        render_pos = render_position_for(sprite.position, screen_width, screen_height)
        render_scale = render_scale_for(sprite.scale, screen_width, screen_height)
        draw_x = render_pos.x - (texture.width.to_f32 * render_scale) / 2.0f32
        draw_y = render_pos.y - (texture.height.to_f32 * render_scale) / 2.0f32

        tint = compose_tint(sprite)
        Raylib.draw_texture_ex(texture, Raylib::Vector2.new(x: draw_x, y: draw_y), 0.0f32, render_scale, tint)
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
        glow_alpha = sprite.glow_pulse ? (0.75f32 + 0.25f32 * Math.sin(sprite.animation_elapsed * sprite.glow_pulse_speed)).to_f32 : 1.0f32
        glow_color = Raylib::Color.new(
          r: glow_color.r,
          g: glow_color.g,
          b: glow_color.b,
          a: (glow_color.a.to_f32 * sprite.alpha * glow_alpha).clamp(0.0f32, 255.0f32).to_u8
        )
        glow_effect = Graphics::Effects::ObjectEffects::GlowEffect.new(glow_color, radius: 10.0f32)
        screen_width = Raylib.get_screen_width
        screen_height = Raylib.get_screen_height
        render_pos = render_position_for(sprite.position, screen_width, screen_height)
        render_scale = render_scale_for(sprite.scale, screen_width, screen_height)
        draw_pos = Raylib::Vector2.new(
          x: render_pos.x - (texture.width.to_f32 * render_scale) / 2.0f32,
          y: render_pos.y - (texture.height.to_f32 * render_scale) / 2.0f32
        )
        glow_effect.draw_glow_for_texture(texture, draw_pos, render_scale, sprite.alpha)
      end

      private def draw_builtin_sprite(identifier : String, sprite : OverlaySprite) : Bool
        basename = File.basename(identifier, File.extname(identifier))
        case basename
        when "shadow_figure"
          draw_shadow_figure(sprite)
          true
        when "dust"
          draw_dust_cloud(sprite)
          true
        else
          false
        end
      end

      private def draw_shadow_figure(sprite : OverlaySprite)
        screen_width = Raylib.get_screen_width
        screen_height = Raylib.get_screen_height
        render_pos = render_position_for(sprite.position, screen_width, screen_height)
        render_scale = render_scale_for(sprite.scale, screen_width, screen_height)
        tint = compose_tint(sprite)

        body_height = 22.0f32 * render_scale
        body_width = 8.0f32 * render_scale
        shoulder_width = 14.0f32 * render_scale
        head_radius = 5.0f32 * render_scale
        base_x = render_pos.x
        base_y = render_pos.y

        Raylib.draw_circle(base_x.to_i, (base_y - body_height).to_i, head_radius, tint)
        Raylib.draw_rectangle(
          (base_x - body_width / 2.0f32).to_i,
          (base_y - body_height + head_radius).to_i,
          body_width.to_i,
          (body_height - head_radius).to_i,
          tint
        )
        Raylib.draw_triangle(
          Raylib::Vector2.new(x: base_x - shoulder_width / 2.0f32, y: base_y - body_height + head_radius + 3.0f32 * render_scale),
          Raylib::Vector2.new(x: base_x + shoulder_width / 2.0f32, y: base_y - body_height + head_radius + 3.0f32 * render_scale),
          Raylib::Vector2.new(x: base_x, y: base_y + 4.0f32 * render_scale),
          tint
        )
      end

      private def draw_dust_cloud(sprite : OverlaySprite)
        screen_width = Raylib.get_screen_width
        screen_height = Raylib.get_screen_height
        render_pos = render_position_for(sprite.position, screen_width, screen_height)
        render_scale = render_scale_for(sprite.scale, screen_width, screen_height)
        tint = compose_tint(sprite)

        offsets = [
          {-8.0f32, 0.0f32, 10.0f32},
          {0.0f32, -4.0f32, 12.0f32},
          {9.0f32, 2.0f32, 8.0f32},
          {-2.0f32, 6.0f32, 7.0f32},
        ]

        offsets.each do |x_off, y_off, radius|
          Raylib.draw_circle(
            (render_pos.x + x_off * render_scale).to_i,
            (render_pos.y + y_off * render_scale).to_i,
            radius * render_scale,
            tint
          )
        end
      end

      private def compose_tint(sprite : OverlaySprite) : Raylib::Color
        Raylib::Color.new(
          r: sprite.tint.r,
          g: sprite.tint.g,
          b: sprite.tint.b,
          a: (sprite.tint.a.to_f32 * sprite.alpha).clamp(0.0f32, 255.0f32).to_u8
        )
      end

      # Check if overlays are still active
      private def check_active_state
        @active = !@sprites.empty? || !@background_layers.empty?
      end
    end
  end
end
