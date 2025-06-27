# Audio resource caching and memory management component

module PointClickEngine
  module Audio
    # Manages audio resource caching with memory limits
    class AudioResourceCache
      # Maximum memory usage for cached audio in bytes
      property max_memory_bytes : UInt64 = 100_000_000_u64 # 100MB default

      # Current memory usage
      getter current_memory_usage : UInt64 = 0_u64

      # Cache statistics
      getter cache_hits : UInt32 = 0_u32
      getter cache_misses : UInt32 = 0_u32

      # Resource metadata
      struct ResourceInfo
        property size_bytes : UInt64
        property last_accessed : Time
        property access_count : UInt32

        def initialize(@size_bytes : UInt64)
          @last_accessed = Time.local
          @access_count = 0_u32
        end
      end

      # Resource tracking
      @resource_info = {} of String => ResourceInfo

      # Register a loaded resource
      def register_resource(name : String, size_bytes : UInt64) : Nil
        @resource_info[name] = ResourceInfo.new(size_bytes)
        @current_memory_usage += size_bytes

        # Evict old resources if over memory limit
        evict_if_needed
      end

      # Mark resource as accessed
      def access_resource(name : String) : Nil
        if info = @resource_info[name]?
          info.last_accessed = Time.local
          info.access_count += 1
          @cache_hits += 1
        else
          @cache_misses += 1
        end
      end

      # Remove a resource from cache tracking
      def remove_resource(name : String) : Nil
        if info = @resource_info.delete(name)
          @current_memory_usage -= info.size_bytes
        end
      end

      # Get cache statistics
      def get_stats : NamedTuple(
        memory_usage: UInt64,
        memory_limit: UInt64,
        resource_count: Int32,
        cache_hits: UInt32,
        cache_misses: UInt32,
        hit_rate: Float32)
        total_accesses = @cache_hits + @cache_misses
        hit_rate = total_accesses > 0 ? @cache_hits.to_f32 / total_accesses : 0.0f32

        {
          memory_usage:   @current_memory_usage,
          memory_limit:   @max_memory_bytes,
          resource_count: @resource_info.size,
          cache_hits:     @cache_hits,
          cache_misses:   @cache_misses,
          hit_rate:       hit_rate,
        }
      end

      # Get least recently used resources for eviction
      def get_lru_resources(count : Int32) : Array(String)
        @resource_info.to_a
          .sort_by { |_, info| info.last_accessed }
          .first(count)
          .map { |name, _| name }
      end

      # Check if cache needs eviction
      def needs_eviction? : Bool
        @current_memory_usage > @max_memory_bytes
      end

      # Clear all cache statistics
      def clear_stats : Nil
        @cache_hits = 0_u32
        @cache_misses = 0_u32
      end

      private def evict_if_needed : Nil
        return unless needs_eviction?

        # Evict least recently used resources until under limit
        lru_resources = get_lru_resources(@resource_info.size)

        lru_resources.each do |resource_name|
          break unless needs_eviction?

          # Note: Actual resource cleanup should be handled by the manager
          # This just tracks the eviction
          remove_resource(resource_name)
        end
      end
    end
  end
end
