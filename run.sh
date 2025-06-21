#!/bin/bash

# Run script for Point Click Engine with audio support

# Set library path for miniaudiohelpers
export LIBRARY_PATH="$LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:${PWD}/lib/raylib-cr/rsrc/miniaudiohelpers"

# Run with audio support by default
crystal run "$@" -Dwith_audio