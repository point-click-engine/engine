require "../spec_helper"

describe PointClickEngine::Localization::LocalizationManager do
  it "manages translations" do
    manager = PointClickEngine::Localization::LocalizationManager.new

    manager.add_translation("test.key", PointClickEngine::Localization::Locale::En_US, "Test Value")
    manager.translate("test.key").should eq("Test Value")
  end

  it "supports fallback locale" do
    manager = PointClickEngine::Localization::LocalizationManager.new(
      PointClickEngine::Localization::Locale::Fr_FR,
      PointClickEngine::Localization::Locale::En_US
    )

    manager.add_translation("only.english", PointClickEngine::Localization::Locale::En_US, "English Only")
    manager.translate("only.english").should eq("English Only")
  end

  it "returns key when translation not found" do
    manager = PointClickEngine::Localization::LocalizationManager.new
    manager.translate("missing.key").should eq("missing.key")
  end

  it "handles interpolation in convenience method" do
    manager = PointClickEngine::Localization::LocalizationManager.new
    manager.add_translation("hello", PointClickEngine::Localization::Locale::En_US, "Hello {{name}}")

    manager.t("hello", name: "Crystal").should eq("Hello Crystal")
  end

  it "lists available locales" do
    manager = PointClickEngine::Localization::LocalizationManager.new

    manager.add_translation("test", PointClickEngine::Localization::Locale::En_US, "Test")
    manager.add_translation("test", PointClickEngine::Localization::Locale::Fr_FR, "Test")
    manager.add_translation("test2", PointClickEngine::Localization::Locale::Es_ES, "Prueba")

    locales = manager.available_locales
    locales.includes?(PointClickEngine::Localization::Locale::En_US).should be_true
    locales.includes?(PointClickEngine::Localization::Locale::Fr_FR).should be_true
    locales.includes?(PointClickEngine::Localization::Locale::Es_ES).should be_true
  end

  it "changes current locale" do
    manager = PointClickEngine::Localization::LocalizationManager.new

    manager.add_translation("test", PointClickEngine::Localization::Locale::En_US, "English")
    manager.add_translation("test", PointClickEngine::Localization::Locale::Fr_FR, "French")

    manager.set_locale(PointClickEngine::Localization::Locale::Fr_FR)
    manager.current_locale.should eq(PointClickEngine::Localization::Locale::Fr_FR)
    manager.translate("test").should eq("French")
  end
end
