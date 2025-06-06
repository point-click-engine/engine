-- Example Lua script for a scriptable character
-- This script demonstrates the scripting API capabilities

-- Initialize the character when the script is loaded
function on_init()
    log("Character " .. character_name .. " initialized")
    
    -- Set some custom properties
    this_character.custom_properties["mood"] = "friendly"
    this_character.custom_properties["health"] = "100"
end

-- Called regularly by the game engine
function on_update(dt)
    -- Example: Check if character should move randomly
    local time = game.get_time()
    if math.floor(time) % 10 == 0 then
        -- Move to a random position every 10 seconds
        local x = math.random(100, 700)
        local y = math.random(100, 500)
        character.move_to(character_name, x, y)
    end
end

-- Called when player interacts with this character
function on_interact(player_name)
    log("Player " .. player_name .. " interacted with " .. character_name)
    
    -- Check if player has a specific item
    if inventory.has_item("key") then
        character.say(character_name, "I see you have the key! Welcome!")
        
        -- Add a reward item
        inventory.add_item("map", "A treasure map")
        
        -- Change character mood
        this_character.custom_properties["mood"] = "excited"
    else
        character.say(character_name, "Hello there! You look like you're searching for something.")
        
        -- Show dialog with information
        dialog.show("I might have something for you, but first you need to find the golden key.", character_name)
    end
end

-- Called when player looks at this character
function on_look()
    local mood = this_character.custom_properties["mood"] or "neutral"
    local description = "This character looks " .. mood .. "."
    
    dialog.show(description)
end

-- Called when player talks to this character
function on_talk()
    local greetings = {
        "How can I help you today?",
        "Nice weather we're having!",
        "Have you explored the castle yet?",
        "I've been waiting for someone like you."
    }
    
    local greeting = greetings[math.random(1, #greetings)]
    character.say(character_name, greeting)
end

-- Called when character completes movement
function on_movement_complete()
    log("Character " .. character_name .. " reached their destination")
    
    -- Play idle animation
    character.set_animation(character_name, "idle")
end

-- Called when character animation completes
function on_animation_complete(animation_name)
    log("Animation '" .. animation_name .. "' completed for " .. character_name)
end

-- Custom event handler
register_event_handler("custom_event", function(data)
    log("Custom event received: " .. (data.message or "no message"))
    character.say(character_name, "Something interesting just happened!")
end)