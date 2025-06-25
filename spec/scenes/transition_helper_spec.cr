require "../spec_helper"
require "../../src/scenes/transition_helper"

describe PointClickEngine::Scenes::TransitionHelper do
  describe ".parse_transition_command" do
    it "parses a full transition command with all parameters" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:swirl:4.5:300,400")

      result.should_not be_nil
      result.not_nil![:scene].should eq("garden")
      result.not_nil![:effect].should eq(PointClickEngine::Graphics::TransitionEffect::Swirl)
      result.not_nil![:duration].should eq(4.5)
      result.not_nil![:position].should eq(RL::Vector2.new(x: 300, y: 400))
    end

    it "returns nil for non-transition commands" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("play_sound:door_creak")
      result.should be_nil
    end

    it "parses command with only scene name" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:library")

      result.should_not be_nil
      result.not_nil![:scene].should eq("library")
      result.not_nil![:effect].should eq(PointClickEngine::Graphics::TransitionEffect::Fade) # default
      result.not_nil![:duration].should eq(-1.0)                                             # signal to use scene default
      result.not_nil![:position].should be_nil
    end

    it "parses command with scene and effect" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:lab:curtain")

      result.should_not be_nil
      result.not_nil![:scene].should eq("lab")
      result.not_nil![:effect].should eq(PointClickEngine::Graphics::TransitionEffect::Curtain)
      result.not_nil![:duration].should eq(-1.0) # signal to use scene default
    end

    it "returns -1.0 duration when duration is empty" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:fade::100,200")

      result.should_not be_nil
      result.not_nil![:duration].should eq(-1.0)
      result.not_nil![:position].should eq(RL::Vector2.new(x: 100, y: 200))
    end

    it "returns -1.0 duration when duration is 'default'" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:fade:default:100,200")

      result.should_not be_nil
      result.not_nil![:duration].should eq(-1.0)
    end

    it "handles invalid duration gracefully" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:fade:invalid:100,200")

      result.should_not be_nil
      result.not_nil![:duration].should eq(-1.0) # falls back to scene default signal
    end

    it "parses position correctly" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:fade:2.0:150,250")

      result.should_not be_nil
      result.not_nil![:position].should eq(RL::Vector2.new(x: 150, y: 250))
    end

    it "handles missing position" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:fade:2.0")

      result.should_not be_nil
      result.not_nil![:position].should be_nil
    end

    it "handles invalid position format" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:fade:2.0:invalid")

      result.should_not be_nil
      result.not_nil![:position].should be_nil
    end

    it "handles unknown effect names" do
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:unknown_effect:2.0")

      result.should_not be_nil
      result.not_nil![:effect].should be_nil
    end

    it "handles all known transition effects" do
      effects = {
        "fade"        => PointClickEngine::Graphics::TransitionEffect::Fade,
        "dissolve"    => PointClickEngine::Graphics::TransitionEffect::Dissolve,
        "slide_left"  => PointClickEngine::Graphics::TransitionEffect::SlideLeft,
        "slide_right" => PointClickEngine::Graphics::TransitionEffect::SlideRight,
        "swirl"       => PointClickEngine::Graphics::TransitionEffect::Swirl,
        "curtain"     => PointClickEngine::Graphics::TransitionEffect::Curtain,
        "heart_wipe"  => PointClickEngine::Graphics::TransitionEffect::HeartWipe,
        "star_wipe"   => PointClickEngine::Graphics::TransitionEffect::StarWipe,
      }

      effects.each do |name, expected_effect|
        result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:test:#{name}")
        result.should_not be_nil
        result.not_nil![:effect].should eq(expected_effect)
      end
    end
  end

  describe ".execute_transition" do
    # Note: These tests verify the parsing logic. The actual execution
    # requires a full Engine instance and would be tested in integration tests.

    it "correctly parses commands with default duration" do
      # The TransitionHelper should properly parse commands that use default duration
      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:swirl::100,200")
      result.should_not be_nil
      result.not_nil![:duration].should eq(-1.0) # Signal for default

      result = PointClickEngine::Scenes::TransitionHelper.parse_transition_command("transition:garden:swirl:default")
      result.should_not be_nil
      result.not_nil![:duration].should eq(-1.0) # Signal for default
    end

    it "returns false for invalid commands" do
      # Create a real engine for this test
      RL.init_window(100, 100, "Test")
      begin
        engine = PointClickEngine::Core::Engine.new(100, 100, "Test")
        engine.init

        success = PointClickEngine::Scenes::TransitionHelper.execute_transition("not_a_transition", engine)
        success.should be_false
      ensure
        RL.close_window
      end
    end
  end
end
