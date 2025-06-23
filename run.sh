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
    crystal spec "$@" -Dwith_audio
    ;;
  "build")
    shift
    crystal build "$@" -Dwith_audio
    ;;
  "run")
    shift
    crystal run "$@" -Dwith_audio
    ;;
  *)
    # Default to run if no command specified
    crystal run "$@" -Dwith_audio
    ;;
esac