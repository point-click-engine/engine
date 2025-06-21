require "../spec_helper"

describe PointClickEngine::Localization::Translation do
  it "stores and retrieves simple translations" do
    translation = PointClickEngine::Localization::Translation.new("hello")
    translation.add_translation(PointClickEngine::Localization::Locale::En_US, "Hello")
    translation.add_translation(PointClickEngine::Localization::Locale::Fr_FR, "Bonjour")

    translation.get(PointClickEngine::Localization::Locale::En_US).should eq("Hello")
    translation.get(PointClickEngine::Localization::Locale::Fr_FR).should eq("Bonjour")
  end

  it "returns key when translation not found" do
    translation = PointClickEngine::Localization::Translation.new("missing.key")
    translation.get(PointClickEngine::Localization::Locale::En_US).should eq("missing.key")
  end

  it "handles interpolation" do
    translation = PointClickEngine::Localization::Translation.new("greeting")
    translation.add_translation(PointClickEngine::Localization::Locale::En_US, "Hello {{name}}!")

    params = {"name" => "World"}
    translation.get(PointClickEngine::Localization::Locale::En_US, nil, params).should eq("Hello World!")
  end

  it "handles pluralization" do
    translation = PointClickEngine::Localization::Translation.new("items")
    forms = {
      "one"   => "{{count}} item",
      "other" => "{{count}} items",
    }
    translation.add_plural_forms(PointClickEngine::Localization::Locale::En_US, forms)

    params1 = {"count" => "1"}
    translation.get(PointClickEngine::Localization::Locale::En_US, 1, params1).should eq("1 item")

    params5 = {"count" => "5"}
    translation.get(PointClickEngine::Localization::Locale::En_US, 5, params5).should eq("5 items")
  end
end
