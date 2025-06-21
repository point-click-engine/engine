#!/bin/bash

echo "================================"
echo "Running Headless Game Tests"
echo "================================"
echo ""

# Set environment variable for headless mode
export HEADLESS_MODE=true

echo "Running unit tests..."
crystal spec spec/ --error-trace

echo ""
echo "Running integration tests..."
crystal spec spec/integration/ --error-trace

echo ""
echo "Running visibility tests..."
crystal spec spec/integration/crystal_mystery_visibility_spec.cr --error-trace

echo ""
echo "Running gameplay simulation..."
crystal spec spec/integration/crystal_mystery_gameplay_spec.cr --error-trace

echo ""
echo "================================"
echo "All tests completed!"
echo "================================"