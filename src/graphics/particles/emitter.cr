# Particle emitter with various emission patterns

require "./particle"

module PointClickEngine
  module Graphics
    module Particles
      # Emission shape types
      enum EmissionShape
        Point      # Emit from a single point
        Circle     # Emit from circle perimeter
        CircleArea # Emit from within circle
        Rectangle  # Emit from rectangle perimeter
        RectArea   # Emit from within rectangle
        Line       # Emit along a line
        Cone       # Emit in a cone shape
        Ring       # Emit from a ring (donut)
      end

      # Particle emitter configuration
      struct EmitterConfig
        # Emission properties
        property emission_rate : Float32 = 10.0f32 # Particles per second
        property burst_count : Int32 = 0           # For burst emissions
        property max_particles : Int32 = 1000      # Maximum alive particles
        property emission_shape : EmissionShape = EmissionShape::Point
        property emission_radius : Float32 = 0.0f32                            # For circle shapes
        property emission_angle : Float32 = 360.0f32                           # For cone shape (degrees)
        property emission_size : RL::Vector2 = RL::Vector2.new(x: 100, y: 100) # For rect shapes

        # Particle properties (with ranges for randomization)
        property lifetime_min : Float32 = 1.0f32
        property lifetime_max : Float32 = 2.0f32
        property speed_min : Float32 = 50.0f32
        property speed_max : Float32 = 150.0f32
        property size_min : Float32 = 2.0f32
        property size_max : Float32 = 5.0f32
        property size_over_lifetime : Bool = false      # Shrink/grow over time
        property end_size_multiplier : Float32 = 0.0f32 # Final size multiplier

        # Movement
        property direction : RL::Vector2 = RL::Vector2.new(x: 0, y: -1) # Up by default
        property spread : Float32 = 45.0f32                             # Spread angle in degrees
        property gravity : RL::Vector2 = RL::Vector2.new(x: 0, y: 100)
        property use_world_space : Bool = true # Particles in world vs local space
        property rotation_min : Float32 = 0.0f32
        property rotation_max : Float32 = 0.0f32
        property rotation_speed_min : Float32 = 0.0f32
        property rotation_speed_max : Float32 = 0.0f32

        # Appearance
        property start_color : RL::Color = RL::WHITE
        property end_color : RL::Color = RL::WHITE
        property color_variation : Float32 = 0.0f32 # 0-1, how much to vary color
        property fade_in_time : Float32 = 0.0f32
        property fade_out_time : Float32 = 0.1f32
        property texture : RL::Texture2D?
        property texture_rect : RL::Rectangle?

        def initialize
        end
      end

      # Particle emitter
      class Emitter
        getter config : EmitterConfig
        getter particles : Array(Particle)
        property position : RL::Vector2
        property active : Bool = true
        getter emission_timer : Float32 = 0.0f32

        # Particle pool for reuse
        @particle_pool : Array(Particle)

        def initialize(@position : RL::Vector2, @config : EmitterConfig = EmitterConfig.new)
          @particles = [] of Particle
          @particle_pool = [] of Particle
        end

        # Update emitter and particles
        def update(dt : Float32)
          # Update existing particles
          @particles.each { |p| p.update(dt, @config.gravity) }

          # Remove dead particles (return to pool)
          @particles.reject! do |particle|
            if !particle.alive?
              @particle_pool << particle if @particle_pool.size < 100
              true
            else
              false
            end
          end

          # Emit new particles
          emit_particles(dt) if @active
        end

        # Draw all particles
        def draw
          @particles.each(&.draw)
        end

        # Draw with render context
        def draw_with_context(context : PointClickEngine::Graphics::RenderContext)
          @particles.each { |p| p.draw_with_context(context) }
        end

        # Start emitting
        def start
          @active = true
        end

        # Stop emitting (particles continue to update)
        def stop
          @active = false
        end

        # Clear all particles
        def clear
          @particles.clear
        end

        # Emit a burst of particles
        def burst(count : Int32? = nil)
          burst_amount = count || @config.burst_count
          burst_amount.times { emit_single_particle }
        end

        # Get particle count
        def particle_count : Int32
          @particles.size
        end

        # Check if emitter has particles
        def has_particles? : Bool
          !@particles.empty?
        end

        private def emit_particles(dt : Float32)
          return if @particles.size >= @config.max_particles

          @emission_timer += dt
          particles_to_emit = 0

          # Calculate how many particles to emit
          while @emission_timer >= 1.0f32 / @config.emission_rate
            particles_to_emit += 1
            @emission_timer -= 1.0f32 / @config.emission_rate
          end

          # Emit particles
          particles_to_emit.times do
            break if @particles.size >= @config.max_particles
            emit_single_particle
          end
        end

        private def emit_single_particle
          # Get spawn position based on emission shape
          spawn_pos = calculate_spawn_position

          # Calculate velocity
          velocity = calculate_initial_velocity

          # Random properties
          lifetime = Random.rand(@config.lifetime_min.to_f32..@config.lifetime_max.to_f32)
          size = Random.rand(@config.size_min.to_f32..@config.size_max.to_f32)
          rotation = Random.rand(@config.rotation_min.to_f32..@config.rotation_max.to_f32)
          rotation_speed = Random.rand(@config.rotation_speed_min.to_f32..@config.rotation_speed_max.to_f32)

          # Color with variation
          color = apply_color_variation(@config.start_color)

          # Get or create particle
          particle = get_or_create_particle
          particle.reset(spawn_pos, velocity, size, color, lifetime)

          # Set additional properties
          particle.end_size = size * @config.end_size_multiplier if @config.size_over_lifetime
          particle.end_color = @config.end_color
          particle.rotation = rotation
          particle.rotation_speed = rotation_speed
          particle.gravity_affected = @config.gravity.x != 0 || @config.gravity.y != 0
          particle.fade_in_time = @config.fade_in_time
          particle.fade_out_time = @config.fade_out_time
          particle.texture = @config.texture
          particle.texture_rect = @config.texture_rect

          @particles << particle
        end

        private def get_or_create_particle : Particle
          if particle = @particle_pool.pop?
            particle
          else
            Particle.new(
              RL::Vector2.new(x: 0, y: 0),
              RL::Vector2.new(x: 0, y: 0),
              1.0f32,
              RL::WHITE,
              1.0f32
            )
          end
        end

        private def calculate_spawn_position : RL::Vector2
          case @config.emission_shape
          when .point?
            @position.dup
          when .circle?
            angle = Random.rand(0.to_f32..Math::PI*2.to_f32)
            RL::Vector2.new(
              x: @position.x + Math.cos(angle).to_f32 * @config.emission_radius,
              y: @position.y + Math.sin(angle).to_f32 * @config.emission_radius
            )
          when .circle_area?
            angle = Random.rand(0.to_f32..Math::PI*2.to_f32)
            radius = Random.rand(0.0..@config.emission_radius)
            RL::Vector2.new(
              x: @position.x + Math.cos(angle).to_f32 * radius,
              y: @position.y + Math.sin(angle).to_f32 * radius
            )
          when .rectangle?
            # Random point on rectangle perimeter
            side = Random.rand(4)
            case side
            when 0 # Top
              RL::Vector2.new(
                x: @position.x + Random.rand(-@config.emission_size.x/2..@config.emission_size.x/2),
                y: @position.y - @config.emission_size.y/2
              )
            when 1 # Right
              RL::Vector2.new(
                x: @position.x + @config.emission_size.x/2,
                y: @position.y + Random.rand(-@config.emission_size.y/2..@config.emission_size.y/2)
              )
            when 2 # Bottom
              RL::Vector2.new(
                x: @position.x + Random.rand(-@config.emission_size.x/2..@config.emission_size.x/2),
                y: @position.y + @config.emission_size.y/2
              )
            else # Left
              RL::Vector2.new(
                x: @position.x - @config.emission_size.x/2,
                y: @position.y + Random.rand(-@config.emission_size.y/2..@config.emission_size.y/2)
              )
            end
          when .rect_area?
            RL::Vector2.new(
              x: @position.x + Random.rand(-@config.emission_size.x/2..@config.emission_size.x/2),
              y: @position.y + Random.rand(-@config.emission_size.y/2..@config.emission_size.y/2)
            )
          when .line?
            t = Random.rand(0.0f32..1.0f32)
            RL::Vector2.new(
              x: @position.x + @config.emission_size.x * (t - 0.5),
              y: @position.y
            )
          when .cone?
            # Emit from point with angle constraint
            @position.dup
          when .ring?
            angle = Random.rand(0.to_f32..Math::PI*2.to_f32)
            inner_radius = @config.emission_radius * 0.7f32
            radius = Random.rand(inner_radius.to_f32..@config.emission_radius.to_f32)
            RL::Vector2.new(
              x: @position.x + Math.cos(angle).to_f32 * radius,
              y: @position.y + Math.sin(angle).to_f32 * radius
            )
          else
            @position.dup
          end
        end

        private def calculate_initial_velocity : RL::Vector2
          speed = Random.rand(@config.speed_min.to_f32..@config.speed_max.to_f32)

          # Base direction
          dir_angle = Math.atan2(@config.direction.y, @config.direction.x)

          # Add spread
          spread_radians = @config.spread * Math::PI / 180.0
          angle_offset = Random.rand(-spread_radians/2.to_f32..spread_radians/2.to_f32)

          # Special handling for cone shape
          if @config.emission_shape.cone?
            cone_half_angle = @config.emission_angle * Math::PI / 360.0
            angle_offset = Random.rand(-cone_half_angle.to_f32..cone_half_angle.to_f32)
          end

          final_angle = dir_angle + angle_offset

          RL::Vector2.new(
            x: Math.cos(final_angle).to_f32 * speed,
            y: Math.sin(final_angle).to_f32 * speed
          )
        end

        private def apply_color_variation(base_color : RL::Color) : RL::Color
          return base_color if @config.color_variation == 0

          variation = @config.color_variation

          r = (base_color.r + Random.rand(-variation.to_f32..variation.to_f32) * 255).clamp(0, 255).to_u8
          g = (base_color.g + Random.rand(-variation.to_f32..variation.to_f32) * 255).clamp(0, 255).to_u8
          b = (base_color.b + Random.rand(-variation.to_f32..variation.to_f32) * 255).clamp(0, 255).to_u8

          RL::Color.new(r: r, g: g, b: b, a: base_color.a)
        end
      end
    end
  end
end
