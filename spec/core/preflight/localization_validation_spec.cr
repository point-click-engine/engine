require "./spec_helper"

describe "PreflightCheck Localization Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "locale file validation" do
    it "checks for locale files when localization enabled" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w|
        w.includes?("Localization enabled") &&
          (w.includes?("no locale files found") || w.includes?("locales directory not found"))
      }
      warning_found.should be_true
    end

    it "validates locale directory structure" do
      Dir.mkdir_p("locales")
      File.write("locales/en.yaml", "welcome: Welcome")
      File.write("locales/fr.yaml", "welcome: Bienvenue")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      supported_locales:
        - "en"
        - "fr"
        - "de"  # Missing file
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about missing locale file
      locale_warnings = result.warnings.select { |w|
        w.includes?("de") && (w.includes?("locale") || w.includes?("missing"))
      }
      locale_warnings.should_not be_empty
    end
  end

  describe "default locale validation" do
    pending "validates default locale exists" do
      Dir.mkdir_p("locales")
      File.write("locales/en.yaml", "test: Test")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      default_locale: "fr"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e|
        e.includes?("Default locale") && e.includes?("not found")
      }
      error_found.should be_true
    end

    it "accepts valid default locale" do
      Dir.mkdir_p("locales")
      File.write("locales/en.yaml", "test: Test")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      default_locale: "en"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not error on valid default locale
      locale_errors = result.errors.select { |e|
        e.includes?("default locale") && e.includes?("not found")
      }
      locale_errors.should be_empty
    end
  end

  describe "locale file content validation" do
    it "validates locale file format" do
      Dir.mkdir_p("locales")
      File.write("locales/en.yaml", "invalid yaml content:")
      File.write("locales/fr.yaml", "valid:\n  content: Contenu")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should error on invalid YAML
      yaml_errors = result.errors.select { |e|
        e.includes?("en.yaml") && (e.includes?("invalid") || e.includes?("parse"))
      }
      yaml_errors.should_not be_empty
    end

    it "warns about missing translations" do
      Dir.mkdir_p("locales")
      File.write("locales/en.yaml", <<-YAML
      menu:
        start: "Start Game"
        options: "Options"
        quit: "Quit"
      YAML
      )
      File.write("locales/fr.yaml", <<-YAML
      menu:
        start: "Commencer"
        # Missing options and quit translations
      YAML
      )

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      supported_locales:
        - "en"
        - "fr"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about missing translations
      translation_warnings = result.warnings.select { |w|
        w.includes?("translation") && (w.includes?("missing") || w.includes?("incomplete"))
      }
      translation_warnings.should_not be_empty
    end
  end

  describe "locale configuration validation" do
    it "validates locale codes" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      supported_locales:
        - "en"
        - "fr"
        - "invalid_locale_code"
        - "x"  # Too short
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about invalid locale codes
      locale_warnings = result.warnings.select { |w|
        w.includes?("locale") && (w.includes?("invalid") || w.includes?("format"))
      }
      locale_warnings.should_not be_empty
    end

    it "accepts standard locale codes" do
      Dir.mkdir_p("locales")
      File.write("locales/en.yaml", "test: Test")
      File.write("locales/fr.yaml", "test: Test")
      File.write("locales/de.yaml", "test: Test")
      File.write("locales/es.yaml", "test: Test")
      File.write("locales/pt-BR.yaml", "test: Test")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "localization"
      supported_locales:
        - "en"
        - "fr"
        - "de"
        - "es"
        - "pt-BR"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not warn about standard locale codes
      locale_format_warnings = result.warnings.select { |w|
        w.includes?("locale") && w.includes?("format")
      }
      locale_format_warnings.should be_empty
    end
  end
end
