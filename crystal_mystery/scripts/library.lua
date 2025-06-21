-- Library Scene Script
-- Handles interactions and events in the library

function on_enter()
    print("Entering library...")
    show_message("The ancient library is filled with dusty tomes and mysterious knowledge.")
    set_game_state("visited_library", true)
    
    -- Play ambient library sounds (subtle)
    play_ambient("library_ambient", 0.2)
end

function on_bookshelf_click()
    if not get_game_state("bookshelf_searched") then
        show_message("You search through the ancient books...")
        if not has_item("research_notes") then
            show_message("Behind some old volumes, you discover research notes about crystal properties!")
            add_to_inventory("research_notes", "Scientific research about crystal properties")
            set_game_state("bookshelf_searched", true)
            play_sound("pickup")
            
            -- Complete quest objective
            complete_quest_objective("library_investigation", "find_research_notes")
        end
    else
        show_message("The bookshelf has been thoroughly searched. Just old books remain.")
    end
end

function on_desk_click()
    if not get_game_state("desk_searched") then
        show_message("You search through the papers on the mahogany desk.")
        show_message("Hidden in a drawer, you find an ornate brass key!")
        add_to_inventory("brass_key", "An ornate brass key")
        set_game_state("desk_searched", true)
        play_sound("pickup")
    else
        show_message("The desk has already been thoroughly searched.")
    end
end

function on_ancient_tome_click()
    if has_item("mysterious_note") then
        show_message("You compare the symbols on the note with the ancient text...")
        show_message("The symbols match! This book contains ancient crystal magic knowledge!")
        set_game_state("ancient_text_decoded", true)
        complete_quest_objective("library_investigation", "decode_ancient_text")
        play_sound("success")
    elseif has_item("lamp") then
        show_message("The lamp's light reveals hidden text in the ancient tome!")
        set_game_state("ritual_discovered", true)
        complete_quest_objective("library_investigation", "discover_ritual")
        play_sound("success")
    else
        show_message("This ancient book is written in strange symbols. You need something to help decipher it.")
    end
end

function on_painting_click()
    if has_item("lamp") then
        show_message("The lamp's light reveals a secret compartment behind the painting!")
        if not get_game_state("secret_compartment_found") then
            show_message("Inside you find additional clues about the mansion's history!")
            set_game_state("secret_compartment_found", true)
            play_sound("success")
        end
    else
        show_message("A portrait of the mansion's founder. His eyes seem to follow you...")
    end
end

function on_globe_click()
    show_message("An ornate celestial globe showing star constellations. Some stars seem to match the crystal symbols.")
    if has_item("mysterious_note") then
        show_message("The patterns on the note align with certain constellations on the globe!")
        set_game_state("constellation_clue_found", true)
    end
end

function on_candlestick_click()
    show_message("An old brass candlestick. It looks like it hasn't been used in years.")
    if has_item("crystal_lens") then
        show_message("The crystal lens focuses the candlelight into interesting patterns...")
    end
end

function on_butler_interact()
    if not get_game_state("butler_questioned") then
        set_game_state("butler_questioned", true)
    end
    
    -- Start dialog with butler
    start_dialog("butler_dialog")
end

function on_door_to_lab_click()
    play_sound("door_open")
    change_scene("laboratory")
end

function on_exit()
    stop_ambient("library_ambient")
end

-- Register hotspot callbacks
hotspot.on_click("bookshelf", on_bookshelf_click)
hotspot.on_click("desk", on_desk_click)
hotspot.on_click("ancient_tome", on_ancient_tome_click)
hotspot.on_click("painting", on_painting_click)
hotspot.on_click("globe", on_globe_click)
hotspot.on_click("candlestick", on_candlestick_click)
hotspot.on_click("door_to_lab", on_door_to_lab_click)

-- Register character interactions
character.on_interact("butler", on_butler_interact)

-- Scene lifecycle callbacks
scene.on_enter(on_enter)
scene.on_exit(on_exit)