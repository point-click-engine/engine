require "../spec_helper"
require "luajit"

module PointClickEngine::Scripting
  # Mock engine for testing
  class MockCharEngine < Core::Engine
      property current_scene : Scenes::Scene?
      
      def initialize
        @window_width = 800
        @window_height = 600
        @window_title = "Test"
        @target_fps = 60
        @running = false
        @resolution = RL::Vector2.new(800f32, 600f32)
        @current_scene = nil
      end
  end

  # Mock character for testing
  class MockCharacterTest < Characters::Character
      property say_called : String? = nil
      property walk_to_position : RL::Vector2? = nil
      property animation_played : String? = nil
      property walking_speed : Float32 = 100.0f32
      property visible : Bool = true
      property state : Characters::CharacterState = Characters::CharacterState::Idle
      property stop_walking_called : Bool = false

      def initialize(name : String)
        super(name, RL::Vector2.new(100f32, 100f32))
      end

      def say(text : String, &block)
        @say_called = text
        yield
      end

      def walk_to(position : RL::Vector2) : Bool
        @walk_to_position = position
        @state = Characters::CharacterState::Walking
        true
      end

      def play_animation(name : String)
        @animation_played = name
      end

      def stop_walking
        @stop_walking_called = true
        @state = Characters::CharacterState::Idle
      end

      def on_interact(interactor : Characters::Character)
        # Mock implementation
      end

      def on_look
        # Mock implementation
      end

      def on_talk
        # Mock implementation
      end
  end

  # Mock scene for testing
  class MockCharScene < Scenes::Scene
      @mock_characters : Hash(String, MockCharacterTest) = {} of String => MockCharacterTest

      def initialize
        super("test_scene", RL::Vector2.new(800f32, 600f32))
      end

      def get_character(name : String) : MockCharacterTest?
        @mock_characters[name]?
      end

      def add_character(name : String, character : MockCharacterTest)
        @mock_characters[name] = character
      end
  end

  describe CharacterScriptAPI do
    describe "#initialize" do
      it "creates API with lua state and registry" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        api.should_not be_nil
      end
    end

    describe "#register" do
      it "creates character module and registers functions" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        api.register
        
        # Verify module exists
        lua.execute!("return type(character)")
        lua.to_string(-1).should eq("table")
        lua.pop(1)
        
        # Verify functions exist
        lua.execute!("return type(character.say)")
        lua.to_string(-1).should eq("function")
        lua.pop(1)
        
        lua.execute!("return type(character.move_to)")
        lua.to_string(-1).should eq("function")
        lua.pop(1)
        
        lua.execute!("return type(character.get_position)")
        lua.to_string(-1).should eq("function")
        lua.pop(1)
      end
    end

    describe "character functions" do
      pending "calls say on character" do
        # Setup
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        # Create mock engine and scene
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        scene.add_character("player", character)
        engine.current_scene = scene
        
        # Replace singleton
        Core::Engine.instance = engine
        
        # Register API
        api.register
        
        # Call from Lua
        lua.execute!("character.say('player', 'Hello world!')")
        
        # Verify
        character.say_called.should eq("Hello world!")
      end

      pending "moves character to position" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("character.move_to('player', 200, 300)")
        
        character.walk_to_position.should eq(RL::Vector2.new(200f32, 300f32))
      end

      pending "gets character position" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        character.position = RL::Vector2.new(150f32, 250f32)
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("pos = character.get_position('player')")
        lua.execute!("return pos.x")
        lua.to_f32(-1).should eq(150f32)
        lua.pop(1)
        
        lua.execute!("return pos.y")
        lua.to_f32(-1).should eq(250f32)
        lua.pop(1)
      end

      pending "returns nil for non-existent character" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("pos = character.get_position('nonexistent')")
        lua.execute!("return pos")
        lua.is_nil?(-1).should be_true
        lua.pop(1)
      end

      pending "sets character animation" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("character.set_animation('player', 'walk_left')")
        
        character.animation_played.should eq("walk_left")
      end

      pending "sets walking speed" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("character.set_walking_speed('player', 250.5)")
        
        character.walking_speed.should eq(250.5f32)
      end

      pending "faces character in direction" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("character.face_direction('player', 'left')")
        character.animation_played.should eq("idle_left")
        
        lua.execute!("character.face_direction('player', 'right')")
        character.animation_played.should eq("idle_right")
        
        lua.execute!("character.face_direction('player', 'up')")
        character.animation_played.should eq("idle_up")
        
        lua.execute!("character.face_direction('player', 'down')")
        character.animation_played.should eq("idle_down")
        
        lua.execute!("character.face_direction('player', 'unknown')")
        character.animation_played.should eq("idle")
      end

      pending "sets character visibility" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("character.set_visible('player', false)")
        character.visible.should be_false
        
        lua.execute!("character.set_visible('player', true)")
        character.visible.should be_true
      end

      pending "checks if character is walking" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        character.state = Characters::CharacterState::Walking
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("return character.is_walking('player')")
        lua.to_boolean(-1).should be_true
        lua.pop(1)
        
        character.state = Characters::CharacterState::Idle
        lua.execute!("return character.is_walking('player')")
        lua.to_boolean(-1).should be_false
        lua.pop(1)
      end

      pending "stops character walking" do
        lua = Luajit.new_with_defaults
        registry = ScriptAPIRegistry.new(lua)
        api = CharacterScriptAPI.new(lua, registry)
        
        engine = MockCharEngine.new
        scene = MockCharScene.new
        character = MockCharacterTest.new("player")
        scene.add_character("player", character)
        engine.current_scene = scene
        
        Core::Engine.instance = engine
        
        api.register
        
        lua.execute!("character.stop_walking('player')")
        
        character.stop_walking_called.should be_true
      end
    end
  end
end