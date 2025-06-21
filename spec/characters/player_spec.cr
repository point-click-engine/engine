require "../spec_helper"

module PointClickEngine
  describe Characters::Player do
    describe "#initialize" do
      it "creates a player with default values" do
        player = Characters::Player.new
        player.name.should eq("Player")
        player.position.x.should eq(0f32)
        player.position.y.should eq(0f32)
        player.size.x.should eq(32f32)
        player.size.y.should eq(64f32)
      end

      it "creates a player with custom values" do
        player = Characters::Player.new(
          "Hero",
          Raylib::Vector2.new(x: 100f32, y: 200f32),
          Raylib::Vector2.new(x: 64f32, y: 128f32)
        )

        player.name.should eq("Hero")
        player.position.x.should eq(100f32)
        player.position.y.should eq(200f32)
        player.size.x.should eq(64f32)
        player.size.y.should eq(128f32)
      end
    end

    describe "#handle_click" do
      it "handles click to move" do
        player = Characters::Player.new
        scene = PointClickEngine::Scenes::Scene.new("test")
        target = Raylib::Vector2.new(x: 300f32, y: 400f32)

        player.handle_click(target, scene)

        # Player should start moving
        player.state.should eq(Characters::CharacterState::Walking)
      end
    end

    describe "#state" do
      it "can be idle or walking" do
        player = Characters::Player.new

        # Should start idle
        player.state.should eq(Characters::CharacterState::Idle)

        # Can be set to walking
        player.state = Characters::CharacterState::Walking
        player.state.should eq(Characters::CharacterState::Walking)
      end
    end
  end
end
