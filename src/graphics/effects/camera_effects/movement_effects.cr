# Camera movement effects like follow, pan, and zoom

require "./base_camera_effect"

module PointClickEngine
  module Graphics
    module Effects
      module CameraEffects
        # Smooth follow effect for tracking targets
        class FollowEffect < BaseCameraEffect
          # Target to follow
          property target : RL::Vector2?
          property target_position : RL::Vector2?

          # Follow parameters
          property deadzone_width : Float32 = 100.0f32
          property deadzone_height : Float32 = 80.0f32
          property follow_speed : Float32 = 5.0f32
          property look_ahead : Float32 = 0.0f32 # How much to look ahead of movement
          property offset : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)

          # Smoothing
          @velocity : RL::Vector2 = RL::Vector2.new(x: 0, y: 0)

          def initialize(@target : RL::Vector2? = nil, duration : Float32 = 0.0f32)
            super(duration)
          end

          def apply_to_camera(camera : Graphics::Core::Camera, dt : Float32)
            # Get current target position
            target_pos = if pos = @target_position
                           pos
                         elsif t = @target
                           t
                         else
                           return # No target
                         end

            # Add offset
            target_x = target_pos.x + @offset.x
            target_y = target_pos.y + @offset.y

            # Calculate distance from camera center
            # TODO: Get viewport size from elsewhere since Graphics::Core::Camera doesn't have viewport
            viewport_width = 1280
            viewport_height = 720
            cam_center_x = camera.position.x + viewport_width / 2
            cam_center_y = camera.position.y + viewport_height / 2

            dx = target_x - cam_center_x
            dy = target_y - cam_center_y

            # Check if target is outside deadzone
            move_x = 0.0f32
            move_y = 0.0f32

            if dx.abs > @deadzone_width / 2
              move_x = dx - (dx > 0 ? @deadzone_width / 2 : -@deadzone_width / 2)
            end

            if dy.abs > @deadzone_height / 2
              move_y = dy - (dy > 0 ? @deadzone_height / 2 : -@deadzone_height / 2)
            end

            # Apply smoothing
            if @smoothing > 0
              # Exponential smoothing
              factor = 1.0f32 - Math.exp(-@follow_speed * dt)
              camera.position.x += move_x * factor
              camera.position.y += move_y * factor
            else
              # Instant follow
              camera.position.x += move_x
              camera.position.y += move_y
            end

            # Update velocity for look ahead
            if @look_ahead > 0
              @velocity.x = move_x
              @velocity.y = move_y

              camera.position.x += @velocity.x * @look_ahead * dt
              camera.position.y += @velocity.y * @look_ahead * dt
            end
          end
        end

        # Pan camera to a specific position
        class PanEffect < BaseCameraEffect
          property target_position : RL::Vector2
          property start_position : RL::Vector2?
          property pan_speed : Float32 = 200.0f32 # pixels per second
          property use_duration : Bool = true     # Use duration vs speed
          property easing : Proc(Float32, Float32) = ->(t : Float32) { t }

          @elapsed : Float32 = 0.0f32
          @total_distance : Float32 = 0.0f32

          def initialize(@target_position : RL::Vector2, duration : Float32 = 2.0f32)
            super(duration)
          end

          def reset
            super
            @elapsed = 0.0f32
            @start_position = nil
          end

          def apply_to_camera(camera : Graphics::Core::Camera, dt : Float32)
            # Initialize start position
            @start_position ||= camera.position.dup

            start = @start_position.not_nil!

            if @use_duration && @duration > 0
              # Duration-based panning
              @elapsed = Math.min(@elapsed + dt, @duration)
              t = @elapsed / @duration

              # Apply easing
              eased_t = @easing.call(t)

              # Interpolate position
              camera.position.x = start.x + (target_position.x - start.x) * eased_t
              camera.position.y = start.y + (target_position.y - start.y) * eased_t

              # Mark as finished when complete
              @finished = true if t >= 1.0f32
            else
              # Speed-based panning
              dx = target_position.x - camera.position.x
              dy = target_position.y - camera.position.y
              distance = Math.sqrt(dx * dx + dy * dy)

              if distance > 1.0f32
                # Normalize and apply speed
                move_distance = @pan_speed * dt
                ratio = Math.min(move_distance / distance, 1.0f32)

                camera.position.x += dx * ratio
                camera.position.y += dy * ratio
              else
                # Reached target
                camera.position = target_position
                @finished = true
              end
            end
          end
        end

        # Zoom effect for camera
        class ZoomEffect < BaseCameraEffect
          property target_zoom : Float32
          property start_zoom : Float32?
          property zoom_speed : Float32 = 2.0f32
          property zoom_center : RL::Vector2? # Point to zoom towards
          property easing : Proc(Float32, Float32) = ->(t : Float32) { t < 0.5 ? 4 * t * t * t : 1 - (-2 * t + 2) ** 3 / 2 }

          @elapsed : Float32 = 0.0f32

          def initialize(@target_zoom : Float32, duration : Float32 = 1.0f32)
            super(duration)
          end

          def reset
            super
            @elapsed = 0.0f32
            @start_zoom = nil
          end

          def apply_to_camera(camera : Graphics::Core::Camera, dt : Float32)
            # Graphics::Core::Camera doesn't support zoom yet
            # TODO: Implement zoom support in Graphics::Core::Camera
            return

            start = @start_zoom.not_nil!

            if @duration > 0
              # Duration-based zoom
              @elapsed = Math.min(@elapsed + dt, @duration)
              t = @elapsed / @duration

              # Apply easing
              eased_t = @easing.call(t)

              # Calculate new zoom
              new_zoom = start + (target_zoom - start) * eased_t

              # If zooming towards a point, adjust camera position
              if center = @zoom_center
                # Calculate how much the view will change
                zoom_ratio = new_zoom / camera.zoom

                # Adjust camera to keep center point in same screen position
                cam_center_x = camera.position.x + 1280 / 2
                cam_center_y = camera.position.y + 720 / 2

                offset_x = center.x - cam_center_x
                offset_y = center.y - cam_center_y

                camera.position.x += offset_x * (1 - zoom_ratio)
                camera.position.y += offset_y * (1 - zoom_ratio)
              end

              camera.zoom = new_zoom

              # Mark as finished
              @finished = true if t >= 1.0f32
            else
              # Instant zoom
              camera.zoom = target_zoom
              @finished = true
            end
          end
        end

        # Camera sway effect (gentle movement)
        class SwayEffect < BaseCameraEffect
          property amplitude_x : Float32 = 10.0f32
          property amplitude_y : Float32 = 5.0f32
          property frequency_x : Float32 = 0.5f32
          property frequency_y : Float32 = 0.3f32
          property phase_offset : Float32 = 0.0f32

          @time : Float32 = 0.0f32
          @base_position : RL::Vector2?

          def initialize(duration : Float32 = 0.0f32)
            super(duration)
          end

          def update(dt : Float32)
            super
            @time += dt
          end

          def reset
            super
            @time = 0.0f32
            @base_position = nil
          end

          def apply_to_camera(camera : Graphics::Core::Camera, dt : Float32)
            # Store base position
            @base_position ||= camera.position.dup

            # Calculate sway offset
            offset_x = Math.sin(@time * frequency_x * Math::PI * 2 + @phase_offset) * amplitude_x * @intensity
            offset_y = Math.sin(@time * frequency_y * Math::PI * 2) * amplitude_y * @intensity

            # Apply to camera
            camera.position.x = @base_position.not_nil!.x + offset_x
            camera.position.y = @base_position.not_nil!.y + offset_y
          end
        end

        # Factory for camera effects
        class CameraEffectFactory
          def self.create(effect_name : String, **params) : BaseCameraEffect?
            case effect_name.downcase
            when "shake", "camera_shake"
              # Reuse object shake effect
              amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 10.0f32
              frequency = params[:frequency]?.try(&.as(Number).to_f32) || 10.0f32
              duration = params[:duration]?.try(&.as(Number).to_f32) || 0.5f32

              shake = ObjectEffects::ShakeEffect.new(amplitude, frequency, duration)
              CameraEffectAdapter.new(shake)
            when "follow", "smooth_follow"
              target = parse_vector2(params[:target]?)
              follow = FollowEffect.new(target)

              follow.deadzone_width = params[:deadzone_width]?.try(&.as(Number).to_f32) || 100.0f32
              follow.deadzone_height = params[:deadzone_height]?.try(&.as(Number).to_f32) || 80.0f32
              follow.follow_speed = params[:follow_speed]?.try(&.as(Number).to_f32) || 5.0f32
              follow.look_ahead = params[:look_ahead]?.try(&.as(Number).to_f32) || 0.0f32

              if offset = parse_vector2(params[:offset]?)
                follow.offset = offset
              end

              follow
            when "pan", "pan_to"
              target = parse_vector2(params[:target]?) || RL::Vector2.new(x: 0, y: 0)
              duration = params[:duration]?.try(&.as(Number).to_f32) || 2.0f32

              pan = PanEffect.new(target, duration)
              pan.pan_speed = params[:speed]?.try(&.as(Number).to_f32) || 200.0f32
              pan.use_duration = params[:use_duration]? != false

              if easing_name = params[:easing]?.try(&.to_s)
                pan.easing = parse_easing(easing_name)
              end

              pan
            when "zoom"
              target_zoom = params[:target]?.try do |t|
                case t
                when Number then t.to_f32
                else 1.0f32
                end
              end || 1.0f32
              duration = params[:duration]?.try(&.as(Number).to_f32) || 1.0f32

              zoom = ZoomEffect.new(target_zoom, duration)
              zoom.zoom_speed = params[:speed]?.try(&.as(Number).to_f32) || 2.0f32

              if center = parse_vector2(params[:center]?)
                zoom.zoom_center = center
              end

              if easing_name = params[:easing]?.try(&.to_s)
                zoom.easing = parse_easing(easing_name)
              end

              zoom
            when "sway", "camera_sway"
              duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

              sway = SwayEffect.new(duration)
              sway.amplitude_x = params[:amplitude_x]?.try(&.as(Number).to_f32) || 10.0f32
              sway.amplitude_y = params[:amplitude_y]?.try(&.as(Number).to_f32) || 5.0f32
              sway.frequency_x = params[:frequency_x]?.try(&.as(Number).to_f32) || 0.5f32
              sway.frequency_y = params[:frequency_y]?.try(&.as(Number).to_f32) || 0.3f32
              sway.phase_offset = params[:phase]?.try(&.as(Number).to_f32) || 0.0f32

              sway
            when "float", "camera_float"
              # Reuse object float effect
              amplitude = params[:amplitude]?.try(&.as(Number).to_f32) || 10.0f32
              speed = params[:speed]?.try(&.as(Number).to_f32) || 1.0f32
              duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

              float = ObjectEffects::FloatEffect.new(amplitude, speed, duration)
              CameraEffectAdapter.new(float)
            when "pulse", "camera_pulse"
              # Reuse object pulse for zoom pulsing
              scale_amount = params[:zoom_amount]?.try(&.as(Number).to_f32) || 0.1f32
              speed = params[:speed]?.try(&.as(Number).to_f32) || 2.0f32
              duration = params[:duration]?.try(&.as(Number).to_f32) || 0.0f32

              pulse = ObjectEffects::PulseEffect.new(scale_amount, speed, duration)
              CameraEffectAdapter.new(pulse)
            else
              nil
            end
          end

          private def self.parse_vector2(value) : RL::Vector2?
            case value
            when Array
              if value.size >= 2
                RL::Vector2.new(
                  x: value[0].as(Number).to_f32,
                  y: value[1].as(Number).to_f32
                )
              else
                nil
              end
            when Hash
              x = value["x"]?.try(&.as(Number).to_f32) || 0.0f32
              y = value["y"]?.try(&.as(Number).to_f32) || 0.0f32
              RL::Vector2.new(x: x, y: y)
            else
              nil
            end
          end

          private def self.parse_easing(name : String) : Proc(Float32, Float32)
            case name.downcase
            when "linear"            then ->(t : Float32) { t }
            when "ease_in"           then ->(t : Float32) { t * t }
            when "ease_out"          then ->(t : Float32) { t * (2 - t) }
            when "ease_in_out"       then ->(t : Float32) { t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t }
            when "ease_in_cubic"     then ->(t : Float32) { t * t * t }
            when "ease_out_cubic"    then ->(t : Float32) { 1 + (t - 1) ** 3 }
            when "ease_in_out_cubic" then ->(t : Float32) { t < 0.5 ? 4 * t * t * t : 1 + (t - 1) * (2 * (t - 2)) ** 2 }
            when "bounce" then ->(t : Float32) {
              if t < 0.363636
                7.5625f32 * t * t
              elsif t < 0.727272
                t2 = t - 0.545454f32
                7.5625f32 * t2 * t2 + 0.75f32
              elsif t < 0.909090
                t2 = t - 0.818181f32
                7.5625f32 * t2 * t2 + 0.9375f32
              else
                t2 = t - 0.954545f32
                7.5625f32 * t2 * t2 + 0.984375f32
              end
            }
            when "elastic" then ->(t : Float32) {
              t == 0 || t == 1 ? t : -2.0f32 ** (10 * (t - 1)) * Math.sin((t - 1.1f32) * 5 * Math::PI).to_f32
            }
            else ->(t : Float32) { t }
            end
          end
        end
      end
    end
  end
end
