# Character scaling based on Y position (perspective) component

module PointClickEngine
  module Scenes
    # Manages scale zones for character perspective effects
    class ScaleZoneManager
      @scale_zones : Array(ScaleZone)

      def initialize
        @scale_zones = [] of ScaleZone
      end

      # Add a scale zone
      def add_zone(zone : ScaleZone) : Nil
        @scale_zones << zone
      end

      # Get all scale zones
      def zones : Array(ScaleZone)
        @scale_zones
      end

      # Clear all zones
      def clear : Nil
        @scale_zones.clear
      end

      # Get character scale based on Y position
      def get_scale_at_y(y : Float32) : Float32
        return 1.0f32 if @scale_zones.empty?

        # Find the appropriate scale zone
        @scale_zones.each do |zone|
          if y >= zone.min_y && y <= zone.max_y
            # Linear interpolation within the zone
            t = (y - zone.min_y) / (zone.max_y - zone.min_y)
            return zone.min_scale + t * (zone.max_scale - zone.min_scale)
          end
        end

        # Default scale if outside all zones
        1.0f32
      end

      # Check if Y position is within any scale zone
      def in_scale_zone?(y : Float32) : Bool
        @scale_zones.any? do |zone|
          y >= zone.min_y && y <= zone.max_y
        end
      end

      # Get the scale zone at a specific Y position
      def get_zone_at_y(y : Float32) : ScaleZone?
        @scale_zones.find do |zone|
          y >= zone.min_y && y <= zone.max_y
        end
      end

      # Validate scale zones (check for overlaps, invalid ranges, etc.)
      def validate_zones : Array(String)
        errors = [] of String

        @scale_zones.each_with_index do |zone, i|
          # Check for invalid range
          if zone.min_y >= zone.max_y
            errors << "Scale zone #{i} has invalid Y range: min_y (#{zone.min_y}) >= max_y (#{zone.max_y})"
          end

          # Check for invalid scale values
          if zone.min_scale < 0.0 || zone.max_scale < 0.0
            errors << "Scale zone #{i} has negative scale values"
          end

          # Check for overlaps with other zones (only check zones after current one to avoid duplicates)
          @scale_zones.each_with_index do |other_zone, j|
            next if i >= j # Skip if same zone or already checked

            if zones_overlap?(zone, other_zone)
              errors << "Scale zones #{i} and #{j} overlap"
            end
          end
        end

        errors
      end

      private def zones_overlap?(zone1 : ScaleZone, zone2 : ScaleZone) : Bool
        # Zones overlap if one's min is between the other's min and max
        (zone1.min_y >= zone2.min_y && zone1.min_y <= zone2.max_y) ||
          (zone1.max_y >= zone2.min_y && zone1.max_y <= zone2.max_y) ||
          (zone2.min_y >= zone1.min_y && zone2.min_y <= zone1.max_y) ||
          (zone2.max_y >= zone1.min_y && zone2.max_y <= zone1.max_y)
      end
    end
  end
end
