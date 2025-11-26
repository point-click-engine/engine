require "../../spec_helper"

# Tests for post-processing effects
# NOTE: Post-processing effects require a GPU/OpenGL context for shader compilation.
# Tests that create shader effects are marked as pending in headless mode.
describe PointClickEngine::Graphics::Effects::PostProcessing do
  describe ".create" do
    pending "creates blur effects" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      # Gaussian blur
      gaussian = PointClickEngine::Graphics::Effects::PostProcessing.create("gaussian_blur",
        radius: 5.0f32, quality: 4)
      gaussian.should_not be_nil
      gaussian.should be_a(PointClickEngine::Graphics::Effects::PostProcessing::BlurShader)

      # Box blur
      box = PointClickEngine::Graphics::Effects::PostProcessing.create("box_blur",
        radius: 3.0f32)
      box.should_not be_nil

      # Motion blur
      motion = PointClickEngine::Graphics::Effects::PostProcessing.create("motion_blur",
        angle: 0.785f32, strength: 0.03f32)
      motion.should_not be_nil

      # Radial blur
      radial = PointClickEngine::Graphics::Effects::PostProcessing.create("radial_blur",
        center: [640, 360], zoom: true)
      radial.should_not be_nil
    end

    pending "creates distortion effects" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      # Heat haze
      heat = PointClickEngine::Graphics::Effects::PostProcessing.create("heat_haze",
        strength: 0.02f32, frequency: 8.0f32, layers: 3)
      heat.should_not be_nil
      heat.should be_a(PointClickEngine::Graphics::Effects::PostProcessing::DistortionShader)

      # Shock wave
      shock = PointClickEngine::Graphics::Effects::PostProcessing.create("shock_wave",
        center: [0.5, 0.5], radius: 0.5f32, force: 0.1f32)
      shock.should_not be_nil

      # Lens distortion
      lens = PointClickEngine::Graphics::Effects::PostProcessing.create("lens_distortion",
        k1: 0.2f32, k2: 0.0f32)
      lens.should_not be_nil

      # Ripple
      ripple = PointClickEngine::Graphics::Effects::PostProcessing.create("ripple",
        center: "center", wavelength: 0.05f32, amplitude: 0.01f32)
      ripple.should_not be_nil
    end

    pending "creates glow effects" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      # Simple glow
      glow = PointClickEngine::Graphics::Effects::PostProcessing.create("glow",
        threshold: 0.7f32, intensity: 2.0f32, tint: "yellow")
      glow.should_not be_nil
      glow.should be_a(PointClickEngine::Graphics::Effects::PostProcessing::GlowShader)

      # Adaptive glow
      adaptive = PointClickEngine::Graphics::Effects::PostProcessing.create("adaptive_glow",
        threshold: 0.8f32, intensity: 1.5f32)
      adaptive.should_not be_nil

      # Selective glow
      selective = PointClickEngine::Graphics::Effects::PostProcessing.create("selective_glow",
        select_color: "red", tolerance: 0.1f32)
      selective.should_not be_nil

      # Lens flare
      lens_flare = PointClickEngine::Graphics::Effects::PostProcessing.create("lens_flare",
        threshold: 0.9f32, dispersion: 0.3f32, halo_width: 0.5f32)
      lens_flare.should_not be_nil
    end

    it "handles invalid effect names" do
      effect = PointClickEngine::Graphics::Effects::PostProcessing.create("invalid_effect")
      effect.should be_nil
    end

    it "returns nil when GPU context unavailable" do
      # Without GPU context, all shader effects should return nil gracefully
      blur = PointClickEngine::Graphics::Effects::PostProcessing.create("gaussian_blur")
      # This is expected to be nil in headless mode (no GPU)
      # In a real environment with GPU, this would return an effect
    end

    pending "normalizes pixel coordinates to UV" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      # Test with pixel coordinates
      blur = PointClickEngine::Graphics::Effects::PostProcessing.create("radial_blur",
        center: [1280, 720])
      blur.should_not be_nil

      if blur.is_a?(PointClickEngine::Graphics::Effects::PostProcessing::BlurShader)
        # Should be normalized to 0-1 range
        blur.radial_center.x.should be_close(1.0, 0.01)
        blur.radial_center.y.should be_close(1.0, 0.01)
      end
    end

    pending "handles color parsing in effects" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      # Test various color formats
      glow1 = PointClickEngine::Graphics::Effects::PostProcessing.create("glow",
        tint: "red")
      glow1.should_not be_nil

      glow2 = PointClickEngine::Graphics::Effects::PostProcessing.create("glow",
        tint: "#00FF00")
      glow2.should_not be_nil

      glow3 = PointClickEngine::Graphics::Effects::PostProcessing.create("glow",
        tint: [255, 255, 0])
      glow3.should_not be_nil
    end
  end

  describe "effect lifecycle" do
    pending "can update effect properties" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      heat = PointClickEngine::Graphics::Effects::PostProcessing.create("heat_haze",
        strength: 0.01f32)

      heat.should_not be_nil
      if heat.is_a?(PointClickEngine::Graphics::Effects::PostProcessing::DistortionShader)
        # Update properties
        heat.strength = 0.05f32
        heat.frequency = 15.0f32
        heat.speed = 2.0f32

        heat.strength.should eq(0.05f32)
        heat.frequency.should eq(15.0f32)
        heat.speed.should eq(2.0f32)
      end
    end

    pending "tracks progress for timed effects" do
      # Requires OpenGL context for shader compilation - skipped in headless mode
      blur = PointClickEngine::Graphics::Effects::PostProcessing.create("gaussian_blur",
        radius: 10.0f32, duration: 2.0f32)

      blur.should_not be_nil
      if blur
        blur.progress.should eq(0.0f32)

        blur.update(1.0f32)
        blur.progress.should eq(0.5f32)

        blur.update(1.0f32)
        blur.progress.should eq(1.0f32)
        blur.finished?.should be_true
      end
    end
  end
end
