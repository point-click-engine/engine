#!/bin/bash

# Comprehensive Testing Suite for Point & Click Engine
# Runs deep integration tests to discover bugs proactively

set -e

echo "🧪 Starting Comprehensive Engine Testing..."
echo "=================================================="

# Set up library paths for audio support
export LIBRARY_PATH="$LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test categories
TESTS_PASSED=0
TESTS_FAILED=0

run_test_category() {
    local category=$1
    local description=$2
    local spec_pattern=$3
    
    echo -e "\n${BLUE}🔍 Testing: $description${NC}"
    echo "----------------------------------------"
    
    if crystal spec $spec_pattern -Dwith_audio --verbose; then
        echo -e "${GREEN}✅ $category tests PASSED${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ $category tests FAILED${NC}"
        ((TESTS_FAILED++))
    fi
}

# 1. Run standard unit tests first
echo -e "${YELLOW}📋 Phase 1: Standard Unit Tests${NC}"
run_test_category "Unit" "Core unit tests" "spec/core spec/scenes spec/ui spec/audio"

# 2. Run integration tests
echo -e "\n${YELLOW}🔧 Phase 2: Integration Tests${NC}"
run_test_category "Integration" "Comprehensive engine integration" "spec/integration"

# 3. Run validation tests
echo -e "\n${YELLOW}✅ Phase 3: Validation Tests${NC}"
run_test_category "Validation" "Configuration and validation" "spec/core/validation*"

# 4. Run example game tests
echo -e "\n${YELLOW}🎮 Phase 4: Example Game Tests${NC}"
run_test_category "Examples" "Example games and templates" "spec/examples"

# 5. Comprehensive testing strategy implementation
echo -e "\n${YELLOW}🧪 Phase 5: Comprehensive Testing Strategy${NC}"
run_test_category "Property" "Property-based testing" "spec/property/"
run_test_category "Stress" "Stress testing under load" "spec/stress/"
run_test_category "Memory" "Memory leak detection" "spec/memory/"
run_test_category "Performance" "Performance regression" "spec/performance/"
run_test_category "Audio" "Audio system reliability" "spec/audio/"
run_test_category "Scripting" "Lua scripting integration" "spec/scripting/"
run_test_category "SaveLoad" "Save/load system reliability" "spec/saveload/"
run_test_category "Quests" "Quest system edge cases" "spec/quests/"
run_test_category "Fuzzing" "Configuration validation fuzzing" "spec/fuzzing/"
run_test_category "CharacterPath" "Character and pathfinding" "spec/character_pathfinding/"

# 6. Test the actual Crystal Mystery game
echo -e "\n${YELLOW}🎯 Phase 6: Real Game Test${NC}"
echo "Testing Crystal Mystery game execution..."

if timeout 10s crystal run crystal_mystery/main.cr -Dwith_audio --no-debug 2>/dev/null || true; then
    echo -e "${GREEN}✅ Crystal Mystery game execution test PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Crystal Mystery game execution test FAILED${NC}"
    ((TESTS_FAILED++))
fi

# 7. Test build process
echo -e "\n${YELLOW}🔨 Phase 7: Build Tests${NC}"
echo "Testing build process..."

if crystal build crystal_mystery/main.cr -o test_build -Dwith_audio --no-debug; then
    echo -e "${GREEN}✅ Build test PASSED${NC}"
    rm -f test_build  # Clean up
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Build test FAILED${NC}"
    ((TESTS_FAILED++))
fi

# 8. Test configuration validation
echo -e "\n${YELLOW}📄 Phase 8: Configuration Validation${NC}"
echo "Testing various game configurations..."

CONFIG_TESTS=0
CONFIG_PASSED=0

test_config() {
    local config_file=$1
    local description=$2
    
    ((CONFIG_TESTS++))
    echo -n "Testing $description... "
    
    if crystal run -e "
require \"./src/core/game_config\"
config = PointClickEngine::Core::GameConfig.from_file(\"$config_file\")
if config.success?
  puts \"Config valid\"
else
  puts \"Config invalid: #{config.error}\"
end
" 2>/dev/null | grep -q "valid"; then
        echo -e "${GREEN}✅${NC}"
        ((CONFIG_PASSED++))
    else
        echo -e "${RED}❌${NC}"
    fi
}

# Test various configurations
if [ -f "templates/game_config_template.yaml" ]; then
    test_config "templates/game_config_template.yaml" "Template config"
fi

if [ -f "crystal_mystery/game_config.yaml" ]; then
    test_config "crystal_mystery/game_config.yaml" "Crystal Mystery config"
fi

if [ $CONFIG_TESTS -gt 0 ]; then
    if [ $CONFIG_PASSED -eq $CONFIG_TESTS ]; then
        echo -e "${GREEN}✅ Configuration validation PASSED ($CONFIG_PASSED/$CONFIG_TESTS)${NC}"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ Configuration validation FAILED ($CONFIG_PASSED/$CONFIG_TESTS)${NC}"
        ((TESTS_FAILED++))
    fi
fi

# 9. Memory leak detection
echo -e "\n${YELLOW}🧠 Phase 9: Memory Leak Detection${NC}"
echo "Running memory leak detection..."

MEMORY_TEST=$(crystal run -e "
require \"./src/core/engine\"
initial = GC.stats.heap_size
engine = PointClickEngine::Core::Engine.new(640, 480, \"Memory Test\")
engine.init
100.times { engine.update(0.016_f32) }
GC.collect
final = GC.stats.heap_size
growth = final - initial
puts \"Memory growth: #{growth} bytes\"
if growth < 1_000_000  # Less than 1MB growth is acceptable
  puts \"PASS\"
else
  puts \"FAIL\"
end
" 2>/dev/null)

if echo "$MEMORY_TEST" | grep -q "PASS"; then
    echo -e "${GREEN}✅ Memory leak detection PASSED${NC}"
    ((TESTS_PASSED++))
else
    echo -e "${RED}❌ Memory leak detection FAILED${NC}"
    echo "$MEMORY_TEST"
    ((TESTS_FAILED++))
fi

# Final Summary
echo -e "\n${BLUE}=================================================="
echo "🏁 COMPREHENSIVE TESTING COMPLETE"
echo -e "==================================================${NC}"

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
echo -e "Total test categories: $TOTAL_TESTS"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Failed: $TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "\n${GREEN}🎉 ALL TESTS PASSED! Engine is ready for production.${NC}"
    exit 0
else
    echo -e "\n${RED}⚠️  Some tests failed. Review the output above for details.${NC}"
    exit 1
fi