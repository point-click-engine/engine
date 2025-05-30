# Extension du Point & Click Game Engine - Système de personnages

module PointClickEngine

  module Talkable

  end
  # État d'un personnage
  enum CharacterState
    Idle
    Walking
    Talking
    Interacting
    Thinking
  end

  # Direction d'un personnage
  enum Direction
    Left
    Right
    Up
    Down
  end

  # Classe de base pour tous les personnages
  abstract class Character < GameObject
    property name : String
    property description : String
    property state : CharacterState = CharacterState::Idle
    property direction : Direction = Direction::Right
    property walking_speed : Float32 = 100.0
    property target_position : RL::Vector2?
    property dialogue_system : CharacterDialogue?
    property sprite : AnimatedSprite?
    property current_animation : String = "idle"
    property animations : Hash(String, AnimationData) = {} of String => AnimationData
    property conversation_partner : Character?

    # Données d'animation
    struct AnimationData
      property start_frame : Int32
      property frame_count : Int32
      property frame_speed : Float32
      property loop : Bool

      def initialize(@start_frame : Int32, @frame_count : Int32,
                     @frame_speed : Float32 = 0.1, @loop : Bool = true)
      end
    end

    def initialize(@name : String, position : RL::Vector2, size : RL::Vector2)
      super(position, size)
      @description = "A character named #{@name}"
      @dialogue_system = CharacterDialogue.new(self)
    end

    # Charge la spritesheet du personnage
    def load_spritesheet(path : String, frame_width : Int32, frame_height : Int32)
      @sprite = AnimatedSprite.new(@position, frame_width, frame_height, 1)
      @sprite.not_nil!.load_texture(path)
      @sprite.not_nil!.scale = calculate_scale(frame_width, frame_height)
    end

    # Ajoute une animation
    def add_animation(name : String, start_frame : Int32, frame_count : Int32,
                     frame_speed : Float32 = 0.1, loop : Bool = true)
      @animations[name] = AnimationData.new(start_frame, frame_count, frame_speed, loop)
    end

    # Change l'animation courante
    def play_animation(name : String)
      return unless @animations.has_key?(name)
      return if @current_animation == name

      @current_animation = name
      anim_data = @animations[name]

      if sprite = @sprite
        sprite.current_frame = anim_data.start_frame
        sprite.frame_count = anim_data.frame_count
        sprite.frame_speed = anim_data.frame_speed
        sprite.loop = anim_data.loop
        sprite.play
      end
    end

    # Fait marcher le personnage vers une position
    def walk_to(target : RL::Vector2)
      @target_position = target
      @state = CharacterState::Walking

      # Détermine la direction
      if target.x < @position.x
        @direction = Direction::Left
        play_animation("walk_left")
      else
        @direction = Direction::Right
        play_animation("walk_right")
      end
    end

    # Arrête le mouvement
    def stop_walking
      @target_position = nil
      @state = CharacterState::Idle
      play_animation("idle")
    end

    # Fait parler le personnage
    def say(text : String, &block : -> Nil)
      @state = CharacterState::Talking
      play_animation("talk")

      if dialogue = @dialogue_system
        dialogue.say(text) do
          @state = CharacterState::Idle
          play_animation("idle")
          block.call
        end
      end
    end

    # Fait parler le personnage avec choix
    def ask(question : String, choices : Array(Tuple(String, Proc(Nil))))
      @state = CharacterState::Talking
      play_animation("talk")

      if dialogue = @dialogue_system
        dialogue.ask(question, choices) do
          @state = CharacterState::Idle
          play_animation("idle")
        end
      end
    end

    # Met à jour le personnage
    def update(dt : Float32)
      return unless @active

      update_movement(dt)
      update_animation(dt)
      @dialogue_system.not_nil!.update(dt)
    end

    # Dessine le personnage
    def draw
      return unless @visible

      @sprite.try &.draw
      @dialogue_system.not_nil!.draw

      # Debug - dessine le nom au-dessus du personnage
      if Game.debug_mode
        RL.draw_text(@name, @position.x.to_i, (@position.y - 25).to_i, 16, RL::WHITE)
      end
    end

    # Méthodes abstraites à implémenter par les sous-classes
    abstract def on_interact(interactor : Character)
    abstract def on_look
    abstract def on_talk

    private def update_movement(dt : Float32)
      return unless @state == CharacterState::Walking
      return unless target = @target_position

      # Calcule la direction et la distance
      direction = RL::Vector2.new(x: target.x - @position.x, y: target.y - @position.y)
      distance = Math.sqrt(direction.x * direction.x + direction.y * direction.y)

      # Arrivé à destination
      if distance < 5.0
        @position = target
        stop_walking
        return
      end

      # Normalise la direction et applique la vitesse
      direction.x /= distance
      direction.y /= distance

      @position.x += direction.x * @walking_speed * dt
      @position.y += direction.y * @walking_speed * dt
    end

    private def update_animation(dt : Float32)
      @sprite.try &.update(dt)
    end

    private def calculate_scale(frame_width : Int32, frame_height : Int32) : Float32
      # Calcule un scale approprié basé sur la taille désirée du personnage
      Math.min(@size.x / frame_width, @size.y / frame_height)
    end
  end

  # Personnage joueur
  class Player < Character
    property inventory_access : Bool = true
    property movement_enabled : Bool = true

    def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
      super(name, position, size)
      setup_default_animations
    end

    def on_interact(interactor : Character)
      # Le joueur ne peut pas interagir avec lui-même
    end

    def on_look
      # Description par défaut du joueur
      say("That's me, #{@name}.")
    end

    def on_talk
      # Le joueur ne peut pas se parler à lui-même
      say("I'd rather talk to someone else.")
    end

    # Gestion des clics pour le mouvement
    def handle_click(target_pos : RL::Vector2, scene : Scene)
      return unless @movement_enabled
      return if @state == CharacterState::Talking

      # Vérifie s'il y a un hotspot ou un personnage à cette position
      if hotspot = scene.get_hotspot_at(target_pos)
        # Marche vers le hotspot puis l'active
        walk_to_and_interact(hotspot.position, hotspot)
      elsif character = scene.get_character_at(target_pos)
        # Marche vers le personnage puis interagit
        walk_to_and_interact(character.position, character)
      else
        # Simple mouvement
        walk_to(target_pos)
      end
    end

    private def walk_to_and_interact(target : RL::Vector2, object)
      walk_to(target)
      # TODO: Ajouter un callback pour l'interaction une fois arrivé
    end

    private def setup_default_animations
      # Animations par défaut - à personnaliser selon vos sprites
      add_animation("idle", 0, 1, 1.0, true)
      add_animation("walk_left", 1, 4, 0.15, true)
      add_animation("walk_right", 5, 4, 0.15, true)
      add_animation("talk", 9, 2, 0.3, true)
    end
  end

  # Personnage non-joueur (PNJ)
  class NPC < Character
    property dialogues : Array(String) = [] of String
    property current_dialogue_index : Int32 = 0
    property can_repeat_dialogues : Bool = true
    property interaction_distance : Float32 = 50.0
    property ai_behavior : NPCBehavior?
    property mood : NPCMood = NPCMood::Neutral

    enum NPCMood
      Friendly
      Neutral
      Hostile
      Sad
      Happy
      Angry
    end

    def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
      super(name, position, size)
      setup_default_animations
    end

    # Ajoute du dialogue au PNJ
    def add_dialogue(text : String)
      @dialogues << text
    end

    # Définit plusieurs dialogues
    def set_dialogues(dialogues : Array(String))
      @dialogues = dialogues
    end

    def on_interact(interactor : Character)
      return if @state == CharacterState::Talking

      # Oriente le PNJ vers l'interacteur
      face_character(interactor)

      # Lance le dialogue
      start_conversation(interactor)
    end

    def on_look
      say(@description)
    end

    def on_talk
      start_conversation(nil)
    end

    # Définit un comportement IA
    def set_ai_behavior(behavior : NPCBehavior)
      @ai_behavior = behavior
    end

    # Change l'humeur du PNJ
    def set_mood(mood : NPCMood)
      @mood = mood
      update_mood_animation
    end

    # Met à jour le PNJ
    def update(dt : Float32)
      super(dt)
      @ai_behavior.try &.update(self, dt)
    end

    private def face_character(character : Character)
      if character.position.x < @position.x
        @direction = Direction::Left
      else
        @direction = Direction::Right
      end
    end

    private def start_conversation(interactor : Character?)
      return if @dialogues.empty?

      dialogue_text = @dialogues[@current_dialogue_index]

      say(dialogue_text) do
        advance_dialogue
      end

      @conversation_partner = interactor
    end

    private def advance_dialogue
      @current_dialogue_index += 1

      if @current_dialogue_index >= @dialogues.size
        if @can_repeat_dialogues
          @current_dialogue_index = 0
        else
          @current_dialogue_index = @dialogues.size - 1
        end
      end
    end

    private def update_mood_animation
      case @mood
      when NPCMood::Happy
        play_animation("happy") if @animations.has_key?("happy")
      when NPCMood::Sad
        play_animation("sad") if @animations.has_key?("sad")
      when NPCMood::Angry
        play_animation("angry") if @animations.has_key?("angry")
      else
        play_animation("idle")
      end
    end

    private def setup_default_animations
      add_animation("idle", 0, 1, 1.0, true)
      add_animation("talk", 1, 2, 0.3, true)
      add_animation("happy", 3, 2, 0.5, true)
      add_animation("sad", 5, 1, 1.0, true)
      add_animation("angry", 6, 2, 0.2, true)
    end
  end

  # Système de dialogue pour les personnages
  class CharacterDialogue
    property character : Character
    property current_dialog : Dialog?
    property dialog_offset : RL::Vector2 = RL::Vector2.new(x: 0, y: -100)

    def initialize(@character : Character)
    end

    def say(text : String, &on_complete : -> Nil)
      dialog_pos = RL::Vector2.new(
        x: @character.position.x + @dialog_offset.x,
        y: @character.position.y + @dialog_offset.y
      )

      dialog_size = RL::Vector2.new(x: 300, y: 100)

      @current_dialog = Dialog.new(text, dialog_pos, dialog_size)
      @current_dialog.not_nil!.character = @character.name
      @current_dialog.not_nil!.on_complete = on_complete
      @current_dialog.not_nil!.show
    end

    def ask(question : String, choices : Array(Tuple(String, Proc(Nil))), &on_complete : -> Nil)
      dialog_pos = RL::Vector2.new(
        x: @character.position.x + @dialog_offset.x,
        y: @character.position.y + @dialog_offset.y
      )

      dialog_size = RL::Vector2.new(x: 400, y: 150 + choices.size * 30)

      @current_dialog = Dialog.new(question, dialog_pos, dialog_size)
      @current_dialog.not_nil!.character = @character.name

      choices.each do |choice_text, action|
        @current_dialog.not_nil!.add_choice(choice_text) do
          action.call
          on_complete.call
        end
      end

      @current_dialog.not_nil!.show
    end

    def update(dt : Float32)
      @current_dialog.try &.update(dt)

      # Nettoie le dialogue s'il n'est plus visible
      if dialog = @current_dialog
        unless dialog.visible
          @current_dialog = nil
        end
      end
    end

    def draw
      @current_dialog.try &.draw
    end
  end

  # Comportement IA pour les PNJ
  abstract class NPCBehavior
    abstract def update(npc : NPC, dt : Float32)
  end

  # Comportement de patrouille
  class PatrolBehavior < NPCBehavior
    property waypoints : Array(RL::Vector2) = [] of RL::Vector2
    property current_waypoint : Int32 = 0
    property wait_time : Float32 = 2.0
    property current_wait : Float32 = 0.0
    property patrol_speed : Float32 = 30.0

    def initialize(@waypoints : Array(RL::Vector2))
    end

    def update(npc : NPC, dt : Float32)
      return if npc.state == CharacterState::Talking
      return if @waypoints.empty?

      target = @waypoints[@current_waypoint]
      distance = Math.sqrt((target.x - npc.position.x)**2 + (target.y - npc.position.y)**2)

      if distance < 10.0
        # Arrivé au waypoint
        if npc.state == CharacterState::Walking
          npc.stop_walking
          @current_wait = 0.0
        end

        # Attendre
        @current_wait += dt
        if @current_wait >= @wait_time
          @current_waypoint = (@current_waypoint + 1) % @waypoints.size
          next_target = @waypoints[@current_waypoint]
          npc.walking_speed = @patrol_speed
          npc.walk_to(next_target)
        end
      end
    end
  end

  # Comportement aléatoire
  class RandomWalkBehavior < NPCBehavior
    property bounds : RL::Rectangle
    property walk_interval : Float32 = 5.0
    property walk_timer : Float32 = 0.0
    property walk_distance : Float32 = 100.0

    def initialize(@bounds : RL::Rectangle)
    end

    def update(npc : NPC, dt : Float32)
      return if npc.state == CharacterState::Talking

      @walk_timer += dt

      if @walk_timer >= @walk_interval && npc.state == CharacterState::Idle
        # Choisit une nouvelle destination aléatoire dans les limites
        angle = Random.rand * Math::PI * 2
        distance = Random.rand * @walk_distance

        new_x = npc.position.x + Math.cos(angle) * distance
        new_y = npc.position.y + Math.sin(angle) * distance

        # S'assure que la destination est dans les limites
        new_x = Math.max(@bounds.x, Math.min(@bounds.x + @bounds.width, new_x))
        new_y = Math.max(@bounds.y, Math.min(@bounds.y + @bounds.height, new_y))

        npc.walk_to(RL::Vector2.new(x: new_x, y: new_y))
        @walk_timer = 0.0
      end
    end
  end

  # Extension de la classe Scene pour gérer les personnages
  class Scene
    property characters : Array(Character) = [] of Character
    property player : Player?

    # Ajoute un personnage à la scène
    def add_character(character : Character)
      @characters << character
      @objects << character
    end

    # Définit le joueur de la scène
    def set_player(player : Player)
      @player = player
      add_character(player)
    end

    # Trouve un personnage à une position donnée
    def get_character_at(point : RL::Vector2) : Character?
      @characters.find { |c| c.active && c.contains_point?(point) }
    end

    # Trouve un personnage par nom
    def get_character(name : String) : Character?
      @characters.find { |c| c.name == name }
    end
  end
end

# Exemple d'utilisation :
#
# # Création du joueur
# player = PointClickEngine::Player.new("Hero", RL::Vector2.new(x: 100, y: 300), RL::Vector2.new(x: 32, y: 48))
# player.load_spritesheet("assets/hero_spritesheet.png", 32, 48)
#
# # Création d'un PNJ
# npc = PointClickEngine::NPC.new("Guard", RL::Vector2.new(x: 400, y: 300), RL::Vector2.new(x: 32, y: 48))
# npc.load_spritesheet("assets/guard_spritesheet.png", 32, 48)
# npc.add_dialogue("Halt! Who goes there?")
# npc.add_dialogue("You may pass, traveler.")
# npc.set_mood(PointClickEngine::NPC::NPCMood::Neutral)
#
# # Ajout d'un comportement de patrouille
# waypoints = [
#   RL::Vector2.new(x: 350, y: 300),
#   RL::Vector2.new(x: 450, y: 300),
#   RL::Vector2.new(x: 450, y: 250),
#   RL::Vector2.new(x: 350, y: 250)
# ]
# patrol = PointClickEngine::PatrolBehavior.new(waypoints)
# npc.set_ai_behavior(patrol)
#
# # Ajout à la scène
# scene.set_player(player)
# scene.add_character(npc)
