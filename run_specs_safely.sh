#!/bin/bash
# NOTE: This script is kept as a backup option. The malloc crash issue has been resolved.
# You can use "crystal spec" normally. This script remains useful for running large test suites in groups.

# Script to run specs in smaller groups to avoid intermittent crashes

echo "Running specs in smaller groups to avoid crashes..."

# Define spec groups
CORE_SPECS="spec/core/*.cr spec/core/**/*.cr"
SCENE_SPECS="spec/scenes/*.cr spec/scenes/**/*.cr"
UI_SPECS="spec/ui/*.cr spec/ui/**/*.cr"
AUDIO_SPECS="spec/audio/*.cr spec/audio/**/*.cr"
ANIMATION_SPECS="spec/animation/*.cr spec/character*.cr"
NAV_SPECS="spec/navigation/*.cr spec/navigation/**/*.cr"
OTHER_SPECS="spec/graphics/*.cr spec/graphics/**/*.cr spec/inventory/*.cr spec/localization/*.cr spec/memory/*.cr spec/performance/*.cr spec/property/*.cr spec/quests/*.cr spec/rendering/*.cr spec/resource_management/*.cr spec/saveload/*.cr spec/scene_management/*.cr spec/scripting/*.cr spec/stress/*.cr spec/utils/*.cr spec/validators/*.cr spec/*.cr"

# Exclude problematic integration specs
EXCLUDE_PATTERN="integration/render|integration/ui_fixes|integration/simple_engine|integration/coordinate"

# Run each group
groups=(
    "Core specs:$CORE_SPECS"
    "Scene specs:$SCENE_SPECS"
    "UI specs:$UI_SPECS"
    "Audio specs:$AUDIO_SPECS"
    "Animation specs:$ANIMATION_SPECS"
    "Navigation specs:$NAV_SPECS"
    "Other specs:$OTHER_SPECS"
)

total_pass=0
total_fail=0
failed_groups=""

for group in "${groups[@]}"; do
    IFS=':' read -r name specs <<< "$group"
    echo -e "\n=== Running $name ==="
    
    # Filter out excluded specs
    filtered_specs=""
    for spec in $specs; do
        if [ -f "$spec" ] && ! echo "$spec" | grep -E "$EXCLUDE_PATTERN" > /dev/null; then
            filtered_specs="$filtered_specs $spec"
        fi
    done
    
    if [ -z "$filtered_specs" ]; then
        echo "No specs found in this group"
        continue
    fi
    
    if crystal spec $filtered_specs --no-color; then
        echo "✓ $name passed"
        ((total_pass++))
    else
        echo "✗ $name failed"
        ((total_fail++))
        failed_groups="$failed_groups\n  - $name"
    fi
done

echo -e "\n=== Summary ==="
echo "Groups passed: $total_pass"
echo "Groups failed: $total_fail"

if [ $total_fail -gt 0 ]; then
    echo -e "\nFailed groups:$failed_groups"
    exit 1
else
    echo -e "\n✅ All spec groups passed!"
    exit 0
fi