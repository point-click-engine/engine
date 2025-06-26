require "./spec_helper"

describe "PreflightCheck Development Environment" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "environment information" do
    it "reports Crystal version" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      version_info = result.info.find { |i| i.includes?("Crystal version") }
      version_info.should_not be_nil
    end

    it "reports operating system" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      os_info = result.info.find { |i|
        i.includes?("OS") || i.includes?("Operating System") || i.includes?("Platform")
      }
      os_info.should_not be_nil
    end
  end

  describe "development tool checks" do
    it "checks for development tools" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should check for git at minimum
      tool_check = result.info.any? { |i| i.includes?("git") && i.includes?("available") }
      tool_check.should be_true
    end

    it "checks for optional tools" do
      config_yaml = create_minimal_config(<<-YAML
      development:
        tools:
          - "git"
          - "make"
          - "docker"
      YAML
      )
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should check for specified tools
      tool_info = result.info.select { |i|
        i.includes?("tool") || i.includes?("available") || i.includes?("installed")
      }
      tool_info.should_not be_empty
    end
  end

  describe "dependency checks" do
    it "checks for required libraries" do
      config_yaml = create_minimal_config(<<-YAML
      dependencies:
        - "raylib"
        - "chipmunk"
      YAML
      )
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should check for dependencies
      dep_info = result.info.select { |i|
        i.includes?("dependency") || i.includes?("library") || i.includes?("raylib")
      }
      dep_info.should_not be_empty
    end

    it "warns about missing dependencies" do
      config_yaml = create_minimal_config(<<-YAML
      dependencies:
        - "non_existent_library"
      YAML
      )
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about missing dependencies
      dep_warnings = result.warnings.select { |w|
        w.includes?("non_existent_library") || w.includes?("missing")
      }
      dep_warnings.should_not be_empty
    end
  end

  describe "build configuration" do
    it "validates build settings" do
      config_yaml = create_minimal_config(<<-YAML
      build:
        release_mode: true
        optimizations: "O3"
        static_linking: false
      YAML
      )
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should validate build configuration
      build_info = result.info.select { |i|
        i.includes?("build") || i.includes?("optimization") || i.includes?("release")
      }
      build_info.should_not be_empty
    end

    it "warns about debug builds in production" do
      config_yaml = create_minimal_config(<<-YAML
      build:
        release_mode: false
        debug_symbols: true
      production: true
      YAML
      )
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about debug build in production
      build_warnings = result.warnings.select { |w|
        w.includes?("debug") && w.includes?("production")
      }
      build_warnings.should_not be_empty
    end
  end

  describe "project structure validation" do
    it "checks required directories" do
      config_yaml = create_minimal_config
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should check for required directories
      dir_info = result.info.select { |i|
        i.includes?("directory") || i.includes?("folder") || i.includes?("structure")
      }
      dir_info.should_not be_empty
    end

    it "warns about missing directories" do
      config_yaml = create_minimal_config(<<-YAML
      assets:
        sprites:
          - "sprites/*.png"
        sounds:
          - "audio/sounds/*.wav"
      YAML
      )
      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should warn about missing asset directories
      dir_warnings = result.warnings.select { |w|
        w.includes?("directory") && (w.includes?("missing") || w.includes?("not found"))
      }
      dir_warnings.should_not be_empty
    end
  end
end
