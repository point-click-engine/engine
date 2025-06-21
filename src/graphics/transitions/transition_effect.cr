# Transition effect types and base classes

module PointClickEngine
  module Graphics
    module Transitions
      # Available transition effects
      enum TransitionEffect
        # Elegant transitions
        Fade       # Classic fade to black
        Dissolve   # Random pixel dissolve
        SlideLeft  # Slide out to the left
        SlideRight # Slide out to the right
        SlideUp    # Slide out upward
        SlideDown  # Slide out downward
        CrossFade  # Smooth cross-fade between scenes

        # Cheesy/retro transitions
        Iris         # Classic iris wipe (circle closing)
        Pixelate     # Pixelate and fade
        Swirl        # Swirl/spiral effect
        Checkerboard # Checkerboard wipe
        StarWipe     # Star-shaped wipe
        HeartWipe    # Heart-shaped wipe (very cheesy!)
        Curtain      # Theater curtain closing
        Ripple       # Water ripple effect

        # Movie-like transitions
        Warp       # Space warp distortion
        Wave       # Ocean wave effect
        FilmBurn   # Old film burn transition
        Static     # TV static noise
        MatrixRain # Digital rain effect
        ZoomBlur   # Zoom with motion blur
        ClockWipe  # Clock hand sweep
        BarnDoor   # Barn doors closing
        PageTurn   # Page turning effect
        Shatter    # Glass shatter effect
        Vortex     # Spiral vortex effect
        Fire       # Fire transition effect
        Glitch     # Digital glitch effect
      end

      # Base class for transition effects
      abstract class BaseTransitionEffect
        property shader : RL::Shader?
        property duration : Float32
        property progress : Float32 = 0.0f32

        def initialize(@duration : Float32)
        end

        # Load the shader for this effect
        abstract def load_shader : RL::Shader?

        # Update shader parameters for current progress
        abstract def update_shader_params(progress : Float32)

        # Get the fragment shader source code
        abstract def fragment_shader_source : String

        # Common vertex shader used by most effects
        def vertex_shader_source : String
          <<-SHADER
          #version 330 core
          layout (location = 0) in vec3 aPos;
          layout (location = 1) in vec2 aTexCoord;
          layout (location = 2) in vec3 aNormal;
          layout (location = 3) in vec4 aColor;

          out vec2 fragTexCoord;
          out vec4 fragColor;

          uniform mat4 mvp;

          void main()
          {
              fragTexCoord = aTexCoord;
              fragColor = aColor;
              gl_Position = mvp * vec4(aPos, 1.0);
          }
          SHADER
        end

        # Cleanup shader resources
        def cleanup
          if shader = @shader
            RL.unload_shader(shader)
            @shader = nil
          end
        end
      end

      # Direction for slide transitions
      enum SlideDirection
        Left
        Right
        Up
        Down
      end
    end
  end
end
