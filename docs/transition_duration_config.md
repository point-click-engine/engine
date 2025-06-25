# Configurable Transition Durations

The Point & Click Engine now supports configurable transition durations in scene YAML files.

## Scene-Level Default Duration

Each scene can specify a default transition duration that will be used when no explicit duration is provided:

```yaml
name: library
background_path: assets/backgrounds/library.png
default_transition_duration: 4.5  # Duration in seconds
```

## Transition Command Formats

The transition command supports several formats:

1. **Full format with explicit duration:**
   ```yaml
   open: "transition:laboratory:swirl:2.5:100,400"
   ```

2. **Using scene's default duration (empty duration):**
   ```yaml
   open: "transition:laboratory:swirl::100,400"
   ```

3. **Explicitly requesting default duration:**
   ```yaml
   open: "transition:laboratory:swirl:default:100,400"
   ```

4. **Minimal format (uses defaults for everything):**
   ```yaml
   open: "transition:laboratory"
   ```

## Fallback Behavior

- If no duration is specified in the transition command, the current scene's `default_transition_duration` is used
- If the scene doesn't have a `default_transition_duration` set, it defaults to 1.0 seconds
- If no scene is loaded, the fallback is also 1.0 seconds

## Example Usage

```yaml
# In library.yaml
default_transition_duration: 4.5  # Long, dramatic transitions

# In laboratory.yaml  
default_transition_duration: 2.0  # Quick transitions for busy scene

# In garden.yaml
default_transition_duration: 3.0  # Medium-paced outdoor transitions
```

This allows different areas of your game to have different pacing without hardcoding durations in every transition command.