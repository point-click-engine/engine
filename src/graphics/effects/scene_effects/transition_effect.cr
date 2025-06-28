# Transition effects for scene changes using the new graphics system

require "./base_scene_effect"
require "raylib-cr"

module PointClickEngine
  module Graphics
    module Effects
      module SceneEffects
        # Enum for transition types
        enum TransitionType
          Fade
          Dissolve
          SlideLeft
          SlideRight
          SlideUp
          SlideDown
          Iris
          Swirl
          StarWipe
          HeartWipe
          Curtain
          Ripple
          Checkerboard
          Pixelate
          Warp
          Wave
          Glitch
          FilmBurn
          Static
          MatrixRain
          ZoomBlur
          ClockWipe
          BarnDoor
          PageTurn
          Shatter
          Vortex
          Fire
          CrossFade
        end

        # Scene transition effect
        class TransitionEffect < BaseSceneEffect
          getter transition_type : TransitionType
          getter reverse : Bool = false
          getter midpoint_callback : Proc(Nil)?
          
          @phase : Float32 = 0.0f32
          @midpoint_triggered : Bool = false
          @shader : RL::Shader?
          @render_texture : RL::RenderTexture2D?

          def initialize(@transition_type : TransitionType,
                         duration : Float32 = 1.0f32,
                         @reverse : Bool = false)
            super(duration)
            @affect_all_layers = true
            
            # Initialize render texture for shader-based effects
            @render_texture = RL.load_render_texture(Display::REFERENCE_WIDTH, Display::REFERENCE_HEIGHT)
            
            # Load shader if this is a shader-based transition
            load_shader_for_transition
          end

          # Set callback for midpoint (scene change)
          def on_midpoint(&block : -> Nil)
            @midpoint_callback = block
          end

          def update(dt : Float32)
            super(dt)
            
            # Trigger midpoint callback at 50%
            if !@midpoint_triggered && progress >= 0.5
              @midpoint_triggered = true
              puts "[TransitionEffect] Midpoint reached, triggering callback"
              @midpoint_callback.try(&.call)
            end
          end

          def apply_to_layer(context : Effects::EffectContext, layer : Layers::Layer)
            # Calculate phase (0-1 for first half, 1-0 for second half)
            @phase = (progress < 0.5 ? progress * 2.0 : 2.0 - (progress * 2.0)).to_f32
            
            # Only apply layer effects for slide transitions
            case @transition_type
            when .slide_left?, .slide_right?, .slide_up?, .slide_down?
              apply_slide(layer, context)
            else
              # For all other transitions, don't modify the layer
              # The visual effect is handled entirely in draw_overlay
              # This prevents backgrounds from disappearing
            end
          end

          private def apply_fade(layer : Layers::Layer)
            # Simple fade using layer opacity
            layer.opacity = (1.0 - @phase).to_f32
          end

          private def apply_dissolve(layer : Layers::Layer)
            # Use a more complex dissolve pattern
            layer.opacity = (1.0 - @phase).to_f32
            # Could add noise or dithering here
          end

          private def apply_slide(layer : Layers::Layer, context : Effects::EffectContext)
            # Slide based on direction
            # Use a default viewport width for now
            viewport_width = 1024.0f32
            offset = @phase * viewport_width
            
            case @transition_type
            when .slide_left?
              layer.offset.x = -offset
            when .slide_right?
              layer.offset.x = offset
            when .slide_up?
              layer.offset.y = -offset
            when .slide_down?
              layer.offset.y = offset
            end
          end

          # Apply transition effect (delegates to apply_to_layer)
          def apply(context : Effects::EffectContext)
            # Transition effects are applied at the layer level
            # This is handled by the scene effect system
          end

          # Draw overlay for transition effects
          def draw_overlay(renderer : PointClickEngine::Graphics::Renderer, width : Int32 = 1024, height : Int32 = 768)
            # For shader-based transitions, we need special handling
            # The shader effects work by modifying how the scene is displayed
            # For now, we'll render non-shader versions
            
            # Check if we have a shader but log that it's loaded
            if shader = @shader
              puts "[TransitionEffect] Shader loaded for #{@transition_type}, but using fallback rendering"
            end
            
            # Fallback to non-shader implementations
            case @transition_type
            when .fade?
              # Draw a black overlay with varying opacity based on phase
              opacity = (@phase * 255).to_u8
              RL.draw_rectangle(0, 0, width, height, RL::Color.new(r: 0, g: 0, b: 0, a: opacity))
            when .dissolve?
              # Similar to fade but could add noise/dithering
              opacity = (@phase * 255).to_u8
              RL.draw_rectangle(0, 0, width, height, RL::Color.new(r: 0, g: 0, b: 0, a: opacity))
            when .curtain?
              # Draw curtain effect (non-shader fallback)
              curtain_width = (width * @phase).to_i
              RL.draw_rectangle(0, 0, curtain_width, height, RL::BLACK)
              RL.draw_rectangle(width - curtain_width, 0, curtain_width, height, RL::BLACK)
            when .slide_left?, .slide_right?, .slide_up?, .slide_down?
              # Slides are handled through layer offsets, not overlays
              # No overlay needed
            else
              # For shader-based effects without shaders, use simple fade
              opacity = (@phase * 255).to_u8
              RL.draw_rectangle(0, 0, width, height, RL::Color.new(r: 0, g: 0, b: 0, a: opacity))
            end
          end

          def clone : Effect
            effect = TransitionEffect.new(@transition_type, @duration, @reverse)
            effect.on_midpoint { @midpoint_callback.try(&.call) }
            effect
          end
          
          # Cleanup shader and render texture
          def cleanup
            @shader.try { |s| RL.unload_shader(s) }
            @render_texture.try { |rt| RL.unload_render_texture(rt) }
          end
          
          # Load shader for the transition type
          private def load_shader_for_transition
            case @transition_type
            when .swirl?
              @shader = load_swirl_shader
            when .heart_wipe?
              @shader = load_heart_wipe_shader
            when .star_wipe?
              @shader = load_star_wipe_shader
            when .curtain?
              @shader = load_curtain_shader
            when .iris?
              @shader = load_iris_shader
            when .checkerboard?
              @shader = load_checkerboard_shader
            else
              # No shader needed for basic transitions
              @shader = nil
            end
          end
          
          # Common vertex shader for all transitions
          private def vertex_shader_source : String
            <<-SHADER
            #version 330 core
            in vec3 vertexPosition;
            in vec2 vertexTexCoord;
            in vec4 vertexColor;

            out vec2 fragTexCoord;
            out vec4 fragColor;

            uniform mat4 mvp;

            void main()
            {
                fragTexCoord = vertexTexCoord;
                fragColor = vertexColor;
                gl_Position = mvp * vec4(vertexPosition, 1.0);
            }
            SHADER
          end
          
          # Load swirl shader from the old implementation
          private def load_swirl_shader : RL::Shader?
            fragment_source = <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;

            uniform sampler2D texture0;
            uniform float progress;

            void main()
            {
                vec2 center = vec2(0.5, 0.5);
                vec2 tc = fragTexCoord - center;
                float dist = length(tc);
                float angle = atan(tc.y, tc.x);
                
                // Create swirl effect based on distance and progress
                float swirl = progress * 10.0 * (1.0 - dist);
                angle += swirl;
                
                vec2 swirlCoord = center + dist * vec2(cos(angle), sin(angle));
                
                if (swirlCoord.x < 0.0 || swirlCoord.x > 1.0 || swirlCoord.y < 0.0 || swirlCoord.y > 1.0) {
                    finalColor = vec4(0.0, 0.0, 0.0, 1.0);
                } else {
                    vec4 color = texture(texture0, swirlCoord);
                    float alpha = 1.0 - progress;
                    finalColor = vec4(color.rgb, color.a * alpha);
                }
            }
            SHADER
            
            load_shader_from_memory(vertex_shader_source, fragment_source)
          end
          
          # Load heart wipe shader from the old implementation
          private def load_heart_wipe_shader : RL::Shader?
            fragment_source = <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;

            uniform sampler2D texture0;
            uniform float progress;

            float dot2(vec2 v) { return dot(v,v); }

            float heart(vec2 p) {
                p.x = abs(p.x);
                if(p.y + p.x > 1.0)
                    return sqrt(dot2(p-vec2(0.25,0.75))) - sqrt(2.0)/4.0;
                return sqrt(min(dot2(p-vec2(0.00,1.00)),
                                dot2(p-0.5*max(p.x+p.y,0.0)))) * sign(p.x-p.y);
            }

            void main()
            {
                vec4 color = texture(texture0, fragTexCoord);
                vec2 center = (fragTexCoord - vec2(0.5, 0.5)) * 2.0;
                center.y = -center.y; // Flip Y for proper heart orientation
                float heartDist = heart(center);
                float threshold = (1.0 - progress) * 1.5 - 0.75; // Inverted progress for fade in
                float alpha = 1.0 - step(heartDist, threshold);
                finalColor = vec4(color.rgb, color.a * alpha);
            }
            SHADER
            
            load_shader_from_memory(vertex_shader_source, fragment_source)
          end
          
          # Load star wipe shader from the old implementation
          private def load_star_wipe_shader : RL::Shader?
            fragment_source = <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;

            uniform sampler2D texture0;
            uniform float progress;

            float star(vec2 p, float r, float n) {
                float an = 3.141593/n;
                float en = 3.141593/n;
                vec2 acs = vec2(cos(an),sin(an));
                vec2 ecs = vec2(cos(en),sin(en));
                float bn = mod(atan(p.x,p.y),2.0*an) - an;
                p = length(p)*vec2(cos(bn),abs(sin(bn)));
                p -= r*acs;
                p += ecs*clamp(-dot(p,ecs), 0.0, r*acs.y/ecs.y);
                return length(p)*sign(p.x);
            }

            void main()
            {
                vec4 color = texture(texture0, fragTexCoord);
                vec2 center = fragTexCoord - vec2(0.5, 0.5);
                float starDist = star(center, 0.3, 5.0);
                float threshold = (progress - 0.5) * 0.8;
                float alpha = step(threshold, starDist);
                finalColor = vec4(color.rgb, color.a * alpha);
            }
            SHADER
            
            load_shader_from_memory(vertex_shader_source, fragment_source)
          end
          
          # Load curtain shader
          private def load_curtain_shader : RL::Shader?
            fragment_source = <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;

            uniform sampler2D texture0;
            uniform float progress;

            void main()
            {
                vec4 color = texture(texture0, fragTexCoord);
                
                // Curtains close from left and right
                float leftCurtain = progress * 0.5;
                float rightCurtain = 1.0 - progress * 0.5;
                
                float alpha = 1.0;
                if (fragTexCoord.x < leftCurtain || fragTexCoord.x > rightCurtain) {
                    alpha = 0.0;
                }
                
                finalColor = vec4(color.rgb, color.a * alpha);
            }
            SHADER
            
            load_shader_from_memory(vertex_shader_source, fragment_source)
          end
          
          # Load iris shader
          private def load_iris_shader : RL::Shader?
            fragment_source = <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;

            uniform sampler2D texture0;
            uniform float progress;

            void main()
            {
                vec4 color = texture(texture0, fragTexCoord);
                vec2 center = fragTexCoord - vec2(0.5, 0.5);
                float dist = length(center);
                float radius = (1.0 - progress) * 0.7071; // sqrt(0.5) to cover corners
                float alpha = smoothstep(radius - 0.01, radius, dist);
                finalColor = vec4(color.rgb, color.a * (1.0 - alpha));
            }
            SHADER
            
            load_shader_from_memory(vertex_shader_source, fragment_source)
          end
          
          # Load checkerboard shader
          private def load_checkerboard_shader : RL::Shader?
            fragment_source = <<-SHADER
            #version 330 core
            in vec2 fragTexCoord;
            in vec4 fragColor;
            out vec4 finalColor;

            uniform sampler2D texture0;
            uniform float progress;

            void main()
            {
                vec4 color = texture(texture0, fragTexCoord);
                float size = 10.0;
                vec2 p = floor(fragTexCoord * size);
                float checker = mod(p.x + p.y, 2.0);
                float alpha = progress > checker * 0.5 + 0.5 ? 0.0 : 1.0;
                finalColor = vec4(color.rgb, color.a * alpha);
            }
            SHADER
            
            load_shader_from_memory(vertex_shader_source, fragment_source)
          end
          
          # Load shader from memory
          private def load_shader_from_memory(vertex_source : String, fragment_source : String) : RL::Shader?
            begin
              shader = RL.load_shader_from_memory(vertex_source, fragment_source)
              if shader.id > 0
                puts "[TransitionEffect] Successfully loaded shader for #{@transition_type}"
                return shader
              else
                puts "[TransitionEffect] Failed to load shader - invalid shader ID"
                return nil
              end
            rescue ex
              puts "[TransitionEffect] Failed to load shader - #{ex.message}"
              return nil
            end
          end
          
          # Render scene with transition shader
          def render_with_shader(&block : -> Nil)
            return yield unless shader = @shader
            return yield unless render_texture = @render_texture
            
            # Render scene to texture
            RL.begin_texture_mode(render_texture)
            RL.clear_background(RL::BLANK)
            yield  # Render the scene
            RL.end_texture_mode
            
            # Apply shader and draw the texture
            RL.begin_shader_mode(shader)
            
            # Set progress uniform
            progress_loc = RL.get_shader_location(shader, "progress")
            RL.set_shader_value(shader, progress_loc, pointerof(@phase), RL::ShaderUniformDataType::Float)
            
            # Draw the render texture with shader applied
            RL.draw_texture_rec(
              render_texture.texture,
              RL::Rectangle.new(x: 0, y: 0, width: render_texture.texture.width.to_f32, height: -render_texture.texture.height.to_f32),
              RL::Vector2.new(x: 0, y: 0),
              RL::WHITE
            )
            
            RL.end_shader_mode
          end

          # Draw swirl transition effect
          private def draw_swirl_effect(width : Int32, height : Int32)
            center_x = width / 2
            center_y = height / 2
            
            # Create a spiral that rotates and grows/shrinks
            spiral_arms = 6
            max_radius = Math.sqrt(center_x * center_x + center_y * center_y).to_f32
            
            # Fill entire screen with black
            RL.draw_rectangle(0, 0, width, height, RL::BLACK)
            
            # Draw spiral cutout that reveals the scene
            points = 200
            points.times do |i|
              t = i.to_f / points
              
              # Create multiple spiral arms
              spiral_arms.times do |arm|
                # Spiral equation: r = a + b * theta
                theta = t * Math::PI * 8 + @phase * Math::PI * 4  # Multiple rotations
                arm_offset = arm * Math::PI * 2 / spiral_arms
                
                # Radius grows from center based on angle and shrinks with phase
                r = (1.0 - @phase) * max_radius * (0.1 + t * 0.9)
                
                # Calculate position
                x = center_x + Math.cos(theta + arm_offset) * r
                y = center_y + Math.sin(theta + arm_offset) * r
                
                # Draw circles to create smooth spiral
                circle_size = ((1.0 - @phase) * 40 * (1.0 - t * 0.5)).to_i
                if circle_size > 0
                  # Use white to "cut through" the black overlay
                  RL.draw_circle(x.to_i, y.to_i, circle_size, RL::WHITE)
                end
              end
            end
            
            # Center circle
            center_size = ((1.0 - @phase) * 80).to_i
            if center_size > 0
              RL.draw_circle(center_x, center_y, center_size, RL::WHITE)
            end
          end

          # Draw heart wipe transition
          private def draw_heart_wipe(width : Int32, height : Int32)
            center_x = width / 2
            center_y = height / 2
            
            # Start with full black screen
            RL.draw_rectangle(0, 0, width, height, RL::BLACK)
            
            # Scale grows from 0 to reveal the scene
            scale = (1.0 - @phase) * 1.5
            
            if scale > 0.01
              # Draw heart shape using many circles
              # Heart parametric equation
              steps = 100
              (0..steps).each do |i|
                t = (i.to_f / steps) * Math::PI * 2
                
                # Heart shape equations
                x = 16 * Math.sin(t) ** 3
                y = -(13 * Math.cos(t) - 5 * Math.cos(2*t) - 2 * Math.cos(3*t) - Math.cos(4*t))
                
                # Scale and position
                px = center_x + x * scale * 8
                py = center_y + y * scale * 8 + 50  # Shift down
                
                # Draw circles along the heart outline
                RL.draw_circle(px.to_i, py.to_i, (scale * 25).to_i, RL::WHITE)
              end
              
              # Fill the heart interior with circles
              grid_size = 10
              (-50..50).step(grid_size) do |gx|
                (-50..50).step(grid_size) do |gy|
                  # Check if point is inside heart
                  # Simplified check using distance from center
                  test_x = gx.to_f / 50.0
                  test_y = gy.to_f / 50.0
                  
                  # Heart interior test
                  if (test_x * test_x + test_y * test_y) < 1.0
                    px = center_x + gx * scale * 3
                    py = center_y + gy * scale * 3 + 50
                    RL.draw_circle(px.to_i, py.to_i, (scale * 15).to_i, RL::WHITE)
                  end
                end
              end
            end
          end

          # Draw star wipe transition
          private def draw_star_wipe(width : Int32, height : Int32)
            center_x = width / 2
            center_y = height / 2
            
            # Fill screen with black
            RL.draw_rectangle(0, 0, width, height, RL::BLACK)
            
            # Scale grows to reveal the scene
            scale = (1.0 - @phase) * 1.2
            
            if scale > 0.01
              # Draw a 5-pointed star
              star_points = 5
              outer_radius = scale * Math.min(width, height) * 0.5
              inner_radius = outer_radius * 0.4
              
              # Create star points
              points = [] of RL::Vector2
              
              (0...(star_points * 2)).each do |i|
                angle = (i.to_f / (star_points * 2)) * Math::PI * 2 - Math::PI / 2
                
                # Alternate between outer and inner radius
                radius = (i % 2 == 0) ? outer_radius : inner_radius
                
                x = center_x + Math.cos(angle) * radius
                y = center_y + Math.sin(angle) * radius
                points << RL::Vector2.new(x: x.to_f32, y: y.to_f32)
              end
              
              # Draw the star as triangles from center
              if points.size > 2
                center_point = RL::Vector2.new(x: center_x.to_f32, y: center_y.to_f32)
                
                (0...points.size).each do |i|
                  next_i = (i + 1) % points.size
                  RL.draw_triangle(center_point, points[i], points[next_i], RL::WHITE)
                end
              end
              
              # Smooth the edges with circles
              points.each do |point|
                RL.draw_circle(point.x.to_i, point.y.to_i, (scale * 20).to_i, RL::WHITE)
              end
            end
          end

          # Draw iris (circular) transition
          private def draw_iris_effect(width : Int32, height : Int32)
            center_x = width / 2
            center_y = height / 2
            max_radius = Math.sqrt(center_x * center_x + center_y * center_y).to_f32
            current_radius = max_radius * (1.0 - @phase)
            
            # Draw black everywhere except the circle
            RL.draw_rectangle(0, 0, width, height, RL::BLACK)
            
            # Draw clear circle (this would need a stencil buffer or render texture in practice)
            # For now, we'll approximate with segments
            segments = 64
            angle_step = (Math::PI * 2) / segments
            
            segments.times do |i|
              angle1 = i * angle_step
              angle2 = (i + 1) * angle_step
              
              x1 = center_x + Math.cos(angle1) * current_radius
              y1 = center_y + Math.sin(angle1) * current_radius
              x2 = center_x + Math.cos(angle2) * current_radius
              y2 = center_y + Math.sin(angle2) * current_radius
              
              # Draw triangle fan from center
              RL.draw_triangle(
                RL::Vector2.new(x: center_x.to_f32, y: center_y.to_f32),
                RL::Vector2.new(x: x1.to_f32, y: y1.to_f32),
                RL::Vector2.new(x: x2.to_f32, y: y2.to_f32),
                RL::WHITE
              )
            end
          end

          # Draw checkerboard transition
          private def draw_checkerboard_effect(width : Int32, height : Int32)
            square_size = 64
            rows = (height.to_f / square_size).ceil.to_i + 1
            cols = (width.to_f / square_size).ceil.to_i + 1
            
            # Draw checkerboard pattern based on phase
            rows.times do |row|
              cols.times do |col|
                # Calculate if this square should be visible
                checker_phase = ((row + col) % 2).to_f / 2.0 + 0.5
                if @phase > checker_phase
                  x = col * square_size
                  y = row * square_size
                  RL.draw_rectangle(x, y, square_size, square_size, RL::BLACK)
                end
              end
            end
          end

          # Draw clock wipe transition
          private def draw_clock_wipe(width : Int32, height : Int32)
            center_x = width / 2
            center_y = height / 2
            radius = Math.sqrt(center_x * center_x + center_y * center_y).to_f32
            
            # Calculate sweep angle based on phase
            sweep_angle = @phase * Math::PI * 2
            
            # Draw pie slice
            segments = 64
            segment_angle = sweep_angle / segments
            
            # Draw black background
            RL.draw_rectangle(0, 0, width, height, RL::BLACK)
            
            # Draw swept area as triangles
            segments.times do |i|
              angle1 = -Math::PI / 2  # Start from top
              angle2 = -Math::PI / 2 + (i + 1) * segment_angle
              
              x1 = center_x + Math.cos(angle1) * radius
              y1 = center_y + Math.sin(angle1) * radius
              x2 = center_x + Math.cos(angle2) * radius
              y2 = center_y + Math.sin(angle2) * radius
              
              RL.draw_triangle(
                RL::Vector2.new(x: center_x.to_f32, y: center_y.to_f32),
                RL::Vector2.new(x: x1.to_f32, y: y1.to_f32),
                RL::Vector2.new(x: x2.to_f32, y: y2.to_f32),
                RL::WHITE
              )
            end
          end

          # Draw barn door transition
          private def draw_barn_door_effect(width : Int32, height : Int32)
            door_width = (width * @phase / 2).to_i
            
            # Draw left door
            RL.draw_rectangle(0, 0, door_width, height, RL::BLACK)
            
            # Draw right door
            RL.draw_rectangle(width - door_width, 0, door_width, height, RL::BLACK)
            
            # Add door handle details for visual interest
            if @phase > 0.1
              handle_size = 20
              handle_y = height / 2
              
              # Left door handle
              RL.draw_circle(door_width - 10, handle_y, handle_size / 2, RL::DARKGRAY)
              
              # Right door handle  
              RL.draw_circle(width - door_width + 10, handle_y, handle_size / 2, RL::DARKGRAY)
            end
          end
        end

        # Factory method for creating transitions
        def self.create_transition(type : TransitionType, duration : Float32 = 1.0f32) : TransitionEffect
          TransitionEffect.new(type, duration)
        end
      end
    end
  end
end