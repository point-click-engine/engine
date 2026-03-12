require "../../spec_helper"

module PointClickEngine::Core::Conditions
  describe ConditionParser do
    describe ".parse" do
      describe "empty conditions" do
        it "returns TrueCondition for empty string" do
          result = ConditionParser.parse("")
          result.success?.should be_true
          result.value.to_s.should eq("true")
        end

        it "returns TrueCondition for whitespace" do
          result = ConditionParser.parse("   ")
          result.success?.should be_true
        end
      end

      describe "flag conditions" do
        it "parses simple flag" do
          result = ConditionParser.parse("has_key")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_flag("has_key", true)
            result.value.evaluate(gsm).success.should be_true
          end
        end

        it "parses negated flag" do
          result = ConditionParser.parse("!locked")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            # locked flag not set (false by default)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_flag("locked", true)
            result.value.evaluate(gsm).success.should be_false
          end
        end
      end

      describe "variable comparisons" do
        it "parses equals comparison" do
          result = ConditionParser.parse("gold == 100")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_variable("gold", 100)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_variable("gold", 50)
            result.value.evaluate(gsm).success.should be_false
          end
        end

        it "parses greater than comparison" do
          result = ConditionParser.parse("level > 5")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_variable("level", 10)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_variable("level", 3)
            result.value.evaluate(gsm).success.should be_false
          end
        end

        it "parses greater or equal comparison" do
          result = ConditionParser.parse("score >= 1000")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_variable("score", 1000)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_variable("score", 1001)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_variable("score", 999)
            result.value.evaluate(gsm).success.should be_false
          end
        end

        it "parses less than comparison" do
          result = ConditionParser.parse("hp < 20")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_variable("hp", 10)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_variable("hp", 30)
            result.value.evaluate(gsm).success.should be_false
          end
        end

        it "parses not equal comparison" do
          result = ConditionParser.parse("status != 0")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_variable("status", 1)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_variable("status", 0)
            result.value.evaluate(gsm).success.should be_false
          end
        end
      end

      describe "quest conditions" do
        it "parses quest:id:active" do
          result = ConditionParser.parse("quest:main:active")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            result.value.evaluate(gsm).success.should be_false

            gsm.start_quest("main")
            result.value.evaluate(gsm).success.should be_true
          end
        end

        it "parses quest:id:completed" do
          result = ConditionParser.parse("quest:main:completed")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.start_quest("main")
            result.value.evaluate(gsm).success.should be_false

            gsm.complete_quest("main")
            result.value.evaluate(gsm).success.should be_true
          end
        end

        it "parses quest:id (defaults to active)" do
          result = ConditionParser.parse("quest:side")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.start_quest("side")
            result.value.evaluate(gsm).success.should be_true
          end
        end
      end

      describe "time conditions" do
        it "parses time:day" do
          result = ConditionParser.parse("time:day")
          result.success?.should be_true
        end

        it "parses time:night" do
          result = ConditionParser.parse("time:night")
          result.success?.should be_true
        end

        it "parses time:morning" do
          result = ConditionParser.parse("time:morning")
          result.success?.should be_true
        end
      end

      describe "achievement conditions" do
        it "parses achievement:id" do
          result = ConditionParser.parse("achievement:master")
          result.success?.should be_true
        end
      end

      describe "boolean operators" do
        it "parses AND conditions" do
          result = ConditionParser.parse("flag1 && flag2")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_flag("flag1", true)
            gsm.set_flag("flag2", true)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_flag("flag2", false)
            result.value.evaluate(gsm).success.should be_false
          end
        end

        it "parses OR conditions" do
          result = ConditionParser.parse("has_key || has_lockpick")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_flag("has_key", true)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_flag("has_key", false)
            gsm.set_flag("has_lockpick", true)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_flag("has_lockpick", false)
            result.value.evaluate(gsm).success.should be_false
          end
        end

        it "parses multiple AND conditions" do
          result = ConditionParser.parse("flag1 && flag2 && flag3")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_flag("flag1", true)
            gsm.set_flag("flag2", true)
            gsm.set_flag("flag3", true)
            result.value.evaluate(gsm).success.should be_true

            gsm.set_flag("flag2", false)
            result.value.evaluate(gsm).success.should be_false
          end
        end

        it "parses multiple OR conditions" do
          result = ConditionParser.parse("flag1 || flag2 || flag3")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_flag("flag2", true)
            result.value.evaluate(gsm).success.should be_true
          end
        end
      end

      describe "parentheses" do
        it "parses parenthesized expressions" do
          result = ConditionParser.parse("(flag1)")
          result.success?.should be_true

          with_test_window do
            gsm = GameStateManager.new
            gsm.set_flag("flag1", true)
            result.value.evaluate(gsm).success.should be_true
          end
        end

        it "parses nested parentheses" do
          result = ConditionParser.parse("((flag1))")
          result.success?.should be_true
        end
      end
    end

    describe ".parse!" do
      it "returns condition on success" do
        condition = ConditionParser.parse!("has_key")
        condition.should_not be_nil
      end

      it "raises on parse error" do
        # This should work since unknown time periods raise
        expect_raises(Exception) do
          ConditionParser.parse!("time:invalid_period")
        end
      end
    end
  end

  describe ConditionValidator do
    describe "#validate" do
      it "validates valid conditions" do
        validator = ConditionValidator.new
        result = validator.validate("has_key && gold >= 100")
        result.valid?.should be_true
      end

      it "detects empty conditions" do
        validator = ConditionValidator.new
        result = validator.validate("")
        result.valid?.should be_false
        result.errors.size.should eq(1)
        result.errors[0].type.should eq(ConditionValidationResult::ErrorType::SyntaxError)
      end

      it "detects unbalanced parentheses" do
        validator = ConditionValidator.new
        result = validator.validate("(flag1 && flag2")
        result.valid?.should be_false
        result.errors.any? { |e| e.type == ConditionValidationResult::ErrorType::UnbalancedParens }.should be_true
      end

      it "warns about unknown flags when registry populated" do
        validator = ConditionValidator.new
        validator.register_flag("known_flag")

        result = validator.validate("unknown_flag")
        result.warnings.any? { |w| w.type == ConditionValidationResult::ErrorType::UnknownFlag }.should be_true
      end

      it "suggests similar flags" do
        validator = ConditionValidator.new
        validator.register_flag("has_key")

        result = validator.validate("has_kye")
        result.warnings.size.should be >= 1
        result.warnings[0].suggestion.should eq("has_key")
      end

      it "warns about unknown variables" do
        validator = ConditionValidator.new
        validator.register_variable("gold")
        validator.register_variable("coins")
        validator.register_variable("score")

        result = validator.validate("goldd >= 100")
        result.warnings.any? { |w| w.type == ConditionValidationResult::ErrorType::UnknownVariable }.should be_true
        # Should have a warning for unknown variable
        warning = result.warnings.find { |w| w.type == ConditionValidationResult::ErrorType::UnknownVariable }
        warning.should_not be_nil
        # The suggestion might be nil if Levenshtein distance > 3
      end

      it "warns about unknown quests" do
        validator = ConditionValidator.new
        validator.register_quest("main_quest")

        result = validator.validate("quest:main_qest:active")
        result.warnings.any? { |w| w.type == ConditionValidationResult::ErrorType::UnknownQuest }.should be_true
        result.warnings[0].suggestion.should eq("main_quest")
      end

      it "detects invalid time periods" do
        validator = ConditionValidator.new
        result = validator.validate("time:invalid")
        result.errors.any? { |e| e.type == ConditionValidationResult::ErrorType::SyntaxError }.should be_true
      end
    end

    describe "#validate_batch" do
      it "validates multiple conditions" do
        validator = ConditionValidator.new
        validator.register_flag("flag1")

        conditions = [
          {condition: "flag1", file: "test.yaml", line: 1},
          {condition: "flag2", file: "test.yaml", line: 2},
        ]

        results = validator.validate_batch(conditions)
        results.size.should eq(2)
      end
    end

    describe "Levenshtein distance" do
      it "finds close matches" do
        validator = ConditionValidator.new
        validator.register_flag("has_key")
        validator.register_flag("has_sword")
        validator.register_flag("completed")

        result = validator.validate("hass_key")
        result.warnings[0].suggestion.should eq("has_key")
      end

      it "doesn't suggest distant matches" do
        validator = ConditionValidator.new
        validator.register_flag("abc")

        result = validator.validate("xyz123")
        # Should not have a suggestion for such a different string
        result.warnings.each do |w|
          if w.type == ConditionValidationResult::ErrorType::UnknownFlag
            w.suggestion.should be_nil
          end
        end
      end
    end
  end

  describe ConditionValidationResult do
    describe "#format_errors" do
      it "returns 'Valid' for valid results" do
        result = ConditionValidationResult.new("flag1")
        result.format_errors.should eq("Valid")
      end

      it "formats errors with details" do
        result = ConditionValidationResult.new("has_kye", "scene.yaml", 10)
        result.add_error(
          ConditionValidationResult::ErrorType::UnknownFlag,
          "Unknown flag 'has_kye'",
          4,
          "has_key"
        )

        output = result.format_errors
        output.should contain("Condition validation failed")
        output.should contain("has_kye")
        output.should contain("scene.yaml")
        output.should contain("10")
        output.should contain("has_key")
      end
    end
  end
end
