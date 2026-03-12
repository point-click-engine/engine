# CLAUDE.md

READ ALL DOCS.

NEVER USE GIT COMMANDS.

When refactoring / modifying a file, never change its name or class name. you can save a copy with old_ prefix.

DO NOT CARE ABOUT BACKWARDS COMPATIBILITY.

If a test or spec expect a method or code that is missing and should exist because of its value is is meaningful, for the engine, implement it.

No easy way, do not comment out or remove tests that are complex or hard to fix. fix them

When running specs, always run them in smaller batches (one directory at a time) to avoid hanging. Do not run all specs at once.