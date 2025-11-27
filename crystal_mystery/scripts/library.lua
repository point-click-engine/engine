-- Library Scene Script - Crystal Mystery
-- The Grand Library: Where knowledge and secrets intertwine
-- This is where the investigation truly begins

-- Scene enter handler
function on_enter()
    print("Entering library...")
    set_game_state("visited_library", true)

    -- Play ambient sounds - rain against windows, crackling fire
    play_ambient("castle_ambient", 0.3)

    -- First visit introduction
    if not get_game_state("library_intro_shown") then
        set_game_state("library_intro_shown", true)

        -- Show atmospheric introduction based on game progress
        if get_game_state("scientist_questioned") then
            show_message("You return to the library. The butler stands by the window, watching the rain.")
            show_message("The professor's words echo in your mind: 'Check the library - someone has been reading the crystal texts.'")
        else
            show_message("Rain patters against the tall windows as you enter the grand library.")
            show_message("Towering shelves heavy with centuries of knowledge surround you. Somewhere in here lies the truth.")
        end
    else
        -- Return visits
        if get_game_state("butler_confessed") and not get_game_state("brass_key_received") then
            show_message("The butler avoids your gaze. Perhaps another conversation is in order.")
        elseif get_game_state("game_state_urgent") then
            show_message("Time is running out. The clock shows nearly eleven.")
        end
    end
end

-- Bookshelf interactions - main investigation point
function examine_bookshelf()
    if not get_game_state("bookshelf_examined") then
        show_message("You run your fingers along the ancient spines, searching for anything out of place.")
        show_message("Some books have been disturbed recently - their dust patterns don't match the others.")

        -- Find titles based on game progress
        if get_game_state("scientist_suspects_butler") then
            show_message("You notice the same books the professor mentioned: 'Crystalline Resonance,' 'Hidden Properties of Light.'")
            show_message("And most telling - 'Servants of the Old Houses' sits askew, as if hastily replaced.")
            set_game_state("butler_reading_confirmed", true)
        end

        -- Discovery of hidden item
        if not has_item("research_notes") and get_game_state("workbench_examined") then
            show_message("Behind a heavy tome on mansion history, you find a bundle of papers!")
            show_message("Scientific research notes, filled with calculations about crystal resonance...")
            add_to_inventory("research_notes")
            play_sound("pickup")
            complete_quest_objective("library_investigation", "find_research_notes")
            set_game_state("research_notes_found", true)
        end

        set_game_state("bookshelf_examined", true)
    else
        -- Additional examination with items
        if has_item("lamp") and not get_game_state("bookshelf_lamp_used") then
            show_message("You hold the lamp close to the shelves...")
            show_message("Its revealing light shows fingerprints on several spines - recent visitors to these forbidden texts.")
            set_game_state("bookshelf_lamp_used", true)
        else
            show_message("The shelves hold their remaining secrets tight. The books that matter have been found.")
        end
    end
end

-- Desk interactions - key discovery point
function examine_desk()
    if not get_game_state("desk_examined") then
        show_message("The mahogany desk is covered in scattered papers and an antique inkwell.")
        show_message("A half-finished letter lies open: 'Dear Edmund, I fear what you're becoming...'")
        show_message("It's signed with only the initial 'J' - the writer never finished.")
        set_game_state("desk_examined", true)
        set_game_state("butler_letter_found", true)
    end

    -- Check drawers
    if not get_game_state("desk_drawer_checked") then
        show_message("You try the drawer. It's locked, but loose on its track...")

        if has_item("brass_key") then
            show_message("The brass key fits! The serpent design matches the desk's carvings.")
            show_message("Inside you find Lord Ashworth's final journal entry, dated the night he died.")
            set_game_state("desk_drawer_checked", true)
            set_game_state("grandfather_journal_found", true)
            play_sound("success")
        else
            show_message("A serpent design marks the lock. You'd need a matching key.")
        end
    else
        show_message("The desk holds no more secrets. The journal entry weighs heavy in your pocket.")
    end
end

-- Ancient tome - requires decoding
function on_ancient_tome_click()
    show_message("An ancient tome bound in strange leather. Its pages are filled with crystalline diagrams.")

    if has_item("mysterious_note") and has_item("lamp") then
        show_message("Using both the note and the lamp's revealing light, the symbols begin to make sense...")
        show_message("It describes a ritual: 'At the eleventh hour, forty-seventh minute, place the crystal in the guardian's hands.'")
        show_message("'Where light meets water, speak the words of power, and the veil shall part.'")
        set_game_state("ritual_decoded", true)
        complete_quest_objective("library_investigation", "decode_ancient_text")
        play_sound("success")
    elseif has_item("mysterious_note") then
        show_message("The symbols on your note match some in this book, but the text remains unclear.")
        show_message("Perhaps better light would reveal what's hidden...")
    elseif has_item("lamp") then
        show_message("The lamp reveals faint annotations in the margins - someone else has studied this.")
        show_message("But without a reference, the main text remains incomprehensible.")
    else
        show_message("The symbols swim before your eyes. You need something to help decode them.")
    end
end

-- Portrait with secret passage
function examine_painting()
    show_message("Lord Ashworth stares down at you with knowing eyes. The portrait seems to follow your movement.")

    if has_item("lamp") then
        show_message("The lamp's light catches something - the frame doesn't sit flush against the wall!")

        if not get_game_state("portrait_secret_found") then
            show_message("You examine the frame carefully. There's a mechanism here...")
            show_message("Pushing the left side reveals a hidden passage leading to the garden!")
            set_game_state("portrait_secret_found", true)
            set_game_state("secret_passage_revealed", true)
            play_sound("success")
        else
            show_message("The secret passage stands open, ready if you need a quick path to the garden.")
        end
    else
        show_message("Something about the frame seems off, but in this dim light, you can't tell what.")
    end
end

-- Fireplace - atmosphere and clues
function examine_fireplace()
    show_message("The dying embers cast dancing shadows across the room.")
    show_message("On the mantelpiece, a clock stands frozen at 11:47.")

    if not get_game_state("clock_examined") then
        show_message("11:47... that time keeps appearing. It must be significant.")
        set_game_state("clock_examined", true)
        set_game_state("time_clue_found", true)
    end

    if has_item("research_notes") then
        show_message("The notes mention 11:47 as the 'moment of alignment.' The clock was stopped deliberately.")
    end
end

-- Globe - constellation clues
function on_globe_click()
    show_message("An antique celestial globe, its surface marked with constellations and mysterious symbols.")

    if has_item("mysterious_note") then
        show_message("The symbols on your note match certain star patterns on the globe!")
        show_message("They form an arrow pointing to Eastern Europe - the Carpathian Mountains.")
        set_game_state("crystal_origin_traced", true)

        if get_game_state("father_theory_formed") then
            show_message("The professor's father fled east... to where the crystal came from?")
        end
    else
        show_message("Someone has circled a location in Eastern Europe with red ink. Romania, perhaps.")
    end
end

-- Reading chair - atmospheric
function examine_reading_chair()
    show_message("A well-worn leather armchair with a reading lamp beside it.")

    if not get_game_state("chair_examined") then
        show_message("An open book lies face-down on the armrest: 'The Hidden Histories of Noble Houses.'")
        show_message("A passage is underlined: 'Those who serve sometimes know more than those they serve.'")
        set_game_state("chair_examined", true)
    else
        show_message("Comfortable, but you have no time for reading. The crystal must be found.")
    end
end

-- Ladder - upper shelf access
function examine_ladder()
    show_message("A brass-railed library ladder, worn smooth from decades of use.")

    if not get_game_state("upper_shelves_checked") then
        show_message("You climb to examine the upper shelves...")
        show_message("Most are covered in dust, but several books show recent handling.")
        show_message("Someone has been researching crystal lore extensively - and recently.")
        set_game_state("upper_shelves_checked", true)
    else
        show_message("The upper shelves have revealed their secrets.")
    end
end

-- Window - atmosphere and garden view
function examine_window()
    show_message("Rain streams down the tall windows, blurring the view of the garden.")

    if get_game_state("garden_light_seen") then
        show_message("The butler mentioned seeing a light in the garden last night...")
        show_message("Through the rain, you can make out the fountain and a shadowy statue.")
    else
        show_message("Lightning illuminates the garden. You glimpse the fountain and something that might be a figure...")
    end
end

-- Butler interaction
function on_butler_interact()
    -- Track that we've questioned the butler
    if not get_game_state("butler_questioned") then
        set_game_state("butler_questioned", true)
    end

    -- Start dialog
    start_dialog("butler_dialog")
end

-- Door to laboratory
function on_door_to_lab_click()
    play_sound("door_open")

    if not get_game_state("visited_laboratory") then
        show_message("You push open the heavy oak door. The smell of chemicals wafts through.")
    end

    change_scene("laboratory")
end

-- Scene exit
function on_exit()
    stop_ambient("castle_ambient")
end

-- Helper function for item use
function use_item_on_hotspot(item, hotspot)
    if item == "lamp" then
        if hotspot == "painting" then
            examine_painting()
            return true
        elseif hotspot == "bookshelf" then
            examine_bookshelf()
            return true
        elseif hotspot == "ancient_tome" then
            on_ancient_tome_click()
            return true
        end
    elseif item == "brass_key" then
        if hotspot == "desk" then
            examine_desk()
            return true
        end
    elseif item == "mysterious_note" then
        if hotspot == "ancient_tome" then
            on_ancient_tome_click()
            return true
        elseif hotspot == "globe" then
            on_globe_click()
            return true
        end
    end

    show_message("That doesn't seem to work here.")
    return false
end

-- Register hotspot callbacks
hotspot.on_click("bookshelf", examine_bookshelf)
hotspot.on_click("desk", examine_desk)
hotspot.on_click("ancient_tome", on_ancient_tome_click)
hotspot.on_click("painting", examine_painting)
hotspot.on_click("globe", on_globe_click)
hotspot.on_click("fireplace", examine_fireplace)
hotspot.on_click("reading_chair", examine_reading_chair)
hotspot.on_click("ladder", examine_ladder)
hotspot.on_click("window", examine_window)
hotspot.on_click("door_to_lab", on_door_to_lab_click)

-- Register character interactions
character.on_interact("butler", on_butler_interact)

-- Register item use handler
scene.on_item_use(use_item_on_hotspot)

-- Scene lifecycle callbacks
scene.on_enter(on_enter)
scene.on_exit(on_exit)
