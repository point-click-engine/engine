#!/bin/bash
# Run specs one by one with filename tracking

echo "=== Running specs with file tracking ==="
echo "Start time: $(date)"

for spec_file in spec/**/*_spec.cr; do
    echo ">>> Running: $spec_file"
    crystal spec "$spec_file" 2>&1 | tail -3
    echo ""
done

echo "End time: $(date)"
echo "=== All specs completed ==="
