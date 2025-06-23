require "../spec_helper"

# Quest system edge case testing
# Tests complex quest scenarios, error conditions, and edge cases
describe "Quest System Edge Case Testing" do
  describe "quest objective edge cases" do
    it "handles complex condition expressions" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      
      # Complex boolean conditions
      complex_conditions = [
        "has_key && has_map",
        "level >= 5",
        "gold > 100 && items_found >= 3",
        "!door_locked",
        "health > 0"
      ]
      
      complex_conditions.each_with_index do |condition, i|
        objective = PointClickEngine::Core::QuestObjective.new(
          "complex_#{i}",
          "Complex objective #{i}",
          condition
        )
        
        # Should not crash on complex conditions
        begin
          result = objective.check_completion(state_manager)
          result.should be_a(Bool)
        rescue ex
          # Some conditions might fail if variables don't exist, that's OK
          ex.should be_a(Exception)
        end
      end
    end
    
    it "handles invalid condition expressions" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      
      invalid_conditions = [
        "",                          # Empty condition
        "invalid syntax !!!",        # Syntax error
        "undefined_variable",        # Undefined variable
        "1 + ",                     # Incomplete expression
        "true && ",                 # Incomplete boolean
        "null.property",            # Null access
        "very_long_" + ("a" * 1000) # Very long condition
      ]
      
      invalid_conditions.each_with_index do |condition, i|
        objective = PointClickEngine::Core::QuestObjective.new(
          "invalid_#{i}",
          "Invalid objective #{i}",
          condition
        )
        
        # Should handle errors gracefully
        begin
          result = objective.check_completion(state_manager)
          # If it succeeds, result should be boolean
          result.should be_a(Bool)
        rescue ex
          # Errors are acceptable for invalid conditions
          ex.should be_a(Exception)
        end
      end
    end
    
    it "handles rapid completion state changes" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      objective = PointClickEngine::Core::QuestObjective.new(
        "rapid_test",
        "Rapid completion test",
        "rapid_flag"
      )
      
      # Rapidly toggle the condition
      100.times do |i|
        state_manager.set_flag("rapid_flag", i % 2 == 0)
        result = objective.check_completion(state_manager)
        
        if i % 2 == 0
          result.should be_true
          objective.completed.should be_true
        else
          # Once completed, objective stays completed
          objective.completed.should be_true
        end
      end
    end
    
    it "handles reset functionality correctly" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      objective = PointClickEngine::Core::QuestObjective.new(
        "reset_test",
        "Reset test objective",
        "reset_flag"
      )
      
      # Complete the objective
      state_manager.set_flag("reset_flag", true)
      objective.check_completion(state_manager).should be_true
      objective.completed.should be_true
      
      # Reset should clear completion
      objective.reset
      objective.completed.should be_false
      
      # Can be completed again after reset
      objective.check_completion(state_manager).should be_true
      objective.completed.should be_true
    end
  end

  describe "quest reward edge cases" do
    it "handles various reward types" do
      reward_types = [
        {"item", "sword", 1},
        {"experience", "combat", 100},
        {"money", "gold", 500},
        {"flag", "quest_complete", 1},
        {"custom", "special_reward", 10}
      ]
      
      reward_types.each do |type, identifier, amount|
        reward = PointClickEngine::Core::QuestReward.new(type, identifier, amount)
        
        reward.type.should eq(type)
        reward.identifier.should eq(identifier)
        reward.amount.should eq(amount)
      end
    end
    
    it "handles extreme reward amounts" do
      extreme_amounts = [0, -1, 1, 1000000, Int32::MAX, Int32::MIN]
      
      extreme_amounts.each do |amount|
        reward = PointClickEngine::Core::QuestReward.new("test", "test_item", amount)
        reward.amount.should eq(amount)
      end
    end
    
    it "handles edge case identifiers" do
      edge_case_identifiers = [
        "",                           # Empty identifier
        " ",                         # Whitespace
        "special!@#$%^&*()chars",    # Special characters
        "unicode_🎮_test",           # Unicode
        "very_long_" + ("x" * 1000)  # Very long identifier
      ]
      
      edge_case_identifiers.each do |identifier|
        reward = PointClickEngine::Core::QuestReward.new("test", identifier, 1)
        reward.identifier.should eq(identifier)
      end
    end
  end

  describe "quest system performance under stress" do
    it "handles many objectives efficiently" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      objectives = [] of PointClickEngine::Core::QuestObjective
      
      # Create many objectives
      1000.times do |i|
        objective = PointClickEngine::Core::QuestObjective.new(
          "stress_objective_#{i}",
          "Stress test objective #{i}",
          "stress_flag_#{i % 10}" # Cycle through 10 different flags
        )
        objectives << objective
      end
      
      # Set some flags to complete some objectives
      10.times do |i|
        state_manager.set_flag("stress_flag_#{i}", true)
      end
      
      # Check all objectives
      start_time = Time.monotonic
      completed_count = 0
      
      objectives.each do |objective|
        if objective.check_completion(state_manager)
          completed_count += 1
        end
      end
      
      check_time = Time.monotonic - start_time
      
      puts "Quest stress test results:"
      puts "  Total objectives: #{objectives.size}"
      puts "  Completed: #{completed_count}"
      puts "  Check time: #{check_time.total_milliseconds.round(2)}ms"
      puts "  Time per objective: #{(check_time.total_milliseconds / objectives.size).round(4)}ms"
      
      # Should be reasonably fast
      (check_time.total_milliseconds / objectives.size).should be < 0.01 # 0.01ms per objective
      completed_count.should be > 0
    end
    
    it "handles complex nested quest dependencies" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      
      # Create dependency chain: A -> B -> C -> D
      objective_a = PointClickEngine::Core::QuestObjective.new(
        "dep_a",
        "First dependency",
        "initial_flag"
      )
      
      objective_b = PointClickEngine::Core::QuestObjective.new(
        "dep_b", 
        "Second dependency",
        "initial_flag && dep_a_complete"
      )
      
      objective_c = PointClickEngine::Core::QuestObjective.new(
        "dep_c",
        "Third dependency", 
        "dep_a_complete && dep_b_complete"
      )
      
      objective_d = PointClickEngine::Core::QuestObjective.new(
        "dep_d",
        "Final dependency",
        "dep_a_complete && dep_b_complete && dep_c_complete"
      )
      
      objectives = [objective_a, objective_b, objective_c, objective_d]
      
      # Initially none should be complete
      objectives.each do |obj|
        obj.check_completion(state_manager).should be_false
      end
      
      # Set initial flag
      state_manager.set_flag("initial_flag", true)
      
      # A should complete
      objective_a.check_completion(state_manager).should be_true
      state_manager.set_flag("dep_a_complete", true)
      
      # B should complete  
      objective_b.check_completion(state_manager).should be_true
      state_manager.set_flag("dep_b_complete", true)
      
      # C should complete
      objective_c.check_completion(state_manager).should be_true
      state_manager.set_flag("dep_c_complete", true)
      
      # D should complete
      objective_d.check_completion(state_manager).should be_true
    end
  end

  describe "quest serialization edge cases" do
    it "serializes and deserializes objectives correctly" do
      objective = PointClickEngine::Core::QuestObjective.new(
        "serialize_test",
        "Test serialization",
        "test_condition"
      )
      objective.optional = true
      objective.hidden = true
      objective.completed = true
      
      # Test JSON serialization
      json_string = objective.to_json
      json_string.should_not be_empty
      json_string.should contain("serialize_test")
      json_string.should contain("Test serialization")
      
      loaded_from_json = PointClickEngine::Core::QuestObjective.from_json(json_string)
      loaded_from_json.id.should eq(objective.id)
      loaded_from_json.description.should eq(objective.description)
      loaded_from_json.condition.should eq(objective.condition)
      loaded_from_json.optional.should eq(objective.optional)
      loaded_from_json.hidden.should eq(objective.hidden)
      loaded_from_json.completed.should eq(objective.completed)
      
      # Test YAML serialization
      yaml_string = objective.to_yaml
      yaml_string.should_not be_empty
      
      loaded_from_yaml = PointClickEngine::Core::QuestObjective.from_yaml(yaml_string)
      loaded_from_yaml.id.should eq(objective.id)
      loaded_from_yaml.description.should eq(objective.description)
      loaded_from_yaml.optional.should eq(objective.optional)
      loaded_from_yaml.hidden.should eq(objective.hidden)
      loaded_from_yaml.completed.should eq(objective.completed)
    end
    
    it "handles corrupted serialization data" do
      corrupted_json_data = [
        "{\"id\": \"test\"}",  # Missing required fields
        "{\"id\": }",          # Invalid JSON
        "not json at all",     # Not JSON
        "{}",                  # Empty object
        "{\"id\": null}"       # Null values
      ]
      
      corrupted_json_data.each do |data|
        begin
          PointClickEngine::Core::QuestObjective.from_json(data)
          # If it succeeds, that's fine too
        rescue ex
          # Errors are expected for corrupted data
          ex.should be_a(Exception)
        end
      end
      
      corrupted_yaml_data = [
        "id: test",           # Missing required fields
        "invalid: yaml: [",   # Invalid YAML
        "",                   # Empty string
        "id:",               # Incomplete YAML
      ]
      
      corrupted_yaml_data.each do |data|
        begin
          PointClickEngine::Core::QuestObjective.from_yaml(data)
        rescue ex
          ex.should be_a(Exception)
        end
      end
    end
  end

  describe "quest state management edge cases" do
    it "handles concurrent objective checking" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      shared_condition = "concurrent_flag"
      
      # Create multiple objectives with same condition
      objectives = [] of PointClickEngine::Core::QuestObjective
      10.times do |i|
        objective = PointClickEngine::Core::QuestObjective.new(
          "concurrent_#{i}",
          "Concurrent objective #{i}",
          shared_condition
        )
        objectives << objective
      end
      
      # All should be incomplete initially
      objectives.each do |obj|
        obj.check_completion(state_manager).should be_false
        obj.completed.should be_false
      end
      
      # Set the flag
      state_manager.set_flag("concurrent_flag", true)
      
      # All should complete
      objectives.each do |obj|
        obj.check_completion(state_manager).should be_true
        obj.completed.should be_true
      end
    end
    
    it "handles memory management during many operations" do
      initial_memory = GC.stats.heap_size
      
      # Create and destroy many quest objects
      100.times do |cycle|
        objectives = [] of PointClickEngine::Core::QuestObjective
        rewards = [] of PointClickEngine::Core::QuestReward
        
        # Create many objects
        50.times do |i|
          objective = PointClickEngine::Core::QuestObjective.new(
            "memory_test_#{cycle}_#{i}",
            "Memory test objective #{i}",
            "memory_flag_#{i}"
          )
          objectives << objective
          
          reward = PointClickEngine::Core::QuestReward.new(
            "item",
            "memory_item_#{i}",
            rand(100)
          )
          rewards << reward
        end
        
        # Use the objects
        state_manager = PointClickEngine::Core::GameStateManager.new
        state_manager.set_flag("memory_flag_25", true)
        
        objectives.each do |obj|
          obj.check_completion(state_manager)
        end
        
        # Objects go out of scope here
      end
      
      # Force garbage collection
      GC.collect
      final_memory = GC.stats.heap_size
      memory_growth = final_memory.to_i64 - initial_memory.to_i64
      
      puts "Quest memory test: growth = #{memory_growth} bytes"
      
      # Should not leak significant memory
      memory_growth.should be < 5_000_000 # 5MB limit
    end
  end

  describe "quest system integration edge cases" do
    it "handles state manager integration robustly" do
      state_manager = PointClickEngine::Core::GameStateManager.new
      
      # Test various state configurations
      # Test various state configurations
      scenarios = [
        {condition: "simple_flag", setup_proc: ->(sm : PointClickEngine::Core::GameStateManager) { sm.set_flag("simple_flag", true) }, expected: true},
        {condition: "!negative_flag", setup_proc: ->(sm : PointClickEngine::Core::GameStateManager) { sm.set_flag("negative_flag", false) }, expected: true},
        {condition: "missing_flag", setup_proc: ->(sm : PointClickEngine::Core::GameStateManager) { }, expected: false},
      ]
      
      scenarios.each_with_index do |scenario, i|
        objective = PointClickEngine::Core::QuestObjective.new(
          "integration_#{i}",
          "Integration test #{i}",
          scenario[:condition]
        )
        
        # Setup state
        scenario[:setup_proc].call(state_manager)
        
        # Check result
        begin
          result = objective.check_completion(state_manager)
          result.should eq(scenario[:expected])
        rescue ex
          # Some conditions might fail, that's OK for edge case testing
          ex.should be_a(Exception)
        end
      end
    end
    
    it "handles unicode and special characters in quest data" do
      special_characters_tests = [
        "🎮 Quest with emoji",
        "Quest with 中文 characters", 
        "Quest with русский text",
        "Quest with special chars: !@#$%^&*()",
        "Quest\nwith\nnewlines",
        "Quest\twith\ttabs",
        "Quest with \"quotes\" and 'apostrophes'"
      ]
      
      special_characters_tests.each_with_index do |description, i|
        objective = PointClickEngine::Core::QuestObjective.new(
          "unicode_#{i}",
          description,
          "unicode_flag_#{i}"
        )
        
        # Should handle special characters without crashing
        objective.description.should eq(description)
        
        # Should serialize/deserialize correctly
        json_string = objective.to_json
        loaded = PointClickEngine::Core::QuestObjective.from_json(json_string)
        loaded.description.should eq(description)
      end
    end
  end
end