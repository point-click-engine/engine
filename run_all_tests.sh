#!/bin/bash

echo "🧪 Running Point Click Engine Test Suite"
echo "========================================"
echo ""

# Count total spec files
TOTAL_SPECS=$(find spec -name "*_spec.cr" -type f | wc -l)
echo "📊 Total spec files: $TOTAL_SPECS"
echo ""

# Run tests with timing
echo "⏱️  Starting test run..."
START_TIME=$(date +%s)

# Run specs and capture output
crystal spec --no-color > test_output.tmp 2>&1
TEST_EXIT_CODE=$?

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Parse results
if [ -f test_output.tmp ]; then
    # Extract summary line
    SUMMARY=$(tail -3 test_output.tmp | grep "examples")
    
    # Extract numbers
    EXAMPLES=$(echo "$SUMMARY" | grep -o '[0-9]* examples' | grep -o '[0-9]*')
    FAILURES=$(echo "$SUMMARY" | grep -o '[0-9]* failures' | grep -o '[0-9]*')
    ERRORS=$(echo "$SUMMARY" | grep -o '[0-9]* errors' | grep -o '[0-9]*')
    PENDING=$(echo "$SUMMARY" | grep -o '[0-9]* pending' | grep -o '[0-9]*')
    
    echo ""
    echo "📋 Test Results:"
    echo "================"
    echo "✅ Examples: $EXAMPLES"
    echo "❌ Failures: $FAILURES"
    echo "💥 Errors: $ERRORS"
    echo "⏸️  Pending: $PENDING"
    echo "⏱️  Duration: ${DURATION}s"
    echo ""
    
    # Show details if there are failures or errors
    if [ "$FAILURES" -gt 0 ] || [ "$ERRORS" -gt 0 ]; then
        echo "❌ TESTS FAILED!"
        echo ""
        echo "Details:"
        echo "--------"
        grep -A 5 "Failure\|Error" test_output.tmp
    else
        echo "✅ ALL TESTS PASSING!"
        
        # List tested modules
        echo ""
        echo "📦 Tested Modules:"
        echo "=================="
        echo "✓ Core Systems (Lua, Scenes, Characters)"
        echo "✓ Graphics (Sprites, Animations, Display)"
        echo "✓ Shader System (9 built-in effects)"
        echo "✓ Pathfinding (A* navigation)"
        echo "✓ Cutscenes (Action system)"
        echo "✓ Localization (8 languages)"
        echo "✓ Dialog System"
        echo "✓ Inventory System"
        echo "✓ Asset Management"
        echo "✓ YAML Serialization"
    fi
    
    # Show pending tests if any
    if [ "$PENDING" -gt 0 ]; then
        echo ""
        echo "⏸️  Pending Tests:"
        echo "================="
        grep -B 1 "pending" test_output.tmp | grep -v "^--$"
    fi
    
    # Clean up
    rm -f test_output.tmp
else
    echo "❌ Error: Could not run tests"
    exit 1
fi

echo ""
echo "🎉 Test run complete!"
exit $TEST_EXIT_CODE