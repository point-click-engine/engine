require "./spec_helper"

describe "PreflightCheck Dialog System Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "dialog file validation" do
    it "checks for dialog files when system enabled" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w|
        w.includes?("Dialog system enabled") && w.includes?("no dialog files found")
      }
      warning_found.should be_true
    end

    it "validates dialog file syntax" do
      Dir.mkdir_p("dialogs")

      # Invalid YAML
      File.write("dialogs/invalid.yaml", "invalid: yaml: {content")

      # Valid dialog file
      File.write("dialogs/valid.yaml", <<-YAML
      dialog_id: "intro_conversation"
      nodes:
        - id: "start"
          text: "Hello there!"
          responses:
            - text: "Hi!"
              next: "greeting"
      YAML
      )

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
      dialogs:
        - "dialogs/*.yaml"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should error on invalid YAML
      syntax_errors = result.errors.select { |e|
        e.includes?("invalid.yaml") && (e.includes?("syntax") || e.includes?("parse"))
      }
      syntax_errors.should_not be_empty
    end
  end

  describe "dialog structure validation" do
    it "validates dialog node structure" do
      Dir.mkdir_p("dialogs")

      dialog_yaml = <<-YAML
      dialog_id: "test_dialog"
      nodes:
        - id: "start"
          # Missing text
          responses:
            - text: "Option 1"
              next: "missing_node"  # References non-existent node
        - id: "orphan"
          text: "This node is never reached"
      YAML

      File.write("dialogs/test.yaml", dialog_yaml)

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
      dialogs:
        - "dialogs/*.yaml"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should have errors for missing text and invalid references
      dialog_errors = result.errors.select { |e|
        e.includes?("dialog") && (e.includes?("missing") || e.includes?("text"))
      }
      dialog_errors.should_not be_empty

      # Should warn about unreachable nodes
      dialog_warnings = result.warnings.select { |w|
        w.includes?("unreachable") || (w.includes?("orphan") && w.includes?("node"))
      }
      dialog_warnings.should_not be_empty
    end

    it "validates dialog conditions" do
      Dir.mkdir_p("dialogs")

      dialog_yaml = <<-YAML
      dialog_id: "conditional_dialog"
      nodes:
        - id: "start"
          text: "Choose your path"
          responses:
            - text: "Secret option"
              next: "secret"
              condition: "has_key && level > 5"
            - text: "Invalid condition"
              next: "next"
              condition: "invalid syntax !@#"
      YAML

      File.write("dialogs/conditional.yaml", dialog_yaml)

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
      dialogs:
        - "dialogs/*.yaml"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should error on invalid condition syntax
      condition_errors = result.errors.select { |e|
        e.includes?("condition") && (e.includes?("invalid") || e.includes?("syntax"))
      }
      condition_errors.should_not be_empty
    end
  end

  describe "dialog localization" do
    it "checks for missing dialog translations" do
      Dir.mkdir_p("dialogs")
      Dir.mkdir_p("locales")

      dialog_yaml = <<-YAML
      dialog_id: "greeting"
      nodes:
        - id: "start"
          text_key: "dialog.greeting.start"
          responses:
            - text_key: "dialog.greeting.response1"
              next: "end"
      YAML

      File.write("dialogs/greeting.yaml", dialog_yaml)

      # English locale has translations
      File.write("locales/en.yaml", <<-YAML
      dialog:
        greeting:
          start: "Hello!"
          response1: "Hi there!"
      YAML
      )

      # French locale missing translations
      File.write("locales/fr.yaml", <<-YAML
      dialog:
        # Missing greeting translations
      YAML
      )

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
        - "localization"
      supported_locales:
        - "en"
        - "fr"
      dialogs:
        - "dialogs/*.yaml"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about missing translations
      translation_warnings = result.warnings.select { |w|
        w.includes?("translation") && w.includes?("dialog")
      }
      translation_warnings.should_not be_empty
    end
  end

  describe "dialog file organization" do
    it "warns about too many dialogs in one file" do
      Dir.mkdir_p("dialogs")

      # Create a file with many dialog trees
      large_dialog = "dialogs:\n"
      50.times do |i|
        large_dialog += <<-YAML
          - dialog_id: "conversation_#{i}"
            nodes:
              - id: "start"
                text: "Dialog #{i}"
        YAML
      end

      File.write("dialogs/huge_file.yaml", large_dialog)

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "dialog_system"
      dialogs:
        - "dialogs/*.yaml"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about file organization
      org_warnings = result.warnings.select { |w|
        w.includes?("dialog") && (w.includes?("large") || w.includes?("many"))
      }
      org_warnings.should_not be_empty
    end
  end
end
