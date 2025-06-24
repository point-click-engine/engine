# Runtime validation for render system to detect architectural issues

module PointClickEngine
  module Core
    # Validates render system architecture at runtime
    module RenderValidation
      extend self

      # Check for common render system issues
      def validate_render_system(engine : Engine) : Array(String)
        issues = [] of String

        # Check if all major drawable systems are accessible
        issues.concat(validate_drawable_accessibility(engine))

        # Check coordinate system consistency
        issues.concat(validate_coordinate_consistency(engine))

        # Check input consumption logic
        issues.concat(validate_input_consumption(engine))

        issues
      end

      # Validate that drawable components are accessible via render pipeline
      private def validate_drawable_accessibility(engine : Engine) : Array(String)
        issues = [] of String

        # Check that dialog manager is accessible (this was the original bug)
        dialog_manager = engine.system_manager.dialog_manager
        if dialog_manager.nil?
          issues << "DialogManager not accessible from SystemManager"
        else
          if dialog_manager.floating_manager.nil?
            issues << "FloatingDialogManager not accessible from DialogManager"
          end
        end

        # Check that verb input system cursor is accessible
        if verb_system = engine.verb_input_system
          if verb_system.cursor_manager.nil?
            issues << "CursorManager not accessible from VerbInputSystem"
          end
        else
          issues << "VerbInputSystem not initialized"
        end

        # Check render manager has expected layers
        render_manager = engine.render_manager
        expected_layers = ["background", "scene_objects", "characters", "effects", "ui", "debug"]
        # Note: We can't easily check layer existence without exposing internal state,
        # but we can check that the render manager exists
        if render_manager.nil?
          issues << "RenderManager not accessible from Engine"
        end

        issues
      end

      # Validate coordinate system usage
      private def validate_coordinate_consistency(engine : Engine) : Array(String)
        issues = [] of String

        # Check display manager coordinate transformation
        if display_manager = engine.system_manager.display_manager
          # Test coordinate transformation consistency
          test_screen_point = RL::Vector2.new(x: 100f32, y: 100f32)
          game_point = display_manager.screen_to_game(test_screen_point)
          back_to_screen = display_manager.game_to_screen(game_point)

          # Should round-trip correctly
          x_diff = (back_to_screen.x - test_screen_point.x).abs
          y_diff = (back_to_screen.y - test_screen_point.y).abs

          if x_diff > 1.0f32 || y_diff > 1.0f32
            issues << "Display manager coordinate transformation not round-trip consistent"
          end
        else
          issues << "DisplayManager not accessible"
        end

        issues
      end

      # Validate input consumption logic
      private def validate_input_consumption(engine : Engine) : Array(String)
        issues = [] of String

        if dialog_manager = engine.system_manager.dialog_manager
          # Test that floating dialogs don't consume input
          original_state = dialog_manager.dialog_consumed_input?

          # Create a floating dialog
          dialog_manager.show_message("Validation test", 0.1f32)
          dialog_manager.update(0.001f32)

          # Should not consume input for floating dialogs
          if dialog_manager.dialog_consumed_input? && dialog_manager.current_dialog.nil?
            issues << "DialogManager consuming input for floating dialogs (should not)"
          end

          # Clean up - let the dialog expire quickly
        else
          issues << "Cannot validate input consumption - DialogManager not accessible"
        end

        issues
      end

      # Quick validation that can be run during development
      def quick_validate(engine : Engine) : Bool
        issues = validate_render_system(engine)

        if issues.empty?
          puts "✅ Render system validation passed"
          return true
        else
          puts "❌ Render system validation failed:"
          issues.each { |issue| puts "  - #{issue}" }
          return false
        end
      end
    end
  end
end
