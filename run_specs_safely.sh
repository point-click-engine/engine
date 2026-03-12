#!/bin/bash
# Script to run specs in smaller groups to avoid hanging on macOS
#
# WHY THIS EXISTS:
# Running "crystal spec" with all specs together can hang on macOS due to
# GLFW/OpenGL context exhaustion. Many tests create and destroy Raylib windows,
# and after too many init/close cycles, GLFW can become unresponsive.
#
# SOLUTION:
# This script runs specs in smaller batches to avoid overwhelming the graphics
# system. Each batch runs in a separate process, allowing proper cleanup.
#
# USAGE:
#   ./run_specs_safely.sh        # Run all specs in batches
#   ./run_specs_safely.sh fast   # Run only fast specs (no integration)
#   ./run_specs_safely.sh --help # Show help

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  fast      Run only fast specs (skip integration tests)"
    echo "  --help    Show this help message"
    echo ""
    echo "This script runs Crystal specs in batches to avoid hanging issues"
    echo "that occur when running all specs together on macOS."
}

# Check for help flag
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_help
    exit 0
fi

echo -e "${YELLOW}Running specs in batches to avoid macOS GLFW hanging...${NC}"
echo ""

# Skip integration tests if 'fast' option provided
SKIP_INTEGRATION=false
if [ "$1" == "fast" ]; then
    SKIP_INTEGRATION=true
    echo -e "${YELLOW}Running in fast mode - skipping integration tests${NC}"
    echo ""
fi

total_pass=0
total_fail=0
failed_groups=""

run_spec_group() {
    local name="$1"
    shift
    local specs="$@"

    # Expand glob patterns and filter to existing files
    local files=""
    for pattern in $specs; do
        for file in $pattern; do
            if [ -f "$file" ]; then
                files="$files $file"
            fi
        done
    done

    if [ -z "$files" ]; then
        echo -e "  ${YELLOW}No spec files found${NC}"
        return 0
    fi

    # Run specs
    local output
    if output=$(crystal spec $files --no-color 2>&1); then
        # Extract summary line
        local summary=$(echo "$output" | grep -E "^[0-9]+ examples" | tail -1)
        if [ -n "$summary" ]; then
            echo -e "  ${GREEN}✓${NC} $summary"
        else
            echo -e "  ${GREEN}✓${NC} Passed"
        fi
        total_pass=$((total_pass + 1))
        return 0
    else
        # Extract failure count if available
        local failures=$(echo "$output" | grep -E "^[0-9]+ examples" | tail -1)
        if [ -n "$failures" ]; then
            echo -e "  ${RED}✗${NC} $failures"
        else
            echo -e "  ${RED}✗ Failed${NC}"
        fi
        total_fail=$((total_fail + 1))
        failed_groups="$failed_groups\n  - $name"
        return 1
    fi
}

# Core Unit specs (no window usage)
echo -e "${YELLOW}=== Core Unit ===${NC}"
run_spec_group "Core Unit" spec/core/game_object_spec.cr spec/core/error_reporter_simple_spec.cr spec/core/validation_summary_spec.cr spec/core/exceptions_spec.cr spec/core/config_manager_spec.cr spec/core/game_constants_spec.cr spec/core/performance_monitor_spec.cr || true
echo ""

# Core Engine specs (window usage)
echo -e "${YELLOW}=== Core Engine ===${NC}"
run_spec_group "Core Engine" spec/core/engine_*.cr || true
echo ""

# Validators
echo -e "${YELLOW}=== Validators ===${NC}"
run_spec_group "Validators" spec/core/validators/*.cr spec/core/preflight/*.cr spec/core/validation/*.cr || true
echo ""

# Scenes
echo -e "${YELLOW}=== Scenes ===${NC}"
run_spec_group "Scenes" spec/scenes/*.cr || true
echo ""

# UI
echo -e "${YELLOW}=== UI ===${NC}"
run_spec_group "UI" spec/ui/*.cr || true
echo ""

# Audio
echo -e "${YELLOW}=== Audio ===${NC}"
run_spec_group "Audio" spec/audio/*.cr || true
echo ""

# Characters
echo -e "${YELLOW}=== Characters ===${NC}"
run_spec_group "Characters" spec/characters/*.cr spec/characters_spec.cr || true
echo ""

# Inventory & Quests
echo -e "${YELLOW}=== Inventory & Quests ===${NC}"
run_spec_group "Inventory" spec/inventory/*.cr spec/quests/*.cr || true
echo ""

# Localization
echo -e "${YELLOW}=== Localization ===${NC}"
run_spec_group "Localization" spec/localization/*.cr || true
echo ""

# Navigation
echo -e "${YELLOW}=== Navigation ===${NC}"
run_spec_group "Navigation" spec/navigation/*.cr || true
echo ""

# Scripting
echo -e "${YELLOW}=== Scripting ===${NC}"
run_spec_group "Scripting" spec/scripting/*.cr || true
echo ""

# Graphics
echo -e "${YELLOW}=== Graphics ===${NC}"
run_spec_group "Graphics" spec/graphics/*.cr || true
echo ""

# Utils & Misc
echo -e "${YELLOW}=== Utils ===${NC}"
run_spec_group "Utils" spec/utils/*.cr spec/property/*.cr spec/saveload/*.cr || true
echo ""

# Root level specs
echo -e "${YELLOW}=== Root ===${NC}"
run_spec_group "Root" spec/*_spec.cr || true
echo ""

# Integration specs (heavier, run last or skip with 'fast' option)
if [ "$SKIP_INTEGRATION" == "false" ]; then
    echo -e "${YELLOW}=== Integration ===${NC}"
    run_spec_group "Integration" spec/integration/*.cr || true
    echo ""

    echo -e "${YELLOW}=== Stress Tests ===${NC}"
    run_spec_group "Stress" spec/stress/*.cr spec/fuzzing/*.cr || true
    echo ""

    echo -e "${YELLOW}=== Performance ===${NC}"
    run_spec_group "Performance" spec/performance/*.cr || true
    echo ""
fi

# Print summary
echo -e "${YELLOW}=== Summary ===${NC}"
echo "Groups passed: $total_pass"
echo "Groups failed: $total_fail"

if [ $total_fail -gt 0 ]; then
    echo -e "\n${RED}Failed groups:${NC}$failed_groups"
    exit 1
else
    echo -e "\n${GREEN}✅ All spec groups passed!${NC}"
    exit 0
fi
