# Système de mise à l'échelle pour résolution adaptative

module PointClickEngine
  # Gestionnaire de résolution et mise à l'échelle
  class DisplayManager
    # Résolution de référence (vos assets)
    REFERENCE_WIDTH = 1024
    REFERENCE_HEIGHT = 768
    REFERENCE_ASPECT_RATIO = REFERENCE_WIDTH.to_f / REFERENCE_HEIGHT.to_f

    property target_width : Int32
    property target_height : Int32
    property scale_factor : Float32 = 1.0
    property offset_x : Float32 = 0.0
    property offset_y : Float32 = 0.0
    property scaling_mode : ScalingMode = ScalingMode::FitWithBars
    property render_texture : RL::RenderTexture2D?

    enum ScalingMode
      # Garde l'aspect ratio, ajoute des barres noires si nécessaire
      FitWithBars
      # Étire pour remplir l'écran (peut déformer)
      Stretch
      # Remplit l'écran en coupant les bords si nécessaire
      Fill
      # Pixels parfaits (multiples entiers seulement)
      PixelPerfect
      # Résolution fixe avec zoom
      FixedZoom
    end

    def initialize(@target_width : Int32, @target_height : Int32)
      calculate_scaling
      setup_render_texture
    end

    # Calcule les paramètres de mise à l'échelle
    def calculate_scaling
      target_aspect = (@target_width.to_f / @target_height.to_f).to_f32

      case @scaling_mode
      when ScalingMode::FitWithBars
        calculate_fit_scaling(target_aspect)
      when ScalingMode::Stretch
        calculate_stretch_scaling
      when ScalingMode::Fill
        calculate_fill_scaling(target_aspect)
      when ScalingMode::PixelPerfect
        calculate_pixel_perfect_scaling
      when ScalingMode::FixedZoom
        calculate_fixed_zoom_scaling
      end
    end

    # Mode "Fit" - garde l'aspect ratio avec barres noires
    private def calculate_fit_scaling(target_aspect : Float32)
      if target_aspect > REFERENCE_ASPECT_RATIO
        # Écran plus large : limité par la hauteur
        @scale_factor = (@target_height.to_f / REFERENCE_HEIGHT).to_f32
        scaled_width = REFERENCE_WIDTH * @scale_factor
        @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
        @offset_y = 0.0_f32
      else
        # Écran plus haut : limité par la largeur
        @scale_factor = (@target_width.to_f / REFERENCE_WIDTH).to_f32
        scaled_height = REFERENCE_HEIGHT * @scale_factor
        @offset_x = 0.0_f32
        @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
      end
    end

    # Mode "Stretch" - étire pour remplir
    private def calculate_stretch_scaling
      scale_x = (@target_width.to_f / REFERENCE_WIDTH).to_f32
      scale_y = (@target_height.to_f / REFERENCE_HEIGHT).to_f32
      @scale_factor = scale_x # On utilise un facteur unique pour simplifier
      @offset_x = 0.0_f32
      @offset_y = 0.0_f32
    end

    # Mode "Fill" - remplit en coupant si nécessaire
    private def calculate_fill_scaling(target_aspect : Float32)
      if target_aspect > REFERENCE_ASPECT_RATIO
        # Écran plus large : limité par la largeur pour remplir en hauteur
        @scale_factor = (@target_width.to_f / REFERENCE_WIDTH).to_f32
        scaled_height = REFERENCE_HEIGHT * @scale_factor
        @offset_x = 0.0_f32
        @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
      else
        # Écran plus haut : limité par la hauteur pour remplir en largeur
        @scale_factor = (@target_height.to_f / REFERENCE_HEIGHT).to_f32
        scaled_width = REFERENCE_WIDTH * @scale_factor
        @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
        @offset_y = 0.0_f32
      end
    end

    # Mode "Pixel Perfect" - multiples entiers seulement
    private def calculate_pixel_perfect_scaling
      scale_x = (@target_width / REFERENCE_WIDTH).to_i
      scale_y = (@target_height / REFERENCE_HEIGHT).to_i
      @scale_factor = Math.min(scale_x, scale_y).to_f32
      @scale_factor = Math.max(1.0_f32, @scale_factor) # Minimum 1x

      scaled_width = REFERENCE_WIDTH * @scale_factor
      scaled_height = REFERENCE_HEIGHT * @scale_factor
      @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
      @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
    end

    # Mode "Fixed Zoom" - zoom fixe défini
    private def calculate_fixed_zoom_scaling
      @scale_factor = 2.0_f32 # Ou toute autre valeur fixe
      scaled_width = REFERENCE_WIDTH * @scale_factor
      scaled_height = REFERENCE_HEIGHT * @scale_factor
      @offset_x = ((@target_width - scaled_width) / 2.0).to_f32
      @offset_y = ((@target_height - scaled_height) / 2.0).to_f32
    end

    # Configure le render texture pour le rendu intermédiaire
    def setup_render_texture
      @render_texture = RL.load_render_texture(REFERENCE_WIDTH, REFERENCE_HEIGHT)
    end

    # Redimensionne quand la fenêtre change
    def resize(new_width : Int32, new_height : Int32)
      @target_width = new_width
      @target_height = new_height
      calculate_scaling
    end

    # Change le mode de scaling
    def set_scaling_mode(mode : ScalingMode)
      @scaling_mode = mode
      calculate_scaling
    end

    # Convertit les coordonnées écran vers les coordonnées du jeu
    def screen_to_game(screen_pos : RL::Vector2) : RL::Vector2
      game_x = (screen_pos.x - @offset_x) / @scale_factor
      game_y = (screen_pos.y - @offset_y) / @scale_factor
      RL::Vector2.new(x: game_x, y: game_y)
    end

    # Convertit les coordonnées du jeu vers les coordonnées écran
    def game_to_screen(game_pos : RL::Vector2) : RL::Vector2
      screen_x = game_pos.x * @scale_factor + @offset_x
      screen_y = game_pos.y * @scale_factor + @offset_y
      RL::Vector2.new(x: screen_x, y: screen_y)
    end

    # Vérifie si un point écran est dans la zone de jeu
    def is_in_game_area(screen_pos : RL::Vector2) : Bool
      game_pos = screen_to_game(screen_pos)
      game_pos.x >= 0 && game_pos.x <= REFERENCE_WIDTH &&
      game_pos.y >= 0 && game_pos.y <= REFERENCE_HEIGHT
    end

    # Commence le rendu sur le render texture
    def begin_game_rendering
      if rt = @render_texture
        RL.begin_texture_mode(rt)
        RL.clear_background(RL::BLACK)
      end
    end

    # Termine le rendu et affiche sur l'écran final
    def end_game_rendering
      if rt = @render_texture
        RL.end_texture_mode

        # Dessine le render texture sur l'écran final avec mise à l'échelle
        RL.begin_drawing
        RL.clear_background(RL::BLACK)

        source_rect = RL::Rectangle.new(
          x: 0, y: 0,
          width: REFERENCE_WIDTH,
          height: -REFERENCE_HEIGHT # Négatif pour flipper la texture
        )

        dest_rect = RL::Rectangle.new(
          x: @offset_x, y: @offset_y,
          width: REFERENCE_WIDTH * @scale_factor,
          height: REFERENCE_HEIGHT * @scale_factor
        )

        RL.draw_texture_pro(rt.texture, source_rect, dest_rect,
                           RL::Vector2.new(x: 0, y: 0), 0.0, RL::WHITE)

        # Affiche les infos de debug si nécessaire
        if Game.debug_mode
          draw_debug_info
        end

        RL.end_drawing
      end
    end

    # Affiche les informations de debug
    private def draw_debug_info
      info_text = "Target: #{@target_width}x#{@target_height} | " \
                 "Scale: #{@scale_factor.round(2)} | " \
                 "Mode: #{@scaling_mode} | " \
                 "Offset: (#{@offset_x.to_i}, #{@offset_y.to_i})"

      RL.draw_text(info_text, 10, 10, 16, RL::GREEN)

      # Dessine les limites de la zone de jeu
      game_rect = RL::Rectangle.new(
        x: @offset_x, y: @offset_y,
        width: REFERENCE_WIDTH * @scale_factor,
        height: REFERENCE_HEIGHT * @scale_factor
      )
      RL.draw_rectangle_lines_ex(game_rect, 2, RL::RED)
    end

    # Nettoie les ressources
    def cleanup
      if rt = @render_texture
        RL.unload_render_texture(rt)
      end
    end
  end

  # Extension de la classe Game pour gérer la résolution adaptative
  class Game
    property display_manager : DisplayManager?
    property fullscreen : Bool = false

    def init
      return if @initialized

      # Initialise d'abord une fenêtre de base pour pouvoir accéder aux infos du moniteur
      RL.init_window(@window_width, @window_height, @title)

      # Maintenant on peut obtenir les infos du moniteur
      monitor = RL.get_current_monitor
      screen_width = RL.get_monitor_width(monitor)
      screen_height = RL.get_monitor_height(monitor)

      # Ajuste la fenêtre selon le mode souhaité
      if @fullscreen
        RL.set_window_size(screen_width, screen_height)
        RL.set_window_state(RL::ConfigFlags::FullscreenMode)
        @display_manager = DisplayManager.new(screen_width, screen_height)
      else
        # Mode fenêtré : utilise une taille raisonnable
        windowed_width = Math.min(1280, Math.max(800, screen_width - 200))
        windowed_height = Math.min(960, Math.max(600, screen_height - 200))
        RL.set_window_size(windowed_width, windowed_height)
        @display_manager = DisplayManager.new(windowed_width, windowed_height)
      end

      RL.set_window_state(RL::ConfigFlags::WindowResizable)
      RL.set_target_fps(@target_fps)
      RL.hide_cursor if @cursor_texture
      @initialized = true
    end

    # Bascule entre plein écran et fenêtré
    def toggle_fullscreen
      @fullscreen = !@fullscreen

      if @fullscreen
        monitor = RL.get_current_monitor
        screen_width = RL.get_monitor_width(monitor)
        screen_height = RL.get_monitor_height(monitor)
        RL.set_window_size(screen_width, screen_height)
        RL.set_window_state(RL::ConfigFlags::FullscreenMode)
        @display_manager.not_nil!.resize(screen_width, screen_height)
      else
        RL.clear_window_state(RL::ConfigFlags::FullscreenMode)
        windowed_width = 1280
        windowed_height = 960
        RL.set_window_size(windowed_width, windowed_height)
        @display_manager.not_nil!.resize(windowed_width, windowed_height)
      end
    end

    # Change le mode de scaling
    def set_scaling_mode(mode : DisplayManager::ScalingMode)
      @display_manager.not_nil!.set_scaling_mode(mode)
    end

    private def update(dt : Float32)
      # Gère le redimensionnement de la fenêtre
      if RL.window_resized?
        new_width = RL.get_screen_width
        new_height = RL.get_screen_height
        @display_manager.not_nil!.resize(new_width, new_height)
      end

      # Bascule plein écran avec F11
      if RL::KeyboardKey::F11.pressed?
        toggle_fullscreen
      end

      # Change les modes de scaling avec les touches F1-F4
      if RL::KeyboardKey::F2.pressed?
        set_scaling_mode(DisplayManager::ScalingMode::FitWithBars)
      elsif RL::KeyboardKey::F3.pressed?
        set_scaling_mode(DisplayManager::ScalingMode::Stretch)
      elsif RL::KeyboardKey::F4.pressed?
        set_scaling_mode(DisplayManager::ScalingMode::Fill)
      elsif RL::KeyboardKey::F5.pressed?
        set_scaling_mode(DisplayManager::ScalingMode::PixelPerfect)
      end

      # Convertit la position de la souris pour le jeu
      raw_mouse_pos = RL.get_mouse_position
      if dm = @display_manager
        game_mouse_pos = dm.screen_to_game(raw_mouse_pos)

        # Vérifie si la souris est dans la zone de jeu
        if dm.is_in_game_area(raw_mouse_pos)
          # Met à jour les objets du jeu avec les coordonnées converties
          update_game_logic(dt, game_mouse_pos)
        end
      end
    end

    private def update_game_logic(dt : Float32, mouse_pos : RL::Vector2)
      # Update current scene avec la position de souris convertie
      @current_scene.try &.update(dt)

      # Update inventory
      @inventory.update(dt)

      # Update dialogs
      @dialogs.each(&.update(dt))
      @dialogs.reject! { |d| !d.visible }

      # Toggle inventory
      if RL::KeyboardKey::I.pressed?
        @inventory.visible = !@inventory.visible
      end

      # Toggle debug mode
      if RL::KeyboardKey::F1.pressed?
        Game.debug_mode = !Game.debug_mode
      end

      # Gestion des clics avec coordonnées converties
      if RL::MouseButton::Left.pressed?
        handle_click(mouse_pos)
      end
    end

    private def handle_click(game_mouse_pos : RL::Vector2)
      return unless scene = @current_scene

      # Vérifie les hotspots avec les coordonnées du jeu
      if hotspot = scene.get_hotspot_at(game_mouse_pos)
        hotspot.on_click.try &.call
      elsif character = scene.get_character_at(game_mouse_pos)
        character.on_interact(scene.player.not_nil!)
      elsif player = scene.player
        # Mouvement du joueur
        player.walk_to(game_mouse_pos)
      end
    end

    private def draw
      return unless dm = @display_manager

      # Commence le rendu sur le render texture de référence
      dm.begin_game_rendering

      # Dessine tout le contenu du jeu à la résolution de référence
      draw_game_content

      # Termine et affiche avec mise à l'échelle
      dm.end_game_rendering
    end

    private def draw_game_content
      # Draw current scene
      @current_scene.try &.draw

      # Draw inventory
      @inventory.draw

      # Draw dialogs
      @dialogs.each(&.draw)

      # Draw custom cursor à la résolution de référence
      if cursor = @cursor_texture
        # Utilise les coordonnées converties
        if dm = @display_manager
          raw_mouse = RL.get_mouse_position
          if dm.is_in_game_area(raw_mouse)
            game_mouse = dm.screen_to_game(raw_mouse)
            RL.draw_texture_v(cursor, game_mouse, RL::WHITE)
          end
        end
      end

      # Draw debug info dans l'espace de jeu
      if Game.debug_mode
        RL.draw_text("FPS: #{RL.get_fps}", 10, 10, 20, RL::GREEN)
        if dm = @display_manager
          raw_mouse = RL.get_mouse_position
          game_mouse = dm.screen_to_game(raw_mouse)
          RL.draw_text("Game Mouse: #{game_mouse.x.to_i}, #{game_mouse.y.to_i}",
                      10, 35, 20, RL::GREEN)
          RL.draw_text("Resolution: #{DisplayManager::REFERENCE_WIDTH}x#{DisplayManager::REFERENCE_HEIGHT}",
                      10, 60, 20, RL::GREEN)
        end
      end
    end

    private def cleanup
      @display_manager.try &.cleanup

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

  # Extension de la classe Drawable pour la compatibilité
  module Drawable
    # Utilise toujours les coordonnées de référence (1024x768)
    # La conversion est gérée automatiquement par le DisplayManager

    def draw_at_screen_pos(screen_pos : RL::Vector2)
      # Si vous avez besoin de dessiner à une position écran spécifique
      if game = Game.current_instance # Vous devrez ajouter cette référence
        if dm = game.display_manager
          game_pos = dm.screen_to_game(screen_pos)
          # Dessiner à game_pos
        end
      end
    end
  end
end

# Exemple d'utilisation:
#
# # Initialisation du jeu
# game = PointClickEngine::Game.new(1024, 768, "Mon Jeu Point & Click")
# game.fullscreen = true  # Démarrer en plein écran
# game.init
#
# # Pendant le jeu:
# # F11 : Basculer plein écran / fenêtré
# # F2 : Mode "Fit with bars" (recommandé)
# # F3 : Mode "Stretch"
# # F4 : Mode "Fill"
# # F5 : Mode "Pixel Perfect"
#
# # Vos assets sont conçus pour 1024x768 et fonctionneront
# # automatiquement sur n'importe quelle résolution !
