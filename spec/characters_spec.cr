require "./spec_helper"

# Create a concrete character for testing
class TestCharacter < PointClickEngine::Characters::Character
  def on_interact(interactor : PointClickEngine::Characters::Character)
    say("Test interaction") { }
  end

  def on_look
    say("Test look") { }
  end

  def on_talk
    say("Test talk") { }
  end
end

describe PointClickEngine::Characters do
  describe PointClickEngine::Characters::Character do
    it "initializes with name, position and size" do
      char = TestCharacter.new("Hero", vec2(100, 200), vec2(32, 48))
      char.name.should eq("Hero")
      char.position.x.should eq(100)
      char.position.y.should eq(200)
      char.size.x.should eq(32)
      char.size.y.should eq(48)
    end

    it "starts in idle state facing right" do
      char = TestCharacter.new("Hero", vec2(0, 0), vec2(32, 48))
      char.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
      char.direction.should eq(PointClickEngine::Characters::Direction::Right)
    end

    it "has configurable walking speed" do
      char = TestCharacter.new("Hero", vec2(0, 0), vec2(32, 48))
      char.walking_speed = 150.0_f32
      char.walking_speed.should eq(150.0_f32)
    end

    it "can add animations" do
      char = TestCharacter.new("Hero", vec2(0, 0), vec2(32, 48))
      char.add_animation("walk", 0, 4, 0.15_f32, true)

      char.animations.has_key?("walk").should be_true
      anim = char.animations["walk"]
      anim.start_frame.should eq(0)
      anim.frame_count.should eq(4)
      anim.frame_speed.should eq(0.15_f32)
      anim.loop.should be_true
    end

    it "can set walk targets" do
      char = TestCharacter.new("Hero", vec2(0, 0), vec2(32, 48))
      target = vec2(100, 50)

      char.walk_to(target)

      char.target_position.should eq(target)
      char.state.should eq(PointClickEngine::Characters::CharacterState::Walking)
    end

    it "determines direction when walking" do
      char = TestCharacter.new("Hero", vec2(50, 50), vec2(32, 48))

      # Walk left
      char.walk_to(vec2(30, 50))
      char.direction.should eq(PointClickEngine::Characters::Direction::Left)

      # Walk right
      char.walk_to(vec2(70, 50))
      char.direction.should eq(PointClickEngine::Characters::Direction::Right)
    end

    it "can stop walking" do
      char = TestCharacter.new("Hero", vec2(0, 0), vec2(32, 48))
      char.walk_to(vec2(100, 100))

      char.stop_walking

      char.target_position.should be_nil
      char.state.should eq(PointClickEngine::Characters::CharacterState::Idle)
    end
  end

  describe PointClickEngine::Characters::Player do
    it "initializes with movement and inventory access enabled" do
      player = PointClickEngine::Characters::Player.new("Hero", vec2(0, 0), vec2(32, 48))
      player.movement_enabled.should be_true
      player.inventory_access.should be_true
    end

    it "has default animations setup" do
      player = PointClickEngine::Characters::Player.new("Hero", vec2(0, 0), vec2(32, 48))

      # Should have basic animations
      player.animations.has_key?("idle").should be_true
      player.animations.has_key?("idle_right").should be_true
      player.animations.has_key?("idle_left").should be_true
      player.animations.has_key?("walk_right").should be_true
      player.animations.has_key?("walk_left").should be_true
      player.animations.has_key?("talk").should be_true
    end

    it "starts with idle_right animation" do
      player = PointClickEngine::Characters::Player.new("Hero", vec2(0, 0), vec2(32, 48))
      player.current_animation.should eq("idle_right")
    end
  end

  describe PointClickEngine::Characters::NPC do
    it "initializes with empty dialogue" do
      npc = PointClickEngine::Characters::NPC.new("Guard", vec2(0, 0), vec2(32, 48))
      npc.dialogues.should be_empty
      npc.current_dialogue_index.should eq(0)
    end

    it "can add dialogue lines" do
      npc = PointClickEngine::Characters::NPC.new("Guard", vec2(0, 0), vec2(32, 48))

      npc.add_dialogue("Hello there!")
      npc.add_dialogue("How are you?")

      npc.dialogues.size.should eq(2)
      npc.dialogues[0].should eq("Hello there!")
      npc.dialogues[1].should eq("How are you?")
    end

    it "can set all dialogues at once" do
      npc = PointClickEngine::Characters::NPC.new("Guard", vec2(0, 0), vec2(32, 48))

      dialogues = ["Line 1", "Line 2", "Line 3"]
      npc.set_dialogues(dialogues)

      npc.dialogues.should eq(dialogues)
    end

    it "has configurable mood" do
      npc = PointClickEngine::Characters::NPC.new("Guard", vec2(0, 0), vec2(32, 48))

      npc.set_mood(PointClickEngine::Characters::NPCMood::Happy)
      npc.mood.should eq(PointClickEngine::Characters::NPCMood::Happy)
    end

    it "has configurable repeat behavior" do
      npc = PointClickEngine::Characters::NPC.new("Guard", vec2(0, 0), vec2(32, 48))

      npc.can_repeat_dialogues = false
      npc.can_repeat_dialogues.should be_false
    end

    it "has interaction distance" do
      npc = PointClickEngine::Characters::NPC.new("Guard", vec2(0, 0), vec2(32, 48))

      npc.interaction_distance = 75.0_f32
      npc.interaction_distance.should eq(75.0_f32)
    end
  end
end
