require "../../spec_helper"
require "../../../src/core/conditions/conditions"

module PointClickEngine::Core::Conditions
  describe ConditionResult do
    it "stores success status and message" do
      result = ConditionResult.new(true, "Test passed")
      result.success.should be_true
      result.message.should eq("Test passed")
    end

    it "provides to_s with checkmark for success" do
      success = ConditionResult.new(true, "Passed")
      failure = ConditionResult.new(false, "Failed")

      success.to_s.should eq("✓ Passed")
      failure.to_s.should eq("✗ Failed")
    end
  end

  describe TrueCondition do
    it "always evaluates to true" do
      condition = TrueCondition.new

      # Create a mock state manager
      with_test_window do
        gsm = GameStateManager.new

        result = condition.evaluate(gsm)
        result.success.should be_true
      end
    end

    it "has to_s representation" do
      TrueCondition.new.to_s.should eq("true")
    end
  end

  describe FalseCondition do
    it "always evaluates to false" do
      condition = FalseCondition.new

      with_test_window do
        gsm = GameStateManager.new

        result = condition.evaluate(gsm)
        result.success.should be_false
      end
    end

    it "has to_s representation" do
      FalseCondition.new.to_s.should eq("false")
    end
  end

  describe FlagCondition do
    describe "with expected=true" do
      it "returns true when flag is set" do
        condition = FlagCondition.new("test_flag", true)

        with_test_window do
          gsm = GameStateManager.new
          gsm.set_flag("test_flag", true)

          result = condition.evaluate(gsm)
          result.success.should be_true
        end
      end

      it "returns false when flag is not set" do
        condition = FlagCondition.new("test_flag", true)

        with_test_window do
          gsm = GameStateManager.new

          result = condition.evaluate(gsm)
          result.success.should be_false
        end
      end
    end

    describe "with expected=false" do
      it "returns true when flag is not set" do
        condition = FlagCondition.new("test_flag", false)

        with_test_window do
          gsm = GameStateManager.new

          result = condition.evaluate(gsm)
          result.success.should be_true
        end
      end

      it "returns false when flag is set" do
        condition = FlagCondition.new("test_flag", false)

        with_test_window do
          gsm = GameStateManager.new
          gsm.set_flag("test_flag", true)

          result = condition.evaluate(gsm)
          result.success.should be_false
        end
      end
    end

    it "has to_s representation" do
      FlagCondition.new("my_flag", true).to_s.should eq("my_flag")
      FlagCondition.new("my_flag", false).to_s.should eq("!my_flag")
    end
  end

  describe VariableCondition do
    it "compares integers with equals" do
      condition = VariableCondition.new("gold", VariableCondition::Operator::Equal, 100)

      with_test_window do
        gsm = GameStateManager.new
        gsm.set_variable("gold", 100)

        result = condition.evaluate(gsm)
        result.success.should be_true
      end
    end

    it "compares integers with greater_than" do
      condition = VariableCondition.new("level", VariableCondition::Operator::GreaterThan, 5)

      with_test_window do
        gsm = GameStateManager.new
        gsm.set_variable("level", 10)

        result = condition.evaluate(gsm)
        result.success.should be_true

        gsm.set_variable("level", 3)
        result = condition.evaluate(gsm)
        result.success.should be_false
      end
    end

    it "compares integers with less_or_equal" do
      condition = VariableCondition.new("hp", VariableCondition::Operator::LessOrEqual, 50)

      with_test_window do
        gsm = GameStateManager.new

        gsm.set_variable("hp", 50)
        result = condition.evaluate(gsm)
        result.success.should be_true

        gsm.set_variable("hp", 30)
        result = condition.evaluate(gsm)
        result.success.should be_true

        gsm.set_variable("hp", 100)
        result = condition.evaluate(gsm)
        result.success.should be_false
      end
    end

    it "returns false for non-existent variable" do
      condition = VariableCondition.new("missing", VariableCondition::Operator::Equal, 0)

      with_test_window do
        gsm = GameStateManager.new

        result = condition.evaluate(gsm)
        result.success.should be_false
        result.message.should contain("not found")
      end
    end

    it "has to_s representation" do
      VariableCondition.new("gold", VariableCondition::Operator::GreaterOrEqual, 100).to_s.should eq("gold >= 100")
    end
  end

  describe QuestCondition do
    describe "active status" do
      it "returns true for active quests" do
        condition = QuestCondition.new("main_quest", QuestCondition::Status::Active)

        with_test_window do
          gsm = GameStateManager.new
          gsm.start_quest("main_quest")

          result = condition.evaluate(gsm)
          result.success.should be_true
        end
      end

      it "returns false for inactive quests" do
        condition = QuestCondition.new("main_quest", QuestCondition::Status::Active)

        with_test_window do
          gsm = GameStateManager.new

          result = condition.evaluate(gsm)
          result.success.should be_false
        end
      end
    end

    describe "completed status" do
      it "returns true for completed quests" do
        condition = QuestCondition.new("main_quest", QuestCondition::Status::Completed)

        with_test_window do
          gsm = GameStateManager.new
          gsm.start_quest("main_quest")
          gsm.complete_quest("main_quest")

          result = condition.evaluate(gsm)
          result.success.should be_true
        end
      end
    end

    it "has to_s representation" do
      QuestCondition.new("main", QuestCondition::Status::Active).to_s.should eq("quest:main:active")
      QuestCondition.new("main", QuestCondition::Status::Completed).to_s.should eq("quest:main:completed")
      QuestCondition.new("main", QuestCondition::Status::AtStep, "step1").to_s.should eq("quest:main:step1")
    end
  end

  describe AndCondition do
    it "returns true when all conditions are true" do
      and_cond = AndCondition.new
      and_cond.add(FlagCondition.new("flag1", true))
      and_cond.add(FlagCondition.new("flag2", true))

      with_test_window do
        gsm = GameStateManager.new
        gsm.set_flag("flag1", true)
        gsm.set_flag("flag2", true)

        result = and_cond.evaluate(gsm)
        result.success.should be_true
      end
    end

    it "returns false when any condition is false" do
      and_cond = AndCondition.new
      and_cond.add(FlagCondition.new("flag1", true))
      and_cond.add(FlagCondition.new("flag2", true))

      with_test_window do
        gsm = GameStateManager.new
        gsm.set_flag("flag1", true)
        # flag2 is not set

        result = and_cond.evaluate(gsm)
        result.success.should be_false
      end
    end

    it "returns true for empty AND" do
      and_cond = AndCondition.new

      with_test_window do
        gsm = GameStateManager.new

        result = and_cond.evaluate(gsm)
        result.success.should be_true
      end
    end

    it "has to_s representation" do
      and_cond = AndCondition.new
      and_cond.add(FlagCondition.new("a", true))
      and_cond.add(FlagCondition.new("b", true))

      and_cond.to_s.should eq("a && b")
    end
  end

  describe OrCondition do
    it "returns true when any condition is true" do
      or_cond = OrCondition.new
      or_cond.add(FlagCondition.new("flag1", true))
      or_cond.add(FlagCondition.new("flag2", true))

      with_test_window do
        gsm = GameStateManager.new
        gsm.set_flag("flag1", true)
        # flag2 is not set

        result = or_cond.evaluate(gsm)
        result.success.should be_true
      end
    end

    it "returns false when all conditions are false" do
      or_cond = OrCondition.new
      or_cond.add(FlagCondition.new("flag1", true))
      or_cond.add(FlagCondition.new("flag2", true))

      with_test_window do
        gsm = GameStateManager.new
        # No flags set

        result = or_cond.evaluate(gsm)
        result.success.should be_false
      end
    end

    it "returns false for empty OR" do
      or_cond = OrCondition.new

      with_test_window do
        gsm = GameStateManager.new

        result = or_cond.evaluate(gsm)
        result.success.should be_false
      end
    end
  end

  describe NotCondition do
    it "inverts true to false" do
      not_cond = NotCondition.new(FlagCondition.new("flag", true))

      with_test_window do
        gsm = GameStateManager.new
        gsm.set_flag("flag", true)

        result = not_cond.evaluate(gsm)
        result.success.should be_false
      end
    end

    it "inverts false to true" do
      not_cond = NotCondition.new(FlagCondition.new("flag", true))

      with_test_window do
        gsm = GameStateManager.new
        # flag is not set

        result = not_cond.evaluate(gsm)
        result.success.should be_true
      end
    end

    it "has to_s representation" do
      not_cond = NotCondition.new(FlagCondition.new("flag", true))
      not_cond.to_s.should eq("!(flag)")
    end
  end

  describe ConditionBuilder do
    describe "#flag" do
      it "builds simple flag conditions" do
        with_test_window do
          gsm = GameStateManager.new
          gsm.set_flag("has_key", true)

          condition = ConditionBuilder.new.flag("has_key").build
          condition.evaluate(gsm).success.should be_true
        end
      end
    end

    describe "#var" do
      it "builds variable conditions with operators" do
        with_test_window do
          gsm = GameStateManager.new
          gsm.set_variable("gold", 150)

          condition = ConditionBuilder.new.var("gold").greater_or_equal(100).build
          condition.evaluate(gsm).success.should be_true

          condition = ConditionBuilder.new.var("gold").less_than(100).build
          condition.evaluate(gsm).success.should be_false
        end
      end
    end

    describe "#quest" do
      it "builds quest conditions" do
        with_test_window do
          gsm = GameStateManager.new
          gsm.start_quest("main")

          condition = ConditionBuilder.new.quest("main").is_active.build
          condition.evaluate(gsm).success.should be_true

          condition = ConditionBuilder.new.quest("main").is_completed.build
          condition.evaluate(gsm).success.should be_false
        end
      end
    end

    describe "#and chaining" do
      it "combines conditions with AND" do
        with_test_window do
          gsm = GameStateManager.new
          gsm.set_flag("flag1", true)
          gsm.set_flag("flag2", true)
          gsm.set_variable("gold", 100)

          condition = ConditionBuilder.new
            .flag("flag1")
            .and
            .flag("flag2")
            .and
            .var("gold").greater_or_equal(50)
            .build

          condition.evaluate(gsm).success.should be_true

          # Remove one condition
          gsm.set_flag("flag2", false)
          condition.evaluate(gsm).success.should be_false
        end
      end
    end

    describe "#or chaining" do
      it "combines conditions with OR" do
        with_test_window do
          gsm = GameStateManager.new
          gsm.set_flag("vip_pass", false)
          gsm.set_variable("gold", 200)

          condition = ConditionBuilder.new
            .flag("vip_pass")
            .or
            .var("gold").greater_or_equal(100)
            .build

          # Should pass because gold >= 100
          condition.evaluate(gsm).success.should be_true
        end
      end
    end

    describe "#check" do
      it "provides shortcut for evaluation result" do
        with_test_window do
          gsm = GameStateManager.new
          gsm.set_flag("flag", true)

          ConditionBuilder.new.flag("flag").check(gsm).should be_true
          ConditionBuilder.new.flag("other").check(gsm).should be_false
        end
      end
    end

    describe ".build block syntax" do
      it "supports block-style building" do
        with_test_window do
          gsm = GameStateManager.new
          gsm.set_flag("has_key", true)
          gsm.set_variable("level", 5)

          condition = ConditionBuilder.build do |c|
            c.flag("has_key").and.var("level").greater_or_equal(3)
          end

          condition.evaluate(gsm).success.should be_true
        end
      end
    end
  end

  describe ConditionWrapper do
    it "wraps conditions for polymorphic storage" do
      flag = FlagCondition.new("test", true)
      wrapper = ConditionWrapper.new(flag)

      with_test_window do
        gsm = GameStateManager.new
        gsm.set_flag("test", true)

        wrapper.evaluate(gsm).success.should be_true
        wrapper.to_s.should eq("test")
      end
    end

    it "allows unwrapping" do
      flag = FlagCondition.new("test", true)
      wrapper = ConditionWrapper.new(flag)

      unwrapped = wrapper.unwrap
      unwrapped.should be_a(FlagCondition)
    end
  end
end
