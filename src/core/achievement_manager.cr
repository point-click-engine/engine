require "yaml"

module PointClickEngine
  module Core
    class AchievementManager
      class Achievement
        include YAML::Serializable

        property id : String
        property name : String
        property description : String
        property unlocked : Bool = false
        property unlock_time : Time?
        property icon_path : String?
        property hidden : Bool = false

        def initialize(@id : String, @name : String, @description : String, @hidden : Bool = false)
        end
      end

      property achievements : Hash(String, Achievement) = {} of String => Achievement
      property save_file : String = "achievements.yaml"
      property notification_duration : Float32 = 3.0f32

      @notification_queue : Array(Achievement) = [] of Achievement
      @current_notification : Achievement?
      @notification_timer : Float32 = 0.0f32

      def initialize
        register_default_achievements
        load_progress
      end

      def register(id : String, name : String, description : String, hidden : Bool = false)
        @achievements[id] = Achievement.new(id, name, description, hidden)
      end

      def unlock(id : String) : Bool
        achievement = @achievements[id]?
        return false unless achievement
        return false if achievement.unlocked

        achievement.unlocked = true
        achievement.unlock_time = Time.utc

        # Queue notification
        @notification_queue << achievement

        # Save progress
        save_progress

        # Trigger event
        begin
          engine = Engine.instance
          engine.event_system.trigger_event("achievement_unlocked", {"id" => id, "name" => achievement.name})
        rescue
          # Engine not initialized yet
        end

        true
      end

      def is_unlocked?(id : String) : Bool
        @achievements[id]?.try(&.unlocked) || false
      end

      def get_progress : {unlocked: Int32, total: Int32}
        unlocked = @achievements.values.count(&.unlocked)
        total = @achievements.size
        {unlocked: unlocked, total: total}
      end

      def update(dt : Float32)
        # Handle notification display
        if @current_notification.nil? && !@notification_queue.empty?
          @current_notification = @notification_queue.shift
          @notification_timer = @notification_duration
        end

        if @current_notification && @notification_timer > 0
          @notification_timer -= dt
          if @notification_timer <= 0
            @current_notification = nil
          end
        end
      end

      def draw
        return unless notification = @current_notification
        return if @notification_timer <= 0

        # Draw achievement notification
        x = 20
        y = 20
        width = 300
        height = 80

        # Background
        alpha = Math.min(@notification_timer, 1.0f32) * 255
        bg_color = Raylib::Color.new(r: 0, g: 0, b: 0, a: alpha.to_u8)
        Raylib.draw_rectangle(x, y, width, height, bg_color)

        # Border
        border_color = Raylib::Color.new(r: 255, g: 215, b: 0, a: alpha.to_u8)
        Raylib.draw_rectangle_lines(x, y, width, height, border_color)

        # Text
        text_color = Raylib::Color.new(r: 255, g: 255, b: 255, a: alpha.to_u8)
        Raylib.draw_text("Achievement Unlocked!", x + 10, y + 10, 16, text_color)
        Raylib.draw_text(notification.name, x + 10, y + 35, 20, text_color)

        # Description (if fits)
        if notification.description.size < 40
          desc_color = Raylib::Color.new(r: 200, g: 200, b: 200, a: alpha.to_u8)
          Raylib.draw_text(notification.description, x + 10, y + 60, 14, desc_color)
        end
      end

      def save_progress
        save_data = @achievements.transform_values do |achievement|
          {
            "unlocked"    => achievement.unlocked,
            "unlock_time" => achievement.unlock_time.try(&.to_s),
          }
        end

        File.write(@save_file, save_data.to_yaml)
      rescue ex
        puts "Failed to save achievements: #{ex.message}"
      end

      def load_progress
        return unless File.exists?(@save_file)

        yaml_content = File.read(@save_file)
        save_data = Hash(String, Hash(String, YAML::Any)).from_yaml(yaml_content)

        save_data.each do |id, data|
          if achievement = @achievements[id]?
            achievement.unlocked = data["unlocked"].as_bool
            if unlock_time_str = data["unlock_time"]?.try(&.as_s?)
              achievement.unlock_time = Time.parse(unlock_time_str, "%Y-%m-%d %H:%M:%S UTC", Time::Location::UTC)
            end
          end
        end
      rescue ex
        puts "Failed to load achievements: #{ex.message}"
      end

      private def register_default_achievements
        # Story achievements
        register("game_complete", "Crystal Guardian", "Complete the main story")
        register("all_secrets", "Secret Hunter", "Find all hidden secrets")

        # Exploration achievements
        register("bookworm", "Bookworm", "Find the hidden note in the library")
        register("puzzle_master", "Puzzle Master", "Solve the fountain puzzle")

        # Collection achievements
        register("collector", "Collector", "Find all items")

        # Hidden achievements
        register("speedrun", "Speed Runner", "Complete the game in under 10 minutes", hidden: true)
      end
    end
  end
end
