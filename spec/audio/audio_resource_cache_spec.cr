require "../spec_helper"

describe PointClickEngine::Audio::AudioResourceCache do
  describe "#register_resource" do
    it "tracks resource memory usage" do
      cache = PointClickEngine::Audio::AudioResourceCache.new

      cache.register_resource("sound1", 1_000_000_u64)
      cache.register_resource("sound2", 2_000_000_u64)

      cache.current_memory_usage.should eq(3_000_000_u64)
    end
  end

  describe "#access_resource" do
    it "tracks cache hits and misses" do
      cache = PointClickEngine::Audio::AudioResourceCache.new

      cache.register_resource("sound1", 1_000_000_u64)

      # Access existing resource (hit)
      cache.access_resource("sound1")
      cache.cache_hits.should eq(1)
      cache.cache_misses.should eq(0)

      # Access non-existing resource (miss)
      cache.access_resource("sound2")
      cache.cache_hits.should eq(1)
      cache.cache_misses.should eq(1)
    end

    it "updates last accessed time" do
      cache = PointClickEngine::Audio::AudioResourceCache.new

      cache.register_resource("sound1", 1_000_000_u64)

      # Get initial access time
      info1 = cache.@resource_info["sound1"]
      initial_time = info1.last_accessed

      # Wait a tiny bit and access again
      sleep 0.001.seconds
      cache.access_resource("sound1")

      # Access time should be updated
      info2 = cache.@resource_info["sound1"]
      info2.last_accessed.should be > initial_time
      info2.access_count.should eq(1)
    end
  end

  describe "#remove_resource" do
    it "removes resource and updates memory usage" do
      cache = PointClickEngine::Audio::AudioResourceCache.new

      cache.register_resource("sound1", 1_000_000_u64)
      cache.register_resource("sound2", 2_000_000_u64)

      cache.remove_resource("sound1")

      cache.current_memory_usage.should eq(2_000_000_u64)
      cache.@resource_info.has_key?("sound1").should be_false
    end
  end

  describe "#get_stats" do
    it "returns cache statistics" do
      cache = PointClickEngine::Audio::AudioResourceCache.new
      cache.max_memory_bytes = 10_000_000_u64

      cache.register_resource("sound1", 1_000_000_u64)
      cache.register_resource("sound2", 2_000_000_u64)

      cache.access_resource("sound1")
      cache.access_resource("sound1")
      cache.access_resource("sound3") # miss

      stats = cache.get_stats

      stats[:memory_usage].should eq(3_000_000_u64)
      stats[:memory_limit].should eq(10_000_000_u64)
      stats[:resource_count].should eq(2)
      stats[:cache_hits].should eq(2)
      stats[:cache_misses].should eq(1)
      stats[:hit_rate].should be_close(0.667, 0.001)
    end
  end

  describe "#get_lru_resources" do
    it "returns least recently used resources" do
      cache = PointClickEngine::Audio::AudioResourceCache.new

      # Register resources with slight delays to ensure different timestamps
      cache.register_resource("sound1", 1_000_000_u64)
      sleep 0.001.seconds
      cache.register_resource("sound2", 1_000_000_u64)
      sleep 0.001.seconds
      cache.register_resource("sound3", 1_000_000_u64)

      # Access sound2 to make it more recent
      cache.access_resource("sound2")

      lru = cache.get_lru_resources(2)

      lru.size.should eq(2)
      lru.should contain("sound1")     # Oldest
      lru.should contain("sound3")     # Second oldest
      lru.should_not contain("sound2") # Recently accessed
    end
  end

  describe "#needs_eviction?" do
    it "detects when cache is over limit" do
      cache = PointClickEngine::Audio::AudioResourceCache.new
      cache.max_memory_bytes = 5_000_000_u64

      cache.needs_eviction?.should be_false

      cache.register_resource("sound1", 3_000_000_u64)
      cache.needs_eviction?.should be_false

      cache.register_resource("sound2", 3_000_000_u64)
      cache.needs_eviction?.should be_true
    end
  end

  describe "#clear_stats" do
    it "resets cache statistics" do
      cache = PointClickEngine::Audio::AudioResourceCache.new

      cache.access_resource("sound1")
      cache.access_resource("sound2")

      cache.cache_hits.should eq(0)
      cache.cache_misses.should eq(2)

      cache.clear_stats

      cache.cache_hits.should eq(0)
      cache.cache_misses.should eq(0)
    end
  end

  describe "automatic eviction" do
    it "evicts LRU resources when over limit" do
      cache = PointClickEngine::Audio::AudioResourceCache.new
      cache.max_memory_bytes = 5_000_000_u64

      # Add resources that will exceed limit
      cache.register_resource("sound1", 2_000_000_u64)
      sleep 0.001.seconds
      cache.register_resource("sound2", 2_000_000_u64)
      sleep 0.001.seconds

      # This should trigger eviction
      cache.register_resource("sound3", 2_000_000_u64)

      # Should have evicted sound1 (oldest)
      cache.@resource_info.has_key?("sound1").should be_false
      cache.@resource_info.has_key?("sound2").should be_true
      cache.@resource_info.has_key?("sound3").should be_true
      cache.current_memory_usage.should eq(4_000_000_u64)
    end
  end
end
