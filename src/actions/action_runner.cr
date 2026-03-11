# ActionRunner - Executes sequences of actions
# Manages action lifecycle and parallel execution

require "./action"
require "./action_loader"

module PointClickEngine
  module Actions
    # Forward declaration - ActionExecutor will be in separate file
    class ActionExecutor; end

    # Runs a sequence of actions
    class ActionRunner
      property actions : Array(ActionInstance)
      property current_index : Int32 = 0
      property running : Bool = false
      property completed : Bool = false
      property skippable : Bool = true
      property auto_advance : Bool = true
      property name : String

      # Variables from YAML (for reference/debugging)
      property variables : Hash(String, YAML::Any) = {} of String => YAML::Any

      # Checkpoints for skip/resume functionality
      property checkpoints : Array(ActionCheckpoint) = [] of ActionCheckpoint

      # Conditions for conditional execution
      property conditions : Array(ActionCondition) = [] of ActionCondition

      # Callbacks
      property on_complete : Proc(Nil)?
      property on_action_start : Proc(ActionInstance, Nil)?
      property on_action_complete : Proc(ActionInstance, Nil)?

      # Parallel action runners (run concurrently with main sequence)
      @parallel_runners : Array(ActionRunner) = [] of ActionRunner
      @active_parallel_indices : Set(Int32) = Set(Int32).new

      # Executor reference (set externally or created lazily)
      property executor : ActionExecutor?

      # Engine reference
      @engine : Core::Engine?

      def initialize(@name : String, @engine : Core::Engine? = nil)
        @actions = [] of ActionInstance
      end

      # Set engine reference
      def engine=(engine : Core::Engine)
        @engine = engine
      end

      # Get engine (lazy access to singleton if not set)
      def engine : Core::Engine
        @engine || Core::Engine.instance
      end

      # Add action from ActionData
      def add(data : ActionData)
        @actions << ActionInstance.new(data)
      end

      # Add action instance directly
      def add(action : ActionInstance)
        @actions << action
      end

      # Add action with callback (for code-defined actions)
      def add_callback(callback : Proc(Nil))
        data = ActionData.new("callback")
        @actions << ActionInstance.new(data, callback)
      end

      # Add parallel action group - all actions run simultaneously
      def add_parallel(actions : Array(ActionData))
        runner = ActionRunner.new("#{@name}_parallel_#{@parallel_runners.size}", @engine)
        runner.executor = @executor
        actions.each { |data| runner.add(data) }

        # Add marker action to main sequence
        marker_data = ActionData.new("_parallel_marker")
        marker_instance = ActionInstance.new(marker_data)
        marker_instance.set_custom("parallel_index", @parallel_runners.size)
        @actions << marker_instance
        @parallel_runners << runner
      end

      # Start playing the action sequence
      def play
        return if @actions.empty?

        @running = true
        @completed = false
        @current_index = 0
        @active_parallel_indices.clear

        # Reset all actions
        @actions.each(&.reset)
        @parallel_runners.each do |runner|
          runner.reset
          runner.executor = @executor
        end

        # Disable player control
        engine.player_control_enabled = false

        # Apply any startup skip/branch conditions before the first update tick.
        evaluate_start_conditions

        # Publish start event
        publish_start_event
      end

      # Stop the action sequence
      def stop
        @running = false
        engine.player_control_enabled = true
        @on_complete.try(&.call)
        publish_end_event(skipped: false)
      end

      # Skip to end of sequence
      def skip
        return unless @skippable
        return unless @running

        scene = current_scene
        return unless scene

        exec = get_executor

        # Fast-forward all remaining actions
        while @current_index < @actions.size
          action = @actions[@current_index]
          unless action.finished?
            exec.start(action, scene) unless action.started
            exec.finish(action, scene)
          end
          @current_index += 1
        end

        # Skip parallel runners too
        @parallel_runners.each do |runner|
          runner.skip if runner.running
        end

        @running = false
        @completed = true
        engine.player_control_enabled = true
        @on_complete.try(&.call)
        publish_end_event(skipped: true)
      end

      # Reset for replay
      def reset
        @running = false
        @completed = false
        @current_index = 0
        @active_parallel_indices.clear
        @actions.each(&.reset)
        @parallel_runners.each(&.reset)
      end

      # Update the action sequence (call every frame)
      def update(dt : Float32)
        return unless @running
        return if @completed

        scene = current_scene
        return unless scene

        exec = get_executor

        # Update any active parallel runners
        @parallel_runners.each_with_index do |runner, idx|
          if @active_parallel_indices.includes?(idx)
            runner.update(dt)
            # Check if parallel runner completed
            if runner.completed
              @active_parallel_indices.delete(idx)
            end
          end
        end

        # Process current action
        process_current_action(exec, scene, dt)
      end

      # Draw action overlays (for text, custom visuals)
      def draw
        return unless @running

        exec = get_executor

        # Draw current action overlay
        if @current_index < @actions.size
          exec.draw(@actions[@current_index])
        end

        # Draw parallel runner overlays
        @parallel_runners.each_with_index do |runner, idx|
          if @active_parallel_indices.includes?(idx)
            runner.draw
          end
        end
      end

      # Check if any parallel runners are still active
      def has_active_parallels? : Bool
        !@active_parallel_indices.empty?
      end

      # Get total action count
      def action_count : Int32
        @actions.size
      end

      # Get current progress (0.0 to 1.0)
      def progress : Float32
        return 1.0f32 if @actions.empty?
        @current_index.to_f32 / @actions.size.to_f32
      end

      private def process_current_action(exec : ActionExecutor, scene : Scenes::Scene, dt : Float32)
        return if @current_index >= @actions.size

        action = @actions[@current_index]

        # Handle parallel marker
        if action.data.type == "_parallel_marker"
          handle_parallel_marker(action)
          return
        end

        # Start action if not started
        unless action.started
          exec.start(action, scene)
          @on_action_start.try(&.call(action))
        end

        # Update action
        if exec.update(action, scene, dt)
          # Action completed
          exec.finish(action, scene)
          @on_action_complete.try(&.call(action))
          advance_to_next_action
        end
      end

      private def handle_parallel_marker(action : ActionInstance)
        if idx = action.get_custom("parallel_index").try(&.as_i?)
          parallel_runner = @parallel_runners[idx]?
          return advance_to_next_action unless parallel_runner

          unless @active_parallel_indices.includes?(idx) || parallel_runner.completed
            # Start the parallel runner
            parallel_runner.play
            @active_parallel_indices << idx
          end

          # Wait for parallel runner to complete before advancing
          if parallel_runner.completed
            action.complete!
            advance_to_next_action
          end
        else
          advance_to_next_action
        end
      end

      private def advance_to_next_action
        @current_index += 1

        # Check if all actions completed
        if @current_index >= @actions.size && @active_parallel_indices.empty?
          complete_sequence
        end
      end

      # ============================================================
      # CHECKPOINT METHODS
      # ============================================================

      # Jump to a named checkpoint
      def jump_to_checkpoint(name : String) : Bool
        checkpoint = @checkpoints.find { |cp| cp.name == name }
        return false unless checkpoint

        @current_index = checkpoint.action_index
        true
      end

      # Get checkpoint by name
      def get_checkpoint(name : String) : ActionCheckpoint?
        @checkpoints.find { |cp| cp.name == name }
      end

      # ============================================================
      # CONDITION METHODS
      # ============================================================

      # Evaluate a condition and execute its actions if true
      # Returns true if condition was met and actions were executed
      def evaluate_condition(name : String) : Bool
        condition = @conditions.find { |c| c.name == name }
        return false unless condition

        # Delegate to GameStateManager for condition evaluation
        game_state = engine.game_state_manager
        return false unless game_state

        if game_state.check_condition(condition.check)
          # Handle skip_to if specified
          if skip_target = condition.skip_to
            jump_to_checkpoint(skip_target)
            return true
          end

          # Queue conditional actions for execution
          # They will be inserted into the action sequence at current position
          condition.actions.each do |action_data|
            @actions.insert(@current_index, ActionInstance.new(action_data))
          end
          true
        else
          false
        end
      end

      # Evaluate all conditions at the start of the sequence
      def evaluate_start_conditions
        @conditions.each do |condition|
          # Only evaluate conditions that have skip_to (for skipping content)
          if condition.skip_to
            evaluate_condition(condition.name)
          end
        end
      end

      # Get a variable value
      def get_variable(name : String) : YAML::Any?
        @variables[name]?
      end

      private def complete_sequence
        @completed = true
        @running = false
        engine.player_control_enabled = true
        @on_complete.try(&.call)
        publish_end_event(skipped: false)
      end

      private def current_scene : Scenes::Scene?
        engine.current_scene
      end

      private def get_executor : ActionExecutor
        @executor ||= ActionExecutor.new(engine)
      end

      private def publish_start_event
        if event_bus = engine.system_manager.try(&.event_bus)
          event_bus.publish(Core::Events::SequenceStartedEvent.new(@name))
        end
      end

      private def publish_end_event(skipped : Bool)
        if event_bus = engine.system_manager.try(&.event_bus)
          event_bus.publish(Core::Events::SequenceEndedEvent.new(@name, skipped))
        end
      end
    end
  end
end
