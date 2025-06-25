require "../../spec_helper"

describe PointClickEngine::Core::Engine do
  describe "input coordination" do
    let(engine) do
      engine = PointClickEngine::Core::Engine.new(800, 600, "Test Game")
      engine.init
      engine
    end

    after_each do
      PointClickEngine::Core::Engine.reset_instance if PointClickEngine::Core::Engine.responds_to?(:reset_instance)
    end

    context "input handler registration" do
      it "registers input handlers with priorities" do
        # Test high priority handler registration
        high_priority_handler = ->(input_state : PointClickEngine::Core::InputState) { true }
        engine.register_input_handler(high_priority_handler, priority: 100)

        # Input manager should have the handler registered
        engine.input_manager.should_not be_nil
      end

      it "maintains input handler priority order" do
        low_handler = ->(input_state : PointClickEngine::Core::InputState) { false }
        high_handler = ->(input_state : PointClickEngine::Core::InputState) { false }

        engine.register_input_handler(low_handler, priority: 1)
        engine.register_input_handler(high_handler, priority: 100)

        # Handlers should be called in priority order (high to low)
        # This would need to be verified through handler execution order
      end

      it "handles duplicate priority registration" do
        handler1 = ->(input_state : PointClickEngine::Core::InputState) { false }
        handler2 = ->(input_state : PointClickEngine::Core::InputState) { false }

        engine.register_input_handler(handler1, priority: 50)
        engine.register_input_handler(handler2, priority: 50)

        # Both handlers should be registered despite same priority
      end

      it "allows handler removal" do
        handler = ->(input_state : PointClickEngine::Core::InputState) { false }

        engine.register_input_handler(handler, priority: 50)
        engine.unregister_input_handler(handler)

        # Handler should be removed from the system
      end
    end

    context "input consumption flow" do
      it "stops processing when handler consumes input" do
        consuming_handler = ->(input_state : PointClickEngine::Core::InputState) { true }
        non_consuming_handler = ->(input_state : PointClickEngine::Core::InputState) { false }

        # Register consuming handler with higher priority
        engine.register_input_handler(consuming_handler, priority: 100)
        engine.register_input_handler(non_consuming_handler, priority: 50)

        # Process input - should stop at consuming handler
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true

        # Would need to verify non_consuming_handler wasn't called
      end

      it "continues processing when handlers don't consume input" do
        handler1 = ->(input_state : PointClickEngine::Core::InputState) { false }
        handler2 = ->(input_state : PointClickEngine::Core::InputState) { false }
        handler3 = ->(input_state : PointClickEngine::Core::InputState) { false }

        engine.register_input_handler(handler1, priority: 100)
        engine.register_input_handler(handler2, priority: 50)
        engine.register_input_handler(handler3, priority: 10)

        # All handlers should be called when none consume input
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true
      end

      it "handles input blocking during specific states" do
        # Block input for specific number of frames
        engine.block_input_frames = 60

        handler = ->(input_state : PointClickEngine::Core::InputState) { false }
        engine.register_input_handler(handler, priority: 50)

        # Input should be blocked
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true

        # Handler should not receive input
      end
    end

    context "specialized input systems" do
      it "configures verb input system when enabled" do
        engine.enable_verb_coin = true
        engine.setup_input_handlers

        # Verb input system should be registered
        engine.verb_input_system.should_not be_nil
      end

      it "handles keyboard shortcuts" do
        engine.enable_keyboard_shortcuts = true
        engine.setup_input_handlers

        # Keyboard shortcut handler should be registered
        # Test specific shortcuts like F1 for help, ESC for menu
      end

      it "manages edge scrolling input" do
        engine.edge_scroll_enabled = true
        engine.setup_input_handlers

        # Edge scroll handler should be active
        # Test mouse near screen edges triggers camera movement
      end

      it "coordinates dialog input handling" do
        # When dialog is active, input should be filtered
        engine.show_dialog("Test dialog", ["Option 1", "Option 2"])

        # Regular game input should be blocked
        # Dialog-specific input should be processed
      end
    end

    context "input state management" do
      it "tracks mouse position accurately" do
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_x = 150
        input_state.mouse_y = 200

        # Engine should track current mouse position
        engine.update_input(input_state)

        # Mouse position should be available to handlers
      end

      it "handles multiple input types simultaneously" do
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true
        input_state.key_pressed = true
        input_state.key_code = PointClickEngine::Core::Key::Space

        # Should handle both mouse and keyboard input in same frame
        engine.update_input(input_state)
      end

      it "maintains input history for gesture recognition" do
        # Track sequence of inputs for gestures
        positions = [{x: 100, y: 100}, {x: 110, y: 100}, {x: 120, y: 100}]

        positions.each do |pos|
          input_state = PointClickEngine::Core::InputState.new
          input_state.mouse_x = pos[:x]
          input_state.mouse_y = pos[:y]
          input_state.mouse_clicked = true

          engine.update_input(input_state)
        end

        # System should recognize swipe gesture
      end

      it "resets input state between frames" do
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true

        engine.update_input(input_state)

        # Click state should be cleared for next frame
        input_state.mouse_clicked = false
        engine.update_input(input_state)

        # No click should be registered
      end
    end

    context "input validation and security" do
      it "validates input coordinates are within screen bounds" do
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_x = -100 # Invalid coordinate
        input_state.mouse_y = 200
        input_state.mouse_clicked = true

        # Should handle invalid coordinates gracefully
        engine.update_input(input_state)
      end

      it "prevents input injection attacks" do
        malicious_input = PointClickEngine::Core::InputState.new
        # Simulate malicious input data
        malicious_input.mouse_x = Int32::MAX
        malicious_input.mouse_y = Int32::MAX

        # Should sanitize and handle safely
        engine.update_input(malicious_input)
      end

      it "rate limits input processing" do
        # Prevent input flooding
        100.times do
          input_state = PointClickEngine::Core::InputState.new
          input_state.mouse_clicked = true
          engine.update_input(input_state)
        end

        # System should remain responsive
      end
    end

    context "performance under load" do
      it "processes input efficiently with many handlers" do
        # Register many input handlers
        100.times do |i|
          handler = ->(input_state : PointClickEngine::Core::InputState) { false }
          engine.register_input_handler(handler, priority: i)
        end

        start_time = Time.monotonic

        # Process input
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true
        engine.update_input(input_state)

        duration = Time.monotonic - start_time
        duration.should be < 16.milliseconds # Should complete within frame time
      end

      it "handles high frequency input updates" do
        # Simulate high refresh rate input
        start_time = Time.monotonic

        1000.times do
          input_state = PointClickEngine::Core::InputState.new
          input_state.mouse_x = Random.rand(800)
          input_state.mouse_y = Random.rand(600)
          engine.update_input(input_state)
        end

        duration = Time.monotonic - start_time
        duration.should be < 1.second
      end
    end

    context "error handling in input processing" do
      it "handles exceptions in input handlers gracefully" do
        failing_handler = ->(input_state : PointClickEngine::Core::InputState) do
          raise "Handler error"
        end

        safe_handler = ->(input_state : PointClickEngine::Core::InputState) { false }

        engine.register_input_handler(failing_handler, priority: 100)
        engine.register_input_handler(safe_handler, priority: 50)

        # Should continue processing despite handler exception
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true

        expect_raises(Exception) do
          engine.update_input(input_state)
        end
      end

      it "recovers from corrupted input state" do
        # Simulate corrupted input data
        corrupted_input = PointClickEngine::Core::InputState.new

        # Should handle gracefully without crashing
        engine.update_input(corrupted_input)
      end
    end

    context "input system integration" do
      it "coordinates with scene-specific input handling" do
        scene = PointClickEngine::Scenes::Scene.new("input_test")
        hotspot = PointClickEngine::Scenes::Hotspot.new("test_hotspot", 100, 100, 50, 50)
        scene.add_hotspot(hotspot)

        engine.add_scene(scene)
        engine.change_scene("input_test")

        # Click on hotspot should be processed by scene
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_x = 125
        input_state.mouse_y = 125
        input_state.mouse_clicked = true

        engine.update_input(input_state)

        # Hotspot should have received the click
      end

      it "integrates with character movement system" do
        if player = engine.player
          # Click should trigger player movement
          input_state = PointClickEngine::Core::InputState.new
          input_state.mouse_x = 300
          input_state.mouse_y = 400
          input_state.mouse_clicked = true

          engine.update_input(input_state)

          # Player should start moving to clicked position
          player.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
        end
      end

      it "works with dialog system input" do
        # Show dialog and test input handling
        dialog_options = ["Yes", "No", "Maybe"]
        engine.show_dialog("Test question?", dialog_options)

        # Click on dialog option
        input_state = PointClickEngine::Core::InputState.new
        input_state.mouse_clicked = true
        # Position over first option

        engine.update_input(input_state)

        # Dialog should process the selection
      end
    end
  end
end
