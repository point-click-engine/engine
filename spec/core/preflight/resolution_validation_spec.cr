require "./spec_helper"

describe "PreflightCheck Resolution and Display Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  describe "resolution validation" do
    it "detects non-standard resolutions" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 1023
        height: 767
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Non-standard resolution") }
      warning_found.should be_true
    end

    it "warns about very large resolutions" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 3840
        height: 2160
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("larger than 1920x1080") }
      warning_found.should be_true
    end

    it "errors on too small resolutions" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 320
        height: 240
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      error_found = result.errors.any? { |e| e.includes?("too small") }
      error_found.should be_true
    end
  end

  describe "aspect ratio validation" do
    it "detects unusual aspect ratios" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 1000
        height: 1000
      YAML
      )

      File.write("test_game.yaml", config_yaml)

      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      warning_found = result.warnings.any? { |w| w.includes?("Unusual aspect ratio") }
      warning_found.should be_true
    end

    it "accepts standard aspect ratios" do
      standard_ratios = [
        {width: 1920, height: 1080}, # 16:9
        {width: 1280, height: 720},  # 16:9
        {width: 1024, height: 768},  # 4:3
        {width: 1440, height: 900},  # 16:10
      ]

      standard_ratios.each do |ratio|
        config_yaml = create_minimal_config(<<-YAML
        window:
          width: #{ratio[:width]}
          height: #{ratio[:height]}
        YAML
        )

        File.write("test_game.yaml", config_yaml)
        result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

        # Should not have aspect ratio warnings
        aspect_warnings = result.warnings.select { |w| w.includes?("aspect ratio") }
        aspect_warnings.should be_empty
      end
    end
  end

  describe "display mode validation" do
    it "validates fullscreen settings" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 1920
        height: 1080
        fullscreen: true
      YAML
      )

      File.write("test_game.yaml", config_yaml)
      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should accept valid fullscreen configuration
      result.info.any? { |i| i.includes?("Display mode") || i.includes?("fullscreen") }.should be_true
    end

    it "validates vsync settings" do
      config_yaml = create_minimal_config(<<-YAML
      window:
        width: 1920
        height: 1080
        vsync: true
      YAML
      )

      File.write("test_game.yaml", config_yaml)
      result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

      # Should accept valid vsync configuration
      result.passed.should be_true
    end
  end
end
