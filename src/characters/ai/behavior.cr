# AI Behavior system for NPCs

require "yaml"

module PointClickEngine
  module Characters
    module AI
      # Base class for NPC behaviors
      abstract class NPCBehavior
        abstract def update(npc : NPC, dt : Float32)

        def after_yaml_deserialize(ctx : YAML::ParseContext, npc : NPC)
        end
      end

      # Patrol behavior - moves between waypoints
      class PatrolBehavior < NPCBehavior
        include YAML::Serializable

        @[YAML::Field(ignore: true)]
        property waypoints : Array(RL::Vector2) = [] of RL::Vector2
        property current_waypoint_index : Int32 = 0
        property wait_time : Float32 = 2.0
        property current_wait_timer : Float32 = 0.0
        property patrol_speed : Float32 = 30.0

        def initialize
          @waypoints = [] of RL::Vector2
        end

        def initialize(@waypoints : Array(RL::Vector2))
        end

        def after_yaml_deserialize(ctx : YAML::ParseContext, npc : NPC)
          super(ctx, npc)
          if npc.state == CharacterState::Idle && !@waypoints.empty?
            npc.walking_speed = @patrol_speed
            npc.walk_to(@waypoints[@current_waypoint_index])
          end
        end

        def update(npc : NPC, dt : Float32)
          return if npc.state == CharacterState::Talking || @waypoints.empty?

          if npc.state == CharacterState::Idle
            @current_wait_timer += dt
            if @current_wait_timer >= @wait_time
              @current_wait_timer = 0.0
              @current_waypoint_index = (@current_waypoint_index + 1) % @waypoints.size
              next_target = @waypoints[@current_waypoint_index]
              npc.walking_speed = @patrol_speed
              npc.walk_to(next_target)
            end
          end
        end
      end

      # Random walk behavior - walks randomly within bounds
      class RandomWalkBehavior < NPCBehavior
        include YAML::Serializable

        @[YAML::Field(ignore: true)]
        property bounds : RL::Rectangle
        property walk_interval : Float32 = 5.0
        property walk_timer : Float32 = 0.0
        property walk_distance : Float32 = 100.0

        def initialize
          @bounds = RL::Rectangle.new
        end

        def initialize(@bounds : RL::Rectangle)
        end

        def after_yaml_deserialize(ctx : YAML::ParseContext, npc : NPC)
          super(ctx, npc)
          @walk_timer = Random.rand(@walk_interval)
        end

        def update(npc : NPC, dt : Float32)
          return if npc.state == CharacterState::Talking
          @walk_timer += dt

          if @walk_timer >= @walk_interval && npc.state == CharacterState::Idle
            angle = Random.rand * Math::PI * 2
            distance = Random.rand * @walk_distance
            new_x = npc.position.x + Math.cos(angle) * distance
            new_y = npc.position.y + Math.sin(angle) * distance

            new_x = new_x.clamp(@bounds.x, @bounds.x + @bounds.width)
            new_y = new_y.clamp(@bounds.y, @bounds.y + @bounds.height)

            npc.walk_to(RL::Vector2.new(x: new_x.to_f, y: new_y.to_f))
            @walk_timer = 0.0
          end
        end
      end

      # Idle behavior - just stands still
      class IdleBehavior < NPCBehavior
        include YAML::Serializable

        def initialize
        end

        def update(npc : NPC, dt : Float32)
          # Do nothing - just idle
        end
      end

      # Follow behavior - follows a target character
      class FollowBehavior < NPCBehavior
        include YAML::Serializable

        property target_name : String?
        @[YAML::Field(ignore: true)]
        property target : Character?
        property follow_distance : Float32 = 100.0
        property follow_speed : Float32 = 80.0

        def initialize
        end

        def initialize(@target : Character?, @follow_distance : Float32 = 100.0)
          @target_name = @target.try(&.name)
        end

        def after_yaml_deserialize(ctx : YAML::ParseContext, npc : NPC)
          super(ctx, npc)
          # Target will be re-linked by the engine after all characters are loaded
        end

        def update(npc : NPC, dt : Float32)
          return if npc.state == CharacterState::Talking
          return unless target = @target

          distance = Math.sqrt((target.position.x - npc.position.x)**2 + (target.position.y - npc.position.y)**2)

          if distance > @follow_distance
            npc.walking_speed = @follow_speed
            npc.walk_to(target.position)
          elsif npc.state == CharacterState::Walking && distance < @follow_distance * 0.8
            npc.stop_walking
          end
        end
      end
    end
  end
end
