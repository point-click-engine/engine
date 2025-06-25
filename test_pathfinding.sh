#!/bin/bash
echo "Starting Crystal Mystery with pathfinding debug..."
echo "Click on the desk area to test pathfinding"
echo "Press Ctrl+C to exit"
echo "================================"
./crystal_mystery/game 2>&1 | grep -E "DEBUG|path|navigation"