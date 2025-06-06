# game.cr
require "../src/point_click_engine" # Assurez-vous que le moteur est dans src/

# Alias pour plus de commodité
alias PCE = PointClickEngine
# alias RL = Raylib

# 1. Initialisation du jeu
game = PCE::Game.new(800, 600, "Aventure dans la Clairière Mystique")
game.target_fps = 60

game.init

# Charger un curseur personnalisé (optionnel)
# Assurez-vous d'avoir un fichier assets/pointer.png
game.load_cursor("pointer.png") # Décommentez si vous avez un curseur personnalisé

# 2. Création d'une scène
grove_scene = PCE::Scene.new("Clairière Mystique")

# Charger l'arrière-plan de la scène
# Assurez-vous d'avoir un fichier assets/mystic_grove.png
grove_scene.load_background("background2.png")

# 3. Création des Hotspots

# Hotspot 1: Champignon luisant
glowing_mushroom = PCE::Hotspot.new(
  "champignon",
  RL::Vector2.new(x: 150, y: 400), # Position x, y
  RL::Vector2.new(x: 260, y: 260)    # Taille largeur, hauteur
)
glowing_mushroom.cursor_type = PCE::Hotspot::CursorType::Look # Change le curseur en mode "Regarder"
glowing_mushroom.on_click = ->{
  dialog_text = "Ce champignon émet une douce lueur apaisante."
  dialog_pos = RL::Vector2.new(x: 100, y: game.window_height - 150)
  dialog_size = RL::Vector2.new(x: game.window_width - 200, y: 100)
  mushroom_dialog = PCE::Dialog.new(dialog_text, dialog_pos, dialog_size)
  mushroom_dialog.character_name = "Observation"
  game.show_dialog(mushroom_dialog)
}
grove_scene.add_hotspot(glowing_mushroom)

# Hotspot 2: Vieux Coffre
old_chest = PCE::Hotspot.new(
  "coffre",
  RL::Vector2.new(x: 550, y: 420),
  RL::Vector2.new(x: 120, y: 90)
)
old_chest.cursor_type = PCE::Hotspot::CursorType::Hand # Curseur "Main" pour interagir

# Action lorsque le coffre est cliqué
old_chest.on_click = ->{
  # Vérifier si la clé est déjà dans l'inventaire pour éviter les doublons
  unless game.inventory.has_item?("Vieille Clé")
    # Créer l'objet d'inventaire
    rusty_key = PCE::InventoryItem.new("Vieille Clé", "Une vieille clé rouillée. À quoi peut-elle servir ?")
    # Charger son icône (assurez-vous d'avoir assets/rusty_key_icon.png)
    rusty_key.load_icon("key.png")
    game.inventory.add_item(rusty_key)

    # Afficher un dialogue
    dialog_text = "Vous avez trouvé une Vieille Clé !"
    dialog_pos = RL::Vector2.new(x: 100, y: game.window_height - 150)
    dialog_size = RL::Vector2.new(x: game.window_width - 200, y: 100)
    key_dialog = PCE::Dialog.new(dialog_text, dialog_pos, dialog_size)
    key_dialog.character_name = "Découverte"
    game.show_dialog(key_dialog)

    # Optionnel: Rendre le hotspot inactif après avoir pris la clé
    old_chest.active = false
    old_chest.visible = false # Le rend invisible en mode debug aussi
  else
    # Si la clé est déjà prise
    dialog_text = "Le coffre est vide maintenant."
    dialog_pos = RL::Vector2.new(x: 100, y: game.window_height - 150)
    dialog_size = RL::Vector2.new(x: game.window_width - 200, y: 100)
    empty_dialog = PCE::Dialog.new(dialog_text, dialog_pos, dialog_size)
    game.show_dialog(empty_dialog)
  end
}
grove_scene.add_hotspot(old_chest)

# Ajouter un objet animé pour le fun (optionnel, nécessite une spritesheet)
# Par exemple, un feu follet
# an_animated_sprite = PCE::AnimatedSprite.new(RL::Vector2.new(x: 300, y: 300), 32, 32, 4) # pos, frame_width, frame_height, frame_count
# an_animated_sprite.load_texture("assets/willisp_spritesheet.png") # remplacer par votre asset
# an_animated_sprite.frame_speed = 0.2
# an_animated_sprite.scale = 1.5
# grove_scene.add_object(an_animated_sprite)


# 4. Ajout de la scène au jeu et configuration initiale
game.add_scene(grove_scene)
game.change_scene("Clairière Mystique") # Définit la scène de départ

# L'inventaire est initialement invisible, appuyez sur 'I' pour le montrer/cacher.
# game.inventory.visible = true # Décommentez pour que l'inventaire soit visible au démarrage

# 5. Lancement du jeu
game.run

puts "Jeu terminé."
