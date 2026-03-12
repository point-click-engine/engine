require "./spec_helper"

describe "PreflightCheck Localization Validation" do
  it "does not register a dedicated localization validator in the current orchestrator" do
    validators = PointClickEngine::Core::PreflightCheck.get_available_validators
    validators.any? { |name| name.includes?("Localization") }.should be_false
  end

  pending "adds dedicated locale file validation once the preflight orchestrator grows a localization validator" do
    raise "unreachable"
  end
end
