#!/bin/bash

# Run script for Point Click Engine with audio support
# Handles all Crystal commands with proper audio library setup

# Set library path for miniaudiohelpers
export LIBRARY_PATH="$LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"

# Handle different commands
case "$1" in
  "spec")
    shift
    crystal spec "$@"
    ;;
  "build")
    shift
    crystal build "$@"
    ;;
  "run")
    shift
    crystal run "$@"
    ;;
  "test-comprehensive")
    # Run comprehensive testing suite
    ./test_comprehensive.sh
    ;;
  "test-stress")
    # Run stress tests only
    shift
    crystal spec spec/integration "$@"
    ;;
  "test-memory")
    # Run memory-focused tests
    shift
    crystal spec spec/core/performance* spec/integration "$@"
    ;;
  *)
    # Default to run if no command specified
    crystal run "$@"
    ;;
esac