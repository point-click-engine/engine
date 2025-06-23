# Makefile for Point & Click Engine Tests

# Crystal compiler settings
CRYSTAL = crystal
CRYSTAL_FLAGS = --release --error-trace

# Test targets
.PHONY: test-simple test-debug test-movement test-clicks test-comprehensive clean help analyze

help:
	@echo "Available targets:"
	@echo "  test-simple       - Run simple movement test (no walkable areas)"
	@echo "  test-debug        - Run comprehensive debug movement test"
	@echo "  test-clicks       - Run minimal click debug test"
	@echo "  test-comprehensive- Run comprehensive test (walkable areas)"
	@echo "  test-comprehensive-simple - Run comprehensive test (no walkable areas)"
	@echo "  test-movement     - Run all movement tests"
	@echo "  analyze           - Run static analysis of movement system"
	@echo "  clean             - Clean compiled binaries"
	@echo "  help              - Show this help"

test-simple:
	@echo "🔧 Compiling simple movement test..."
	$(CRYSTAL) build simple_movement_test.cr -o simple_movement_test $(CRYSTAL_FLAGS)
	@echo "🚀 Running simple movement test..."
	./simple_movement_test

test-debug:
	@echo "🔧 Compiling debug movement test..."
	$(CRYSTAL) build test_player_movement.cr -o test_player_movement $(CRYSTAL_FLAGS)
	@echo "🚀 Running debug movement test..."
	./test_player_movement

test-clicks:
	@echo "🔧 Compiling click debug test..."
	$(CRYSTAL) build debug_clicks.cr -o debug_clicks $(CRYSTAL_FLAGS)
	@echo "🚀 Running click debug test..."
	./debug_clicks

test-comprehensive:
	@echo "🔧 Compiling comprehensive movement test..."
	$(CRYSTAL) build comprehensive_movement_test.cr -o comprehensive_movement_test $(CRYSTAL_FLAGS)
	@echo "🚀 Running comprehensive test with walkable areas..."
	./comprehensive_movement_test walkable

test-comprehensive-simple:
	@echo "🔧 Compiling comprehensive movement test..."
	$(CRYSTAL) build comprehensive_movement_test.cr -o comprehensive_movement_test $(CRYSTAL_FLAGS)
	@echo "🚀 Running comprehensive test without walkable areas..."
	./comprehensive_movement_test simple

test-movement: test-simple test-debug test-clicks test-comprehensive

analyze:
	@echo "🔧 Running movement system analysis..."
	$(CRYSTAL) run analyze_movement_issues.cr

clean:
	@echo "🧹 Cleaning compiled binaries..."
	rm -f simple_movement_test test_player_movement debug_clicks comprehensive_movement_test
	@echo "✅ Clean complete"

# Build without running
build-simple:
	@echo "🔧 Building simple movement test..."
	$(CRYSTAL) build simple_movement_test.cr -o simple_movement_test $(CRYSTAL_FLAGS)

build-debug:
	@echo "🔧 Building debug movement test..."
	$(CRYSTAL) build test_player_movement.cr -o test_player_movement $(CRYSTAL_FLAGS)

build-clicks:
	@echo "🔧 Building click debug test..."
	$(CRYSTAL) build debug_clicks.cr -o debug_clicks $(CRYSTAL_FLAGS)

build-comprehensive:
	@echo "🔧 Building comprehensive movement test..."
	$(CRYSTAL) build comprehensive_movement_test.cr -o comprehensive_movement_test $(CRYSTAL_FLAGS)

build-all: build-simple build-debug build-clicks build-comprehensive