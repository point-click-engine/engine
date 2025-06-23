require "../spec_helper"
require "../../src/core/game_constants"

describe PointClickEngine::Core::GameConstants do
  describe "movement constants" do
    it "defines movement arrival threshold" do
      PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD.should be_a(Float32)
      PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD.should be > 0.0_f32
    end

    it "defines pathfinding waypoint threshold" do
      PointClickEngine::Core::GameConstants::PATHFINDING_WAYPOINT_THRESHOLD.should be_a(Float32)
      PointClickEngine::Core::GameConstants::PATHFINDING_WAYPOINT_THRESHOLD.should be > 0.0_f32
    end

    it "defines default walking speed" do
      PointClickEngine::Core::GameConstants::DEFAULT_WALKING_SPEED.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEFAULT_WALKING_SPEED.should be > 0.0_f32
    end

    it "defines scaled walking speed" do
      PointClickEngine::Core::GameConstants::SCALED_WALKING_SPEED.should be_a(Float32)
      PointClickEngine::Core::GameConstants::SCALED_WALKING_SPEED.should be > 0.0_f32
    end

    it "has scaled speed greater than default speed" do
      scaled = PointClickEngine::Core::GameConstants::SCALED_WALKING_SPEED
      default = PointClickEngine::Core::GameConstants::DEFAULT_WALKING_SPEED

      scaled.should be > default
    end
  end

  describe "animation constants" do
    it "defines default animation speed" do
      PointClickEngine::Core::GameConstants::DEFAULT_ANIMATION_SPEED.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEFAULT_ANIMATION_SPEED.should be > 0.0_f32
    end

    it "defines fast animation speed" do
      PointClickEngine::Core::GameConstants::FAST_ANIMATION_SPEED.should be_a(Float32)
      PointClickEngine::Core::GameConstants::FAST_ANIMATION_SPEED.should be > 0.0_f32
    end

    it "defines slow animation speed" do
      PointClickEngine::Core::GameConstants::SLOW_ANIMATION_SPEED.should be_a(Float32)
      PointClickEngine::Core::GameConstants::SLOW_ANIMATION_SPEED.should be > 0.0_f32
    end

    it "has proper animation speed ordering" do
      fast = PointClickEngine::Core::GameConstants::FAST_ANIMATION_SPEED
      default = PointClickEngine::Core::GameConstants::DEFAULT_ANIMATION_SPEED
      slow = PointClickEngine::Core::GameConstants::SLOW_ANIMATION_SPEED

      fast.should be < default
      default.should be < slow
    end
  end

  describe "input constants" do
    it "defines double click time" do
      PointClickEngine::Core::GameConstants::DOUBLE_CLICK_TIME.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DOUBLE_CLICK_TIME.should be > 0.0_f32
    end

    it "defines drag threshold" do
      PointClickEngine::Core::GameConstants::DRAG_THRESHOLD.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DRAG_THRESHOLD.should be > 0.0_f32
    end

    it "defines long press time" do
      PointClickEngine::Core::GameConstants::LONG_PRESS_TIME.should be_a(Float32)
      PointClickEngine::Core::GameConstants::LONG_PRESS_TIME.should be > 0.0_f32
    end
  end

  describe "ui constants" do
    it "defines floating text duration" do
      PointClickEngine::Core::GameConstants::FLOATING_TEXT_DURATION.should be_a(Float32)
      PointClickEngine::Core::GameConstants::FLOATING_TEXT_DURATION.should be > 0.0_f32
    end

    it "defines extended floating text duration" do
      PointClickEngine::Core::GameConstants::EXTENDED_FLOATING_TEXT_DURATION.should be_a(Float32)
      PointClickEngine::Core::GameConstants::EXTENDED_FLOATING_TEXT_DURATION.should be > 0.0_f32
    end

    it "defines tooltip delay" do
      PointClickEngine::Core::GameConstants::TOOLTIP_DELAY.should be_a(Float32)
      PointClickEngine::Core::GameConstants::TOOLTIP_DELAY.should be > 0.0_f32
    end

    it "defines dialog fade speed" do
      PointClickEngine::Core::GameConstants::DIALOG_FADE_SPEED.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DIALOG_FADE_SPEED.should be > 0.0_f32
    end
  end

  describe "scaling constants" do
    it "defines default character scale" do
      PointClickEngine::Core::GameConstants::DEFAULT_CHARACTER_SCALE.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEFAULT_CHARACTER_SCALE.should be > 0.0_f32
    end

    it "defines maximum character scale" do
      PointClickEngine::Core::GameConstants::MAX_CHARACTER_SCALE.should be_a(Float32)
      PointClickEngine::Core::GameConstants::MAX_CHARACTER_SCALE.should be > 0.0_f32
    end

    it "defines minimum character scale" do
      PointClickEngine::Core::GameConstants::MIN_CHARACTER_SCALE.should be_a(Float32)
      PointClickEngine::Core::GameConstants::MIN_CHARACTER_SCALE.should be > 0.0_f32
    end

    it "has proper scale ordering" do
      min_scale = PointClickEngine::Core::GameConstants::MIN_CHARACTER_SCALE
      default_scale = PointClickEngine::Core::GameConstants::DEFAULT_CHARACTER_SCALE
      max_scale = PointClickEngine::Core::GameConstants::MAX_CHARACTER_SCALE

      min_scale.should be < default_scale
      default_scale.should be < max_scale
    end
  end

  describe "rendering constants" do
    it "defines debug line thickness" do
      PointClickEngine::Core::GameConstants::DEBUG_LINE_THICKNESS.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEBUG_LINE_THICKNESS.should be > 0.0_f32
    end

    it "defines debug visualization constants" do
      PointClickEngine::Core::GameConstants::DEBUG_LINE_THICKNESS.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEBUG_LINE_THICKNESS.should be > 0.0_f32

      PointClickEngine::Core::GameConstants::DEBUG_CIRCLE_RADIUS.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEBUG_CIRCLE_RADIUS.should be > 0.0_f32

      PointClickEngine::Core::GameConstants::DEBUG_WAYPOINT_RADIUS.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEBUG_WAYPOINT_RADIUS.should be > 0.0_f32
    end
  end

  describe "audio constants" do
    it "defines default volume levels" do
      PointClickEngine::Core::GameConstants::DEFAULT_MASTER_VOLUME.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEFAULT_MUSIC_VOLUME.should be_a(Float32)
      PointClickEngine::Core::GameConstants::DEFAULT_SFX_VOLUME.should be_a(Float32)
    end

    it "has volume levels within valid range" do
      master = PointClickEngine::Core::GameConstants::DEFAULT_MASTER_VOLUME
      music = PointClickEngine::Core::GameConstants::DEFAULT_MUSIC_VOLUME
      sfx = PointClickEngine::Core::GameConstants::DEFAULT_SFX_VOLUME

      master.should be >= 0.0_f32
      master.should be <= 1.0_f32
      music.should be >= 0.0_f32
      music.should be <= 1.0_f32
      sfx.should be >= 0.0_f32
      sfx.should be <= 1.0_f32
    end

    it "defines audio fade speed" do
      PointClickEngine::Core::GameConstants::AUDIO_FADE_SPEED.should be_a(Float32)
      PointClickEngine::Core::GameConstants::AUDIO_FADE_SPEED.should be > 0.0_f32
    end
  end

  describe "performance constants" do
    it "defines performance cache limits" do
      PointClickEngine::Core::GameConstants::MAX_VECTOR_POOL_SIZE.should be_a(Int32)
      PointClickEngine::Core::GameConstants::MAX_VECTOR_POOL_SIZE.should be > 0

      PointClickEngine::Core::GameConstants::MAX_CACHED_ANIMATIONS.should be_a(Int32)
      PointClickEngine::Core::GameConstants::MAX_CACHED_ANIMATIONS.should be > 0
    end

    it "defines auto save interval" do
      PointClickEngine::Core::GameConstants::AUTO_SAVE_INTERVAL.should be_a(Float32)
      PointClickEngine::Core::GameConstants::AUTO_SAVE_INTERVAL.should be > 0.0_f32
    end
  end

  describe "constant consistency" do
    it "has reasonable default values" do
      # Movement speeds should be reasonable for gameplay
      PointClickEngine::Core::GameConstants::DEFAULT_WALKING_SPEED.should be >= 50.0_f32
      PointClickEngine::Core::GameConstants::DEFAULT_WALKING_SPEED.should be <= 500.0_f32

      # Animation speeds should be reasonable
      PointClickEngine::Core::GameConstants::DEFAULT_ANIMATION_SPEED.should be >= 0.05_f32
      PointClickEngine::Core::GameConstants::DEFAULT_ANIMATION_SPEED.should be <= 1.0_f32

      # Input timing should be reasonable
      PointClickEngine::Core::GameConstants::DOUBLE_CLICK_TIME.should be >= 0.1_f32
      PointClickEngine::Core::GameConstants::DOUBLE_CLICK_TIME.should be <= 1.0_f32

      PointClickEngine::Core::GameConstants::LONG_PRESS_TIME.should be >= 0.5_f32
      PointClickEngine::Core::GameConstants::LONG_PRESS_TIME.should be <= 2.0_f32
    end

    it "has no conflicting values" do
      # Arrival threshold should be smaller than waypoint threshold
      arrival = PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD
      waypoint = PointClickEngine::Core::GameConstants::PATHFINDING_WAYPOINT_THRESHOLD

      arrival.should be <= waypoint
    end

    it "has consistent float precision" do
      # All float constants should use _f32 suffix for consistency
      # This is more of a code style check but ensures consistency
      constants = [
        PointClickEngine::Core::GameConstants::MOVEMENT_ARRIVAL_THRESHOLD,
        PointClickEngine::Core::GameConstants::DEFAULT_WALKING_SPEED,
        PointClickEngine::Core::GameConstants::DEFAULT_ANIMATION_SPEED,
        PointClickEngine::Core::GameConstants::DOUBLE_CLICK_TIME,
      ]

      constants.each do |constant|
        constant.should be_a(Float32)
      end
    end
  end
end
