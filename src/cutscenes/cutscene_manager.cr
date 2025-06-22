module PointClickEngine
  module Cutscenes
    # Manages cutscenes in the game
    class CutsceneManager
      property current_cutscene : Cutscene?
      property cutscenes : Hash(String, Cutscene)

      def initialize
        @cutscenes = {} of String => Cutscene
      end

      def add_cutscene(cutscene : Cutscene)
        @cutscenes[cutscene.name] = cutscene
      end

      def play_cutscene(name : String, on_complete : Proc(Nil)? = nil)
        if cutscene = @cutscenes[name]?
          @current_cutscene = cutscene
          cutscene.on_complete = on_complete
          cutscene.play
          true
        else
          false
        end
      end

      def stop_current
        @current_cutscene.try(&.stop)
        @current_cutscene = nil
      end

      def skip_current
        @current_cutscene.try(&.skip)
        @current_cutscene = nil
      end

      def is_playing? : Bool
        @current_cutscene.try(&.playing) || false
      end

      def update(dt : Float32)
        if cutscene = @current_cutscene
          cutscene.update(dt)

          # Clear current cutscene if completed
          if cutscene.completed
            @current_cutscene = nil
          end
        end
      end
      

      def draw
        @current_cutscene.try(&.draw)
      end

      # Create cutscene with DSL
      def create_cutscene(name : String, &block) : Cutscene
        cutscene = Cutscene.new(name)
        with cutscene yield
        add_cutscene(cutscene)
        cutscene
      end
    end
  end
end
