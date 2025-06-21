-- Library scene script

function on_enter()
    print("Entering library...")
    
    -- Check game state
    if not get_game_state("intro_shown") then
        show_message("You enter the old library. The smell of ancient books fills the air.")
        set_game_state("intro_shown", true)
    end
end

function on_bookshelf_click()
    if not has_item("ancient_book") then
        show_message("You find an ancient book about crystals!")
        add_to_inventory("ancient_book", "A book about mysterious crystals")
        trigger_achievement("bookworm")
    else
        show_message("You've already taken the interesting book.")
    end
end

function on_desk_click()
    if not has_item("key") then
        show_message("You find a small key in the desk drawer!")
        add_to_inventory("key", "A small brass key")
    else
        show_message("The desk is empty now.")
    end
end

function on_painting_click()
    show_message("The portrait shows Professor Blackwood, the mansion's former owner.")
    if has_item("ancient_book") then
        show_message("Wait... the crystal in the painting looks familiar!")
        set_game_state("painting_clue", true)
    end
end

function on_door_to_lab_click()
    change_scene("laboratory")
end

-- Register hotspot callbacks
hotspot.on_click("bookshelf", on_bookshelf_click)
hotspot.on_click("desk", on_desk_click)
hotspot.on_click("painting", on_painting_click)
hotspot.on_click("door_to_lab", on_door_to_lab_click)