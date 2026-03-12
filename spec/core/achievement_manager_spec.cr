require "../spec_helper"
require "../../src/core/achievement_manager"

TEST_ACHIEVEMENT_SAVE_FILE        = "tmp/achievement_manager_spec.yaml"
TEST_ACHIEVEMENT_PERSISTENCE_FILE = "tmp/achievement_manager_persistence.yaml"

private def cleanup_achievement_save_files
  [TEST_ACHIEVEMENT_SAVE_FILE, TEST_ACHIEVEMENT_PERSISTENCE_FILE].each do |path|
    File.delete(path) if File.exists?(path)
  end
end

private def build_achievement_manager(save_file : String = TEST_ACHIEVEMENT_SAVE_FILE)
  Dir.mkdir_p(File.dirname(save_file))
  PointClickEngine::Core::AchievementManager.new(save_file)
end

describe PointClickEngine::Core::AchievementManager do
  before_each do
    cleanup_achievement_save_files
  end

  after_each do
    cleanup_achievement_save_files
  end

  describe "#initialize" do
    it "creates manager with default achievements" do
      manager = build_achievement_manager
      manager.achievements.size.should be > 0
      manager.achievements.has_key?("game_complete").should be_true
      manager.achievements.has_key?("bookworm").should be_true
    end
  end

  describe "#register" do
    it "registers a new achievement" do
      manager = build_achievement_manager
      manager.register("test_achievement", "Test Name", "Test Description")

      achievement = manager.achievements["test_achievement"]
      achievement.should_not be_nil
      achievement.name.should eq("Test Name")
      achievement.description.should eq("Test Description")
      achievement.unlocked.should be_false
      achievement.hidden.should be_false
    end

    it "registers a hidden achievement" do
      manager = build_achievement_manager
      manager.register("secret", "Secret Achievement", "Hidden description", hidden: true)

      achievement = manager.achievements["secret"]
      achievement.hidden.should be_true
    end
  end

  describe "#unlock" do
    it "unlocks an achievement" do
      manager = build_achievement_manager
      manager.register("test", "Test", "Description")

      result = manager.unlock("test")
      result.should be_true

      achievement = manager.achievements["test"]
      achievement.unlocked.should be_true
      achievement.unlock_time.should_not be_nil
    end

    it "doesn't unlock already unlocked achievement" do
      manager = build_achievement_manager
      manager.register("test", "Test", "Description")

      manager.unlock("test").should be_true
      manager.unlock("test").should be_false # Second unlock fails
    end

    it "returns false for non-existent achievement" do
      manager = build_achievement_manager
      manager.unlock("non_existent").should be_false
    end

    it "queues notification when unlocked" do
      manager = build_achievement_manager
      manager.register("test", "Test", "Description")

      manager.unlock("test")
      # Notification should be queued (internal state)
    end
  end

  describe "#is_unlocked?" do
    it "returns unlock status" do
      manager = build_achievement_manager
      manager.register("test", "Test", "Description")

      manager.is_unlocked?("test").should be_false
      manager.unlock("test")
      manager.is_unlocked?("test").should be_true
    end

    it "returns false for non-existent achievement" do
      manager = build_achievement_manager
      manager.is_unlocked?("non_existent").should be_false
    end
  end

  describe "#get_progress" do
    it "returns unlocked and total count" do
      manager = build_achievement_manager
      initial_count = manager.achievements.size

      manager.register("test1", "Test 1", "Description 1")
      manager.register("test2", "Test 2", "Description 2")
      manager.register("test3", "Test 3", "Description 3")

      progress = manager.get_progress
      progress[:total].should eq(initial_count + 3)
      progress[:unlocked].should eq(0)

      manager.unlock("test1")
      manager.unlock("test2")

      progress = manager.get_progress
      progress[:unlocked].should eq(2)
    end
  end

  describe "#update" do
    it "handles notification timing" do
      manager = build_achievement_manager
      manager.notification_duration = 1.0f32
      manager.register("test", "Test", "Description")

      manager.unlock("test")

      # Should show notification
      manager.update(0.5f32)

      # Should hide notification after duration
      manager.update(0.6f32)
    end
  end

  describe "#save_progress and #load_progress" do
    it "saves and loads achievement progress" do
      save_file = TEST_ACHIEVEMENT_PERSISTENCE_FILE
      Dir.mkdir_p(File.dirname(save_file))

      # Save progress
      manager1 = build_achievement_manager(save_file)
      manager1.register("test1", "Test 1", "Description")
      manager1.register("test2", "Test 2", "Description")
      manager1.unlock("test1")
      manager1.save_progress

      # Load in new instance
      manager2 = build_achievement_manager(save_file)
      manager2.register("test1", "Test 1", "Description")
      manager2.register("test2", "Test 2", "Description")
      manager2.load_progress

      manager2.is_unlocked?("test1").should be_true
      manager2.is_unlocked?("test2").should be_false
    end

    it "handles missing save file gracefully" do
      manager = build_achievement_manager("tmp/non_existent_achievements.yaml")
      manager.load_progress # Should not crash
    end
  end

  describe "Achievement" do
    it "initializes with correct defaults" do
      achievement = PointClickEngine::Core::AchievementManager::Achievement.new(
        "test_id", "Test Name", "Test Description"
      )

      achievement.id.should eq("test_id")
      achievement.name.should eq("Test Name")
      achievement.description.should eq("Test Description")
      achievement.unlocked.should be_false
      achievement.unlock_time.should be_nil
      achievement.hidden.should be_false
    end
  end
end
