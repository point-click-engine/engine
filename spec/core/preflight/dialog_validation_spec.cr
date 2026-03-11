require "./spec_helper"

describe "PreflightCheck Dialog System Validation" do
  it "does not register a dedicated dialog validator in the current orchestrator" do
    validators = PointClickEngine::Core::PreflightCheck.get_available_validators
    validators.any? { |name| name.includes?("Dialog") }.should be_false
  end

  pending "adds dedicated dialog file validation once the preflight orchestrator grows a dialog validator" do
    raise "unreachable"
  end
end
