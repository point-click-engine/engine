require "./spec_helper"

describe "PreflightCheck Feature Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "feature compatibility validation" do
    it "detects conflicting features" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "shaders"
        - "low_end_mode"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("conflicting") || w.includes?("conflict") }
      warning_found.should be_true
    end

    it "accepts compatible features" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "auto_save"
        - "achievements"
        - "analytics"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not have conflict warnings
      conflict_warnings = result.warnings.select { |w| w.includes?("conflict") }
      conflict_warnings.should be_empty
    end
  end

  describe "shader feature validation" do
    it "validates shader files when shaders enabled" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "shaders"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("shader") && w.includes?("not found") }
      warning_found.should be_true
    end

    it "validates existing shader files" do
      Dir.mkdir_p("shaders")
      File.write("shaders/default.vert", "// vertex shader")
      File.write("shaders/default.frag", "// fragment shader")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "shaders"
      shaders:
        default:
          vertex: "shaders/default.vert"
          fragment: "shaders/default.frag"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not have shader not found warnings
      shader_warnings = result.warnings.select { |w| w.includes?("shader") && w.includes?("not found") }
      shader_warnings.should be_empty
    end
  end

  describe "save system validation" do
    it "checks save directory permissions" do
      Dir.mkdir_p("test_game_dir/saves")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "auto_save"
      YAML
      )

      File.write("test_game_dir/test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/test_game.yaml")

      # Should check save directory exists and is writable
      save_info = result.info.select { |i| i.includes?("save") || i.includes?("Save") }
      save_info.should_not be_empty
    end

    it "warns about missing save directory" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "auto_save"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("save") && (w.includes?("directory") || w.includes?("folder")) }
      warning_found.should be_true
    end

    it "validates save slot configuration" do
      Dir.mkdir_p("saves")

      config_yaml = create_minimal_config(<<-YAML
      features:
        - "auto_save"
      save_system:
        max_slots: -1
        auto_save_interval: 0
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should error on invalid save configuration
      save_errors = result.errors.select { |e|
        e.includes?("save") && (e.includes?("negative") || e.includes?("invalid"))
      }
      save_errors.should_not be_empty
    end
  end

  describe "analytics feature validation" do
    it "validates analytics configuration" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "analytics"
      analytics:
        endpoint: ""
        api_key: ""
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about missing analytics configuration
      analytics_warnings = result.warnings.select { |w|
        w.includes?("analytics") && (w.includes?("endpoint") || w.includes?("api_key"))
      }
      analytics_warnings.should_not be_empty
    end

    it "accepts valid analytics configuration" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "analytics"
      analytics:
        endpoint: "https://analytics.example.com/api/v1"
        api_key: "test-api-key-12345"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should not have analytics configuration warnings
      analytics_warnings = result.warnings.select { |w|
        w.includes?("analytics") && (w.includes?("missing") || w.includes?("empty"))
      }
      analytics_warnings.should be_empty
    end
  end

  describe "achievement system validation" do
    it "validates achievement definitions" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "achievements"
      achievements:
        - id: "first_room"
          name: ""
          description: "Enter the first room"
          points: -10
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should error on invalid achievement configuration
      achievement_errors = result.errors.select { |e|
        e.includes?("achievement") && (e.includes?("name") || e.includes?("points"))
      }
      achievement_errors.should_not be_empty
    end

    it "detects duplicate achievement IDs" do
      config_yaml = create_minimal_config(<<-YAML
      features:
        - "achievements"
      achievements:
        - id: "duplicate_id"
          name: "First Achievement"
          description: "Description 1"
        - id: "duplicate_id"
          name: "Second Achievement"
          description: "Description 2"
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should error on duplicate IDs
      duplicate_errors = result.errors.select { |e|
        e.includes?("duplicate") && e.includes?("achievement")
      }
      duplicate_errors.should_not be_empty
    end
  end
end
