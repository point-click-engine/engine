# Player character with 8-directional animations and adventure game features

require "yaml"
require "./animation_controller"

module PointClickEngine
  # # Character system for adventure game protagonists and NPCs.
  ##
  # # The `Characters` module provides a complete character system with:
  # # - Base character functionality for all game entities
  # # - Specialized player character with inventory integration
  # # - NPC system with AI behaviors and scheduling
  # # - Advanced animation with 8-directional movement
  # # - Dialog and interaction systems
  # # - Mood and personality traits
  ##
  # # ## Character Hierarchy
  ##
  # # ```
  # # Character (abstract base)
  # # ├── Player (protagonist)
  # # ├── NPC (non-player characters)
  # # │   ├── SimpleNPC (basic NPCs)
  # # │   └── ScriptableCharacter (Lua-driven)
  # # └── Character (8-dir animations)
  # # ```
  ##
  # # ## Animation System
  ##
  # # ```crystal
  # # # Characters support multiple animation states
  # # character.play_animation("walk_left")
  # # character.set_animation_state(AnimationState::Talking)
  ##
  # # # 8-directional movement for modern games
  # # direction = Direction8.from_velocity(velocity)
  # # character.play_animation(state, direction)
  # # ```
  ##
  # # ## AI Behaviors
  ##
  # # ```crystal
  # # # NPCs can have complex behaviors
  # # guard = NPC.new("Guard", pos, size)
  # # guard.behavior = PatrolBehavior.new([point1, point2, point3])
  # # guard.mood = CharacterMood::Suspicious
  # # ```
  ##
  # # ## Dialog Integration
  ##
  # # ```crystal
  # # # Characters can engage in conversations
  # # npc.on_talk do |player|
  # #   dialog_tree = load_dialog("guard_conversation")
  # #   dialog_tree.start(player, npc)
  # # end
  # # ```
  ##
  # # ## Common Patterns
  ##
  # # ### Creating Interactive NPCs
  # # ```crystal
  # # shopkeeper = NPC.new("Shopkeeper", Vector2.new(400, 300), Vector2.new(64, 96))
  # # shopkeeper.load_spritesheet("shopkeeper.png", 64, 96)
  # # shopkeeper.add_idle_animation
  # # shopkeeper.mood = CharacterMood::Friendly
  ##
  # # shopkeeper.on_interact = ->(player : Character) {
  # #   if player.has_item?("money")
  # #     open_shop_interface
  # #   else
  # #     shopkeeper.say("Come back when you have money!")
  # #   end
  # # }
  # # ```
  ##
  # # ### Player Character Setup
  # # ```crystal
  # # player = Player.new("Hero", start_position, Vector2.new(32, 48))
  # # player.load_enhanced_spritesheet("hero_8dir.png", 32, 48, 8, 4)
  # # player.movement_enabled = true
  # # player.inventory_access = true
  # # ```
  ##
  # # ## See Also
  ##
  # # - `AI::NPCBehavior` - NPC behavior patterns
  # # - `Dialogue::DialogTree` - Conversation system
  # # - `AnimationController` - Animation management
  # # - `Inventory::InventorySystem` - Player inventory
  module Characters
    # # The main player character with inventory and interaction capabilities.
    ##
    # # `Player` represents the protagonist that the user controls. It extends
    # # `Character` with player-specific features like inventory access,
    # # item usage, and special interaction callbacks. The player character
    # # serves as the primary interface between the user and the game world.
    ##
    # # ## Features
    ##
    # # - 8-directional walking animations
    # # - Context-specific action animations (pick up, use, examine)
    # # - Inventory system integration
    # # - Movement enable/disable for cutscenes
    # # - Special idle and personality animations
    # # - Interaction callbacks for game logic
    ##
    # # ## Basic Setup
    ##
    # # ```crystal
    # # # Create player character
    # # player = Player.new("Alex", Vector2.new(400, 300), Vector2.new(32, 48))
    ##
    # # # Load animated sprite sheet
    # # player.load_enhanced_spritesheet("alex_sprites.png", 32, 48, 8, 4)
    # # # 8 columns for directions, 4 rows for animation states
    ##
    # # # Add to scene
    # # scene.player = player
    # # ```
    ##
    # # ## Movement Control
    ##
    # # ```crystal
    # # # Player automatically handles click-to-walk
    # # player.handle_click(mouse_pos, scene)
    ##
    # # # Disable during cutscenes
    # # player.movement_enabled = false
    # # cutscene.play
    # # cutscene.on_complete = -> { player.movement_enabled = true }
    # # ```
    ##
    # # ## Item Interactions
    ##
    # # ```crystal
    # # # Using items on objects
    # # player.use_item_on_target(door_position)
    # # # Plays "using" animation facing the door
    ##
    # # # Picking up items
    # # player.pick_up_item(key_position)
    # # # Plays "picking up" animation and faces item
    ##
    # # # Examining objects
    # # player.examine_object(painting_position)
    # # # Turns to face object without moving
    # # ```
    ##
    # # ## Inventory Integration
    ##
    # # ```crystal
    # # # Control inventory access
    # # player.inventory_access = false  # Disable during conversations
    ##
    # # # Check for items
    # # if player.inventory.has_item?("key")
    # #   player.use_item_on_target(door_position)
    # # end
    # # ```
    ##
    # # ## Interaction Callbacks
    ##
    # # ```crystal
    # # # Track what the player is interacting with
    # # player.on_interact_with = ->(target : Hotspot | Character, verb : Symbol) {
    # #   case verb
    # #   when :use
    # #     handle_use_interaction(target)
    # #   when :look
    # #     handle_examine(target)
    # #   when :talk
    # #     start_conversation(target) if target.is_a?(Character)
    # #   end
    # # }
    # # ```
    ##
    # # ## Common Gotchas
    ##
    # # 1. **Movement during dialogs**: Always disable movement during conversations
    # #    ```crystal
    # #    dialog.on_show = -> { player.movement_enabled = false }
    # #    dialog.on_hide = -> { player.movement_enabled = true }
    # #    ```
    ##
    # # 2. **Player is not automatically added to scene**: Must assign explicitly
    # #    ```crystal
    # #    scene.player = player  # Don't forget this!
    # #    ```
    ##
    # # 3. **Animation setup timing**: Load spritesheet after window init
    # #    ```crystal
    # #    engine.init
    # #    player.load_enhanced_spritesheet(...)  # After init
    # #    ```
    ##
    # # 4. **Interaction callbacks not serialized**: Re-register after loading
    # #    ```crystal
    # #    # After loading a save:
    # #    player.interaction_callback = original_callback
    # #    ```
    ##
    # # ## Customization
    ##
    # # ```crystal
    # # class CustomPlayer < Player
    # #   property stamina : Float32 = 100.0
    ##
    # #   def walk_to(target : Vector2)
    # #     if @stamina > 0
    # #       super
    # #       @stamina -= 1.0
    # #     else
    # #       say("I'm too tired to walk!")
    # #     end
    # #   end
    ##
    # #   def rest
    # #     perform_action(AnimationState::Sitting)
    # #     @stamina = Math.min(100.0, @stamina + 50.0)
    # #   end
    # # end
    # # ```
    ##
    # # ## Performance Notes
    ##
    # # - Player updates every frame when visible
    # # - Pathfinding calculations occur on click (can be expensive)
    # # - Animation frames cached for performance
    # # - Consider disabling when off-screen
    ##
    # # ## See Also
    ##
    # # - `Character` - Base class with 8-dir animations
    # # - `Inventory::InventorySystem` - Player inventory
    # # - `Scene#player` - Scene player management
    # # - `Engine#player` - Global player access
    class Player < Character
      include Talkable

      # # Whether the player can open their inventory.
      ##
      # # Disable during conversations, cutscenes, or puzzles to prevent
      # # players from accessing items at inappropriate times.
      property inventory_access : Bool = true

      # # Whether the player can move via mouse clicks.
      ##
      # # Disable during dialogs, cutscenes, or scripted sequences to
      # # prevent unwanted movement.
      property movement_enabled : Bool = true

      # # Callback tracking current interaction target and verb (runtime only).
      ##
      # # Used by the game logic to handle complex multi-step interactions.
      # # Format: {target_object, verb_symbol}
      @[YAML::Field(ignore: true)]
      property interaction_callback : Tuple(Scenes::Hotspot | Character, Symbol)?

      def initialize
        super()
        @name = "Player"
        @description = "That's me, #{@name}."
        @size = RL::Vector2.new(x: Core::GameConstants::DEFAULT_PLAYER_WIDTH, y: Core::GameConstants::DEFAULT_PLAYER_HEIGHT)
        setup_player_animations
      end

      def initialize(name : String, position : RL::Vector2, size : RL::Vector2)
        super(name, position, size)
        @name = name
        @description = "That's me, #{@name}."
        setup_player_animations
      end

      def after_yaml_deserialize(ctx : YAML::ParseContext)
        super(ctx)
        setup_player_animations
      end

      # Handle interactions with other characters
      def on_interact(interactor : Character)
        play_animation(AnimationState::Talking.to_s)
        say("Someone's trying to interact with me, #{@name}.") { }
      end

      # Handle look action
      def on_look
        play_animation(AnimationState::Talking.to_s)
        say("That's me, #{@name}.") { }
      end

      # Handle talk action
      def on_talk
        play_animation(AnimationState::Talking.to_s)
        say("I can't talk to myself!") { }
      end

      # # Handles mouse click for player movement.
      ##
      # # Validates the target position is walkable before initiating movement.
      # # Automatically selects appropriate walking animation based on direction.
      ##
      # # - *mouse_pos* : Click position in world coordinates
      # # - *scene* : Current scene for walkability checks
      ##
      # # ```crystal
      # # # In input handler
      # # if mouse_clicked
      # #   player.handle_click(mouse_world_pos, current_scene)
      # # end
      # # ```
      ##
      # # NOTE: Respects `movement_enabled` flag
      def handle_click(mouse_pos : RL::Vector2, scene : Scenes::Scene)
        if Core::DebugConfig.should_log?(:player_input)
          puts "[PLAYER] Mouse clicked at #{mouse_pos}, player at #{@position}"
        end

        return unless @movement_enabled

        # Don't move if clicking very close to current position
        distance_to_target = Math.sqrt((mouse_pos.x - @position.x)**2 + (mouse_pos.y - @position.y)**2)

        if Core::DebugConfig.should_log?(:player_input)
          puts "[PLAYER] Distance to target: #{distance_to_target}"
        end

        if distance_to_target < Core::GameConstants::MINIMUM_CLICK_DISTANCE # Minimum movement threshold
          if Core::DebugConfig.should_log?(:player_input)
            puts "[PLAYER] Click too close to current position, ignoring"
          end
          return
        end

        # If the target is walkable, move directly there
        if scene.is_walkable?(mouse_pos)
          if Core::DebugConfig.should_log?(:player_input)
            puts "[PLAYER] Target #{mouse_pos} is walkable, moving directly"
          end
          walk_to(mouse_pos, use_pathfinding: @use_pathfinding)
        else
          if Core::DebugConfig.should_log?(:player_input)
            puts "[PLAYER] Target #{mouse_pos} is not walkable, finding nearest walkable point"
          end

          # Find the nearest walkable point to the target
          if walkable_area = scene.walkable_area
            nearest_point = walkable_area.find_nearest_walkable_point(mouse_pos)

            if Core::DebugConfig.should_log?(:player_input)
              puts "[PLAYER] Nearest walkable point: #{nearest_point}"
            end

            # Only move if we found a walkable point that's different from target
            if scene.is_walkable?(nearest_point) &&
               ((nearest_point.x - mouse_pos.x).abs > Core::GameConstants::WALKABLE_POINT_TOLERANCE || (nearest_point.y - mouse_pos.y).abs > Core::GameConstants::WALKABLE_POINT_TOLERANCE)
              if Core::DebugConfig.should_log?(:player_input)
                puts "[PLAYER] Moving to nearest walkable point #{nearest_point}"
              end
              walk_to(nearest_point, use_pathfinding: @use_pathfinding)
            else
              if Core::DebugConfig.should_log?(:player_input)
                puts "[PLAYER] Nearest point #{nearest_point} is not suitable for movement"
              end
            end
          end
        end
      end

      # # Plays item usage animation facing the target.
      ##
      # # Character turns to face the target and plays the "using" animation.
      # # Useful for key-in-lock, lever pulling, button pressing animations.
      ##
      # # - *target_position* : Position of the object being used
      ##
      # # ```crystal
      # # if player.selected_item == "key"
      # #   player.use_item_on_target(door.position)
      # #   # Then handle the actual interaction
      # # end
      # # ```
      def use_item_on_target(target_position : RL::Vector2)
        play_animation(AnimationState::Using.to_s)
      end

      # # Plays item pickup animation facing the item.
      ##
      # # Character bends down or reaches out to pick up an item.
      # # The animation varies based on item height relative to character.
      ##
      # # - *item_position* : Position of the item being picked up
      ##
      # # ```crystal
      # # player.pick_up_item(coin.position)
      # # inventory.add_item(coin)
      # # scene.remove_object(coin)
      # # ```
      def pick_up_item(item_position : RL::Vector2)
        play_animation(AnimationState::PickingUp.to_s)
      end

      # # Turns character to look at an object without moving.
      ##
      # # Useful for examine actions where the player comments on something
      # # without walking to it. Uses idle animation in the appropriate direction.
      ##
      # # - *object_position* : Position to look towards
      ##
      # # ```crystal
      # # player.examine_object(painting.position)
      # # player.say("A beautiful landscape painting.")
      # # ```
      def examine_object(object_position : RL::Vector2)
        # Look in direction of object
        direction_vec = RL::Vector2.new(
          x: object_position.x - @position.x,
          y: object_position.y - @position.y
        )
        direction = Direction8.from_velocity(direction_vec)
        play_animation(AnimationState::Idle.to_s)
      end

      def push_object(object_position : RL::Vector2)
        play_animation(AnimationState::Pushing.to_s)
      end

      def pull_object(object_position : RL::Vector2)
        play_animation(AnimationState::Pulling.to_s)
      end

      # Walking with pathfinding
      def walk_to_with_path(path : Array(RL::Vector2))
        return if path.empty?

        @path = path
        @current_path_index = 0

        if path.size > 1
          # Calculate initial direction from first two waypoints
          velocity = RL::Vector2.new(
            x: path[1].x - path[0].x,
            y: path[1].y - path[0].y
          )
          @direction_8 = Direction8.from_velocity(velocity)
        end

        walk_to(path.first)
      end

      # Override stop_walking to return to idle properly
      def stop_walking
        super
        @movement_state = AnimationState::Idle
        @animation_controller.try(&.play_animation("idle"))
      end

      private def update_movement(dt : Float32)
        previous_state = @state
        super(dt)

        if previous_state == CharacterState::Walking && @state == CharacterState::Idle
          if callback_data = @interaction_callback
            target_object, action_method = callback_data
            case target_object
            when Scenes::Hotspot
              target_object.on_click.try &.call
            when Character
              if action_method == :on_interact
                target_object.on_interact(self)
              elsif action_method == :on_talk
                target_object.on_talk
              end
            end
            @interaction_callback = nil
          end
        end
      end

      # Setup player-specific animations
      private def setup_player_animations
        # Set up basic animations for compatibility
        @animation_controller.try(&.add_animation("idle", 0, 1, 0.1f32, true))
        @animation_controller.try(&.add_animation("idle_right", 0, 1, 0.1f32, true))
        @animation_controller.try(&.add_animation("idle_left", 0, 1, 0.1f32, true))
        @animation_controller.try(&.add_animation("walk_right", 4, 4, 0.1f32, true))
        @animation_controller.try(&.add_animation("walk_left", 8, 4, 0.1f32, true))
        @animation_controller.try(&.add_animation("talk", 32, 2, 0.3f32, true))
        @animation_controller.try(&.play_animation("idle_right"))

        # Add player-specific idle variations
        @animation_controller.try(&.add_idle_variation("check_inventory", 100, 8, 0.15))
        @animation_controller.try(&.add_idle_variation("look_around", 108, 6, 0.2))
        @animation_controller.try(&.add_idle_variation("tap_foot", 114, 4, 0.25))

        # Add action animations (assuming they start after walking animations)
        # Walking: frames 0-31 (8 directions × 4 frames)
        # Talking: frames 32-47 (8 directions × 2 frames)
        @animation_controller.try(&.add_directional_animation("talk", 32, 2, 0.3))

        # Action animations (single direction, will be mirrored/rotated as needed)
        @animation_controller.try(&.add_animation("pickup", 48, 6, 0.15, false))
        @animation_controller.try(&.add_animation("use", 54, 4, 0.2, false))
        @animation_controller.try(&.add_animation("push", 58, 6, 0.12, false))
        @animation_controller.try(&.add_animation("pull", 64, 6, 0.12, false))
        @animation_controller.try(&.add_animation("climb", 70, 8, 0.15, false))
        @animation_controller.try(&.add_animation("sit", 78, 1, 1.0, true))
        @animation_controller.try(&.add_animation("stand", 79, 3, 0.2, false))
        @animation_controller.try(&.add_animation("die", 82, 8, 0.3, false))
      end
    end
  end
end
