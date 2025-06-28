require "yaml"
require "./scene"
require "./hotspot"
require "./polygon_hotspot"
require "./dynamic_hotspot"
require "./walkable_area"
require "../characters/character"
require "../characters/npc"
require "../assets/asset_loader"
require "../ui/cursor_manager"
require "../core/exceptions"
require "../graphics/effects/scene_effects/scene_effect_factory"

module PointClickEngine
  module Scenes
    class SceneLoader
      def self.load_from_yaml(path : String) : Scene
        scene_name = File.basename(path, ".yaml")
        scene_dir = File.dirname(path)

        begin
          yaml_content = PointClickEngine::AssetLoader.read_yaml(path)
          scene_data = YAML.parse(yaml_content)
        rescue ex
          raise Core::SceneError.new("Failed to load scene file: #{ex.message}", scene_name)
        end

        unless scene_data["name"]?
          raise Core::SceneError.new("Missing required field 'name'", scene_name)
        end

        scene = Scene.new(scene_data["name"].as_s)

        if scale = scene_data["scale"]?
          scene.scale = scale.as_f.to_f32
        end

        if background_path = scene_data["background_path"]?
          # Resolve asset path relative to scene directory
          original_path = background_path.as_s
          full_background_path = File.join(File.dirname(scene_dir), original_path)
          scene.load_background(full_background_path, original_path, scene.scale)
        end

        if enable_pathfinding = scene_data["enable_pathfinding"]?
          scene.enable_pathfinding = enable_pathfinding.as_bool
        end

        if navigation_cell_size = scene_data["navigation_cell_size"]?
          scene.navigation_cell_size = navigation_cell_size.as_i
        end

        # Load logical dimensions (default to 1024x768 if not specified)
        if logical_width = scene_data["logical_width"]?
          scene.logical_width = logical_width.as_i
        end

        if logical_height = scene_data["logical_height"]?
          scene.logical_height = logical_height.as_i
        end

        if hotspots = scene_data["hotspots"]?
          hotspots.as_a.each do |hotspot_data|
            hotspot_type = hotspot_data["type"]?.try(&.as_s) || "rectangle"

            hotspot = case hotspot_type
                      when "dynamic"
                        # Load dynamic hotspot
                        x = hotspot_data["x"]?.try(&.as_f.to_f32) || 0f32
                        y = hotspot_data["y"]?.try(&.as_f.to_f32) || 0f32
                        width = hotspot_data["width"]?.try(&.as_f.to_f32) || 100f32
                        height = hotspot_data["height"]?.try(&.as_f.to_f32) || 100f32

                        # Convert top-left to center position
                        pos = Raylib::Vector2.new(
                          x: x + width / 2,
                          y: y + height / 2
                        )
                        size = Raylib::Vector2.new(
                          x: width,
                          y: height
                        )

                        dynamic_hotspot = DynamicHotspot.new(
                          hotspot_data["name"].as_s,
                          pos,
                          size
                        )

                        # Load states
                        if states_data = hotspot_data["states"]?
                          states_data.as_h.each do |state_name, state_data|
                            state = HotspotState.new
                            if desc = state_data["description"]?
                              state.description = desc.as_s
                            end
                            if active = state_data["active"]?
                              state.active = active.as_bool
                            end
                            dynamic_hotspot.add_state(state_name.as_s, state)
                          end
                        end

                        # Load visibility conditions
                        if vis_conditions = hotspot_data["visibility_conditions"]?
                          vis_conditions.as_a.each do |cond_data|
                            if condition = load_condition(cond_data)
                              dynamic_hotspot.add_visibility_condition(condition)
                            end
                          end
                        end

                        # Load state conditions
                        if state_conditions = hotspot_data["state_conditions"]?
                          state_conditions.as_h.each do |state_name, conditions|
                            conditions.as_a.each do |cond_data|
                              if condition = load_condition(cond_data)
                                dynamic_hotspot.add_state_condition(state_name.as_s, condition)
                              end
                            end
                          end
                        end

                        dynamic_hotspot
                      when "polygon"
                        # Load polygon hotspot
                        vertices = [] of Raylib::Vector2
                        if vertices_data = hotspot_data["vertices"]?
                          vertices_data.as_a.each do |vertex|
                            vertices << Raylib::Vector2.new(
                              x: vertex["x"].as_f.to_f32,
                              y: vertex["y"].as_f.to_f32
                            )
                          end
                        end
                        PolygonHotspot.new(hotspot_data["name"].as_s, vertices)
                      else
                        # Load rectangle hotspot (default)
                        # The hotspot position is the top-left corner in YAML,
                        # but GameObject expects center position
                        x = hotspot_data["x"].as_f.to_f32
                        y = hotspot_data["y"].as_f.to_f32
                        width = hotspot_data["width"].as_f.to_f32
                        height = hotspot_data["height"].as_f.to_f32

                        # Convert top-left to center position
                        pos = Raylib::Vector2.new(
                          x: x + width / 2,
                          y: y + height / 2
                        )

                        size = Raylib::Vector2.new(
                          x: width,
                          y: height
                        )

                        Hotspot.new(hotspot_data["name"].as_s, pos, size)
                      end

            if description = hotspot_data["description"]?
              hotspot.description = description.as_s
            end

            # Load verb and object type
            if default_verb = hotspot_data["default_verb"]?
              case default_verb.as_s.downcase
              when "walk"  then hotspot.default_verb = UI::VerbType::Walk
              when "look"  then hotspot.default_verb = UI::VerbType::Look
              when "talk"  then hotspot.default_verb = UI::VerbType::Talk
              when "use"   then hotspot.default_verb = UI::VerbType::Use
              when "take"  then hotspot.default_verb = UI::VerbType::Take
              when "open"  then hotspot.default_verb = UI::VerbType::Open
              when "close" then hotspot.default_verb = UI::VerbType::Close
              when "push"  then hotspot.default_verb = UI::VerbType::Push
              when "pull"  then hotspot.default_verb = UI::VerbType::Pull
              when "give"  then hotspot.default_verb = UI::VerbType::Give
              end
            end

            if object_type = hotspot_data["object_type"]?
              case object_type.as_s.downcase
              when "background" then hotspot.object_type = UI::ObjectType::Background
              when "item"       then hotspot.object_type = UI::ObjectType::Item
              when "character"  then hotspot.object_type = UI::ObjectType::Character
              when "door"       then hotspot.object_type = UI::ObjectType::Door
              when "container"  then hotspot.object_type = UI::ObjectType::Container
              when "device"     then hotspot.object_type = UI::ObjectType::Device
              when "exit"       then hotspot.object_type = UI::ObjectType::Exit
              end
            end

            # Load action commands
            if actions = hotspot_data["actions"]?
              actions.as_h.each do |verb, command|
                hotspot.action_commands[verb.as_s] = command.as_s
              end
            end

            scene.add_hotspot(hotspot)
          end
        end

        if characters = scene_data["characters"]?
          characters.as_a.each do |char_data|
            pos = if position = char_data["position"]?
                    Raylib::Vector2.new(
                      x: position["x"].as_f.to_f32,
                      y: position["y"].as_f.to_f32
                    )
                  else
                    Raylib::Vector2.new(x: 0f32, y: 0f32)
                  end

            size = Raylib::Vector2.new(x: 32f32, y: 64f32) # Default character size
            if char_size = char_data["size"]?
              size.x = char_size["width"].as_f.to_f32
              size.y = char_size["height"].as_f.to_f32
            end

            character = Characters::NPC.new(char_data["name"].as_s, pos, size)

            if sprite_path = char_data["sprite_path"]?
              frame_width = 32
              frame_height = 64
              if sprite_info = char_data["sprite_info"]?
                frame_width = sprite_info["frame_width"].as_i
                frame_height = sprite_info["frame_height"].as_i
              end
              # Resolve asset path relative to scene directory
              full_sprite_path = File.join(File.dirname(scene_dir), sprite_path.as_s)
              character.load_spritesheet(full_sprite_path, frame_width, frame_height)
            end

            # Apply scale from YAML if specified
            if char_scale = char_data["scale"]?
              scale_value = char_scale.as_f.to_f32
              character.manual_scale = scale_value
              character.scale = scale_value
            end

            scene.add_character(character)
          end
        end

        if script_path = scene_data["script_path"]?
          scene.script_path = script_path.as_s
        end

        # Load scene effects
        if effects = scene_data["effects"]?
          effects.as_a.each do |effect_data|
            effect_type = effect_data["type"]?.try(&.as_s) || ""
            
            # Convert YAML parameters for the specific effect type
            params = {} of String => String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32)
            
            effect_data.as_h.each do |key, value|
              key_str = key.as_s
              next if key_str == "type"  # Skip the type key
              
              # Map fog_type to type for the factory
              param_key = key_str == "fog_type" ? "type" : key_str
              param_symbol = param_key.to_s
              
              params[param_symbol] = case value.raw
                                     when String then value.as_s
                                     when Int64 then value.as_i
                                     when Float64 then value.as_f.to_f32
                                     when Bool then value.as_bool
                                     when Array
                                       # Handle color arrays
                                       value.as_a.map { |v| v.as_i }
                                     else
                                       value.to_s
                                     end
            end
            
            # Use existing private methods to create effects based on type
            begin
              effect = case effect_type
                      when "fog"
                        create_fog_effect(params)
                      when "rain"
                        create_rain_effect(params)
                      when "darkness"
                        create_darkness_effect(params)
                      when "underwater"
                        create_underwater_effect(params)
                      when "simple_rain"
                        create_simple_rain_effect(params)
                      when "test_overlay"
                        create_test_overlay_effect(params)
                      else
                        nil
                      end
              
              if effect
                scene.scene_effects << effect
              else
                puts "[SceneLoader] Warning: Unknown effect type '#{effect_type}'"
              end
            rescue ex
              puts "[SceneLoader] Error creating effect '#{effect_type}': #{ex.message}"
            end
          end
        end

        # Load walkable areas
        if walkable_data = scene_data["walkable_areas"]?
          walkable_area = WalkableArea.new

          # Load regions
          if regions = walkable_data["regions"]?
            regions.as_a.each do |region_data|
              region = PolygonRegion.new(
                name: region_data["name"]?.try(&.as_s) || "",
                walkable: region_data["walkable"]?.try(&.as_bool) != false
              )

              if vertices = region_data["vertices"]?
                vertices.as_a.each do |vertex|
                  region.vertices << Raylib::Vector2.new(
                    x: vertex["x"].as_f.to_f32,
                    y: vertex["y"].as_f.to_f32
                  )
                end
              end

              walkable_area.regions << region
            end
            # Ensure bounds are updated after loading all regions
            walkable_area.update_bounds
          end

          # Load walk-behind regions
          if walk_behind = walkable_data["walk_behind"]?
            walk_behind.as_a.each do |behind_data|
              region = WalkBehindRegion.new(
                name: behind_data["name"]?.try(&.as_s) || "",
                y_threshold: behind_data["y_threshold"].as_f.to_f32,
                z_order: behind_data["z_order"]?.try(&.as_i) || 0
              )

              if vertices = behind_data["vertices"]?
                vertices.as_a.each do |vertex|
                  region.vertices << Raylib::Vector2.new(
                    x: vertex["x"].as_f.to_f32,
                    y: vertex["y"].as_f.to_f32
                  )
                end
              end

              walkable_area.walk_behind_regions << region
            end
          end

          # Load scale zones
          if scale_zones = walkable_data["scale_zones"]?
            scale_zones.as_a.each do |zone_data|
              zone = ScaleZone.new(
                min_y: zone_data["min_y"].as_f.to_f32,
                max_y: zone_data["max_y"].as_f.to_f32,
                min_scale: zone_data["min_scale"]?.try(&.as_f.to_f32) || 0.5f32,
                max_scale: zone_data["max_scale"]?.try(&.as_f.to_f32) || 1.0f32
              )

              walkable_area.scale_zones << zone
            end
          end

          walkable_area.update_bounds
          scene.walkable_area = walkable_area
        end

        # Setup navigation after loading walkable areas
        if scene.enable_pathfinding && scene.walkable_area
          scene.setup_navigation
        end

        scene
      end

      # Create a fog effect from parsed parameters
      private def self.create_fog_effect(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : Graphics::Effects::SceneEffects::FogShader?
        fog_type = case params["type"]?.try(&.to_s)
        when "linear"      then Graphics::Effects::SceneEffects::FogType::Linear
        when "exponential" then Graphics::Effects::SceneEffects::FogType::Exponential
        when "layered"     then Graphics::Effects::SceneEffects::FogType::Layered
        when "volumetric"  then Graphics::Effects::SceneEffects::FogType::Volumetric
        else Graphics::Effects::SceneEffects::FogType::Linear
        end
        
        # Parse color array to RL::Color
        color = if color_array = params["color"]?.try(&.as(Array(Int32)))
          RL::Color.new(
            r: color_array[0].to_u8,
            g: color_array[1].to_u8,
            b: color_array[2].to_u8,
            a: (color_array[3]? || 255).to_u8
          )
        else
          RL::Color.new(r: 128, g: 128, b: 150, a: 200)
        end
        
        density = params["density"]?.try(&.as(Float32)) || 0.02f32
        duration = params["duration"]?.try(&.as(Float32)) || 0.0f32
        
        effect = Graphics::Effects::SceneEffects::FogShader.new(fog_type, color, density, duration)
        
        # Set additional parameters if provided
        if fog_start = params["start"]?.try(&.as(Float32))
          effect.fog_start = fog_start
        end
        if fog_end = params["end"]?.try(&.as(Float32))
          effect.fog_end = fog_end
        end
        
        effect
      end

      # Create a rain effect from parsed parameters
      private def self.create_rain_effect(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : Graphics::Effects::SceneEffects::RainShader?
        rain_intensity = case params["intensity"]?.try(&.to_s)
        when "light"  then Graphics::Effects::SceneEffects::RainIntensity::Light
        when "medium" then Graphics::Effects::SceneEffects::RainIntensity::Medium
        when "heavy"  then Graphics::Effects::SceneEffects::RainIntensity::Heavy
        when "storm"  then Graphics::Effects::SceneEffects::RainIntensity::Storm
        else Graphics::Effects::SceneEffects::RainIntensity::Medium
        end
        
        wind_strength = params["wind"]?.try(&.as(Float32)) || 0.2f32
        duration = params["duration"]?.try(&.as(Float32)) || 0.0f32
        
        effect = Graphics::Effects::SceneEffects::RainShader.new(rain_intensity, wind_strength, duration)
        
        # Parse color array to RL::Color
        if color_array = params["color"]?.try(&.as(Array(Int32)))
          effect.rain_color = RL::Color.new(
            r: color_array[0].to_u8,
            g: color_array[1].to_u8,
            b: color_array[2].to_u8,
            a: (color_array[3]? || 255).to_u8
          )
        end
        
        if splashes = params["splashes"]?.try(&.as(Bool))
          effect.splash_enabled = splashes
        end
        
        effect
      end

      # Create a simple CPU-based rain effect from parsed parameters
      private def self.create_simple_rain_effect(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : Graphics::Effects::SceneEffects::RainEffect?
        intensity = params["intensity"]?.try(&.to_s) == "heavy" ? 1.0f32 : 0.5f32
        duration = params["duration"]?.try(&.as(Float32)) || 0.0f32
        
        effect = Graphics::Effects::SceneEffects::RainEffect.new(intensity, duration)
        
        # Set wind speed if provided
        if wind = params["wind"]?
          case wind
          when Float32
            effect.wind_speed = -wind
          when Int32
            effect.wind_speed = -wind.to_f32
          when String
            effect.wind_speed = -wind.to_f32
          end
        end
        
        # Parse color array to RL::Color
        if color_array = params["color"]?.try(&.as(Array(Int32)))
          effect.drop_color = RL::Color.new(
            r: color_array[0].to_u8,
            g: color_array[1].to_u8,
            b: color_array[2].to_u8,
            a: (color_array[3]? || 255).to_u8
          )
        end
        
        effect
      end

      # Create a simple test overlay effect that draws a colored rectangle
      private def self.create_test_overlay_effect(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : Graphics::Effects::SceneEffects::TestOverlayEffect?
        # Parse color array to RL::Color
        color = if color_array = params["color"]?.try(&.as(Array(Int32)))
          RL::Color.new(
            r: color_array[0].to_u8,
            g: color_array[1].to_u8,
            b: color_array[2].to_u8,
            a: (color_array[3]? || 255).to_u8
          )
        else
          RL::Color.new(r: 255, g: 0, b: 0, a: 100)
        end
        
        Graphics::Effects::SceneEffects::TestOverlayEffect.new(color)
      end
      
      # Create a darkness effect from parsed parameters
      private def self.create_darkness_effect(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : Graphics::Effects::SceneEffects::DarknessShader?
        intensity = params["intensity"]?.try(&.as(Float32)) || 0.8f32
        duration = params["duration"]?.try(&.as(Float32)) || 0.0f32
        
        # Just use simple vignette darkness
        darkness_type = Graphics::Effects::SceneEffects::DarknessType::Vignette
        
        Graphics::Effects::SceneEffects::DarknessShader.new(darkness_type, intensity, duration)
      end
      
      # Create an underwater effect from parsed parameters
      private def self.create_underwater_effect(params : Hash(String, String | Float32 | Int32 | Bool | Array(Int32) | Array(Float32))) : Graphics::Effects::SceneEffects::UnderwaterShader?
        # Determine quality level
        quality = Graphics::Effects::SceneEffects::UnderwaterQuality::Medium
        
        # Parse water color
        water_color = if color_array = params["color"]?.try(&.as(Array(Int32)))
          RL::Color.new(
            r: color_array[0].to_u8,
            g: color_array[1].to_u8,
            b: color_array[2].to_u8,
            a: (color_array[3]? || 100).to_u8
          )
        else
          RL::Color.new(r: 0, g: 80, b: 120, a: 100)
        end
        
        duration = params["duration"]?.try(&.as(Float32)) || 0.0f32
        
        effect = Graphics::Effects::SceneEffects::UnderwaterShader.new(quality, water_color, duration)
        
        # Set wave parameters if provided
        if wave_amplitude = params["wave_amplitude"]?.try(&.as(Float32))
          effect.wave_amplitude = wave_amplitude
        end
        
        if wave_frequency = params["wave_frequency"]?.try(&.as(Float32))
          effect.wave_frequency = wave_frequency
        end
        
        effect
      end

      # Load a condition from YAML data
      private def self.load_condition(cond_data : YAML::Any) : Condition?
        cond_type = cond_data["type"]?.try(&.as_s) || return nil

        case cond_type
        when "inventory"
          item_name = cond_data["item"]?.try(&.as_s) || return nil
          has_item = cond_data["has_item"]?.try(&.as_bool) != false
          InventoryCondition.new(item_name, has_item)
        when "state"
          variable = cond_data["variable"]?.try(&.as_s) || return nil
          value = cond_data["value"]
          return nil unless value

          # Convert value to appropriate type
          actual_value = case value.raw
                         when String  then value.as_s
                         when Int64   then value.as_i.to_i32
                         when Float64 then value.as_f.to_f32
                         when Bool    then value.as_bool
                         else              return nil
                         end

          # Parse operator
          operator = ComparisonOperator::Equals
          if op_str = cond_data["operator"]?.try(&.as_s)
            case op_str.downcase
            when "equals", "=="        then operator = ComparisonOperator::Equals
            when "not_equals", "!="    then operator = ComparisonOperator::NotEquals
            when "greater", ">"        then operator = ComparisonOperator::Greater
            when "greater_equal", ">=" then operator = ComparisonOperator::GreaterEqual
            when "less", "<"           then operator = ComparisonOperator::Less
            when "less_equal", "<="    then operator = ComparisonOperator::LessEqual
            end
          end

          StateCondition.new(variable, actual_value, operator)
        when "combined"
          conditions = [] of Condition
          if cond_list = cond_data["conditions"]?.try(&.as_a)
            cond_list.each do |sub_cond|
              if cond = load_condition(sub_cond)
                conditions << cond
              end
            end
          end

          return nil if conditions.empty?

          logic = CombinedCondition::LogicType::And
          if logic_str = cond_data["logic"]?.try(&.as_s)
            case logic_str.downcase
            when "and" then logic = CombinedCondition::LogicType::And
            when "or"  then logic = CombinedCondition::LogicType::Or
            end
          end

          CombinedCondition.new(conditions, logic)
        else
          nil
        end
      end


      def self.save_to_yaml(scene : Scene, path : String)
        yaml_data = {
          "name"                 => scene.name,
          "background_path"      => scene.background_path,
          "scale"                => scene.scale,
          "enable_pathfinding"   => scene.enable_pathfinding,
          "navigation_cell_size" => scene.navigation_cell_size,
          "hotspots"             => scene.hotspots.map do |hotspot|
            base_data = {
              "name"        => hotspot.name,
              "description" => hotspot.description,
            }

            if hotspot.is_a?(PolygonHotspot)
              polygon_hotspot = hotspot.as(PolygonHotspot)
              base_data.merge({
                "type"     => "polygon",
                "vertices" => polygon_hotspot.vertices.map do |vertex|
                  {"x" => vertex.x, "y" => vertex.y}
                end,
              })
            else
              # Convert center position back to top-left for saving
              x = hotspot.position.x - hotspot.size.x / 2
              y = hotspot.position.y - hotspot.size.y / 2

              base_data.merge({
                "type"   => "rectangle",
                "x"      => x,
                "y"      => y,
                "width"  => hotspot.size.x,
                "height" => hotspot.size.y,
              })
            end
          end,
          "characters" => scene.characters.map do |character|
            {
              "name"     => character.name,
              "position" => {
                "x" => character.position.x,
                "y" => character.position.y,
              },
            }
          end,
        }

        File.write(path, yaml_data.to_yaml)
      end
    end
  end
end
