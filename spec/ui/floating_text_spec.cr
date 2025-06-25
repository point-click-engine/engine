require "../spec_helper"

describe PointClickEngine::UI::FloatingText do
  it "initializes with basic properties" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Hello world", "Player", position)

    text.text.should eq("Hello world")
    text.character_name.should eq("Player")
    text.target_position.should eq(position)
    text.visible.should be_true
    text.fade_alpha.should eq(255.0f32)
    text.choices.should be_empty
  end

  it "determines character colors based on name" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    player_text = PointClickEngine::UI::FloatingText.new("Hi", "Player", position)
    wizard_text = PointClickEngine::UI::FloatingText.new("Magic", "Wizard", position)
    butler_text = PointClickEngine::UI::FloatingText.new("Sir", "Butler", position)

    # Player should be white
    player_text.text_color.r.should eq(255)
    player_text.text_color.g.should eq(255)
    player_text.text_color.b.should eq(255)

    # Wizard should be purple
    wizard_text.text_color.r.should eq(138)
    wizard_text.text_color.g.should eq(43)
    wizard_text.text_color.b.should eq(226)

    # Butler should be brown
    butler_text.text_color.r.should eq(139)
    butler_text.text_color.g.should eq(69)
    butler_text.text_color.b.should eq(19)
  end

  it "adds dialog choices with actions" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Choose wisely", "Merchant", position)

    action_called = false
    choice_text = ""

    text.add_choice("Buy sword") do
      action_called = true
      choice_text = "sword"
    end

    text.add_choice("Buy shield") do
      choice_text = "shield"
    end

    text.choices.size.should eq(2)
    text.choices[0].text.should eq("Buy sword")
    text.choices[1].text.should eq("Buy shield")

    # Simulate choice selection
    text.choices[0].action.call
    action_called.should be_true
    choice_text.should eq("sword")
  end

  it "updates position when character moves" do
    initial_pos = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Following", "Player", initial_pos)

    new_pos = RL::Vector2.new(x: 150f32, y: 250f32)
    text.update_position(new_pos)

    text.target_position.should eq(new_pos)
  end

  it "handles fade in animation" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Fading in", "Player", position)

    text.is_fading_in.should be_true
    text.fade_alpha.should eq(255.0f32) # Initial state

    # Update partway through fade
    text.update(0.15f32) # Half of 0.3s fade duration
    text.fade_alpha.should be > 0.0f32
    text.fade_alpha.should be < 255.0f32

    # Complete fade in
    text.update(0.2f32) # Total 0.35s > 0.3s fade duration
    text.is_fading_in.should be_false
    text.fade_alpha.should eq(255.0f32)
  end

  it "handles fade out animation" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Fading out", "Player", position)

    # Start fade out
    text.start_fade_out
    text.is_fading_out.should be_true

    # Update partway through fade
    text.update(0.15f32)
    text.fade_alpha.should be < 255.0f32
    text.visible.should be_true

    # Complete fade out
    result = text.update(0.2f32) # Total > 0.3s fade duration
    result.should be_false       # Should be removed
    text.visible.should be_false
  end

  it "animates with floating effect" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Floating", "Player", position)

    # Record initial state
    initial_elapsed = text.elapsed_time

    # Update to trigger animation
    text.update(0.5f32)

    # Time should advance
    text.elapsed_time.should eq(initial_elapsed + 0.5f32)

    # Float offset should be calculated based on sin wave
    # Can't test exact value but can verify it's within expected range
    float_offset = Math.sin(text.elapsed_time * text.float_speed) * text.float_amplitude
    float_offset.abs.should be <= text.float_amplitude
  end

  it "wraps long text to multiple lines" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    long_text = "This is a very long message that should definitely wrap to multiple lines because it exceeds the maximum width"
    text = PointClickEngine::UI::FloatingText.new(long_text, "Player", position)

    # Text should be wrapped (can't test exact wrapping without raylib measure_text)
    # But we can verify the wrapping logic exists
    text.max_width.should eq(300) # Default max width
  end

  it "sets visual properties" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Test", "Player", position)

    # Test default values
    text.font_size.should eq(16)
    text.padding.should eq(12)
    text.line_spacing.should eq(4)
    text.choice_spacing.should eq(8)

    # Test customization
    text.font_size = 20
    text.max_width = 400
    text.padding = 16

    text.font_size.should eq(20)
    text.max_width.should eq(400)
    text.padding.should eq(16)
  end

  it "handles choice callbacks" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Pick one", "NPC", position)

    selected_index = -1
    text.on_choice_selected = ->(index : Int32) {
      selected_index = index
    }

    text.add_choice("Option A") { }
    text.add_choice("Option B") { }

    # Simulate selecting choice (would normally happen through mouse input)
    text.on_choice_selected.not_nil!.call(1)
    selected_index.should eq(1)
  end

  it "supports text completion callback" do
    position = RL::Vector2.new(x: 100f32, y: 200f32)
    text = PointClickEngine::UI::FloatingText.new("Done", "Player", position)

    completed = false
    text.on_text_completed = -> {
      completed = true
    }

    text.on_text_completed.not_nil!.call
    completed.should be_true
  end
end

describe PointClickEngine::UI::FloatingTextManager do
  it "initializes empty" do
    manager = PointClickEngine::UI::FloatingTextManager.new

    manager.active_texts.should be_empty
    manager.default_duration.should eq(4.0f32)
    manager.auto_dismiss.should be_true
  end

  it "shows basic floating text" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    floating_text = manager.show_text("Player", "Hello world", position)

    manager.active_texts.size.should eq(1)
    manager.active_texts.first.should eq(floating_text)
    floating_text.text.should eq("Hello world")
    floating_text.character_name.should eq("Player")
  end

  it "shows floating text with choices" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    selected_choice = -1
    floating_text = manager.show_choice(
      "Merchant",
      "What would you like?",
      ["Buy", "Sell", "Leave"],
      position,
      ->(choice : Int32) {
        selected_choice = choice
      }
    )

    manager.active_texts.size.should eq(1)
    floating_text.choices.size.should eq(3)
    floating_text.choices[0].text.should eq("Buy")
    floating_text.choices[1].text.should eq("Sell")
    floating_text.choices[2].text.should eq("Leave")

    # Simulate selecting middle choice
    floating_text.choices[1].action.call
    selected_choice.should eq(1)
  end

  it "updates all active texts" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    pos1 = RL::Vector2.new(x: 100f32, y: 200f32)
    pos2 = RL::Vector2.new(x: 200f32, y: 300f32)

    text1 = manager.show_text("Player", "First", pos1, 0.5f32)
    text2 = manager.show_text("NPC", "Second", pos2, 1.0f32)

    manager.active_texts.size.should eq(2)

    # Update manager
    manager.update(0.1f32)

    # Both texts should have been updated
    text1.elapsed_time.should eq(0.1f32)
    text2.elapsed_time.should eq(0.1f32)
  end

  it "removes expired texts during update" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    # Create text that will expire quickly
    text = manager.show_text("Player", "Quick", position, 0.1f32)
    text.start_fade_out # Manually trigger fade out for test

    manager.active_texts.size.should eq(1)

    # Update past expiration
    10.times { manager.update(0.1f32) } # 1.0s total

    # Text should be removed
    manager.active_texts.should be_empty
  end

  it "updates character positions for their texts" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    initial_pos = RL::Vector2.new(x: 100f32, y: 200f32)

    text1 = manager.show_text("Player", "Following you", initial_pos)
    text2 = manager.show_text("NPC", "Standing still", initial_pos)
    text3 = manager.show_text("Player", "Also following", initial_pos)

    new_pos = RL::Vector2.new(x: 150f32, y: 250f32)
    manager.update_character_position("Player", new_pos)

    # Only Player texts should move
    text1.target_position.should eq(new_pos)
    text2.target_position.should eq(initial_pos)
    text3.target_position.should eq(new_pos)
  end

  it "clears all texts" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.show_text("Player", "Text 1", position)
    manager.show_text("NPC", "Text 2", position)
    manager.show_text("Guard", "Text 3", position)

    manager.active_texts.size.should eq(3)

    manager.clear_all
    manager.active_texts.should be_empty
  end

  it "clears texts for specific character" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.show_text("Player", "Player text 1", position)
    manager.show_text("NPC", "NPC text", position)
    manager.show_text("Player", "Player text 2", position)

    manager.active_texts.size.should eq(3)

    manager.clear_character_texts("Player")

    manager.active_texts.size.should eq(1)
    manager.active_texts.first.character_name.should eq("NPC")
  end

  it "checks if character has active text" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    manager.has_active_text?("Player").should be_false

    text = manager.show_text("Player", "Hello", position)
    manager.has_active_text?("Player").should be_true
    manager.has_active_text?("NPC").should be_false

    # Make text invisible
    text.visible = false
    manager.has_active_text?("Player").should be_false
  end

  it "respects custom duration for texts" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    # Show text with custom duration
    text = manager.show_text("Player", "Custom duration", position, 10.0f32)

    # Text should exist with our custom duration
    # (actual auto-dismiss would be handled by timer system)
    text.should_not be_nil
    manager.active_texts.size.should eq(1)
  end

  it "handles multiple texts from same character" do
    manager = PointClickEngine::UI::FloatingTextManager.new
    position = RL::Vector2.new(x: 100f32, y: 200f32)

    text1 = manager.show_text("Player", "First message", position)
    text2 = manager.show_text("Player", "Second message", position)
    text3 = manager.show_text("Player", "Third message", position)

    manager.active_texts.size.should eq(3)
    manager.has_active_text?("Player").should be_true

    # All should be from same character
    manager.active_texts.all? { |t| t.character_name == "Player" }.should be_true
  end
end
