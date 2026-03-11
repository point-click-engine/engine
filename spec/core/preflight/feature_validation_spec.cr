require "./spec_helper"

describe "PreflightCheck Feature Validation" do
  before_each do
    cleanup_test_files
  end

  after_each do
    cleanup_test_files
  end

  it "detects configured feature conflicts" do
    config_yaml = create_minimal_config(<<-YAML
    features:
      - "shaders"
      - "low_end_mode"
    YAML
    )
    File.write("test_game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.warnings.any? { |warning| warning.includes?("Feature conflict detected") }.should be_true
  end

  it "reports built-in shader support when shaders are enabled without custom files" do
    config_yaml = create_minimal_config(<<-YAML
    features:
      - "shaders"
    YAML
    )
    File.write("test_game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.info.any? { |info| info.includes?("Shaders enabled (using built-in shaders)") }.should be_true
  end

  it "reports discovered custom shader files" do
    Dir.mkdir_p("test_game_dir/shaders")
    File.write("test_game_dir/shaders/default.vert", "// vertex shader")
    File.write("test_game_dir/shaders/default.frag", "// fragment shader")
    File.write("test_game_dir/test_game.yaml", create_minimal_config(<<-YAML
    features:
      - "shaders"
    YAML
    ))

    result = PointClickEngine::Core::PreflightCheck.run("test_game_dir/test_game.yaml")

    result.info.any? { |info| info.includes?("Found 2 custom shader file(s)") }.should be_true
  end

  it "surfaces security issues for risky feature flags" do
    config_yaml = create_minimal_config(<<-YAML
    features:
      - "networking"
      - "debug"
    YAML
    )
    File.write("test_game.yaml", config_yaml)

    result = PointClickEngine::Core::PreflightCheck.run("test_game.yaml")

    result.security_issues.any? { |issue| issue.includes?("Networking feature enabled") }.should be_true
    result.security_issues.any? { |issue| issue.includes?("Debug mode enabled") }.should be_true
  end

  pending "adds dedicated save, analytics, and achievement validation when those validators exist in preflight" do
    raise "unreachable"
  end
end
