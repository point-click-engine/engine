require "../spec_helper"

describe PointClickEngine::Localization::Locale do
  it "converts to string correctly" do
    PointClickEngine::Localization::Locale::En_US.to_s.should eq("en-us")
    PointClickEngine::Localization::Locale::Fr_FR.to_s.should eq("fr-fr")
  end

  it "parses from string" do
    PointClickEngine::Localization::Locale.from_string("en-us").should eq(PointClickEngine::Localization::Locale::En_US)
    PointClickEngine::Localization::Locale.from_string("EN-US").should eq(PointClickEngine::Localization::Locale::En_US)
    PointClickEngine::Localization::Locale.from_string("en_US").should eq(PointClickEngine::Localization::Locale::En_US)
    PointClickEngine::Localization::Locale.from_string("invalid").should be_nil
  end

  it "extracts language and country codes" do
    locale = PointClickEngine::Localization::Locale::En_US
    locale.language_code.should eq("en")
    locale.country_code.should eq("us")
  end

  it "provides display names" do
    PointClickEngine::Localization::Locale::En_US.display_name.should eq("English")
    PointClickEngine::Localization::Locale::Fr_FR.display_name.should eq("Français")
    PointClickEngine::Localization::Locale::Ja_JP.display_name.should eq("日本語")
  end
end
